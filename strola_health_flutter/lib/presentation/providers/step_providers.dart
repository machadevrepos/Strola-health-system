import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strola_health/core/constants/step_goals.dart';
import 'package:strola_health/core/utils/fitness_calculator.dart';
import 'package:strola_health/core/utils/formatters.dart';
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

  static const _key = 'daily_goal';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_key);
    if (saved != null) state = saved;
  }

  Future<void> setGoal(int goal) async {
    final clamped = goal.clamp(StepGoals.minDailyGoal, StepGoals.maxDailyGoal);
    state = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, clamped);
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

  static const _key = 'user_weight_kg';
  static const double minWeight = 30.0;
  static const double maxWeight = 200.0;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_key);
    if (saved != null) state = saved;
  }

  Future<void> setWeight(double kg) async {
    final clamped = kg.clamp(minWeight, maxWeight);
    state = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, clamped);
  }
}

final userWeightKgProvider =
    StateNotifierProvider<UserWeightNotifier, double>(
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

// Today's step distribution by hour — 24 values (index = hour 0–23).
// Realistic pattern: low overnight, morning commute peak, lunch dip,
// evening walk peak. Today's live count is reflected in the current hour.
final todayHourlyStepsProvider = Provider<List<int>>((ref) {
  final liveSteps = ref.watch(stepCountProvider);
  final now = DateTime.now().hour;

  final hours = [
    0, 0, 0, 0, 0, 0,              // 12AM–5AM: asleep
    220, 970, 1380, 640, 290, 210, // 6AM–11AM: morning + commute
    820, 1240, 390, 180, 250, 460, // 12PM–5PM: lunch walk + desk
    880, 1360, 800, 360, 100, 0,   // 6PM–11PM: evening walk + wind-down
  ];

  // Replace current hour with today's live step count clamped to chart scale
  hours[now] = (liveSteps / 10).clamp(0, 1800).toInt();
  return hours;
});
