import { onCall } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument } from "../lib/auth-helpers";
import { writeWorkoutSessionCore, mergeDailyActivity } from "./ingestCore";
import { estimateDistanceMeters, estimateCalories } from "./calculations";
import { recomputePersonalRecords } from "./recomputePersonalRecords";
import { evaluateBadgesForUser } from "../badges/evaluate";
import type { ActivityType, UserProfile } from "../lib/types";

const VALID_ACTIVITY_TYPES: ActivityType[] = [
  "outdoor_walk",
  "outdoor_run",
  "treadmill",
  "strength_training",
  "yoga",
  "pilates",
  "cardio",
  "biking",
  "hiit",
  "other",
];

/**
 * Function #17. `id` is client-generated (per strola_health_flutter's
 * WorkoutSession.id, an epoch-ms string) and doubles as the idempotency key
 * for re-uploads. distance/calories are computed server-side whenever the
 * client doesn't already have them — a synced Strava/Garmin activity that
 * arrives with both already computed skips re-derivation.
 */
export const ingestWorkoutSession = onCall(async (request) => {
  const uid = requireAuth(request);
  const data = (request.data ?? {}) as {
    id?: string;
    startTimeMillis?: number;
    endTimeMillis?: number;
    steps?: number;
    distanceMeters?: number;
    durationSeconds?: number;
    activityType?: ActivityType;
    customActivityName?: string;
    routePolyline?: string;
    avgPaceSecPerKm?: number;
    caloriesBurned?: number;
    source?: string;
    externalId?: string;
  };

  if (
    !data.id ||
    data.startTimeMillis == null ||
    data.endTimeMillis == null ||
    data.steps == null ||
    data.durationSeconds == null ||
    !data.activityType
  ) {
    invalidArgument(
      "id, startTimeMillis, endTimeMillis, steps, durationSeconds, and activityType are required."
    );
  }
  if (!VALID_ACTIVITY_TYPES.includes(data.activityType!)) {
    invalidArgument(`activityType must be one of: ${VALID_ACTIVITY_TYPES.join(", ")}.`);
  }

  const userSnap = await db.collection(Collections.users).doc(uid).get();
  const user = userSnap.data() as UserProfile | undefined;
  const heightCm = user?.height_cm ?? 170;
  const gender = user?.gender ?? "prefer_not_to_say";
  const weightKg = user?.weight_kg ?? 70;

  const distanceMeters =
    data.distanceMeters ?? estimateDistanceMeters(data.steps!, heightCm, gender);
  const caloriesBurned =
    data.caloriesBurned ??
    estimateCalories({
      activityType: data.activityType!,
      durationSeconds: data.durationSeconds!,
      weightKg,
      steps: data.steps!,
    });

  await writeWorkoutSessionCore({
    id: data.id!,
    user_id: uid,
    start_time: Timestamp.fromMillis(data.startTimeMillis!),
    end_time: Timestamp.fromMillis(data.endTimeMillis!),
    steps: data.steps!,
    distance_meters: distanceMeters,
    duration_seconds: data.durationSeconds!,
    activity_type: data.activityType!,
    custom_activity_name: data.customActivityName ?? null,
    route_polyline: data.routePolyline ?? null,
    avg_pace_sec_per_km: data.avgPaceSecPerKm ?? null,
    calories_burned: caloriesBurned,
    source: data.source ?? "strolla_app",
    external_id: data.externalId ?? null,
  });

  const date = new Date(data.startTimeMillis!).toISOString().slice(0, 10);
  await mergeDailyActivity({
    userId: uid,
    date,
    source: data.source ?? "strolla_app",
    steps: data.steps!,
    distanceMeters,
    calories: caloriesBurned,
    dailyGoalStepsIfNew: user?.daily_goal_steps ?? 10000,
  });

  await recomputePersonalRecords(uid, {
    sessionId: data.id!,
    durationSeconds: data.durationSeconds!,
    distanceMeters,
    steps: data.steps!,
    avgPaceSecPerKm: data.avgPaceSecPerKm ?? null,
  });

  await evaluateBadgesForUser(uid, { session_steps: data.steps! });

  return { success: true, distanceMeters, caloriesBurned };
});
