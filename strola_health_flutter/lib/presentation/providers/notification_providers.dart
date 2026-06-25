import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/notification_copy.dart';
import 'package:strola_health/core/services/local_notification_service.dart';
import 'package:strola_health/data/repositories/notification_repository.dart';
import 'package:strola_health/domain/entities/app_notification.dart';
import 'package:strola_health/domain/entities/challenge.dart';
import 'package:strola_health/presentation/providers/ble_providers.dart';
import 'package:strola_health/presentation/providers/community_providers.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';
import 'package:strola_health/presentation/providers/step_providers.dart';

// ── Feed + unread count ───────────────────────────────────────────────────────

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() {
    return ref.read(notificationRepositoryProvider).getAll();
  }

  Future<void> add(AppNotification notification) async {
    final repo = ref.read(notificationRepositoryProvider);
    state = AsyncData(await repo.add(notification));
    await LocalNotificationService.showNow(notification);
  }

  Future<void> markRead(String id) async {
    final repo = ref.read(notificationRepositoryProvider);
    state = AsyncData(await repo.markRead(id));
  }

  Future<void> markAllRead() async {
    final repo = ref.read(notificationRepositoryProvider);
    state = AsyncData(await repo.markAllRead());
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? const [];
  return notifications.where((n) => !n.isRead).length;
});

Future<void> _fire(
  WidgetRef ref, {
  required NotificationCategory category,
  required String title,
  required String body,
  String? routeTarget,
}) {
  final notification = AppNotification(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    category: category,
    title: title,
    body: body,
    timestamp: DateTime.now(),
    routeTarget: routeTarget,
  );
  return ref.read(notificationsProvider.notifier).add(notification);
}

// ── Entry point — call once from MainShell.build() ───────────────────────────

/// Registers every notification detector. Safe to call on every build —
/// `ref.listen` re-registration is the standard Riverpod pattern, and the
/// one-time Timer below is guarded so it's only ever created once.
void registerNotificationDetectors(WidgetRef ref) {
  _watchGoalAchieved(ref);
  _watchGoalReminder(ref);
  _watchStreak(ref);
  _watchChallenges(ref);
  _watchCommunitySimulator(ref);
  _watchDeviceStatus(ref);
}

// ── Goal Achieved ──────────────────────────────────────────────────────────────

void _watchGoalAchieved(WidgetRef ref) {
  ref.listen<bool>(goalReachedProvider, (previous, next) {
    if (next && previous != true) {
      _fire(
        ref,
        category: NotificationCategory.goalAchieved,
        title: NotificationCopy.goalAchievedTitle,
        body: NotificationCopy.goalAchieved(),
        routeTarget: 'home',
      );
    }
  });
}

// ── Goal Reminder — evening nudge once goal is ≥75% and not yet hit ─────────

void _watchGoalReminder(WidgetRef ref) {
  void evaluate() {
    final goalReached = ref.read(goalReachedProvider);
    final progress = ref.read(progressProvider);

    if (goalReached || progress < 0.75) {
      LocalNotificationService.cancelGoalReminder();
      return;
    }

    final int goal = ref.read(dailyGoalProvider);
    final int steps = ref.read(stepCountProvider);
    final body = NotificationCopy.goalReminder(remainingSteps: goal - steps);

    if (DateTime.now().hour >= 19) {
      _maybeFireGoalReminderNow(ref, body);
    } else {
      LocalNotificationService.scheduleGoalReminder(
        title: NotificationCopy.goalReminderTitle,
        body: body,
      );
    }
  }

  ref.listen<int>(stepCountProvider, (_, __) => evaluate());
  evaluate();
}

Future<void> _maybeFireGoalReminderNow(WidgetRef ref, String body) async {
  const key = 'goal_reminder_last_fired_date';
  final prefs = ref.read(sharedPreferencesProvider);
  final todayKey = DateTime.now().toIso8601String().substring(0, 10);
  if (prefs.getString(key) == todayKey) return;

  await prefs.setString(key, todayKey);
  await LocalNotificationService.cancelGoalReminder();
  await _fire(
    ref,
    category: NotificationCategory.goalReminder,
    title: NotificationCopy.goalReminderTitle,
    body: body,
    routeTarget: 'home',
  );
}

// ── Streak ─────────────────────────────────────────────────────────────────────

void _watchStreak(WidgetRef ref) {
  ref.listen<StreakState>(streakProvider, (previous, next) {
    if (next.current == (previous?.current ?? 0)) return;
    if (next.current <= (previous?.current ?? 0)) return; // streak broke — no notification for that

    final oldLongest = previous?.longest ?? 0;
    if (next.current == oldLongest && oldLongest > 0) {
      _fire(
        ref,
        category: NotificationCategory.streak,
        title: NotificationCopy.streakTitle,
        body: NotificationCopy.streakNewRecordEve(),
        routeTarget: 'stats',
      );
      return;
    }

    final isMilestone = next.current == 3 ||
        next.current == 7 ||
        (next.current >= 14 && next.current % 7 == 0);
    if (isMilestone) {
      _fire(
        ref,
        category: NotificationCategory.streak,
        title: NotificationCopy.streakTitle,
        body: NotificationCopy.streakMilestone(next.current),
        routeTarget: 'stats',
      );
    }
  });
}

// ── Challenge ──────────────────────────────────────────────────────────────────

void _watchChallenges(WidgetRef ref) {
  void evaluate(List<Challenge>? challenges) {
    if (challenges != null) _processChallenges(ref, challenges);
  }

  ref.listen<AsyncValue<List<Challenge>>>(
    challengesProvider,
    (_, next) => evaluate(next.value),
  );
  evaluate(ref.read(challengesProvider).value);
}

Future<void> _processChallenges(WidgetRef ref, List<Challenge> challenges) async {
  final prefs = ref.read(sharedPreferencesProvider);

  final seenIds = (jsonDecode(prefs.getString('challenge_seen_ids') ?? '[]') as List)
      .cast<String>()
      .toSet();
  final prevRanks = (jsonDecode(prefs.getString('challenge_prev_ranks') ?? '{}')
          as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v as int));
  final daysLeftNotified = (jsonDecode(
          prefs.getString('challenge_days_left_notified') ?? '{}')
      as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v as int));

  for (final challenge in challenges) {
    if (!challenge.isJoined) continue;

    if (!seenIds.contains(challenge.id)) {
      seenIds.add(challenge.id);
      await _fire(
        ref,
        category: NotificationCategory.challenge,
        title: NotificationCopy.challengeTitle,
        body: NotificationCopy.challengeStarted(challenge.title),
        routeTarget: 'challenges',
      );
    }

    final currentRank = challenge.myRank;
    final prevRank = prevRanks[challenge.id];
    if (prevRank == null) {
      await _fire(
        ref,
        category: NotificationCategory.challenge,
        title: NotificationCopy.challengeTitle,
        body: NotificationCopy.challengeCurrentRank(currentRank, challenge.title),
        routeTarget: 'challenges',
      );
    } else if (currentRank < prevRank) {
      await _fire(
        ref,
        category: NotificationCategory.challenge,
        title: NotificationCopy.challengeTitle,
        body: NotificationCopy.challengeMovedUp(
          prevRank - currentRank,
          challenge.title,
        ),
        routeTarget: 'challenges',
      );
    }
    prevRanks[challenge.id] = currentRank;

    final daysLeft = challenge.daysLeft;
    if (daysLeft <= 3 && daysLeftNotified[challenge.id] != daysLeft) {
      daysLeftNotified[challenge.id] = daysLeft;
      await _fire(
        ref,
        category: NotificationCategory.challenge,
        title: NotificationCopy.challengeTitle,
        body: NotificationCopy.challengeDaysLeft(daysLeft, challenge.title),
        routeTarget: 'challenges',
      );
    }
  }

  await Future.wait([
    prefs.setString('challenge_seen_ids', jsonEncode(seenIds.toList())),
    prefs.setString('challenge_prev_ranks', jsonEncode(prevRanks)),
    prefs.setString(
      'challenge_days_left_notified',
      jsonEncode(daysLeftNotified),
    ),
  ]);
}

// ── Community — simulated; no real multi-user backend yet ───────────────────

Timer? _communityTimer;

void _watchCommunitySimulator(WidgetRef ref) {
  _communityTimer ??= Timer.periodic(const Duration(seconds: 90), (_) {
    final posts = ref.read(postsProvider).value;
    if (posts == null || posts.isEmpty) return;

    final names = posts
        .map((p) => p.authorName)
        .where((n) => n != 'You')
        .toSet()
        .toList();
    if (names.isEmpty) return;

    final random = Random();
    final name = names[random.nextInt(names.length)];
    final body = switch (random.nextInt(3)) {
      0 => NotificationCopy.communityComment(name),
      1 => NotificationCopy.communityLike(name),
      _ => NotificationCopy.communityFriendRequest(),
    };

    _fire(
      ref,
      category: NotificationCategory.community,
      title: NotificationCopy.communityTitle,
      body: body,
      routeTarget: 'community',
    );
  });
}

// ── Device — disconnect (real) + low battery (stub) ──────────────────────────

void _watchDeviceStatus(WidgetRef ref) {
  ref.listen<BleStatus>(bleStatusProvider, (previous, next) {
    if (previous == BleStatus.connected && next == BleStatus.disconnected) {
      _fire(
        ref,
        category: NotificationCategory.deviceDisconnected,
        title: NotificationCopy.deviceDisconnectedTitle,
        body: NotificationCopy.deviceDisconnected(),
        routeTarget: 'home',
      );
    }
  });

  ref.listen<int?>(batteryLevelProvider, (previous, next) {
    if (next != null && next <= 15 && (previous == null || previous > 15)) {
      _fire(
        ref,
        category: NotificationCategory.lowBattery,
        title: NotificationCopy.lowBatteryTitle,
        body: NotificationCopy.lowBattery(),
        routeTarget: 'home',
      );
    }
  });
}
