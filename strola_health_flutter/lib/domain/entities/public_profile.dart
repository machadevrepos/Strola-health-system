/// Resolves a uid to a display identity — `users/{uid}` is owner/admin-only
/// in firestore.rules, so every screen that needs to show *someone else's*
/// name (post/comment authorship, challenge leaderboards, friend requests)
/// goes through the `getPublicProfiles` callable instead. `showStats` mirrors
/// the target's own `privacy.public_profile` toggle — stats fields are null
/// when it's off, identity fields are always present.
class PublicProfile {
  const PublicProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.photoUrl,
    required this.showStats,
    required this.streakCurrent,
    required this.streakLongest,
    required this.lifetimeSteps,
  });

  final String id;
  final String name;
  final String username;
  final String? photoUrl;
  final bool showStats;
  final int? streakCurrent;
  final int? streakLongest;
  final int? lifetimeSteps;

  /// Falls back to username, then a generic label — `name` can be empty for
  /// a user who never finished onboarding.
  String get displayName {
    if (name.trim().isNotEmpty) return name;
    if (username.trim().isNotEmpty) return username;
    return 'Strolla User';
  }

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName
        .substring(0, displayName.length >= 2 ? 2 : 1)
        .toUpperCase();
  }

  factory PublicProfile.fromMap(Map<String, dynamic> map) {
    return PublicProfile(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      username: map['username'] as String? ?? '',
      photoUrl: map['photo_url'] as String?,
      showStats: map['show_stats'] as bool? ?? false,
      streakCurrent: (map['streak_current'] as num?)?.toInt(),
      streakLongest: (map['streak_longest'] as num?)?.toInt(),
      lifetimeSteps: (map['lifetime_steps'] as num?)?.toInt(),
    );
  }

  /// Placeholder for a uid that `getPublicProfiles` didn't return anything
  /// for (deleted/banned account) — keeps callers from having to null-check
  /// everywhere a post/comment's author has since disappeared.
  factory PublicProfile.unknown(String id) => PublicProfile(
    id: id,
    name: 'Strolla User',
    username: '',
    photoUrl: null,
    showStats: false,
    streakCurrent: null,
    streakLongest: null,
    lifetimeSteps: null,
  );
}
