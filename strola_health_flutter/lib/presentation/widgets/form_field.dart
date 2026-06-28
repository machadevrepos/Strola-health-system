import 'package:flutter/material.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';

/// Filled + outlined text field with a floating label — Flutter's native
/// equivalent of the MUI outlined input minimals.cc is built on. Deliberately
/// has no card/shadow of its own: an input is a quiet, recessed surface, not
/// an elevated one — that visual weight belongs to cards and buttons, not to
/// every field stacked inside them. The previous version wrapped each field
/// in its own `FlatCard`, which looked fine standalone but doubled up into
/// nested cards-within-a-card wherever a field sits inside one already.
class AppFormField extends StatelessWidget {
  const AppFormField({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    this.onChanged,
    this.optional = false,
    this.maxLines = 1,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.onSuffixTap,
    this.errorText,
  });

  final IconData icon;
  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool optional;
  final int maxLines;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusM);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: AppTypography.bodyM.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: optional ? '$label (Optional)' : label,
        labelStyle: AppTypography.bodyM.copyWith(color: AppColors.textMuted),
        floatingLabelStyle: AppTypography.labelM.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
        ),
        hintText: hint,
        hintStyle: AppTypography.bodyM.copyWith(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: AppTheme.iconS),
        suffixIcon: suffixIcon == null
            ? null
            : GestureDetector(
                onTap: onSuffixTap,
                child: Icon(
                  suffixIcon,
                  color: AppColors.textMuted,
                  size: AppTheme.iconS,
                ),
              ),
        filled: true,
        fillColor: AppColors.accentSecondary.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceM,
          vertical: AppTheme.spaceM,
        ),
        errorText: errorText,
        errorStyle: AppTypography.labelS.copyWith(color: AppColors.error),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: AppColors.accentSecondary.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: AppColors.accentSecondary.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}
