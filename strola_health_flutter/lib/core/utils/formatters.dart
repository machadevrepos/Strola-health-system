import 'package:strola_health/domain/entities/user_profile.dart';

class Formatters {
  Formatters._();

  static const double _kmToMiles = 0.621371;

  /// Converts a distance in kilometres to the user's preferred unit
  /// (kilometres for metric, miles for imperial).
  static double distanceFromKm(double km, UnitSystem units) =>
      units == UnitSystem.imperial ? km * _kmToMiles : km;

  /// The distance unit suffix for the user's preferred unit system.
  static String distanceUnitLabel(UnitSystem units) =>
      units == UnitSystem.imperial ? 'mi' : 'km';

  /// Formats a distance given in kilometres, respecting [units] —
  /// e.g. "5.2 km" or "3.2 mi".
  static String distanceLabel(double km, UnitSystem units, {int decimals = 1}) {
    final value = distanceFromKm(km, units);
    return '${value.toStringAsFixed(decimals)} ${distanceUnitLabel(units)}';
  }

  /// Formats a short distance given in kilometres, respecting [units] —
  /// drops to metres/yards below 1 km (or 0.1 mi) for readability.
  static String distanceLabelSmart(double km, UnitSystem units) {
    if (units == UnitSystem.imperial) {
      final miles = km * _kmToMiles;
      return miles >= 0.1
          ? '${miles.toStringAsFixed(2)} mi'
          : '${(miles * 1760).round()} yd';
    }
    return km >= 1 ? '${km.toStringAsFixed(1)} km' : '${(km * 1000).round()} m';
  }

  static String stepCount(int steps) {
    if (steps >= 1000) {
      final thousands = steps ~/ 1000;
      final remainder = steps % 1000;
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return steps.toString();
  }

  static String calories(int steps, {double weightKg = 65.0}) {
    final cal = (steps * weightKg * 0.000571).toInt();
    return '$cal kcal';
  }

  static String distance(int steps) {
    final meters = steps * 0.762;
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  static String fullDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  static String dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
  }
}
