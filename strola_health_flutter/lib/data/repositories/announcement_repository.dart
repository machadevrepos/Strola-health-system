import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strola_health/core/services/firebase_client.dart';
import 'package:strola_health/domain/entities/announcement.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';

/// Real Firestore-backed announcements. `announcements` is directly
/// client-readable for any signed-in user (firestore.rules), no callable
/// needed — audience targeting (`Announcement.audience`) isn't evaluated
/// server-side anywhere, so this repository does it itself against the
/// caller's own `users/{uid}` doc (self-readable).
class AnnouncementRepository {
  AnnouncementRepository(this._firestore, this._auth, this._prefs);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SharedPreferences _prefs;

  static const _dismissedKey = 'dismissed_announcement_ids';

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in.');
    return uid;
  }

  /// The single best-matching, not-yet-dismissed announcement to show right
  /// now, or null if none apply — real state (nothing published, nothing
  /// matches this user, or everything matching was already dismissed), not
  /// an error.
  Future<Announcement?> getActiveAnnouncement() async {
    final snap = await _firestore
        .collection('announcements')
        .where('active', isEqualTo: true)
        .orderBy('starts_at', descending: true)
        .limit(20)
        .get();
    if (snap.docs.isEmpty) return null;

    final now = DateTime.now();
    final candidates = snap.docs
        .map((d) => Announcement.fromFirestore(d.data(), d.id))
        .where((a) => !a.startsAt.isAfter(now))
        .where((a) => a.endsAt == null || !a.endsAt!.isBefore(now))
        .toList();
    if (candidates.isEmpty) return null;

    final dismissed = _prefs.getStringList(_dismissedKey)?.toSet() ?? const {};
    final undismissed = candidates
        .where((a) => !dismissed.contains(a.id))
        .toList();
    if (undismissed.isEmpty) return null;

    final userSnap = await _firestore.collection('users').doc(_uid).get();
    final user = userSnap.data();
    if (user == null) return null;

    for (final a in undismissed) {
      if (_matchesAudience(a, user)) return a;
    }
    return null;
  }

  bool _matchesAudience(Announcement a, Map<String, dynamic> user) {
    switch (a.audience) {
      case 'everyone':
        return true;
      case 'free':
        return (user['subscription'] as Map?)?['tier'] == 'free';
      case 'premium':
        return (user['subscription'] as Map?)?['tier'] == 'premium';
      case 'new_users':
        final createdAt = user['created_at'];
        if (createdAt == null) return false;
        final createdDate = (createdAt as dynamic).toDate() as DateTime;
        return DateTime.now().difference(createdDate).inDays <= 7;
      case 'beta_testers':
        return ((user['tags'] as List?) ?? const []).contains('beta_tester');
      case 'kickstarter_backers':
        return ((user['tags'] as List?) ?? const []).contains(
          'kickstarter_backer',
        );
      case 'iphone':
        return Platform.isIOS;
      case 'android':
        return Platform.isAndroid;
      case 'canada':
        return user['country'] == 'CA';
      case 'usa':
        return user['country'] == 'US';
      case 'app_version':
        // No package_info_plus dependency wired up to read the running
        // app's own version string — rather than guess, this audience
        // simply never matches yet (skipped, not fabricated as a match).
        return false;
      default:
        return false;
    }
  }

  Future<void> dismiss(String announcementId) async {
    final dismissed =
        _prefs.getStringList(_dismissedKey)?.toSet() ?? <String>{};
    dismissed.add(announcementId);
    await _prefs.setStringList(_dismissedKey, dismissed.toList());
  }
}

final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepository(
    FirebaseClient.firestore,
    FirebaseAuth.instance,
    ref.watch(sharedPreferencesProvider),
  ),
);

final activeAnnouncementProvider = FutureProvider<Announcement?>((ref) {
  return ref.watch(announcementRepositoryProvider).getActiveAnnouncement();
});
