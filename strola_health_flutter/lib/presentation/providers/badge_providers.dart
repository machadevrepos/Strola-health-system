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
