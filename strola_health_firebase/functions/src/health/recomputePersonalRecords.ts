import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import type { PersonalRecordCategory, PersonalRecords } from "../lib/types";

/**
 * Function #20. Replaces the Flutter app's "full-table SQL scan on every
 * session save" (SessionRepository.checkPersonalRecords) with one
 * maintained doc per user, updated transactionally as each session ingests.
 */
export async function recomputePersonalRecords(
  userId: string,
  session: {
    sessionId: string;
    durationSeconds: number;
    distanceMeters: number;
    steps: number;
    avgPaceSecPerKm: number | null;
  }
): Promise<PersonalRecordCategory[]> {
  const ref = db.collection(Collections.personalRecords).doc(userId);
  const newRecords: PersonalRecordCategory[] = [];

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const existing = (snap.exists ? snap.data() : { user_id: userId, records: {} }) as PersonalRecords;
    const records = { ...existing.records };

    const maybeUpdate = (category: PersonalRecordCategory, value: number, higherIsBetter: boolean) => {
      if (value <= 0) return;
      const current = records[category];
      const better = !current || (higherIsBetter ? value > current.value : value < current.value);
      if (better) {
        records[category] = {
          value,
          session_id: session.sessionId,
          achieved_at: FieldValue.serverTimestamp() as unknown as Timestamp,
        };
        newRecords.push(category);
      }
    };

    maybeUpdate("longest_duration", session.durationSeconds, true);
    maybeUpdate("farthest_distance", session.distanceMeters, true);
    maybeUpdate("most_steps_in_session", session.steps, true);
    if (session.avgPaceSecPerKm) maybeUpdate("best_pace", session.avgPaceSecPerKm, false);

    tx.set(ref, { user_id: userId, records }, { merge: true });
  });

  return newRecords;
}
