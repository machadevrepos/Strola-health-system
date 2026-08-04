import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/domain/entities/app_badge.dart';

/// Reads badge definitions and this user's earned set directly from
/// Firestore (`badges` / `userBadges` — see
/// strola_health_firebase/functions/src/lib/types.ts `Badge`/`UserBadge`).
/// Badges are only ever written server-side by the admin-only `awardBadge`
/// function, so this repository is read-only.
class BadgeRepository {
  BadgeRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Every enabled + visible badge, each merged with whether the signed-in
  /// user has earned it. Returns an empty list (rather than throwing) when
  /// no one is signed in, since the Achievements screen has nothing
  /// meaningful to show in that state either way.
  Future<List<AppBadge>> getBadges() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const [];

    final badgesQuery = _firestore
        .collection('badges')
        .where('enabled', isEqualTo: true)
        .where('visible', isEqualTo: true)
        .get();
    final userBadgesQuery = _firestore
        .collection('userBadges')
        .where('user_id', isEqualTo: uid)
        .get();

    final results = await Future.wait([badgesQuery, userBadgesQuery]);
    final badgesSnapshot = results[0];
    final userBadgesSnapshot = results[1];

    final earnedBadgeIds = userBadgesSnapshot.docs
        .map((doc) => doc.data()['badge_id'] as String?)
        .whereType<String>()
        .toSet();

    return [
      for (final doc in badgesSnapshot.docs)
        AppBadge.fromFirestore(
          doc.data(),
          doc.id,
          earned: earnedBadgeIds.contains(
            doc.data()['id'] as String? ?? doc.id,
          ),
        ),
    ];
  }
}

final badgeRepositoryProvider = Provider<BadgeRepository>(
  (_) => BadgeRepository(FirebaseFirestore.instance, FirebaseAuth.instance),
);
