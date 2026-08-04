import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

/** Function #23. Only one `is_official` challenge at a time — flips it
 * across every other challenge in the same batch. */
export const setOfficialMonthlyChallenge = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { challengeId } = (request.data ?? {}) as { challengeId?: string };
  if (!challengeId) invalidArgument("challengeId is required.");

  const targetRef = db.collection(Collections.challenges).doc(challengeId);
  const targetSnap = await targetRef.get();
  if (!targetSnap.exists) notFound("Challenge not found.");

  const currentlyOfficial = await db
    .collection(Collections.challenges)
    .where("is_official", "==", true)
    .get();

  const batch = db.batch();
  currentlyOfficial.forEach((doc) => {
    if (doc.id !== challengeId) batch.update(doc.ref, { is_official: false });
  });
  batch.update(targetRef, { is_official: true, status: "published", type: "official_monthly" });
  await batch.commit();

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "set_official_monthly_challenge",
    target: challengeId,
  });

  return { success: true };
});
