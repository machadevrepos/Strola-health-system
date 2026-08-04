import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/services/firebase_client.dart';
import 'package:strola_health/data/repositories/public_profile_repository.dart';
import 'package:strola_health/domain/entities/challenge.dart';
import 'package:strola_health/domain/entities/public_profile.dart';

/// Real Firestore-backed challenges. `challenges/{id}` is readable by any
/// signed-in user (firestore.rules) — "private" is an invite/UI concept, not
/// a read restriction — so "your private challenges" is derived by finding
/// challenges the caller has actually joined (via the `participants`
/// collectionGroup), not by querying `visibility == 'private'` directly.
class ChallengeRepository {
  ChallengeRepository(this._firestore, this._auth, this._profiles);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PublicProfileRepository _profiles;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _challenges =>
      _firestore.collection('challenges');

  Future<Challenge?> _hydrate(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    if (!doc.exists) return null;
    final participant = await doc.reference
        .collection('participants')
        .doc(_uid)
        .get();
    final pData = participant.data();
    final isJoined = pData != null && pData['left_at'] == null;
    return Challenge.fromFirestore(
      doc.data()!,
      doc.id,
      isJoined: isJoined,
      myStepsInChallenge: (pData?['steps'] as num?)?.toInt() ?? 0,
    );
  }

  Future<Challenge?> getChallenge(String id) async {
    final doc = await _challenges.doc(id).get();
    return _hydrate(doc);
  }

  /// The current featured official challenge ("Challenge of the Month").
  Future<Challenge?> getCurrentOfficialChallenge() async {
    final snap = await _challenges
        .where('type', isEqualTo: 'official_monthly')
        .where('status', isEqualTo: 'published')
        .orderBy('start_date', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _hydrate(snap.docs.first);
  }

  /// Live version of [getCurrentOfficialChallenge] — same query, `.snapshots()`
  /// instead of `.get()`, so a challenge the admin panel just made official
  /// appears immediately without the app needing to re-fetch. `_hydrate`
  /// does its own extra `participants` read per emission, which is fine at
  /// this call frequency (once per real change to the official challenge,
  /// not per keystroke).
  Stream<Challenge?> watchCurrentOfficialChallenge() {
    return _challenges
        .where('type', isEqualTo: 'official_monthly')
        .where('status', isEqualTo: 'published')
        .orderBy('start_date', descending: true)
        .limit(1)
        .snapshots()
        .asyncMap((snap) async {
          if (snap.docs.isEmpty) return null;
          return _hydrate(snap.docs.first);
        });
  }

  /// The most recently archived official challenge — powers "Last Month's
  /// Winners". Null when none has ever completed yet (real state, not an
  /// error — nothing to fabricate a winner for).
  Future<Challenge?> getLastCompletedOfficialChallenge() async {
    final snap = await _challenges
        .where('type', isEqualTo: 'official_monthly')
        .where('status', isEqualTo: 'archived')
        .orderBy('end_date', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _hydrate(snap.docs.first);
  }

  /// Challenges (of either visibility) the caller has actually joined and
  /// not left — "Your Private Challenges" / "Your Completed Challenges" both
  /// filter this by `status` client-side.
  Future<List<Challenge>> getMyChallenges() async {
    final participantDocs = await _firestore
        .collectionGroup('participants')
        .where('user_id', isEqualTo: _uid)
        .where('left_at', isNull: true)
        .get();
    if (participantDocs.docs.isEmpty) return const [];

    final challengeIds = participantDocs.docs
        .map((d) => d.reference.parent.parent!.id)
        .toSet()
        .toList();

    final challenges = <Challenge>[];
    for (var i = 0; i < challengeIds.length; i += 10) {
      final chunk = challengeIds.sublist(
        i,
        (i + 10).clamp(0, challengeIds.length),
      );
      final snap = await _challenges
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final hydrated = await _hydrate(doc);
        if (hydrated != null) challenges.add(hydrated);
      }
    }
    return challenges;
  }

  /// Live leaderboard for one challenge, resolved with real identities and
  /// sorted by steps descending — `showPercent` UIs re-sort client-side by
  /// `goalCompletionPct` instead of re-querying.
  Future<List<ChallengeLeaderboardEntry>> getLeaderboard(
    String challengeId, {
    int limit = 50,
  }) async {
    final snap = await _challenges
        .doc(challengeId)
        .collection('participants')
        .where('left_at', isNull: true)
        .orderBy('steps', descending: true)
        .limit(limit)
        .get();
    if (snap.docs.isEmpty) return const [];

    final userIds = snap.docs.map((d) => d.data()['user_id'] as String).toSet();
    final profiles = {
      for (final p in await _profiles.getMany(userIds)) p.id: p,
    };

    return [
      for (final doc in snap.docs)
        ChallengeLeaderboardEntry(
          userId: doc.data()['user_id'] as String,
          profile:
              profiles[doc.data()['user_id']] ??
              PublicProfile.unknown(doc.data()['user_id'] as String),
          steps: (doc.data()['steps'] as num?)?.toInt() ?? 0,
          lockedDailyGoal:
              (doc.data()['locked_daily_goal'] as num?)?.toInt() ?? 10000,
          isMe: doc.data()['user_id'] == _uid,
        ),
    ];
  }

  /// Denormalized top-N straight off the challenge doc (`leaderboard_top`,
  /// maintained by a backend trigger) — used for a completed/archived
  /// challenge where the live `participants` subcollection may no longer be
  /// the authoritative final standing.
  Future<List<ChallengeLeaderboardEntry>> getLeaderboardTop(
    Challenge challenge,
  ) async {
    final doc = await _challenges.doc(challenge.id).get();
    final raw = (doc.data()?['leaderboard_top'] as List?) ?? const [];
    if (raw.isEmpty) return const [];
    final entries = asMapList(raw);
    final userIds = entries.map((e) => e['user_id'] as String).toSet();
    final profiles = {
      for (final p in await _profiles.getMany(userIds)) p.id: p,
    };
    return [
      for (final e in entries)
        ChallengeLeaderboardEntry(
          userId: e['user_id'] as String,
          profile:
              profiles[e['user_id']] ??
              PublicProfile.unknown(e['user_id'] as String),
          steps: (e['steps'] as num?)?.toInt() ?? 0,
          lockedDailyGoal: (e['locked_daily_goal'] as num?)?.toInt() ?? 10000,
          isMe: e['user_id'] == _uid,
        ),
    ];
  }

  Future<void> joinChallenge({String? challengeId, String? inviteCode}) =>
      FirebaseClient.call('joinChallenge', {
        if (challengeId != null) 'challengeId': challengeId,
        if (inviteCode != null) 'inviteCode': inviteCode,
      });

  Future<void> leaveChallenge(String challengeId) =>
      FirebaseClient.call('leaveChallenge', {'challengeId': challengeId});

  /// [startDate]/[endDate] as `YYYY-MM-DD`, matching the backend's stored
  /// format. Always creates a private challenge (only the admin panel can
  /// create an official one) — the creator auto-joins server-side.
  /// `inviteCode` is non-null for a private (`isPublic: false`) challenge —
  /// the backend generates it server-side and it's the only way anyone else
  /// can find/join a private challenge, so callers must surface it to the
  /// user after creation.
  Future<({String id, String? inviteCode})> createChallenge({
    required String title,
    String? description,
    required int goalSteps,
    required String startDate,
    required String endDate,
    String? badgeEmoji,
    int? accentColorValue,
    required bool isPublic,
    required WinnerType winnerType,
  }) async {
    final result = await FirebaseClient.call('createChallenge', {
      'title': title,
      if (description != null) 'description': description,
      'goalSteps': goalSteps,
      'startDate': startDate,
      'endDate': endDate,
      if (badgeEmoji != null) 'badgeEmoji': badgeEmoji,
      if (accentColorValue != null) 'accentColorValue': accentColorValue,
      'visibility': isPublic ? 'public' : 'private',
      'winnerType': winnerType == WinnerType.goalCompletionPct
          ? 'goal_completion_pct'
          : 'most_steps',
    });
    return (
      id: result['challengeId'] as String,
      inviteCode: result['inviteCode'] as String?,
    );
  }
}

final challengeRepositoryProvider = Provider<ChallengeRepository>(
  (ref) => ChallengeRepository(
    FirebaseClient.firestore,
    FirebaseAuth.instance,
    ref.watch(publicProfileRepositoryProvider),
  ),
);
