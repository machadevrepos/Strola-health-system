import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/formatters.dart';
import 'package:strola_health/core/utils/haptics_helper.dart';
import 'package:strola_health/presentation/screens/challenge_of_the_month_screen.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/header_actions.dart';

/// Standalone Challenges screen (pushed, e.g. from the profile stats).
/// The actual content lives in [ChallengesView] so it can also be embedded as
/// a tab inside the Community screen.
class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // When shown as a shell tab (nothing to pop), keep the FAB clear of the
    // bottom nav bar MainShell draws over the body — just enough to clear
    // navBarHeight (64) plus a typical safe-area inset, not the generous
    // 120 Home/Community use at the very end of a long scroll (here it sat
    // at the top of mostly-empty space instead, pushing the FAB up high).
    final isTab = !Navigator.of(context).canPop();
    final navClearance = isTab ? 84.0 : 0.0;

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
                      mini: true,
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
                        size: AppTheme.iconL,
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
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ChallengeOfTheMonthScreen(),
            ),
          ),
          child: const _ChallengeOfTheMonthCard(),
        ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.06),
        const SizedBox(height: 15), // sectionGap (14) + 10%

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
        const SizedBox(height: 9), // spaceS (8) + 10%
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
          ),
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
                child: const Icon(AppIcons.trophy, color: AppColors.accent, size: AppTheme.iconM),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentSecondary.withValues(alpha: 0.30),
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Pink hero zone — title, date, description + image placeholder.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 15, 18, 13),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.bgDeep,
                    AppColors.accentSecondary.withValues(alpha: 0.35),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
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
                        const SizedBox(height: 11),
                        Text(
                          'May Walking Challenge',
                          style: AppTypography.titleL.copyWith(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 7),
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
                        const SizedBox(height: 9),
                        Text(
                          'Step more, move together, and finish May stronger '
                          'than you started!',
                          style: AppTypography.bodyS.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 0,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceS),
                  const _ChallengePathIllustration(),
                ],
              ),
            ),

            // White stats + CTA zone.
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 13, 18, 15),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: _ChallengeStat(
                          icon: AppIcons.groups,
                          value: '1,248',
                          label: 'Participants',
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceM),
                      Container(
                        width: 1,
                        height: 35,
                        color: AppColors.accentSecondary.withValues(alpha: 0.25),
                      ),
                      const SizedBox(width: AppTheme.spaceM),
                      const Expanded(
                        child: _ChallengeStat(
                          icon: AppIcons.star,
                          value: '12 days left',
                          label: 'to join and participate',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
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
                        padding: const EdgeInsets.symmetric(vertical: 13),
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
                  const SizedBox(height: 9),
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
            ),
          ],
        ),
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
                  color: AppColors.accent,
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

/// Placeholder for the real "May Walking Challenge" illustration asset —
/// swap the Icon for an Image.asset(...) once the art is ready.
class _ChallengePathIllustration extends StatelessWidget {
  const _ChallengePathIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 97,
      height: 132,
      decoration: BoxDecoration(
        color: AppColors.accentSecondary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: AppColors.accentSecondary.withValues(alpha: 0.5),
        ),
      ),
      child: const Center(
        child: Icon(
          AppIcons.image,
          color: AppColors.accent,
          size: AppTheme.iconXL,
        ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 13,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: AppColors.accentSecondary.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.accent, size: 18),
          ),
          const SizedBox(height: 7),
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
          const SizedBox(height: 9),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
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
          const SizedBox(height: 4),
          Text(
            name,
            style: AppTypography.labelM.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 2),
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

  // (name, dateRange, rank, totalParticipants, totalSteps, color)
  static const _challenges = <(String, String, int, int, int, Color)>[
    (
      'Spring Step Showdown',
      'Apr 1 – Apr 14, 2024',
      1,
      12,
      128543,
      AppColors.goalAmber,
    ),
    (
      '10K Steps a Day',
      'Mar 10 – Mar 23, 2024',
      2,
      20,
      157832,
      Color(0xFF0891B2),
    ),
    (
      'March Madness Steps',
      'Feb 25 – Mar 9, 2024',
      3,
      15,
      101245,
      Color(0xFFD97706),
    ),
    (
      "Valentine's Step Challenge",
      'Feb 1 – Feb 14, 2024',
      4,
      18,
      88731,
      AppColors.success,
    ),
    (
      'New Year, New Steps',
      'Jan 1 – Jan 14, 2024',
      1,
      10,
      112894,
      Color(0xFF7C3AED),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        _CompletedBanner(completedCount: _challenges.length)
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
                      dateRange: e.value.$2,
                      rank: e.value.$3,
                      totalParticipants: e.value.$4,
                      totalSteps: e.value.$5,
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
  const _CompletedBanner({required this.completedCount});

  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _CompletedTrophyBadge(),
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
                  'You completed $completedCount challenges. Keep it up '
                  'and crush your next goal!',
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
    );
  }
}

/// White circle + trophy, with a small green check badge — matches the
/// simple "Great job!" banner emblem (no sparkles/laurels here).
class _CompletedTrophyBadge extends StatelessWidget {
  const _CompletedTrophyBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.trophy,
              color: AppColors.success,
              size: 28,
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                AppIcons.check,
                color: Colors.white,
                size: 12,
              ),
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
    required this.dateRange,
    required this.rank,
    required this.totalParticipants,
    required this.totalSteps,
    required this.color,
  });

  final String name;
  final String dateRange;
  final int rank;
  final int totalParticipants;
  final int totalSteps;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FlatCard(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RankBadge(
            rank: rank,
            totalParticipants: totalParticipants,
            color: color,
          ),
          const SizedBox(width: AppTheme.spaceM),
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
                  'Step challenge',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceS,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        AppIcons.goalReached,
                        color: AppColors.success,
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Completed',
                        style: AppTypography.labelS.copyWith(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceS),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.stepCount(totalSteps),
                style: AppTypography.titleS.copyWith(fontWeight: FontWeight.w800),
              ),
              Text('Total Steps', style: AppTypography.labelS.copyWith(fontSize: 9)),
              const SizedBox(height: AppTheme.spaceXS),
              const Icon(
                AppIcons.chevronRight,
                color: AppColors.textMuted,
                size: AppTheme.iconS,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({
    required this.rank,
    required this.totalParticipants,
    required this.color,
  });

  final int rank;
  final int totalParticipants;
  final Color color;

  String get _ordinal => switch (rank) {
    1 => '1st',
    2 => '2nd',
    3 => '3rd',
    _ => '${rank}th',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.trophy, color: Colors.white, size: AppTheme.iconS),
          const SizedBox(height: 2),
          Text(
            _ordinal,
            style: AppTypography.titleS.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'of $totalParticipants',
            style: AppTypography.labelS.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CREATE CHALLENGE
// ═══════════════════════════════════════════════════════════════════════════════

class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  static const _durationLabels = ['7 Days', '14 Days', '30 Days', 'Custom'];

  String _name = '';
  int _durationIndex = 0;
  DateTime? _startDate;
  DateTime? _customEndDate;
  int? _winnerMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSurface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      AppIcons.back,
                      color: AppColors.accent,
                      size: AppTheme.iconM,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Create Challenge',
                      style: AppTypography.titleL.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: AppTheme.iconM),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Set up your challenge and invite friends to join!',
                textAlign: TextAlign.center,
                style: AppTypography.bodyS.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceL),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('Challenge Name'),
                    const SizedBox(height: AppTheme.spaceS),
                    TextField(
                      maxLength: 40,
                      onChanged: (v) => setState(() => _name = v),
                      decoration: InputDecoration(
                        counterText: '',
                        prefixIcon: const Icon(
                          AppIcons.trophy,
                          color: AppColors.accent,
                          size: AppTheme.iconS,
                        ),
                        hintText: 'e.g., Weekend Warriors',
                        hintStyle: AppTypography.bodyM.copyWith(
                          color: AppColors.textMuted,
                        ),
                        filled: true,
                        fillColor: AppColors.bgSurface,
                        border: _fieldBorder(),
                        enabledBorder: _fieldBorder(),
                        focusedBorder: _fieldBorder(focused: true),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: AppTheme.spaceM),
                          child: Align(
                            widthFactor: 1,
                            child: Text(
                              '${_name.length}/40',
                              style: AppTypography.labelS,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceXL),
                    const _SectionLabel('Duration'),
                    const SizedBox(height: 2),
                    Text(
                      'How long will the challenge last?',
                      style: AppTypography.bodyS.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Row(
                      children: [
                        for (var i = 0; i < _durationLabels.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppTheme.spaceS),
                          Expanded(
                            child: _DurationChip(
                              label: _durationLabels[i],
                              selected: _durationIndex == i,
                              onTap: () {
                                HapticsHelper.selection();
                                setState(() => _durationIndex = i);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppTheme.spaceXL),
                    const _SectionLabel('Start Date'),
                    const SizedBox(height: 2),
                    Text(
                      'When will the challenge begin?',
                      style: AppTypography.bodyS.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    _DateField(
                      label: _startDate == null
                          ? 'Select start date'
                          : _formatDate(_startDate!),
                      filled: _startDate != null,
                      onTap: () => _pickStartDate(context),
                    ),

                    if (_durationIndex == 3) ...[
                      const SizedBox(height: AppTheme.spaceL),
                      const _SectionLabel('End Date'),
                      const SizedBox(height: AppTheme.spaceS),
                      _DateField(
                        label: _customEndDate == null
                            ? 'Select end date'
                            : _formatDate(_customEndDate!),
                        filled: _customEndDate != null,
                        onTap: () => _pickCustomEndDate(context),
                      ),
                    ],

                    const SizedBox(height: AppTheme.spaceXL),
                    const _SectionLabel('Winner Determination'),
                    const SizedBox(height: 2),
                    Text(
                      'How should the winner be determined?',
                      style: AppTypography.bodyS.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    FlatCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _WinnerMethodOption(
                            icon: AppIcons.steps,
                            title: 'Most Steps',
                            description:
                                'Participant with the highest total steps during the challenge.',
                            selected: _winnerMethod == 0,
                            onTap: () {
                              HapticsHelper.selection();
                              setState(() => _winnerMethod = 0);
                            },
                          ),
                          Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spaceL,
                            ),
                            color: AppColors.accentSecondary.withValues(
                              alpha: 0.15,
                            ),
                          ),
                          _WinnerMethodOption(
                            icon: AppIcons.target,
                            title: 'Highest Goal Completion %',
                            description:
                                'Participant with the highest average daily goal '
                                'completion percentage during the challenge.',
                            selected: _winnerMethod == 1,
                            onTap: () {
                              HapticsHelper.selection();
                              setState(() => _winnerMethod = 1);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceM),
                      decoration: BoxDecoration(
                        color: AppColors.accentSecondary.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            AppIcons.info,
                            color: AppColors.accent,
                            size: AppTheme.iconS,
                          ),
                          const SizedBox(width: AppTheme.spaceS),
                          Expanded(
                            child: Text(
                              "Everyone's personal daily step goal (from "
                              'their profile) is used to calculate goal '
                              'completion %.',
                              style: AppTypography.labelS.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceXL),
                    const _SectionLabel('Invite Friends (Optional)'),
                    const SizedBox(height: 2),
                    Text(
                      'Invite friends to join your challenge.',
                      style: AppTypography.bodyS.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _InviteOptionCard(
                            icon: AppIcons.people,
                            title: 'Select Friends',
                            description: 'Choose from your connections',
                            onTap: () =>
                                _showComingSoon(context, 'Selecting friends'),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceM),
                        Expanded(
                          child: _InviteOptionCard(
                            icon: AppIcons.link,
                            title: 'Share Invite Link',
                            description: 'Anyone with the link can join',
                            onTap: () =>
                                _showComingSoon(context, 'Invite links'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _createChallenge(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Create Challenge',
                    style: AppTypography.bodyL.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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

  OutlineInputBorder _fieldBorder({bool focused = false}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        borderSide: BorderSide(
          color: focused
              ? AppColors.accent
              : AppColors.accentSecondary.withValues(alpha: 0.3),
          width: focused ? 1.5 : 1,
        ),
      );

  Future<void> _pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickCustomEndDate(BuildContext context) async {
    final earliest = _startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customEndDate ?? earliest.add(const Duration(days: 7)),
      firstDate: earliest,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _customEndDate = picked);
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon')),
    );
  }

  void _createChallenge(BuildContext context) {
    if (_name.trim().isEmpty) {
      _showValidationError(context, 'Give your challenge a name first');
      return;
    }
    if (_startDate == null) {
      _showValidationError(context, 'Pick a start date');
      return;
    }
    if (_winnerMethod == null) {
      _showValidationError(context, 'Choose how the winner is determined');
      return;
    }
    HapticsHelper.lightImpact();
    Navigator.pop(context);
  }

  void _showValidationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentSecondary.withValues(alpha: 0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : AppColors.accentSecondary.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.calendar,
              color: selected ? AppColors.accent : AppColors.textMuted,
              size: AppTheme.iconXS,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelM.copyWith(
                  color: selected ? AppColors.accent : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceM,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: AppColors.accentSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              AppIcons.calendar,
              color: AppColors.accent,
              size: AppTheme.iconS,
            ),
            const SizedBox(width: AppTheme.spaceS),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyM.copyWith(
                  color: filled ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ),
            const Icon(
              AppIcons.chevronRight,
              color: AppColors.textMuted,
              size: AppTheme.iconS,
            ),
          ],
        ),
      ),
    );
  }
}

class _WinnerMethodOption extends StatelessWidget {
  const _WinnerMethodOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentSecondary.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.accent, size: AppTheme.iconS),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleS),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.bodyS.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceS),
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.accent
                      : AppColors.accentSecondary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteOptionCard extends StatelessWidget {
  const _InviteOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FlatCard(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accentSecondary.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.accent,
                    size: AppTheme.iconS,
                  ),
                ),
                const Spacer(),
                const Icon(
                  AppIcons.chevronRight,
                  color: AppColors.textMuted,
                  size: AppTheme.iconS,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceS),
            Text(title, style: AppTypography.titleS.copyWith(fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              description,
              style: AppTypography.labelS.copyWith(height: 1.3),
            ),
          ],
        ),
      ),
    );
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
      text.toUpperCase(),
      style: AppTypography.labelM.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }
}
