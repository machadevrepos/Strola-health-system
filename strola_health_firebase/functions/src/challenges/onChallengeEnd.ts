import { FieldValue } from "firebase-admin/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { evaluateBadgesForUser } from "../badges/evaluate";
import type { Challenge, UserProfile } from "../lib/types";

/** Function #27. Locks in the default winner (leaderboard leader) at
 * end_date — admins can still override afterward via setChallengeWinner.
 *
 * Also the one place a challenge is known to have just completed for the
 * first time (guarded the same way as the winner lock-in, by
 * `winner_user_id == null` — never re-runs for the same challenge), so
 * this is also where every participant's `challenges_completed` count goes
 * up and gets checked against any `challenges_completed`-requirement badge.
 * Previously nothing evaluated that metric at all — badges keyed to it
 * could be created but could never actually be earned. */
export const onChallengeEnd = onSchedule("every day 00:10", async () => {
  const today = new Date().toISOString().slice(0, 10);

  const endedSnap = await db
    .collection(Collections.challenges)
    .where("status", "==", "published")
    .where("end_date", "<=", today)
    .where("winner_user_id", "==", null)
    .get();

  for (const doc of endedSnap.docs) {
    const challenge = doc.data() as Challenge;
    const leader = challenge.leaderboard_top?.[0];
    if (leader) {
      await doc.ref.update({ winner_user_id: leader.user_id });
    }

    const participantsSnap = await doc.ref.collection("participants").where("left_at", "==", null).get();
    for (const participantDoc of participantsSnap.docs) {
      const userId = (participantDoc.data() as { user_id: string }).user_id;
      const userRef = db.collection(Collections.users).doc(userId);
      const userSnap = await userRef.get();
      if (!userSnap.exists) continue;

      const current = (userSnap.data() as UserProfile).stats.challenges_completed ?? 0;
      const next = current + 1;
      await userRef.update({ "stats.challenges_completed": FieldValue.increment(1) });
      await evaluateBadgesForUser(userId, { challenges_completed: next });
    }
  }
});
