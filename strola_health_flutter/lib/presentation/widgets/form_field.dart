import 'package:flutter/material.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';

/// Icon + label + borderless TextField inside a FlatCard — the one text
/// input style used across onboarding and auth screens.
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
    return FlatCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceL,
        vertical: AppTheme.spaceM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: AppColors.accent, size: AppTheme.iconM),
          ),
          const SizedBox(width: AppTheme.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: AppTypography.titleS),
                    if (optional) ...[
                      const SizedBox(width: AppTheme.spaceXS),
                      Text('(Optional)', style: AppTypography.labelS),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        onChanged: onChanged,
                        maxLines: maxLines,
                        obscureText: obscureText,
                        keyboardType: keyboardType,
                        style: AppTypography.bodyM.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          hintText: hint,
                          hintStyle: AppTypography.bodyM.copyWith(
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    if (suffixIcon != null)
                      GestureDetector(
                        onTap: onSuffixTap,
                        child: Icon(
                          suffixIcon,
                          color: AppColors.textMuted,
                          size: AppTheme.iconS,
                        ),
                      ),
                  ],
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    errorText!,
                    style: AppTypography.labelS.copyWith(color: AppColors.error),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
