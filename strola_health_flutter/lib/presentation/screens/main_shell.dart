import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/services/push_token_service.dart';
import 'package:strola_health/core/utils/formatters.dart';
import 'package:strola_health/data/datasources/backend_api.dart';
import 'package:strola_health/data/repositories/device_repository.dart';
import 'package:strola_health/domain/entities/app_notification.dart';
import 'package:strola_health/domain/entities/challenge.dart';
import 'package:strola_health/presentation/providers/auth_providers.dart';
import 'package:strola_health/presentation/providers/ble_providers.dart';
import 'package:strola_health/presentation/providers/challenge_providers.dart';
import 'package:strola_health/presentation/providers/navigation_providers.dart';
import 'package:strola_health/presentation/providers/notification_providers.dart';
import 'package:strola_health/presentation/providers/step_providers.dart';
import 'package:strola_health/presentation/screens/challenge_of_the_month_screen.dart';
import 'package:strola_health/presentation/screens/challenges_screen.dart';
import 'package:strola_health/presentation/screens/community_screen.dart';
import 'package:strola_health/presentation/screens/home_screen.dart';
import 'package:strola_health/presentation/screens/session_screen.dart';
import 'package:strola_health/presentation/screens/stats_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  // 4 real screens; nav index 2 (Start Workout) opens a modal instead
  static const _screens = [
    HomeScreen(),
    StatsScreen(),
    CommunityScreen(),
    ChallengesScreen(),
  ];

  Timer? _dailyActivitySyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // MainShell only ever mounts once a user is fully signed in and
    // onboarded, so this is the one place a push token needs registering —
    // fires once per app session, not on every rebuild (unlike the
    // notification detectors below, which need to re-run on every build to
    // pick up ref changes).
    if (ref.read(firebaseAvailableProvider)) {
      PushTokenService.register();
    }
    _maybeAutoConnectBle();
    // Periodic while the app is open, plus an immediate one on backgrounding
    // below — keeps `stats.streak_current` (admin panel's user detail page)
    // reasonably live for a BLE-only user without a write on every single
    // step update, which the BLE stream fires far too often for.
    _dailyActivitySyncTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _syncDailyActivity(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dailyActivitySyncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Covers both a cold launch (initState, above) and coming back to the
    // foreground — the OS is free to tear a BLE connection down while the
    // app is backgrounded/suspended, so returning to it is exactly when a
    // stale "disconnected" needs a fresh attempt, not just a first launch.
    if (state == AppLifecycleState.resumed) {
      _maybeAutoConnectBle();
    }
    // Backgrounding is a natural "finalize what's been tracked so far"
    // moment — syncs immediately rather than waiting out the rest of the
    // 15-minute timer.
    if (state == AppLifecycleState.paused) {
      _syncDailyActivity();
    }
  }

  /// Pushes today's running BLE total to `dailyActivity` (via
  /// ingestDeviceSteps) so the server-computed streak/lifetime stats the
  /// admin panel reads stay current. Best-effort and silent on failure —
  /// same as `pushLiveSteps` — a flaky network shouldn't ever surface as an
  /// error in the app shell.
  Future<void> _syncDailyActivity() async {
    if (!ref.read(firebaseAvailableProvider)) return;
    try {
      final steps = ref.read(stepCountProvider);
      await ref
          .read(backendApiProvider)
          .ingestDeviceSteps(
            date: DateTime.now(),
            steps: steps,
            distanceMeters: ref.read(distanceKmProvider) * 1000,
            calories: ref.read(caloriesProvider),
          );
    } catch (e, st) {
      debugPrint('[MainShell] daily activity sync failed: $e\n$st');
    }
  }

  /// If this account has a paired device and BLE isn't already
  /// connected/scanning, (re)start the connection. `connect()` is always
  /// safe to call speculatively — permission_handler no-ops on an
  /// already-answered prompt rather than re-showing it, and BleStepService
  /// itself no-ops if a connection attempt is already active.
  Future<void> _maybeAutoConnectBle() async {
    if (!ref.read(firebaseAvailableProvider)) return;
    if (ref.read(bleStatusProvider) != BleStatus.disconnected) return;
    try {
      final device = await ref.read(myDeviceProvider.future);
      if (device != null && mounted) {
        ref.read(bleStatusProvider.notifier).connect();
      }
    } catch (_) {
      // Best-effort — no paired-device lookup should ever block the app
      // shell from rendering.
    }
  }

  /// A local-feed entry (so it's not just a popup that vanishes — it's
  /// revisitable in the notification list, same as every other real
  /// notification) plus the blocking popup itself. Deferred a frame so
  /// `showDialog` never races the build this listener fired from.
  void _announceNewOfficialChallenge(Challenge challenge) {
    ref
        .read(notificationsProvider.notifier)
        .add(
          AppNotification(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            category: NotificationCategory.challenge,
            title: 'New challenge!',
            body: '"${challenge.title}" is this month\'s official challenge.',
            timestamp: DateTime.now(),
            routeTarget: 'challenge',
          ),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => _NewOfficialChallengeDialog(challenge: challenge),
      );
    });
  }

  void _onNavTap(int navIndex) {
    if (navIndex == 2) {
      openSessionScreen(context);
      return;
    }
    // Nav indices 0,1 → screen indices 0,1
    // Nav indices 3,4 → screen indices 2,3 (skip the FAB slot)
    final screenIndex = navIndex < 2 ? navIndex : navIndex - 1;
    ref.read(mainTabIndexProvider.notifier).state = screenIndex;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainTabIndexProvider);

    // MainShell is always mounted regardless of active tab, so this is the
    // one place notification detectors can live and fire app-wide.
    registerNotificationDetectors(ref);

    // Same reasoning — the one place that can pop up a modal no matter which
    // tab or pushed screen the user is actually on. Guarded so this only
    // fires when the official challenge actually changes identity while the
    // app is already running, not on the cold-start load — but "cold start"
    // means `previous` is still loading, NOT "previous resolved to null".
    // Going from *no* official challenge to a real one is exactly the event
    // this should announce, and that transition's `previous` is a loaded
    // AsyncData wrapping a null value, not AsyncLoading — checking
    // `previous.value == null` instead of `previous.isLoading` would (and
    // did) silently swallow that exact case.
    ref.listen<AsyncValue<Challenge?>>(officialChallengeProvider, (
      previous,
      next,
    ) {
      if (previous == null || previous.isLoading) return;
      final now = next.value;
      if (now == null) return;
      if (previous.value?.id == now.id) return;
      _announceNewOfficialChallenge(now);
    });

    return Scaffold(
      // Was `extendBody: true`, which makes the body draw full-height behind
      // the (opaque) nav bar instead of Flutter reserving space for it — every
      // tab then had to guess that reserved amount itself (Challenges'
      // navClearance, Home's and Community's hardcoded SizedBox spacers), and
      // those guesses kept drifting from the bar's real height. False is the
      // Scaffold default and makes Flutter size the body correctly for every
      // tab automatically, with nothing to keep in sync by hand.
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: AnimatedSwitcher(
          duration: AppTheme.animNormal,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(currentIndex),
            child: _screens[currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: _StrollaNavBar(
        currentIndex: currentIndex,
        onTap: _onNavTap,
      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.25),
      // Owned here (not by ChallengesScreen) so Flutter positions it above
      // _StrollaNavBar automatically — a FAB nested inside a screen with no
      // bottomNavigationBar of its own has nothing to auto-position against.
      floatingActionButton: currentIndex == 3
          ? FloatingActionButton(
              mini: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CreateChallengeScreen(),
                ),
              ),
              backgroundColor: AppColors.accent,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(
                AppIcons.add,
                color: Colors.white,
                size: AppTheme.iconL,
              ),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV BAR
// White surface · warm coral shadow upward · 5-item layout with center FAB
// ─────────────────────────────────────────────────────────────────────────────

class _StrollaNavBar extends StatelessWidget {
  const _StrollaNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SizedBox(
          height: AppTheme.navBarHeight,
          child: Padding(
            // Each item is `Expanded`, so this is what actually controls
            // the gap between icons — without it the Row spans the full
            // bar edge-to-edge and 5 equal flex slots leaves a lot of
            // empty space around Home/Stats' short labels specifically.
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _NavItem(
                  icon: AppIcons.home,
                  label: 'Home',
                  isActive: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: AppIcons.stats,
                  label: 'Stats',
                  isActive: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                _StartWorkoutFab(onTap: () => onTap(2)),
                _NavItem(
                  icon: AppIcons.community,
                  label: 'Community',
                  isActive: currentIndex == 2,
                  onTap: () => onTap(3),
                ),
                _NavItem(
                  icon: AppIcons.challenge,
                  label: 'Challenges',
                  isActive: currentIndex == 3,
                  onTap: () => onTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NAV ITEM — icon + label, animates between active / inactive states
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: AppTheme.animFast,
              child: Icon(
                icon,
                key: ValueKey(isActive),
                color: isActive ? AppColors.accent : AppColors.textMuted,
                size: AppTheme.navIconSize,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: AppTheme.animFast,
              style: AppTypography.labelS.copyWith(
                color: isActive ? AppColors.accent : AppColors.textMuted,
                fontSize: AppTheme.navLabelSize,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.1,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CENTER FAB — "Start Workout" coral circle raised above the nav bar
// ─────────────────────────────────────────────────────────────────────────────

class _StartWorkoutFab extends StatelessWidget {
  const _StartWorkoutFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Same Expanded + icon-slot-then-label Column shape as _NavItem, so this
    // item's label sits on exactly the same baseline as Home/Stats/
    // Community/Challenges instead of being independently positioned and
    // drifting out of alignment with them.
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: AppTheme.navIconSize,
              // The circle is deliberately bigger than a normal icon slot —
              // OverflowBox lets it render at full size without inflating
              // the slot itself (which would push the label down and out
              // of alignment with the other four items). bottomCenter
              // anchors the circle's bottom edge to the slot's bottom edge
              // (same baseline every other icon sits on), so the excess
              // height (navFabSize - navIconSize) overflows upward only —
              // most of the circle stays within the bar, just its top
              // portion pokes above, not an even 50/50 split.
              child: OverflowBox(
                maxWidth: AppTheme.navFabSize,
                maxHeight: AppTheme.navFabSize,
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: AppTheme.navFabSize,
                  height: AppTheme.navFabSize,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.40),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    AppIcons.start,
                    color: Colors.white,
                    size: AppTheme.navFabIconSize,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Start Workout',
              style: AppTypography.labelS.copyWith(
                color: AppColors.textMuted,
                fontSize: AppTheme.navLabelSize,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEW OFFICIAL CHALLENGE POPUP — shown app-wide the moment one goes live
// ─────────────────────────────────────────────────────────────────────────────

class _NewOfficialChallengeDialog extends StatefulWidget {
  const _NewOfficialChallengeDialog({required this.challenge});

  final Challenge challenge;

  @override
  State<_NewOfficialChallengeDialog> createState() =>
      _NewOfficialChallengeDialogState();
}

class _NewOfficialChallengeDialogState
    extends State<_NewOfficialChallengeDialog> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    // A frame late so the burst starts once the card's own entrance
    // animation is actually on screen, not before the dialog route settles.
    WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
                margin: const EdgeInsets.only(top: 36),
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceXL,
                  56,
                  AppTheme.spaceXL,
                  AppTheme.spaceXL,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSheet),
                  boxShadow: AppTheme.elevatedShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceM,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.accentSecondary],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        'NEW OFFICIAL CHALLENGE',
                        style: AppTypography.labelS.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Text(
                      challenge.title,
                      textAlign: TextAlign.center,
                      style: AppTypography.displayM.copyWith(fontSize: 24),
                    ),
                    if (challenge.description.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spaceS),
                      Text(
                        challenge.description,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyM.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spaceL),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceM,
                        vertical: AppTheme.spaceS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentSecondary.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            AppIcons.goal,
                            color: AppColors.accent,
                            size: AppTheme.iconS,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${Formatters.stepCount(challenge.goalSteps)} steps · '
                              '${Formatters.fullDate(challenge.startDate)} - '
                              '${Formatters.fullDate(challenge.endDate)}',
                              style: AppTypography.labelM.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXL),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.accentSecondary,
                              AppColors.accent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ChallengeOfTheMonthScreen(),
                                ),
                              );
                            },
                            child: Center(
                              child: Text(
                                'View Challenge',
                                style: AppTypography.titleS.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXS),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Maybe Later',
                        style: AppTypography.bodyM.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: AppTheme.animNormal)
              .scale(
                begin: const Offset(0.8, 0.8),
                curve: Curves.easeOutBack,
                duration: AppTheme.animSpring,
              ),

          // Badge — trophy in a glowing gradient ring, overlapping the top
          // edge of the card (the "seal" a real achievement popup wears).
          Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.accentSecondary, AppColors.accent],
                  ),
                  border: Border.all(color: AppColors.bgSurface, width: 5),
                  boxShadow: AppTheme.glowShadow,
                ),
                child: Center(
                  child: Text(
                    challenge.badgeEmoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: AppTheme.animNormal)
              .scale(
                begin: const Offset(0.4, 0.4),
                curve: Curves.easeOutBack,
                duration: AppTheme.animSpring,
                delay: 80.ms,
              ),

          // Confetti burst — same palette/config as the goal-reached
          // celebration on Home (home_screen.dart), reused here rather than
          // a new one-off, so the app has one consistent "you did it" motif.
          Positioned(
            top: -20,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 28,
              gravity: 0.25,
              colors: const [
                AppColors.accent,
                AppColors.accentSecondary,
                AppColors.goalAmber,
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
