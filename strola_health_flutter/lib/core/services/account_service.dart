import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/services/purchase_service.dart';
import 'package:strola_health/data/datasources/local_database.dart';
import 'package:strola_health/data/repositories/notification_repository.dart';
import 'package:strola_health/presentation/providers/auth_providers.dart';
import 'package:strola_health/presentation/providers/community_providers.dart';
import 'package:strola_health/presentation/providers/notification_providers.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';
import 'package:strola_health/presentation/providers/session_providers.dart';
import 'package:strola_health/presentation/providers/step_providers.dart';

/// Signs out and wipes every piece of locally-stored data tied to the
/// account that was signed in — not just the Firebase session.
///
/// This app has no backend sync yet, so local storage is the only copy of a
/// given account's profile, weight, goal, streaks, and workout history. A
/// logout that left it behind would let the next sign-in on this device
/// (same person or a different account) inherit a stranger's data, and
/// `onboardingComplete` staying true would skip onboarding for them
/// entirely instead of asking who they are.
///
/// Deliberately does NOT touch `has_seen_intro` or `remember_me` — those
/// describe how this device behaves, not who was signed into it.
Future<void> signOutAndWipeLocalData(WidgetRef ref) async {
  // RevenueCat first, while the Firebase uid that's currently linked is
  // still the active one — logging out detaches it and reverts to a fresh
  // anonymous purchaser id, so the next account signed in here doesn't
  // inherit this one's cached entitlements.
  await PurchaseService.logOut();

  if (ref.read(firebaseAvailableProvider)) {
    await ref.read(authServiceProvider).signOut();
  } else {
    await ref.read(localSignedInProvider.notifier).signOut();
  }

  final prefs = ref.read(sharedPreferencesProvider);
  await Future.wait([
    prefs.remove(UserProfileNotifier.prefsKey),
    prefs.remove(DailyGoalNotifier.prefsKey),
    prefs.remove(UserWeightNotifier.prefsKey),
    prefs.remove(StreakNotifier.currentKey),
    prefs.remove(StreakNotifier.longestKey),
    prefs.remove(StreakNotifier.lastSeenDateKey),
    prefs.remove(PrivacySettingsNotifier.prefsKey),
    prefs.remove(BlockedUsersNotifier.prefsKey),
    prefs.remove(NotificationRepository.prefsKey),
  ]);

  final db = await LocalDatabase.instance;
  await db.delete('workout_sessions');
  await db.delete('daily_steps');

  // Forces every affected provider to rebuild from the now-empty storage
  // immediately, rather than waiting for some unrelated future rebuild to
  // surface the wipe.
  ref.invalidate(userProfileProvider);
  ref.invalidate(dailyGoalProvider);
  ref.invalidate(userWeightKgProvider);
  ref.invalidate(streakProvider);
  ref.invalidate(privacySettingsProvider);
  ref.invalidate(blockedUsersProvider);
  ref.invalidate(notificationsProvider);
  ref.invalidate(sessionHistoryProvider);
  ref.invalidate(dailyStepsMapProvider);
  ref.invalidate(stepCountProvider);
}

/// Deletes the account itself (Firebase Auth user), not just its local
/// session — everything [signOutAndWipeLocalData] wipes locally, plus the
/// account so it can't be signed back into on this or any other device.
///
/// Firebase requires a recent sign-in for this; if the session is stale it
/// throws an [AuthException] (via [AuthService.deleteAccount]) asking the
/// user to log back in first — the caller should surface that message
/// rather than treating it as a generic failure.
Future<void> deleteAccountAndWipeData(WidgetRef ref) async {
  await PurchaseService.logOut();

  if (ref.read(firebaseAvailableProvider)) {
    await ref.read(authServiceProvider).deleteAccount();
  } else {
    await ref.read(localSignedInProvider.notifier).signOut();
  }

  final prefs = ref.read(sharedPreferencesProvider);
  await Future.wait([
    prefs.remove(UserProfileNotifier.prefsKey),
    prefs.remove(DailyGoalNotifier.prefsKey),
    prefs.remove(UserWeightNotifier.prefsKey),
    prefs.remove(StreakNotifier.currentKey),
    prefs.remove(StreakNotifier.longestKey),
    prefs.remove(StreakNotifier.lastSeenDateKey),
    prefs.remove(PrivacySettingsNotifier.prefsKey),
    prefs.remove(BlockedUsersNotifier.prefsKey),
    prefs.remove(NotificationRepository.prefsKey),
  ]);

  final db = await LocalDatabase.instance;
  await db.delete('workout_sessions');
  await db.delete('daily_steps');

  ref.invalidate(userProfileProvider);
  ref.invalidate(dailyGoalProvider);
  ref.invalidate(userWeightKgProvider);
  ref.invalidate(streakProvider);
  ref.invalidate(privacySettingsProvider);
  ref.invalidate(blockedUsersProvider);
  ref.invalidate(notificationsProvider);
  ref.invalidate(sessionHistoryProvider);
  ref.invalidate(dailyStepsMapProvider);
  ref.invalidate(stepCountProvider);
}
