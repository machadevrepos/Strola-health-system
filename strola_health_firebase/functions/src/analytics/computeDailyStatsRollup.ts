import { onSchedule } from "firebase-functions/v2/scheduler";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import type { AnalyticsEvent } from "../lib/types";

/**
 * Function #61. Replaces the admin panel's "scan every raw event on every
 * page load" pattern with one pre-aggregated doc per day. Runs just after
 * midnight for the day that just completed.
 */
export const computeDailyStatsRollup = onSchedule("every day 00:30", async () => {
  const yesterday = new Date(Date.now() - 24 * 3600 * 1000).toISOString().slice(0, 10);
  const dayStart = Timestamp.fromDate(new Date(`${yesterday}T00:00:00.000Z`));
  const dayEnd = Timestamp.fromDate(new Date(`${yesterday}T23:59:59.999Z`));

  const eventsSnap = await db
    .collection(Collections.analyticsEvents)
    .where("created_at", ">=", dayStart)
    .where("created_at", "<=", dayEnd)
    .get();

  const dau = new Set<string>();
  const counts = {
    new_signups: 0,
    posts_created: 0,
    challenges_joined: 0,
    workouts_completed: 0,
    premium_started: 0,
    premium_cancelled: 0,
  };

  eventsSnap.forEach((doc) => {
    const event = doc.data() as AnalyticsEvent;
    if (event.event_type === "app_opened" && event.user_id) dau.add(event.user_id);
    switch (event.event_type) {
      case "account_created":
        counts.new_signups++;
        break;
      case "community_post_created":
        counts.posts_created++;
        break;
      case "challenge_joined":
        counts.challenges_joined++;
        break;
      case "workout_completed":
        counts.workouts_completed++;
        break;
      case "premium_started":
        counts.premium_started++;
        break;
      case "premium_cancelled":
        counts.premium_cancelled++;
        break;
    }
  });

  await db
    .collection(Collections.dailyStatsRollups)
    .doc(yesterday)
    .set({
      date: yesterday,
      dau: dau.size,
      ...counts,
      computed_at: FieldValue.serverTimestamp(),
    });
});
