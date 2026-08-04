import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/services/firebase_client.dart';
import 'package:strola_health/domain/entities/challenge.dart';
import 'package:strola_health/presentation/providers/challenge_providers.dart';
import 'package:strola_health/presentation/screens/challenge_of_the_month_screen.dart'
    show
        ChallengePodiumRow,
        ChallengeLeaderboardRow,
        kChallengeAccentPalette,
        formatChallengeDateRange,
        daysLeftLabel;
import 'package:strola_health/presentation/widgets/flat_card.dart';

/// Detail view for a single private challenge — same hero/leaderboard layout
/// as [ChallengeOfTheMonthScreen], but with one leaderboard instead of a
/// switchable pair: a private challenge is created with exactly one winner
/// method (`Challenge.winnerType`), so there's nothing to toggle between
/// here. Leaderboard is always the live `challengeLeaderboardProvider` per
/// the migration plan, regardless of whether this was reached from the
/// Private or Completed tab.
class PrivateChallengeDetailScreen extends ConsumerWidget {
  const PrivateChallengeDetailScreen({
    super.key,
    required this.challenge,
    this.accentColor,
  });

  final Challenge challenge;

  /// Decorative color carried over from the list card that navigated here
  /// (so the card and its detail screen match) — falls back to a
  /// deterministic pick from the shared palette when opened another way.
  final Color? accentColor;

  bool get _byPercent => challenge.winnerType == WinnerType.goalCompletionPct;

  List<(int rank, ChallengeLeaderboardEntry p)> _ranked(
    List<ChallengeLeaderboardEntry> entries,
  ) {
    final sorted = [...entries]
      ..sort(
        (a, b) => _byPercent
            ? b.goalCompletionPct.compareTo(a.goalCompletionPct)
            : b.steps.compareTo(a.steps),
      );
    return [for (var i = 0; i < sorted.length; i++) (i + 1, sorted[i])];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color =
        accentColor ??
        kChallengeAccentPalette[challenge.id.hashCode.abs() %
            kChallengeAccentPalette.length];
    final leaderboardAsync = ref.watch(
      challengeLeaderboardProvider(challenge.id),
    );
    final canLeave =
        !challenge.isOfficial && challenge.status != ChallengeStatus.archived;

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
          title: Text(challenge.title, style: AppTypography.titleM),
          centerTitle: true,
          actions: [
            GestureDetector(
              onTap: () => _showComingSoon(context, 'Inviting friends'),
              child: const Icon(
                AppIcons.addFriend,
                color: AppColors.accent,
                size: AppTheme.iconM,
              ),
            ),
            if (canLeave) ...[
              const SizedBox(width: AppTheme.spaceL),
              GestureDetector(
                onTap: () => _showChallengeMenu(context, ref),
                child: const Icon(
                  AppIcons.more,
                  color: AppColors.accent,
                  size: AppTheme.iconM,
                ),
              ),
            ],
            const SizedBox(width: AppTheme.spaceL),
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
              challenge: challenge,
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

            leaderboardAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.spaceXXL),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
              error: (_, __) => const _CenteredMessage(
                icon: AppIcons.error,
                message: 'Could not load the leaderboard.',
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return const _CenteredMessage(
                    icon: AppIcons.groups,
                    message: "No one's joined yet. Invite some friends!",
                  );
                }
                final ranked = _ranked(entries);
                final top3 = ranked.take(3).toList();
                final rest = ranked.skip(3).toList();
                return Column(
                  children: [
                    ChallengePodiumRow(top3: top3, showPercent: _byPercent)
                        .animate()
                        .fadeIn(delay: 150.ms, duration: AppTheme.animSlow),
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
                  ],
                );
              },
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

  void _showChallengeMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
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
                leading: const Icon(AppIcons.logout, color: AppColors.error),
                title: Text(
                  'Leave Challenge',
                  style: AppTypography.bodyL.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _confirmLeave(context, ref);
                },
              ),
              const SizedBox(height: AppTheme.spaceM),
            ],
          ),
        );
      },
    );
  }

  void _confirmLeave(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Leave "${challenge.title}"?',
          style: AppTypography.titleM.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          "You'll be removed from the leaderboard and will need a new "
          'invite to rejoin.',
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
              final dialogNavigator = Navigator.of(dialogCtx);
              try {
                await ref
                    .read(myChallengesProvider.notifier)
                    .leave(challenge.id);
              } on BackendException catch (e) {
                dialogNavigator.pop();
                messenger.showSnackBar(SnackBar(content: Text(e.message)));
                return;
              } catch (_) {
                dialogNavigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Could not leave. Please try again.'),
                  ),
                );
                return;
              }
              dialogNavigator.pop(); // close dialog
              navigator.pop(); // close detail screen
              messenger.showSnackBar(
                SnackBar(
                  content: Text('You left "${challenge.title}".'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.accent,
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
              'Leave',
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

// ─────────────────────────────────────────────────────────────────────────────
// HERO CARD
// ─────────────────────────────────────────────────────────────────────────────

class _PrivateHeroCard extends StatelessWidget {
  const _PrivateHeroCard({required this.challenge, required this.color});

  final Challenge challenge;
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
                      challenge.title,
                      style: AppTypography.titleL.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (challenge.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        challenge.description,
                        style: AppTypography.bodyS.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
                child: Icon(
                  AppIcons.trophy,
                  color: color,
                  size: AppTheme.iconM,
                ),
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
                  Text(
                    formatChallengeDateRange(
                      challenge.startDate,
                      challenge.endDate,
                      withYear: true,
                    ),
                    style: AppTypography.labelM,
                  ),
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
                  challenge.status == ChallengeStatus.archived
                      ? 'Completed'
                      : daysLeftLabel(challenge),
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
                      : 'Whoever has the highest total steps when the '
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
// SMALL SHARED WIDGET — loading-error / empty leaderboard message.
// ─────────────────────────────────────────────────────────────────────────────

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.message});

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
              style: AppTypography.bodyS.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
