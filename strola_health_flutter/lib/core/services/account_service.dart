import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/services/purchase_service.dart';
import 'package:strola_health/data/datasources/backend_api.dart';
import 'package:strola_health/data/datasources/local_database.dart';
import 'package:strola_health/data/repositories/notification_repository.dart';
import 'package:strola_health/presentation/providers/auth_providers.dart';
import 'package:strola_health/presentation/providers/community_providers.dart';
import 'package:strola_health/presentation/providers/notification_providers.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';
import 'package:strola_health/presentation/providers/session_providers.dart';
import 'package:strola_health/presentation/providers/step_providers.dart';

/// Restores a returning user's profile from the backend right after a
/// successful sign-in — in particular `onboardingComplete`, so an existing
/// account that already finished onboarding doesn't see that wizard again
/// just because local storage on this device doesn't have it (e.g. after a
/// previous logout wiped it, or this is a fresh install/different device).
///
/// Deliberately not called after sign-*up* — a brand-new account has
/// nothing to restore, and should always see onboarding once.
///
/// Best-effort: if this fails (no network, brand-new account with no
/// profile saved yet, etc.) it silently leaves local state as-is, so a
/// returning user worst-case sees onboarding again rather than the app
/// being blocked on a failed network call.
Future<void> restoreProfileFromBackend(WidgetRef ref) async {
  try {
    final result = await ref.read(backendApiProvider).getMyProfile();
    await ref.read(userProfileProvider.notifier).save(result.profile);
    await ref.read(dailyGoalProvider.notifier).setGoal(result.dailyGoalSteps);
    if (result.weightKg != null) {
      await ref.read(userWeightKgProvider.notifier).setWeight(result.weightKg!);
    }
  } catch (_) {
    // Best-effort — see doc comment above.
  }
}

/// Signs out. With a real backend (Firebase configured), also wipes every
/// piece of locally-stored data tied to the account that was signed in —
/// not just the Firebase session.
///
/// With a real backend, local storage is otherwise the only copy of a given
/// account's profile, weight, goal, streaks, and workout history on *this*
/// device. A logout that left it behind would let the next sign-in on this
/// device (same person or a different account) inherit a stranger's data
/// until [restoreProfileFromBackend] next ran. [restoreProfileFromBackend]
/// (called right after sign-in) is what makes the returning-user case safe
/// to wipe here — it re-fetches the real profile for whoever actually signs
/// back in, so wiping first and restoring after is correct either way.
///
/// Without a real backend (no Firebase project configured yet), there is no
/// account to restore from — wiping here would mean onboarding reappearing
/// after every single logout, which makes the demo flow unusable while
/// that's still being set up. So in that mode this only signs out of the
/// local-only session and leaves all local data — there's no multi-account
/// risk to guard against yet, since every "account" in this mode is just
/// this same local install.
///
/// Deliberately does NOT touch `has_seen_intro` or `remember_me` — those
/// describe how this device behaves, not who was signed into it.
Future<void> signOutAndWipeLocalData(WidgetRef ref) async {
  // RevenueCat first, while the Firebase uid that's currently linked is
  // still the active one — logging out detaches it and reverts to a fresh
  // anonymous purchaser id, so the next account signed in here doesn't
  // inherit this one's cached entitlements.
  await PurchaseService.logOut();

  if (!ref.read(firebaseAvailableProvider)) {
    await ref.read(localSignedInProvider.notifier).signOut();
    return;
  }
  await ref.read(authServiceProvider).signOut();

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
