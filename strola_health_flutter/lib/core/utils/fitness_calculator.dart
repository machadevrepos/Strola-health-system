import 'package:strola_health/domain/entities/user_profile.dart';

/// Physiologically-grounded conversions from raw step counts into distance and
/// calories, personalized by the user's height, weight, gender and age.
///
/// These replace the old flat `steps × constant` estimates so the numbers
/// actually reflect the person using the app.
class FitnessCalculator {
  FitnessCalculator._();

  // ── Stride & distance ──────────────────────────────────────────────────────

  /// Walking stride length in metres, derived from height with a small
  /// gender adjustment (men ~0.415·h, women ~0.413·h).
  static double strideMeters(double heightCm, Gender gender) {
    final factor = switch (gender) {
      Gender.male => 0.415,
      Gender.female => 0.413,
      _ => 0.414,
    };
    return heightCm * factor / 100.0;
  }

  static double distanceMeters(int steps, double heightCm, Gender gender) =>
      steps * strideMeters(heightCm, gender);

  static double distanceKm(int steps, double heightCm, Gender gender) =>
      distanceMeters(steps, heightCm, gender) / 1000.0;

  // ── Calories ────────────────────────────────────────────────────────────────

  /// Active calories burned by the given steps.
  ///
  /// Uses gross walking expenditure (~0.79 kcal per kg of body-weight per km
  /// at a moderate pace), scaled by the distance those steps actually cover —
  /// which itself depends on stride/height. So a taller, heavier person burns
  /// more for the same step count, as expected.
  static int activeCalories({
    required int steps,
    required double weightKg,
    required double heightCm,
    required Gender gender,
  }) {
    final km = distanceKm(steps, heightCm, gender);
    return (0.79 * weightKg * km).round();
  }

  /// Basal Metabolic Rate (kcal/day) — Mifflin-St Jeor equation.
  static double bmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return switch (gender) {
      Gender.male => base + 5,
      Gender.female => base - 161,
      _ => base - 78, // midpoint of the male/female constants
    };
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static int ageFromDob(DateTime? dob) {
    if (dob == null) return 30;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age.clamp(5, 120);
  }

  // ── Unit conversions ──────────────────────────────────────────────────────────

  static double kgToLb(double kg) => kg * 2.2046226218;
  static double lbToKg(double lb) => lb / 2.2046226218;

  /// Returns (feet, inches) for a height in centimetres.
  static (int, int) cmToFtIn(double cm) {
    final totalInches = (cm / 2.54).round();
    return (totalInches ~/ 12, totalInches % 12);
  }

  static double ftInToCm(int feet, int inches) => ((feet * 12) + inches) * 2.54;
}
