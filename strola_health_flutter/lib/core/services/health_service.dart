import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:strola_health/data/datasources/backend_api.dart';

/// Wraps the `health` package — HealthKit on iOS, Health Connect on Android
/// (which is also where Samsung Health and the modern Google Fit successor
/// write their data, so this one integration covers all three on Android).
///
/// Reads steps/distance/calories in (`syncToday`) and, since both platforms
/// support per-source priority for data they store, also writes Strolla's
/// own live totals back out (`pushLiveSteps`) — so the user can go into
/// Health Connect's (or Apple Health's) own settings and set Strolla as the
/// preferred source for steps, ahead of Samsung Health, Google Fit, or a
/// phone's built-in pedometer. Strolla can't force that priority itself —
/// it's a user-controlled OS setting on both platforms — this just makes
/// Strolla's data available to be preferred.
class HealthService {
  HealthService(this._backendApi);
  final BackendApi _backendApi;

  static final _health = Health();

  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  static const _readWrite = [
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
  ];

  IntegrationProvider get _provider => Platform.isIOS
      ? IntegrationProvider.healthkit
      : IntegrationProvider.healthConnect;

  // Write-back throttling state, kept on the instance (see
  // `healthServiceProvider`, which keeps one shared instance alive for this
  // reason) so repeated calls from the live step stream don't flood Health
  // Connect/HealthKit with a new record on every BLE update.
  DateTime? _lastWriteAt;
  int _lastWrittenSteps = 0;
  bool? _writeAuthorized;

  /// Requests on-device permission, marks the provider connected on the
  /// backend, then does an initial sync of today's data. Returns false if
  /// the user denies permission — callers should show that as "not
  /// connected" rather than an error.
  ///
  /// Requests read+write (not read-only) so Strolla can also push its own
  /// totals back into Health Connect/HealthKit — see [pushLiveSteps].
  Future<bool> connect() async {
    await _health.configure();
    final granted = await _health.requestAuthorization(
      _types,
      permissions: _readWrite,
    );
    if (!granted) return false;

    _writeAuthorized = true;
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
      types: [
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      ],
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

  /// Pushes today's live totals into Health Connect/HealthKit as the day
  /// progresses, so the running count Samsung Health, Google Fit, or any
  /// other app reads back out reflects Strolla's device — not just whatever
  /// it captured itself. Each call writes only the delta since the last
  /// successful write, as a record covering [last write time, now] — never
  /// the cumulative total again, since re-writing overlapping ranges would
  /// double-count when something aggregates the day.
  ///
  /// No-ops quietly if write permission was never granted (most users, who
  /// haven't connected this integration) or if called again too soon —
  /// callers don't need to gate this themselves, just call it on every step
  /// update.
  Future<void> pushLiveSteps({
    required int todaySteps,
    required double todayDistanceMeters,
    required int todayCalories,
  }) async {
    final now = DateTime.now();

    // New calendar day since the last write — start the delta tracking over
    // from this midnight rather than comparing against yesterday's totals.
    if (_lastWriteAt != null && !_isSameDay(_lastWriteAt!, now)) {
      _lastWriteAt = null;
      _lastWrittenSteps = 0;
    }

    if (todaySteps <= _lastWrittenSteps) return;
    if (_lastWriteAt != null &&
        now.difference(_lastWriteAt!) < const Duration(minutes: 5)) {
      return;
    }

    _writeAuthorized ??=
        await _health.hasPermissions(_types, permissions: _readWrite) ?? false;
    if (_writeAuthorized != true) return;

    final stepsDelta = todaySteps - _lastWrittenSteps;
    final start = _lastWriteAt ?? DateTime(now.year, now.month, now.day);
    // Same proportion of distance/calories as the step delta represents of
    // today's total — there's no separate "distance/calories since last
    // write" signal to read, so this is the best available split.
    final fraction = stepsDelta / todaySteps;

    try {
      await _health.writeHealthData(
        value: stepsDelta.toDouble(),
        type: HealthDataType.STEPS,
        startTime: start,
        endTime: now,
      );
      if (todayDistanceMeters > 0) {
        await _health.writeHealthData(
          value: todayDistanceMeters * fraction,
          type: HealthDataType.DISTANCE_WALKING_RUNNING,
          startTime: start,
          endTime: now,
        );
      }
      if (todayCalories > 0) {
        await _health.writeHealthData(
          value: todayCalories * fraction,
          type: HealthDataType.ACTIVE_ENERGY_BURNED,
          startTime: start,
          endTime: now,
        );
      }
      _lastWriteAt = now;
      _lastWrittenSteps = todaySteps;
    } catch (_) {
      // Best-effort — a failed write here shouldn't disrupt step tracking.
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// One shared instance for the app's lifetime — [HealthService] keeps
/// write-throttling state on itself, which only works if the same instance
/// is reused across calls (the integrations screen's connect flow and the
/// live step stream's periodic push both need to share it).
final healthServiceProvider = Provider<HealthService>(
  (ref) => HealthService(ref.watch(backendApiProvider)),
);
