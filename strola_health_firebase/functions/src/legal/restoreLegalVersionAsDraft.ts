import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, invalidArgument, notFound } from "../lib/auth-helpers";
import type { LegalDocumentVersion } from "../lib/types";

/** Function #49. Never silently re-publishes old content — always creates
 * a brand-new draft seeded from the historical version's content. */
export const restoreLegalVersionAsDraft = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { versionId } = (request.data ?? {}) as { versionId?: string };
  if (!versionId) invalidArgument("versionId is required.");

  const snap = await db.collection(Collections.legalDocumentVersions).doc(versionId).get();
  if (!snap.exists) notFound("Version not found.");
  const source = snap.data() as LegalDocumentVersion;

  const latestSnap = await db
    .collection(Collections.legalDocumentVersions)
    .where("doc_type", "==", source.doc_type)
    .orderBy("version", "desc")
    .limit(1)
    .get();
  const nextVersion = latestSnap.empty ? 1 : (latestSnap.docs[0].data() as LegalDocumentVersion).version + 1;

  const ref = db.collection(Collections.legalDocumentVersions).doc();
  await ref.set({
    id: ref.id,
    doc_type: source.doc_type,
    version: nextVersion,
    status: "draft",
    content: source.content,
    changelog: null,
    effective_date: null,
    requires_reaccept: false,
    created_by: callerUid,
    created_at: FieldValue.serverTimestamp(),
    published_at: null,
  });

  return { success: true, versionId: ref.id, version: nextVersion };
});
