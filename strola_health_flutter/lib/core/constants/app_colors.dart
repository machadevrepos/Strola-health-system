import 'package:flutter/material.dart';

/// Strolla Health — canonical colour tokens (warm cream / mocha-rose palette).
///
/// Source of truth: the "CORE UI COLOURS" brief (2026-09-14). Every colour in
/// the app must come from here — never write a new `Color(0x...)` literal in
/// a widget. Tokens not covered by the brief (status colours, derived tints)
/// are called out below as such; flag them for design sign-off if they need
/// to change too.
class AppColors {
  AppColors._();

  // ── Background ────────────────────────────────────────────────────────────

  /// Main app background. Brief: "Main background".
  static const Color bgSurface = Color(0xFFFFFFFF);

  /// Card surfaces. Brief: "Card background". Distinct from [bgSurface] —
  /// use this for [FlatCard] and any other card-shaped surface, not white.
  static const Color bgCard = Color(0xFFFFFCFA);

  /// Card borders and the progress ring's unfilled track. Brief: "Card
  /// border" / "Incomplete progress ring" — the same warm cream tone covers
  /// both call-outs in the brief.
  static const Color cardBorder = Color(0xFFF3E9E5);

  /// NOT in the brief — kept as an alias of [cardBorder] so the many existing
  /// "blush tint / inactive border / icon bg" call sites (settings toggles,
  /// chip backgrounds, etc.) recolour for free. Prefer [cardBorder] in new
  /// code; this name is kept for the call sites that already reference it.
  static const Color accentSecondary = cardBorder;

  /// NOT in the brief. [bgGradient]'s deepest stop and the solid "fill"
  /// colour used by several text fields / decorative discs that need a tint
  /// visibly darker than [bgSurface]. Reuses [cardBorder] rather than
  /// inventing an unspecified hex.
  static const Color bgDeep = cardBorder;

  /// NOT in the brief. [bgGradient]'s middle stop — a hair off white so the
  /// gradient reads as "flat white" per the brief while still easing into
  /// [bgDeep] at the very edge. Flag for design review if an exact value
  /// matters here.
  static const Color bgMid = Color(0xFFFDFBFA);

  // ── Accent — mocha rose ───────────────────────────────────────────────────

  /// Brief: "Primary accent / Primary buttons / Active navigation-icons /
  /// Completed progress ring".
  static const Color accent = Color(0xFFC38381);
  static const Color accentGlow = Color(0x33C38381);

  /// NOT in the brief — a darker rose for the step ring's second-lap
  /// ("overflow") indicator, derived from [accent] by the same darkening
  /// the old palette applied to its accent. Flag for design sign-off.
  static const Color accentDeep = Color(0xFFA8585F);

  // ── Supporting brand colour — soft peach ─────────────────────────────────

  /// Brief: "Supporting brand colour — soft peach", used selectively.
  static const Color supporting = Color(0xFFD9B6A0);

  /// NOT explicitly in the brief — this is the old "goal hit" gold, repointed
  /// to [supporting] since the brief has no amber/gold in the core palette
  /// and calls the soft peach out as the one colour meant for exactly this
  /// kind of selective highlight (goal-reached states, trophies, achievement
  /// badges). Kept as its own name rather than renamed everywhere it's used.
  static const Color goalAmber = supporting;
  static const Color goalAmberGlow = Color(0x33D9B6A0);

  // ── Glass surfaces ────────────────────────────────────────────────────────

  static const Color glassWhite = Color(0xCCFFFFFF);
  static const Color glassBorder = Color(0x66F3E9E5);

  // ── Text ──────────────────────────────────────────────────────────────────

  /// Brief: "Primary text / headings", "Primary body text", "Numbers / key
  /// data" — all three map to this single token, same as before.
  static const Color textPrimary = Color(0xFF4B342C);

  /// Brief: "Secondary / less important text". A true brand colour now
  /// rather than an alpha of [textPrimary] — the brief gives it its own hex.
  static const Color textSecondary = Color(0xFF9C7063);

  /// NOT in the brief (no third text tier given). Derived as [textSecondary]
  /// at reduced alpha to keep the existing 3-tier hierarchy (labels/units
  /// need to sit visibly lighter than secondary body text). Flag if design
  /// wants a dedicated hex instead.
  static const Color textMuted = Color(0x999C7063); // textSecondary @ 60%

  // ── Status — NOT in the brief, left unchanged (functional, not brand) ────

  static const Color success = Color(0xFF55A56B);
  static const Color warning = Color(0xFFE9B44C);
  static const Color error = Color(0xFFE25858);
  static const Color bleConnected = Color(0xFF55A56B);
  static const Color bleScanning = Color(0xFFE9B44C);
  static const Color bleDisconnected = textMuted;

  // ── Gradients ─────────────────────────────────────────────────────────────

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgSurface, bgDeep, bgMid],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentSecondary],
  );

  /// NOT in the brief — second stop is a hand-derived deeper peach so the
  /// gradient still has direction rather than being one flat colour.
  static const LinearGradient goalGradient = LinearGradient(
    colors: [goalAmber, Color(0xFFC3A490)],
  );
}
