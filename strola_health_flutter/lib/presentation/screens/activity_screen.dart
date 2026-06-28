import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/constants/step_goals.dart';
import 'package:strola_health/core/utils/formatters.dart';
import 'package:strola_health/domain/entities/workout_session.dart';
import 'package:strola_health/presentation/providers/session_providers.dart';
import 'package:strola_health/presentation/providers/step_providers.dart';
import 'package:strola_health/presentation/screens/session_screen.dart'
    show ActivityTypeUI;
import 'package:strola_health/presentation/screens/workout_detail_screen.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/pressable_scale.dart';
import 'package:strola_health/presentation/widgets/skeleton_loaders.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
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
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                        'Activity',
                        style: AppTypography.displayL.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: AppTheme.animSlow)
                      .slideX(begin: 0.12),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Glass tab bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FlatCard(
                padding: const EdgeInsets.all(4),
                borderRadius: 16,
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.4),
                    ),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: AppTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                  unselectedLabelStyle: AppTypography.bodyS.copyWith(
                    letterSpacing: 0,
                  ),
                  tabs: const [
                    Tab(text: 'Log'),
                    Tab(text: 'Week'),
                    Tab(text: 'Month'),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 8),

            // ── Tab content ────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: const [_LogTab(), _WeekTab(), _MonthTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Log tab — workout history ─────────────────────────────────────────────────

class _LogTab extends ConsumerWidget {
  const _LogTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionHistoryProvider);

    return sessionsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: WorkoutLogSkeleton(),
      ),
      error: (_, __) => const _ErrorState(),
      data: (sessions) {
        if (sessions.isEmpty) {
          return const _EmptyLogState();
        }
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverList.separated(
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) =>
                    _SessionCard(session: sessions[i], index: i),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.index});

  final WorkoutSession session;
  final int index;

  @override
  Widget build(BuildContext context) {
    final type = session.activityType;
    // Alternate coral/blush so consecutive entries don't all look identical.
    final color = (index % 2 == 0)
        ? AppColors.accent
        : AppColors.accentSecondary;

    return PressableScale(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WorkoutDetailScreen(session: session),
        ),
      ),
      child:
          FlatCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: color.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(type.icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.displayName,
                            style: AppTypography.bodyM.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatDate(session.startTime),
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
                          type.countsSteps
                              ? Formatters.stepCount(session.steps)
                              : session.formattedDuration,
                          style: AppTypography.titleM.copyWith(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          type.showsDistance
                              ? '${session.formattedDistance}  ·  ${session.formattedDuration}'
                              : '${session.calories} kcal  ·  ${session.formattedDuration}',
                          style: AppTypography.labelS.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
              .animate(delay: Duration(milliseconds: 80 * index))
              .fadeIn()
              .slideX(begin: 0.08, curve: Curves.easeOut),
    );
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
    final h = d.hour > 12 ? d.hour - 12 : d.hour;
    final p = d.hour >= 12 ? 'PM' : 'AM';
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}  ·  $h:${d.minute.toString().padLeft(2, '0')} $p';
  }
}

class _EmptyLogState extends StatelessWidget {
  const _EmptyLogState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.steps,
              color: AppColors.accent,
              size: 36,
            ),
          ).animate().fadeIn().scale(
            begin: const Offset(0.7, 0.7),
            curve: Curves.easeOutBack,
          ),
          const SizedBox(height: 16),
          Text(
            'No workouts yet',
            style: AppTypography.titleM.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 6),
          Text(
            'Start a walk or run to see\nyour workout history here.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyM.copyWith(letterSpacing: 0),
          ).animate().fadeIn(delay: 150.ms),
        ],
      ),
    );
  }
}

// ── Week tab ──────────────────────────────────────────────────────────────────

class _WeekTab extends ConsumerWidget {
  const _WeekTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklySteps = ref.watch(weeklyStepsProvider);
    final weightKg = ref.watch(userWeightKgProvider);
    final totalWeekly = weeklySteps.reduce((a, b) => a + b);
    final avgDaily = totalWeekly ~/ weeklySteps.length;
    final bestDay = weeklySteps.reduce((a, b) => a > b ? a : b);
    final goalDays = weeklySteps
        .where((s) => s >= StepGoals.defaultDailyGoal)
        .length;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Summary cards
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _WeekStatCard(
                label: 'Total Steps',
                value: Formatters.stepCount(totalWeekly),
                icon: AppIcons.steps,
                color: AppColors.accent,
              ),
              _WeekStatCard(
                label: 'Daily Avg',
                value: Formatters.stepCount(avgDaily),
                icon: AppIcons.showChart,
                color: AppColors.accentSecondary,
              ),
              _WeekStatCard(
                label: 'Best Day',
                value: Formatters.stepCount(bestDay),
                icon: AppIcons.trophy,
                color: AppColors.accent,
              ),
              _WeekStatCard(
                label: 'Goal Days',
                value: '$goalDays / 7',
                icon: AppIcons.goalReached,
                color: AppColors.accentSecondary,
              ),
            ],
          ),
        ),

        // Bar chart
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: FlatCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Last 7 Days',
                        style: AppTypography.bodyL.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 2,
                              color: AppColors.accent.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Goal',
                              style: AppTypography.labelS.copyWith(
                                color: AppColors.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: _WeekBarChart(steps: weeklySteps),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08),
          ),
        ),

        // Daily breakdown
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Daily Breakdown',
              style: AppTypography.bodyL.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ).animate().fadeIn(delay: 150.ms),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
          sliver: SliverList.builder(
            itemCount: weeklySteps.length,
            itemBuilder: (_, i) {
              final reversed = weeklySteps.length - 1 - i;
              final steps = weeklySteps[reversed];
              final date = DateTime.now().subtract(Duration(days: i));
              final goalMet = steps >= StepGoals.defaultDailyGoal;
              final color = goalMet
                  ? AppColors.accent
                  : AppColors.accentSecondary;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child:
                    FlatCard(
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
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  goalMet ? AppIcons.trophy : AppIcons.steps,
                                  color: color,
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
                                      color: color,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  Text(
                                    '${Formatters.distance(steps)} · ${Formatters.calories(steps, weightKg: weightKg)}',
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
                        .animate(delay: Duration(milliseconds: 200 + i * 60))
                        .fadeIn()
                        .slideX(begin: 0.06, curve: Curves.easeOut),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WeekStatCard extends StatelessWidget {
  const _WeekStatCard({
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
    return FlatCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: AppTypography.bodyS.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
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
    ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.06);
  }
}

class _WeekBarChart extends StatelessWidget {
  const _WeekBarChart({required this.steps});

  final List<int> steps;

  @override
  Widget build(BuildContext context) {
    final maxSteps = steps.reduce((a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: (maxSteps * 1.25).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5000,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.accentSecondary.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: StepGoals.defaultDailyGoal.toDouble(),
              color: AppColors.accent.withValues(alpha: 0.4),
              strokeWidth: 1.5,
              dashArray: [6, 4],
            ),
          ],
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
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
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
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
                width: 14,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: goalMet
                      ? [
                          AppColors.accent.withValues(alpha: 0.6),
                          AppColors.accent,
                        ]
                      : isToday
                      ? [
                          AppColors.accent.withValues(alpha: 0.5),
                          AppColors.accent,
                        ]
                      : [
                          AppColors.accentSecondary.withValues(alpha: 0.2),
                          AppColors.accentSecondary.withValues(alpha: 0.5),
                        ],
                ),
              ),
            ],
          );
        }),
      ),
      swapAnimationDuration: const Duration(milliseconds: 600),
      swapAnimationCurve: Curves.easeOutCubic,
    );
  }
}

// ── Month tab — calendar heat-map ─────────────────────────────────────────────

class _MonthTab extends ConsumerStatefulWidget {
  const _MonthTab();

  @override
  ConsumerState<_MonthTab> createState() => _MonthTabState();
}

class _MonthTabState extends ConsumerState<_MonthTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final dailyStepsAsync = ref.watch(dailyStepsMapProvider);

    return dailyStepsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (_, __) => const _ErrorState(),
      data: (stepsMap) => _buildCalendar(stepsMap),
    );
  }

  Widget _buildCalendar(Map<DateTime, int> stepsMap) {
    // Add mock data for visual richness during development
    final enriched = {
      ...stepsMap,
      for (var i = 1; i <= 30; i++)
        DateTime(DateTime.now().year, DateTime.now().month, i):
            (3000 + i * 300) % 15000,
    };

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverToBoxAdapter(
            child: FlatCard(
              padding: const EdgeInsets.all(12),
              child: TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.now(),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (d) => setState(() => _focusedDay = d),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: AppTypography.bodyL.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                  leftChevronIcon: const Icon(
                    AppIcons.chevronLeft,
                    color: AppColors.textSecondary,
                  ),
                  rightChevronIcon: const Icon(
                    AppIcons.chevronRight,
                    color: AppColors.textSecondary,
                  ),
                  headerPadding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: AppTypography.labelS.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                  weekendStyle: AppTypography.labelS.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: AppTypography.labelM.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.6),
                    ),
                  ),
                  todayTextStyle: AppTypography.labelM.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: AppTypography.labelM.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, _) {
                    final dateKey = DateTime(day.year, day.month, day.day);
                    final steps = enriched[dateKey] ?? 0;
                    if (steps == 0) return null;
                    final intensity = (steps / StepGoals.defaultDailyGoal)
                        .clamp(0.1, 1.0);
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(
                          alpha: intensity * 0.7,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: AppTypography.labelM.copyWith(
                            color: intensity > 0.5
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.05),
          ),
        ),

        // Heat-map legend
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Less',
                  style: AppTypography.labelS.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 8),
                ...List.generate(5, (i) {
                  final opacity = 0.1 + i * 0.18;
                  return Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: opacity),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  'More',
                  style: AppTypography.labelS.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms),
          ),
        ),

        // Selected day detail
        if (_selectedDay != null) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Consumer(
                builder: (_, ref, __) => _SelectedDayCard(
                  day: _selectedDay!,
                  steps:
                      enriched[DateTime(
                        _selectedDay!.year,
                        _selectedDay!.month,
                        _selectedDay!.day,
                      )] ??
                      0,
                  weightKg: ref.watch(userWeightKgProvider),
                ).animate().fadeIn().slideY(begin: 0.08),
              ),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({
    required this.day,
    required this.steps,
    required this.weightKg,
  });

  final DateTime day;
  final int steps;
  final double weightKg;

  @override
  Widget build(BuildContext context) {
    final goalMet = steps >= StepGoals.defaultDailyGoal;
    final color = goalMet ? AppColors.accent : AppColors.accentSecondary;

    return FlatCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              goalMet ? AppIcons.trophy : AppIcons.steps,
              color: color,
              size: AppTheme.iconM,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.dayLabel(day),
                  style: AppTypography.bodyM.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  steps > 0
                      ? '${Formatters.distance(steps)} · ${Formatters.calories(steps, weightKg: weightKg)}'
                      : 'No data',
                  style: AppTypography.labelS.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: steps),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              Formatters.stepCount(v),
              style: AppTypography.titleM.copyWith(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared error state ────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Something went wrong.\nPlease restart the app.',
        textAlign: TextAlign.center,
        style: AppTypography.bodyM.copyWith(letterSpacing: 0),
      ),
    );
  }
}
