import { onSchedule } from "firebase-functions/v2/scheduler";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import type { Challenge } from "../lib/types";

/** Function #27. Locks in the default winner (leaderboard leader) at
 * end_date — admins can still override afterward via setChallengeWinner. */
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
  }
});
