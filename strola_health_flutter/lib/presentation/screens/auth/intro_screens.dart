import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/presentation/providers/auth_providers.dart';

class _IntroSlide {
  const _IntroSlide({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}

const _slides = [
  _IntroSlide(
    icon: AppIcons.steps,
    title: 'Track Every Step',
    body: 'Pair with your Strolla device for accurate, real-time step '
        "tracking — or just carry your phone, we've got you either way.",
  ),
  _IntroSlide(
    icon: AppIcons.people,
    title: 'Move Together',
    body: 'Join a community of women cheering each other on, sharing '
        'wins, and joining challenges together.',
  ),
  _IntroSlide(
    icon: AppIcons.trophy,
    title: 'Reach Your Goals',
    body: 'Set a daily step goal, build streaks, and celebrate every '
        'milestone — big or small.',
  ),
];

/// 3-page welcome carousel shown once, before the auth screens.
class IntroScreens extends ConsumerStatefulWidget {
  const IntroScreens({super.key});

  @override
  ConsumerState<IntroScreens> createState() => _IntroScreensState();
}

class _IntroScreensState extends ConsumerState<IntroScreens> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => ref.read(hasSeenIntroProvider.notifier).markSeen();

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: AppTheme.animNormal,
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    AppTheme.spaceM,
                    AppTheme.screenPaddingH,
                    0,
                  ),
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: AppTypography.bodyM.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _slides.length,
                  itemBuilder: (context, i) {
                    final slide = _slides[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.screenPaddingH,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.accentSecondary.withValues(alpha: 0.20),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              slide.icon,
                              color: AppColors.accent,
                              size: AppTheme.iconXXL,
                            ),
                          ).animate().fadeIn(duration: AppTheme.animSlow).scale(
                                begin: const Offset(0.85, 0.85),
                                curve: Curves.easeOutBack,
                              ),
                          const SizedBox(height: AppTheme.spaceXXL),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: AppTypography.titleL.copyWith(fontSize: 24),
                          ).animate().fadeIn(delay: 80.ms, duration: AppTheme.animSlow),
                          const SizedBox(height: AppTheme.spaceM),
                          Text(
                            slide.body,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyM.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ).animate().fadeIn(delay: 140.ms, duration: AppTheme.animSlow),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: AppTheme.animFast,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppColors.accent
                            : AppColors.accentSecondary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenPaddingH,
                  AppTheme.spaceXL,
                  AppTheme.screenPaddingH,
                  AppTheme.spaceXXL,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceL),
                    ),
                    child: Text(
                      _page == _slides.length - 1 ? 'Get Started' : 'Next',
                      style: AppTypography.titleS.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
