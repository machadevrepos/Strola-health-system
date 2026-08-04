import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/services/firebase_client.dart';
import 'package:strola_health/data/repositories/public_profile_repository.dart';
import 'package:strola_health/domain/entities/friend.dart';
import 'package:strola_health/domain/entities/public_profile.dart';

/// Real Firestore-backed friends + blocking. Both `friendships/{id}` and
/// `blockedUsers/{id}` use deterministic uid-pair doc ids (see
/// friends.ts::pairId / blocks.ts) and firestore.rules gates reads by
/// matching the caller's own uid inside that id — a plain collection query
/// filtered to docs containing/prefixed with the caller's uid satisfies that
/// rule the same way a single-doc read would.
class FriendRepository {
  FriendRepository(this._firestore, this._auth, this._profiles);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PublicProfileRepository _profiles;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in.');
    return uid;
  }

  Future<List<FriendSummary>> getFriendships() async {
    final snap = await _firestore
        .collection('friendships')
        .where('uids', arrayContains: _uid)
        .get();
    if (snap.docs.isEmpty) return const [];

    final otherIds = <String>{};
    for (final doc in snap.docs) {
      final uids = (doc.data()['uids'] as List).cast<String>();
      otherIds.add(uids.firstWhere((id) => id != _uid));
    }
    final profiles = {
      for (final p in await _profiles.getMany(otherIds)) p.id: p,
    };

    return [
      for (final doc in snap.docs)
        FriendSummary(
          profile:
              profiles[(doc.data()['uids'] as List).cast<String>().firstWhere(
                (id) => id != _uid,
              )] ??
              PublicProfile.unknown('unknown'),
          status: doc.data()['status'] == 'accepted'
              ? FriendshipStatus.accepted
              : FriendshipStatus.pending,
          isIncomingRequest:
              doc.data()['status'] == 'pending' &&
              doc.data()['requested_by'] != _uid,
        ),
    ];
  }

  /// Null when no friendship/request exists yet between the two users.
  Future<FriendshipStatus?> getFriendshipWith(String otherUserId) async {
    final id = ([_uid, otherUserId]..sort()).join('_');
    final doc = await _firestore.collection('friendships').doc(id).get();
    if (!doc.exists) return null;
    return doc.data()!['status'] == 'accepted'
        ? FriendshipStatus.accepted
        : FriendshipStatus.pending;
  }

  Future<void> sendRequest(String targetUserId) =>
      FirebaseClient.call('sendFriendRequest', {'targetUserId': targetUserId});

  Future<void> respondRequest(String requesterId, bool accept) =>
      FirebaseClient.call('respondFriendRequest', {
        'requesterId': requesterId,
        'accept': accept,
      });

  Future<void> removeFriend(String friendUserId) =>
      FirebaseClient.call('removeFriend', {'friendUserId': friendUserId});

  Future<List<PublicProfile>> searchUsers(String query) =>
      _profiles.search(query);

  Future<Set<String>> getBlockedUserIds() async {
    final snap = await _firestore
        .collection('blockedUsers')
        .where('blocker_id', isEqualTo: _uid)
        .get();
    return snap.docs.map((d) => d.data()['blocked_id'] as String).toSet();
  }

  Future<void> blockUser(String userId) =>
      FirebaseClient.call('blockUser', {'blockedUserId': userId});

  Future<void> unblockUser(String userId) =>
      FirebaseClient.call('unblockUser', {'blockedUserId': userId});
}

final friendRepositoryProvider = Provider<FriendRepository>(
  (ref) => FriendRepository(
    FirebaseClient.firestore,
    FirebaseAuth.instance,
    ref.watch(publicProfileRepositoryProvider),
  ),
);
