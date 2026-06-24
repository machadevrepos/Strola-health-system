import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── Pure formula tests (no BLE, no SharedPreferences, no platform channels) ─

  group('Calorie formula', () {
    double calcCalories(int steps, double weightKg) =>
        steps * weightKg * 0.000571;

    test('1000 steps at 70 kg = ~39.97 kcal', () {
      expect(calcCalories(1000, 70.0).toInt(), 39);
    });

    test('0 steps = 0 kcal', () {
      expect(calcCalories(0, 70.0).toInt(), 0);
    });

    test('10000 steps at 65 kg = ~371 kcal', () {
      expect(calcCalories(10000, 65.0).toInt(), 371);
    });
  });

  group('Progress formula', () {
    double calcProgress(int steps, int goal) =>
        (steps / goal).clamp(0.0, 1.0);

    test('0 steps / 10000 goal = 0.0', () {
      expect(calcProgress(0, 10000), 0.0);
    });

    test('5000 / 10000 = 0.5', () {
      expect(calcProgress(5000, 10000), 0.5);
    });

    test('10000 / 10000 = 1.0', () {
      expect(calcProgress(10000, 10000), 1.0);
    });

    test('clamps at 1.0 when over goal', () {
      expect(calcProgress(20000, 10000), 1.0);
    });
  });

  group('Goal reached logic', () {
    bool goalReached(int steps, int goal) => steps >= goal;

    test('9999 steps, goal 10000 → not reached', () {
      expect(goalReached(9999, 10000), isFalse);
    });

    test('exactly 10000 steps → reached', () {
      expect(goalReached(10000, 10000), isTrue);
    });

    test('over goal → reached', () {
      expect(goalReached(15000, 10000), isTrue);
    });
  });

  group('Distance formula', () {
    String formatDistance(int steps) {
      final meters = steps * 0.762;
      if (meters >= 1000) {
        return '${(meters / 1000).toStringAsFixed(1)} km';
      }
      return '${meters.toInt()} m';
    }

    test('1000 steps = 762 m', () {
      expect(formatDistance(1000), '762 m');
    });

    test('2000 steps = 1.5 km', () {
      expect(formatDistance(2000), '1.5 km');
    });

    test('10000 steps = 7.6 km', () {
      expect(formatDistance(10000), '7.6 km');
    });
  });

  group('Milestone thresholds', () {
    const milestones = [2500, 5000, 7500, 10000];

    test('2500 steps unlocks first milestone', () {
      expect(milestones.where((m) => 2500 >= m).length, 1);
    });

    test('7500 steps unlocks three milestones', () {
      expect(milestones.where((m) => 7500 >= m).length, 3);
    });

    test('9999 steps — final milestone not yet reached', () {
      expect(milestones.where((m) => 9999 >= m).length, 3);
    });

    test('10000 steps — all milestones reached', () {
      expect(milestones.where((m) => 10000 >= m).length, 4);
    });
  });
}
