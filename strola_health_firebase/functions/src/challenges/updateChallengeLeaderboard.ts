import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import type { Challenge, ChallengeParticipant } from "../lib/types";

const LEADERBOARD_TOP_N = 50;

/** Function #28. Maintains a denormalized top-N on the challenge doc so
 * clients don't have to fetch/sort every participant to render a
 * leaderboard. Sort key follows the challenge's own `winner_type`. */
export const updateChallengeLeaderboard = onDocumentWritten(
  `${Collections.challenges}/{challengeId}/participants/{userId}`,
  async (event) => {
    const challengeId = event.params.challengeId;
    const challengeRef = db.collection(Collections.challenges).doc(challengeId);
    const challengeSnap = await challengeRef.get();
    if (!challengeSnap.exists) return;
    const challenge = challengeSnap.data() as Challenge;

    const participantsSnap = await db
      .collection(Collections.challengeParticipants(challengeId))
      .where("left_at", "==", null)
      .get();
    const participants = participantsSnap.docs.map((d) => d.data() as ChallengeParticipant);

    participants.sort((a, b) => {
      if (challenge.winner_type === "goal_completion_pct" && challenge.goal_steps > 0) {
        return b.steps / challenge.goal_steps - a.steps / challenge.goal_steps;
      }
      return b.steps - a.steps;
    });

    await challengeRef.update({ leaderboard_top: participants.slice(0, LEADERBOARD_TOP_N) });
  }
);
