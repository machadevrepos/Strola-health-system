import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_typography.dart';

/// Today's step distribution broken into 24 hourly bars.
/// X-axis labels: 12AM · 6AM · 12PM · 6PM.
/// Y-axis labels: 0 · 1K · 2K (fixed scale — keeps the chart stable
/// as live data updates rather than rescaling on every tick).
class HourlyChart extends StatelessWidget {
  const HourlyChart({super.key, required this.hourlySteps});

  final List<int> hourlySteps; // 24 values, index = hour 0–23

  static const double _chartMaxY = 2100;
  static const double _yInterval  = 1000;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().hour;

    return BarChart(
      BarChartData(
        maxY: _chartMaxY,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _yInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.accentSecondary.withValues(alpha: 0.18),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _yInterval,
              getTitlesWidget: _leftTitle,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: _bottomTitle,
            ),
          ),
        ),
        barGroups: List.generate(hourlySteps.length, (i) {
          // Clamp to 0.5 minimum — a zero-height bar combined with LinearGradient
          // produces a zero-size rect that causes "Rect contained NaN" errors.
          final steps = hourlySteps[i] < 1 ? 0.5 : hourlySteps[i].toDouble();
          final isPast = i <= now;

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: steps,
                width: 7,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: isPast
                      ? [
                          AppColors.accentSecondary.withValues(alpha: 0.55),
                          AppColors.accent,
                        ]
                      : [
                          AppColors.accentSecondary.withValues(alpha: 0.12),
                          AppColors.accentSecondary.withValues(alpha: 0.25),
                        ],
                ),
              ),
            ],
          );
        }),
        barTouchData: BarTouchData(enabled: false),
      ),
      swapAnimationDuration: const Duration(milliseconds: 500),
      swapAnimationCurve: Curves.easeOutCubic,
    );
  }

  Widget _leftTitle(double value, TitleMeta meta) {
    String text;
    if (value == 0) {
      text = '0';
    } else if (value == 1000) {
      text = '1K';
    } else if (value == 2000) {
      text = '2K';
    } else {
      return const SizedBox.shrink();
    }
    return Text(
      text,
      style: AppTypography.labelS,
      textAlign: TextAlign.right,
    );
  }

  Widget _bottomTitle(double value, TitleMeta meta) {
    final hour = value.toInt();
    String? label;
    switch (hour) {
      case 0:
        label = '12AM';
      case 6:
        label = '6AM';
      case 12:
        label = '12PM';
      case 18:
        label = '6PM';
    }
    if (label == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(label, style: AppTypography.labelS),
    );
  }
}
