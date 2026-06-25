import 'dart:io';

import 'package:health/health.dart';
import 'package:strola_health/data/datasources/backend_api.dart';

/// Wraps the `health` package — HealthKit on iOS, Health Connect on Android
/// (which is also where Samsung Health and the modern Google Fit successor
/// write their data, so this one integration covers all three on Android).
class HealthService {
  HealthService(this._backendApi);
  final BackendApi _backendApi;

  static final _health = Health();

  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  IntegrationProvider get _provider => Platform.isIOS
      ? IntegrationProvider.healthkit
      : IntegrationProvider.healthConnect;

  /// Requests on-device permission, marks the provider connected on the
  /// backend, then does an initial sync of today's data. Returns false if
  /// the user denies permission — callers should show that as "not
  /// connected" rather than an error.
  Future<bool> connect() async {
    await _health.configure();
    final granted = await _health.requestAuthorization(
      _types,
      permissions: _types.map((_) => HealthDataAccess.READ).toList(),
    );
    if (!granted) return false;

    await _backendApi.markOnDeviceConnected(_provider);
    await syncToday();
    return true;
  }

  /// Reads today's steps/distance/calories and pushes them to the backend.
  /// Safe to call repeatedly (e.g. on app resume) — the backend's ingestion
  /// endpoint just records the latest totals for the day.
  Future<void> syncToday() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    final steps = await _health.getTotalStepsInInterval(midnight, now);

    final samples = await _health.getHealthDataFromTypes(
      types: [HealthDataType.DISTANCE_WALKING_RUNNING, HealthDataType.ACTIVE_ENERGY_BURNED],
      startTime: midnight,
      endTime: now,
    );
    double distanceMeters = 0;
    double calories = 0;
    for (final point in samples) {
      final value = point.value;
      if (value is! NumericHealthValue) continue;
      if (point.type == HealthDataType.DISTANCE_WALKING_RUNNING) {
        distanceMeters += value.numericValue.toDouble();
      } else if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
        calories += value.numericValue.toDouble();
      }
    }

    await _backendApi.ingestHealthSample(
      provider: _provider,
      date: midnight,
      steps: steps,
      distanceMeters: distanceMeters > 0 ? distanceMeters : null,
      calories: calories > 0 ? calories.round() : null,
    );
  }
}
