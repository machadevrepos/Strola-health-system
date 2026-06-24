class StepGoals {
  StepGoals._();

  static const int defaultDailyGoal = 10000;
  static const int minDailyGoal = 1000;
  static const int maxDailyGoal = 30000;

  static const double caloriesPerStep = 0.04;
  static const double metersPerStep = 0.762;

  // Milestone thresholds that trigger celebrations
  static const List<int> milestones = [2500, 5000, 7500, 10000];

  static double stepsToCalories(int steps) => steps * caloriesPerStep;
  static double stepsToKm(int steps) => (steps * metersPerStep) / 1000;

  static String formatDistance(int steps) {
    final km = stepsToKm(steps);
    return km >= 1 ? '${km.toStringAsFixed(1)} km' : '${(km * 1000).toInt()} m';
  }
}
