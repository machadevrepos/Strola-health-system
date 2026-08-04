import { onCall } from "firebase-functions/v2/https";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { requireAdmin, invalidArgument } from "../lib/auth-helpers";

/**
 * Function #63. Serves pre-computed rollups for the Analytics page's date
 * range. v1 reads only what computeDailyStatsRollup/computeRetentionCohort
 * have already produced (no on-demand gap-fill for un-rolled days yet —
 * flagged as a follow-up, not needed until there's real event volume).
 */
export const getAnalyticsDashboard = onCall(async (request) => {
  requireAdmin(request);
  const { startDate, endDate } = (request.data ?? {}) as { startDate?: string; endDate?: string };
  if (!startDate || !endDate) invalidArgument("startDate and endDate (YYYY-MM-DD) are required.");

  const rollupsSnap = await db
    .collection(Collections.dailyStatsRollups)
    .where("date", ">=", startDate)
    .where("date", "<=", endDate)
    .orderBy("date", "asc")
    .get();

  const retentionSnap = await db
    .collection(Collections.retentionCohorts)
    .orderBy("signup_week", "desc")
    .limit(8)
    .get();

  return {
    success: true,
    days: rollupsSnap.docs.map((d) => d.data()),
    retentionCohorts: retentionSnap.docs.map((d) => d.data()),
  };
});
