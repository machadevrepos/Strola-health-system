import 'package:flutter/material.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_typography.dart';

/// Hexagon achievement badge (gamification — multicolor by design, the one
/// intentional exception to the 5-color rule). Shared by the Profile
/// "Achievements" preview and the full Achievements screen.
class HexBadge extends StatelessWidget {
  const HexBadge({
    super.key,
    required this.gradient,
    required this.small,
    required this.label,
    this.big,
    this.icon,
    this.date,
    this.description,
    this.earned,
    this.width = 58,
  });

  final List<Color> gradient;
  final String small;
  final String label;
  final String? big;
  final IconData? icon;

  /// Shown below [label] on the Profile preview (date earned).
  final String? date;

  /// Shown below [label] on the full Achievements screen, paired with
  /// [earned] to render the "Earned" / "Locked" status line.
  final String? description;
  final bool? earned;

  final double width;

  @override
  Widget build(BuildContext context) {
    final locked = earned == false;
    final effectiveGradient = locked
        ? [
            AppColors.textMuted.withValues(alpha: 0.35),
            AppColors.textMuted.withValues(alpha: 0.35),
          ]
        : gradient;

    return SizedBox(
      width: width,
      child: Column(
        children: [
          SizedBox(
            width: width - 4,
            height: width + 2,
            child: ClipPath(
              clipper: _HexagonClipper(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: effectiveGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null)
                        Icon(icon, color: Colors.white, size: 18)
                      else
                        Text(
                          big!,
                          style: AppTypography.titleS.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      const SizedBox(height: 1),
                      Text(
                        small,
                        textAlign: TextAlign.center,
                        style: AppTypography.labelS.copyWith(
                          color: Colors.white,
                          fontSize: 6,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppTypography.titleS.copyWith(
              fontSize: 9,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          if (date != null)
            Text(
              date!,
              textAlign: TextAlign.center,
              style: AppTypography.labelS.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
          if (description != null) ...[
            Text(
              description!,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppTypography.labelS.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              locked ? 'Locked' : 'Earned',
              textAlign: TextAlign.center,
              style: AppTypography.labelS.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                color: locked ? AppColors.textMuted : AppColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Vertical hexagon (points top & bottom) used for achievement badges.
class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.26)
      ..lineTo(w, h * 0.74)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.74)
      ..lineTo(0, h * 0.26)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
