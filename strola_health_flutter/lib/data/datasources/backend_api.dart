import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/services/api_client.dart';
import 'package:strola_health/domain/entities/user_profile.dart';
import 'package:strola_health/presentation/providers/auth_providers.dart';

// Flutter's enums are camelCase; the backend's Python StrEnums are
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

/// Mirrors the backend's `DataSource` enum — only the 5 platform-integration
/// values, not the BLE-device/manual-entry ones the backend also defines.
enum IntegrationProvider { healthkit, healthConnect, oura, garmin, strava }

extension IntegrationProviderX on IntegrationProvider {
  String get apiValue => switch (this) {
        IntegrationProvider.healthkit => 'healthkit',
        IntegrationProvider.healthConnect => 'health_connect',
        IntegrationProvider.oura => 'oura',
        IntegrationProvider.garmin => 'garmin',
        IntegrationProvider.strava => 'strava',
      };

  /// True for HealthKit/Health Connect — read on-device, no OAuth redirect.
  bool get isOnDevice =>
      this == IntegrationProvider.healthkit || this == IntegrationProvider.healthConnect;
}

/// Calls the FastAPI backend's `/api/v1` endpoints. Every method here
/// assumes the caller is signed in — `ApiClient`'s interceptor attaches the
/// Firebase ID token automatically; there's nothing to pass explicitly.
class BackendApi {
  BackendApi(this._client);
  final ApiClient _client;

  /// `GET /auth/me` — full profile including `subscription` (tier/status/
  /// comp_until), unlike the public projection other users see.
  Future<Map<String, dynamic>> getMe() async {
    final response = await _client.dio.get('/auth/me');
    return response.data as Map<String, dynamic>;
  }

  /// `PATCH /users/me` — pushes the local profile (plus goal/weight, which
  /// live in their own providers locally) to the backend. Called once
  /// onboarding finishes, and whenever the profile is edited afterward.
  Future<void> updateProfile(
    UserProfile profile, {
    required int dailyGoalSteps,
    required double weightKg,
  }) {
    return _client.dio.patch(
      '/users/me',
      data: {
        'username': profile.username,
        'name': profile.name,
        'location': profile.location,
        'bio': profile.bio,
        'height_cm': profile.heightCm,
        'gender': _genderToBackend[profile.gender],
        'date_of_birth': profile.dateOfBirth?.toIso8601String().split('T').first,
        'reasons': profile.reasons.map((r) => _reasonToBackend[r]).toList(),
        'units': profile.units.name,
        'onboarding_complete': profile.onboardingComplete,
        'daily_goal_steps': dailyGoalSteps,
        'weight_kg': weightKg,
      },
    );
  }

  /// `GET /integrations` — every provider this user has connected.
  Future<List<Map<String, dynamic>>> getIntegrations() async {
    final response = await _client.dio.get('/integrations');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  /// `GET /integrations/{provider}/connect` — for Strava/Oura/Garmin, the
  /// URL to open in a browser to start the OAuth consent flow. The backend's
  /// own `/callback` route finishes the exchange once the provider redirects
  /// back; this app never sees the client secret.
  Future<String> getOAuthAuthorizationUrl(IntegrationProvider provider) async {
    final response = await _client.dio.get('/integrations/${provider.apiValue}/connect');
    return (response.data as Map<String, dynamic>)['authorization_url'] as String;
  }

  /// `POST /integrations/{provider}/connected` — HealthKit/Health Connect
  /// have no OAuth callback to hang a "connected" event off, so the app
  /// calls this directly once the user grants on-device permission.
  Future<void> markOnDeviceConnected(IntegrationProvider provider) {
    return _client.dio.post('/integrations/${provider.apiValue}/connected');
  }

  /// `POST /integrations/ingest` — the entire backend integration point for
  /// HealthKit/Health Connect: read locally, push the result here.
  Future<void> ingestHealthSample({
    required IntegrationProvider provider,
    required DateTime date,
    int? steps,
    double? distanceMeters,
    int? calories,
  }) {
    return _client.dio.post(
      '/integrations/ingest',
      data: {
        'source': provider.apiValue,
        'date': date.toIso8601String().split('T').first,
        'steps': steps,
        'distance_meters': distanceMeters,
        'calories': calories,
      },
    );
  }
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(firebaseAuthProvider)),
);

final backendApiProvider = Provider<BackendApi>(
  (ref) => BackendApi(ref.watch(apiClientProvider)),
);
