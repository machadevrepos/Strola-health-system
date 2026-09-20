/// What a badge is awarded for — mirrors `BadgeRequirementMetric` in
/// strola_health_firebase/functions/src/lib/types.ts. `unknown` covers
/// retired metrics (`early_morning_sessions`, `community_posts`) and any
/// future value this client doesn't recognize yet — badges with this
/// metric have no matching section on the Achievements screen and are
/// dropped from display rather than crashing on an unhandled case.
enum BadgeRequirementMetric {
  totalSteps,
  sessionSteps,
  streakDays,
  challengesCompleted,
  unknown,
}

BadgeRequirementMetric badgeRequirementMetricFromString(String value) {
  switch (value) {
    case 'total_steps':
      return BadgeRequirementMetric.totalSteps;
    case 'session_steps':
      return BadgeRequirementMetric.sessionSteps;
    case 'streak_days':
      return BadgeRequirementMetric.streakDays;
    case 'challenges_completed':
      return BadgeRequirementMetric.challengesCompleted;
    default:
      return BadgeRequirementMetric.unknown;
  }
}

/// A badge definition (`badges/{badgeId}`) merged with whether the current
/// user has earned it (a matching `userBadges/{uid}_{badgeId}` doc exists).
/// Badges are only ever awarded server-side, so this is a read-only view —
/// there's no client-side "claim" mutation on this entity.
class AppBadge {
  const AppBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.requirementMetric,
    required this.requirementValue,
    required this.earned,
    this.earnedAt,
  });

  final String id;
  final String name;
  final String description;
  final String emoji;
  final BadgeRequirementMetric requirementMetric;
  final int requirementValue;
  final bool earned;

  /// When this user earned the badge (from `userBadges.awarded_at`) — null
  /// when [earned] is false, or for badges awarded before this field existed.
  final DateTime? earnedAt;

  /// [docId] is the Firestore document id (`badges/{badgeId}`) — used as a
  /// fallback when the document doesn't carry its own `id` field.
  factory AppBadge.fromFirestore(
    Map<String, dynamic> data,
    String docId, {
    required bool earned,
    DateTime? earnedAt,
  }) {
    return AppBadge(
      id: data['id'] as String? ?? docId,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '🏅',
      requirementMetric: badgeRequirementMetricFromString(
        data['requirement_metric'] as String? ?? '',
      ),
      requirementValue: (data['requirement_value'] as num?)?.toInt() ?? 0,
      earned: earned,
      earnedAt: earnedAt,
    );
  }
}
