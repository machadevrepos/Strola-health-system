import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/formatters.dart';
import 'package:strola_health/presentation/providers/community_providers.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';
import 'package:strola_health/presentation/providers/step_providers.dart';
import 'package:strola_health/presentation/screens/achievements_screen.dart';
import 'package:strola_health/presentation/screens/challenges_screen.dart';
import 'package:strola_health/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:strola_health/presentation/screens/settings_screen.dart';
import 'package:strola_health/presentation/screens/view_profile_picture_screen.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/hex_badge.dart';
import 'package:strola_health/presentation/widgets/pressable_scale.dart';
import 'package:strola_health/presentation/widgets/report_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(stepCountProvider);
    final goal = ref.watch(dailyGoalProvider);
    final weekly = ref.watch(weeklyStepsProvider);
    final profile = ref.watch(userProfileProvider);
    final privacy = ref.watch(privacySettingsProvider);

    final distanceStr = ref.watch(distanceProvider);
    final calories = ref.watch(caloriesProvider);

    final displayName = profile.name.isEmpty ? 'Your Name' : profile.name;
    final displayHandle = profile.username.isEmpty ? 'you' : profile.username;
    final displayBio = profile.bio?.isNotEmpty == true
        ? profile.bio!
        : 'Walking for strength, energy, and a healthier me. 💕';

    int streak = 0;
    for (int i = weekly.length - 2; i >= 0; i--) {
      if (weekly[i] >= goal) {
        streak++;
      } else {
        break;
      }
    }

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App bar ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceXL,
                    AppTheme.spaceXS,
                    AppTheme.spaceXL,
                    0,
                  ),
                  child: Row(
                    children: [
                      if (Navigator.canPop(context))
                        PressableScale(
                          onTap: () => Navigator.maybePop(context),
                          child: const Icon(
                            AppIcons.back,
                            color: AppColors.textPrimary,
                            size: AppTheme.iconM,
                          ),
                        ),
                      const Spacer(),
                      PressableScale(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.10),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            AppIcons.settings,
                            color: AppColors.textSecondary,
                            size: AppTheme.iconM,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 50.ms, duration: AppTheme.animSlow),
            ),

            // ── Profile header ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child:
                  Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.spaceXL,
                          AppTheme.spaceS,
                          AppTheme.spaceXL,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar
                                Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showAvatarSheet(
                                        context,
                                        ref,
                                        profile.photoPath,
                                      ),
                                      child: Container(
                                        width: 76,
                                        height: 76,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.accentSecondary
                                              .withValues(alpha: 0.3),
                                          border: Border.all(
                                            color: AppColors.accentSecondary
                                                .withValues(alpha: 0.5),
                                            width: 2,
                                          ),
                                          image: profile.photoPath != null
                                              ? DecorationImage(
                                                  image: FileImage(
                                                    File(profile.photoPath!),
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: profile.photoPath == null
                                            ? const Icon(
                                                AppIcons.profile,
                                                color: AppColors.accent,
                                                size: 38,
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    PressableScale(
                                      onTap: () =>
                                          _changeProfilePhoto(context, ref),
                                      child: Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.accent,
                                          border: Border.all(
                                            color: AppColors.bgSurface,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.accent
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          AppIcons.camera,
                                          color: Colors.white,
                                          size: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                // Identity
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: AppTypography.titleL.copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '@$displayHandle',
                                        style: AppTypography.bodyS.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        displayBio,
                                        style: AppTypography.bodyS.copyWith(
                                          fontSize: 12,
                                          height: 1.35,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Action + connections
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    PressableScale(
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const OnboardingScreen(
                                                isEditing: true,
                                              ),
                                        ),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 9,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent,
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusM,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.accent
                                                  .withValues(alpha: 0.30),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          'Edit Profile',
                                          style: AppTypography.bodyS.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      '842',
                                      style: AppTypography.titleL.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Text(
                                      'Friends',
                                      style: AppTypography.labelS.copyWith(
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spaceM),
                            // Chips
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: AppTheme.spaceXS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        AppIcons.streak,
                                        color: AppColors.accent,
                                        size: 13,
                                      ),
                                      const SizedBox(width: AppTheme.spaceXS),
                                      Text(
                                        '$streak Day Streak',
                                        style: AppTypography.labelS.copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!privacy.hideLocation &&
                                    profile.location?.isNotEmpty == true) ...[
                                  const SizedBox(width: AppTheme.spaceS),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: AppTheme.spaceXS,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentSecondary
                                          .withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          AppIcons.location,
                                          color: AppColors.textMuted,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          profile.location!,
                                          style: AppTypography.labelS.copyWith(
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: 0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: AppTheme.animSlow)
                      .slideY(begin: 0.12),
            ),

            if (!privacy.hideActivityData) ...[
              const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.sectionGap),
              ),

              // ── Today's stats ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child:
                    Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceXL,
                          ),
                          child: FlatCard(
                            padding: const EdgeInsets.all(AppTheme.spaceL),
                            child: Row(
                              children: [
                                _StatTile(
                                  icon: AppIcons.steps,
                                  value: Formatters.stepCount(steps),
                                  label: 'Steps Today',
                                ),
                                _StatTile(
                                  icon: AppIcons.location,
                                  value: distanceStr,
                                  label: 'Distance',
                                ),
                                _StatTile(
                                  icon: AppIcons.calories,
                                  value: '$calories',
                                  label: 'Active Calories',
                                ),
                                PressableScale(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ChallengesScreen(),
                                    ),
                                  ),
                                  child: const _StatTile(
                                    icon: AppIcons.trophy,
                                    value: '27',
                                    label: 'Challenges\nCompleted',
                                    isLink: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: AppTheme.animSlow)
                        .slideY(begin: 0.12),
              ),
            ],

            if (!privacy.hideAchievements) ...[
              const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.sectionGap),
              ),

              // ── Achievements ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child:
                    Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceXL,
                          ),
                          child: FlatCard(
                            padding: const EdgeInsets.all(AppTheme.spaceL),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Achievements',
                                      style: AppTypography.titleM.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    PressableScale(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const AchievementsScreen(),
                                        ),
                                      ),
                                      child: Text(
                                        'View All',
                                        style: AppTypography.bodyS.copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.sectionGap),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: const [
                                    HexBadge(
                                      big: '12',
                                      small: 'DAY STREAK',
                                      label: '12 Day Streak',
                                      date: 'May 12, 2024',
                                      gradient: [
                                        AppColors.accent,
                                        AppColors.error,
                                      ],
                                    ),
                                    HexBadge(
                                      big: '100K',
                                      small: 'STEPS',
                                      label: '100K Steps',
                                      date: 'Apr 28, 2024',
                                      gradient: [
                                        AppColors.success,
                                        AppColors.success,
                                      ],
                                    ),
                                    HexBadge(
                                      icon: AppIcons.earlyBird,
                                      small: 'EARLY BIRD',
                                      label: 'Early Bird',
                                      date: 'Apr 15, 2024',
                                      gradient: [
                                        AppColors.goalAmber,
                                        AppColors.accent,
                                      ],
                                    ),
                                    HexBadge(
                                      big: '7',
                                      small: 'DAY STREAK',
                                      label: '7 Day Streak',
                                      date: 'Apr 7, 2024',
                                      gradient: [
                                        AppColors.goalAmber,
                                        AppColors.goalAmber,
                                      ],
                                    ),
                                    HexBadge(
                                      big: '50K',
                                      small: 'STEPS',
                                      label: '50K Steps',
                                      date: 'Mar 22, 2024',
                                      gradient: [
                                        AppColors.accentSecondary,
                                        AppColors.accent,
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: AppTheme.animSlow)
                        .slideY(begin: 0.12),
              ),
            ],

            if (!privacy.hideRecentActivity) ...[
              const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.sectionGap),
              ),

              // ── Recent Activity ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child:
                    Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceXL,
                          ),
                          child: FlatCard(
                            padding: const EdgeInsets.all(AppTheme.spaceL),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Recent Activity',
                                      style: AppTypography.titleM.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    PressableScale(
                                      onTap: () {},
                                      child: Text(
                                        'View All',
                                        style: AppTypography.bodyS.copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spaceM),
                                ...[
                                  (
                                    'Hit ${Formatters.stepCount(steps)} steps',
                                    _todayStr(),
                                  ),
                                  (
                                    'Completed Day $streak of the 10K Steps Challenge',
                                    _daysAgoStr(1),
                                  ),
                                  ('Hit 11,009 steps', _daysAgoStr(1)),
                                  ('Hit 9,842 steps', _daysAgoStr(2)),
                                ].asMap().entries.map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppTheme.spaceM,
                                    ),
                                    child:
                                        Row(
                                              children: [
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.accent
                                                        .withValues(alpha: 0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    AppIcons.steps,
                                                    color: AppColors.accent,
                                                    size: AppTheme.iconS,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    e.value.$1,
                                                    style: AppTypography.bodyL
                                                        .copyWith(fontSize: 13),
                                                  ),
                                                ),
                                                Text(
                                                  e.value.$2,
                                                  style: AppTypography.labelS
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        letterSpacing: 0,
                                                      ),
                                                ),
                                              ],
                                            )
                                            .animate(
                                              delay: Duration(
                                                milliseconds: 220 + e.key * 60,
                                              ),
                                            )
                                            .fadeIn(duration: AppTheme.animSlow)
                                            .slideX(begin: 0.06),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 250.ms, duration: AppTheme.animSlow)
                        .slideY(begin: 0.12),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  String _todayStr() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _daysAgoStr(int daysAgo) {
    final d = DateTime.now().subtract(Duration(days: daysAgo));
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ── Public Profile (viewed by others) ─────────────────────────────────────────

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({
    super.key,
    required this.name,
    required this.username,
    required this.stepsToday,
    required this.distanceKm,
    required this.streak,
    this.location = 'Toronto, Canada',
    this.bio =
        'Mother. Healthcare worker. Walking for strength, energy, and my little ones. 💕',
    this.isConnected = false,
  });

  final String name;
  final String username;
  final int stepsToday;
  final double distanceKm;
  final int streak;
  final String location;
  final String bio;
  final bool isConnected;

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
                  onTap: () => _showMoreOptions(context, ref),
                  child: const Padding(
                    padding: EdgeInsets.only(right: AppTheme.spaceL),
                    child: Icon(AppIcons.more, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceXL,
                  0,
                  AppTheme.spaceXL,
                  0,
                ),
                child: Column(
                  children: [
                    // Profile header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentSecondary.withValues(
                              alpha: 0.3,
                            ),
                            border: Border.all(
                              color: AppColors.accentSecondary.withValues(
                                alpha: 0.5,
                              ),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            AppIcons.profile,
                            color: AppColors.accent,
                            size: 38,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Identity
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: AppTypography.titleL.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '@$username',
                                style: AppTypography.bodyS.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                bio,
                                style: AppTypography.bodyS.copyWith(
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Connect + connections
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _ConnectButton(initiallyConnected: isConnected),
                            const SizedBox(height: 14),
                            Text(
                              '842',
                              style: AppTypography.titleL.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Friends',
                              style: AppTypography.labelS.copyWith(
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ).animate().fadeIn(
                      delay: 50.ms,
                      duration: AppTheme.animSlow,
                    ),

                    const SizedBox(height: AppTheme.spaceM),

                    // Chips
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: AppTheme.spaceXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                AppIcons.streak,
                                color: AppColors.accent,
                                size: 13,
                              ),
                              const SizedBox(width: AppTheme.spaceXS),
                              Text(
                                '$streak Day Streak',
                                style: AppTypography.labelS.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (location.isNotEmpty) ...[
                          const SizedBox(width: AppTheme.spaceS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: AppTheme.spaceXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentSecondary.withValues(
                                alpha: 0.18,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  AppIcons.location,
                                  color: AppColors.textMuted,
                                  size: 13,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  location,
                                  style: AppTypography.labelS.copyWith(
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppTheme.spaceL),

                    // Stats row
                    FlatCard(
                          padding: const EdgeInsets.all(AppTheme.spaceL),
                          child: Row(
                            children: [
                              _StatTile(
                                icon: AppIcons.steps,
                                value: Formatters.stepCount(stepsToday),
                                label: 'Steps Today',
                              ),
                              _StatTile(
                                icon: AppIcons.location,
                                value: '${distanceKm.toStringAsFixed(1)} km',
                                label: 'Distance',
                              ),
                              const _StatTile(
                                icon: AppIcons.calories,
                                value: '423',
                                label: 'Active Calories',
                              ),
                              const _StatTile(
                                icon: AppIcons.trophy,
                                value: '27',
                                label: 'Challenges\nCompleted',
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: AppTheme.animSlow)
                        .slideY(begin: 0.12),

                    const SizedBox(height: AppTheme.sectionGap),

                    // Achievements
                    FlatCard(
                          padding: const EdgeInsets.all(AppTheme.spaceL),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Achievements',
                                    style: AppTypography.titleM.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  PressableScale(
                                    onTap: () {},
                                    child: Text(
                                      'View All',
                                      style: AppTypography.bodyS.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.sectionGap),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: const [
                                  HexBadge(
                                    big: '12',
                                    small: 'DAY STREAK',
                                    label: '12 Day Streak',
                                    date: 'May 12, 2024',
                                    gradient: [
                                      AppColors.accent,
                                      AppColors.error,
                                    ],
                                  ),
                                  HexBadge(
                                    big: '100K',
                                    small: 'STEPS',
                                    label: '100K Steps',
                                    date: 'Apr 28, 2024',
                                    gradient: [
                                      AppColors.success,
                                      AppColors.success,
                                    ],
                                  ),
                                  HexBadge(
                                    icon: AppIcons.earlyBird,
                                    small: 'EARLY BIRD',
                                    label: 'Early Bird',
                                    date: 'Apr 15, 2024',
                                    gradient: [
                                      AppColors.goalAmber,
                                      AppColors.accent,
                                    ],
                                  ),
                                  HexBadge(
                                    big: '7',
                                    small: 'DAY STREAK',
                                    label: '7 Day Streak',
                                    date: 'Apr 7, 2024',
                                    gradient: [
                                      AppColors.goalAmber,
                                      AppColors.goalAmber,
                                    ],
                                  ),
                                  HexBadge(
                                    big: '50K',
                                    small: 'STEPS',
                                    label: '50K Steps',
                                    date: 'Mar 22, 2024',
                                    gradient: [
                                      AppColors.accentSecondary,
                                      AppColors.accent,
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: AppTheme.animSlow)
                        .slideY(begin: 0.12),

                    const SizedBox(height: AppTheme.sectionGap),

                    // Recent Activity
                    FlatCard(
                          padding: const EdgeInsets.all(AppTheme.spaceL),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recent Activity',
                                    style: AppTypography.titleM.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  PressableScale(
                                    onTap: () {},
                                    child: Text(
                                      'View All',
                                      style: AppTypography.bodyS.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              ...[
                                'Hit ${Formatters.stepCount(stepsToday)} steps',
                                'Completed Day $streak of the 10K Steps Challenge',
                                'Hit 11,009 steps',
                                'Hit 9,842 steps',
                              ].asMap().entries.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withValues(
                                            alpha: 0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          AppIcons.steps,
                                          color: AppColors.accent,
                                          size: AppTheme.iconXS,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          e.value,
                                          style: AppTypography.labelM.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: 0,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'May ${14 - e.key}, 2024',
                                        style: AppTypography.labelS.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: AppTheme.animSlow)
                        .slideY(begin: 0.12),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        margin: const EdgeInsets.all(AppTheme.spaceL),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.accentSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
            const SizedBox(height: AppTheme.spaceS),
            ListTile(
              leading: const Icon(AppIcons.block, color: AppColors.error),
              title: Text(
                'Block User',
                style: AppTypography.bodyL.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                "$name won't see your profile or posts, and you won't see theirs",
                style: AppTypography.labelM.copyWith(
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _confirmBlock(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(
                AppIcons.report,
                color: AppColors.textSecondary,
              ),
              title: Text(
                'Report',
                style: AppTypography.bodyL.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                showReportSheet(context, subject: name);
              },
            ),
            const SizedBox(height: AppTheme.spaceM),
          ],
        ),
      ),
    );
  }

  void _confirmBlock(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Block $name?',
          style: AppTypography.titleM.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          "They won't be able to see your profile or anything you post in the "
          "forum, and you won't see theirs.",
          style: AppTypography.bodyS,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: AppTypography.bodyL.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              ref.read(blockedUsersProvider.notifier).block(name);
              Navigator.pop(dialogCtx); // close dialog
              Navigator.pop(context); // close profile
              messenger.showSnackBar(
                SnackBar(
                  content: Text("You've blocked $name."),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Block',
              style: AppTypography.bodyL.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile photo (view / change) ───────────────────────────────────────────

Future<void> _showAvatarSheet(
  BuildContext context,
  WidgetRef ref,
  String? photoPath,
) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Container(
      margin: const EdgeInsets.all(AppTheme.spaceL),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.accentSecondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          ListTile(
            leading: const Icon(AppIcons.image, color: AppColors.textSecondary),
            title: Text(
              'View Profile Picture',
              style: AppTypography.bodyL.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Navigator.pop(sheetCtx);
              Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) =>
                      ViewProfilePictureScreen(photoPath: photoPath),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              AppIcons.camera,
              color: AppColors.textSecondary,
            ),
            title: Text(
              'Change Profile Picture',
              style: AppTypography.bodyL.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Navigator.pop(sheetCtx);
              _changeProfilePhoto(context, ref);
            },
          ),
          const SizedBox(height: AppTheme.spaceM),
        ],
      ),
    ),
  );
}

/// Picks an image from the gallery, then lets the user crop/reposition it
/// into the circular profile-photo frame before it's saved — same pattern
/// most apps use for avatar uploads. Stored as a local file path for now;
/// there's no backend to upload to yet.
Future<void> _changeProfilePhoto(BuildContext context, WidgetRef ref) async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    imageQuality: 90,
  );
  if (picked == null) return;

  final cropped = await ImageCropper().cropImage(
    sourcePath: picked.path,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 90,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Edit Photo',
        toolbarColor: AppColors.accent,
        toolbarWidgetColor: Colors.white,
        cropStyle: CropStyle.circle,
        lockAspectRatio: true,
      ),
      IOSUiSettings(
        title: 'Edit Photo',
        cropStyle: CropStyle.circle,
        aspectRatioLockEnabled: true,
        aspectRatioPickerButtonHidden: true,
      ),
    ],
  );
  if (cropped == null) return;

  await ref
      .read(userProfileProvider.notifier)
      .update((p) => p.copyWith(photoPath: cropped.path));
}

// ── Connect button (toggles connect / connected) ──────────────────────────────

class _ConnectButton extends StatefulWidget {
  const _ConnectButton({required this.initiallyConnected});

  final bool initiallyConnected;

  @override
  State<_ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<_ConnectButton> {
  late bool _connected;

  @override
  void initState() {
    super.initState();
    _connected = widget.initiallyConnected;
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => setState(() => _connected = !_connected),
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: _connected ? AppColors.bgSurface : AppColors.accent,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: _connected
                ? AppColors.accentSecondary.withValues(alpha: 0.5)
                : AppColors.accent,
          ),
          boxShadow: _connected
              ? null
              : [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Text(
          _connected ? 'Friends' : 'Add Friend',
          style: AppTypography.bodyS.copyWith(
            color: _connected ? AppColors.textSecondary : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.isLink = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool isLink;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: AppTheme.iconM),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            value,
            style: AppTypography.bodyM.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelS.copyWith(
              color: isLink ? AppColors.accent : AppColors.textMuted,
              fontSize: 10,
              fontWeight: isLink ? FontWeight.w600 : FontWeight.w400,
              letterSpacing: 0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
