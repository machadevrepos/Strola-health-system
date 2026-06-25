import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strola_health/data/repositories/community_repository.dart';
import 'package:strola_health/domain/entities/challenge.dart';
import 'package:strola_health/domain/entities/community_post.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';

// ── Blocked users ─────────────────────────────────────────────────────────────
// Persisted set of author names the user has blocked. Their profile and forum
// posts are hidden everywhere.

class BlockedUsersNotifier extends StateNotifier<Set<String>> {
  BlockedUsersNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;
  static const prefsKey = 'blocked_users';

  static Set<String> _load(SharedPreferences prefs) =>
      (prefs.getStringList(prefsKey) ?? const <String>[]).toSet();

  Future<void> block(String name) async {
    state = {...state, name};
    await _prefs.setStringList(prefsKey, state.toList());
  }

  Future<void> unblock(String name) async {
    state = state.where((n) => n != name).toSet();
    await _prefs.setStringList(prefsKey, state.toList());
  }
}

final blockedUsersProvider =
    StateNotifierProvider<BlockedUsersNotifier, Set<String>>(
      (ref) => BlockedUsersNotifier(ref.watch(sharedPreferencesProvider)),
    );

// ── Posts ────────────────────────────────────────────────────────────────────

class PostsNotifier extends AsyncNotifier<List<CommunityPost>> {
  @override
  Future<List<CommunityPost>> build() {
    return ref.read(communityRepositoryProvider).getPosts();
  }

  Future<void> likePost(String postId) async {
    final repo = ref.read(communityRepositoryProvider);
    final updated = await repo.likePost(postId);
    state = AsyncData(
      state.value!.map((p) => p.id == postId ? updated : p).toList(),
    );
  }

  Future<void> createPost(
    String content, {
    int? stepCount,
    String? imagePath,
  }) async {
    final repo = ref.read(communityRepositoryProvider);
    final post = await repo.createPost(
      content,
      stepCount: stepCount,
      imagePath: imagePath,
    );
    state = AsyncData([post, ...state.value ?? []]);
  }
}

final postsProvider = AsyncNotifierProvider<PostsNotifier, List<CommunityPost>>(
  PostsNotifier.new,
);

// ── Challenges ───────────────────────────────────────────────────────────────

class ChallengesNotifier extends AsyncNotifier<List<Challenge>> {
  @override
  Future<List<Challenge>> build() {
    return ref.read(communityRepositoryProvider).getChallenges();
  }

  Future<void> joinChallenge(String challengeId) async {
    final repo = ref.read(communityRepositoryProvider);
    final updated = await repo.joinChallenge(challengeId);
    state = AsyncData(
      state.value!.map((c) => c.id == challengeId ? updated : c).toList(),
    );
  }
}

final challengesProvider =
    AsyncNotifierProvider<ChallengesNotifier, List<Challenge>>(
      ChallengesNotifier.new,
    );
