import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/presentation/providers/navigation_providers.dart';
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

class _MainShellState extends ConsumerState<MainShell> {
  // 4 real screens; nav index 2 (Start Workout) opens a modal instead
  static const _screens = [
    HomeScreen(),
    StatsScreen(),
    CommunityScreen(),
    ChallengesScreen(),
  ];

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

    return Scaffold(
      extendBody: true,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV BAR
// White surface · warm coral shadow upward · 5-item layout with center FAB
// ─────────────────────────────────────────────────────────────────────────────

class _StrollaNavBar extends StatelessWidget {
  const _StrollaNavBar({
    required this.currentIndex,
    required this.onTap,
  });

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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The FAB circle sits above the nav bar baseline
            Transform.translate(
              offset: const Offset(0, -10),
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
            // Label sits at nav bar text baseline — pulled up with the transform
            Transform.translate(
              offset: const Offset(0, -8),
              child: Text(
                'Start Workout',
                style: AppTypography.labelS.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
