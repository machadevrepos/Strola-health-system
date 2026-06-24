class ChallengeParticipant {
  const ChallengeParticipant({
    required this.name,
    required this.steps,
    required this.rank,
    this.avatarColor,
    this.isMe = false,
  });

  final String name;
  final int steps;
  final int rank;
  final int? avatarColor;
  final bool isMe;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }
}

class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.goalSteps,
    required this.startDate,
    required this.endDate,
    required this.participants,
    required this.mySteps,
    this.isJoined = false,
    this.badgeEmoji = '🏆',
    this.accentColorValue,
  });

  final String id;
  final String title;
  final String description;
  final int goalSteps;
  final DateTime startDate;
  final DateTime endDate;
  final List<ChallengeParticipant> participants;
  final int mySteps;
  final bool isJoined;
  final String badgeEmoji;
  final int? accentColorValue;

  double get progress => (mySteps / goalSteps).clamp(0.0, 1.0);

  int get daysLeft {
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff.clamp(0, 9999);
  }

  int get myRank {
    final me = participants.indexWhere((p) => p.isMe);
    return me >= 0 ? participants[me].rank : participants.length + 1;
  }

  List<ChallengeParticipant> get topThree => participants.take(3).toList();

  Challenge copyWith({bool? isJoined, int? mySteps}) => Challenge(
    id: id,
    title: title,
    description: description,
    goalSteps: goalSteps,
    startDate: startDate,
    endDate: endDate,
    participants: participants,
    mySteps: mySteps ?? this.mySteps,
    isJoined: isJoined ?? this.isJoined,
    badgeEmoji: badgeEmoji,
    accentColorValue: accentColorValue,
  );
}
