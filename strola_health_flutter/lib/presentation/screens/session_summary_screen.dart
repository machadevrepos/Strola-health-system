import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/constants/notification_copy.dart';
import 'package:strola_health/core/utils/haptics_helper.dart';
import 'package:strola_health/data/repositories/session_repository.dart';
import 'package:strola_health/domain/entities/app_notification.dart';
import 'package:strola_health/domain/entities/personal_record.dart';
import 'package:strola_health/domain/entities/workout_session.dart';
import 'package:strola_health/presentation/providers/notification_providers.dart';
import 'package:strola_health/presentation/screens/session_screen.dart'
    show ActivityTypeUI;
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/route_map.dart';

class SessionSummaryScreen extends ConsumerStatefulWidget {
  const SessionSummaryScreen({super.key, required this.session});

  final WorkoutSession session;

  @override
  ConsumerState<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends ConsumerState<SessionSummaryScreen> {
  late final ConfettiController _confetti;
  List<PersonalRecordCategory> _newRecords = const [];

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    Future.delayed(const Duration(milliseconds: 400), () {
      _confetti.play();
      HapticsHelper.goalReached();
    });
    _checkPersonalRecords();
  }

  Future<void> _checkPersonalRecords() async {
    final records = await ref
        .read(sessionRepositoryProvider)
        .checkPersonalRecords(widget.session);
    if (mounted) setState(() => _newRecords = records);
    if (records.isEmpty) return;

    final body = records.length == 1
        ? NotificationCopy.personalRecord(records.first.label)
        : 'You just set ${records.length} new personal records this session!';
    await ref.read(notificationsProvider.notifier).add(
          AppNotification(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            category: NotificationCategory.personalRecord,
            title: NotificationCopy.personalRecordTitle,
            body: body,
            timestamp: DateTime.now(),
            routeTarget: 'home',
          ),
        );
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final isPR = _newRecords.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.bgGradient),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.3,
                                  ),
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
                                    '${session.activityType.displayName} Complete',
                                    style: AppTypography.labelM.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isPR) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentSecondary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.accentSecondary.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '🏆',
                                      style: AppTypography.labelM.copyWith(
                                        letterSpacing: 0,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.spaceXS),
                                    Text(
                                      'New Record',
                                      style: AppTypography.labelM.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ).animate().fadeIn(),

                        const SizedBox(height: 16),

                        Text(
                          'Great Work!',
                          style: AppTypography.displayL.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                          ),
                        ).animate().fadeIn(delay: 100.ms, duration: AppTheme.animSlow).slideY(begin: 0.12),

                        const SizedBox(height: 6),

                        Text(
                          _formatDate(session.startTime),
                          style: AppTypography.bodyM.copyWith(letterSpacing: 0),
                        ).animate().fadeIn(delay: 150.ms),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Primary stats ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FlatCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Hero duration
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (_, t, __) {
                              final seconds = (session.durationSeconds * t)
                                  .toInt();
                              final m = seconds ~/ 60;
                              final s = seconds % 60;
                              return Text(
                                '${m}m ${s}s',
                                style: AppTypography.displayXL.copyWith(
                                  color: AppColors.accent,
                                ),
                              );
                            },
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
                              _MetricBox(
                                label: 'STEPS',
                                value: _formatSteps(session.steps),
                                color: AppColors.accent,
                                icon: AppIcons.steps,
                              ),
                              const SizedBox(width: 10),
                              _MetricBox(
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
                              _MetricBox(
                                label: 'CALORIES',
                                value: '${session.calories} kcal',
                                color: AppColors.accent,
                                icon: AppIcons.calories,
                              ),
                              const SizedBox(width: 10),
                              _MetricBox(
                                label: 'AVG PACE',
                                value: session.formattedPace,
                                color: AppColors.accentSecondary,
                                icon: AppIcons.pace,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
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
                            height: 200,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Action buttons ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).popUntil((r) => r.isFirst),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Done',
                              style: AppTypography.titleM.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 50,
              gravity: 0.3,
              colors: const [
                AppColors.accent,
                AppColors.accentSecondary,
                AppColors.bgDeep,
                Colors.white,
              ],
            ),
          ),
        ],
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

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.titleM.copyWith(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelS.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
