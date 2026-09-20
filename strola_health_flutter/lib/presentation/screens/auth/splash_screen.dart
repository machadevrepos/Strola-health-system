import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';

/// Shown while Firebase resolves the cached session and local prefs load —
/// purely presentational, the root gate decides when to swap away from it.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Real brand lockup asset rather than an icon + text
              // approximation of the wordmark.
              Image.asset(
                'assets/images/branding/strolla_logo.png',
                width: 220,
              ).animate().scale(
                begin: const Offset(0.85, 0.85),
                curve: Curves.easeOutBack,
                duration: AppTheme.animSpring,
              ).fadeIn(duration: AppTheme.animSlow),
              const SizedBox(height: AppTheme.spaceL),
              Text(
                'Every Step Counts',
                style: AppTypography.bodyM.copyWith(
                  color: AppColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 250.ms, duration: AppTheme.animSlow),
            ],
          ),
        ),
      ),
    );
  }
}
