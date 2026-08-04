import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { evaluateBadgesForUser } from "../badges/evaluate";
import { syncChallengeParticipantProgress } from "../challenges/syncParticipantProgress";
import type { DailyActivitySummary } from "../lib/types";

function shiftDateStr(dateStr: string, deltaDays: number): string {
  const d = new Date(`${dateStr}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + deltaDays);
  return d.toISOString().slice(0, 10);
}

function todayDateStr(): string {
  return new Date().toISOString().slice(0, 10);
}

/**
 * Function #19. Fires on every dailyActivity write (from ingestWorkoutSession,
 * ingestHealthSample, or the OAuth sync job) and recomputes the denormalized
 * stats the admin panel's Users/Analytics pages read directly off the user
 * doc (`stats.lifetime_steps`, `stats.streak_current`, `stats.streak_longest`)
 * — replacing the mock's "recompute by scanning on every read" approach.
 *
 * Streak math respects actual date contiguity (a day with no recorded
 * activity breaks the streak even if surrounding days are in the fetched
 * window), not just adjacency in the query results.
 *
 * Also syncs steps into any challenge this user is actively participating
 * in whose date window covers the changed day (challenges/syncParticipantProgress.ts).
 */
export const onDailyActivityWrite = onDocumentWritten(
  `${Collections.dailyActivity}/{docId}`,
  async (event) => {
    const after = event.data?.after.data() as DailyActivitySummary | undefined;
    if (!after) return; // deletion — nothing to recompute
    const userId = after.user_id;

    const historySnap = await db
      .collection(Collections.dailyActivity)
      .where("user_id", "==", userId)
      .orderBy("date", "desc")
      .limit(400)
      .get();
    const days = historySnap.docs.map((d) => d.data() as DailyActivitySummary);

    const lifetimeSteps = days.reduce((sum, d) => sum + (d.steps ?? 0), 0);

    // ingestDeviceSteps syncs today's running total periodically throughout
    // the day (not just once it's finished), so `days[0]` is very often an
    // in-progress "today" that hasn't met goal yet. That must not
    // retroactively zero out an otherwise-intact streak from prior complete
    // days — same reasoning as the client's calcStreak (rolling_week.dart's
    // sibling, streak.dart). Only grant this grace period when the newest
    // record is dated today; a genuinely-elapsed past day that missed goal
    // still correctly breaks the streak with no grace.
    let streakStart = 0;
    if (days.length > 0 && days[0].date === todayDateStr() && days[0].steps < (days[0].goal_snapshot || 10000)) {
      streakStart = 1;
    }

    let currentStreak = 0;
    let expectedDate = days[streakStart]?.date ?? null;
    for (let i = streakStart; i < days.length; i++) {
      const day = days[i];
      if (day.date !== expectedDate) break;
      if (day.steps < (day.goal_snapshot || 10000)) break;
      currentStreak++;
      expectedDate = shiftDateStr(day.date, -1);
    }

    let longestStreak = currentStreak;
    let running = 0;
    let prevDate: string | null = null;
    for (const day of [...days].reverse()) {
      const metGoal = day.steps >= (day.goal_snapshot || 10000);
      const contiguous = prevDate === null || shiftDateStr(prevDate, 1) === day.date;
      running = metGoal ? (contiguous ? running + 1 : 1) : 0;
      longestStreak = Math.max(longestStreak, running);
      prevDate = day.date;
    }

    await db
      .collection(Collections.users)
      .doc(userId)
      .update({
        "stats.lifetime_steps": lifetimeSteps,
        "stats.streak_current": currentStreak,
        "stats.streak_longest": longestStreak,
        "stats.last_active_date": days[0]?.date ?? null,
      });

    await evaluateBadgesForUser(userId, {
      total_steps: lifetimeSteps,
      streak_days: longestStreak,
    });

    await syncChallengeParticipantProgress(userId, after.date);
  }
);
