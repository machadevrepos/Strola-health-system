import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/formatters.dart';
import 'package:strola_health/domain/entities/user_profile.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';
import 'package:strola_health/presentation/providers/step_providers.dart';
import 'package:strola_health/presentation/screens/share_steps_screen.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/header_actions.dart';
import 'package:strola_health/presentation/widgets/pressable_scale.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTab = 0;

  static const _tabLabels = ['Overview', 'Steps', 'Distance', 'Activity'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() => _selectedTab = _tabController.index);
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceXL,
                AppTheme.spaceL,
                AppTheme.spaceXL,
                0,
              ),
              child: Row(
                children: [
                  Text(
                        'Stats',
                        style: AppTypography.displayM.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: AppTheme.animSlow)
                      .slideX(begin: -0.1),
                  const Spacer(),
                  const HeaderActions(),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.sectionGap),

            // ── Pill tab bar ─────────────────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceXL,
                ),
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppTheme.spaceS),
                itemCount: _tabLabels.length,
                itemBuilder: (context, i) {
                  final isActive = i == _selectedTab;
                  return PressableScale(
                    onTap: () => _tabController.animateTo(i),
                    child: AnimatedContainer(
                      duration: AppTheme.animFast,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceL,
                        vertical: AppTheme.spaceS,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.accent : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? AppColors.accent
                              : AppColors.accentSecondary.withValues(
                                  alpha: 0.3,
                                ),
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        _tabLabels[i],
                        style: AppTypography.bodyS.copyWith(
                          color: isActive
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppTheme.spaceS),

            // ── Tab content ──────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(
                    onViewAllSteps: () => _tabController.animateTo(1),
                    onViewAllDistance: () => _tabController.animateTo(2),
                  ),
                  const _StepsTab(),
                  const _DistanceTab(),
                  const _ActivityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// OVERVIEW TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({
    required this.onViewAllSteps,
    required this.onViewAllDistance,
  });

  final VoidCallback onViewAllSteps;
  final VoidCallback onViewAllDistance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(stepCountProvider);
    final goal = ref.watch(dailyGoalProvider);
    final calories = ref.watch(caloriesProvider);
    final weekly = ref.watch(weeklyStepsProvider);
    final units = ref.watch(userProfileProvider).units;
    final progress = (steps / goal).clamp(0.0, 1.0);

    final distanceKm = steps * 0.762 / 1000;
    final distanceStr = Formatters.distanceLabelSmart(distanceKm, units);
    final activeMin = (steps ~/ 88); // ~88 steps/min at moderate pace
    final yesterday = weekly.length > 1 ? weekly[weekly.length - 2] : 0;
    final vsYesterday = yesterday > 0
        ? ((steps - yesterday) / yesterday * 100).round()
        : 0;
    final streakDays = _calcStreak(weekly, goal);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceXL,
        AppTheme.spaceXS,
        AppTheme.spaceXL,
        100,
      ),
      children: [
        // Today card
        FlatCard(
              padding: const EdgeInsets.all(AppTheme.spaceXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today',
                              style: AppTypography.titleS.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _todayDate(),
                              style: AppTypography.labelM.copyWith(
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: AppTheme.sectionGap),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: steps.toDouble()),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              builder: (_, v, __) => Text(
                                Formatters.stepCount(v.toInt()),
                                style: AppTypography.displayXL.copyWith(
                                  color: AppColors.accent,
                                  fontSize: 44,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Steps',
                              style: AppTypography.bodyS.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0,
                              ),
                            ),
                            if (yesterday > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    vsYesterday >= 0
                                        ? AppIcons.trendUp
                                        : AppIcons.trendDown,
                                    color: vsYesterday >= 0
                                        ? AppColors.success
                                        : AppColors.error,
                                    size: AppTheme.iconXS,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${vsYesterday.abs()}% vs yesterday',
                                    style: AppTypography.labelM.copyWith(
                                      color: vsYesterday >= 0
                                          ? AppColors.success
                                          : AppColors.error,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceM),
                      // Goal ring
                      SizedBox(
                        width: 104,
                        height: 104,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: 1,
                              strokeWidth: 8,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.accentSecondary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: progress),
                              duration: AppTheme.animCrawl,
                              curve: Curves.easeOutCubic,
                              builder: (_, v, __) => CircularProgressIndicator(
                                value: v,
                                strokeWidth: 8,
                                strokeCap: StrokeCap.round,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.accent,
                                ),
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    AppIcons.start,
                                    size: AppTheme.iconL,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: AppTypography.titleM.copyWith(
                                      color: AppColors.accent,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  Text(
                                    'of daily goal',
                                    style: AppTypography.labelS.copyWith(
                                      fontSize: 9,
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
                    ],
                  ),
                  const SizedBox(height: 18),
                  Divider(
                    height: 1,
                    color: AppColors.accentSecondary.withValues(alpha: 0.18),
                  ),
                  const SizedBox(height: AppTheme.sectionGap),
                  Row(
                    children: [
                      _SubStat(
                        icon: AppIcons.calories,
                        value: '$calories',
                        label: 'Active Calories',
                      ),
                      const _SubDivider(),
                      _SubStat(
                        icon: AppIcons.location,
                        value: distanceStr,
                        label: 'Distance',
                      ),
                      const _SubDivider(),
                      _SubStat(
                        icon: AppIcons.timer,
                        value: '${activeMin ~/ 60}h ${activeMin % 60}m',
                        label: 'Active Time',
                      ),
                    ],
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: AppTheme.animSlow, delay: 50.ms)
            .slideY(begin: 0.12),

        const SizedBox(height: AppTheme.sectionGap),

        // Steps This Week
        FlatCard(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Steps This Week',
                        style: AppTypography.titleS.copyWith(letterSpacing: 0),
                      ),
                      _ViewAllLink(onTap: onViewAllSteps),
                    ],
                  ),
                  Text(
                    Formatters.stepCount(weekly.reduce((a, b) => a + b)),
                    style: AppTypography.titleL.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  SizedBox(
                    height: 132,
                    child: _LabeledWeekBars(
                      values: weekly.map((s) => s.toDouble()).toList(),
                      todayIndex: DateTime.now().weekday - 1,
                      barLabel: (v) => Formatters.stepCount(v.toInt()),
                      axisLabel: (v) => v >= 1000
                          ? '${(v / 1000).round()}K'
                          : v.round().toString(),
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: AppTheme.animSlow, delay: 100.ms)
            .slideY(begin: 0.12),

        const SizedBox(height: AppTheme.sectionGap),

        // Distance This Week
        FlatCard(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Distance This Week',
                        style: AppTypography.titleS.copyWith(letterSpacing: 0),
                      ),
                      _ViewAllLink(onTap: onViewAllDistance),
                    ],
                  ),
                  Text(
                    Formatters.distanceLabel(
                      weekly.reduce((a, b) => a + b) * 0.762 / 1000,
                      units,
                    ),
                    style: AppTypography.titleL.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  SizedBox(
                    height: 132,
                    child: _LabeledWeekBars(
                      values: weekly
                          .map(
                            (s) => Formatters.distanceFromKm(
                              s * 0.762 / 1000,
                              units,
                            ),
                          )
                          .toList(),
                      todayIndex: DateTime.now().weekday - 1,
                      barLabel: (v) => v.toStringAsFixed(1),
                      axisLabel: (v) => v.round().toString(),
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: AppTheme.animSlow, delay: 150.ms)
            .slideY(begin: 0.12),

        const SizedBox(height: AppTheme.sectionGap),

        // Your Averages
        Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppTheme.spaceXS,
                    bottom: AppTheme.spaceM,
                  ),
                  child: Text(
                    'Your Averages',
                    style: AppTypography.titleS.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Row(
                  children: [
                    _AvgBox(
                      icon: AppIcons.steps,
                      value: Formatters.stepCount(
                        weekly.reduce((a, b) => a + b) ~/ weekly.length,
                      ),
                      label: 'Avg. Steps / Day',
                      trend: '+8%',
                      positive: true,
                    ),
                    const SizedBox(width: 10),
                    _AvgBox(
                      icon: AppIcons.calories,
                      value:
                          '${(weekly.reduce((a, b) => a + b) * 0.04 ~/ weekly.length)}',
                      label: 'Avg. Active Calories',
                      trend: '+6%',
                      positive: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _AvgBox(
                      icon: AppIcons.location,
                      value: Formatters.distanceLabel(
                        weekly.reduce((a, b) => a + b) *
                            0.762 /
                            1000 /
                            weekly.length,
                        units,
                      ),
                      label: 'Avg. Distance / Day',
                      trend: '+7%',
                      positive: true,
                    ),
                    const SizedBox(width: 10),
                    _AvgBox(
                      icon: AppIcons.timer,
                      value:
                          '${(weekly.reduce((a, b) => a + b) ~/ weekly.length ~/ 88 ~/ 60)}h ${(weekly.reduce((a, b) => a + b) ~/ weekly.length ~/ 88 % 60)}m',
                      label: 'Avg. Active Time / Day',
                      trend: '+9%',
                      positive: true,
                    ),
                  ],
                ),
              ],
            )
            .animate()
            .fadeIn(duration: AppTheme.animSlow, delay: 200.ms)
            .slideY(begin: 0.12),

        const SizedBox(height: AppTheme.sectionGap),

        // Current Streak
        FlatCard(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      AppIcons.streak,
                      color: AppColors.accent,
                      size: AppTheme.iconL,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Streak',
                          style: AppTypography.labelS.copyWith(
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '$streakDays days',
                          style: AppTypography.titleL.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        Text(
                          streakDays > 0
                              ? "Keep it up! You're on fire! 🔥"
                              : 'Start your streak today!',
                          style: AppTypography.labelM.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(7, (i) {
                      final met = i < weekly.length && weekly[i] >= goal;
                      return Padding(
                        padding: const EdgeInsets.only(left: AppTheme.spaceXS),
                        child: Column(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: met
                                    ? AppColors.accent
                                    : AppColors.accentSecondary.withValues(
                                        alpha: 0.2,
                                      ),
                                border: Border.all(
                                  color: met
                                      ? AppColors.accent
                                      : AppColors.accentSecondary.withValues(
                                          alpha: 0.4,
                                        ),
                                ),
                              ),
                              child: met
                                  ? const Icon(
                                      AppIcons.check,
                                      color: Colors.white,
                                      size: 12,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                              style: AppTypography.labelS.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: AppTheme.animSlow, delay: 250.ms)
            .slideY(begin: 0.12),
      ],
    );
  }

  int _calcStreak(List<int> weekly, int goal) {
    int streak = 0;
    for (int i = weekly.length - 2; i >= 0; i--) {
      if (weekly[i] >= goal) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  String _todayDate() {
    final now = DateTime.now();
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
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEPS TAB
// ═══════════════════════════════════════════════════════════════════════════════

/// Compact step count for small spaces — e.g. "8.5K" instead of "8,500".
String _compactSteps(double v) =>
    v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : v.toStringAsFixed(0);

class _StepsTab extends ConsumerWidget {
  const _StepsTab();

  // Mock 30-day data (in prod, pull from SQLite session_repository)
  static const _mockMonthly = [
    8200,
    11300,
    9800,
    7400,
    10200,
    12100,
    9600,
    8900,
    15842,
    11200,
    10500,
    6800,
    9300,
    10800,
    11500,
    8700,
    9200,
    10100,
    7600,
    9800,
    11000,
    8400,
    10300,
    9700,
    11800,
    12300,
    8900,
    10400,
    9100,
    0,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(stepCountProvider);
    final goal = ref.watch(dailyGoalProvider);

    final data = [..._mockMonthly];
    data[data.length - 1] = steps;

    final total = data.reduce((a, b) => a + b);
    final prevTotal = 183520; // mock previous month
    final pct = ((total - prevTotal) / prevTotal * 100).round();
    final progress = (total / (goal * 31)).clamp(0.0, 1.0);
    final bestDay = data.reduce((a, b) => a > b ? a : b);
    final bestDayIndex = data.indexOf(bestDay);
    final avgPerDay = total ~/ data.where((d) => d > 0).length;
    final daysMetGoal = data.where((d) => d >= goal).length;

    final weeklySteps = ref
        .watch(weeklyStepsProvider)
        .map((e) => e.toDouble())
        .toList();
    final weeklyBestIndex = weeklySteps.indexOf(
      weeklySteps.reduce((a, b) => a > b ? a : b),
    );

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceXL,
        AppTheme.spaceXS,
        AppTheme.spaceXL,
        100,
      ),
      children: [
        // Monthly header card
        FlatCard(
              padding: const EdgeInsets.all(AppTheme.spaceXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'This Month',
                                  style: AppTypography.titleS.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceXS),
                                const Icon(
                                  AppIcons.expandMore,
                                  color: AppColors.textMuted,
                                  size: 18,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _monthLabel(),
                              style: AppTypography.labelM.copyWith(
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: AppTheme.sectionGap),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: total.toDouble()),
                              duration: AppTheme.animCrawl,
                              curve: Curves.easeOutCubic,
                              builder: (_, v, __) => Text(
                                Formatters.stepCount(v.toInt()),
                                style: AppTypography.displayL.copyWith(
                                  color: AppColors.accent,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total Steps',
                              style: AppTypography.bodyS.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  pct >= 0
                                      ? AppIcons.trendUp
                                      : AppIcons.trendDown,
                                  color: pct >= 0
                                      ? AppColors.success
                                      : AppColors.error,
                                  size: AppTheme.iconXS,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${pct.abs()}% vs ${_lastMonthLabel()}',
                                  style: AppTypography.labelM.copyWith(
                                    color: pct >= 0
                                        ? AppColors.success
                                        : AppColors.error,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceM),
                      // Monthly goal ring
                      SizedBox(
                        width: 108,
                        height: 108,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: 1,
                              strokeWidth: 8,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.accentSecondary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: progress),
                              duration: AppTheme.animCrawl,
                              curve: Curves.easeOutCubic,
                              builder: (_, v, __) => CircularProgressIndicator(
                                value: v,
                                strokeWidth: 8,
                                strokeCap: StrokeCap.round,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.accent,
                                ),
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    AppIcons.start,
                                    size: 22,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: AppTypography.titleM.copyWith(
                                      color: AppColors.accent,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  Text(
                                    'of monthly total',
                                    style: AppTypography.labelS.copyWith(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    '${Formatters.stepCount(goal * 31)} steps',
                                    style: AppTypography.labelS.copyWith(
                                      color: AppColors.accent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0,
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
                  const SizedBox(height: AppTheme.spaceL),
                  Row(
                    children: [
                      Text(
                        'Daily Goal:',
                        style: AppTypography.labelM.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceXS),
                      Text(
                        '${Formatters.stepCount(goal)} steps',
                        style: AppTypography.labelM.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceS),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXS),
                    child: LinearProgressIndicator(
                      value: (steps / goal).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppColors.accentSecondary.withValues(
                        alpha: 0.2,
                      ),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: AppTheme.animSlow, delay: 50.ms)
            .slideY(begin: 0.12),

        const SizedBox(height: AppTheme.sectionGap),

        // Monthly chart
        FlatCard(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Steps This Month',
                        style: AppTypography.bodyM.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _ViewAllLink(onTap: () {}),
                    ],
                  ),
                  Text(
                    Formatters.stepCount(total),
                    style: AppTypography.titleM.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceL),
                  SizedBox(
                    height: 200,
                    child: _MonthlyBarsChart(
                      data: data.map((e) => e.toDouble()).toList(),
                      maxY: 20000,
                      interval: 5000,
                      leftReserved: 30,
                      highlightIndex: bestDayIndex,
                      goalLine: goal.toDouble(),
                      axisLabel: (v) => v == 0 ? '0' : '${(v / 1000).round()}K',
                      tooltipLabel: (v) =>
                          '${Formatters.stepCount(v.toInt())} steps',
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: AppTheme.animSlow, delay: 100.ms)
            .slideY(begin: 0.12),

        const SizedBox(height: AppTheme.sectionGap),

        // Steps by day
        FlatCard(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Steps by Day',
                        style: AppTypography.bodyM.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _ViewAllLink(
                        onTap: () => _openMonthSheet(
                          context,
                          title: 'Steps by Day',
                          values: data.map((e) => e.toDouble()).toList(),
                          valueLabel: _compactSteps,
                          unitLabel: 'steps',
                          highlightIndex: bestDayIndex,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.sectionGap),
                  _WeekCircleRow(
                    values: weeklySteps,
                    valueLabel: _compactSteps,
                    unitLabel: 'steps',
                    highlightIndex: weeklyBestIndex,
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: AppTheme.animSlow, delay: 150.ms)
            .slideY(begin: 0.12),

        const SizedBox(height: AppTheme.sectionGap),

        // Steps Insights
        FlatCard(
          padding: const EdgeInsets.all(AppTheme.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Steps Insights',
                style: AppTypography.titleS.copyWith(letterSpacing: 0),
              ),
              const SizedBox(height: AppTheme.spaceM),
              _InsightRow(
                icon: AppIcons.stats,
                title: 'Best Day',
                subtitle: 'May ${bestDayIndex + 1}',
                value: '${Formatters.stepCount(bestDay)}\nsteps',
                onTap: () => _openInsight(
                  context,
                  icon: AppIcons.stats,
                  title: 'Best Day',
                  headline: '${Formatters.stepCount(bestDay)} steps',
                  subtitle: 'May ${bestDayIndex + 1}, ${DateTime.now().year}',
                  body:
                      "This was your most active day this month — that's ${(bestDay / goal * 100).round()}% of your daily goal. Days like this add up fast. Keep chasing them!",
                ),
              ),
              Divider(
                color: AppColors.accent.withValues(alpha: 0.10),
                height: 20,
              ),
              _InsightRow(
                icon: AppIcons.calendarMonth,
                title: 'Average This Month',
                subtitle: '${Formatters.stepCount(avgPerDay)} steps / day',
                value: '+10%\nvs ${_lastMonthLabel()}',
                valueColor: AppColors.success,
                onTap: () => _openInsight(
                  context,
                  icon: AppIcons.calendarMonth,
                  title: 'Average This Month',
                  headline: '${Formatters.stepCount(avgPerDay)} / day',
                  subtitle: '+10% vs ${_lastMonthLabel()}',
                  body:
                      "You're averaging more steps per day than last month. Small, consistent days are the real win — your average is trending up.",
                ),
              ),
              Divider(
                color: AppColors.accent.withValues(alpha: 0.10),
                height: 20,
              ),
              _InsightRow(
                icon: AppIcons.steps,
                title: 'Days Met Goal',
                subtitle: '$daysMetGoal days',
                value: '${(daysMetGoal / 30 * 100).round()}%\nof days',
                onTap: () => _openInsight(
                  context,
                  icon: AppIcons.steps,
                  title: 'Days Met Goal',
                  headline: '$daysMetGoal of 30 days',
                  subtitle: '${(daysMetGoal / 30 * 100).round()}% of days',
                  body: daysMetGoal >= 15
                      ? "You hit your ${Formatters.stepCount(goal)}-step goal on more than half the days this month. That's how strong habits are built!"
                      : "You reached your ${Formatters.stepCount(goal)}-step goal $daysMetGoal days so far. Aim for a few more — you've got this.",
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Row(
                  children: [
                    const Icon(
                      AppIcons.steps,
                      color: AppColors.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        daysMetGoal >= 15
                            ? "You're doing great! You met your daily goal more than half the days this month."
                            : "Keep going! Try to hit your step goal each day.",
                        style: AppTypography.labelM.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              _InsightRow(
                icon: AppIcons.trophy,
                title: 'All-Time Steps',
                subtitle: '512,456 steps',
                value: '',
              ),
            ],
          ),
        ).animate().fadeIn(duration: AppTheme.animSlow, delay: 200.ms).slideY(begin: 0.12),
      ],
    );
  }

  String _monthLabel() {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  String _lastMonthLabel() {
    final now = DateTime.now();
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
    final lastMonth = now.month == 1 ? 11 : now.month - 2;
    return '${months[lastMonth]} ${now.month == 1 ? now.year - 1 : now.year}';
  }

  void _openInsight(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String headline,
    required String subtitle,
    required String body,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _InsightSheet(
        icon: icon,
        title: title,
        headline: headline,
        subtitle: subtitle,
        body: body,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DISTANCE TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _DistanceTab extends ConsumerWidget {
  const _DistanceTab();

  static const _mockMonthly = [
    6.25,
    8.61,
    7.47,
    5.64,
    7.77,
    9.22,
    7.32,
    6.78,
    12.6,
    8.54,
    8.0,
    5.18,
    7.09,
    8.23,
    8.77,
    6.63,
    7.01,
    7.7,
    5.79,
    7.47,
    8.38,
    6.4,
    7.85,
    7.39,
    8.99,
    9.37,
    6.78,
    7.93,
    6.93,
    0.0,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(stepCountProvider);
    final units = ref.watch(userProfileProvider).units;
    final unitLabel = Formatters.distanceUnitLabel(units);
    final todayKm = steps * 0.762 / 1000;

    final kmData = [..._mockMonthly];
    kmData[kmData.length - 1] = todayKm;

    final data = kmData
        .map((km) => Formatters.distanceFromKm(km, units))
        .toList();
    final total = data.fold(0.0, (a, b) => a + b);
    final bestDay = data.reduce((a, b) => a > b ? a : b);
    final bestDayIndex = data.indexOf(bestDay);
    final avgPerDay = total / data.where((d) => d > 0).length;

    final weeklyDistance = ref
        .watch(weeklyStepsProvider)
        .map((s) => Formatters.distanceFromKm(s * 0.762 / 1000, units))
        .toList();
    final weeklyBestIndex = weeklyDistance.indexOf(
      weeklyDistance.reduce((a, b) => a > b ? a : b),
    );

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceXL,
        AppTheme.spaceXS,
        AppTheme.spaceXL,
        100,
      ),
      children: [
        FlatCard(
              padding: const EdgeInsets.all(AppTheme.spaceXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'This Month',
                                  style: AppTypography.titleS.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceXS),
                                const Icon(
                                  AppIcons.expandMore,
                                  color: AppColors.textMuted,
                                  size: 18,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _monthLabel(),
                              style: AppTypography.labelM.copyWith(
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: AppTheme.sectionGap),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: total),
                              duration: AppTheme.animCrawl,
                              curve: Curves.easeOutCubic,
                              builder: (_, v, __) => RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: v.toStringAsFixed(1),
                                      style: AppTypography.displayL.copyWith(
                                        color: AppColors.accent,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' $unitLabel',
                                      style: AppTypography.titleM.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total Distance',
                              style: AppTypography.bodyS.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  AppIcons.trendUp,
                                  color: AppColors.success,
                                  size: AppTheme.iconXS,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '10% vs ${_lastMonthLabel()}',
                                  style: AppTypography.labelM.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceM),
                      // This-month distance badge
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          color: AppColors.accentSecondary.withValues(
                            alpha: 0.18,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              AppIcons.location,
                              color: AppColors.accent,
                              size: 26,
                            ),
                            const SizedBox(height: AppTheme.spaceXS),
                            Text(
                              'This month',
                              style: AppTypography.labelS.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0,
                              ),
                            ),
                            Text(
                              '${total.toStringAsFixed(1)} $unitLabel',
                              style: AppTypography.bodyS.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
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
            .fadeIn(duration: AppTheme.animSlow, delay: 50.ms)
            .slideY(begin: 0.12),

        const SizedBox(height: AppTheme.sectionGap),

        FlatCard(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Distance This Month',
                        style: AppTypography.bodyM.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _ViewAllLink(onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceXS),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${total.toStringAsFixed(1)} $unitLabel',
                        style: AppTypography.titleM.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      Text(
                        'Total Distance',
                        style: AppTypography.labelS.copyWith(
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  SizedBox(
                    height: 200,
                    child: _MonthlyBarsChart(
                      data: data,
                      maxY: units == UnitSystem.imperial ? 10 : 15,
                      interval: units == UnitSystem.imperial ? 2 : 5,
                      leftReserved: 38,
                      highlightIndex: bestDayIndex,
                      axisLabel: (v) => '${v.round()} $unitLabel',
                      tooltipLabel: (v) => '${v.toStringAsFixed(1)} $unitLabel',
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: AppTheme.animSlow, delay: 100.ms)
            .slideY(begin: 0.12),

        const SizedBox(height: AppTheme.sectionGap),

        // Distance by day
        FlatCard(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Distance by Day',
                        style: AppTypography.bodyM.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _ViewAllLink(
                        onTap: () => _openMonthSheet(
                          context,
                          title: 'Distance by Day',
                          values: data,
                          valueLabel: (v) => v.toStringAsFixed(1),
                          unitLabel: unitLabel,
                          highlightIndex: bestDayIndex,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.sectionGap),
                  _WeekCircleRow(
                    values: weeklyDistance,
                    valueLabel: (v) => v.toStringAsFixed(1),
                    unitLabel: unitLabel,
                    highlightIndex: weeklyBestIndex,
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: AppTheme.animSlow, delay: 150.ms)
            .slideY(begin: 0.12),

        const SizedBox(height: AppTheme.sectionGap),

        FlatCard(
          padding: const EdgeInsets.all(AppTheme.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Distance Insights',
                style: AppTypography.titleS.copyWith(letterSpacing: 0),
              ),
              const SizedBox(height: AppTheme.spaceM),
              _InsightRow(
                icon: AppIcons.trophy,
                title: 'Best Day',
                subtitle: 'May ${bestDayIndex + 1}',
                value: '${bestDay.toStringAsFixed(1)} $unitLabel',
                onTap: () => _openInsight(
                  context,
                  icon: AppIcons.trophy,
                  title: 'Best Day',
                  headline: '${bestDay.toStringAsFixed(1)} $unitLabel',
                  subtitle: 'May ${bestDayIndex + 1}, ${DateTime.now().year}',
                  body:
                      'Your longest day this month — you covered more ground than on any other day. Every kilometre counts!',
                ),
              ),
              Divider(
                color: AppColors.accent.withValues(alpha: 0.10),
                height: 20,
              ),
              _InsightRow(
                icon: AppIcons.calendar,
                title: 'Average Per Day',
                subtitle: '${avgPerDay.toStringAsFixed(1)} $unitLabel',
                value: '+10%\nvs ${_lastMonthLabel()}',
                valueColor: AppColors.success,
                onTap: () => _openInsight(
                  context,
                  icon: AppIcons.calendar,
                  title: 'Average Per Day',
                  headline: '${avgPerDay.toStringAsFixed(1)} $unitLabel / day',
                  subtitle: '+10% vs ${_lastMonthLabel()}',
                  body:
                      "You're walking a little further each day than last month. Consistency like this really adds up over time.",
                ),
              ),
              Divider(
                color: AppColors.accent.withValues(alpha: 0.10),
                height: 20,
              ),
              _InsightRow(
                icon: AppIcons.premium,
                title: 'All-Time Distance',
                subtitle: Formatters.distanceLabel(2456.7, units),
                value: '',
                onTap: () => _openInsight(
                  context,
                  icon: AppIcons.premium,
                  title: 'All-Time Distance',
                  headline: Formatters.distanceLabel(2456.7, units),
                  subtitle: 'Since you joined Strolla',
                  body:
                      "That's roughly the distance from London to Athens! Every walk has carried you a little further.",
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: AppTheme.animSlow, delay: 200.ms).slideY(begin: 0.12),
      ],
    );
  }

  String _monthLabel() {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  String _lastMonthLabel() {
    final now = DateTime.now();
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
    final lastMonth = now.month == 1 ? 11 : now.month - 2;
    return '${months[lastMonth]} ${now.month == 1 ? now.year - 1 : now.year}';
  }

  void _openInsight(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String headline,
    required String subtitle,
    required String body,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _InsightSheet(
        icon: icon,
        title: title,
        headline: headline,
        subtitle: subtitle,
        body: body,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ACTIVITY TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _ActivityTab extends ConsumerWidget {
  const _ActivityTab();

  static const _mockWorkouts = [
    ('Outdoor Walk', 45, 312, AppIcons.steps, 'May 19, 2024'),
    ('Outdoor Run', 32, 284, AppIcons.run, 'May 18, 2024'),
    ('Yoga', 50, 156, AppIcons.yoga, 'May 17, 2024'),
    ('Treadmill', 40, 245, AppIcons.treadmill, 'May 16, 2024'),
    ('Cardio', 35, 310, AppIcons.heart, 'May 15, 2024'),
  ];

  static const _weeklyKcal = [356, 289, 412, 325, 298, 215, 167];

  // Last 30 days of active calories (most recent = today).
  static const _monthlyKcal = [
    245,
    312,
    198,
    356,
    289,
    412,
    325,
    276,
    301,
    188,
    264,
    398,
    342,
    215,
    356,
    187,
    298,
    245,
    388,
    312,
    205,
    289,
    401,
    318,
    276,
    412,
    234,
    345,
    298,
    256,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avgKcal = _monthlyKcal.reduce((a, b) => a + b) ~/ _monthlyKcal.length;
    final totalKcal30 = _monthlyKcal.reduce((a, b) => a + b);
    final bestKcalIndex = _monthlyKcal.indexOf(
      _monthlyKcal.reduce((a, b) => a > b ? a : b),
    );
    final weeklyBestKcalIndex = _weeklyKcal.indexOf(
      _weeklyKcal.reduce((a, b) => a > b ? a : b),
    );

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceXL,
        AppTheme.spaceXS,
        AppTheme.spaceXL,
        100,
      ),
      children: [
        // Activity Summary
        FlatCard(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Activity Summary',
                    style: AppTypography.titleS.copyWith(letterSpacing: 0),
                  ),
                  Text(
                    'Last 30 Days',
                    style: AppTypography.labelM.copyWith(
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppTheme.sectionGap),
                  Row(
                    children: [
                      _ActivitySummaryBox(
                        icon: AppIcons.calories,
                        iconColor: AppColors.accent,
                        bgColor: AppColors.accent.withValues(alpha: 0.06),
                        value: Formatters.stepCount(totalKcal30),
                        label: 'Active Calories',
                        avg: 'Avg $avgKcal kcal / day',
                        trend: '6% vs previous 30 days',
                      ),
                      const SizedBox(width: 10),
                      _ActivitySummaryBox(
                        icon: AppIcons.run,
                        iconColor: AppColors.accentSecondary,
                        bgColor: AppColors.accentSecondary.withValues(
                          alpha: 0.08,
                        ),
                        value: '12',
                        label: 'Workouts',
                        avg: 'Avg 0.4 / day',
                        trend: '20% vs previous 30 days',
                      ),
                    ],
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: AppTheme.animSlow, delay: 50.ms)
            .slideY(begin: 0.12),

        const SizedBox(height: AppTheme.sectionGap),

        // Active Calories chart
        FlatCard(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Calories',
                        style: AppTypography.bodyM.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _ViewAllLink(onTap: () {}),
                    ],
                  ),
                  Text(
                    '${Formatters.stepCount(totalKcal30)} kcal',
                    style: AppTypography.titleM.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  Text(
                    '↑ 6% vs previous 30 days',
                    style: AppTypography.labelS.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppTheme.sectionGap),
                  SizedBox(
                    height: 170,
                    child: _MonthlyBarsChart(
                      data: _monthlyKcal.map((e) => e.toDouble()).toList(),
                      maxY: 600,
                      interval: 200,
                      leftReserved: 30,
                      highlightIndex: bestKcalIndex,
                      startDate: DateTime.now().subtract(
                        const Duration(days: 29),
                      ),
                      axisLabel: (v) => v.round().toString(),
                      tooltipLabel: (v) => '${v.round()} kcal',
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: AppTheme.animSlow, delay: 100.ms)
            .slideY(begin: 0.12),

        const SizedBox(height: AppTheme.sectionGap),

        // Activity by day
        FlatCard(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Activity by Day',
                        style: AppTypography.bodyM.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _ViewAllLink(
                        onTap: () => _openMonthSheet(
                          context,
                          title: 'Activity by Day',
                          values: _monthlyKcal
                              .map((e) => e.toDouble())
                              .toList(),
                          valueLabel: (v) => v.round().toString(),
                          unitLabel: 'kcal',
                          highlightIndex: bestKcalIndex,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.sectionGap),
                  _WeekCircleRow(
                    values: _weeklyKcal.map((e) => e.toDouble()).toList(),
                    valueLabel: (v) => v.round().toString(),
                    unitLabel: 'kcal',
                    highlightIndex: weeklyBestKcalIndex,
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  Text(
                    'Daily average: $avgKcal kcal',
                    style: AppTypography.labelS.copyWith(
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: AppTheme.animSlow, delay: 150.ms)
            .slideY(begin: 0.12),

        const SizedBox(height: AppTheme.sectionGap),

        // Activity Insights
        FlatCard(
          padding: const EdgeInsets.all(AppTheme.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity Insights',
                style: AppTypography.titleS.copyWith(letterSpacing: 0),
              ),
              const SizedBox(height: AppTheme.spaceM),
              _InsightRow(
                icon: AppIcons.calories,
                title: "You're on fire!",
                subtitle:
                    'You burned 6% more calories compared to the previous 30 days.',
                value: '',
                onTap: () => _openInsight(
                  context,
                  icon: AppIcons.calories,
                  title: "You're on fire!",
                  headline: '+6% calories',
                  subtitle: 'vs the previous 30 days',
                  body:
                      'You burned more active calories this month than last. Your effort is paying off — keep that fire going!',
                ),
              ),
              Divider(
                color: AppColors.accent.withValues(alpha: 0.10),
                height: 20,
              ),
              _InsightRow(
                icon: AppIcons.run,
                title: 'More movement, more results',
                subtitle:
                    'Your workouts are up 20% compared to the previous 30 days.',
                value: '',
                onTap: () => _openInsight(
                  context,
                  icon: AppIcons.run,
                  title: 'More movement, more results',
                  headline: '+20% workouts',
                  subtitle: 'vs the previous 30 days',
                  body:
                      "You're moving more often than last month. Every session builds strength and energy — amazing consistency!",
                ),
              ),
              Divider(
                color: AppColors.accent.withValues(alpha: 0.10),
                height: 20,
              ),
              _InsightRow(
                icon: AppIcons.calendarMonth,
                title: 'Keep it up!',
                subtitle: "You've been active on 24 of the last 30 days.",
                value: '',
                onTap: () => _openInsight(
                  context,
                  icon: AppIcons.calendarMonth,
                  title: 'Keep it up!',
                  headline: '24 of 30 days',
                  subtitle: 'active this month',
                  body:
                      'You showed up on 24 of the last 30 days. Turning movement into a habit is exactly how lasting change happens.',
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: AppTheme.animSlow, delay: 200.ms).slideY(begin: 0.12),

        const SizedBox(height: AppTheme.sectionGap),

        // Recent Workouts
        FlatCard(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Workouts',
                        style: AppTypography.titleS.copyWith(letterSpacing: 0),
                      ),
                      _ViewAllLink(onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  ..._mockWorkouts.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
                      child:
                          PressableScale(
                                onTap: () => _openWorkout(context, e.value),
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        e.value.$4,
                                        color: AppColors.accent,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.spaceM),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.value.$1,
                                            style: AppTypography.bodyS.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0,
                                            ),
                                          ),
                                          Text(
                                            '${e.value.$5} · ${e.value.$2} min',
                                            style: AppTypography.labelS
                                                .copyWith(
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: 0,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${e.value.$3} kcal',
                                      style: AppTypography.bodyS.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      AppIcons.chevronRight,
                                      color: AppColors.textMuted,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              )
                              .animate(
                                delay: Duration(milliseconds: 200 + e.key * 60),
                              )
                              .fadeIn(duration: AppTheme.animSlow)
                              .slideX(begin: 0.12),
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: AppTheme.animSlow, delay: 250.ms)
            .slideY(begin: 0.12),
      ],
    );
  }

  void _openInsight(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String headline,
    required String subtitle,
    required String body,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _InsightSheet(
        icon: icon,
        title: title,
        headline: headline,
        subtitle: subtitle,
        body: body,
      ),
    );
  }

  void _openWorkout(
    BuildContext context,
    (String, int, int, IconData, String) w,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorkoutDetailSheet(
        name: w.$1,
        minutes: w.$2,
        kcal: w.$3,
        icon: w.$4,
        date: w.$5,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED CHART WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// Monthly bars chart with daily bars (best day highlighted + touch tooltip),
/// a dashed 7-day average overlay, an optional Goal line, a Y-axis and dated
/// X-axis ticks. Used by both the Steps and Distance tabs.
class _MonthlyBarsChart extends StatelessWidget {
  const _MonthlyBarsChart({
    required this.data,
    required this.maxY,
    required this.interval,
    required this.highlightIndex,
    required this.axisLabel,
    required this.tooltipLabel,
    this.goalLine,
    this.leftReserved = 32,
    this.startDate,
  });

  final List<double> data;
  final double maxY;
  final double interval;
  final int highlightIndex;
  final String Function(double) axisLabel; // left axis tick label
  final String Function(double) tooltipLabel; // value in the touch tooltip
  final double? goalLine; // optional dashed "Goal" line
  final double leftReserved;

  /// When set, bars are labelled as a rolling window starting from this date
  /// (e.g. last 30 days). When null, labels are calendar-month days.
  final DateTime? startDate;

  @override
  Widget build(BuildContext context) {
    final n = data.length;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceBetween,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.textPrimary,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            getTooltipItem: (group, _, __, ___) => BarTooltipItem(
              '${tooltipLabel(data[group.x])}\n',
              AppTypography.labelS.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
              children: [
                TextSpan(
                  text: _dayLabel(group.x),
                  style: AppTypography.labelS.copyWith(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: leftReserved,
              interval: interval,
              getTitlesWidget: _leftTitle,
            ),
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
              reservedSize: 20,
              interval: 1,
              getTitlesWidget: _bottomTitle,
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.accentSecondary.withValues(alpha: 0.15),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (goalLine != null)
              HorizontalLine(
                y: goalLine!,
                color: AppColors.accent,
                strokeWidth: 1,
                dashArray: [4, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  labelResolver: (_) => 'Goal',
                  style: AppTypography.labelS.copyWith(
                    color: AppColors.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
          ],
        ),
        barGroups: List.generate(n, (i) {
          final isHi = i == highlightIndex;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i],
                color: isHi
                    ? AppColors.accent
                    : AppColors.accentSecondary.withValues(alpha: 0.4),
                width: 5,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(2),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _leftTitle(double value, TitleMeta meta) {
    if ((value % interval).abs() > 0.01) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spaceXS),
      child: Text(
        axisLabel(value),
        style: AppTypography.labelS.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _bottomTitle(double value, TitleMeta meta) {
    final i = value.toInt();
    if (i != 0 && i != 7 && i != 14 && i != 21 && i != 28) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        _dayLabel(i),
        style: AppTypography.labelS.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
      ),
    );
  }

  String _dayLabel(int index) {
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
    if (startDate != null) {
      final d = startDate!.add(Duration(days: index));
      return '${months[d.month - 1]} ${d.day}';
    }
    final m = months[DateTime.now().month - 1];
    return '$m ${index + 1}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WEEK / MONTH CIRCLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

void _openMonthSheet(
  BuildContext context, {
  required String title,
  required List<double> values,
  required String Function(double) valueLabel,
  required String unitLabel,
  required int highlightIndex,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _MonthCircleSheet(
      title: title,
      values: values,
      valueLabel: valueLabel,
      unitLabel: unitLabel,
      highlightIndex: highlightIndex,
    ),
  );
}

/// A row of 7 circles (Mon→Sun), each showing one day's value — the best
/// day is highlighted in coral. Used by the "X by Day" cards.
class _WeekCircleRow extends StatelessWidget {
  const _WeekCircleRow({
    required this.values,
    required this.valueLabel,
    required this.unitLabel,
    required this.highlightIndex,
  });

  final List<double> values; // 7 entries, Mon→Sun
  final String Function(double) valueLabel;
  final String unitLabel;
  final int highlightIndex;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(values.length, (i) {
        final isHi = i == highlightIndex;
        return Expanded(
          child: Column(
            children: [
              Text(
                _days[i],
                style: AppTypography.labelS.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: AppTheme.spaceS),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isHi
                      ? AppColors.accent
                      : AppColors.accentSecondary.withValues(alpha: 0.18),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        valueLabel(values[i]),
                        style: AppTypography.labelM.copyWith(
                          color: isHi ? Colors.white : AppColors.accent,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      Text(
                        unitLabel,
                        style: AppTypography.labelS.copyWith(
                          color: isHi ? Colors.white70 : AppColors.textMuted,
                          fontSize: 7,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Bottom sheet showing a full month of daily values as circles in a
/// 7-column calendar grid — opened from a "by Day" card's "View All" link.
class _MonthCircleSheet extends StatelessWidget {
  const _MonthCircleSheet({
    required this.title,
    required this.values,
    required this.valueLabel,
    required this.unitLabel,
    required this.highlightIndex,
  });

  final String title;
  final List<double> values; // oldest → newest (last entry = today)
  final String Function(double) valueLabel;
  final String unitLabel;
  final int highlightIndex;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final n = values.length;
    final todayIndex = n - 1;
    final rows = (n / 7).ceil();

    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceM),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceXL,
        AppTheme.spaceM,
        AppTheme.spaceXL,
        AppTheme.spaceXL,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSheet),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.accentSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: AppTypography.titleM.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          Text(
            'Last 30 Days · $unitLabel',
            style: AppTypography.labelM.copyWith(
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppTheme.spaceL),
          Row(
            children: _days
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: AppTypography.labelS.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          for (var r = 0; r < rows; r++)
            Padding(
              padding: EdgeInsets.only(bottom: r == rows - 1 ? 0 : 10),
              child: Row(
                children: List.generate(7, (c) {
                  final i = r * 7 + c;
                  if (i >= n) return const Expanded(child: SizedBox());
                  final isHi = i == highlightIndex;
                  final isToday = i == todayIndex;
                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isHi
                                ? AppColors.accent
                                : AppColors.accentSecondary.withValues(
                                    alpha: 0.18,
                                  ),
                            border: isToday
                                ? Border.all(
                                    color: AppColors.accent,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              valueLabel(values[i]),
                              style: AppTypography.labelS.copyWith(
                                color: isHi ? Colors.white : AppColors.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceXS),
                        Text(
                          '${i + 1}',
                          style: AppTypography.labelS.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _SubDivider extends StatelessWidget {
  const _SubDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: AppColors.accentSecondary.withValues(alpha: 0.25),
    );
  }
}

/// Week bar chart with a value label above every bar, a small left axis, and
/// today highlighted — matches the Stats Overview design.
class _LabeledWeekBars extends StatelessWidget {
  const _LabeledWeekBars({
    required this.values,
    required this.todayIndex,
    required this.barLabel,
    required this.axisLabel,
  });

  final List<double> values; // 7 entries, Mon→Sun
  final int todayIndex;
  final String Function(double) barLabel;
  final String Function(double) axisLabel;

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final rawMax = values.fold<double>(0, (m, v) => v > m ? v : m);
    final niceMax = rawMax <= 0 ? 1.0 : rawMax * 1.28;

    final axisStyle = AppTypography.labelS.copyWith(
      fontSize: 9,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left axis
        Padding(
          padding: const EdgeInsets.only(
            top: AppTheme.spaceL,
            bottom: AppTheme.spaceXL,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(axisLabel(niceMax), style: axisStyle),
              Text(axisLabel(niceMax / 2), style: axisStyle),
              Text(axisLabel(0), style: axisStyle),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.spaceS),
        // Bars
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(values.length, (i) {
              final isToday = i == todayIndex;
              final barColor = isToday
                  ? AppColors.accent
                  : AppColors.accentSecondary.withValues(alpha: 0.45);
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      barLabel(values[i]),
                      style: AppTypography.labelS.copyWith(
                        color: isToday
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXS),
                    Expanded(
                      child: FractionallySizedBox(
                        alignment: Alignment.bottomCenter,
                        heightFactor: (values[i] / niceMax)
                            .clamp(0.02, 1.0)
                            .toDouble(),
                        child: Container(
                          width: 14,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppTheme.radiusXS),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      days[i],
                      style: AppTypography.labelS.copyWith(
                        color: isToday ? AppColors.accent : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SubStat extends StatelessWidget {
  const _SubStat({
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
          Icon(icon, color: AppColors.accent, size: 18),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            value,
            style: AppTypography.bodyM.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelS.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AvgBox extends StatelessWidget {
  const _AvgBox({
    required this.icon,
    required this.value,
    required this.label,
    required this.trend,
    required this.positive,
  });

  final IconData icon;
  final String value;
  final String label;
  final String trend;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FlatCard(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.accent, size: 18),
            const SizedBox(height: AppTheme.spaceS),
            Text(
              value,
              style: AppTypography.titleM.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
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
            const SizedBox(height: AppTheme.spaceXS),
            Row(
              children: [
                Icon(
                  positive ? AppIcons.trendUp : AppIcons.trendDown,
                  color: positive ? AppColors.success : AppColors.error,
                  size: 10,
                ),
                Text(
                  trend,
                  style: AppTypography.labelS.copyWith(
                    color: positive ? AppColors.success : AppColors.error,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  ' vs last week',
                  style: AppTypography.labelS.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.valueColor = AppColors.accent,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final Color valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.accent, size: 16),
        ),
        const SizedBox(width: AppTheme.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyS.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.labelS.copyWith(
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        if (value.isNotEmpty) ...[
          const SizedBox(width: AppTheme.spaceS),
          Text(
            value,
            style: AppTypography.labelM.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            textAlign: TextAlign.right,
          ),
        ],
        if (value.isNotEmpty || onTap != null) ...[
          const SizedBox(width: AppTheme.spaceXS),
          Icon(
            AppIcons.chevronRight,
            color: AppColors.textMuted,
            size: AppTheme.iconS,
          ),
        ],
      ],
    );

    if (onTap == null) return row;
    return PressableScale(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: row,
    );
  }
}

class _ActivitySummaryBox extends StatelessWidget {
  const _ActivitySummaryBox({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.value,
    required this.label,
    required this.avg,
    required this.trend,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String value;
  final String label;
  final String avg;
  final String trend;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTypography.titleL.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    label,
                    style: AppTypography.labelS.copyWith(
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    avg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelS.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          AppIcons.trendUp,
                          color: AppColors.success,
                          size: 11,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          trend,
                          maxLines: 2,
                          style: AppTypography.labelS.copyWith(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
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

class _WorkoutDetailSheet extends ConsumerWidget {
  const _WorkoutDetailSheet({
    required this.name,
    required this.minutes,
    required this.kcal,
    required this.icon,
    required this.date,
  });

  final String name;
  final int minutes;
  final int kcal;
  final IconData icon;
  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(userProfileProvider).units;
    final distanceKm = minutes * 0.095;

    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceM),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceXL,
        AppTheme.spaceM,
        AppTheme.spaceXL,
        AppTheme.spaceXL,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSheet),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.accentSecondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.titleM.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      date,
                      style: AppTypography.labelM.copyWith(
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _SubStat(
                  icon: AppIcons.timer,
                  value: '$minutes min',
                  label: 'Duration',
                ),
                const _SubDivider(),
                _SubStat(
                  icon: AppIcons.location,
                  value: Formatters.distanceLabel(distanceKm, units),
                  label: 'Distance',
                ),
                const _SubDivider(),
                _SubStat(
                  icon: AppIcons.calories,
                  value: '$kcal',
                  label: 'Active Calories',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceXL),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                final nav = Navigator.of(context);
                nav.pop();
                nav.push(
                  MaterialPageRoute(builder: (_) => const ShareStepsScreen()),
                );
              },
              icon: Icon(AppIcons.share, color: Colors.white, size: 18),
              label: Text(
                'Share Workout',
                style: AppTypography.bodyM.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightSheet extends StatelessWidget {
  const _InsightSheet({
    required this.icon,
    required this.title,
    required this.headline,
    required this.subtitle,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String headline;
  final String subtitle;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceM),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceXL,
        AppTheme.spaceM,
        AppTheme.spaceXL,
        AppTheme.spaceXL,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSheet),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.accentSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: AppTheme.statChipCircleSize,
                height: AppTheme.statChipCircleSize,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleM.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.labelM.copyWith(
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
          Text(
            headline,
            style: AppTypography.displayM.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Text(body, style: AppTypography.bodyS.copyWith(letterSpacing: 0)),
          const SizedBox(height: AppTheme.spaceXL),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Got it',
                style: AppTypography.bodyM.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewAllLink extends StatelessWidget {
  const _ViewAllLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Text(
        'View All',
        style: AppTypography.labelM.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
