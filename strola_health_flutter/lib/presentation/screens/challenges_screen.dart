import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/services/firebase_client.dart';
import 'package:strola_health/core/utils/formatters.dart';
import 'package:strola_health/core/utils/haptics_helper.dart';
import 'package:strola_health/domain/entities/challenge.dart';
import 'package:strola_health/presentation/providers/challenge_providers.dart';
import 'package:strola_health/presentation/screens/challenge_of_the_month_screen.dart';
import 'package:strola_health/presentation/screens/private_challenge_detail_screen.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/header_actions.dart';

/// Standalone Challenges screen (pushed, e.g. from the profile stats).
/// The actual content lives in [ChallengesView] so it can also be embedded as
/// a tab inside the Community screen.
class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // When shown as a shell tab (nothing to pop), MainShell draws its own
    // bottom nav bar and owns the create-challenge FAB itself (see
    // main_shell.dart) — Flutter can only auto-position a FAB above a
    // bottomNavigationBar that lives in the *same* Scaffold, so a FAB nested
    // in here had nothing real to position against. MainShell's Scaffold
    // also now correctly reserves space for that nav bar (no more
    // `extendBody`), so this screen doesn't need to guess any clearance for
    // it either — `Expanded` below is already sized to stop right above it.
    final isTab = !Navigator.of(context).canPop();

    final header = Padding(
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
    );

    final content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 14),
          const Expanded(child: ChallengesView()),
        ],
      ),
    );

    if (isTab) {
      // No nested Scaffold needed — MainShell's own Scaffold already
      // satisfies any Scaffold.of(context)/ScaffoldMessenger lookups below.
      return Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: content,
      );
    }

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: content,
        floatingActionButton:
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
                          color: isActive
                              ? AppColors.accent
                              : AppColors.textMuted,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
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

class _PublicChallengesTab extends ConsumerWidget {
  const _PublicChallengesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final officialAsync = ref.watch(officialChallengeProvider);
    final lastCompletedAsync = ref.watch(
      lastCompletedOfficialChallengeProvider,
    );
    final lastCompleted = lastCompletedAsync.asData?.value;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async {
        ref.invalidate(officialChallengeProvider);
        ref.invalidate(lastCompletedOfficialChallengeProvider);
      },
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          officialAsync
              .when(
                loading: () => const _PublicTabPlaceholder(
                  icon: AppIcons.trophy,
                  message: 'Loading this month\'s challenge…',
                ),
                error: (_, __) => const _PublicTabPlaceholder(
                  icon: AppIcons.error,
                  message: 'Could not load the challenge of the month.',
                ),
                data: (challenge) {
                  if (challenge == null) {
                    return const _PublicTabPlaceholder(
                      icon: AppIcons.trophy,
                      message:
                          "There's no official challenge running right "
                          'now. Check back soon!',
                    );
                  }
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChallengeOfTheMonthScreen(),
                      ),
                    ),
                    child: _ChallengeOfTheMonthCard(challenge: challenge),
                  );
                },
              )
              .animate()
              .fadeIn(delay: 60.ms)
              .slideY(begin: 0.06),

          if (lastCompleted != null) ...[
            const SizedBox(height: 15), // sectionGap (14) + 10%
            _LastMonthWinnersSection(challenge: lastCompleted),
          ],

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
                  child: const Icon(
                    AppIcons.trophy,
                    color: AppColors.accent,
                    size: AppTheme.iconM,
                  ),
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
                const Icon(
                  AppIcons.chevronRight,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.06),
        ],
      ),
    );
  }
}

/// Centered icon + message for the hero slot — loading/error/empty states,
/// matching the tone of `_EmptyBadgeRow` in achievements_screen.dart.
class _PublicTabPlaceholder extends StatelessWidget {
  const _PublicTabPlaceholder({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXXL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentSecondary.withValues(alpha: 0.30),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppTheme.iconXXL, color: AppColors.textMuted),
              const SizedBox(height: AppTheme.spaceM),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyM.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Last Month's Winners" — resolves the archived official challenge's
/// denormalized top-N standings and shows the "Most Steps" and "Highest
/// Goal Completion %" winners (they may or may not be the same person).
class _LastMonthWinnersSection extends ConsumerWidget {
  const _LastMonthWinnersSection({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topAsync = ref.watch(challengeLeaderboardTopProvider(challenge));
    return topAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (entries) {
        if (entries.isEmpty) return const SizedBox.shrink();
        final bySteps = [...entries]
          ..sort((a, b) => b.steps.compareTo(a.steps));
        final byPercent = [...entries]
          ..sort((a, b) => b.goalCompletionPct.compareTo(a.goalCompletionPct));
        final stepsWinner = bySteps.first;
        final percentWinner = byPercent.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  AppIcons.trophy,
                  color: AppColors.accent,
                  size: AppTheme.iconS,
                ),
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
                children: [
                  Expanded(
                    child: _WinnerCard(
                      icon: AppIcons.steps,
                      title: 'Most Steps',
                      subtitle: 'Total steps in the challenge',
                      name: stepsWinner.name,
                      initials: stepsWinner.initials,
                      value: Formatters.stepCount(stepsWinner.steps),
                      valueLabel: 'steps',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _WinnerCard(
                      icon: AppIcons.target,
                      title: 'Highest Goal Completion',
                      subtitle: 'Highest average % of daily goal',
                      name: percentWinner.name,
                      initials: percentWinner.initials,
                      value: '${percentWinner.goalCompletionPct}%',
                      valueLabel: 'of goal',
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.06),
          ],
        );
      },
    );
  }
}

/// Hero card for the single featured "Challenge of the Month".
class _ChallengeOfTheMonthCard extends ConsumerStatefulWidget {
  const _ChallengeOfTheMonthCard({required this.challenge});

  final Challenge challenge;

  @override
  ConsumerState<_ChallengeOfTheMonthCard> createState() =>
      _ChallengeOfTheMonthCardState();
}

class _ChallengeOfTheMonthCardState
    extends ConsumerState<_ChallengeOfTheMonthCard> {
  bool _joining = false;

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      await ref
          .read(myChallengesProvider.notifier)
          .join(challengeId: widget.challenge.id);
      ref.invalidate(officialChallengeProvider);
      HapticsHelper.lightImpact();
    } on BackendException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not join. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    final joined = challenge.isJoined;
    final imageUrl = challenge.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentSecondary.withValues(alpha: 0.30),
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Landscape challenge photo, full-bleed behind both zones below —
            // falls back to each zone's own plain background when no image
            // has been uploaded (admin-only, see updateChallenge.ts).
            if (hasImage)
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            if (hasImage)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black38, Colors.black45, Colors.black87],
                    ),
                  ),
                ),
              ),
            Column(
              children: [
                // Hero zone — pill, title, date, description.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 15, 18, 13),
                  decoration: hasImage
                      ? null
                      : BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.bgDeep,
                              AppColors.accentSecondary.withValues(
                                alpha: 0.35,
                              ),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: hasImage
                              ? Colors.white.withValues(alpha: 0.20)
                              : AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              AppIcons.trophy,
                              color: hasImage
                                  ? Colors.white
                                  : AppColors.accent,
                              size: 13,
                            ),
                            const SizedBox(width: AppTheme.spaceXS),
                            Text(
                              'Challenge of the Month',
                              style: AppTypography.labelS.copyWith(
                                color: hasImage
                                    ? Colors.white
                                    : AppColors.accent,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 11),
                      Text(
                        challenge.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleL.copyWith(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.15,
                          color: hasImage ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            AppIcons.calendar,
                            color: hasImage
                                ? Colors.white70
                                : AppColors.textMuted,
                            size: 12,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            formatChallengeDateRange(
                              challenge.startDate,
                              challenge.endDate,
                            ),
                            style: AppTypography.labelM.copyWith(
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0,
                              color: hasImage ? Colors.white70 : null,
                            ),
                          ),
                        ],
                      ),
                      if (challenge.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 9),
                        Text(
                          challenge.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyS.copyWith(
                            color: hasImage
                                ? Colors.white.withValues(alpha: 0.85)
                                : AppColors.textSecondary,
                            letterSpacing: 0,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Stats + CTA zone.
                Container(
                  width: double.infinity,
                  color: hasImage ? Colors.transparent : Colors.white,
                  padding: const EdgeInsets.fromLTRB(18, 13, 18, 15),
                  child: Column(
                    children: [
                      _ChallengeStat(
                        icon: AppIcons.star,
                        value: daysLeftLabel(challenge),
                        label: 'to join and participate',
                        light: hasImage,
                      ),
                      const SizedBox(height: 13),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: joined || _joining ? null : _join,
                          style: FilledButton.styleFrom(
                            backgroundColor: joined
                                ? AppColors.success
                                : AppColors.accent,
                            disabledBackgroundColor: joined
                                ? AppColors.success
                                : AppColors.accent.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: _joining
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (joined) ...[
                                      const Icon(
                                        AppIcons.goalReached,
                                        color: Colors.white,
                                        size: AppTheme.iconS,
                                      ),
                                      const SizedBox(width: AppTheme.spaceS),
                                    ],
                                    Text(
                                      joined ? 'Joined' : 'Join Challenge',
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
                          color: hasImage ? Colors.white70 : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
    this.light = false,
  });

  final IconData icon;
  final String value;
  final String label;

  /// True when this sits over a full-bleed challenge photo — swaps the
  /// accent-tinted styling for white/translucent so it stays legible on a
  /// dark overlay instead of disappearing against it.
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: light
                ? Colors.white.withValues(alpha: 0.20)
                : AppColors.accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: light ? Colors.white : AppColors.accent,
            size: 15,
          ),
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
                  color: light ? Colors.white : AppColors.accent,
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
                  color: light ? Colors.white70 : null,
                ),
              ),
            ],
          ),
        ),
      ],
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
    required this.initials,
    required this.value,
    required this.valueLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String name;
  final String initials;
  final String value;
  final String valueLabel;

  @override
  Widget build(BuildContext context) {
    return FlatCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
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
                    initials,
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
          Positioned(left: 21, bottom: 10, child: avatar(34, AppColors.accent)),
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

class _PrivateChallengesTab extends ConsumerWidget {
  const _PrivateChallengesTab({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(myChallengesProvider);

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => ref.read(myChallengesProvider.notifier).refresh(),
      child: ListView(
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
              const Icon(
                AppIcons.expandMore,
                color: AppColors.textMuted,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stale-while-revalidate: once we've ever loaded this, keep
          // showing it during a refresh instead of a blank spinner.
          if (challengesAsync.value != null)
            _PrivateChallengesList(all: challengesAsync.value!)
          else
            challengesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.spaceXXL),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
              error: (_, __) => const _TabEmptyMessage(
                icon: AppIcons.error,
                message: 'Could not load your private challenges.',
              ),
              data: (_) => const SizedBox.shrink(),
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
                const Icon(
                  AppIcons.lock,
                  color: AppColors.textMuted,
                  size: AppTheme.iconS,
                ),
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
      ),
    );
  }
}

class _PrivateChallengesList extends StatelessWidget {
  const _PrivateChallengesList({required this.all});

  final List<Challenge> all;

  @override
  Widget build(BuildContext context) {
    final challenges = all
        .where((c) => c.status != ChallengeStatus.archived)
        .toList();
    if (challenges.isEmpty) {
      return const _TabEmptyMessage(
        icon: AppIcons.challenge,
        message:
            "You haven't joined any private challenges yet. "
            'Create one or ask a friend to invite you!',
      );
    }
    return Column(
      children: [
        for (final entry in challenges.asMap().entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child:
                _PrivateChallengeCard(
                      challenge: entry.value,
                      color: challengeColorFor(entry.key, isMe: false),
                    )
                    .animate(delay: Duration(milliseconds: 80 + entry.key * 60))
                    .fadeIn()
                    .slideY(begin: 0.06),
          ),
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
                        const Icon(
                          AppIcons.add,
                          color: Colors.white,
                          size: AppTheme.iconS,
                        ),
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

class _PrivateChallengeCard extends ConsumerWidget {
  const _PrivateChallengeCard({required this.challenge, required this.color});

  final Challenge challenge;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(
      challengeLeaderboardProvider(challenge.id),
    );

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PrivateChallengeDetailScreen(
            challenge: challenge,
            accentColor: color,
          ),
        ),
      ),
      child: FlatCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leaderboardAsync.when(
              loading: () => _RankBadgePlaceholder(color: color),
              error: (_, __) => _RankBadgePlaceholder(color: color),
              data: (entries) {
                final myIndex = entries.indexWhere((e) => e.isMe);
                if (myIndex == -1) return _RankBadgePlaceholder(color: color);
                return _RankBadge(
                  rank: myIndex + 1,
                  totalParticipants: entries.length,
                  color: color,
                );
              },
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
                              challenge.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyM.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                            ),
                            if (challenge.description.trim().isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(
                                challenge.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelS.copyWith(
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
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
                                    formatChallengeDateRange(
                                      challenge.startDate,
                                      challenge.endDate,
                                      withYear: true,
                                    ),
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
                      leaderboardAsync.maybeWhen(
                        data: (entries) => _MemberAvatars(
                          extra: (entries.length - 3).clamp(0, 999),
                        ),
                        orElse: () => const SizedBox(width: 44, height: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: challenge.progress,
                            minHeight: 5,
                            backgroundColor: AppColors.accentSecondary
                                .withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        daysLeftLabel(challenge),
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
            const Icon(
              AppIcons.chevronRight,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
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
                  child: const Icon(
                    AppIcons.profile,
                    color: Colors.white,
                    size: 12,
                  ),
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

class _CompletedChallengesTab extends ConsumerWidget {
  const _CompletedChallengesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(myChallengesProvider);

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => ref.read(myChallengesProvider.notifier).refresh(),
      child: challengesAsync.value != null
          ? _CompletedChallengesList(all: challengesAsync.value!)
          : challengesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spaceXXL),
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
              error: (_, __) => const _TabEmptyMessage(
                icon: AppIcons.error,
                message: 'Could not load your completed challenges.',
              ),
              data: (_) => const SizedBox.shrink(),
            ),
    );
  }
}

class _CompletedChallengesList extends StatelessWidget {
  const _CompletedChallengesList({required this.all});

  final List<Challenge> all;

  @override
  Widget build(BuildContext context) {
    final challenges = all
        .where((c) => c.status == ChallengeStatus.archived)
        .toList();

    if (challenges.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: const [
          _TabEmptyMessage(
            icon: AppIcons.trophy,
            message: "You haven't completed any challenges yet.",
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        _CompletedBanner(
          completedCount: challenges.length,
        ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.06),
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
          ],
        ),
        const SizedBox(height: 12),

        ...challenges.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child:
                _CompletedChallengeEntry(
                      challenge: e.value,
                      color: challengeColorFor(e.key, isMe: false),
                    )
                    .animate(delay: Duration(milliseconds: 80 + e.key * 50))
                    .fadeIn()
                    .slideY(begin: 0.06),
          ),
        ),
      ],
    );
  }
}

/// Resolves one archived challenge's final standing from its denormalized
/// `leaderboard_top` (see ChallengeRepository.getLeaderboardTop) — the live
/// `participants` subcollection isn't the authoritative source once a
/// challenge has ended.
class _CompletedChallengeEntry extends ConsumerWidget {
  const _CompletedChallengeEntry({
    required this.challenge,
    required this.color,
  });

  final Challenge challenge;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topAsync = ref.watch(challengeLeaderboardTopProvider(challenge));
    final dateRange = formatChallengeDateRange(
      challenge.startDate,
      challenge.endDate,
      withYear: true,
    );

    return topAsync.when(
      loading: () => _CompletedChallengeCard(
        name: challenge.title,
        dateRange: dateRange,
        rank: null,
        totalParticipants: 0,
        totalSteps: challenge.myStepsInChallenge,
        color: color,
      ),
      error: (_, __) => _CompletedChallengeCard(
        name: challenge.title,
        dateRange: dateRange,
        rank: null,
        totalParticipants: 0,
        totalSteps: challenge.myStepsInChallenge,
        color: color,
      ),
      data: (entries) {
        final myIndex = entries.indexWhere((e) => e.isMe);
        final mySteps = myIndex >= 0
            ? entries[myIndex].steps
            : challenge.myStepsInChallenge;
        return _CompletedChallengeCard(
          name: challenge.title,
          dateRange: dateRange,
          rank: myIndex >= 0 ? myIndex + 1 : null,
          totalParticipants: entries.length,
          totalSteps: mySteps,
          color: color,
        );
      },
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
              child: const Icon(AppIcons.check, color: Colors.white, size: 12),
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

  /// Null while the final standing is still loading/unavailable — renders a
  /// placeholder badge rather than a fake "0th of 0".
  final int? rank;
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
          rank == null
              ? _RankBadgePlaceholder(color: color)
              : _RankBadge(
                  rank: rank!,
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
                style: AppTypography.titleS.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Total Steps',
                style: AppTypography.labelS.copyWith(fontSize: 9),
              ),
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
          const Icon(
            AppIcons.trophy,
            color: Colors.white,
            size: AppTheme.iconS,
          ),
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

class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  static const _durationLabels = ['7 Days', '14 Days', '30 Days', 'Custom'];
  static const _durationDays = [7, 14, 30];

  String _name = '';
  int? _goalSteps;
  int _durationIndex = 0;
  DateTime? _startDate;
  DateTime? _customEndDate;
  int? _winnerMethod;
  bool _submitting = false;

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
                          padding: const EdgeInsets.only(
                            right: AppTheme.spaceM,
                          ),
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
                    const _SectionLabel('Goal (Steps)'),
                    const SizedBox(height: 2),
                    Text(
                      'Total steps to reach by the end of the challenge.',
                      style: AppTypography.bodyS.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          setState(() => _goalSteps = int.tryParse(v)),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          AppIcons.steps,
                          color: AppColors.accent,
                          size: AppTheme.iconS,
                        ),
                        hintText: 'e.g., 70000',
                        hintStyle: AppTypography.bodyM.copyWith(
                          color: AppColors.textMuted,
                        ),
                        filled: true,
                        fillColor: AppColors.bgSurface,
                        border: _fieldBorder(),
                        enabledBorder: _fieldBorder(),
                        focusedBorder: _fieldBorder(focused: true),
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
                  onPressed: _submitting ? null : _createChallenge,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature coming soon')));
  }

  Future<void> _createChallenge() async {
    if (_name.trim().isEmpty) {
      _showValidationError(context, 'Give your challenge a name first');
      return;
    }
    if (_goalSteps == null || _goalSteps! <= 0) {
      _showValidationError(context, 'Enter a step goal for the challenge');
      return;
    }
    if (_startDate == null) {
      _showValidationError(context, 'Pick a start date');
      return;
    }
    if (_durationIndex == 3 && _customEndDate == null) {
      _showValidationError(context, 'Pick an end date');
      return;
    }
    if (_winnerMethod == null) {
      _showValidationError(context, 'Choose how the winner is determined');
      return;
    }

    final endDate = _durationIndex == 3
        ? _customEndDate!
        : _startDate!.add(Duration(days: _durationDays[_durationIndex]));

    HapticsHelper.lightImpact();
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(myChallengesProvider.notifier)
          .create(
            title: _name.trim(),
            goalSteps: _goalSteps!,
            startDate: _isoDate(_startDate!),
            endDate: _isoDate(endDate),
            isPublic: false,
            winnerType: _winnerMethod == 1
                ? WinnerType.goalCompletionPct
                : WinnerType.mostSteps,
          );
      if (!mounted) return;
      Navigator.pop(context);
      if (result.inviteCode != null) {
        _showInviteCodeDialog(context, result.inviteCode!);
      }
    } on BackendException catch (e) {
      if (!mounted) return;
      _showValidationError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      _showValidationError(
        context,
        'Could not create challenge. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showInviteCodeDialog(BuildContext context, String inviteCode) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Challenge Created!',
          style: AppTypography.titleM.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share this invite code so friends can join:',
              style: AppTypography.bodyS,
            ),
            const SizedBox(height: AppTheme.spaceM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceL,
                vertical: AppTheme.spaceM,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgDeep,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Text(
                inviteCode,
                textAlign: TextAlign.center,
                style: AppTypography.titleL.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Close',
              style: AppTypography.bodyL.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteCode));
              Navigator.pop(dialogCtx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Copy Code',
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

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _showValidationError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: AppTypography.labelM.copyWith(
                    color: selected ? AppColors.accent : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
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

/// Shared empty/error state for a tab's real-data list — icon + message,
/// matching the app's established empty-state visual pattern (see
/// achievements_screen.dart's `_EmptyBadgeRow`).
class _TabEmptyMessage extends StatelessWidget {
  const _TabEmptyMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXXL),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppTheme.iconXL, color: AppColors.textMuted),
            const SizedBox(height: AppTheme.spaceS),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyS.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Same footprint as [_RankBadge] for while a challenge's leaderboard is
/// still loading, failed to load, or the caller isn't in it (e.g. just
/// joined and hasn't synced any steps yet) — an unknown rank isn't the same
/// as rank 0, so this deliberately doesn't guess a number.
class _RankBadgePlaceholder extends StatelessWidget {
  const _RankBadgePlaceholder({required this.color});

  final Color color;

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
          const Icon(
            AppIcons.trophy,
            color: Colors.white,
            size: AppTheme.iconS,
          ),
          const SizedBox(height: 2),
          Text(
            '—',
            style: AppTypography.titleS.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
