import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/presentation/screens/challenge_of_the_month_screen.dart'
    show ChallengeParticipant, ChallengePodiumRow, ChallengeLeaderboardRow;
import 'package:strola_health/presentation/widgets/flat_card.dart';

/// Detail view for a single private challenge — same hero/leaderboard layout
/// as [ChallengeOfTheMonthScreen], but with one leaderboard instead of a
/// switchable pair: a private challenge is created with exactly one winner
/// method (`winnerMethod`: 0 = Most Steps, 1 = Highest Goal Completion %),
/// so there's nothing to toggle between here.
class PrivateChallengeDetailScreen extends StatelessWidget {
  const PrivateChallengeDetailScreen({
    super.key,
    required this.name,
    required this.subtitle,
    required this.dateRange,
    required this.daysLeft,
    required this.winnerMethod,
    required this.icon,
    required this.color,
  });

  final String name;
  final String subtitle;
  final String dateRange;
  final String daysLeft;

  /// 0 = Most Steps, 1 = Highest Goal Completion %.
  final int winnerMethod;
  final IconData icon;
  final Color color;

  bool get _byPercent => winnerMethod == 1;

  List<(int rank, ChallengeParticipant p)> get _ranked {
    final sorted = [..._participants]
      ..sort(
        (a, b) => _byPercent
            ? b.goalCompletionPct.compareTo(a.goalCompletionPct)
            : b.steps.compareTo(a.steps),
      );
    return [for (var i = 0; i < sorted.length; i++) (i + 1, sorted[i])];
  }

  @override
  Widget build(BuildContext context) {
    final ranked = _ranked;
    final top3 = ranked.take(3).toList();
    final rest = ranked.skip(3).toList();

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.bgSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              AppIcons.back,
              color: AppColors.accent,
              size: AppTheme.iconM,
            ),
          ),
          title: Text(name, style: AppTypography.titleM),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spaceL),
              child: GestureDetector(
                onTap: () => _showComingSoon(context, 'Inviting friends'),
                child: const Icon(
                  AppIcons.addFriend,
                  color: AppColors.accent,
                  size: AppTheme.iconM,
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: AppColors.accentSecondary.withValues(alpha: 0.15),
            ),
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPaddingH,
            AppTheme.spaceL,
            AppTheme.screenPaddingH,
            AppTheme.spaceXXL,
          ),
          children: [
            _PrivateHeroCard(
              name: name,
              subtitle: subtitle,
              dateRange: dateRange,
              daysLeft: daysLeft,
              icon: icon,
              color: color,
            ).animate().fadeIn(duration: AppTheme.animSlow).slideY(begin: 0.08),
            const SizedBox(height: AppTheme.sectionGap),
            _PrivateHowItWorksCard(byPercent: _byPercent)
                .animate()
                .fadeIn(delay: 100.ms, duration: AppTheme.animSlow)
                .slideY(begin: 0.08),
            const SizedBox(height: AppTheme.sectionGap + 8),

            Text('Leaderboard', style: AppTypography.titleL),
            const SizedBox(height: AppTheme.spaceXL),

            ChallengePodiumRow(
              top3: top3,
              showPercent: _byPercent,
            ).animate().fadeIn(delay: 150.ms, duration: AppTheme.animSlow),
            const SizedBox(height: AppTheme.spaceXL),

            for (final entry in rest)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
                child:
                    ChallengeLeaderboardRow(
                          rank: entry.$1,
                          participant: entry.$2,
                          showPercent: _byPercent,
                        )
                        .animate()
                        .fadeIn(
                          delay: (200 + entry.$1 * 40).ms,
                          duration: AppTheme.animSlow,
                        )
                        .slideX(begin: 0.04),
              ),

            const SizedBox(height: AppTheme.spaceL),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.lock,
                    color: AppColors.textMuted,
                    size: AppTheme.iconS,
                  ),
                  const SizedBox(width: AppTheme.spaceXS),
                  Text(
                    'Only people you invited can see this leaderboard.',
                    style: AppTypography.bodyS.copyWith(
                      color: AppColors.textSecondary,
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

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature coming soon')));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO CARD
// ─────────────────────────────────────────────────────────────────────────────

class _PrivateHeroCard extends StatelessWidget {
  const _PrivateHeroCard({
    required this.name,
    required this.subtitle,
    required this.dateRange,
    required this.daysLeft,
    required this.icon,
    required this.color,
  });

  final String name;
  final String subtitle;
  final String dateRange;
  final String daysLeft;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: BoxDecoration(
        color: AppColors.accentSecondary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: AppColors.accentSecondary.withValues(alpha: 0.30),
        ),
      ),
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
                      style: AppTypography.titleL.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodyS.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: AppTheme.iconM),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTheme.spaceS,
            runSpacing: AppTheme.spaceXS,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    AppIcons.calendar,
                    color: AppColors.textMuted,
                    size: AppTheme.iconXS,
                  ),
                  const SizedBox(width: AppTheme.spaceXS),
                  Text(dateRange, style: AppTypography.labelM),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceS,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  daysLeft,
                  style: AppTypography.labelS.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceL),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  AppIcons.goalReached,
                  color: Colors.white,
                  size: AppTheme.iconS,
                ),
                const SizedBox(width: AppTheme.spaceXS),
                Text(
                  "You're In!",
                  style: AppTypography.bodyL.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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

// ─────────────────────────────────────────────────────────────────────────────
// HOW IT WORKS CARD (single method — private challenges only have one)
// ─────────────────────────────────────────────────────────────────────────────

class _PrivateHowItWorksCard extends StatelessWidget {
  const _PrivateHowItWorksCard({required this.byPercent});

  final bool byPercent;

  @override
  Widget build(BuildContext context) {
    return FlatCard(
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
            child: Icon(
              byPercent ? AppIcons.target : AppIcons.steps,
              color: AppColors.accent,
              size: AppTheme.iconS,
            ),
          ),
          const SizedBox(width: AppTheme.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  byPercent ? 'Highest Goal Completion %' : 'Most Steps',
                  style: AppTypography.titleS,
                ),
                const SizedBox(height: 2),
                Text(
                  byPercent
                      ? 'Whoever has the highest average daily goal '
                            'completion when the challenge ends wins.'
                      : 'Whoever logs the highest total steps when the '
                            'challenge ends wins.',
                  style: AppTypography.bodyS.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
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

// ─────────────────────────────────────────────────────────────────────────────
// MOCK PARTICIPANTS — a private challenge's pool is just its invited members
// ─────────────────────────────────────────────────────────────────────────────

const _participants = [
  ChallengeParticipant(
    name: 'Priya N.',
    steps: 84213,
    goalCompletionPct: 121,
    colorValue: 0xFF7C3AED,
  ),
  ChallengeParticipant(
    name: 'You',
    steps: 76590,
    goalCompletionPct: 109,
    isMe: true,
  ),
  ChallengeParticipant(
    name: 'Hannah B.',
    steps: 68940,
    goalCompletionPct: 98,
    colorValue: 0xFFDB2777,
  ),
  ChallengeParticipant(
    name: 'Liz M.',
    steps: 52110,
    goalCompletionPct: 87,
    colorValue: 0xFF0891B2,
  ),
];
