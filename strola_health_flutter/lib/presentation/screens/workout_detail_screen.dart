import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/domain/entities/workout_session.dart';
import 'package:strola_health/presentation/screens/session_screen.dart'
    show ActivityTypeUI;
import 'package:strola_health/presentation/screens/session_summary_screen.dart'
    show MetricBox;
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/route_map.dart';

/// Read-only view of a past, already-saved workout — reached by tapping a
/// row in the workout log. Same stats + route layout as the just-completed
/// summary screen, minus confetti/personal-record checks/save-or-delete,
/// since none of that applies to something already in history.
class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key, required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accentSecondary.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: const Icon(
                            AppIcons.back,
                            color: AppColors.textSecondary,
                            size: AppTheme.iconM,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              session.activityType.icon,
                              color: AppColors.accent,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              session.activityType.displayName,
                              style: AppTypography.labelM.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatDate(session.startTime),
                        style: AppTypography.bodyM.copyWith(letterSpacing: 0),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Primary stats ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FlatCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          session.formattedDuration,
                          style: AppTypography.displayXL.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                        Text(
                          'DURATION',
                          style: AppTypography.labelS.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            MetricBox(
                              label: 'STEPS',
                              value: _formatSteps(session.steps),
                              color: AppColors.accent,
                              icon: AppIcons.steps,
                            ),
                            const SizedBox(width: 10),
                            MetricBox(
                              label: 'DISTANCE',
                              value: session.formattedDistance,
                              color: AppColors.accentSecondary,
                              icon: AppIcons.route,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            MetricBox(
                              label: 'CALORIES',
                              value: '${session.calories} kcal',
                              color: AppColors.accent,
                              icon: AppIcons.calories,
                            ),
                            const SizedBox(width: 10),
                            MetricBox(
                              label: 'AVG PACE',
                              value: session.formattedPace,
                              color: AppColors.accentSecondary,
                              icon: AppIcons.pace,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Route map (GPS activities only) ────────────────────────
              if (session.activityType.usesGps)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FlatCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                            child: Row(
                              children: [
                                Text(
                                  'Route',
                                  style: AppTypography.bodyL.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (session.routePoints.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentSecondary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.accentSecondary
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '${session.routePoints.length} GPS points',
                                      style: AppTypography.labelS.copyWith(
                                        color: AppColors.accentSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          StaticRouteMap(
                            routePoints: session.routePoints,
                            height: 220,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.1),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${steps ~/ 1000},${(steps % 1000).toString().padLeft(3, '0')}';
    }
    return '$steps';
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hour = d.hour > 12 ? d.hour - 12 : d.hour;
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}  ·  $hour:${d.minute.toString().padLeft(2, '0')} $period';
  }
}
