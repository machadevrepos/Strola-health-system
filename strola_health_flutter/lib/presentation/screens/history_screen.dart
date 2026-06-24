import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/constants/step_goals.dart';
import 'package:strola_health/core/utils/formatters.dart';
import 'package:strola_health/presentation/providers/step_providers.dart';
import 'package:strola_health/presentation/widgets/glass_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklySteps = ref.watch(weeklyStepsProvider);
    final totalWeekly = weeklySteps.reduce((a, b) => a + b);
    final avgDaily = totalWeekly ~/ weeklySteps.length;
    final bestDay = weeklySteps.reduce((a, b) => a > b ? a : b);
    final goalDays = weeklySteps
        .where((s) => s >= StepGoals.defaultDailyGoal)
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'History',
                  style: AppTypography.displayL.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                  ),
                ).animate().fadeIn(duration: AppTheme.animSlow).slideX(begin: 0.12),
              ),
            ),
          ),

          // ── Weekly summary cards ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  _SummaryCard(
                    label: 'Total Steps',
                    value: Formatters.stepCount(totalWeekly),
                    icon: AppIcons.steps,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppTheme.spaceM),
                  _SummaryCard(
                    label: 'Daily Average',
                    value: Formatters.stepCount(avgDaily),
                    icon: AppIcons.showChart,
                    color: AppColors.accentSecondary,
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  _SummaryCard(
                    label: 'Best Day',
                    value: Formatters.stepCount(bestDay),
                    icon: AppIcons.trophy,
                    color: AppColors.goalAmber,
                  ),
                  const SizedBox(width: AppTheme.spaceM),
                  _SummaryCard(
                    label: 'Goal Days',
                    value: '$goalDays / 7',
                    icon: AppIcons.goalReached,
                    color: AppColors.success,
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
            ),
          ),

          // ── 7-day bar chart ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last 7 Days',
                      style: AppTypography.bodyL.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 160,
                      child: BarChart(
                        _buildBarData(weeklySteps),
                        swapAnimationDuration: const Duration(
                          milliseconds: 600,
                        ),
                        swapAnimationCurve: Curves.easeOutCubic,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
            ),
          ),

          // ── Daily breakdown list ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Daily Breakdown',
                style: AppTypography.bodyL.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ).animate().fadeIn(delay: 300.ms),
            ),
          ),

          SliverList.builder(
            itemCount: weeklySteps.length,
            itemBuilder: (context, i) {
              final reversedIndex = weeklySteps.length - 1 - i;
              final steps = weeklySteps[reversedIndex];
              final date = DateTime.now().subtract(Duration(days: i));
              final goalMet = steps >= StepGoals.defaultDailyGoal;

              return Padding(
                padding: EdgeInsets.fromLTRB(20, i == 0 ? 12 : 8, 20, 0),
                child:
                    GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      (goalMet
                                              ? AppColors.goalAmber
                                              : AppColors.accent)
                                          .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  goalMet
                                      ? AppIcons.trophy
                                      : AppIcons.steps,
                                  color: goalMet
                                      ? AppColors.goalAmber
                                      : AppColors.accent,
                                  size: AppTheme.iconM,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Formatters.dayLabel(date),
                                      style: AppTypography.bodyS.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                    Text(
                                      Formatters.fullDate(date),
                                      style: AppTypography.labelS.copyWith(
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    Formatters.stepCount(steps),
                                    style: AppTypography.bodyL.copyWith(
                                      color: goalMet
                                          ? AppColors.goalAmber
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  Text(
                                    '${Formatters.distance(steps)} · ${Formatters.calories(steps)}',
                                    style: AppTypography.labelS.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                        .animate(delay: Duration(milliseconds: 350 + i * 60))
                        .fadeIn()
                        .slideX(begin: 0.08, curve: Curves.easeOut),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  BarChartData _buildBarData(List<int> steps) {
    final maxSteps = steps.reduce((a, b) => a > b ? a : b);
    return BarChartData(
      maxY: (maxSteps * 1.25).toDouble(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 5000,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (v, _) => Text(
              '${(v / 1000).toInt()}k',
              style: AppTypography.labelS.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= steps.length) return const SizedBox.shrink();
              final d = DateTime.now().subtract(
                Duration(days: steps.length - 1 - i),
              );
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  Formatters.dayLabel(d),
                  style: AppTypography.labelS.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barGroups: List.generate(steps.length, (i) {
        final s = steps[i];
        final isToday = i == steps.length - 1;
        final goalMet = s >= StepGoals.defaultDailyGoal;
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: s.toDouble(),
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(5),
              ),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: goalMet
                    ? [
                        AppColors.goalAmber.withValues(alpha: 0.5),
                        AppColors.goalAmber,
                      ]
                    : isToday
                    ? [
                        AppColors.accent.withValues(alpha: 0.5),
                        AppColors.accent,
                      ]
                    : [
                        AppColors.accentSecondary.withValues(alpha: 0.2),
                        AppColors.accentSecondary.withValues(alpha: 0.6),
                      ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTypography.bodyM.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    label,
                    style: AppTypography.labelS.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
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
