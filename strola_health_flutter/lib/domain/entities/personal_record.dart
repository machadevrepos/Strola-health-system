/// Session-level personal record categories — checked against this device's
/// full local session history each time a workout is saved.
enum PersonalRecordCategory {
  longestDuration,
  farthestDistance,
  mostStepsInSession,
  bestPace,
}

extension PersonalRecordCategoryX on PersonalRecordCategory {
  String get label => switch (this) {
    PersonalRecordCategory.longestDuration => 'Longest Session',
    PersonalRecordCategory.farthestDistance => 'Farthest Distance',
    PersonalRecordCategory.mostStepsInSession => 'Most Steps in a Session',
    PersonalRecordCategory.bestPace => 'Best Pace',
  };
}
