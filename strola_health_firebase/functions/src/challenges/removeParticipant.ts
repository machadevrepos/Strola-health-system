import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

/** Function #25. Admin "kick" from a challenge. */
export const removeParticipant = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { challengeId, userId } = (request.data ?? {}) as { challengeId?: string; userId?: string };
  if (!challengeId || !userId) invalidArgument("challengeId and userId are required.");

  const ref = db.collection(Collections.challengeParticipants(challengeId)).doc(userId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Participant not found.");

  await ref.delete();

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "remove_challenge_participant",
    target: challengeId,
    metadata: { user_id: userId },
  });
  return { success: true };
});
