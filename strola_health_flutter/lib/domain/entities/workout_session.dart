import 'package:latlong2/latlong.dart';

enum ActivityType {
  outdoorWalk,
  outdoorRun,
  treadmill,
  strengthTraining,
  yoga,
  pilates,
  cardio,
  biking,
  hiit,
  other;

  /// Only outdoor activities use GPS route tracking.
  bool get usesGps =>
      this == outdoorWalk || this == outdoorRun || this == biking;

  /// Whether this activity tracks step count from the BLE device.
  /// Biking is pedaling, not stepping — a step count wouldn't mean anything.
  bool get countsSteps => this != yoga && this != pilates && this != biking;

  /// Whether a distance figure is meaningful to display.
  bool get showsDistance => usesGps || this == treadmill;

  /// MET (Metabolic Equivalent of Task) — used for calorie calculation.
  double get met => switch (this) {
    outdoorWalk => 3.5,
    outdoorRun => 8.0,
    treadmill => 4.0,
    strengthTraining => 3.5,
    yoga => 2.5,
    pilates => 3.0,
    cardio => 5.0,
    biking => 7.5,
    hiit => 8.0,
    other => 3.0,
  };

  /// Stride length in metres, used for step-based distance estimation.
  double get strideM => switch (this) {
    outdoorRun => 1.0,
    treadmill => 0.762,
    _ => 0.762,
  };

  String get displayName => switch (this) {
    outdoorWalk => 'Outdoor Walk',
    outdoorRun => 'Outdoor Run',
    treadmill => 'Treadmill',
    strengthTraining => 'Strength',
    yoga => 'Yoga',
    pilates => 'Pilates',
    cardio => 'Cardio',
    biking => 'Biking',
    hiit => 'HIIT',
    other => 'Other',
  };

  /// Backward-compatible parse — handles old 'walk'/'run' values from v1 DB.
  static ActivityType fromString(String? s) {
    if (s == null) return outdoorWalk;
    // Legacy values from before the enum was expanded
    if (s == 'walk') return outdoorWalk;
    if (s == 'run') return outdoorRun;
    return ActivityType.values.firstWhere(
      (t) => t.name == s,
      orElse: () => outdoorWalk,
    );
  }
}

/// A GPS fix with associated instantaneous speed, used for route heat-map coloring.
class RoutePoint {
  const RoutePoint({required this.position, required this.speedMps});

  final LatLng position;
  final double speedMps;

  @override
  bool operator ==(Object other) =>
      other is RoutePoint &&
      other.position == position &&
      other.speedMps == speedMps;

  @override
  int get hashCode => Object.hash(position, speedMps);
}

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.steps,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.activityType,
    this.routePoints = const [],
    this.avgPaceSecPerKm,
    this.caloriesBurned,
  });

  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int steps;
  final double distanceMeters;
  final int durationSeconds;
  final ActivityType activityType;
  final List<RoutePoint> routePoints;
  final double? avgPaceSecPerKm;

  /// MET-based calories stored at session end; falls back to step-based for old records.
  final int? caloriesBurned;

  double get distanceKm => distanceMeters / 1000;

  int get calories => caloriesBurned ?? (steps * 0.04).toInt();

  String get formattedDuration {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String get formattedDistance => distanceKm >= 1
      ? '${distanceKm.toStringAsFixed(2)} km'
      : '${distanceMeters.toInt()} m';

  String get formattedPace {
    if (distanceKm <= 0 || durationSeconds <= 0) return '--:--';
    final paceSecPerKm = durationSeconds / distanceKm;
    final paceMin = paceSecPerKm ~/ 60;
    final paceSec = (paceSecPerKm % 60).toInt();
    return "$paceMin'${paceSec.toString().padLeft(2, '0')}\"";
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'start_time': startTime.millisecondsSinceEpoch,
    'end_time': endTime.millisecondsSinceEpoch,
    'steps': steps,
    'distance_meters': distanceMeters,
    'duration_seconds': durationSeconds,
    'activity_type': activityType.name,
    'route_points': routePoints
        .map(
          (p) => '${p.position.latitude},${p.position.longitude},${p.speedMps}',
        )
        .join(';'),
    'calories_burned': caloriesBurned,
  };

  factory WorkoutSession.fromMap(Map<String, dynamic> m) => WorkoutSession(
    id: m['id'] as String,
    startTime: DateTime.fromMillisecondsSinceEpoch(m['start_time'] as int),
    endTime: DateTime.fromMillisecondsSinceEpoch(m['end_time'] as int),
    steps: m['steps'] as int,
    distanceMeters: (m['distance_meters'] as num).toDouble(),
    durationSeconds: m['duration_seconds'] as int,
    activityType: ActivityType.fromString(m['activity_type'] as String?),
    caloriesBurned: m['calories_burned'] as int?,
    routePoints: (m['route_points'] as String? ?? '')
        .split(';')
        .where((s) => s.contains(','))
        .map((s) {
          final parts = s.split(',');
          return RoutePoint(
            position: LatLng(double.parse(parts[0]), double.parse(parts[1])),
            speedMps: parts.length > 2
                ? (double.tryParse(parts[2]) ?? 0.0)
                : 0.0,
          );
        })
        .toList(),
  );
}
