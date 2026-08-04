import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, actorLabelFromRequest, invalidArgument, notFound } from "../lib/auth-helpers";
import { writeAuditLog } from "../lib/audit";

/** Function #26. Overrides the auto-computed default winner (e.g. for
 * disqualifications found after the challenge ended). `adminNotes` is
 * never shown to users. */
export const setChallengeWinner = onCall(async (request) => {
  const { uid: callerUid } = requireAdmin(request);
  const { challengeId, winnerUserId, adminNotes } = (request.data ?? {}) as {
    challengeId?: string;
    winnerUserId?: string;
    adminNotes?: string;
  };
  if (!challengeId || !winnerUserId) invalidArgument("challengeId and winnerUserId are required.");

  const ref = db.collection(Collections.challenges).doc(challengeId);
  const snap = await ref.get();
  if (!snap.exists) notFound("Challenge not found.");

  await ref.update({
    winner_user_id: winnerUserId,
    admin_notes: adminNotes ?? null,
  });

  await writeAuditLog({
    actorUid: callerUid,
    actor: actorLabelFromRequest(request),
    action: "set_challenge_winner",
    target: challengeId,
    metadata: { winner_user_id: winnerUserId },
  });
  return { success: true };
});
