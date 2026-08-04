import 'package:strola_health/domain/entities/public_profile.dart';

/// Mirrors the backend's `ChallengeType`/`ChallengeVisibility`/
/// `ChallengeStatus`/`WinnerType` (functions/src/lib/types.ts) — string
/// values match exactly, this is what's stored in Firestore.
enum ChallengeType { officialMonthly, private }

enum ChallengeVisibility { public, private }

enum ChallengeStatus { draft, published, archived }

enum WinnerType { mostSteps, goalCompletionPct }

ChallengeType _typeFromString(String v) => v == 'official_monthly'
    ? ChallengeType.officialMonthly
    : ChallengeType.private;

ChallengeVisibility _visibilityFromString(String v) =>
    v == 'public' ? ChallengeVisibility.public : ChallengeVisibility.private;

ChallengeStatus _statusFromString(String v) => switch (v) {
  'published' => ChallengeStatus.published,
  'archived' => ChallengeStatus.archived,
  _ => ChallengeStatus.draft,
};

WinnerType _winnerTypeFromString(String v) => v == 'goal_completion_pct'
    ? WinnerType.goalCompletionPct
    : WinnerType.mostSteps;

/// A single leaderboard entry — either from `challenges/{id}/participants`
/// (live, joined by the caller) or a challenge's denormalized
/// `leaderboard_top` (already the shape a completed challenge's winners
/// come from). `profile` is resolved separately via
/// `getPublicProfiles`/`PublicProfileRepository` since `user_id` alone isn't
/// displayable.
class ChallengeLeaderboardEntry {
  const ChallengeLeaderboardEntry({
    required this.userId,
    required this.profile,
    required this.steps,
    required this.lockedDailyGoal,
    required this.isMe,
  });

  final String userId;
  final PublicProfile profile;
  final int steps;
  final int lockedDailyGoal;
  final bool isMe;

  String get name => profile.displayName;
  String get initials => profile.initials;

  int get goalCompletionPct =>
      lockedDailyGoal > 0 ? ((steps / lockedDailyGoal) * 100).round() : 0;
}

/// Mirrors `challenges/{id}` (`Challenge` in
/// strola_health_firebase/functions/src/lib/types.ts). `isJoined` and
/// `myStepsInChallenge` are populated by the repository from the caller's
/// own `participants/{uid}` doc (null steps/not-joined when absent), not
/// stored on the challenge document itself.
class Challenge {
  const Challenge({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.goalSteps,
    required this.startDate,
    required this.endDate,
    required this.badgeEmoji,
    required this.accentColorValue,
    required this.visibility,
    required this.isOfficial,
    required this.inviteCode,
    required this.imageUrl,
    required this.rules,
    required this.winnerType,
    required this.status,
    required this.winnerUserId,
    required this.isJoined,
    required this.myStepsInChallenge,
  });

  final String id;
  final ChallengeType type;
  final String title;
  final String description;
  final int goalSteps;
  final DateTime startDate;
  final DateTime endDate;
  final String badgeEmoji;
  final int? accentColorValue;
  final ChallengeVisibility visibility;
  final bool isOfficial;
  final String? inviteCode;
  final String? imageUrl;
  final String? rules;
  final WinnerType winnerType;
  final ChallengeStatus status;
  final String? winnerUserId;
  final bool isJoined;
  final int myStepsInChallenge;

  int get daysLeft => endDate.difference(DateTime.now()).inDays.clamp(0, 9999);

  double get progress =>
      goalSteps == 0 ? 0 : (myStepsInChallenge / goalSteps).clamp(0.0, 1.0);

  Challenge copyWith({bool? isJoined, int? myStepsInChallenge}) => Challenge(
    id: id,
    type: type,
    title: title,
    description: description,
    goalSteps: goalSteps,
    startDate: startDate,
    endDate: endDate,
    badgeEmoji: badgeEmoji,
    accentColorValue: accentColorValue,
    visibility: visibility,
    isOfficial: isOfficial,
    inviteCode: inviteCode,
    imageUrl: imageUrl,
    rules: rules,
    winnerType: winnerType,
    status: status,
    winnerUserId: winnerUserId,
    isJoined: isJoined ?? this.isJoined,
    myStepsInChallenge: myStepsInChallenge ?? this.myStepsInChallenge,
  );

  factory Challenge.fromFirestore(
    Map<String, dynamic> data,
    String docId, {
    required bool isJoined,
    required int myStepsInChallenge,
  }) {
    DateTime parseDate(Object? v) =>
        DateTime.tryParse(v as String? ?? '') ?? DateTime.now();
    return Challenge(
      id: docId,
      type: _typeFromString(data['type'] as String? ?? 'private'),
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      goalSteps: (data['goal_steps'] as num?)?.toInt() ?? 0,
      startDate: parseDate(data['start_date']),
      endDate: parseDate(data['end_date']),
      badgeEmoji: data['badge_emoji'] as String? ?? '🏆',
      accentColorValue: (data['accent_color_value'] as num?)?.toInt(),
      visibility: _visibilityFromString(
        data['visibility'] as String? ?? 'private',
      ),
      isOfficial: data['is_official'] as bool? ?? false,
      inviteCode: data['invite_code'] as String?,
      imageUrl: data['image_url'] as String?,
      rules: data['rules'] as String?,
      winnerType: _winnerTypeFromString(
        data['winner_type'] as String? ?? 'most_steps',
      ),
      status: _statusFromString(data['status'] as String? ?? 'draft'),
      winnerUserId: data['winner_user_id'] as String?,
      isJoined: isJoined,
      myStepsInChallenge: myStepsInChallenge,
    );
  }
}
