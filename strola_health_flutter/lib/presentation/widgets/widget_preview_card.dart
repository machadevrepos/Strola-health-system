import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/formatters.dart';
import 'package:strola_health/presentation/widgets/strolla_icons.dart'; // flame/footstep/clock used in _MiniStat

/// Full widget preview section — shown on the home screen.
/// Contains two preview cards:
///   1. Lock-screen / notification widget (matches inspiration image exactly)
///   2. Home-screen widget (coral card, matches design reference third-last screen)
class WidgetPreviewSection extends StatelessWidget {
  const WidgetPreviewSection({
    super.key,
    required this.steps,
    required this.goal,
    required this.distance,
    required this.calories,
    required this.activeMin,
    required this.weeklySteps,
  });

  final int steps;
  final int goal;
  final String distance;
  final int calories;
  final int activeMin;
  final List<int> weeklySteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ─────────────────────────────────────────────────
        Row(
          children: [
            Text(
              'Widgets',
              style: AppTypography.titleS.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Add to Home',
                style: AppTypography.labelS.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── 1. Lock screen / notification widget preview ───────────────────
        _LockScreenWidgetPreview(steps: steps, goal: goal),
        const SizedBox(height: 10),

        // ── 2. Home screen widget preview (coral card) ────────────────────
        _HomeScreenWidgetPreview(
          steps: steps,
          distance: distance,
          calories: calories,
          activeMin: activeMin,
          weeklySteps: weeklySteps,
        ),

        const SizedBox(height: 10),

        // Instructional hint
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.info, color: AppColors.textMuted, size: 12),
            const SizedBox(width: AppTheme.spaceXS),
            Text(
              'Long-press your home screen → Widgets → Strolla',
              style: AppTypography.labelS.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Lock-screen / notification widget ─────────────────────────────────────────
// Matches the inspiration image: white card, mini ring | step count + bar | motivation

class _LockScreenWidgetPreview extends StatelessWidget {
  const _LockScreenWidgetPreview({
    required this.steps,
    required this.goal,
  });

  final int steps;
  final int goal;

  @override
  Widget build(BuildContext context) {
    // `progress` stays clamped — it only ever feeds the progress bar's
    // fill, which can't visually exceed full. `percent` is the displayed
    // text and should reflect steps actually going over goal (110%, etc.)
    // rather than capping at 100.
    final progress = (steps / goal).clamp(0.0, 1.0);
    final percent = ((steps / goal) * 100).toInt();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentSecondary.withValues(alpha: 0.30),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: App icon square + "Strolla" label — mirrors lock screen widget header
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Center(
                  child: Icon(AppIcons.steps, size: 15, color: Colors.white),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Strolla',
                style: AppTypography.bodyS.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Body: [mini ring] | [step count + progress bar] | [motivation]
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── LEFT: compact progress ring with footstep icon ────────────
              _MiniProgressRing(progress: progress),
              const SizedBox(width: 14),

              // ── CENTRE: step count, sub-label, coral bar, percent ─────────
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: steps),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Text(
                        Formatters.stepCount(v),
                        style: AppTypography.displayM.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.4,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '/ ${Formatters.stepCount(goal)} steps',
                      style: AppTypography.labelS.copyWith(
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 9),
                    // Coral linear progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        height: 7,
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor:
                              AppColors.accentSecondary.withValues(alpha: 0.25),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$percent% of goal',
                      style: AppTypography.labelS.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Vertical divider ──────────────────────────────────────────
              Container(
                width: 1,
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: AppColors.accentSecondary.withValues(alpha: 0.35),
              ),

              // ── RIGHT: sparkle + motivation text ─────────────────────────
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 4-point sparkle star (matches inspiration ✦)
                    const Icon(AppIcons.sparkle, color: AppColors.accent, size: 15),
                    const SizedBox(height: 5),
                    Text(
                      'Every step\ncounts!',
                      style: AppTypography.labelM.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      steps >= goal
                          ? 'Goal achieved! 🎉'
                          : 'Keep going,\nyou\'ve got this!',
                      style: AppTypography.labelS.copyWith(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.06, curve: Curves.easeOut);
  }
}

// ── Compact progress ring used inside the lock screen preview ─────────────────

class _MiniProgressRing extends StatelessWidget {
  const _MiniProgressRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 5.5,
              strokeCap: StrokeCap.round,
              backgroundColor:
                  AppColors.accentSecondary.withValues(alpha: 0.22),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          // Blush circle + footstep icon inside ring
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentSecondary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(AppIcons.steps, color: AppColors.accent, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Home screen widget preview — coral card ───────────────────────────────────
// Matches design reference: coral bg, "strolla" logo, step count, mini chart, stats

class _HomeScreenWidgetPreview extends StatelessWidget {
  const _HomeScreenWidgetPreview({
    required this.steps,
    required this.distance,
    required this.calories,
    required this.activeMin,
    required this.weeklySteps,
  });

  final int steps;
  final String distance;
  final int calories;
  final int activeMin;
  final List<int> weeklySteps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: "strolla" logo + shoe icon ──────────────────────────
          Row(
            children: [
              Text(
                'strolla',
                style: AppTypography.brand.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(AppIcons.steps, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Big step count ────────────────────────────────────────────────
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: steps),
            duration: const Duration(milliseconds: 750),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              Formatters.stepCount(v),
              style: AppTypography.displayXL.copyWith(
                color: Colors.white,
                fontSize: 38,
                letterSpacing: -1.8,
              ),
            ),
          ),
          Text(
            'steps today',
            style: AppTypography.labelM.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 14),

          // ── Mini 7-bar chart (white bars on coral) ────────────────────────
          _MiniBarChart(weeklySteps: weeklySteps),
          const SizedBox(height: 14),

          // ── Stats row: km | kcal | min ────────────────────────────────────
          Row(
            children: [
              _MiniStat(
                icon: StrollaIconType.footstep,
                value: distance,
                unit: 'km',
              ),
              // Vertical divider
              Container(
                width: 1,
                height: 28,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              _MiniStat(
                icon: StrollaIconType.flame,
                value: '$calories',
                unit: 'kcal',
              ),
              Container(
                width: 1,
                height: 28,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              _MiniStat(
                icon: StrollaIconType.clock,
                value: '$activeMin',
                unit: 'min',
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 80.ms, duration: 400.ms)
        .slideY(begin: 0.06, curve: Curves.easeOut);
  }
}

// ── Mini 7-bar chart inside the coral home widget ─────────────────────────────

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.weeklySteps});

  final List<int> weeklySteps;

  @override
  Widget build(BuildContext context) {
    final maxSteps = weeklySteps.isEmpty
        ? 1
        : weeklySteps.reduce((a, b) => a > b ? a : b);
    final safeMax = maxSteps == 0 ? 1 : maxSteps;

    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(weeklySteps.length, (i) {
          final isToday = i == weeklySteps.length - 1;
          final ratio = (weeklySteps[i] / safeMax).clamp(0.06, 1.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FractionallySizedBox(
                heightFactor: ratio,
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    color: isToday
                        ? Colors.white.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Single stat column inside the home widget ─────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.unit,
  });

  final StrollaIconType icon;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StrollaIcon(icon, size: 15, color: Colors.white70),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTypography.bodyM.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            unit,
            style: AppTypography.labelS.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
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
