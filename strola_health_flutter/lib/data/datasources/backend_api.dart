import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/services/firebase_client.dart';
import 'package:strola_health/domain/entities/user_profile.dart';

// Flutter's enums are camelCase; the backend's field values are
// snake_case. Only two enums cross this boundary, so an explicit map is
// clearer (and safer) here than a generic camel->snake converter.
const _genderToBackend = {
  Gender.male: 'male',
  Gender.female: 'female',
  Gender.other: 'other',
  Gender.preferNotToSay: 'prefer_not_to_say',
};

const _reasonToBackend = {
  StrollaReason.strollerWagon: 'stroller_wagon',
  StrollaReason.walkingPad: 'walking_pad',
  StrollaReason.cantWearWearable: 'cant_wear_wearable',
  StrollaReason.accurateTracking: 'accurate_tracking',
  StrollaReason.other: 'other',
};

// Reverse of the two maps above — used to restore a profile fetched from
// the backend back into this app's enums.
const _genderFromBackend = {
  'male': Gender.male,
  'female': Gender.female,
  'other': Gender.other,
  'prefer_not_to_say': Gender.preferNotToSay,
};

const _reasonFromBackend = {
  'stroller_wagon': StrollaReason.strollerWagon,
  'walking_pad': StrollaReason.walkingPad,
  'cant_wear_wearable': StrollaReason.cantWearWearable,
  'accurate_tracking': StrollaReason.accurateTracking,
  'other': StrollaReason.other,
};

/// Mirrors the backend's `IntegrationProvider` union.
enum IntegrationProvider {
  healthkit,
  healthConnect,
  oura,
  garmin,
  strava,
  myfitnesspal,
}

extension IntegrationProviderX on IntegrationProvider {
  String get apiValue => switch (this) {
    IntegrationProvider.healthkit => 'healthkit',
    IntegrationProvider.healthConnect => 'health_connect',
    IntegrationProvider.oura => 'oura',
    IntegrationProvider.garmin => 'garmin',
    IntegrationProvider.strava => 'strava',
    IntegrationProvider.myfitnesspal => 'myfitnesspal',
  };

  /// True for HealthKit/Health Connect — read on-device, no OAuth redirect.
  bool get isOnDevice =>
      this == IntegrationProvider.healthkit ||
      this == IntegrationProvider.healthConnect;
}

/// Calls the real Firebase backend (Cloud Functions + Firestore, project
/// strolla-health-4c93b) — every method here keeps the exact same signature
/// it had when this class called the retired FastAPI backend, so none of
/// this class's call sites (health_service.dart, integrations_screen.dart,
/// account_service.dart, etc.) needed to change, only these internals did.
class BackendApi {
  /// Takes a thunk rather than a resolved `FirebaseAuth` instance —
  /// `FirebaseAuth.instance` itself calls `Firebase.app()` under the hood,
  /// which throws `[core/no-app]` if `Firebase.initializeApp()` hasn't
  /// succeeded. Deferring that lookup means merely *constructing* a
  /// `BackendApi` (e.g. via `healthServiceProvider`, which needs one purely
  /// for dependency wiring and never actually calls into it for on-device
  /// HealthKit/Health Connect writes) can never crash the app on its own —
  /// only an actual Firebase-dependent call can, and those already have
  /// their own error handling at the UI layer.
  BackendApi(this._authGetter);
  final FirebaseAuth Function() _authGetter;
  FirebaseAuth get _auth => _authGetter();

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in.');
    return uid;
  }

  /// The full `users/{uid}` document — includes `subscription`
  /// (tier/status/comp_until), unlike the public projection other users see.
  /// Every Timestamp field comes back as an ISO 8601 string.
  Future<Map<String, dynamic>> getMe() async {
    final snap = await FirebaseClient.firestore
        .collection('users')
        .doc(_uid)
        .get();
    if (!snap.exists) throw StateError('User not found.');
    return convertFirestoreTimestamps(snap.data()) as Map<String, dynamic>;
  }

  /// [getMe] parsed into this app's local model shapes — used to restore a
  /// returning user's profile (including, critically, whether they've
  /// already completed onboarding) when signing in on a device whose local
  /// storage doesn't have it, e.g. after a previous logout wiped it, or a
  /// fresh install. Local-only fields with no backend equivalent yet
  /// (`photoPath`) are left unset.
  Future<({UserProfile profile, int dailyGoalSteps, double? weightKg})>
  getMyProfile() async {
    final me = await getMe();
    final profile = UserProfile(
      username: me['username'] as String? ?? '',
      name: me['name'] as String? ?? '',
      location: me['location'] as String?,
      bio: me['bio'] as String?,
      heightCm: (me['height_cm'] as num?)?.toDouble() ?? 170,
      gender:
          _genderFromBackend[me['gender'] as String?] ?? Gender.preferNotToSay,
      dateOfBirth: me['date_of_birth'] == null
          ? null
          : DateTime.parse(me['date_of_birth'] as String),
      reasons: ((me['reasons'] as List?) ?? const [])
          .map((r) => _reasonFromBackend[r as String])
          .whereType<StrollaReason>()
          .toSet(),
      units: (me['units'] as String?) == 'imperial'
          ? UnitSystem.imperial
          : UnitSystem.metric,
      onboardingComplete: me['onboarding_complete'] as bool? ?? false,
    );
    return (
      profile: profile,
      dailyGoalSteps: me['daily_goal_steps'] as int? ?? 10000,
      weightKg: (me['weight_kg'] as num?)?.toDouble(),
    );
  }

  /// `updateMyProfile` — pushes the local profile (plus goal/weight, which
  /// live in their own providers locally) to the backend. Called once
  /// onboarding finishes, and whenever the profile is edited afterward.
  Future<void> updateProfile(
    UserProfile profile, {
    required int dailyGoalSteps,
    required double weightKg,
  }) {
    return FirebaseClient.call('updateMyProfile', {
      'username': profile.username,
      'name': profile.name,
      'location': profile.location,
      'bio': profile.bio,
      'heightCm': profile.heightCm,
      'gender': _genderToBackend[profile.gender],
      'dateOfBirth': profile.dateOfBirth?.toIso8601String().split('T').first,
      'reasons': profile.reasons.map((r) => _reasonToBackend[r]).toList(),
      'units': profile.units.name,
      'onboardingComplete': profile.onboardingComplete,
      'dailyGoalSteps': dailyGoalSteps,
      'weightKg': weightKg,
    });
  }

  /// `updateMyPrivacy` — the Privacy Settings screen previously only wrote
  /// to SharedPreferences and never called anything. `hideLocation` has no
  /// `shareActivity`/`showInLeaderboards`/`allowFriendRequests` counterpart
  /// in this app's UI yet, those 3 backend fields are simply never sent.
  Future<void> updatePrivacy({
    bool? publicProfile,
    bool? hideActivityData,
    bool? hideAchievements,
    bool? hideRecentActivity,
    bool? hideLocation,
  }) {
    final data = <String, dynamic>{};
    if (publicProfile != null) data['public_profile'] = publicProfile;
    if (hideActivityData != null) data['hide_activity_data'] = hideActivityData;
    if (hideAchievements != null) data['hide_achievements'] = hideAchievements;
    if (hideRecentActivity != null) {
      data['hide_recent_activity'] = hideRecentActivity;
    }
    if (hideLocation != null) data['hide_location'] = hideLocation;
    return FirebaseClient.call('updateMyPrivacy', data);
  }

  /// `listMyIntegrationConnections` — every provider this user has
  /// connected. `integrationConnections` is entirely Functions-only in
  /// firestore.rules (holds OAuth tokens), so this can't be a direct
  /// Firestore read even for the owning user.
  Future<List<Map<String, dynamic>>> getIntegrations() async {
    final result = await FirebaseClient.call('listMyIntegrationConnections');
    return asMapList(result['connections']);
  }

  /// `startOAuthConnect` — for Strava/Oura/Garmin, the URL to open in a
  /// browser to start the OAuth consent flow. The backend's own
  /// `oauthCallback` function finishes the exchange once the provider
  /// redirects back; this app never sees the client secret.
  Future<String> getOAuthAuthorizationUrl(IntegrationProvider provider) async {
    final result = await FirebaseClient.call('startOAuthConnect', {
      'provider': provider.apiValue,
    });
    return result['authorization_url'] as String;
  }

  /// `markOnDeviceConnected` — HealthKit/Health Connect have no OAuth
  /// callback to hang a "connected" event off, so the app calls this
  /// directly once the user grants on-device permission.
  Future<void> markOnDeviceConnected(IntegrationProvider provider) {
    return FirebaseClient.call('markOnDeviceConnected', {
      'provider': provider.apiValue,
    });
  }

  /// `disconnectIntegration` — self-service, the backend checks the
  /// connection's `user_id` matches the caller (see
  /// functions/src/integrations/disconnectIntegration.ts), so this can't be
  /// used to disconnect anyone else's integration.
  Future<void> disconnectIntegration(String connectionId) {
    return FirebaseClient.call('disconnectIntegration', {
      'connectionId': connectionId,
    });
  }

  /// `ingestHealthSample` — the entire backend integration point for
  /// HealthKit/Health Connect: read locally, push the result here.
  Future<void> ingestHealthSample({
    required IntegrationProvider provider,
    required DateTime date,
    int? steps,
    double? distanceMeters,
    int? calories,
  }) {
    return FirebaseClient.call('ingestHealthSample', {
      'source': provider.apiValue,
      'date': date.toIso8601String().split('T').first,
      'steps': steps,
      'distanceMeters': distanceMeters,
      'calories': calories,
    });
  }

  /// `ingestDeviceSteps` — periodic sync of today's running BLE total, the
  /// counterpart to [ingestHealthSample] for Strolla's own hardware (see
  /// that callable's own comment: this is what keeps `stats.streak_current`
  /// — which the admin panel reads directly — actually current for a user
  /// who's only ever worn the device, never run a GPS session or connected
  /// a health platform).
  Future<void> ingestDeviceSteps({
    required DateTime date,
    required int steps,
    double? distanceMeters,
    int? calories,
  }) {
    return FirebaseClient.call('ingestDeviceSteps', {
      'date': date.toIso8601String().split('T').first,
      'steps': steps,
      'distanceMeters': distanceMeters,
      'calories': calories,
    });
  }
}

final backendApiProvider = Provider<BackendApi>(
  (ref) => BackendApi(() => FirebaseAuth.instance),
);
