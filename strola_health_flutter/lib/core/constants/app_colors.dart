import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Background ────────────────────────────────────────────────────────────
  static const Color bgDeep = Color(0xFFFFF2F2);
  static const Color bgMid = Color(0xFFFFF7F7);
  static const Color bgSurface = Color(0xFFFFFFFF);

  // ── Accent — coral / rose ─────────────────────────────────────────────────
  static const Color accent = Color(0xFFE07A7A);
  static const Color accentGlow = Color(0x33E07A7A);
  static const Color accentSecondary = Color(0xFFF6B1B1); // soft blush

  // ── Goal hit — warm amber ─────────────────────────────────────────────────
  static const Color goalAmber = Color(0xFFE9B44C);
  static const Color goalAmberGlow = Color(0x33E9B44C);

  // ── Glass surfaces ────────────────────────────────────────────────────────
  static const Color glassWhite = Color(0xCCFFFFFF);
  static const Color glassBorder = Color(0x66F6B1B1);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xB3333333);
  static const Color textMuted = Color(0x66333333);

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF55A56B);
  static const Color warning = Color(0xFFE9B44C);
  static const Color error = Color(0xFFE25858);
  static const Color bleConnected = Color(0xFF55A56B);
  static const Color bleScanning = Color(0xFFE9B44C);
  static const Color bleDisconnected = Color(0x66333333);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgSurface, bgDeep, bgMid],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentSecondary],
  );

  static const LinearGradient goalGradient = LinearGradient(
    colors: [goalAmber, Color(0xFFE8A23A)],
  );
}
