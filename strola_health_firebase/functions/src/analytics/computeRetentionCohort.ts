import { onSchedule } from "firebase-functions/v2/scheduler";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import type { AnalyticsEvent, UserProfile } from "../lib/types";

const CHECKPOINTS = [0, 1, 3, 7, 14, 30] as const;

function startOfWeekUTC(date: Date): Date {
  const d = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  const day = d.getUTCDay();
  const diff = (day === 0 ? -6 : 1) - day; // Monday-start week
  d.setUTCDate(d.getUTCDate() + diff);
  return d;
}

/**
 * Function #62. Cohort = users who signed up in the week starting 5 weeks
 * ago (guarantees day-30 retention is actually observable by the time this
 * runs). Bounded to one week's signups, so the per-user event lookup below
 * stays reasonable even though it's N+1 — this is a weekly batch job, not a
 * hot path.
 */
export const computeRetentionCohort = onSchedule("every monday 01:00", async () => {
  const cohortWeekStart = startOfWeekUTC(new Date(Date.now() - 5 * 7 * 24 * 3600 * 1000));
  const cohortWeekEnd = new Date(cohortWeekStart.getTime() + 7 * 24 * 3600 * 1000);
  const cohortKey = cohortWeekStart.toISOString().slice(0, 10);

  const usersSnap = await db
    .collection(Collections.users)
    .where("created_at", ">=", Timestamp.fromDate(cohortWeekStart))
    .where("created_at", "<", Timestamp.fromDate(cohortWeekEnd))
    .get();
  if (usersSnap.empty) return;

  const retainedCounts: Record<number, number> = {};
  CHECKPOINTS.forEach((cp) => (retainedCounts[cp] = 0));

  for (const userDoc of usersSnap.docs) {
    const user = userDoc.data() as UserProfile;
    const signupDate = user.created_at.toDate();

    const eventsSnap = await db
      .collection(Collections.analyticsEvents)
      .where("user_id", "==", userDoc.id)
      .where("event_type", "==", "app_opened")
      .where("created_at", ">=", user.created_at)
      .get();
    const openedDates = new Set(
      eventsSnap.docs.map((d) => (d.data() as AnalyticsEvent).created_at.toDate().toISOString().slice(0, 10))
    );

    for (const cp of CHECKPOINTS) {
      const checkDate = new Date(signupDate.getTime() + cp * 24 * 3600 * 1000).toISOString().slice(0, 10);
      if (openedDates.has(checkDate)) retainedCounts[cp]++;
    }
  }

  const cohortSize = usersSnap.size;
  const retention: Record<string, number> = {};
  CHECKPOINTS.forEach((cp) => {
    retention[`day_${cp}`] = cohortSize > 0 ? retainedCounts[cp] / cohortSize : 0;
  });

  await db.collection(Collections.retentionCohorts).doc(cohortKey).set({
    signup_week: cohortKey,
    cohort_size: cohortSize,
    retention,
    computed_at: FieldValue.serverTimestamp(),
  });
});
