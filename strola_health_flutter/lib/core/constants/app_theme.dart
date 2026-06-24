import 'package:flutter/material.dart';

/// Strolla Health — spacing, sizing, shadow, and animation tokens.
///
/// Rules:
///   • All spacing, border radii, icon sizes, and shadow values must come from
///     here. Never hard-code a magic number in a widget.
///   • Shadow values use the coral accent at very low alpha so they feel warm,
///     not generic grey.
class AppTheme {
  AppTheme._();

  // ─────────────────────────────────────────────────────────────────────────
  // SPACING
  // Use these for padding, gaps, and margins — never raw numbers.
  // ─────────────────────────────────────────────────────────────────────────

  static const double spaceXS  = 4.0;
  static const double spaceS   = 8.0;
  static const double spaceM   = 12.0;
  static const double spaceL   = 16.0;
  static const double spaceXL  = 20.0;
  static const double spaceXXL = 24.0;
  static const double spaceXXXL = 32.0;

  /// Standard horizontal screen padding. All screens use this on left and right.
  static const double screenPaddingH = 24.0;

  /// Vertical gap between cards/sections on a scrollable screen.
  static const double sectionGap = 14.0;

  // ─────────────────────────────────────────────────────────────────────────
  // BORDER RADII
  // ─────────────────────────────────────────────────────────────────────────

  static const double radiusXS   = 6.0;   // small tags, badges
  static const double radiusS    = 10.0;  // chips, compact pill buttons
  static const double radiusM    = 14.0;  // buttons, small cards
  static const double radiusL    = 18.0;  // standard cards
  static const double radiusXL   = 22.0;  // large content cards
  static const double radiusSheet = 28.0; // bottom sheets, modals
  static const double radiusFull  = 999.0; // circular pills

  // ─────────────────────────────────────────────────────────────────────────
  // ICON SIZES
  // ─────────────────────────────────────────────────────────────────────────

  static const double iconXS  = 14.0; // inline text icons
  static const double iconS   = 16.0; // chip icons, small indicators
  static const double iconM   = 20.0; // nav bar, standard UI icons
  static const double iconL   = 24.0; // primary action icons
  static const double iconXL  = 28.0; // session / hero icons
  static const double iconXXL = 36.0; // step ring center icon

  // ─────────────────────────────────────────────────────────────────────────
  // NAVIGATION BAR
  // ─────────────────────────────────────────────────────────────────────────

  static const double navBarHeight  = 64.0;
  static const double navFabSize    = 52.0; // coral circle FAB diameter
  static const double navFabIconSize = 24.0;
  static const double navIconSize   = 22.0;
  static const double navLabelSize  = 10.0;

  // ─────────────────────────────────────────────────────────────────────────
  // SHADOWS
  // Warm coral-tinted shadows — consistent warmth across the app.
  // ─────────────────────────────────────────────────────────────────────────

  /// Flat card — very subtle lift, used on most content cards.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0AE07A7A), // accent at ~4 %
      blurRadius: 16,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  /// Elevated element — buttons, FABs, banners.
  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x1AE07A7A), // accent at ~10 %
      blurRadius: 24,
      spreadRadius: 0,
      offset: Offset(0, 6),
    ),
  ];

  /// Avatar / icon circle — soft glow for profile and status indicators.
  static const List<BoxShadow> glowShadow = [
    BoxShadow(
      color: Color(0x14E07A7A), // accent at ~8 %
      blurRadius: 12,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // ANIMATION DURATIONS
  // ─────────────────────────────────────────────────────────────────────────

  static const Duration animXS     = Duration(milliseconds: 150);
  static const Duration animFast   = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow   = Duration(milliseconds: 500);
  static const Duration animSpring = Duration(milliseconds: 700);
  static const Duration animCrawl  = Duration(milliseconds: 900);

  // ─────────────────────────────────────────────────────────────────────────
  // STEP RING
  // ─────────────────────────────────────────────────────────────────────────

  static const double stepRingSize     = 280.0;
  static const double stepRingThickness = 0.13; // as factor of radius

  // ─────────────────────────────────────────────────────────────────────────
  // STAT CHIP ICON CIRCLE
  // ─────────────────────────────────────────────────────────────────────────

  static const double statChipCircleSize = 44.0;
}
