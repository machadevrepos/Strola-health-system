import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument, notFound, failedPrecondition } from "../lib/auth-helpers";
import { enforceRateLimit, RateLimits } from "../lib/rateLimit";
import { APP_CHECK_ENFORCED } from "../lib/appCheck";
import type { Challenge, UserProfile } from "../lib/types";

export async function joinChallengeCore(
  challengeId: string,
  userId: string,
  lockedDailyGoal: number
): Promise<void> {
  const ref = db.collection(Collections.challengeParticipants(challengeId)).doc(userId);
  await ref.set(
    {
      id: `${challengeId}_${userId}`,
      challenge_id: challengeId,
      user_id: userId,
      steps: 0,
      locked_daily_goal: lockedDailyGoal,
      joined_at: FieldValue.serverTimestamp(),
      left_at: null,
    },
    { merge: true }
  );
}

/** Function #22a. Joins by challengeId (public) or inviteCode (private). */
export const joinChallenge = onCall({ enforceAppCheck: APP_CHECK_ENFORCED }, async (request) => {
  const uid = requireAuth(request);
  await enforceRateLimit(uid, "joinChallenge", RateLimits.joinChallenge);
  const { challengeId, inviteCode } = (request.data ?? {}) as {
    challengeId?: string;
    inviteCode?: string;
  };

  let targetId = challengeId;
  if (!targetId && inviteCode) {
    const q = await db
      .collection(Collections.challenges)
      .where("invite_code", "==", inviteCode)
      .limit(1)
      .get();
    if (q.empty) notFound("Invalid invite code.");
    targetId = q.docs[0].id;
  }
  if (!targetId) invalidArgument("challengeId or inviteCode is required.");

  const challengeSnap = await db.collection(Collections.challenges).doc(targetId).get();
  if (!challengeSnap.exists) notFound("Challenge not found.");
  const challenge = challengeSnap.data() as Challenge;
  if (challenge.status === "archived") failedPrecondition("This challenge has ended.");

  const userSnap = await db.collection(Collections.users).doc(uid).get();
  const dailyGoal = (userSnap.data() as UserProfile | undefined)?.daily_goal_steps ?? 10000;

  await joinChallengeCore(targetId, uid, dailyGoal);
  return { success: true, challengeId: targetId };
});

/** Function #22b. */
export const leaveChallenge = onCall(async (request) => {
  const uid = requireAuth(request);
  const { challengeId } = (request.data ?? {}) as { challengeId?: string };
  if (!challengeId) invalidArgument("challengeId is required.");

  const ref = db.collection(Collections.challengeParticipants(challengeId)).doc(uid);
  const snap = await ref.get();
  if (!snap.exists) notFound("You're not in this challenge.");

  await ref.update({ left_at: FieldValue.serverTimestamp() });
  return { success: true };
});
