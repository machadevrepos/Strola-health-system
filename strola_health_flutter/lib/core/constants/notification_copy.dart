import 'dart:math';

import 'package:strola_health/core/utils/formatters.dart';

/// Single source of truth for all notification copy — exact client-approved
/// wording. Detectors must pull strings from here, never inline a new one.
class NotificationCopy {
  NotificationCopy._();

  static final _random = Random();

  static String _pickRandom(List<String> variants) =>
      variants[_random.nextInt(variants.length)];

  // ── Goal Reminder — sent if not at goal by 7pm and >=75% of the way there ──
  static const String goalReminderTitle = 'Daily Goal';

  static String goalReminder({required int remainingSteps}) => _pickRandom([
    "You're only ${Formatters.stepCount(remainingSteps)} steps away from today's goal.",
    "A quick walk could get you to today's goal.",
    "Almost at your goal! Every step counts. You've got this.",
    "Just a little more movement and today's goal is yours.",
  ]);

  // ── Goal Achieved ───────────────────────────────────────────────────────────
  static const String goalAchievedTitle = 'Goal Achieved';

  static String goalAchieved() => _pickRandom(const [
    'Goal achieved! Nice work today.',
    'You did it! Another goal completed.',
    'Goal achieved! Way to go!',
  ]);

  // ── Streak ──────────────────────────────────────────────────────────────────
  static const String streakTitle = 'Streak';

  /// 3/7/14-day copy is exact client wording; beyond that we extend the
  /// 14-day phrasing pattern with the real day count (no copy was supplied
  /// for e.g. day 21, 28...).
  static String streakMilestone(int days) {
    switch (days) {
      case 3:
        return '3-day streak! Keep it going.';
      case 7:
        return "You're on a 7-day streak.";
      case 14:
        return '14 days in a row! Amazing consistency.';
      default:
        return '$days days in a row! Amazing consistency.';
    }
  }

  static String streakNewRecordEve() =>
      "One more day and you'll hit a new streak record.";

  // ── Challenge ────────────────────────────────────────────────────────────────
  static const String challengeTitle = 'Challenge Update';

  static String challengeStarted(String challengeName) =>
      'The $challengeName has begun!';

  static String challengeCurrentRank(int rank, String challengeName) =>
      "You're currently ranked #$rank in $challengeName.";

  static String challengeMovedUp(int places, String challengeName) =>
      "You've moved up $places places this week in $challengeName.";

  static String challengeDaysLeft(int days, String challengeName) =>
      'Only $days days left in $challengeName.';

  // ── Community — simulated; no real multi-user backend yet ───────────────────
  static const String communityTitle = 'Strolla Community';

  static String communityComment(String name) =>
      '$name commented on your post.';

  static String communityLike(String name) => '$name liked your update.';

  static String communityFriendRequest() => 'You have a new friend request.';

  // ── Low Battery — stub; BLE doesn't parse a battery characteristic yet ──────
  static const String lowBatteryTitle = 'Battery';

  static String lowBattery() => _pickRandom(const [
    'Your Strolla battery is running low.',
    'Time to charge your Strolla.',
  ]);

  // ── Device Disconnected — bonus, reuses bleStatusProvider ────────────────────
  static const String deviceDisconnectedTitle = 'Device';

  static String deviceDisconnected() =>
      'Your Strolla device disconnected. Reconnect to keep tracking steps.';

  // ── Personal Record — bonus, session-level history check ────────────────────
  static const String personalRecordTitle = 'New Personal Record';

  static String personalRecord(String categoryLabel) =>
      'You just set a new record: $categoryLabel!';
}
