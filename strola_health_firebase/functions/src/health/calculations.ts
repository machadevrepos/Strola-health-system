import type { ActivityType, Gender } from "../lib/types";

// Mirrors strola_health_backend_fastApi/app/models/activity.py::ActivityType.met
// and app/models/user.py::Gender.stride_multiplier — same formulas, so a
// session synced from either the app or an OAuth provider lands on the same
// numbers a future FastAPI milestone would also produce. `biking`/`hiit`
// aren't in the FastAPI reference enum (Flutter's ActivityType has them,
// FastAPI's doesn't yet) — MET values chosen from standard compendium figures.
const MET: Record<ActivityType, number> = {
  outdoor_walk: 3.5,
  outdoor_run: 8.0,
  treadmill: 4.0,
  strength_training: 3.5,
  yoga: 2.5,
  pilates: 3.0,
  cardio: 5.0,
  biking: 6.8,
  hiit: 8.0,
  other: 3.0,
};

const STRIDE_MULTIPLIER: Record<Gender, number> = {
  female: 0.413,
  male: 0.415,
  other: 0.414,
  prefer_not_to_say: 0.414,
};

/** Flat per-step estimate, matching strola_health_flutter's
 * step_goals.dart::caloriesPerStep — used only for `other`, where MET is
 * skipped entirely per the client's explicit instruction. */
const CALORIES_PER_STEP = 0.04;

export function usesMetCalories(activityType: ActivityType): boolean {
  return activityType !== "other";
}

export function estimateStrideMeters(heightCm: number, gender: Gender): number {
  return (heightCm / 100) * STRIDE_MULTIPLIER[gender];
}

export function estimateDistanceMeters(steps: number, heightCm: number, gender: Gender): number {
  return steps * estimateStrideMeters(heightCm, gender);
}

export function estimateCalories(params: {
  activityType: ActivityType;
  durationSeconds: number;
  weightKg: number;
  steps: number;
}): number {
  if (usesMetCalories(params.activityType)) {
    const hours = params.durationSeconds / 3600;
    return Math.round(MET[params.activityType] * params.weightKg * hours);
  }
  return Math.round(params.steps * CALORIES_PER_STEP);
}
