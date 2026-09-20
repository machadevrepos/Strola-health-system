import 'package:flutter/material.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_theme.dart';

class FlatCard extends StatelessWidget {
  const FlatCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20.0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: child,
    );
  }
}
