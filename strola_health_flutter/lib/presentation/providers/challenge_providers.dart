import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/data/repositories/challenge_repository.dart';
import 'package:strola_health/domain/entities/challenge.dart';

/// The current featured "Challenge of the Month" — null when no official
/// challenge is published yet (real state, not an error). A live stream, not
/// a one-shot fetch: the admin panel writes straight to Firestore when it
/// flags a challenge official, so this needs to be watching, not polling,
/// for that to show up without a manual refresh.
final officialChallengeProvider = StreamProvider<Challenge?>((ref) {
  return ref.watch(challengeRepositoryProvider).watchCurrentOfficialChallenge();
});

/// Most recently archived official challenge, for "Last Month's Winners".
/// Null until the first official challenge has ever completed.
final lastCompletedOfficialChallengeProvider = FutureProvider<Challenge?>((
  ref,
) {
  return ref
      .watch(challengeRepositoryProvider)
      .getLastCompletedOfficialChallenge();
});

/// Live leaderboard for a single challenge (sorted by steps).
final challengeLeaderboardProvider =
    FutureProvider.family<List<ChallengeLeaderboardEntry>, String>((
      ref,
      challengeId,
    ) {
      return ref.watch(challengeRepositoryProvider).getLeaderboard(challengeId);
    });

/// Denormalized final standings for a completed challenge — see
/// ChallengeRepository.getLeaderboardTop.
final challengeLeaderboardTopProvider =
    FutureProvider.family<List<ChallengeLeaderboardEntry>, Challenge>((
      ref,
      challenge,
    ) {
      return ref
          .watch(challengeRepositoryProvider)
          .getLeaderboardTop(challenge);
    });

/// Challenges the signed-in user has joined — the "Private Challenges" tab
/// filters this to `status == published`, "Completed Challenges" to
/// `status == archived`.
class MyChallengesNotifier extends AsyncNotifier<List<Challenge>> {
  @override
  Future<List<Challenge>> build() {
    return ref.read(challengeRepositoryProvider).getMyChallenges();
  }

  /// Keeps the current list visible (via `.value`) while refetching —
  /// stale-while-revalidate, not a blank spinner on every pull-to-refresh or
  /// post-join/leave/create reload.
  Future<void> refresh() async {
    state = AsyncLoading<List<Challenge>>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(challengeRepositoryProvider).getMyChallenges(),
    );
  }

  Future<void> join({String? challengeId, String? inviteCode}) async {
    await ref
        .read(challengeRepositoryProvider)
        .joinChallenge(challengeId: challengeId, inviteCode: inviteCode);
    await refresh();
  }

  Future<void> leave(String challengeId) async {
    await ref.read(challengeRepositoryProvider).leaveChallenge(challengeId);
    await refresh();
  }

  Future<({String id, String? inviteCode})> create({
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
    final created = await ref
        .read(challengeRepositoryProvider)
        .createChallenge(
          title: title,
          description: description,
          goalSteps: goalSteps,
          startDate: startDate,
          endDate: endDate,
          badgeEmoji: badgeEmoji,
          accentColorValue: accentColorValue,
          isPublic: isPublic,
          winnerType: winnerType,
        );
    await refresh();
    return created;
  }
}

final myChallengesProvider =
    AsyncNotifierProvider<MyChallengesNotifier, List<Challenge>>(
      MyChallengesNotifier.new,
    );
