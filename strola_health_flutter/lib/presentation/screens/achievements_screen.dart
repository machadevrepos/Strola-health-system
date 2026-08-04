import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/domain/entities/app_badge.dart';
import 'package:strola_health/presentation/providers/badge_providers.dart';
import 'package:strola_health/presentation/widgets/hex_badge.dart';
import 'package:strola_health/presentation/widgets/pressable_scale.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              pinned: false,
              leading: PressableScale(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  AppIcons.back,
                  color: AppColors.textPrimary,
                  size: AppTheme.iconM,
                ),
              ),
              actions: [
                PressableScale(
                  onTap: () => _showInfo(context),
                  child: const Padding(
                    padding: EdgeInsets.only(right: AppTheme.spaceL),
                    child: Icon(AppIcons.info, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.screenPaddingH,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Achievements',
                      style: AppTypography.displayM,
                    ).animate().fadeIn(duration: AppTheme.animSlow),
                    const SizedBox(height: AppTheme.spaceS),
                    Text(
                      'Earn badges by staying active, building healthy '
                      'habits, and achieving your goals!',
                      style: AppTypography.bodyM.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ).animate().fadeIn(
                      delay: 80.ms,
                      duration: AppTheme.animSlow,
                    ),
                    const SizedBox(height: AppTheme.spaceXXL),

                    _AchievementSection(
                      icon: AppIcons.steps,
                      title: 'Steps',
                      description:
                          'Earn badges by reaching total step milestones.',
                      badgesAsync: ref.watch(stepBadgesProvider),
                      gradient: const [
                        AppColors.accent,
                        AppColors.accentSecondary,
                      ],
                      delay: 120,
                    ),
                    const SizedBox(height: AppTheme.spaceXXL),
                    _AchievementSection(
                      icon: AppIcons.streak,
                      title: 'Streaks',
                      description:
                          'Earn badges by meeting your daily step goal '
                          'multiple days in a row.',
                      badgesAsync: ref.watch(streakBadgesProvider),
                      gradient: const [AppColors.accent, AppColors.error],
                      delay: 200,
                    ),
                    const SizedBox(height: AppTheme.spaceXXL),
                    _AchievementSection(
                      icon: AppIcons.trophy,
                      title: 'Challenges',
                      description: 'Earn badges by completing challenges.',
                      badgesAsync: ref.watch(challengeBadgesProvider),
                      gradient: const [AppColors.goalAmber, AppColors.accent],
                      delay: 280,
                    ),

                    const SizedBox(height: AppTheme.spaceXXL),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            AppIcons.heart,
                            color: AppColors.accent,
                            size: AppTheme.iconS,
                          ),
                          const SizedBox(width: AppTheme.spaceXS),
                          Text(
                            'Keep it up! Every step counts.',
                            style: AppTypography.bodyS.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(
                      delay: 360.ms,
                      duration: AppTheme.animSlow,
                    ),
                    const SizedBox(height: AppTheme.spaceXXL),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('About Achievements', style: AppTypography.titleM),
        content: Text(
          'Badges unlock automatically as you hit step, streak, and '
          'challenge milestones. Keep moving to earn them all!',
          style: AppTypography.bodyM,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Got it',
              style: AppTypography.titleS.copyWith(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AchievementSection extends StatelessWidget {
  const _AchievementSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.badgesAsync,
    required this.gradient,
    required this.delay,
  });

  final IconData icon;
  final String title;
  final String description;
  final AsyncValue<List<AppBadge>> badgesAsync;
  final List<Color> gradient;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.accent, size: AppTheme.iconM),
                const SizedBox(width: AppTheme.spaceS),
                Text(title, style: AppTypography.titleL),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTypography.bodyS.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spaceL),
            badgesAsync.when(
              loading: () => const _BadgeRowSkeleton(),
              error: (_, __) => const Center(
                child: Text(
                  'Could not load badges.',
                  style: AppTypography.bodyM,
                ),
              ),
              data: (badges) {
                if (badges.isEmpty) return const _EmptyBadgeRow();
                return Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: AppTheme.spaceL,
                  children: [
                    for (final b in badges)
                      HexBadge(
                        big: b.emoji,
                        small: _smallLabel(b.requirementMetric),
                        label: b.name,
                        description: b.description,
                        earned: b.earned,
                        gradient: gradient,
                        width: 64,
                      ),
                  ],
                );
              },
            ),
          ],
        )
        .animate()
        .fadeIn(delay: delay.ms, duration: AppTheme.animSlow)
        .slideY(begin: 0.1);
  }
}

/// Short caption shown under the badge's emoji on the hexagon face — matches
/// the requirement this section's badges track.
String _smallLabel(BadgeRequirementMetric metric) {
  switch (metric) {
    case BadgeRequirementMetric.totalSteps:
    case BadgeRequirementMetric.sessionSteps:
      return 'STEPS';
    case BadgeRequirementMetric.streakDays:
      return 'DAY STREAK';
    case BadgeRequirementMetric.challengesCompleted:
      return 'CHALLENGES';
    case BadgeRequirementMetric.unknown:
      return '';
  }
}

// ── Loading / empty states ──────────────────────────────────────────────────

class _BadgeRowSkeleton extends StatelessWidget {
  const _BadgeRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: AppColors.accentSecondary.withValues(alpha: 0.15),
        highlightColor: AppColors.accentSecondary.withValues(alpha: 0.35),
        duration: const Duration(milliseconds: 1200),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: AppTheme.spaceL,
        children: List.generate(
          4,
          (_) => const HexBadge(
            gradient: [AppColors.textMuted, AppColors.textMuted],
            small: 'LOADING',
            label: 'Loading badge name',
            description: 'Loading badge description here',
            big: '00',
            earned: false,
            width: 64,
          ),
        ),
      ),
    );
  }
}

/// Shown for a section whose category has zero enabled/visible badges yet in
/// Firestore — sparse real data shouldn't render as a broken empty row.
class _EmptyBadgeRow extends StatelessWidget {
  const _EmptyBadgeRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceM),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              AppIcons.trophy,
              size: AppTheme.iconL,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppTheme.spaceXS),
            Text(
              'No badges here yet. Check back soon.',
              style: AppTypography.bodyS.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
