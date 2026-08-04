import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAuth, invalidArgument } from "../lib/auth-helpers";
import { mergeDailyActivity } from "./ingestCore";
import type { UserProfile } from "../lib/types";

const VALID_SOURCES = ["healthkit", "health_connect"];

/**
 * Function #18. Matches backend_api.dart's `POST /integrations/ingest`
 * (HealthSampleIngest payload) exactly — the entire on-device HealthKit /
 * Health Connect integration is this one endpoint, no OAuth involved.
 */
export const ingestHealthSample = onCall(async (request) => {
  const uid = requireAuth(request);
  const { source, date, steps, distanceMeters, calories } = (request.data ?? {}) as {
    source?: string;
    date?: string;
    steps?: number;
    distanceMeters?: number;
    calories?: number;
  };
  if (!source || !VALID_SOURCES.includes(source) || !date) {
    invalidArgument("source (healthkit|health_connect) and date (YYYY-MM-DD) are required.");
  }

  const userSnap = await db.collection(Collections.users).doc(uid).get();
  const user = userSnap.data() as UserProfile | undefined;

  await mergeDailyActivity({
    userId: uid,
    date: date!,
    source: source!,
    steps,
    distanceMeters,
    calories,
    dailyGoalStepsIfNew: user?.daily_goal_steps ?? 10000,
  });

  return { success: true };
});
