import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strola_health/core/constants/step_goals.dart';
import 'package:strola_health/core/services/health_service.dart';
import 'package:strola_health/core/utils/fitness_calculator.dart';
import 'package:strola_health/core/utils/formatters.dart';
import 'package:strola_health/data/repositories/session_repository.dart';
import 'package:strola_health/presentation/providers/ble_providers.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';

// ── Live step count ──────────────────────────────────────────────────────────

class StepCountNotifier extends StateNotifier<int> {
  StepCountNotifier(this._ref) : super(3247) {
    _ref.listen<AsyncValue<int>>(
      bleStepStreamProvider,
      (_, next) => next.whenData((steps) => state = steps),
    );

    _mockTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_ref.read(bleStatusProvider) != BleStatus.connected) {
        state = (state + Random().nextInt(8) + 1).clamp(0, 99999);
      }
    });
  }

  final Ref _ref;
  Timer? _mockTimer;

  void reset() => state = 0;

  @override
  void dispose() {
    _mockTimer?.cancel();
    super.dispose();
  }
}

final stepCountProvider = StateNotifierProvider<StepCountNotifier, int>(
  (ref) => StepCountNotifier(ref),
);

// ── Daily goal — persisted via SharedPreferences ──────────────────────────────

class DailyGoalNotifier extends StateNotifier<int> {
  DailyGoalNotifier() : super(StepGoals.defaultDailyGoal) {
    _load();
  }

  static const prefsKey = 'daily_goal';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(prefsKey);
    if (saved != null) state = saved;
  }

  Future<void> setGoal(int goal) async {
    final clamped = goal.clamp(StepGoals.minDailyGoal, StepGoals.maxDailyGoal);
    state = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefsKey, clamped);
  }
}

final dailyGoalProvider = StateNotifierProvider<DailyGoalNotifier, int>(
  (_) => DailyGoalNotifier(),
);

// ── User body weight — persisted via SharedPreferences ───────────────────────

class UserWeightNotifier extends StateNotifier<double> {
  UserWeightNotifier() : super(65.0) {
    _load();
  }

  static const prefsKey = 'user_weight_kg';
  static const double minWeight = 30.0;
  static const double maxWeight = 200.0;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(prefsKey);
    if (saved != null) state = saved;
  }

  Future<void> setWeight(double kg) async {
    final clamped = kg.clamp(minWeight, maxWeight);
    state = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(prefsKey, clamped);
  }
}

final userWeightKgProvider = StateNotifierProvider<UserWeightNotifier, double>(
  (_) => UserWeightNotifier(),
);

// ── Derived metrics ───────────────────────────────────────────────────────────

/// Active calories burned, personalized by the user's body metrics.
/// Distance covered (from height/stride) × weight × walking expenditure.
final caloriesProvider = Provider<int>((ref) {
  final steps = ref.watch(stepCountProvider);
  final weight = ref.watch(userWeightKgProvider);
  final profile = ref.watch(userProfileProvider);
  return FitnessCalculator.activeCalories(
    steps: steps,
    weightKg: weight,
    heightCm: profile.heightCm,
    gender: profile.gender,
  );
});

/// Distance covered today in kilometres (height/gender-aware stride).
final distanceKmProvider = Provider<double>((ref) {
  final steps = ref.watch(stepCountProvider);
  final profile = ref.watch(userProfileProvider);
  return FitnessCalculator.distanceKm(steps, profile.heightCm, profile.gender);
});

/// Formatted distance string, respecting the user's unit preference.
final distanceProvider = Provider<String>((ref) {
  final km = ref.watch(distanceKmProvider);
  final units = ref.watch(userProfileProvider).units;
  return Formatters.distanceLabelSmart(km, units);
});

final progressProvider = Provider<double>((ref) {
  final steps = ref.watch(stepCountProvider);
  final goal = ref.watch(dailyGoalProvider);
  return (steps / goal).clamp(0.0, 1.0);
});

// Last 7 days — today's value is live from BLE/mock
final weeklyStepsProvider = Provider<List<int>>((ref) {
  return [6800, 11200, 9400, 4100, 12500, 8900, ref.watch(stepCountProvider)];
});

final goalReachedProvider = Provider<bool>((ref) {
  return ref.watch(stepCountProvider) >= ref.watch(dailyGoalProvider);
});

// ── Streak — real, persisted, derived from SQLite `daily_steps` ─────────────
// Used by the notification detectors. The cosmetic per-screen streak numbers
// (home/stats/profile) keep their existing independent inline calculations —
// this is a separate, more accurate source of truth purely for deciding when
// to fire streak notifications and for tracking the all-time record.

class StreakState {
  const StreakState({this.current = 0, this.longest = 0});
  final int current;
  final int longest;
}

class StreakNotifier extends StateNotifier<StreakState> {
  StreakNotifier(this._ref, this._prefs) : super(_load(_prefs)) {
    _checkRollover();
    _ref.listen<int>(stepCountProvider, (_, steps) => _onStepsChanged(steps));
  }

  final Ref _ref;
  final SharedPreferences _prefs;

  static const currentKey = 'streak_current';
  static const longestKey = 'streak_longest';
  static const lastSeenDateKey = 'streak_last_seen_date';

  static StreakState _load(SharedPreferences prefs) => StreakState(
    current: prefs.getInt(currentKey) ?? 0,
    longest: prefs.getInt(longestKey) ?? 0,
  );

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _parseYmd(String s) {
    final p = s.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  Future<void> _onStepsChanged(int steps) async {
    await _ref
        .read(sessionRepositoryProvider)
        .recordDailyTotal(
          DateTime.now(),
          steps,
          goal: _ref.read(dailyGoalProvider),
        );
    // Best-effort, throttled internally — pushes Strolla's running total
    // into Health Connect/HealthKit so other apps can be set to prefer it.
    // No-ops on its own if write access was never granted.
    unawaited(
      _ref
          .read(healthServiceProvider)
          .pushLiveSteps(
            todaySteps: steps,
            todayDistanceMeters: _ref.read(distanceKmProvider) * 1000,
            todayCalories: _ref.read(caloriesProvider),
          ),
    );
    await _checkRollover();
  }

  /// Detects the calendar date advancing since we last checked and, if so,
  /// finalizes the streak for the day(s) that passed unseen.
  Future<void> _checkRollover() async {
    final today = DateTime.now();
    final todayKey = _ymd(today);
    final lastSeen = _prefs.getString(lastSeenDateKey);

    if (lastSeen == null) {
      await _prefs.setString(lastSeenDateKey, todayKey);
      return;
    }
    if (lastSeen == todayKey) return;

    final lastSeenDate = _parseYmd(lastSeen);
    final steps = await _ref
        .read(sessionRepositoryProvider)
        .getStepsForDate(lastSeenDate);
    final goal = _ref.read(dailyGoalProvider);
    _applyCompletedDay(metGoal: steps >= goal);

    if (today.difference(lastSeenDate).inDays > 1) {
      // One or more days with no app activity in between — no data means
      // the goal can't have been met, so the streak is broken regardless
      // of what happened on lastSeenDate.
      _applyCompletedDay(metGoal: false);
    }

    await _prefs.setString(lastSeenDateKey, todayKey);
  }

  void _applyCompletedDay({required bool metGoal}) {
    final newCurrent = metGoal ? state.current + 1 : 0;
    final newLongest = newCurrent > state.longest ? newCurrent : state.longest;
    state = StreakState(current: newCurrent, longest: newLongest);
    _prefs.setInt(currentKey, newCurrent);
    _prefs.setInt(longestKey, newLongest);
  }
}

final streakProvider = StateNotifierProvider<StreakNotifier, StreakState>(
  (ref) => StreakNotifier(ref, ref.watch(sharedPreferencesProvider)),
);

// Today's step distribution by hour — 24 values (index = hour 0–23).
// Realistic pattern: low overnight, morning commute peak, lunch dip,
// evening walk peak. Today's live count is reflected in the current hour.
final todayHourlyStepsProvider = Provider<List<int>>((ref) {
  final liveSteps = ref.watch(stepCountProvider);
  final now = DateTime.now().hour;

  final hours = [
    0, 0, 0, 0, 0, 0, // 12AM–5AM: asleep
    220, 970, 1380, 640, 290, 210, // 6AM–11AM: morning + commute
    820, 1240, 390, 180, 250, 460, // 12PM–5PM: lunch walk + desk
    880, 1360, 800, 360, 100, 0, // 6PM–11PM: evening walk + wind-down
  ];

  // Replace current hour with today's live step count clamped to chart scale
  hours[now] = (liveSteps / 10).clamp(0, 1800).toInt();
  return hours;
});
