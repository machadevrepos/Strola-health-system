import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/constants/step_goals.dart';
import 'package:strola_health/core/utils/formatters.dart';

class WeeklyChart extends StatelessWidget {
  const WeeklyChart({super.key, required this.weeklySteps});

  final List<int> weeklySteps;

  @override
  Widget build(BuildContext context) {
    final maxSteps = weeklySteps.reduce((a, b) => a > b ? a : b);
    // Ensure chart top always clears the goal line, even on low-step days
    final chartMax = (maxSteps * 1.25).clamp(
      StepGoals.defaultDailyGoal * 1.15,
      double.infinity,
    );

    return BarChart(
      BarChartData(
        maxY: chartMax,
        // No grid lines — cleaner, more premium look
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= weeklySteps.length) {
                  return const SizedBox.shrink();
                }
                final isToday = idx == weeklySteps.length - 1;
                final date = DateTime.now().subtract(
                  Duration(days: weeklySteps.length - 1 - idx),
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    Formatters.dayLabel(date),
                    style: AppTypography.labelS.copyWith(
                      color: isToday ? AppColors.accent : AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(weeklySteps.length, (i) {
          final steps = weeklySteps[i];
          final isToday = i == weeklySteps.length - 1;
          final goalMet = steps >= StepGoals.defaultDailyGoal;

          // 3-stop gradient per bar type — bottom → mid → tip
          final List<Color> colors;
          if (isToday) {
            // Today: richest coral treatment
            colors = [
              AppColors.accentSecondary,
              AppColors.accent,
              AppColors.accent.withValues(alpha: 0.88),
            ];
          } else if (goalMet) {
            // Past goal-met days: medium coral (coral palette, not amber)
            colors = [
              AppColors.accentSecondary.withValues(alpha: 0.48),
              AppColors.accent.withValues(alpha: 0.62),
              AppColors.accent.withValues(alpha: 0.78),
            ];
          } else {
            // Other days: soft blush — visible but not distracting
            colors = [
              AppColors.accentSecondary.withValues(alpha: 0.22),
              AppColors.accentSecondary.withValues(alpha: 0.44),
              AppColors.accentSecondary.withValues(alpha: 0.60),
            ];
          }

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: steps.toDouble(),
                width: 18,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: colors,
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ],
          );
        }),
        // Subtle dashed goal line — no label (keeps chart uncluttered)
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: StepGoals.defaultDailyGoal.toDouble(),
              color: AppColors.accent.withValues(alpha: 0.20),
              strokeWidth: 1.2,
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
      swapAnimationDuration: const Duration(milliseconds: 550),
      swapAnimationCurve: Curves.easeOutCubic,
    );
  }
}
