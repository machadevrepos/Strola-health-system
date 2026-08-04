import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound, failedPrecondition } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";
import type { LegalDocumentVersion } from "../lib/types";

const FANOUT_BATCH_SIZE = 450; // stays under Firestore's 500-write batch limit

/**
 * Function #47. The audit's single clearest "atomic backend job": archive
 * the prior published version, promote the draft, and — if
 * `requires_reaccept` — fan out a `pending` LegalAcceptance to every active
 * (non-deleted, role=user) user, batched for scale.
 */
export const publishLegalVersion = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { versionId, changelog } = (request.data ?? {}) as { versionId?: string; changelog?: string };
  if (!versionId) invalidArgument("versionId is required.");

  const ref = db.collection(Collections.legalDocumentVersions).doc(versionId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Draft not found.");
  const draft = snap.data() as LegalDocumentVersion;
  if (draft.status !== "draft") failedPrecondition("Only a draft can be published.");

  const priorPublishedSnap = await db
    .collection(Collections.legalDocumentVersions)
    .where("doc_type", "==", draft.doc_type)
    .where("status", "==", "published")
    .get();

  const publishBatch = db.batch();
  priorPublishedSnap.forEach((doc) => publishBatch.update(doc.ref, { status: "archived" }));
  publishBatch.update(ref, {
    status: "published",
    changelog: changelog ?? null,
    published_at: FieldValue.serverTimestamp(),
  });
  await publishBatch.commit();

  let fannedOutTo = 0;
  if (draft.requires_reaccept) {
    const usersSnap = await db
      .collection(Collections.users)
      .where("deleted", "==", false)
      .where("role", "==", "user")
      .get();

    for (let i = 0; i < usersSnap.docs.length; i += FANOUT_BATCH_SIZE) {
      const chunk = usersSnap.docs.slice(i, i + FANOUT_BATCH_SIZE);
      const fanoutBatch = db.batch();
      chunk.forEach((userDoc) => {
        const acceptanceId = `${userDoc.id}_${draft.doc_type}`;
        fanoutBatch.set(db.collection(Collections.legalAcceptances).doc(acceptanceId), {
          id: acceptanceId,
          user_id: userDoc.id,
          doc_type: draft.doc_type,
          version: draft.version,
          status: "pending",
          responded_at: null,
        });
      });
      await fanoutBatch.commit();
    }
    fannedOutTo = usersSnap.size;
  }

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "publish_legal_version",
    target: versionId,
    metadata: { doc_type: draft.doc_type, version: draft.version, fanned_out_to: fannedOutTo },
  });

  return { success: true, fannedOutTo };
});
