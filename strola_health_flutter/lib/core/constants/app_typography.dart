import 'package:flutter/material.dart';
import 'package:strola_health/core/constants/app_colors.dart';

/// Strolla Health — canonical text styles.
///
/// Rules:
///   • Always reference these constants — never write an inline TextStyle.
///   • Colour overrides: use [TextStyle.copyWith] — never override via a
///     wrapping [DefaultTextStyle] except at screen root.
///   • Tabular figures are enabled on every Display style so step counters
///     never shift width as digits change.
///   • Line-height (height) is set on every style for cross-platform
///     consistency — never rely on the platform default.
class AppTypography {
  AppTypography._();

  // ─────────────────────────────────────────────────────────────────────────
  // DISPLAY — hero numbers only (step count, session distance, etc.)
  // Never use for body copy or titles.
  // ─────────────────────────────────────────────────────────────────────────

  /// 52 px · w800 · hero step counter, primary KPI number
  static const TextStyle displayXL = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 52,
    fontWeight: FontWeight.w800,
    letterSpacing: -2.0,
    height: 1.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// 36 px · w700 · session stats, large isolated metrics
  static const TextStyle displayL = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    height: 1.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// 28 px · w700 · card-level hero numbers (weekly total, challenge goal)
  static const TextStyle displayM = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // TITLE — screen headers, card section headers
  // ─────────────────────────────────────────────────────────────────────────

  /// 20 px · w600 · screen-level titles (e.g. "Workout Log")
  static const TextStyle titleL = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    height: 1.2,
  );

  /// 17 px · w600 · in-screen section headers, card titles
  static const TextStyle titleM = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.2,
  );

  /// 15 px · w600 · sub-section labels, card row headers
  static const TextStyle titleS = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // BODY — readable text content
  // ─────────────────────────────────────────────────────────────────────────

  /// 15 px · w500 · stat values, primary list item text
  static const TextStyle bodyL = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    height: 1.4,
  );

  /// 14 px · w400 · secondary body copy, descriptions
  static const TextStyle bodyM = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.0,
    height: 1.5,
  );

  /// 13 px · w400 · supporting text, timestamps, metadata
  static const TextStyle bodyS = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // LABEL — caps labels, chips, metadata tags
  // ─────────────────────────────────────────────────────────────────────────

  /// 12 px · w500 · secondary metadata, tag text
  static const TextStyle labelM = TextStyle(
    color: AppColors.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    height: 1.3,
  );

  /// 11 px · w500 · unit labels below stat values, muted caps
  static const TextStyle labelS = TextStyle(
    color: AppColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    height: 1.3,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // BRAND
  // ─────────────────────────────────────────────────────────────────────────

  /// 26 px · w800 · "strolla" wordmark in coral — app bar only
  static const TextStyle brand = TextStyle(
    color: AppColors.accent,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.0,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // MATERIAL TEXTTHEME MAPPING
  // Applied in main.dart via theme.textTheme.
  // Do not use these slots directly in widgets — use the named constants above.
  // ─────────────────────────────────────────────────────────────────────────

  static const TextTheme textTheme = TextTheme(
    displayLarge: displayXL, // 52/w800
    displayMedium: displayL, // 36/w700
    displaySmall: displayM, // 28/w700
    headlineLarge: titleL, // 20/w600
    headlineMedium: titleM, // 17/w600
    headlineSmall: titleS, // 15/w600
    titleLarge: titleM, // 17/w600 (Material nav/dialog title)
    titleMedium: bodyL, // 15/w500
    titleSmall: bodyM, // 14/w400
    bodyLarge: bodyL, // 15/w500
    bodyMedium: bodyM, // 14/w400
    bodySmall: bodyS, // 13/w400
    labelLarge: labelM, // 12/w500
    labelMedium: labelS, // 11/w500
    labelSmall: labelS, // 11/w500
  );
}
