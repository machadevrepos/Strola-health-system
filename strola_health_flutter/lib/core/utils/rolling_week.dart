/// Maps an index in a rolling N-day window (oldest first, today last — the
/// convention `weeklyStepsProvider` and every "week" chart/dot-row on Home
/// and Stats already use) to that day's real calendar weekday.
///
/// Extracted after a real bug: several widgets used to label a rolling
/// window with a fixed `['Mon', ..., 'Sun']` array, which only happened to
/// line up with reality on Sundays (see stats_screen.dart's `_LabeledWeekBars`
/// history). One shared, tested implementation instead of that logic
/// reimplemented — and re-broken — per widget.
class RollingWeek {
  RollingWeek._();

  static const shortNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  /// [index] counts from 0 (oldest, `length - 1` days ago) to `length - 1`
  /// (today). [today] is injectable for tests; defaults to the real clock.
  static DateTime dateForIndex(int index, int length, {DateTime? today}) {
    final now = today ?? DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);
    return todayKey.subtract(Duration(days: length - 1 - index));
  }

  static String shortLabelForIndex(int index, int length, {DateTime? today}) =>
      shortNames[dateForIndex(index, length, today: today).weekday - 1];

  static String letterForIndex(int index, int length, {DateTime? today}) =>
      letters[dateForIndex(index, length, today: today).weekday - 1];
}
