import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/data/repositories/friend_repository.dart';
import 'package:strola_health/domain/entities/friend.dart';

class FriendshipsNotifier extends AsyncNotifier<List<FriendSummary>> {
  @override
  Future<List<FriendSummary>> build() {
    return ref.read(friendRepositoryProvider).getFriendships();
  }

  /// Keeps the current list visible (via `.value`) while refetching —
  /// stale-while-revalidate, not a blank spinner on every pull-to-refresh.
  Future<void> refresh() async {
    state = AsyncLoading<List<FriendSummary>>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(friendRepositoryProvider).getFriendships(),
    );
  }

  Future<void> sendRequest(String targetUserId) async {
    await ref.read(friendRepositoryProvider).sendRequest(targetUserId);
    await refresh();
  }

  Future<void> respondRequest(String requesterId, bool accept) async {
    await ref
        .read(friendRepositoryProvider)
        .respondRequest(requesterId, accept);
    await refresh();
  }

  Future<void> removeFriend(String friendUserId) async {
    await ref.read(friendRepositoryProvider).removeFriend(friendUserId);
    await refresh();
  }
}

final friendshipsProvider =
    AsyncNotifierProvider<FriendshipsNotifier, List<FriendSummary>>(
      FriendshipsNotifier.new,
    );

/// One-off pairwise status lookup — powers PublicProfileScreen's connect
/// button without loading the caller's entire friend list.
final friendshipWithProvider = FutureProvider.family<FriendshipStatus?, String>(
  (ref, otherUserId) =>
      ref.read(friendRepositoryProvider).getFriendshipWith(otherUserId),
);
