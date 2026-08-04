/// Counts the current streak of consecutive days meeting [goal], ending at
/// the last entry in [dailySteps] (today, in every caller's convention —
/// same "oldest first, today last" ordering as [RollingWeek]/
/// `weeklyStepsProvider`).
///
/// Today gets special handling because it's the one day still in progress:
/// - If today has *already* met goal, it counts, same as any other day —
///   the moment live steps cross goal the streak includes today, matching
///   a day-dot row that already marks today as complete.
/// - If today has *not yet* met goal, that in-progress shortfall must not
///   retroactively break an otherwise-intact streak — a user who completed
///   yesterday and simply hasn't finished today yet is still mid-streak,
///   not reset to 0 the instant a new day starts. So in that case the walk
///   starts from yesterday instead, and today is silently skipped (neither
///   counted nor treated as a break).
///
/// Two real bugs lived in the naive "always start at length - 1" and
/// "always start at length - 2" versions of this — each fixed one of the
/// two cases above while re-breaking the other. Both were independently
/// duplicated across the home, stats, and profile screens before being
/// unified into this one, tested implementation.
int calcStreak(List<int> dailySteps, int goal) {
  if (dailySteps.isEmpty) return 0;

  var startIndex = dailySteps.length - 1;
  if (dailySteps[startIndex] < goal) startIndex--;

  var streak = 0;
  for (var i = startIndex; i >= 0; i--) {
    if (dailySteps[i] >= goal) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}
