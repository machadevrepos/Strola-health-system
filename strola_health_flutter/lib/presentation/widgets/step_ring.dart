import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/formatters.dart';

class StepRing extends StatelessWidget {
  const StepRing({
    super.key,
    required this.steps,
    required this.goal,
    this.size = 280,
  });

  final int steps;
  final int goal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final progress = (steps / goal).clamp(0.0, 1.0);
    final isGoalReached = steps >= goal;
    // How far into a *second* lap the ring is, once steps pass 100% of goal
    // — e.g. 150% of goal shows as half the ring re-painted in the overflow
    // shade. Capped at one extra full lap (200%) rather than wrapping with
    // modulo, so someone who triples their goal doesn't visually look like
    // they barely passed it.
    final overflowFraction = ((steps / goal) - 1.0).clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        // ── Ambient glow disc behind the ring ────────────────────────────────
        // Intensity scales with progress so the glow grows as you walk.
        Container(
          width: size * 0.84,
          height: size * 0.84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(
                  alpha: progress > 0 ? (0.08 + progress * 0.10) : 0.05,
                ),
                blurRadius: 52,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
        // ── SfRadialGauge ──────────────────────────────────────────────────
        SizedBox(
          width: size,
          height: size,
          child: SfRadialGauge(
            animationDuration: 900,
            enableLoadingAnimation: true,
            axes: [
              // Decorative hairline inner ring — adds premium depth to the gauge
              RadialAxis(
                minimum: 0,
                maximum: 1,
                startAngle: 270,
                endAngle: 270,
                showLabels: false,
                showTicks: false,
                radiusFactor: 0.72,
                axisLineStyle: AxisLineStyle(
                  thickness: 0.030,
                  thicknessUnit: GaugeSizeUnit.factor,
                  color: AppColors.accentSecondary.withValues(alpha: 0.22),
                ),
              ),
              // Main progress ring
              RadialAxis(
                minimum: 0,
                maximum: goal.toDouble(),
                startAngle: 270,
                endAngle: 270,
                showLabels: false,
                showTicks: false,
                axisLineStyle: AxisLineStyle(
                  thickness: 0.13,
                  thicknessUnit: GaugeSizeUnit.factor,
                  color: AppColors.accentSecondary.withValues(alpha: 0.18),
                  cornerStyle: CornerStyle.bothCurve,
                ),
                pointers: [
                  RangePointer(
                    // Explicitly capped rather than relying on the gauge to
                    // clamp an out-of-range value itself — steps regularly
                    // exceed goal, and this axis's maximum is the goal.
                    value: steps.toDouble().clamp(0, goal.toDouble()),
                    width: 0.13,
                    sizeUnit: GaugeSizeUnit.factor,
                    enableAnimation: true,
                    animationDuration: 750,
                    animationType: AnimationType.easeOutBack,
                    // 2-stop sweep gradient: blush start → coral tip
                    gradient: const SweepGradient(
                      colors: [
                        AppColors.accentSecondary, // blush — sweep origin
                        AppColors.accent, // full accent coral
                      ],
                      stops: [0.0, 1.0],
                    ),
                    // Rounded caps at both ends leave a hairline seam where
                    // they meet once the sweep completes a full 360° loop —
                    // flatten them right at full closure so the ring actually
                    // looks closed instead of showing a small gap at the top.
                    cornerStyle: steps >= goal
                        ? CornerStyle.bothFlat
                        : CornerStyle.bothCurve,
                  ),
                  // Overflow lap — painted on top of the base ring, from the
                  // same starting point, so it visually reads as "the ring
                  // has gone around again" rather than a second separate arc.
                  if (overflowFraction > 0)
                    RangePointer(
                      value: overflowFraction * goal,
                      width: 0.13,
                      sizeUnit: GaugeSizeUnit.factor,
                      enableAnimation: true,
                      animationDuration: 750,
                      animationType: AnimationType.easeOutBack,
                      gradient: const SweepGradient(
                        colors: [
                          AppColors
                              .accent, // continues from the base ring's tip
                          AppColors
                              .goalAmber, // amber — same as goal-reached state
                        ],
                        stops: [0.0, 1.0],
                      ),
                      cornerStyle: overflowFraction >= 1.0
                          ? CornerStyle.bothFlat
                          : CornerStyle.bothCurve,
                    ),
                ],
                annotations: [
                  GaugeAnnotation(
                    angle: 90,
                    positionFactor: 0,
                    widget: _CenterAnnotation(
                      steps: steps,
                      goal: goal,
                      progress: progress,
                      isGoalReached: isGoalReached,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Ring center annotation ─────────────────────────────────────────────────────

class _CenterAnnotation extends StatelessWidget {
  const _CenterAnnotation({
    required this.steps,
    required this.goal,
    required this.progress,
    required this.isGoalReached,
  });

  final int steps;
  final int goal;
  final double progress;
  final bool isGoalReached;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toInt();
    final subLabel = isGoalReached
        ? 'Goal achieved! 🎉'
        : '$pct% of ${Formatters.stepCount(goal)}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Running icon — same glyph as the Start Workout tab — scales up
        // slightly on goal reached
        AnimatedContainer(
          duration: AppTheme.animNormal,
          curve: Curves.easeOutBack,
          width: isGoalReached ? 42 : 36,
          height: isGoalReached ? 42 : 36,
          child: Icon(
            AppIcons.start,
            size: isGoalReached ? 42 : 36,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 8),
        // Animated step counter — counts up from 0 on mount
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: steps),
          duration: AppTheme.animSpring,
          curve: Curves.easeOutCubic,
          builder: (_, value, __) => Text(
            Formatters.stepCount(value),
            style: AppTypography.displayL.copyWith(fontSize: 38),
          ),
        ),
        const SizedBox(height: 2),
        Text('Steps', style: AppTypography.bodyM),
        const SizedBox(height: 3),
        // "78% of 10,000" — coral, shifts to amber on goal reached
        AnimatedDefaultTextStyle(
          duration: AppTheme.animFast,
          style: AppTypography.labelM.copyWith(
            color: isGoalReached ? AppColors.goalAmber : AppColors.accent,
            fontWeight: FontWeight.w600,
          ),
          child: Text(subLabel),
        ),
      ],
    );
  }
}
