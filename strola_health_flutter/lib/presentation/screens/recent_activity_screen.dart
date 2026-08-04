import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/formatters.dart';
import 'package:strola_health/presentation/providers/session_providers.dart';
import 'package:strola_health/presentation/providers/step_providers.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';

/// Full history behind the Profile screen's "Recent Activity" preview — the
/// same shared, real list (`recentActivityProvider`), so this page and the
/// preview's first 4 entries always agree.
class RecentActivityScreen extends ConsumerWidget {
  const RecentActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(recentActivityProvider);
    final goal = ref.watch(dailyGoalProvider);

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
              color: AppColors.textPrimary,
              size: AppTheme.iconM,
            ),
          ),
          title: Text('Recent Activity', style: AppTypography.titleM),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: AppColors.accentSecondary.withValues(alpha: 0.15),
            ),
          ),
        ),
        body: SafeArea(
          child: entries.isEmpty
              ? _EmptyState()
              : _ActivityList(entries: entries, goal: goal),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.steps,
                color: AppColors.accent,
                size: 32,
              ),
            ),
            const SizedBox(height: AppTheme.spaceL),
            Text('No activity yet', style: AppTypography.titleS),
            const SizedBox(height: AppTheme.spaceXS),
            Text(
              'Start walking to see your activity history here.',
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

// ─────────────────────────────────────────────────────────────────────────────
// LIST  (summary card + grouped, goal-aware rows)
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.entries, required this.goal});

  final List<MapEntry<DateTime, int>> entries;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);
    final avg = total ~/ entries.length;
    final best = entries.reduce((a, b) => a.value > b.value ? a : b);
    final daysMetGoal = entries.where((e) => e.value >= goal).length;

    final now = DateTime.now();
    final weekCutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final thisWeek = entries.where((e) => !e.key.isBefore(weekCutoff)).toList();
    final earlier = entries.where((e) => e.key.isBefore(weekCutoff)).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.screenPaddingH,
        AppTheme.spaceL,
        AppTheme.screenPaddingH,
        AppTheme.spaceXXL,
      ),
      children: [
        _SummaryCard(
          total: total,
          best: best.value,
          avg: avg,
          daysMetGoal: daysMetGoal,
          totalDays: entries.length,
        ).animate().fadeIn(duration: AppTheme.animSlow).slideY(begin: 0.08),

        if (thisWeek.isNotEmpty) ...[
          const SizedBox(height: AppTheme.sectionGap + 6),
          _SectionLabel('This Week'),
          const SizedBox(height: AppTheme.spaceS),
          for (var i = 0; i < thisWeek.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
              child: _ActivityRow(
                entry: thisWeek[i],
                goal: goal,
                isBest: thisWeek[i].key == best.key,
                delayIndex: i,
              ),
            ),
        ],

        if (earlier.isNotEmpty) ...[
          const SizedBox(height: AppTheme.sectionGap),
          _SectionLabel('Earlier'),
          const SizedBox(height: AppTheme.spaceS),
          for (var i = 0; i < earlier.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
              child: _ActivityRow(
                entry: earlier[i],
                goal: goal,
                isBest: earlier[i].key == best.key,
                delayIndex: thisWeek.length + i,
              ),
            ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.labelS.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.textMuted,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY CARD
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.best,
    required this.avg,
    required this.daysMetGoal,
    required this.totalDays,
  });

  final int total;
  final int best;
  final int avg;
  final int daysMetGoal;
  final int totalDays;

  @override
  Widget build(BuildContext context) {
    return FlatCard(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.showChart,
                  color: AppColors.accent,
                  size: AppTheme.iconM,
                ),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: total.toDouble()),
                      duration: AppTheme.animCrawl,
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Text(
                        '${Formatters.stepCount(v.toInt())} steps',
                        style: AppTypography.titleL.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    Text(
                      'across the last $totalDays days',
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
          const SizedBox(height: AppTheme.spaceL),
          Container(
            height: 1,
            color: AppColors.accentSecondary.withValues(alpha: 0.15),
          ),
          const SizedBox(height: AppTheme.spaceL),
          Row(
            children: [
              _MiniStat(
                icon: AppIcons.trophy,
                value: Formatters.stepCount(best),
                label: 'Best Day',
              ),
              _MiniStat(
                icon: AppIcons.calendarMonth,
                value: Formatters.stepCount(avg),
                label: 'Daily Avg',
              ),
              _MiniStat(
                icon: AppIcons.goalReached,
                value: '$daysMetGoal/$totalDays',
                label: 'Goal Met',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: AppTheme.iconS),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            value,
            style: AppTypography.bodyM.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          Text(
            label,
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

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITY ROW
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.entry,
    required this.goal,
    required this.isBest,
    required this.delayIndex,
  });

  final MapEntry<DateTime, int> entry;
  final int goal;
  final bool isBest;
  final int delayIndex;

  @override
  Widget build(BuildContext context) {
    final steps = entry.value;
    final goalMet = steps >= goal;
    final color = goalMet ? AppColors.accent : AppColors.accentSecondary;
    final pct = (steps / goal * 100).round();

    return FlatCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceL,
            vertical: AppTheme.spaceM,
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      goalMet ? AppIcons.trophy : AppIcons.steps,
                      color: color,
                      size: AppTheme.iconS,
                    ),
                  ),
                  if (isBest)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.goalAmber,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          AppIcons.star,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hit ${Formatters.stepCount(steps)} steps',
                      style: AppTypography.bodyL.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      goalMet ? "$pct% of goal, nailed it" : '$pct% of goal',
                      style: AppTypography.labelS.copyWith(
                        color: goalMet ? AppColors.accent : AppColors.textMuted,
                        fontWeight: goalMet ? FontWeight.w600 : FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _relativeDate(entry.key),
                style: AppTypography.labelS.copyWith(
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 30 * delayIndex))
        .fadeIn(duration: AppTheme.animSlow)
        .slideX(begin: 0.04);
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
