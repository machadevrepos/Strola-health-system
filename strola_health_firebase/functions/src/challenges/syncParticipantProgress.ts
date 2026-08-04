import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import type { Challenge, DailyActivitySummary } from "../lib/types";

/**
 * Called from health/onDailyActivityWrite.ts whenever a user's daily steps
 * change — recomputes that user's `steps` on every challenge they're
 * actively participating in whose date window covers the changed day.
 * Recomputes as a fresh sum over the window rather than incrementing, since
 * the same day can be revised multiple times as sources merge (BLE device,
 * then a later HealthKit backfill, etc.) — incrementing would double-count.
 */
export async function syncChallengeParticipantProgress(userId: string, date: string): Promise<void> {
  const participantsSnap = await db
    .collectionGroup("participants")
    .where("user_id", "==", userId)
    .where("left_at", "==", null)
    .get();

  for (const participantDoc of participantsSnap.docs) {
    const challengeRef = participantDoc.ref.parent.parent;
    if (!challengeRef) continue;

    const challengeSnap = await challengeRef.get();
    if (!challengeSnap.exists) continue;
    const challenge = challengeSnap.data() as Challenge;
    if (date < challenge.start_date || date > challenge.end_date) continue;

    const activitySnap = await db
      .collection(Collections.dailyActivity)
      .where("user_id", "==", userId)
      .where("date", ">=", challenge.start_date)
      .where("date", "<=", challenge.end_date)
      .get();
    const totalSteps = activitySnap.docs.reduce(
      (sum, d) => sum + ((d.data() as DailyActivitySummary).steps ?? 0),
      0
    );

    await participantDoc.ref.update({ steps: totalSteps });
  }
}
