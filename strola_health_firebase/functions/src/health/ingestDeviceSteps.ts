import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument } from "../lib/auth-helpers";
import { mergeDailyActivity } from "./ingestCore";
import type { UserProfile } from "../lib/types";

/**
 * Periodic sync of the day's running total from Strolla's own BLE hardware
 * (ambient step tracking, not a completed GPS session or a health-platform
 * sample — see ingestWorkoutSession.ts / ingestHealthSample.ts for those).
 * Without this, routine BLE step tracking never reached `dailyActivity` at
 * all, so `stats.streak_current`/`stats.streak_longest` (onDailyActivityWrite.ts)
 * — which the admin panel's user detail page already displays — stayed
 * stale for any user who wasn't also running GPS sessions or a connected
 * health platform. Source is always "strolla_device" here (top of
 * SOURCE_PRIORITY), never client-supplied.
 */
export const ingestDeviceSteps = onCall(async (request) => {
  const uid = requireAuth(request);
  const { date, steps, distanceMeters, calories } = (request.data ?? {}) as {
    date?: string;
    steps?: number;
    distanceMeters?: number;
    calories?: number;
  };
  if (!date || steps === undefined) {
    invalidArgument("date (YYYY-MM-DD) and steps are required.");
  }

  const userSnap = await db.collection(Collections.users).doc(uid).get();
  const user = userSnap.data() as UserProfile | undefined;

  await mergeDailyActivity({
    userId: uid,
    date: date!,
    source: "strolla_device",
    steps,
    distanceMeters,
    calories,
    dailyGoalStepsIfNew: user?.daily_goal_steps ?? 10000,
  });

  return { success: true };
});
