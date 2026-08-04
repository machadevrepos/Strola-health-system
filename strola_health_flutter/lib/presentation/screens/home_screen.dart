import 'dart:io';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/haptics_helper.dart';
import 'package:strola_health/core/utils/rolling_week.dart';
import 'package:strola_health/core/utils/streak.dart';
import 'package:strola_health/domain/entities/user_profile.dart';
import 'package:strola_health/presentation/providers/ble_providers.dart';
import 'package:strola_health/presentation/providers/navigation_providers.dart';
import 'package:strola_health/presentation/providers/notification_providers.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';
import 'package:strola_health/presentation/providers/session_providers.dart';
import 'package:strola_health/presentation/providers/step_providers.dart';
import 'package:strola_health/presentation/providers/widget_prompt_providers.dart';
import 'package:strola_health/presentation/screens/notifications_screen.dart';
import 'package:strola_health/presentation/screens/profile_screen.dart';
import 'package:strola_health/presentation/screens/share_steps_screen.dart';
import 'package:strola_health/presentation/widgets/add_widget_sheet.dart';
import 'package:strola_health/presentation/widgets/announcement_banner.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';
import 'package:strola_health/presentation/widgets/goal_settings_sheet.dart';
import 'package:strola_health/presentation/widgets/hourly_chart.dart';
import 'package:strola_health/presentation/widgets/pressable_scale.dart';
import 'package:strola_health/presentation/widgets/step_ring.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final ConfettiController _confettiController;
  bool _goalCelebrated = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    // Deferred a frame — showing a sheet during initState (before the first
    // build completes) has no valid Navigator/Overlay to attach to yet.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeShowWidgetPrompt(),
    );
  }

  Future<void> _maybeShowWidgetPrompt() async {
    if (!mounted) return;
    if (ref.read(hasSeenWidgetPromptProvider)) return;
    await ref.read(hasSeenWidgetPromptProvider.notifier).markSeen();
    if (mounted) await showAddWidgetSheet(context);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _checkGoalCelebration(bool goalReached) {
    if (goalReached && !_goalCelebrated) {
      _goalCelebrated = true;
      _confettiController.play();
      HapticsHelper.goalReached();
    } else if (!goalReached) {
      _goalCelebrated = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = ref.watch(stepCountProvider);
    final goal = ref.watch(dailyGoalProvider);
    final weeklySteps = ref.watch(weeklyStepsProvider);
    final hourlySteps = ref.watch(todayHourlyStepsProvider);
    final goalReached = ref.watch(goalReachedProvider);

    _checkGoalCelebration(goalReached);

    // ── Computed stats — personalized by the user's profile ───────────────────
    final calories = ref.watch(caloriesProvider);
    final distKm = ref.watch(distanceKmProvider);
    final units = ref.watch(userProfileProvider).units;

    // Real, not mock — batteryLevelProvider is a deliberate stub (null)
    // until the firmware exposes a real battery characteristic to parse, so
    // this always reads as "no reading available" today. Distinct from "not
    // connected" regardless: a real device could in principle be connected
    // with the battery simply not known yet, so the label reflects BLE
    // connection state and the value reflects whether a reading exists.
    final batteryLevel = ref.watch(batteryLevelProvider);
    final isBleConnected = ref.watch(bleStatusProvider) == BleStatus.connected;
    final hasBatteryReading = isBleConnected && batteryLevel != null;

    final String distanceStr;
    final String distanceUnit;
    if (units == UnitSystem.imperial) {
      distanceStr = (distKm * 0.621371).toStringAsFixed(2);
      distanceUnit = 'mi';
    } else if (distKm >= 1) {
      distanceStr = distKm.toStringAsFixed(1);
      distanceUnit = 'km';
    } else {
      distanceStr = (distKm * 1000).round().toString();
      distanceUnit = 'm';
    }

    final streak = calcStreak(weeklySteps, goal);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── App bar — static, never scrolls (matches Stats/Community/
            // Challenges, which all keep their header pinned) ─────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.screenPaddingH,
                AppTheme.spaceL,
                AppTheme.screenPaddingH,
                0,
              ),
              child: _AppBar(),
            ).animate().fadeIn(delay: 50.ms),

            const SizedBox(height: AppTheme.sectionGap),

            Expanded(
              child: Stack(
                children: [
                  CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppTheme.spaceS),
                          child: const AnnouncementBanner(),
                        ),
                      ),

                      // ── 2. Step ring — tap to adjust the daily goal ────────────────
                      SliverToBoxAdapter(
                        child:
                            Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppTheme.spaceXL,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticsHelper.lightImpact();
                                      showGoalSheet(context);
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Center(
                                      child: StepRing(steps: steps, goal: goal),
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 150.ms)
                                .scale(
                                  begin: const Offset(0.92, 0.92),
                                  curve: Curves.easeOutBack,
                                  duration: 650.ms,
                                ),
                      ),

                      // ── 3. Stat cards — Distance | Active Calories | Battery ───────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.screenPaddingH,
                            AppTheme.sectionGap,
                            AppTheme.screenPaddingH,
                            0,
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    icon: AppIcons.location,
                                    iconColor: AppColors.accent,
                                    value: distanceStr,
                                    unit: distanceUnit,
                                    label: 'Distance',
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceS),
                                Expanded(
                                  child: _StatCard(
                                    icon: AppIcons.calories,
                                    iconColor: AppColors.accent,
                                    value: '$calories',
                                    label: 'Active Calories',
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceS),
                                Expanded(
                                  child: _StatCard(
                                    icon: AppIcons.battery,
                                    iconColor: hasBatteryReading
                                        ? AppColors.success
                                        : AppColors.bleDisconnected,
                                    value: hasBatteryReading
                                        ? '$batteryLevel%'
                                        : '—',
                                    label: isBleConnected
                                        ? 'Battery'
                                        : 'Not Connected',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.10),
                      ),

                      // ── 4. Streak card — tap to view stats ──────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.screenPaddingH,
                            AppTheme.sectionGap,
                            AppTheme.screenPaddingH,
                            0,
                          ),
                          child: PressableScale(
                            onTap: () {
                              HapticsHelper.lightImpact();
                              ref.read(mainTabIndexProvider.notifier).state = 1;
                            },
                            behavior: HitTestBehavior.opaque,
                            child: FlatCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spaceL,
                                vertical: AppTheme.spaceM + 2,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Flame circle
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withValues(
                                            alpha: 0.10,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          AppIcons.streak,
                                          color: AppColors.accent,
                                          size: AppTheme.iconL,
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.spaceM),
                                      // Streak text
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                TweenAnimationBuilder<int>(
                                                  tween: IntTween(
                                                    begin: 0,
                                                    end: streak,
                                                  ),
                                                  duration: AppTheme.animSpring,
                                                  builder: (_, v, __) => Text(
                                                    '$v',
                                                    style: AppTypography.titleM
                                                        .copyWith(
                                                          color:
                                                              AppColors.accent,
                                                          fontSize: 20,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: AppTheme.spaceXS,
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    'Day Streak',
                                                    style: AppTypography.titleS,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Keep it going! 🔥',
                                              style: AppTypography.labelS,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        AppIcons.chevronRight,
                                        color: AppColors.textMuted,
                                        size: AppTheme.iconM,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spaceM),
                                  // MTWTFSS dots — full width
                                  _WeekDots(
                                    weeklySteps: weeklySteps,
                                    goal: goal,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 390.ms).slideY(begin: 0.10),
                      ),

                      // ── 5. Share Your Steps banner ─────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.screenPaddingH,
                            AppTheme.sectionGap,
                            AppTheme.screenPaddingH,
                            0,
                          ),
                          child: PressableScale(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ShareStepsScreen(),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spaceXL,
                                vertical: AppTheme.spaceL,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.accent,
                                    AppColors.accentSecondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusL,
                                ),
                                boxShadow: AppTheme.elevatedShadow,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.22,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      AppIcons.share,
                                      color: Colors.white,
                                      size: AppTheme.iconM,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spaceL),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Share Your Steps',
                                          style: AppTypography.titleS.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Inspire others on their journey',
                                          style: AppTypography.bodyS.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.75,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    AppIcons.chevronRight,
                                    color: Colors.white.withValues(alpha: 0.70),
                                    size: AppTheme.iconM,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.08),
                      ),

                      // ── 6. Today's Progress (hourly chart) ─────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.screenPaddingH,
                            AppTheme.sectionGap,
                            AppTheme.screenPaddingH,
                            0,
                          ),
                          child: FlatCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Today's Progress",
                                      style: AppTypography.titleS,
                                    ),
                                    const Spacer(),
                                    PressableScale(
                                      onTap: () {
                                        HapticsHelper.lightImpact();
                                        ref
                                                .read(
                                                  mainTabIndexProvider.notifier,
                                                )
                                                .state =
                                            1;
                                      },
                                      child: Text(
                                        'View Stats',
                                        style: AppTypography.labelM.copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spaceL),
                                SizedBox(
                                  height: 160,
                                  child: HourlyChart(hourlySteps: hourlySteps),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 510.ms).slideY(begin: 0.10),
                      ),

                      // Comfortable breathing room at the end of the scroll —
                      // MainShell's Scaffold already reserves space for the
                      // nav bar itself, so this is just visual padding, not a
                      // clearance guess.
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppTheme.sectionGap),
                      ),
                    ],
                  ),

                  // ── Confetti ───────────────────────────────────────────────
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      numberOfParticles: 40,
                      gravity: 0.30,
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
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _AppBar extends ConsumerWidget {
  const _AppBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoPath = ref.watch(userProfileProvider).photoPath;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Brand wordmark + date
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('strolla', style: AppTypography.brand),
            const SizedBox(height: 1),
            Text(_dateLabel(), style: AppTypography.labelS),
          ],
        ),

        const Spacer(),

        // Notification bell with badge
        PressableScale(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.glowShadow,
                ),
                child: Icon(
                  AppIcons.notifications,
                  color: AppColors.textSecondary,
                  size: AppTheme.iconM,
                ),
              ),
              // Unread badge dot
              if (ref.watch(unreadNotificationCountProvider) > 0)
                Positioned(
                  top: 8,
                  right: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(width: AppTheme.spaceM - 2),

        // Profile avatar
        PressableScale(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentSecondary.withValues(alpha: 0.22),
              border: Border.all(
                color: AppColors.accentSecondary.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: AppTheme.glowShadow,
              image: photoPath != null
                  ? DecorationImage(
                      image: FileImage(File(photoPath)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photoPath == null
                ? Icon(
                    AppIcons.profile,
                    color: AppColors.accent,
                    size: AppTheme.iconM,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  String _dateLabel() {
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
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CARD — one of three side-by-side cards below the ring
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.unit = '',
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return FlatCard(
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.spaceL,
        horizontal: AppTheme.spaceXS,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: AppTheme.iconL),
          const SizedBox(height: AppTheme.spaceS),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppTheme.animSpring,
            builder: (_, t, __) => Text(
              value,
              style: AppTypography.displayM.copyWith(fontSize: 22),
            ),
          ),
          if (unit.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(unit, style: AppTypography.labelS),
          ],
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            label,
            style: AppTypography.labelS,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WEEK DOTS — compact M T W T F S S row for the streak card
// ─────────────────────────────────────────────────────────────────────────────

class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.weeklySteps, required this.goal});

  final List<int> weeklySteps;
  final int goal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        final letter = RollingWeek.letterForIndex(i, 7);
        final met = weeklySteps[i] >= goal;
        final isToday = i == 6;

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppTheme.animNormal,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: met
                      ? AppColors.accent
                      : AppColors.accentSecondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isToday && !met
                        ? AppColors.accent
                        : met
                        ? AppColors.accent
                        : AppColors.accentSecondary.withValues(alpha: 0.30),
                    width: 1.5,
                  ),
                ),
                child: met
                    ? const Icon(AppIcons.check, color: Colors.white, size: 11)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                letter,
                style: AppTypography.labelS.copyWith(
                  color: isToday ? AppColors.accent : AppColors.textMuted,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
