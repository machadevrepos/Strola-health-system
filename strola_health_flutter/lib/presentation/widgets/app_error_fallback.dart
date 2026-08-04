import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';

/// Replaces Flutter's default red-screen-of-death for any widget that
/// throws during build — installed once via `ErrorWidget.builder` in
/// `main()`. Renders wherever the broken widget would have (a single card,
/// a whole tab, occasionally a whole screen), so it's built to look right
/// at any size rather than assuming it owns the full screen.
class AppErrorFallback extends StatelessWidget {
  const AppErrorFallback({super.key, required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSurface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // A broken widget can be embedded anywhere a build can throw — a
          // full screen, or a small fixed-height slot (e.g. a session's
          // route map card). Never let this fallback itself overflow
          // whatever space it was given: show less content in a tight
          // slot, not more pixels than the parent has room for. The
          // SingleChildScrollView is a last-resort safety net on top of
          // that — harmless (no visible scrolling) whenever the compact
          // content already fits.
          final compact =
              constraints.maxHeight.isFinite && constraints.maxHeight < 160;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: compact ? 36 : 56,
                  height: compact ? 36 : 56,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.warning,
                    color: AppColors.error,
                    size: compact ? AppTheme.iconM : AppTheme.iconXL,
                  ),
                ),
                SizedBox(height: compact ? AppTheme.spaceXS : AppTheme.spaceM),
                Text(
                  'Something went wrong',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleS.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    "This part of the screen couldn't load. The rest of the "
                    'app is unaffected, try going back and returning to '
                    'this screen.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyS.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                // Debug builds only — the real exception, for whoever's
                // testing. Never shown to a real user in a release build.
                // Also skipped in a compact slot — there isn't room for it
                // without pushing the fallback itself into overflow.
                if (kDebugMode && !compact) ...[
                  const SizedBox(height: AppTheme.spaceM),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceS),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Text(
                      details.exceptionAsString(),
                      textAlign: TextAlign.left,
                      style: AppTypography.labelS.copyWith(
                        color: AppColors.error,
                        fontFeatures: const [],
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
