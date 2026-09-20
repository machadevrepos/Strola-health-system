import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/data/repositories/badge_repository.dart';
import 'package:strola_health/domain/entities/app_badge.dart';

/// Every enabled + visible badge, merged with the signed-in user's earned
/// status. Simple one-shot read (no mutations happen on this screen — badges
/// are only ever awarded server-side), so a plain `FutureProvider` is enough;
/// pull-to-refresh re-reads via `ref.refresh`.
final badgesProvider = FutureProvider<List<AppBadge>>((ref) {
  return ref.watch(badgeRepositoryProvider).getBadges();
});

/// Badges for a single Achievements-screen section, filtered by requirement
/// metric and sorted ascending by requirement value so tiers read low → high,
/// matching the screen's previous hardcoded ordering.
AsyncValue<List<AppBadge>> _filterSorted(
  AsyncValue<List<AppBadge>> badges,
  BadgeRequirementMetric metric,
) {
  return badges.whenData((list) {
    final filtered = list.where((b) => b.requirementMetric == metric).toList()
      ..sort((a, b) => a.requirementValue.compareTo(b.requirementValue));
    return filtered;
  });
}

final stepBadgesProvider = Provider<AsyncValue<List<AppBadge>>>((ref) {
  return _filterSorted(
    ref.watch(badgesProvider),
    BadgeRequirementMetric.totalSteps,
  );
});

final streakBadgesProvider = Provider<AsyncValue<List<AppBadge>>>((ref) {
  return _filterSorted(
    ref.watch(badgesProvider),
    BadgeRequirementMetric.streakDays,
  );
});

final challengeBadgesProvider = Provider<AsyncValue<List<AppBadge>>>((ref) {
  return _filterSorted(
    ref.watch(badgesProvider),
    BadgeRequirementMetric.challengesCompleted,
  );
});

/// The 5 most recently earned badges, newest first — feeds the Profile
/// screen's "Achievements" preview strip. Unlike the section providers
/// above, this crosses all requirement metrics, since the preview shows a
/// user's overall recent progress rather than one category.
final recentEarnedBadgesProvider = Provider<AsyncValue<List<AppBadge>>>((ref) {
  return ref.watch(badgesProvider).whenData((list) {
    final earned = list.where((b) => b.earned).toList()
      ..sort((a, b) {
        final aAt = a.earnedAt;
        final bAt = b.earnedAt;
        if (aAt == null && bAt == null) return 0;
        if (aAt == null) return 1;
        if (bAt == null) return -1;
        return bAt.compareTo(aAt);
      });
    return earned.take(5).toList();
  });
});
