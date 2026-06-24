import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/haptics_helper.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/header_actions.dart';

/// Standalone Challenges screen (pushed, e.g. from the profile stats).
/// The actual content lives in [ChallengesView] so it can also be embedded as
/// a tab inside the Community screen.
class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // When shown as a shell tab (nothing to pop), keep the FAB and the list
    // clear of the bottom nav bar that MainShell draws over the body.
    final isTab = !Navigator.of(context).canPop();
    final navClearance = isTab ? AppTheme.navBarHeight + AppTheme.spaceM : 0.0;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    if (Navigator.of(context).canPop()) ...[
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          AppIcons.back,
                          color: AppColors.textPrimary,
                          size: AppTheme.iconL,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceS),
                    ],
                    Text(
                      'Challenges',
                      style: AppTypography.displayL.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                      ),
                    ).animate().fadeIn(duration: AppTheme.animSlow).slideX(begin: 0.12),
                    const Spacer(),
                    const HeaderActions(),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: navClearance),
                  child: const ChallengesView(),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: navClearance),
          child: Builder(
            builder: (context) =>
                FloatingActionButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreateChallengeScreen(),
                        ),
                      ),
                      backgroundColor: AppColors.accent,
                      elevation: 4,
                      shape: const CircleBorder(),
                      child: const Icon(
                        AppIcons.add,
                        color: Colors.white,
                        size: AppTheme.iconXXL,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms)
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      curve: Curves.easeOutBack,
                    ),
          ),
        ),
      ),
    );
  }
}

/// The Public / Private / Completed challenge tabs + content. Embeddable
/// anywhere with a bounded height (Community tab, or the standalone screen).
class ChallengesView extends StatefulWidget {
  const ChallengesView({super.key});

  @override
  State<ChallengesView> createState() => _ChallengesViewState();
}

class _ChallengesViewState extends State<ChallengesView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTab = 0;

  static const _tabLabels = [
    'Public Challenges',
    'Private Challenges',
    'Completed Challenges',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() => _selectedTab = _tabController.index);
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Underline sub-tab bar
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            separatorBuilder: (_, __) => const SizedBox(width: 18),
            itemCount: _tabLabels.length,
            itemBuilder: (context, i) {
              final isActive = i == _selectedTab;
              return GestureDetector(
                onTap: () => _tabController.animateTo(i),
                behavior: HitTestBehavior.opaque,
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _tabLabels[i],
                        style: AppTypography.bodyS.copyWith(
                          color: isActive ? AppColors.accent : AppColors.textMuted,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 7),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 2.5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          height: 1,
          color: AppColors.accentSecondary.withValues(alpha: 0.18),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              const _PublicChallengesTab(),
              _PrivateChallengesTab(
                onCreateTap: () => _openCreateChallenge(context),
              ),
              const _CompletedChallengesTab(),
            ],
          ),
        ),
      ],
    );
  }

  void _openCreateChallenge(BuildContext context) {
    HapticsHelper.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const CreateChallengeScreen(),
      ),
    );
  }
}

class _PublicChallengesTab extends StatelessWidget {
  const _PublicChallengesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        const _ChallengeOfTheMonthCard()
            .animate()
            .fadeIn(delay: 60.ms)
            .slideY(begin: 0.06),
        const SizedBox(height: 20),

        // Last Month's Winners
        Row(
          children: [
            const Icon(AppIcons.trophy, color: AppColors.accent, size: AppTheme.iconS),
            const SizedBox(width: 6),
            Text(
              "Last Month's Winners",
              style: AppTypography.bodyL.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Two ways to win, two champions!',
          style: AppTypography.labelM.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(
              child: _WinnerCard(
                icon: AppIcons.steps,
                title: 'Most Steps',
                subtitle: 'Total steps in the challenge',
                name: 'Sarah J.',
                value: '284,932',
                valueLabel: 'steps',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _WinnerCard(
                icon: AppIcons.target,
                title: 'Highest Goal Completion',
                subtitle: 'Highest average % of daily goal',
                name: 'Emily R.',
                value: '132%',
                valueLabel: 'of goal',
              ),
            ),
          ],
        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.06),

        const SizedBox(height: 14),

        // Badge banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.accentSecondary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.premium, color: AppColors.accent, size: AppTheme.iconM),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: Text(
                  'Everyone who joins earns a special badge when the '
                  'challenge is complete!',
                  style: AppTypography.labelM.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceS),
              const Icon(AppIcons.chevronRight, color: AppColors.textMuted, size: 18),
            ],
          ),
        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.06),
      ],
    );
  }
}

/// Hero card for the single featured "Challenge of the Month".
class _ChallengeOfTheMonthCard extends StatefulWidget {
  const _ChallengeOfTheMonthCard();

  @override
  State<_ChallengeOfTheMonthCard> createState() =>
      _ChallengeOfTheMonthCardState();
}

class _ChallengeOfTheMonthCardState extends State<_ChallengeOfTheMonthCard> {
  bool _joined = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.bgDeep,
            AppColors.accentSecondary.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentSecondary.withValues(alpha: 0.30),
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -6,
            right: -6,
            child: _ChallengePathIllustration(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(AppIcons.trophy, color: AppColors.accent, size: 13),
                    const SizedBox(width: AppTheme.spaceXS),
                    Text(
                      'Challenge of the Month',
                      style: AppTypography.labelS.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 64),
                child: Text(
                  'May Walking Challenge',
                  style: AppTypography.titleL.copyWith(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(AppIcons.calendar, color: AppColors.textMuted, size: 12),
                  const SizedBox(width: 5),
                  Text(
                    'May 1 – May 31',
                    style: AppTypography.labelM.copyWith(
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  'Step more, move together, and finish May stronger than '
                  'you started!',
                  style: AppTypography.bodyS.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Expanded(
                    child: _ChallengeStat(
                      icon: AppIcons.groups,
                      value: '1,248',
                      label: 'Participants',
                    ),
                  ),
                  SizedBox(width: AppTheme.spaceM),
                  Expanded(
                    child: _ChallengeStat(
                      icon: AppIcons.star,
                      value: '12 days left',
                      label: 'to join and participate',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    HapticsHelper.lightImpact();
                    setState(() => _joined = !_joined);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _joined
                        ? AppColors.success
                        : AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_joined) ...[
                        const Icon(AppIcons.goalReached, color: Colors.white, size: AppTheme.iconS),
                        const SizedBox(width: AppTheme.spaceS),
                      ],
                      Text(
                        _joined ? 'Joined' : 'Join Challenge',
                        style: AppTypography.bodyL.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceS),
              Text(
                'Join anytime! Your progress will count from the day you join.',
                textAlign: TextAlign.center,
                style: AppTypography.labelS.copyWith(
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChallengeStat extends StatelessWidget {
  const _ChallengeStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.accent, size: 15),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyM.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelS.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Decorative "walking path" motif (placeholder for a real illustration asset).
class _ChallengePathIllustration extends StatelessWidget {
  const _ChallengePathIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 6,
            right: 14,
            child: Icon(
              AppIcons.sun,
              color: AppColors.goalAmber.withValues(alpha: 0.45),
              size: 30,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Icon(
              AppIcons.park,
              color: AppColors.accent.withValues(alpha: 0.30),
              size: 50,
            ),
          ),
          Positioned(
            bottom: 6,
            left: 0,
            child: Icon(
              AppIcons.flora,
              color: AppColors.accentSecondary.withValues(alpha: 0.55),
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

/// Winner card for the "Last Month's Winners" leaderboard recap.
class _WinnerCard extends StatelessWidget {
  const _WinnerCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.name,
    required this.value,
    required this.valueLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String name;
  final String value;
  final String valueLabel;

  @override
  Widget build(BuildContext context) {
    return FlatCard(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentSecondary.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.accent, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.bodyS.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.labelS.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accentSecondary.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentSecondary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    name[0],
                    style: AppTypography.titleM.copyWith(
                      color: AppColors.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.trophy,
                    color: AppColors.goalAmber,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: AppTypography.labelM.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleM.copyWith(
              color: AppColors.accent,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          Text(
            valueLabel,
            style: AppTypography.labelS.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Decorative "friends with trophy" motif (placeholder for a real asset).
class _TrophyCluster extends StatelessWidget {
  const _TrophyCluster();

  @override
  Widget build(BuildContext context) {
    Widget avatar(double size, Color color) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(AppIcons.profile, color: Colors.white, size: size * 0.55),
    );

    return SizedBox(
      width: 76,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: avatar(34, AppColors.accentSecondary),
          ),
          Positioned(right: 0, bottom: 0, child: avatar(34, AppColors.accent)),
          Positioned(
            left: 21,
            bottom: 10,
            child: avatar(34, AppColors.accent),
          ),
          const Positioned(
            top: 0,
            left: 26,
            child: Icon(AppIcons.trophy, color: AppColors.goalAmber, size: 26),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PRIVATE CHALLENGES TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _PrivateChallengesTab extends StatelessWidget {
  const _PrivateChallengesTab({required this.onCreateTap});

  final VoidCallback onCreateTap;

  // (name, subtitle, dateRange, daysLeft, progress, members, icon, color)
  static const _challenges =
      <(String, String, String, String, double, int, IconData, Color)>[
        (
          'Weekend Warrior',
          'Step challenge',
          'May 11 – May 17, 2024',
          '3 days left',
          0.72,
          2,
          AppIcons.trophy,
          AppColors.error,
        ),
        (
          '5K in May',
          'Distance challenge',
          'May 1 – May 31, 2024',
          '10 days left',
          0.66,
          1,
          AppIcons.run,
          AppColors.accentSecondary,
        ),
        (
          '14 Day Fitness Streak',
          'Streak challenge',
          'Apr 28 – May 11, 2024',
          '2 days left',
          0.85,
          3,
          AppIcons.streak,
          AppColors.accent,
        ),
        (
          'Family Steps Challenge',
          'Step challenge',
          'Apr 20 – May 20, 2024',
          '19 days left',
          0.40,
          4,
          AppIcons.steps,
          AppColors.success,
        ),
        (
          'Active Hour Challenge',
          'Active Time challenge',
          'Apr 15 – May 15, 2024',
          '14 days left',
          0.55,
          2,
          AppIcons.duration,
          AppColors.accent,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        _PrivateBanner(
          onCreateTap: onCreateTap,
        ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.06),
        const SizedBox(height: 18),

        Row(
          children: [
            Text(
              'Your Private Challenges',
              style: AppTypography.bodyL.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            Text(
              'Sort by: Recent',
              style: AppTypography.labelS.copyWith(
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
            const Icon(AppIcons.expandMore, color: AppColors.textMuted, size: 14),
          ],
        ),
        const SizedBox(height: 12),

        ..._challenges.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child:
                _PrivateChallengeCard(
                      name: e.value.$1,
                      subtitle: e.value.$2,
                      dateRange: e.value.$3,
                      daysLeft: e.value.$4,
                      progress: e.value.$5,
                      members: e.value.$6,
                      icon: e.value.$7,
                      color: e.value.$8,
                    )
                    .animate(delay: Duration(milliseconds: 80 + e.key * 60))
                    .fadeIn()
                    .slideY(begin: 0.06),
          ),
        ),

        const SizedBox(height: 8),

        // Privacy note
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.accentSecondary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(AppIcons.lock, color: AppColors.textMuted, size: AppTheme.iconS),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Only people you invite can see and join these private '
                  'challenges.',
                  style: AppTypography.labelS.copyWith(
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceS),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Learn More',
                  style: AppTypography.labelS.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}

class _PrivateBanner extends StatelessWidget {
  const _PrivateBanner({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.bgDeep,
            AppColors.accentSecondary.withValues(alpha: 0.30),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.accentSecondary.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create and join private\nchallenges with friends,\nfamily, or groups.',
                  style: AppTypography.bodyL.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stay motivated together and crush your goals!',
                  style: AppTypography.labelM.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: onCreateTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.add, color: Colors.white, size: AppTheme.iconS),
                        const SizedBox(width: 6),
                        Text(
                          'Create New Challenge',
                          style: AppTypography.bodyS.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const _TrophyCluster(),
        ],
      ),
    );
  }
}

class _PrivateChallengeCard extends StatelessWidget {
  const _PrivateChallengeCard({
    required this.name,
    required this.subtitle,
    required this.dateRange,
    required this.daysLeft,
    required this.progress,
    required this.members,
    required this.icon,
    required this.color,
  });

  final String name;
  final String subtitle;
  final String dateRange;
  final String daysLeft;
  final double progress;
  final int members;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FlatCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyM.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            style: AppTypography.labelS.copyWith(
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(AppIcons.calendar, color: AppColors.textMuted, size: 11),
                              const SizedBox(width: AppTheme.spaceXS),
                              Flexible(
                                child: Text(
                                  dateRange,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelS.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _MemberAvatars(extra: members),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: AppColors.accentSecondary.withValues(
                            alpha: 0.2,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      daysLeft,
                      style: AppTypography.labelS.copyWith(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(AppIcons.chevronRight, color: AppColors.textMuted, size: 18),
        ],
      ),
    );
  }
}

/// Overlapping member avatars + "+N" for a private challenge.
class _MemberAvatars extends StatelessWidget {
  const _MemberAvatars({required this.extra});

  final int extra;

  @override
  Widget build(BuildContext context) {
    const colors = [
      AppColors.accent,
      AppColors.accentSecondary,
      AppColors.goalAmber,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
          height: 22,
          child: Stack(
            children: List.generate(3, (i) {
              return Positioned(
                left: i * 11.0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: colors[i].withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(AppIcons.profile, color: Colors.white, size: 12),
                ),
              );
            }),
          ),
        ),
        if (extra > 0) ...[
          const SizedBox(width: 3),
          Text(
            '+$extra',
            style: AppTypography.labelS.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMPLETED CHALLENGES TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _CompletedChallengesTab extends StatelessWidget {
  const _CompletedChallengesTab();

  // (name, subtitle, dateRange, rank, icon, color)
  static const _challenges = <(String, String, String, int, IconData, Color)>[
    (
      '10K Steps a Day',
      '7-day step challenge',
      'Apr 29 – May 5, 2024',
      1,
      AppIcons.steps,
      AppColors.error,
    ),
    (
      'Run 20K This Week',
      '7-day running challenge',
      'Apr 22 – Apr 28, 2024',
      2,
      AppIcons.run,
      AppColors.accentSecondary,
    ),
    (
      '14 Day Streak',
      'Streak challenge',
      'Apr 10 – Apr 23, 2024',
      3,
      AppIcons.streak,
      AppColors.accent,
    ),
    (
      'April Step Challenge',
      'Monthly step challenge',
      'Apr 1 – Apr 30, 2024',
      1,
      AppIcons.steps,
      AppColors.success,
    ),
    (
      'Active Hour Challenge',
      '14-day active time challenge',
      'Mar 15 – Mar 28, 2024',
      2,
      AppIcons.duration,
      AppColors.accent,
    ),
    (
      'Workout Warrior',
      '7-day workout challenge',
      'Mar 5 – Mar 11, 2024',
      3,
      AppIcons.treadmill,
      AppColors.error,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        const _CompletedBanner()
            .animate()
            .fadeIn(delay: 60.ms)
            .slideY(begin: 0.06),
        const SizedBox(height: 18),

        Row(
          children: [
            Text(
              'Your Completed Challenges',
              style: AppTypography.bodyL.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            Text(
              'Sort by: Most Recent',
              style: AppTypography.labelS.copyWith(
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
            const Icon(AppIcons.expandMore, color: AppColors.textMuted, size: 14),
          ],
        ),
        const SizedBox(height: 12),

        ..._challenges.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child:
                _CompletedChallengeCard(
                      name: e.value.$1,
                      subtitle: e.value.$2,
                      dateRange: e.value.$3,
                      rank: e.value.$4,
                      icon: e.value.$5,
                      color: e.value.$6,
                    )
                    .animate(delay: Duration(milliseconds: 80 + e.key * 50))
                    .fadeIn()
                    .slideY(begin: 0.06),
          ),
        ),

        const SizedBox(height: 8),

        // Encouragement footer
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accentSecondary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.premium, color: AppColors.accent, size: AppTheme.iconM),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keep challenging yourself!',
                      style: AppTypography.bodyS.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      "You're building healthy habits and inspiring others.",
                      style: AppTypography.labelS.copyWith(
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spaceS),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceM,
                    vertical: AppTheme.spaceS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Text(
                    'Browse New\nChallenges',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelS.copyWith(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}

class _CompletedBanner extends StatelessWidget {
  const _CompletedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.bgDeep,
            AppColors.accentSecondary.withValues(alpha: 0.30),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.accentSecondary.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _CompletedTrophy(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Great job!',
                      style: AppTypography.titleM.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXS),
                    Text(
                      'Celebrate your achievements and keep up the amazing work.',
                      style: AppTypography.labelM.copyWith(
                        height: 1.4,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              _CompletedStat(
                icon: AppIcons.friends,
                color: AppColors.accent,
                value: '23',
                label: 'Challenges\nCompleted',
              ),
              _CompletedStat(
                icon: AppIcons.trophy,
                color: AppColors.goalAmber,
                value: '12',
                label: 'First Place\nFinishes',
              ),
              _CompletedStat(
                icon: AppIcons.premium,
                color: AppColors.accent,
                value: '8',
                label: 'Top 3\nFinishes',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Celebratory gold-trophy emblem with sparkles (placeholder for a real asset).
class _CompletedTrophy extends StatelessWidget {
  const _CompletedTrophy();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.goalAmber.withValues(alpha: 0.12),
            ),
          ),
          // Laurel hint (two faded leaves)
          Positioned(
            left: 4,
            child: Transform.rotate(
              angle: 0.5,
              child: Icon(
                AppIcons.ecology,
                color: AppColors.goalAmber.withValues(alpha: 0.45),
                size: 30,
              ),
            ),
          ),
          Positioned(
            right: 4,
            child: Transform.rotate(
              angle: -0.5,
              child: Transform.flip(
                flipX: true,
                child: Icon(
                  AppIcons.ecology,
                  color: AppColors.goalAmber.withValues(alpha: 0.45),
                  size: 30,
                ),
              ),
            ),
          ),
          const Icon(AppIcons.trophy, color: AppColors.goalAmber, size: 52),
          // Sparkles
          const Positioned(
            top: 6,
            right: 14,
            child: Icon(AppIcons.sparkle, color: AppColors.goalAmber, size: 14),
          ),
          Positioned(
            bottom: 14,
            left: 10,
            child: Icon(
              AppIcons.sparkle,
              color: AppColors.goalAmber.withValues(alpha: 0.7),
              size: 10,
            ),
          ),
          const Positioned(
            top: 18,
            left: 16,
            child: Icon(AppIcons.star, color: AppColors.goalAmber, size: 9),
          ),
        ],
      ),
    );
  }
}

class _CompletedStat extends StatelessWidget {
  const _CompletedStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: AppTheme.iconS),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            value,
            style: AppTypography.titleM.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelS.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedChallengeCard extends StatelessWidget {
  const _CompletedChallengeCard({
    required this.name,
    required this.subtitle,
    required this.dateRange,
    required this.rank,
    required this.icon,
    required this.color,
  });

  final String name;
  final String subtitle;
  final String dateRange;
  final int rank;
  final IconData icon;
  final Color color;

  static const _rankColors = {
    1: AppColors.goalAmber,
    2: AppColors.textMuted,
    3: AppColors.goalAmber,
  };

  String get _rankLabel => switch (rank) {
    1 => '1st',
    2 => '2nd',
    _ => '3rd',
  };

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColors[rank] ?? AppColors.textMuted;
    return FlatCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyM.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelS.copyWith(
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Row(
                  children: [
                    const Icon(
                      AppIcons.calendar,
                      color: AppColors.textMuted,
                      size: 11,
                    ),
                    const SizedBox(width: AppTheme.spaceXS),
                    Flexible(
                      child: Text(
                        dateRange,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelS.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Row(
                  children: [
                    const Icon(
                      AppIcons.goalReached,
                      color: AppColors.success,
                      size: 12,
                    ),
                    const SizedBox(width: AppTheme.spaceXS),
                    Text(
                      'You finished',
                      style: AppTypography.labelS.copyWith(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const _MemberAvatars(extra: 0),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.trophy, color: rankColor, size: AppTheme.iconM),
              const SizedBox(height: 1),
              Text(
                _rankLabel,
                style: AppTypography.labelS.copyWith(
                  color: rankColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppTheme.spaceXS),
          const Icon(
            AppIcons.chevronRight,
            color: AppColors.textMuted,
            size: AppTheme.iconS,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CREATE CHALLENGE WIZARD
// ═══════════════════════════════════════════════════════════════════════════════

class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  int _step = 0;
  String _name = '';
  int _typeIndex = 0;
  String _goal = '10,000';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  static const _types = <(IconData, String, Color)>[
    (AppIcons.steps, 'Steps', AppColors.success),
    (AppIcons.location, 'Distance', AppColors.accent),
    (AppIcons.duration, 'Active Time', AppColors.accent),
    (AppIcons.treadmill, 'Workouts', AppColors.error),
    (AppIcons.calories, 'Calories', AppColors.accent),
  ];

  static const _iconOptions = <(IconData, Color)>[
    (AppIcons.trophy, AppColors.error),
    (AppIcons.steps, AppColors.success),
    (AppIcons.target, AppColors.accent),
    (AppIcons.goal, AppColors.accent),
    (AppIcons.star, AppColors.goalAmber),
    (AppIcons.celebration, AppColors.accent),
  ];

  int _selectedIcon = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSurface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_step > 0) {
                        setState(() => _step--);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: const Icon(AppIcons.back, color: AppColors.textPrimary),
                  ),
                  Expanded(
                    child: Text(
                      'Create New Challenge',
                      style: AppTypography.titleM.copyWith(letterSpacing: -0.3),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Row(
                children: List.generate(3, (i) {
                  final isActive = i == _step;
                  final isDone = i < _step;
                  return Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive || isDone
                                ? AppColors.accent
                                : AppColors.accentSecondary.withValues(
                                    alpha: 0.2,
                                  ),
                            border: Border.all(
                              color: isActive || isDone
                                  ? AppColors.accent
                                  : AppColors.accentSecondary.withValues(
                                      alpha: 0.4,
                                    ),
                            ),
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(AppIcons.check, color: Colors.white, size: 14)
                                : Text(
                                    '${i + 1}',
                                    style: AppTypography.labelM.copyWith(
                                      color: isActive ? Colors.white : AppColors.textMuted,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0,
                                    ),
                                  ),
                          ),
                        ),
                        if (i < 2) ...[
                          Expanded(
                            child: Container(
                              height: 2,
                              color: isDone
                                  ? AppColors.accent
                                  : AppColors.accentSecondary.withValues(
                                      alpha: 0.2,
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 6),

            // Step labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Challenge Info',
                    style: AppTypography.labelS.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    'Settings',
                    style: AppTypography.labelS.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    'Invite',
                    style: AppTypography.labelS.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _step == 0
                    ? _buildStep1()
                    : _step == 1
                    ? _buildStep2()
                    : _buildStep3(),
              ),
            ),

            // Next button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    HapticsHelper.lightImpact();
                    if (_step < 2) {
                      setState(() => _step++);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _step == 2
                        ? 'Create Challenge'
                        : 'Next: ${['Settings', 'Invite', ''][_step]}',
                    style: AppTypography.bodyL.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Challenge Name'),
        const SizedBox(height: 8),
        TextField(
          onChanged: (v) => setState(() => _name = v),
          decoration: InputDecoration(
            hintText: 'e.g., Weekend Warrior',
            hintStyle: AppTypography.bodyM.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 0,
            ),
            filled: true,
            fillColor: AppColors.bgSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.accentSecondary.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.accentSecondary.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            suffix: Text(
              '${_name.length}/60',
              style: AppTypography.labelS.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        const _SectionLabel('Challenge Type'),
        const SizedBox(height: 4),
        Text(
          'Choose the type of activity for your challenge.',
          style: AppTypography.labelM.copyWith(letterSpacing: 0),
        ),
        const SizedBox(height: 10),
        Row(
          children: _types.asMap().entries.map((e) {
            final isSelected = e.key == _typeIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticsHelper.selection();
                  setState(() => _typeIndex = e.key);
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: e.key < _types.length - 1 ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.accentSecondary.withValues(alpha: 0.3),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(e.value.$1, color: e.value.$3, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        e.value.$2,
                        style: AppTypography.labelS.copyWith(
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          letterSpacing: 0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        const _SectionLabel('Challenge Description (Optional)'),
        const SizedBox(height: 8),
        TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add a fun description to inspire your participants...',
            hintStyle: AppTypography.bodyS.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 0,
            ),
            filled: true,
            fillColor: AppColors.bgSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.accentSecondary.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.accentSecondary.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 20),

        const _SectionLabel('Challenge Icon'),
        const SizedBox(height: 10),
        Row(
          children: _iconOptions.asMap().entries.map((e) {
            final isSelected = e.key == _selectedIcon;
            final color = e.value.$2;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticsHelper.selection();
                  setState(() => _selectedIcon = e.key);
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: e.key < _iconOptions.length - 1 ? 8 : 0,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(e.value.$1, color: color, size: 22),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Dates
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Start Date'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => _startDate = d);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.accentSecondary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            AppIcons.calendar,
                            color: AppColors.textMuted,
                            size: 15,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(_startDate),
                            style: AppTypography.bodyS.copyWith(
                              color: AppColors.textPrimary,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('End Date'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => _endDate = d);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.accentSecondary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            AppIcons.calendar,
                            color: AppColors.textMuted,
                            size: 15,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(_endDate),
                            style: AppTypography.bodyS.copyWith(
                              color: AppColors.textPrimary,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        const _SectionLabel('Challenge Goal'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: TextEditingController(text: _goal),
                onChanged: (v) => _goal = v,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bgSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.accentSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.accentSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.accent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.accentSecondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _types[_typeIndex].$2,
                      style: AppTypography.bodyS.copyWith(
                        color: AppColors.textPrimary,
                        letterSpacing: 0,
                      ),
                    ),
                    const Spacer(),
                    const Icon(AppIcons.expandMore, color: AppColors.textMuted, size: AppTheme.iconS),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(AppIcons.info, color: AppColors.accent, size: 14),
              const SizedBox(width: AppTheme.spaceS),
              Expanded(
                child: Text(
                  'This is the total ${_types[_typeIndex].$2.toLowerCase()} goal for the entire duration of the challenge. Participants need to reach this total from ${_formatDate(_startDate)} to ${_formatDate(_endDate)}.',
                  style: AppTypography.labelS.copyWith(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const _SectionLabel('Visibility'),
        const SizedBox(height: 4),
        Text(
          'This challenge will be private and only accessible to invited participants.',
          style: AppTypography.labelM.copyWith(letterSpacing: 0),
        ),
        const SizedBox(height: 10),
        FlatCard(
          padding: const EdgeInsets.all(AppTheme.spaceL),
          child: Row(
            children: [
              const Icon(AppIcons.lock, color: AppColors.accent, size: AppTheme.iconM),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Private Challenge',
                      style: AppTypography.bodyM.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      'Only people you invite can see and join this challenge.',
                      style: AppTypography.labelS.copyWith(
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(AppIcons.chevronRight, color: AppColors.textMuted, size: AppTheme.iconS),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Scoring'),
        const SizedBox(height: AppTheme.spaceS),
        FlatCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(AppIcons.leaderboard, color: AppColors.accent),
            title: Text(
              'Leaderboard (Most progress wins)',
              style: AppTypography.bodyS.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 0,
              ),
            ),
            trailing: const Icon(AppIcons.goalReached, color: AppColors.accent, size: AppTheme.iconM),
          ),
        ),
        const SizedBox(height: AppTheme.spaceXL),
        const _SectionLabel('Notifications'),
        const SizedBox(height: AppTheme.spaceS),
        FlatCard(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Daily reminders',
                  style: AppTypography.bodyS.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
                value: true,
                onChanged: null,
                activeTrackColor: AppColors.accent,
                activeThumbColor: Colors.white,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Milestone alerts',
                  style: AppTypography.bodyS.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
                value: true,
                onChanged: null,
                activeTrackColor: AppColors.accent,
                activeThumbColor: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Invite Friends'),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search friends...',
            hintStyle: AppTypography.bodyS.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 0,
            ),
            prefixIcon: const Icon(AppIcons.search, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.bgSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.accentSecondary.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.accentSecondary.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ...['Sarah J.', 'Alex M.', 'Priya K.', 'James L.'].asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child:
                FlatCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent.withValues(alpha: 0.15),
                            ),
                            child: Center(
                              child: Text(
                                e.value[0],
                                style: AppTypography.bodyL.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              e.value,
                              style: AppTypography.bodyM.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentSecondary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.accentSecondary.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Text(
                              'Invite',
                              style: AppTypography.labelM.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate(delay: Duration(milliseconds: e.key * 60))
                    .fadeIn()
                    .slideX(begin: 0.06),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
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

// ═══════════════════════════════════════════════════════════════════════════════
// SMALL SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyM.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }
}
