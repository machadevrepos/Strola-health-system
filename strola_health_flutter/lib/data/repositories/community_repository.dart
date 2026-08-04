import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/services/firebase_client.dart';
import 'package:strola_health/data/repositories/public_profile_repository.dart';
import 'package:strola_health/domain/entities/community_post.dart';
import 'package:strola_health/domain/entities/public_profile.dart';

/// One page of the feed — a keyset/cursor pagination result (the same
/// pattern Instagram/Twitter/Reddit feeds use: "give me N items after this
/// specific item", never "give me page 7"). Offset-based paging would mean
/// asking Firestore to skip an ever-growing number of documents as someone
/// scrolls deeper, which gets slower with every page; a cursor is a fixed
/// cost regardless of how far in the feed you are.
class PostsPage {
  const PostsPage({
    required this.posts,
    required this.cursor,
    required this.hasMore,
  });

  final List<CommunityPost> posts;

  /// Opaque cursor for `getPostsPage(startAfter: ...)`'s next call —
  /// nothing about its shape should leak past this repository.
  final DocumentSnapshot<Map<String, dynamic>>? cursor;

  /// True if this page was full (`posts.length == limit`), meaning there's
  /// *probably* more — the cheap, standard heuristic (skips an extra COUNT
  /// query just to know for certain).
  final bool hasMore;
}

/// Real Firestore-backed community feed. Posts/comments are written via
/// callables (createPost/addComment/etc. — see
/// strola_health_firebase/functions/src/community); likes are the one
/// direct-client-write exception in firestore.rules (owner-only
/// `likes/{uid}` create/delete), so those go straight to Firestore.
///
/// Post images: the composer uploads directly to Storage (see
/// FirebaseClient.uploadCommunityPostImage) and passes the resulting
/// download URL through `createPost` as `imageUrl` — no callable in the
/// upload path itself, matching the storage.rules owner-only write.
class CommunityRepository {
  CommunityRepository(this._firestore, this._auth, this._profiles);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PublicProfileRepository _profiles;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('communityPosts');

  DateTime? _timestamp(Object? v) => v is Timestamp ? v.toDate() : null;

  /// One page of the feed, newest first (official posts pinned to the top).
  /// [startAfter] is the previous page's [PostsPage.cursor] — omit it for
  /// the first page.
  ///
  /// Fetches the "did I like this?" flag for the whole page in a single
  /// batched query (`_likedPostIds`) instead of one Firestore read per
  /// post — the N+1 pattern the old `getPosts()` had (`Future.wait` over
  /// one `.get()` per post) was the actual reason the feed felt slow: 20
  /// individual round trips serialize into far more wall-clock time than
  /// the one query that replaced them, even though both eventually finish.
  Future<PostsPage> getPostsPage({
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    var query = _posts
        .where('moderation.hidden', isEqualTo: false)
        .orderBy('pinned', descending: true)
        .orderBy('timestamp', descending: true)
        .limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snap = await query.get();
    if (snap.docs.isEmpty) {
      return PostsPage(posts: const [], cursor: startAfter, hasMore: false);
    }

    final postIds = snap.docs.map((d) => d.id).toList();
    final authorIds = snap.docs
        .map((d) => d.data()['author_id'] as String)
        .toSet();
    // Independent reads — run together rather than one after the other.
    final results = await Future.wait([
      _profiles.getMany(authorIds),
      _likedPostIds(postIds),
    ]);
    final profiles = {
      for (final p in results[0] as List<PublicProfile>) p.id: p,
    };
    final liked = results[1] as Set<String>;

    final posts = [
      for (final doc in snap.docs)
        CommunityPost.fromFirestore(
          {...doc.data(), 'timestamp': _timestamp(doc.data()['timestamp'])},
          doc.id,
          author:
              profiles[doc.data()['author_id']] ??
              PublicProfile.unknown(doc.data()['author_id'] as String),
          isLiked: liked.contains(doc.id),
          currentUserId: _uid,
        ),
    ];

    return PostsPage(
      posts: posts,
      cursor: snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  }

  /// Which of [postIds] the current user has liked — one
  /// `collectionGroup('likes')` query filtered by exact document path
  /// (`FieldPath.documentId whereIn [...]`) instead of a separate
  /// `likes/{uid}` existence check per post. `whereIn` caps at 30 values,
  /// so this chunks defensively even though today's page size (20) always
  /// fits in a single call.
  Future<Set<String>> _likedPostIds(List<String> postIds) async {
    if (postIds.isEmpty) return const {};
    final liked = <String>{};
    for (var i = 0; i < postIds.length; i += 30) {
      final chunk = postIds.skip(i).take(30);
      final refs = [
        for (final id in chunk) _posts.doc(id).collection('likes').doc(_uid),
      ];
      final snap = await _firestore
          .collectionGroup('likes')
          .where(FieldPath.documentId, whereIn: refs)
          .get();
      liked.addAll(snap.docs.map((d) => d.reference.parent.parent!.id));
    }
    return liked;
  }

  Future<void> toggleLike(String postId, {required bool currentlyLiked}) async {
    final ref = _posts.doc(postId).collection('likes').doc(_uid);
    if (currentlyLiked) {
      await ref.delete();
    } else {
      await ref.set({
        'user_id': _uid,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<String> createPost(
    String content, {
    int? stepCount,
    String? badgeEmoji,
    String? imageUrl,
  }) async {
    final result = await FirebaseClient.call('createPost', {
      'content': content,
      if (stepCount != null) 'stepCount': stepCount,
      if (badgeEmoji != null) 'badgeEmoji': badgeEmoji,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
    return result['postId'] as String;
  }

  Future<void> deletePost(String postId) =>
      FirebaseClient.call('deletePost', {'postId': postId});

  Future<List<CommunityComment>> getComments(String postId) async {
    final snap = await _posts
        .doc(postId)
        .collection('comments')
        .where('hidden', isEqualTo: false)
        .orderBy('timestamp')
        .get();
    if (snap.docs.isEmpty) return const [];

    final authorIds = snap.docs
        .map((d) => d.data()['author_id'] as String)
        .toSet();
    final profiles = {
      for (final p in await _profiles.getMany(authorIds)) p.id: p,
    };

    return [
      for (final doc in snap.docs)
        CommunityComment.fromFirestore(
          {...doc.data(), 'timestamp': _timestamp(doc.data()['timestamp'])},
          doc.id,
          author:
              profiles[doc.data()['author_id']] ??
              PublicProfile.unknown(doc.data()['author_id'] as String),
          currentUserId: _uid,
        ),
    ];
  }

  Future<void> addComment(String postId, String content) =>
      FirebaseClient.call('addComment', {'postId': postId, 'content': content});

  Future<void> deleteComment(String postId, String commentId) =>
      FirebaseClient.call('deleteComment', {
        'postId': postId,
        'commentId': commentId,
      });

  /// [targetType] is `'post'` or `'user'` — matches the backend's
  /// `ReportTargetType` exactly (reportContent.ts).
  Future<void> reportContent({
    required String targetType,
    required String targetId,
    required String category,
    required String reason,
  }) => FirebaseClient.call('reportContent', {
    'targetType': targetType,
    'targetId': targetId,
    'category': category,
    'reason': reason,
  });
}

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => CommunityRepository(
    FirebaseClient.firestore,
    FirebaseAuth.instance,
    ref.watch(publicProfileRepositoryProvider),
  ),
);
