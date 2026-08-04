import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/data/repositories/community_repository.dart';
import 'package:strola_health/data/repositories/friend_repository.dart';
import 'package:strola_health/domain/entities/community_post.dart';
import 'package:strola_health/domain/entities/public_profile.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';

// ── Blocked users ─────────────────────────────────────────────────────────────
// Real backend-uid-keyed block list (blockedUsers/{uid}_{targetUid} — see
// friend_repository.dart), superseding the old local-only, display-name-keyed
// version. Loaded once per session; block/unblock optimistically update local
// state after the callable succeeds.

class BlockedUsersNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() {
    return ref.read(friendRepositoryProvider).getBlockedUserIds();
  }

  Future<void> block(String userId) async {
    await ref.read(friendRepositoryProvider).blockUser(userId);
    state = AsyncData({...state.value ?? const {}, userId});
  }

  Future<void> unblock(String userId) async {
    await ref.read(friendRepositoryProvider).unblockUser(userId);
    state = AsyncData(
      (state.value ?? const {}).where((id) => id != userId).toSet(),
    );
  }
}

final blockedUsersProvider =
    AsyncNotifierProvider<BlockedUsersNotifier, Set<String>>(
      BlockedUsersNotifier.new,
    );

// ── Posts ────────────────────────────────────────────────────────────────────
// Cursor-paginated (`getPostsPage`) — the same "fetch the next N after this
// exact item" scheme Instagram/Twitter/Reddit feeds use, so scrolling deeper
// into a large feed costs the same as page 1 rather than degrading the way
// offset/page-number paging does. `feedHasMoreProvider`/
// `feedLoadingMoreProvider` are tiny sibling providers (not part of
// `postsProvider`'s own `List<CommunityPost>` state shape) purely so
// `_FeedTab` can reactively show/hide an end-of-list spinner without every
// other reader of `postsProvider` having to unwrap a bigger state object.

final feedHasMoreProvider = StateProvider<bool>((ref) => true);
final feedLoadingMoreProvider = StateProvider<bool>((ref) => false);

class PostsNotifier extends AsyncNotifier<List<CommunityPost>> {
  DocumentSnapshot<Map<String, dynamic>>? _cursor;

  @override
  Future<List<CommunityPost>> build() async {
    final page = await ref.read(communityRepositoryProvider).getPostsPage();
    _cursor = page.cursor;
    ref.read(feedHasMoreProvider.notifier).state = page.hasMore;
    return page.posts;
  }

  /// Keeps the current feed visible (via `.value`) while refetching —
  /// stale-while-revalidate, not a blank spinner on every pull-to-refresh.
  /// On failure, also keeps the previous `.value` around (via
  /// `copyWithPrevious` on the error itself, not just the loading state) —
  /// a flaky reconciliation fetch right after posting shouldn't make a
  /// just-created (optimistically shown) post vanish behind an error
  /// screen; it should just stay exactly as it already looked.
  ///
  /// Always restarts from page 1 — a pull-to-refresh (or the reconciliation
  /// fetch after posting) means "show me what's current", not "keep
  /// scrolling from wherever I was".
  Future<void> refresh() async {
    state = AsyncLoading<List<CommunityPost>>().copyWithPrevious(state);
    final result = await AsyncValue.guard(() async {
      final page = await ref.read(communityRepositoryProvider).getPostsPage();
      _cursor = page.cursor;
      ref.read(feedHasMoreProvider.notifier).state = page.hasMore;
      return page.posts;
    });
    state = result.hasError ? result.copyWithPrevious(state) : result;
  }

  /// Appends the next page — called when the feed's scroll position nears
  /// the bottom (see `_FeedTab`). No-ops if a load is already in flight or
  /// the previous page was short (the standard "shorter than the page size
  /// means we've hit the end" signal, `PostsPage.hasMore`).
  Future<void> loadMore() async {
    if (ref.read(feedLoadingMoreProvider) || !ref.read(feedHasMoreProvider)) {
      return;
    }
    final current = state.value;
    if (current == null) return;

    ref.read(feedLoadingMoreProvider.notifier).state = true;
    try {
      final page = await ref
          .read(communityRepositoryProvider)
          .getPostsPage(startAfter: _cursor);
      _cursor = page.cursor;
      ref.read(feedHasMoreProvider.notifier).state = page.hasMore;
      // The still-current `state.value` (not the possibly-stale `current`
      // captured before this await) — createPost/likePost could have
      // updated it while this fetch was in flight.
      state = AsyncData([...(state.value ?? current), ...page.posts]);
    } catch (_) {
      // Best-effort — leave the feed exactly as it was; scrolling back up
      // and down again (or the next natural loadMore trigger) retries.
    } finally {
      ref.read(feedLoadingMoreProvider.notifier).state = false;
    }
  }

  Future<void> likePost(String postId) async {
    final current = state.value;
    if (current == null) return;
    final post = current.firstWhere((p) => p.id == postId);
    final wasLiked = post.isLiked;

    // Optimistic update — toggleLike is a direct Firestore write (fast), but
    // the UI shouldn't wait a round trip for a like button to respond.
    state = AsyncData(
      current
          .map(
            (p) => p.id == postId
                ? p.copyWith(
                    isLiked: !wasLiked,
                    likesCount: wasLiked ? p.likesCount - 1 : p.likesCount + 1,
                  )
                : p,
          )
          .toList(),
    );
    try {
      await ref
          .read(communityRepositoryProvider)
          .toggleLike(postId, currentlyLiked: wasLiked);
    } catch (_) {
      // Revert on failure.
      state = AsyncData(
        (state.value ?? current).map((p) => p.id == postId ? post : p).toList(),
      );
    }
  }

  Future<void> createPost(String content, {int? stepCount, String? imageUrl}) async {
    final postId = await ref
        .read(communityRepositoryProvider)
        .createPost(content, stepCount: stepCount, imageUrl: imageUrl);

    // Show it at the top immediately — the whole point is not making the
    // poster wait on (or, if that fetch hits a network hiccup, silently
    // lose it to) a server round trip just to see their own post appear.
    // `refresh()` below still runs right after, in the background, to
    // reconcile with the server's real timestamp/moderation state — this
    // optimistic entry is what's actually on screen in the meantime.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final profile = ref.read(userProfileProvider);
      final optimisticPost = CommunityPost(
        id: postId,
        authorId: uid,
        author: PublicProfile(
          id: uid,
          name: profile.name,
          username: profile.username,
          photoUrl: null,
          showStats: false,
          streakCurrent: null,
          streakLongest: null,
          lifetimeSteps: null,
        ),
        content: content,
        timestamp: DateTime.now(),
        likesCount: 0,
        commentsCount: 0,
        isLiked: false,
        stepCount: stepCount,
        badgeEmoji: null,
        imageUrl: imageUrl,
        pinned: false,
        commentsLocked: false,
        isMine: true,
      );
      final current = state.value ?? const [];
      state = AsyncData([optimisticPost, ...current]);
    }

    await refresh();
  }

  Future<void> deletePost(String postId) async {
    await ref.read(communityRepositoryProvider).deletePost(postId);
    state = AsyncData(
      (state.value ?? const []).where((p) => p.id != postId).toList(),
    );
  }
}

final postsProvider = AsyncNotifierProvider<PostsNotifier, List<CommunityPost>>(
  PostsNotifier.new,
);

// ── Comments (per post) ─────────────────────────────────────────────────────

class CommentsNotifier
    extends FamilyAsyncNotifier<List<CommunityComment>, String> {
  @override
  Future<List<CommunityComment>> build(String postId) {
    return ref.read(communityRepositoryProvider).getComments(postId);
  }

  Future<void> addComment(String content) async {
    await ref.read(communityRepositoryProvider).addComment(arg, content);
    state = AsyncData(
      await ref.read(communityRepositoryProvider).getComments(arg),
    );
    // Reflect the new comment count on the cached post list without a full reload.
    final postsNotifier = ref.read(postsProvider.notifier);
    final posts = ref.read(postsProvider).value;
    if (posts != null) {
      postsNotifier.state = AsyncData(
        posts
            .map(
              (p) => p.id == arg
                  ? p.copyWith(commentsCount: p.commentsCount + 1)
                  : p,
            )
            .toList(),
      );
    }
  }
}

final commentsProvider =
    AsyncNotifierProvider.family<
      CommentsNotifier,
      List<CommunityComment>,
      String
    >(CommentsNotifier.new);
