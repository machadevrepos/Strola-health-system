import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strola_health/domain/entities/user_profile.dart';

/// Provides the shared SharedPreferences instance. Overridden in `main()` with
/// the already-loaded instance so the profile can be read synchronously at
/// startup (no first-frame flash of the wrong screen).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden in main()'),
);

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier(this._prefs) : super(_initial(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'user_profile';

  static UserProfile _initial(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return const UserProfile();
    try {
      return UserProfile.decode(raw);
    } catch (_) {
      return const UserProfile();
    }
  }

  Future<void> save(UserProfile profile) async {
    state = profile;
    await _prefs.setString(_key, profile.encode());
  }

  Future<void> update(UserProfile Function(UserProfile) transform) =>
      save(transform(state));
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>(
  (ref) => UserProfileNotifier(ref.watch(sharedPreferencesProvider)),
);

/// Whether the first-run 5-step setup has been completed.
final onboardingCompleteProvider = Provider<bool>(
  (ref) => ref.watch(userProfileProvider).onboardingComplete,
);

// ── Privacy settings ──────────────────────────────────────────────────────────
// Controls what others can see, and which sections show on the profile.

class PrivacySettings {
  const PrivacySettings({
    this.publicProfile = true,
    this.shareActivity = true,
    this.showInLeaderboards = true,
    this.allowFriendRequests = true,
    this.hideActivityData = false,
    this.hideAchievements = false,
    this.hideRecentActivity = false,
  });

  final bool publicProfile;
  final bool shareActivity;
  final bool showInLeaderboards;
  final bool allowFriendRequests;
  final bool hideActivityData;
  final bool hideAchievements;
  final bool hideRecentActivity;

  PrivacySettings copyWith({
    bool? publicProfile,
    bool? shareActivity,
    bool? showInLeaderboards,
    bool? allowFriendRequests,
    bool? hideActivityData,
    bool? hideAchievements,
    bool? hideRecentActivity,
  }) =>
      PrivacySettings(
        publicProfile: publicProfile ?? this.publicProfile,
        shareActivity: shareActivity ?? this.shareActivity,
        showInLeaderboards: showInLeaderboards ?? this.showInLeaderboards,
        allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
        hideActivityData: hideActivityData ?? this.hideActivityData,
        hideAchievements: hideAchievements ?? this.hideAchievements,
        hideRecentActivity: hideRecentActivity ?? this.hideRecentActivity,
      );

  Map<String, dynamic> toJson() => {
        'publicProfile': publicProfile,
        'shareActivity': shareActivity,
        'showInLeaderboards': showInLeaderboards,
        'allowFriendRequests': allowFriendRequests,
        'hideActivityData': hideActivityData,
        'hideAchievements': hideAchievements,
        'hideRecentActivity': hideRecentActivity,
      };

  factory PrivacySettings.fromJson(Map<String, dynamic> j) => PrivacySettings(
        publicProfile: j['publicProfile'] as bool? ?? true,
        shareActivity: j['shareActivity'] as bool? ?? true,
        showInLeaderboards: j['showInLeaderboards'] as bool? ?? true,
        allowFriendRequests: j['allowFriendRequests'] as bool? ?? true,
        hideActivityData: j['hideActivityData'] as bool? ?? false,
        hideAchievements: j['hideAchievements'] as bool? ?? false,
        hideRecentActivity: j['hideRecentActivity'] as bool? ?? false,
      );
}

class PrivacySettingsNotifier extends StateNotifier<PrivacySettings> {
  PrivacySettingsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'privacy_settings';

  static PrivacySettings _load(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return const PrivacySettings();
    try {
      return PrivacySettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const PrivacySettings();
    }
  }

  Future<void> update(PrivacySettings Function(PrivacySettings) transform) async {
    state = transform(state);
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }
}

final privacySettingsProvider =
    StateNotifierProvider<PrivacySettingsNotifier, PrivacySettings>(
  (ref) => PrivacySettingsNotifier(ref.watch(sharedPreferencesProvider)),
);
