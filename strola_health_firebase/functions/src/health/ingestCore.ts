import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections, SOURCE_PRIORITY } from "../lib/constants";
import type { DailyActivitySummary, SourceMetrics, WorkoutSession } from "../lib/types";

/**
 * Shared by the app's direct ingestion callables (#17/#18, Phase 4) and the
 * OAuth-provider scheduled sync (#59, Phase 3) — one merge path regardless
 * of where a day's numbers came from, so `SOURCE_PRIORITY` is only ever
 * applied in this one place.
 */
export async function mergeDailyActivity(params: {
  userId: string;
  date: string; // YYYY-MM-DD
  source: string;
  steps?: number;
  distanceMeters?: number;
  calories?: number;
  dailyGoalStepsIfNew?: number;
}): Promise<DailyActivitySummary> {
  const docId = `${params.userId}_${params.date}`;
  const ref = db.collection(Collections.dailyActivity).doc(docId);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const existing = snap.exists ? (snap.data() as DailyActivitySummary) : null;
    const bySource: Record<string, SourceMetrics> = { ...(existing?.by_source ?? {}) };
    bySource[params.source] = {
      steps: params.steps ?? bySource[params.source]?.steps ?? 0,
      distance_meters: params.distanceMeters ?? bySource[params.source]?.distance_meters ?? 0,
      calories: params.calories ?? bySource[params.source]?.calories ?? 0,
    };

    let primarySource: string | null = null;
    for (const candidate of SOURCE_PRIORITY) {
      if (bySource[candidate]) {
        primarySource = candidate;
        break;
      }
    }
    if (!primarySource) primarySource = Object.keys(bySource)[0] ?? null;
    const winning = primarySource
      ? bySource[primarySource]
      : { steps: 0, distance_meters: 0, calories: 0 };

    const merged: DailyActivitySummary = {
      id: docId,
      user_id: params.userId,
      date: params.date,
      by_source: bySource,
      steps: winning.steps,
      distance_meters: winning.distance_meters,
      calories: winning.calories,
      goal_snapshot: existing?.goal_snapshot ?? params.dailyGoalStepsIfNew ?? 10000,
      primary_source: primarySource,
      updated_at: FieldValue.serverTimestamp() as unknown as Timestamp,
    };

    tx.set(ref, merged, { merge: true });
    return merged;
  });
}

/** Idempotent by `id` (client-generated / provider external id) — a re-upload
 * or re-sync just overwrites the same document rather than duplicating. */
export async function writeWorkoutSessionCore(session: Omit<WorkoutSession, "created_at">): Promise<void> {
  const ref = db.collection(Collections.workoutSessions).doc(session.id);
  await ref.set(
    {
      ...session,
      created_at: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}
