import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

async function deleteSubcollection(path: string): Promise<void> {
  const snap = await db.collection(path).get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
}

/** Function #24a. */
export const publishChallenge = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { challengeId } = (request.data ?? {}) as { challengeId?: string };
  if (!challengeId) invalidArgument("challengeId is required.");

  const ref = db.collection(Collections.challenges).doc(challengeId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Challenge not found.");

  await ref.update({ status: "published" });
  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "publish_challenge",
    target: challengeId,
  });
  return { success: true };
});

/** Function #24b. */
export const archiveChallenge = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { challengeId } = (request.data ?? {}) as { challengeId?: string };
  if (!challengeId) invalidArgument("challengeId is required.");

  const ref = db.collection(Collections.challenges).doc(challengeId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Challenge not found.");

  await ref.update({ status: "archived" });
  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "archive_challenge",
    target: challengeId,
  });
  return { success: true };
});

/** Function #24c. Cascades participant removal (mirrors the mock UI's
 * documented delete behavior for both official drafts and community-created
 * challenges). */
export const deleteChallenge = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { challengeId } = (request.data ?? {}) as { challengeId?: string };
  if (!challengeId) invalidArgument("challengeId is required.");

  const ref = db.collection(Collections.challenges).doc(challengeId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Challenge not found.");

  await deleteSubcollection(Collections.challengeParticipants(challengeId));
  await ref.delete();

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "delete_challenge",
    target: challengeId,
  });
  return { success: true };
});
