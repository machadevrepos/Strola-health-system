import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
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
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.glowShadow,
                ),
                child: const Icon(
                  AppIcons.start,
                  color: AppColors.accent,
                  size: AppTheme.iconXXL,
                ),
              ).animate().scale(
                begin: const Offset(0.85, 0.85),
                curve: Curves.easeOutBack,
                duration: AppTheme.animSpring,
              ),
              const SizedBox(height: AppTheme.spaceXL),
              Text(
                'strolla',
                style: AppTypography.brand.copyWith(fontSize: 34),
              ).animate().fadeIn(delay: 150.ms, duration: AppTheme.animSlow),
              const SizedBox(height: AppTheme.spaceS),
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
