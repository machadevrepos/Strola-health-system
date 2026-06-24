import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/utils/haptics_helper.dart';
import 'package:strola_health/domain/entities/workout_session.dart';
import 'package:strola_health/presentation/providers/session_providers.dart';
import 'package:strola_health/presentation/providers/step_providers.dart';
import 'package:strola_health/presentation/screens/session_summary_screen.dart';
import 'package:strola_health/presentation/widgets/pressable_scale.dart';
import 'package:strola_health/presentation/widgets/route_map.dart';

// ── Entry point: fullscreen modal ─────────────────────────────────────────────

Future<void> openSessionScreen(BuildContext context) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      fullscreenDialog: true,
      opaque: true,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => const SessionScreen(),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
}

// ── Activity type icon mapping ────────────────────────────────────────────────

extension ActivityTypeUI on ActivityType {
  IconData get icon => switch (this) {
    ActivityType.outdoorWalk => AppIcons.walk,
    ActivityType.outdoorRun => AppIcons.run,
    ActivityType.treadmill => AppIcons.treadmill,
    ActivityType.strengthTraining => AppIcons.strength,
    ActivityType.yoga => AppIcons.yoga,
    ActivityType.pilates => AppIcons.pilates,
    ActivityType.cardio => AppIcons.heart,
    ActivityType.other => AppIcons.otherActivity,
  };
}

// ── Main session screen widget ────────────────────────────────────────────────

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  ActivityType _selectedType = ActivityType.outdoorWalk;
  bool _sessionStarted = false;

  @override
  void dispose() {
    final session = ref.read(sessionProvider);
    if (session.isRunning) {
      ref.read(sessionProvider.notifier).stop();
    }
    super.dispose();
  }

  Future<void> _startSession() async {
    // Request location from widget layer (OS dialog must appear here).
    if (_selectedType.usesGps) {
      await Permission.locationWhenInUse.request();
    }
    HapticsHelper.heavyImpact();
    await ref.read(sessionProvider.notifier).startSession(_selectedType);
    setState(() => _sessionStarted = true);
  }

  Future<void> _stopSession() async {
    HapticsHelper.mediumImpact();
    final session = await ref.read(sessionProvider.notifier).stop();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => SessionSummaryScreen(session: session),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final totalSteps = ref.watch(stepCountProvider);
    final dailyGoal = ref.watch(dailyGoalProvider);
    return _sessionStarted && session.isRunning
        ? _ActiveSessionView(
            session: session,
            totalSteps: totalSteps,
            dailyGoal: dailyGoal,
            onPause: () {
              HapticsHelper.lightImpact();
              ref.read(sessionProvider.notifier).pause();
            },
            onResume: () {
              HapticsHelper.lightImpact();
              ref.read(sessionProvider.notifier).resume();
            },
            onStop: _stopSession,
          )
        : _ActivityPickerView(
            selectedType: _selectedType,
            onTypeChanged: (t) => setState(() => _selectedType = t),
            onStart: _startSession,
            onClose: () => Navigator.of(context).pop(),
          );
  }
}

// ── Activity picker — 2-column grid ──────────────────────────────────────────

const _allActivities = ActivityType.values;

class _ActivityPickerView extends StatelessWidget {
  const _ActivityPickerView({
    required this.selectedType,
    required this.onTypeChanged,
    required this.onStart,
    required this.onClose,
  });

  final ActivityType selectedType;
  final ValueChanged<ActivityType> onTypeChanged;
  final VoidCallback onStart;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.bgGradient),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceXL,
                    AppTheme.spaceM,
                    AppTheme.spaceXL,
                    0,
                  ),
                  child: Row(
                    children: [
                      PressableScale(
                        onTap: onClose,
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
                            AppIcons.close,
                            color: AppColors.textSecondary,
                            size: AppTheme.iconM,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'New Activity',
                          textAlign: TextAlign.center,
                          style: AppTypography.titleM,
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ).animate().fadeIn(duration: AppTheme.animSlow),

                const SizedBox(height: AppTheme.spaceL),

                // ── Section label ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceXXL,
                  ),
                  child: Text(
                    'Choose activity',
                    style: AppTypography.labelS.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ).animate().fadeIn(delay: 80.ms, duration: AppTheme.animSlow),

                const SizedBox(height: AppTheme.spaceM),

                // ── Activity grid ──────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceL,
                    ),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppTheme.spaceM,
                            mainAxisSpacing: AppTheme.spaceM,
                            childAspectRatio: 1.45,
                          ),
                      itemCount: _allActivities.length,
                      itemBuilder: (_, i) {
                        final type = _allActivities[i];
                        final isSelected = type == selectedType;
                        return _ActivityTile(
                          type: type,
                          isSelected: isSelected,
                          index: i,
                          onTap: () => onTypeChanged(type),
                        );
                      },
                    ),
                  ),
                ),

                // ── GPS notice + Start button ──────────────────────────────
                Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spaceXL,
                        AppTheme.spaceS,
                        AppTheme.spaceXL,
                        0,
                      ),
                      child: Column(
                        children: [
                          if (selectedType.usesGps)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  AppIcons.gps,
                                  size: AppTheme.iconXS,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'GPS route tracking will activate automatically',
                                  style: AppTypography.labelS,
                                ),
                              ],
                            ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: onStart,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.spaceL,
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    selectedType.icon,
                                    size: AppTheme.iconM,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: AppTheme.spaceS),
                                  Text(
                                    'Start ${selectedType.displayName}',
                                    style: AppTypography.titleM.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceXXL),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: AppTheme.animSlow)
                    .slideY(begin: 0.15),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Individual activity tile ──────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.type,
    required this.isSelected,
    required this.index,
    required this.onTap,
  });

  final ActivityType type;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child:
          AnimatedContainer(
                duration: AppTheme.animFast,
                padding: const EdgeInsets.all(AppTheme.spaceL),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.5)
                        : AppColors.accentSecondary.withValues(alpha: 0.3),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(
                        alpha: isSelected ? 0.12 : 0.04,
                      ),
                      blurRadius: isSelected ? 14 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon circle
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.18)
                            : AppColors.accentSecondary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        type.icon,
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textMuted,
                        size: AppTheme.iconM,
                      ),
                    ),
                    const Spacer(),
                    // Activity name
                    Text(
                      type.displayName,
                      style: AppTypography.bodyS.copyWith(
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // GPS badge — outdoor walk/run only
                    if (type.usesGps)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXS,
                          ),
                        ),
                        child: Text(
                          'GPS',
                          style: AppTypography.labelS.copyWith(
                            color: AppColors.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              )
              .animate(delay: Duration(milliseconds: 100 + index * 60))
              .fadeIn(duration: AppTheme.animSlow)
              .slideY(begin: 0.12, curve: Curves.easeOut),
    );
  }
}

// ── Active session view ───────────────────────────────────────────────────────

class _ActiveSessionView extends StatelessWidget {
  const _ActiveSessionView({
    required this.session,
    required this.totalSteps,
    required this.dailyGoal,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final SessionState session;
  final int totalSteps;
  final int dailyGoal;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    final showMap = session.activityType.usesGps;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmStop(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.bgDeep,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Map background (only for GPS activities) ────────────────────
            if (showMap) _MapView(session: session),

            // Background gradient (replaces map for non-GPS activities)
            if (!showMap)
              Container(
                decoration: const BoxDecoration(gradient: AppColors.bgGradient),
              ),

            // Top gradient overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 220,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.bgDeep.withValues(alpha: 0.96),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 300,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.bgDeep.withValues(alpha: 0.98),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Content ─────────────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Top: status badge + activity type badge
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spaceXL,
                      AppTheme.spaceM,
                      AppTheme.spaceXL,
                      0,
                    ),
                    child: Row(
                      children: [
                        // Recording / Paused badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceM,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: session.isActive
                                ? AppColors.accent.withValues(alpha: 0.12)
                                : AppColors.accentSecondary.withValues(
                                    alpha: 0.2,
                                  ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: session.isActive
                                  ? AppColors.accent.withValues(alpha: 0.4)
                                  : AppColors.accentSecondary.withValues(
                                      alpha: 0.5,
                                    ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: session.isActive
                                          ? AppColors.accent
                                          : AppColors.accentSecondary,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                  .animate(
                                    onPlay: (c) =>
                                        session.isActive ? c.repeat() : null,
                                  )
                                  .fadeIn(duration: 600.ms)
                                  .then()
                                  .fadeOut(duration: 600.ms),
                              if (!session.isActive) ...[
                                const SizedBox(width: 6),
                                Text(
                                  'Paused',
                                  style: AppTypography.labelM.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Activity type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceM,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.accentSecondary.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                session.activityType.icon,
                                color: AppColors.accent,
                                size: AppTheme.iconXS,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                session.activityType.displayName,
                                style: AppTypography.labelM.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceXXL),

                  // Big timer
                  Text(
                    session.formattedElapsed,
                    style: AppTypography.displayXL.copyWith(
                      fontSize: 64,
                      letterSpacing: -3,
                    ),
                  ).animate().fadeIn(duration: AppTheme.animSlow),

                  const SizedBox(height: 6),

                  Text(
                    'ELAPSED TIME',
                    style: AppTypography.labelS.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceXL),

                  // Daily goal progress
                  Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceXL,
                        ),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.spaceL,
                            AppTheme.spaceM,
                            AppTheme.spaceL,
                            13,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.accentSecondary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _fmt(totalSteps),
                                    style: AppTypography.displayM.copyWith(
                                      color: AppColors.accent,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.2,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Text(
                                      'steps today',
                                      style: AppTypography.labelS.copyWith(
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Text(
                                      '${_fmt(dailyGoal)} goal',
                                      style: AppTypography.labelM.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 9),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value:
                                      (totalSteps / dailyGoal.clamp(1, 999999))
                                          .clamp(0.0, 1.0),
                                  backgroundColor: AppColors.accentSecondary
                                      .withValues(alpha: 0.2),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppColors.accent,
                                      ),
                                  minHeight: 5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 80.ms, duration: AppTheme.animSlow)
                      .slideY(begin: 0.08),

                  const Spacer(),

                  // Stats card — adapt columns based on activity type
                  Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceXL,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spaceXL,
                            horizontal: AppTheme.spaceL,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.accentSecondary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              if (session.activityType.countsSteps)
                                _StatItem(
                                  label: 'STEPS',
                                  value: _fmt(session.steps),
                                  color: AppColors.accent,
                                ),
                              if (session.activityType.countsSteps &&
                                  session.activityType.showsDistance)
                                _Divider(),
                              if (session.activityType.showsDistance)
                                _StatItem(
                                  label: 'DISTANCE',
                                  value: session.formattedDistance,
                                  color: AppColors.accent,
                                ),
                              if (session.activityType.usesGps) ...[
                                _Divider(),
                                _StatItem(
                                  label: 'PACE',
                                  value: session.formattedPace,
                                  color: AppColors.accent,
                                ),
                              ],
                              _Divider(),
                              _StatItem(
                                label: 'KCAL',
                                value: _estimatedKcal(session),
                                color: AppColors.accentSecondary,
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: AppTheme.animSlow)
                      .slideY(begin: 0.1),

                  const SizedBox(height: AppTheme.spaceXL),

                  // Controls
                  Padding(
                        padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ControlButton(
                              icon: AppIcons.controlStop,
                              color: AppColors.error,
                              size: 52,
                              onTap: () => _confirmStop(context),
                            ),
                            const SizedBox(width: AppTheme.spaceXXL),
                            _ControlButton(
                              icon: session.isActive
                                  ? AppIcons.controlPause
                                  : AppIcons.controlPlay,
                              color: AppColors.accent,
                              size: 72,
                              onTap: session.isActive ? onPause : onResume,
                              isPrimary: true,
                            ),
                            const SizedBox(width: AppTheme.spaceXXL),
                            const SizedBox(width: 52),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: AppTheme.animSlow)
                      .slideY(begin: 0.15),

                  const SizedBox(height: AppTheme.spaceXXXL),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Live calorie estimate during a session using MET × weight (default 65 kg).
  String _estimatedKcal(SessionState session) {
    // Reading userWeightKgProvider here would require ref; use provider default.
    // The actual final value is computed in stop() with the real persisted weight.
    const defaultWeight = 65.0;
    final hours = session.elapsed.inSeconds / 3600;
    final kcal = (session.activityType.met * defaultWeight * hours).toInt();
    return '$kcal';
  }

  void _confirmStop(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _StopDialog(onStop: onStop),
    );
  }
}

// ── Map view (GPS activities only) ───────────────────────────────────────────

class _MapView extends StatefulWidget {
  const _MapView({required this.session});

  final SessionState session;

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_MapView old) {
    super.didUpdateWidget(old);
    if (widget.session.currentLocation != null &&
        widget.session.currentLocation != old.session.currentLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _mapController.move(widget.session.currentLocation!, 16);
        } catch (_) {}
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final center =
        widget.session.currentLocation ?? const LatLng(51.5074, -0.1278);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 16,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.strola.health',
              retinaMode: true,
            ),
            if (widget.session.routePoints.length >= 2)
              PolylineLayer(
                polylines: buildRouteSpeedPolylines(widget.session.routePoints),
              ),
            if (widget.session.currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.session.currentLocation!,
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.6),
                            blurRadius: 14,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        Positioned(bottom: 16, left: 16, child: const RouteSpeedLegend()),
      ],
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.titleL.copyWith(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTypography.labelS.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.accentSecondary.withValues(alpha: 0.35),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPrimary ? color : color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: isPrimary ? 1 : 0.4),
            width: 1.5,
          ),
          boxShadow: isPrimary ? AppTheme.elevatedShadow : null,
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : color,
          size: size * 0.45,
        ),
      ),
    );
  }
}

// ── Stop confirmation dialog ──────────────────────────────────────────────────

class _StopDialog extends StatelessWidget {
  const _StopDialog({required this.onStop});

  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceXXL),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.accentSecondary.withValues(alpha: 0.3),
          ),
          boxShadow: AppTheme.elevatedShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.stop,
                color: AppColors.error,
                size: AppTheme.iconXL,
              ),
            ),
            const SizedBox(height: AppTheme.spaceL),
            Text(
              'End Session?',
              style: AppTypography.titleL.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppTheme.spaceS),
            Text(
              'Your progress will be saved to your workout log.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyS,
            ),
            const SizedBox(height: AppTheme.spaceXXL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(
                        color: AppColors.accentSecondary.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Keep Going'),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onStop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'End Session',
                      style: AppTypography.bodyL.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
