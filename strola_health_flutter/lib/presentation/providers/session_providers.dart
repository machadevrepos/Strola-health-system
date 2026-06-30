import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:latlong2/latlong.dart';
import 'package:strola_health/data/repositories/session_repository.dart';
import 'package:strola_health/domain/entities/workout_session.dart';
import 'package:strola_health/presentation/providers/step_providers.dart';

// ── Session state ────────────────────────────────────────────────────────────

enum SessionStatus { idle, active, paused }

class SessionState {
  const SessionState({
    this.status = SessionStatus.idle,
    this.activityType = ActivityType.outdoorWalk,
    this.elapsed = Duration.zero,
    this.steps = 0,
    this.distanceMeters = 0,
    this.routePoints = const [],
    this.currentLocation,
    this.currentSpeedMps,
    this.startTime,
    this.gpsAvailable = false,
    this.customActivityName,
  });

  final SessionStatus status;
  final ActivityType activityType;
  final Duration elapsed;
  final int steps;
  final double distanceMeters;
  final List<RoutePoint> routePoints;
  final LatLng? currentLocation;
  final double? currentSpeedMps;
  final DateTime? startTime;
  final bool gpsAvailable;

  /// User-entered name for an [ActivityType.other] session (e.g. "Hiking").
  final String? customActivityName;

  bool get isIdle => status == SessionStatus.idle;
  bool get isActive => status == SessionStatus.active;
  bool get isPaused => status == SessionStatus.paused;
  bool get isRunning => status != SessionStatus.idle;

  /// What to actually show for this session — the custom name when set,
  /// otherwise the activity type's own fixed name.
  String get displayName => customActivityName?.isNotEmpty == true
      ? customActivityName!
      : activityType.displayName;

  double get distanceKm => distanceMeters / 1000;

  String get formattedElapsed {
    final h = elapsed.inHours;
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String get formattedDistance => distanceKm >= 1
      ? '${distanceKm.toStringAsFixed(2)} km'
      : '${distanceMeters.toInt()} m';

  String get formattedPace {
    if (distanceKm <= 0 || elapsed.inSeconds <= 0) return "--'--\"";
    final paceSecPerKm = elapsed.inSeconds / distanceKm;
    final paceMin = paceSecPerKm ~/ 60;
    final paceSec = (paceSecPerKm % 60).toInt();
    return "$paceMin'${paceSec.toString().padLeft(2, '0')}\"";
  }

  SessionState copyWith({
    SessionStatus? status,
    ActivityType? activityType,
    Duration? elapsed,
    int? steps,
    double? distanceMeters,
    List<RoutePoint>? routePoints,
    LatLng? currentLocation,
    double? currentSpeedMps,
    DateTime? startTime,
    bool? gpsAvailable,
    String? customActivityName,
  }) => SessionState(
    status: status ?? this.status,
    activityType: activityType ?? this.activityType,
    elapsed: elapsed ?? this.elapsed,
    steps: steps ?? this.steps,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    routePoints: routePoints ?? this.routePoints,
    currentLocation: currentLocation ?? this.currentLocation,
    currentSpeedMps: currentSpeedMps ?? this.currentSpeedMps,
    startTime: startTime ?? this.startTime,
    gpsAvailable: gpsAvailable ?? this.gpsAvailable,
    customActivityName: customActivityName ?? this.customActivityName,
  );
}

// ── Session notifier ──────────────────────────────────────────────────────────

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier(this._ref) : super(const SessionState());

  final Ref _ref;
  Timer? _timer;
  StreamSubscription<Position>? _gpsSubscription;
  int _startStepCount = 0;

  Future<void> startSession(
    ActivityType type, {
    String? customActivityName,
  }) async {
    _startStepCount = _ref.read(stepCountProvider);
    final now = DateTime.now();

    state = state.copyWith(
      status: SessionStatus.active,
      activityType: type,
      elapsed: Duration.zero,
      steps: 0,
      distanceMeters: 0,
      routePoints: [],
      startTime: now,
      customActivityName: customActivityName,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);

    // Only request GPS for outdoor activities
    if (type.usesGps) {
      await _startGps();
    }
  }

  void _onTick(Timer _) {
    if (!state.isActive) return;

    final currentTotal = _ref.read(stepCountProvider);
    final sessionSteps = (currentTotal - _startStepCount).clamp(0, 999999);

    if (state.activityType.usesGps) {
      // GPS distance is accumulated in the GPS stream — don't overwrite it here.
      state = state.copyWith(
        elapsed: state.elapsed + const Duration(seconds: 1),
        steps: sessionSteps,
      );
    } else {
      // Step-based distance for non-GPS activities.
      state = state.copyWith(
        elapsed: state.elapsed + const Duration(seconds: 1),
        steps: sessionSteps,
        distanceMeters: sessionSteps * state.activityType.strideM,
      );
    }
  }

  Future<void> _startGps() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return; // GPS unavailable — session still tracks steps
      }

      state = state.copyWith(gpsAvailable: true);

      // Get last known position immediately to avoid showing London fallback.
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && state.isRunning) {
        state = state.copyWith(
          currentLocation: LatLng(lastKnown.latitude, lastKnown.longitude),
        );
      }

      // Fresh fix in background — updates map as soon as it resolves.
      Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          )
          .then((pos) {
            if (!state.isRunning) return;
            state = state.copyWith(
              currentLocation: LatLng(pos.latitude, pos.longitude),
            );
          })
          .catchError((_) {});

      // Continuous tracking — each new fix adds to distance and route polyline.
      _gpsSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5, // emit every 5 m of movement
            ),
          ).listen((pos) {
            if (!state.isRunning) return;

            final speedMps = pos.speed.clamp(0.0, 30.0);
            final newPoint = RoutePoint(
              position: LatLng(pos.latitude, pos.longitude),
              speedMps: speedMps,
            );

            // Accumulate true GPS distance between successive fixes.
            double additionalMeters = 0;
            if (state.routePoints.isNotEmpty) {
              final last = state.routePoints.last.position;
              additionalMeters = Geolocator.distanceBetween(
                last.latitude,
                last.longitude,
                pos.latitude,
                pos.longitude,
              );
            }

            state = state.copyWith(
              routePoints: [...state.routePoints, newPoint],
              currentLocation: newPoint.position,
              currentSpeedMps: speedMps > 0 ? speedMps : state.currentSpeedMps,
              distanceMeters: state.distanceMeters + additionalMeters,
            );
          });
    } catch (_) {
      // GPS errors are non-fatal — app degrades gracefully to step-only mode.
    }
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(status: SessionStatus.paused);
  }

  void resume() {
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
    state = state.copyWith(status: SessionStatus.active);
  }

  /// Stops timers/GPS and builds the final [WorkoutSession], but does NOT
  /// persist it — the summary screen decides whether to keep or discard it
  /// (so accidentally-started sessions can be thrown away), via
  /// [saveCompletedSession].
  Future<WorkoutSession> stop() async {
    _timer?.cancel();
    _timer = null;
    await _gpsSubscription?.cancel();
    _gpsSubscription = null;

    // MET-based calorie calculation: MET × weight_kg × hours elapsed.
    final weightKg = _ref.read(userWeightKgProvider);
    final hours = state.elapsed.inSeconds / 3600;
    final calories = (state.activityType.met * weightKg * hours).toInt();

    final session = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: state.startTime ?? DateTime.now(),
      endTime: DateTime.now(),
      steps: state.steps,
      distanceMeters: state.distanceMeters,
      durationSeconds: state.elapsed.inSeconds,
      activityType: state.activityType,
      routePoints: state.routePoints,
      caloriesBurned: calories,
      customActivityName: state.customActivityName,
    );

    state = const SessionState();
    return session;
  }

  Future<void> saveCompletedSession(WorkoutSession session) async {
    await _ref
        .read(sessionRepositoryProvider)
        .saveSession(session, goal: _ref.read(dailyGoalProvider));
    _ref.invalidate(sessionHistoryProvider);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gpsSubscription?.cancel();
    super.dispose();
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>(
  (ref) => SessionNotifier(ref),
);

// ── Session history ───────────────────────────────────────────────────────────

final sessionHistoryProvider = FutureProvider<List<WorkoutSession>>((ref) {
  return ref.read(sessionRepositoryProvider).getSessions();
});

final dailyStepsMapProvider = FutureProvider<Map<DateTime, int>>((ref) async {
  return ref.read(sessionRepositoryProvider).getRecentDailySteps(days: 30);
});

/// Days with recorded steps, most recent first — real data, padded out with
/// deterministic filler days when there isn't yet enough real history (same
/// "visual richness during development" pattern as the calendar heat-map in
/// `activity_screen.dart`). Today's entry always reflects the live count.
/// One shared list so the Profile screen's preview and its "View All" page
/// always agree — the preview is just this list's first 4 entries.
final recentActivityProvider = Provider<List<MapEntry<DateTime, int>>>((ref) {
  final steps = ref.watch(stepCountProvider);
  final recentMap = ref.watch(dailyStepsMapProvider).value ?? const {};
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final merged = {...recentMap, today: steps};

  final real = merged.entries.where((e) => e.value > 0).toList()
    ..sort((a, b) => b.key.compareTo(a.key));

  const target = 16; // middle of the requested ~12–18 range
  if (real.length >= target) return real;

  final used = real.map((e) => e.key).toSet();
  final padded = [...real];
  var cursor = (real.isEmpty ? today : real.last.key).subtract(
    const Duration(days: 1),
  );
  var seed = 1;
  while (padded.length < target) {
    if (!used.contains(cursor)) {
      final mockSteps = 7600 + ((seed * 1597) % 6800);
      padded.add(MapEntry(cursor, mockSteps));
      used.add(cursor);
      seed++;
    }
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return padded;
});

/// [month]'s recorded days, each paired with the goal that was active when
/// it was last written — used so "days met goal" stays correct even after
/// the user raises their goal partway through the month, and so browsing to
/// a previous month reflects the goal that applied back then.
final stepsForMonthWithGoalProvider =
    FutureProvider.family<
      List<({DateTime date, int steps, int goal})>,
      DateTime
    >((ref, month) {
      return ref
          .read(sessionRepositoryProvider)
          .getStepsForMonthWithGoal(
            month,
            fallbackGoal: ref.read(dailyGoalProvider),
          );
    });

final allTimeStepsProvider = FutureProvider<int>((ref) {
  return ref.read(sessionRepositoryProvider).getAllTimeSteps();
});
