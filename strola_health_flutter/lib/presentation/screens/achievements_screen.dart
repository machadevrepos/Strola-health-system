import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/presentation/widgets/hex_badge.dart';
import 'package:strola_health/presentation/widgets/pressable_scale.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      badges: _stepBadges,
                      delay: 120,
                    ),
                    const SizedBox(height: AppTheme.spaceXXL),
                    _AchievementSection(
                      icon: AppIcons.streak,
                      title: 'Streaks',
                      description:
                          'Earn badges by meeting your daily step goal '
                          'multiple days in a row.',
                      badges: _streakBadges,
                      delay: 200,
                    ),
                    const SizedBox(height: AppTheme.spaceXXL),
                    _AchievementSection(
                      icon: AppIcons.trophy,
                      title: 'Challenges',
                      description: 'Earn badges by completing challenges.',
                      badges: _challengeBadges,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
    required this.badges,
    required this.delay,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<_BadgeInfo> badges;
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
          style: AppTypography.bodyS.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppTheme.spaceL),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final b in badges)
              HexBadge(
                big: b.big,
                icon: b.icon,
                small: b.small,
                label: b.label,
                description: b.description,
                earned: b.earned,
                gradient: b.gradient,
                width: 64,
              ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: delay.ms, duration: AppTheme.animSlow).slideY(begin: 0.1);
  }
}

// ── Badge catalog ──────────────────────────────────────────────────────────────

class _BadgeInfo {
  const _BadgeInfo({
    required this.small,
    required this.label,
    required this.description,
    required this.earned,
    required this.gradient,
    this.big,
    this.icon,
  });

  final String small;
  final String label;
  final String description;
  final bool earned;
  final List<Color> gradient;
  final String? big;
  final IconData? icon;
}

const _stepBadges = [
  _BadgeInfo(
    big: '50K',
    small: 'STEPS',
    label: '50,000 Steps',
    description: 'Take 50,000 total steps',
    earned: true,
    gradient: [AppColors.success, AppColors.success],
  ),
  _BadgeInfo(
    big: '100K',
    small: 'STEPS',
    label: '100,000 Steps',
    description: 'Take 100,000 total steps',
    earned: true,
    gradient: [AppColors.accent, AppColors.accentSecondary],
  ),
  _BadgeInfo(
    big: '250K',
    small: 'STEPS',
    label: '250,000 Steps',
    description: 'Take 250,000 total steps',
    earned: true,
    gradient: [AppColors.goalAmber, AppColors.accent],
  ),
  _BadgeInfo(
    big: '500K',
    small: 'STEPS',
    label: '500,000 Steps',
    description: 'Take 500,000 total steps',
    earned: false,
    gradient: [AppColors.textMuted, AppColors.textMuted],
  ),
];

const _streakBadges = [
  _BadgeInfo(
    big: '3',
    small: 'DAY STREAK',
    label: '3 Day Streak',
    description: 'Meet your daily step goal 3 days in a row',
    earned: true,
    gradient: [AppColors.accent, AppColors.error],
  ),
  _BadgeInfo(
    big: '7',
    small: 'DAY STREAK',
    label: '7 Day Streak',
    description: 'Meet your daily step goal 7 days in a row',
    earned: true,
    gradient: [AppColors.goalAmber, AppColors.goalAmber],
  ),
  _BadgeInfo(
    big: '14',
    small: 'DAY STREAK',
    label: '14 Day Streak',
    description: 'Meet your daily step goal 14 days in a row',
    earned: true,
    gradient: [AppColors.goalAmber, AppColors.accent],
  ),
  _BadgeInfo(
    big: '30',
    small: 'DAY STREAK',
    label: '30 Day Streak',
    description: 'Meet your daily step goal 30 days in a row',
    earned: false,
    gradient: [AppColors.textMuted, AppColors.textMuted],
  ),
];

const _challengeBadges = [
  _BadgeInfo(
    icon: AppIcons.star,
    small: 'FINISHER',
    label: 'Challenge Finisher',
    description: 'Complete your first challenge',
    earned: true,
    gradient: [AppColors.accent, AppColors.accentSecondary],
  ),
  _BadgeInfo(
    big: '5',
    small: 'CHALLENGES',
    label: 'Challenge Pro',
    description: 'Complete 5 challenges',
    earned: true,
    gradient: [AppColors.goalAmber, AppColors.accent],
  ),
  _BadgeInfo(
    big: '10',
    small: 'CHALLENGES',
    label: 'Challenge Master',
    description: 'Complete 10 challenges',
    earned: false,
    gradient: [AppColors.textMuted, AppColors.textMuted],
  ),
  _BadgeInfo(
    big: '25',
    small: 'CHALLENGES',
    label: 'Challenge Legend',
    description: 'Complete 25 challenges',
    earned: false,
    gradient: [AppColors.textMuted, AppColors.textMuted],
  ),
];
