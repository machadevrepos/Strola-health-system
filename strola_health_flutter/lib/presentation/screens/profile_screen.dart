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
import 'package:strola_health/core/utils/streak.dart';
import 'package:strola_health/data/repositories/friend_repository.dart';
import 'package:strola_health/data/repositories/public_profile_repository.dart';
import 'package:strola_health/domain/entities/challenge.dart';
import 'package:strola_health/domain/entities/friend.dart';
import 'package:strola_health/domain/entities/public_profile.dart';
import 'package:strola_health/presentation/providers/challenge_providers.dart';
import 'package:strola_health/presentation/providers/community_providers.dart';
import 'package:strola_health/presentation/providers/friend_providers.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';
import 'package:strola_health/presentation/providers/session_providers.dart';
import 'package:strola_health/presentation/providers/step_providers.dart';
import 'package:strola_health/presentation/screens/achievements_screen.dart';
import 'package:strola_health/presentation/screens/challenges_screen.dart';
import 'package:strola_health/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:strola_health/presentation/screens/recent_activity_screen.dart';
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

    final streak = calcStreak(weekly, goal);
    final completedChallenges = (ref.watch(myChallengesProvider).value ?? const [])
        .where((c) => c.status == ChallengeStatus.archived)
        .length;

    // Shared with RecentActivityScreen's "View All" — same list, this is
    // just its first 4 entries, so the preview and full page always agree.
    final recentActivity = ref.watch(recentActivityProvider);

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
                                Stack(
                                  clipBehavior: Clip.none,
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
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: PressableScale(
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
                                _StatTile(
                                  icon: AppIcons.trophy,
                                  value: '$completedChallenges',
                                  label: 'Challenges\nCompleted',
                                  isLink: true,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ChallengesScreen(),
                                    ),
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
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RecentActivityScreen(),
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
                                const SizedBox(height: AppTheme.spaceM),
                                if (recentActivity.isEmpty)
                                  Text(
                                    'Start walking to see your activity here.',
                                    style: AppTypography.bodyS.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  )
                                else
                                  ...recentActivity
                                      .take(4)
                                      .toList()
                                      .asMap()
                                      .entries
                                      .map(
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
                                                        decoration:
                                                            BoxDecoration(
                                                              color: AppColors
                                                                  .accent
                                                                  .withValues(
                                                                    alpha: 0.1,
                                                                  ),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                        child: const Icon(
                                                          AppIcons.steps,
                                                          color:
                                                              AppColors.accent,
                                                          size: AppTheme.iconS,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          'Hit ${Formatters.stepCount(e.value.value)} steps',
                                                          style: AppTypography
                                                              .bodyL
                                                              .copyWith(
                                                                fontSize: 13,
                                                              ),
                                                        ),
                                                      ),
                                                      Text(
                                                        _relativeDate(
                                                          e.value.key,
                                                        ),
                                                        style: AppTypography
                                                            .labelS
                                                            .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              letterSpacing: 0,
                                                            ),
                                                      ),
                                                    ],
                                                  )
                                                  .animate(
                                                    delay: Duration(
                                                      milliseconds:
                                                          220 + e.key * 60,
                                                    ),
                                                  )
                                                  .fadeIn(
                                                    duration: AppTheme.animSlow,
                                                  )
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

  /// "Today" / "Yesterday" for the last couple of days, an unambiguous
  /// month+day for everything older — `Formatters.dayLabel` alone falls back
  /// to a bare weekday name past that, which is ambiguous over many weeks.
  String _relativeDate(DateTime date) {
    final label = Formatters.dayLabel(date);
    if (label == 'Today' || label == 'Yesterday') return label;
    return Formatters.fullDate(date);
  }
}

// ── Public Profile (viewed by others) ─────────────────────────────────────────

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(userId));
    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: Text(
            'Could not load this profile.',
            style: AppTypography.bodyM,
          ),
        ),
      ),
      data: (profile) => _PublicProfileBody(userId: userId, profile: profile),
    );
  }
}

class _PublicProfileBody extends ConsumerWidget {
  const _PublicProfileBody({required this.userId, required this.profile});

  final String userId;
  final PublicProfile profile;

  String get name => profile.displayName;
  String get username => profile.username;

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
                          clipBehavior: Clip.antiAlias,
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
                          child: profile.photoUrl != null
                              ? Image.network(
                                  profile.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    AppIcons.profile,
                                    color: AppColors.accent,
                                    size: 38,
                                  ),
                                )
                              : const Icon(
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
                              if (username.isNotEmpty)
                                Text(
                                  '@$username',
                                  style: AppTypography.bodyS.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _ConnectButton(userId: userId),
                      ],
                    ).animate().fadeIn(
                      delay: 50.ms,
                      duration: AppTheme.animSlow,
                    ),

                    const SizedBox(height: AppTheme.spaceM),

                    if (profile.showStats &&
                        (profile.streakCurrent ?? 0) > 0) ...[
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
                                  '${profile.streakCurrent} Day Streak',
                                  style: AppTypography.labelS.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceL),
                    ],

                    // Stats row — only what the backend actually exposes for
                    // another user (see PublicProfileRepository/
                    // getPublicProfiles): lifetime totals gated by their own
                    // "public profile" privacy toggle. Per-day steps,
                    // calories, and achievements aren't cross-user readable
                    // (firestore.rules scopes dailyActivity/userBadges to
                    // owner+admin only), so there's nothing real to show
                    // there instead of fabricating numbers.
                    if (profile.showStats)
                      FlatCard(
                            padding: const EdgeInsets.all(AppTheme.spaceL),
                            child: Row(
                              children: [
                                _StatTile(
                                  icon: AppIcons.streak,
                                  value: '${profile.streakCurrent ?? 0}',
                                  label: 'Day Streak',
                                ),
                                _StatTile(
                                  icon: AppIcons.trophy,
                                  value: '${profile.streakLongest ?? 0}',
                                  label: 'Longest\nStreak',
                                ),
                                _StatTile(
                                  icon: AppIcons.steps,
                                  value: Formatters.stepCount(
                                    profile.lifetimeSteps ?? 0,
                                  ),
                                  label: 'Lifetime\nSteps',
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 100.ms, duration: AppTheme.animSlow)
                          .slideY(begin: 0.12)
                    else
                      FlatCard(
                            padding: const EdgeInsets.all(AppTheme.spaceL),
                            child: Row(
                              children: [
                                const Icon(
                                  AppIcons.lock,
                                  color: AppColors.textMuted,
                                  size: AppTheme.iconM,
                                ),
                                const SizedBox(width: AppTheme.spaceM),
                                Expanded(
                                  child: Text(
                                    "$name's stats are private.",
                                    style: AppTypography.bodyS.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 100.ms, duration: AppTheme.animSlow)
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
                showReportSheet(
                  context,
                  subject: name,
                  targetType: 'user',
                  targetId: userId,
                );
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
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              try {
                await ref.read(blockedUsersProvider.notifier).block(userId);
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Could not block. Please try again.'),
                  ),
                );
                return;
              }
              navigator.pop(); // close dialog
              navigator.pop(); // close profile
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

/// Reflects and mutates real friendship state (`friendshipWithProvider` /
/// `FriendRepository`) rather than pure local toggle state. `_busy` guards
/// against double-taps while a callable is in flight.
class _ConnectButton extends ConsumerStatefulWidget {
  const _ConnectButton({required this.userId});

  final String userId;

  @override
  ConsumerState<_ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends ConsumerState<_ConnectButton> {
  bool _busy = false;

  Future<void> _handleTap(FriendshipStatus? status) async {
    setState(() => _busy = true);
    try {
      if (status == FriendshipStatus.accepted) {
        await ref.read(friendRepositoryProvider).removeFriend(widget.userId);
      } else if (status == FriendshipStatus.pending) {
        // A pending request the caller already sent — tapping again cancels
        // it via the same removeFriend callable (deletes the doc outright).
        await ref.read(friendRepositoryProvider).removeFriend(widget.userId);
      } else {
        await ref.read(friendRepositoryProvider).sendRequest(widget.userId);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      ref.invalidate(friendshipWithProvider(widget.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(friendshipWithProvider(widget.userId));
    final status = statusAsync.value;
    final connected = status == FriendshipStatus.accepted;
    final pending = status == FriendshipStatus.pending;

    return PressableScale(
      onTap: _busy ? null : () => _handleTap(status),
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: connected || pending ? AppColors.bgSurface : AppColors.accent,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: connected || pending
                ? AppColors.accentSecondary.withValues(alpha: 0.5)
                : AppColors.accent,
          ),
          boxShadow: connected || pending
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
          connected ? 'Friends' : (pending ? 'Requested' : 'Add Friend'),
          style: AppTypography.bodyS.copyWith(
            color: connected || pending
                ? AppColors.textSecondary
                : Colors.white,
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
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool isLink;

  /// Handled *inside* this widget (via [PressableScale], wrapping only the
  /// [Column] below) rather than by the caller wrapping the whole
  /// `_StatTile` externally — `Expanded` must be a direct child of the
  /// `Row` it sits in, and `PressableScale`'s `AnimatedScale` breaks that
  /// if it sits between them (`Incorrect use of ParentDataWidget` — this is
  /// exactly the bug that shape produced for the one tile that used to be
  /// wrapped externally).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
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
    );
    return Expanded(
      child: onTap == null
          ? content
          : PressableScale(onTap: onTap, child: content),
    );
  }
}
