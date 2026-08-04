import 'package:flutter/material.dart';
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
import 'package:strola_health/presentation/widgets/flat_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHARED LEADERBOARD DECORATION — real users don't have a stored "favorite
// color" in the backend, so podium/leaderboard rows and challenge cards cycle
// through a small fixed palette by list index. `isMe` always wins and renders
// as AppColors.accent regardless of position. Reused by
// private_challenge_detail_screen.dart and challenges_screen.dart.
// ─────────────────────────────────────────────────────────────────────────────

const List<Color> kChallengeAccentPalette = [
  AppColors.accent,
  Color(0xFF0891B2),
  AppColors.goalAmber,
  Color(0xFFD97706),
  AppColors.success,
  Color(0xFF7C3AED),
];

Color challengeColorFor(int index, {required bool isMe}) => isMe
    ? AppColors.accent
    : kChallengeAccentPalette[index % kChallengeAccentPalette.length];

/// Formats a challenge's date range, e.g. "May 1 – May 31" (or with a year
/// suffix for challenges that may span/reference a different year, e.g.
/// "May 11 – May 17, 2024").
String formatChallengeDateRange(
  DateTime start,
  DateTime end, {
  bool withYear = false,
}) {
  final startLabel = Formatters.fullDate(start);
  final endLabel = Formatters.fullDate(end);
  return withYear
      ? '$startLabel – $endLabel, ${end.year}'
      : '$startLabel – $endLabel';
}

/// "3 days left" / "Ends today" — shared across the challenge screens.
String daysLeftLabel(Challenge challenge) {
  final days = challenge.daysLeft;
  if (days <= 0) return 'Ends today';
  if (days == 1) return '1 day left';
  return '$days days left';
}

class ChallengeOfTheMonthScreen extends ConsumerStatefulWidget {
  const ChallengeOfTheMonthScreen({super.key});

  @override
  ConsumerState<ChallengeOfTheMonthScreen> createState() =>
      _ChallengeOfTheMonthScreenState();
}

class _ChallengeOfTheMonthScreenState
    extends ConsumerState<ChallengeOfTheMonthScreen> {
  int _tab = 0;

  List<(int rank, ChallengeLeaderboardEntry p)> _rank(
    List<ChallengeLeaderboardEntry> entries,
  ) {
    final sorted = [...entries]
      ..sort(
        (a, b) => _tab == 0
            ? b.steps.compareTo(a.steps)
            : b.goalCompletionPct.compareTo(a.goalCompletionPct),
      );
    return [for (var i = 0; i < sorted.length; i++) (i + 1, sorted[i])];
  }

  @override
  Widget build(BuildContext context) {
    final challengeAsync = ref.watch(officialChallengeProvider);

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
          title: Text('Challenge of the Month', style: AppTypography.titleM),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spaceL),
              child: GestureDetector(
                onTap: () => _showComingSoon(context, 'Sharing'),
                child: const Icon(
                  AppIcons.share,
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
        body: challengeAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
          error: (_, __) => _MessageState(
            icon: AppIcons.error,
            message: 'Could not load this challenge. Please try again.',
          ),
          data: (challenge) {
            if (challenge == null) {
              return const _MessageState(
                icon: AppIcons.trophy,
                message:
                    "There's no official challenge running right now. "
                    'Check back soon!',
              );
            }
            return _ChallengeOfTheMonthBody(
              challenge: challenge,
              tab: _tab,
              onTabChanged: (i) => setState(() => _tab = i),
              rank: _rank,
            );
          },
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

/// Centered icon + message — used for the loading-error and no-challenge
/// states, matching the tone of other empty states in this codebase (e.g.
/// achievements_screen.dart's `_EmptyBadgeRow`).
class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}

class _ChallengeOfTheMonthBody extends ConsumerStatefulWidget {
  const _ChallengeOfTheMonthBody({
    required this.challenge,
    required this.tab,
    required this.onTabChanged,
    required this.rank,
  });

  final Challenge challenge;
  final int tab;
  final ValueChanged<int> onTabChanged;
  final List<(int rank, ChallengeLeaderboardEntry p)> Function(
    List<ChallengeLeaderboardEntry>,
  )
  rank;

  @override
  ConsumerState<_ChallengeOfTheMonthBody> createState() =>
      _ChallengeOfTheMonthBodyState();
}

class _ChallengeOfTheMonthBodyState
    extends ConsumerState<_ChallengeOfTheMonthBody> {
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
    final leaderboardAsync = ref.watch(
      challengeLeaderboardProvider(challenge.id),
    );

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.screenPaddingH,
        AppTheme.spaceL,
        AppTheme.screenPaddingH,
        AppTheme.spaceXXL,
      ),
      children: [
        _HeroCard(
          challenge: challenge,
          joining: _joining,
          onJoin: _join,
        ).animate().fadeIn(duration: AppTheme.animSlow).slideY(begin: 0.08),
        const SizedBox(height: AppTheme.sectionGap),
        const _HowItWorksCard()
            .animate()
            .fadeIn(delay: 100.ms, duration: AppTheme.animSlow)
            .slideY(begin: 0.08),
        const SizedBox(height: AppTheme.sectionGap + 8),

        Text('Leaderboard', style: AppTypography.titleL),
        const SizedBox(height: AppTheme.spaceM),
        _LeaderboardTabSwitch(
          selected: widget.tab,
          onChanged: widget.onTabChanged,
        ),
        const SizedBox(height: AppTheme.spaceXL),

        leaderboardAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.spaceXXL),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ),
          error: (_, __) => const _MessageState(
            icon: AppIcons.error,
            message: 'Could not load the leaderboard.',
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return const _MessageState(
                icon: AppIcons.groups,
                message: "No one's joined yet. Be the first!",
              );
            }
            final ranked = widget.rank(entries);
            final top3 = ranked.take(3).toList();
            final rest = ranked.skip(3).toList();
            return Column(
              children: [
                ChallengePodiumRow(
                  top3: top3,
                  showPercent: widget.tab == 1,
                ).animate().fadeIn(delay: 150.ms, duration: AppTheme.animSlow),
                const SizedBox(height: AppTheme.spaceXL),
                for (final entry in rest)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
                    child:
                        ChallengeLeaderboardRow(
                              rank: entry.$1,
                              participant: entry.$2,
                              showPercent: widget.tab == 1,
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
              const Icon(
                AppIcons.steps,
                color: AppColors.accent,
                size: AppTheme.iconS,
              ),
              const SizedBox(width: AppTheme.spaceXS),
              Text(
                'Keep it up! Every step brings you closer to the top.',
                style: AppTypography.bodyS.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO CARD
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.challenge,
    required this.joining,
    required this.onJoin,
  });

  final Challenge challenge;
  final bool joining;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final imageUrl = challenge.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.accentSecondary.withValues(alpha: 0.18),
          border: Border.all(
            color: AppColors.accentSecondary.withValues(alpha: 0.30),
          ),
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            // Landscape challenge photo, full-bleed behind everything —
            // falls back to the plain tinted background above when no
            // image has been uploaded (admin-only, see updateChallenge.ts).
            if (hasImage)
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            // Dark scrim so title/description/button stay legible over any
            // photo, regardless of how bright or busy it is.
            if (hasImage)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black45, Colors.black38, Colors.black87],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          challenge.title,
                          style: AppTypography.titleL.copyWith(
                            fontWeight: FontWeight.w800,
                            color: hasImage
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceXS),
                      Icon(
                        AppIcons.run,
                        color: hasImage ? Colors.white : AppColors.accent,
                        size: AppTheme.iconM,
                      ),
                    ],
                  ),
                  if (challenge.description.trim().isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spaceS),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            challenge.description,
                            style: AppTypography.bodyS.copyWith(
                              color: hasImage
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceXS),
                        const Icon(
                          AppIcons.sun,
                          color: AppColors.goalAmber,
                          size: AppTheme.iconS,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppTheme.spaceM),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppTheme.spaceS,
                    runSpacing: AppTheme.spaceXS,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.calendar,
                            color: hasImage
                                ? Colors.white70
                                : AppColors.textMuted,
                            size: AppTheme.iconXS,
                          ),
                          const SizedBox(width: AppTheme.spaceXS),
                          Text(
                            formatChallengeDateRange(
                              challenge.startDate,
                              challenge.endDate,
                            ),
                            style: AppTypography.labelM.copyWith(
                              color: hasImage ? Colors.white70 : null,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceS,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: hasImage
                              ? Colors.white.withValues(alpha: 0.92)
                              : AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: Text(
                          daysLeftLabel(challenge),
                          style: AppTypography.labelS.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceL),
                  _JoinButton(
                    joined: challenge.isJoined,
                    joining: joining,
                    onTap: onJoin,
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

class _JoinButton extends StatelessWidget {
  const _JoinButton({
    required this.joined,
    required this.joining,
    required this.onTap,
  });

  final bool joined;
  final bool joining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: joined || joining ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: joined ? AppColors.success : AppColors.accent,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (joining)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else ...[
              Icon(
                joined ? AppIcons.goalReached : AppIcons.add,
                color: Colors.white,
                size: AppTheme.iconS,
              ),
              const SizedBox(width: AppTheme.spaceXS),
              Text(
                joined ? "You're In!" : 'Join Challenge',
                style: AppTypography.bodyL.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOW IT WORKS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _IconCircle(icon: AppIcons.trophy),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How it works', style: AppTypography.titleS),
                    const SizedBox(height: 2),
                    Text(
                      'Track your steps for the whole challenge. When it '
                      "ends, we'll crown 2 winners!",
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
          const SizedBox(height: AppTheme.spaceL),
          Container(
            height: 1,
            color: AppColors.accentSecondary.withValues(alpha: 0.15),
          ),
          const SizedBox(height: AppTheme.spaceL),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(
                child: _HowItWorksStat(
                  icon: AppIcons.steps,
                  title: 'Most Steps',
                  description: 'Winner with the highest total steps',
                ),
              ),
              SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: _HowItWorksStat(
                  icon: AppIcons.target,
                  title: 'Highest Goal Completion %',
                  description:
                      'Winner with the highest average goal completion',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.accentSecondary.withValues(alpha: 0.20),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.accent, size: AppTheme.iconS),
    );
  }
}

class _HowItWorksStat extends StatelessWidget {
  const _HowItWorksStat({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconCircle(icon: icon),
        const SizedBox(height: AppTheme.spaceS),
        Text(title, style: AppTypography.titleS.copyWith(fontSize: 13)),
        const SizedBox(height: 2),
        Text(description, style: AppTypography.labelS.copyWith(height: 1.3)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEADERBOARD TAB SWITCH
// ─────────────────────────────────────────────────────────────────────────────

class _LeaderboardTabSwitch extends StatelessWidget {
  const _LeaderboardTabSwitch({
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _segment(context, 0, 'Most Steps')),
        const SizedBox(width: AppTheme.spaceS),
        Expanded(child: _segment(context, 1, 'Highest Goal Completion %')),
      ],
    );
  }

  Widget _segment(BuildContext context, int index, String label) {
    final active = selected == index;
    return GestureDetector(
      onTap: () => onChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? AppColors.accentSecondary.withValues(alpha: 0.22)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: active
                ? AppColors.accent.withValues(alpha: 0.4)
                : AppColors.accentSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyS.copyWith(
            color: active ? AppColors.accent : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PODIUM (top 3)
// ─────────────────────────────────────────────────────────────────────────────

class ChallengePodiumRow extends StatelessWidget {
  const ChallengePodiumRow({
    super.key,
    required this.top3,
    required this.showPercent,
  });
  final List<(int rank, ChallengeLeaderboardEntry p)> top3;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    final byRank = {for (final t in top3) t.$1: t.$2};
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (byRank[2] != null)
          _PodiumAvatar(
            rank: 2,
            participant: byRank[2]!,
            size: 64,
            showPercent: showPercent,
          ),
        if (byRank[1] != null)
          _PodiumAvatar(
            rank: 1,
            participant: byRank[1]!,
            size: 80,
            showPercent: showPercent,
          ),
        if (byRank[3] != null)
          _PodiumAvatar(
            rank: 3,
            participant: byRank[3]!,
            size: 64,
            showPercent: showPercent,
          ),
      ],
    );
  }
}

class _PodiumAvatar extends StatelessWidget {
  const _PodiumAvatar({
    required this.rank,
    required this.participant,
    required this.size,
    required this.showPercent,
  });

  final int rank;
  final ChallengeLeaderboardEntry participant;
  final double size;
  final bool showPercent;

  Color get _medalColor => switch (rank) {
    1 => AppColors.goalAmber,
    2 => AppColors.textMuted,
    _ => AppColors.accent,
  };

  @override
  Widget build(BuildContext context) {
    final color = challengeColorFor(rank - 1, isMe: participant.isMe);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.18),
                border: Border.all(
                  color: rank == 1
                      ? AppColors.goalAmber
                      : color.withValues(alpha: 0.4),
                  width: rank == 1 ? 2.5 : 1.5,
                ),
                boxShadow: rank == 1 ? AppTheme.glowShadow : null,
              ),
              child: Center(
                child: Text(
                  participant.initials,
                  style: AppTypography.titleM.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: rank == 1 ? 22 : 18,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _medalColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: AppTypography.labelS.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceS),
        Text(
          participant.name,
          style: AppTypography.bodyS.copyWith(
            fontWeight: FontWeight.w700,
            color: participant.isMe ? AppColors.accent : AppColors.textPrimary,
          ),
        ),
        Text(
          showPercent
              ? '${participant.goalCompletionPct}%'
              : '${Formatters.stepCount(participant.steps)} steps',
          style: AppTypography.labelS,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEADERBOARD ROW (rank 4+)
// ─────────────────────────────────────────────────────────────────────────────

class ChallengeLeaderboardRow extends StatelessWidget {
  const ChallengeLeaderboardRow({
    super.key,
    required this.rank,
    required this.participant,
    required this.showPercent,
  });

  final int rank;
  final ChallengeLeaderboardEntry participant;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    final highlight = participant.isMe;
    final color = challengeColorFor(rank - 1, isMe: participant.isMe);
    return FlatCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceL,
        vertical: AppTheme.spaceM,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              '$rank',
              style: AppTypography.bodyM.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceS),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
              border: Border.all(
                color: color.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                participant.initials,
                style: AppTypography.bodyS.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceM),
          Expanded(
            child: Text(
              participant.name,
              style: AppTypography.bodyL.copyWith(
                color: highlight ? AppColors.accent : AppColors.textPrimary,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            showPercent
                ? '${participant.goalCompletionPct}%'
                : '${Formatters.stepCount(participant.steps)} steps',
            style: AppTypography.bodyS.copyWith(
              color: highlight ? AppColors.accent : AppColors.textSecondary,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          const SizedBox(width: AppTheme.spaceS),
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
