import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/formatters.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';

class ChallengeOfTheMonthScreen extends StatefulWidget {
  const ChallengeOfTheMonthScreen({super.key});

  @override
  State<ChallengeOfTheMonthScreen> createState() =>
      _ChallengeOfTheMonthScreenState();
}

class _ChallengeOfTheMonthScreenState extends State<ChallengeOfTheMonthScreen> {
  int _tab = 0;

  List<(int rank, ChallengeParticipant p)> get _ranked {
    final sorted = [..._participants]
      ..sort(
        (a, b) => _tab == 0
            ? b.steps.compareTo(a.steps)
            : b.goalCompletionPct.compareTo(a.goalCompletionPct),
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
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPaddingH,
            AppTheme.spaceL,
            AppTheme.screenPaddingH,
            AppTheme.spaceXXL,
          ),
          children: [
            const _HeroCard()
                .animate()
                .fadeIn(duration: AppTheme.animSlow)
                .slideY(begin: 0.08),
            const SizedBox(height: AppTheme.sectionGap),
            const _HowItWorksCard()
                .animate()
                .fadeIn(delay: 100.ms, duration: AppTheme.animSlow)
                .slideY(begin: 0.08),
            const SizedBox(height: AppTheme.sectionGap + 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Leaderboard', style: AppTypography.titleL),
                GestureDetector(
                  onTap: () => _showComingSoon(context, 'Full leaderboard'),
                  child: Text(
                    'View all',
                    style: AppTypography.bodyM.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceM),
            _LeaderboardTabSwitch(
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: AppTheme.spaceXL),

            ChallengePodiumRow(
              top3: top3,
              showPercent: _tab == 1,
            ).animate().fadeIn(delay: 150.ms, duration: AppTheme.animSlow),
            const SizedBox(height: AppTheme.spaceXL),

            for (final entry in rest)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
                child:
                    ChallengeLeaderboardRow(
                          rank: entry.$1,
                          participant: entry.$2,
                          showPercent: _tab == 1,
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

class _HeroCard extends StatelessWidget {
  const _HeroCard();

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
      child: Stack(
        children: [
          const Positioned(top: 0, right: 0, child: _ImagePlaceholder()),
          Padding(
            padding: const EdgeInsets.only(right: 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'May Walking Challenge',
                        style: AppTypography.titleL.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceXS),
                    const Icon(
                      AppIcons.run,
                      color: AppColors.accent,
                      size: AppTheme.iconM,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceS),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Step into a healthier, happier you this May!',
                        style: AppTypography.bodyS.copyWith(
                          color: AppColors.textSecondary,
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
                        Text('May 1 - May 31', style: AppTypography.labelM),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceS,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        '19 days left',
                        style: AppTypography.labelS.copyWith(
                          color: AppColors.accent,
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
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 112,
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
          size: AppTheme.iconL,
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
                      "Track your steps all month long. At the end of "
                      "May, we'll crown 2 winners!",
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
  final List<(int rank, ChallengeParticipant p)> top3;
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
  final ChallengeParticipant participant;
  final double size;
  final bool showPercent;

  Color get _medalColor => switch (rank) {
    1 => AppColors.goalAmber,
    2 => AppColors.textMuted,
    _ => AppColors.accent,
  };

  @override
  Widget build(BuildContext context) {
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
                color: participant.color.withValues(alpha: 0.18),
                border: Border.all(
                  color: rank == 1
                      ? AppColors.goalAmber
                      : participant.color.withValues(alpha: 0.4),
                  width: rank == 1 ? 2.5 : 1.5,
                ),
                boxShadow: rank == 1 ? AppTheme.glowShadow : null,
              ),
              child: Center(
                child: Text(
                  participant.initials,
                  style: AppTypography.titleM.copyWith(
                    color: participant.color,
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
  final ChallengeParticipant participant;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    final highlight = participant.isMe;
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
              color: participant.color.withValues(alpha: 0.18),
              border: Border.all(
                color: participant.color.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                participant.initials,
                style: AppTypography.bodyS.copyWith(
                  color: participant.color,
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

// ─────────────────────────────────────────────────────────────────────────────
// PARTICIPANT DATA
// ─────────────────────────────────────────────────────────────────────────────

class ChallengeParticipant {
  const ChallengeParticipant({
    required this.name,
    required this.steps,
    required this.goalCompletionPct,
    this.colorValue,
    this.isMe = false,
  });

  final String name;
  final int steps;
  final int goalCompletionPct;
  final int? colorValue;
  final bool isMe;

  Color get color => isMe ? AppColors.accent : Color(colorValue!);

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

const _participants = [
  ChallengeParticipant(
    name: 'Jessica M.',
    steps: 412389,
    goalCompletionPct: 142,
    colorValue: 0xFF7C3AED,
  ),
  ChallengeParticipant(
    name: 'Sarah T.',
    steps: 378221,
    goalCompletionPct: 127,
    colorValue: 0xFFDB2777,
  ),
  ChallengeParticipant(
    name: 'Amanda K.',
    steps: 334125,
    goalCompletionPct: 148,
    colorValue: 0xFFD97706,
  ),
  ChallengeParticipant(
    name: 'Emily R.',
    steps: 298743,
    goalCompletionPct: 119,
    colorValue: 0xFF0891B2,
  ),
  ChallengeParticipant(
    name: 'You',
    steps: 265410,
    goalCompletionPct: 131,
    isMe: true,
  ),
  ChallengeParticipant(
    name: 'Megan L.',
    steps: 243876,
    goalCompletionPct: 139,
    colorValue: 0xFF059669,
  ),
];
