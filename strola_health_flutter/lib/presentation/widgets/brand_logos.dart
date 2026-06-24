import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';

/// The five share destinations. `community` is Strolla's own feed; the rest are
/// external social platforms rendered with their real brand identity.
enum BrandType { community, instagram, facebook, whatsapp, tiktok }

// ── Brand colors — external identities, NOT part of the app palette ───────────
const Color kFacebookColor  = Color(0xFF1877F2);
const Color kWhatsappColor  = Color(0xFF25D366);
const Color kTiktokColor    = Color(0xFF010101);
const Color kInstagramColor = Color(0xFFD62976);

const LinearGradient kInstagramGradient = LinearGradient(
  colors: [
    Color(0xFFFEDA75),
    Color(0xFFFA7E1E),
    Color(0xFFD62976),
    Color(0xFF962FBF),
    Color(0xFF4F5BD5),
  ],
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
);

/// Representative accent color for a brand — used for labels, rings and the
/// secondary "story" badge. Community maps to the app accent.
Color brandColorOf(BrandType type) {
  switch (type) {
    case BrandType.community:
      return AppColors.accent;
    case BrandType.instagram:
      return kInstagramColor;
    case BrandType.facebook:
      return kFacebookColor;
    case BrandType.whatsapp:
      return kWhatsappColor;
    case BrandType.tiktok:
      return kTiktokColor;
  }
}

/// A self-contained app-icon style mark for a share destination.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.type, this.size = 44});

  final BrandType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case BrandType.community:
        return _circle(
          AppColors.accent,
          Icon(AppIcons.people, color: Colors.white, size: size * 0.50),
        );
      case BrandType.instagram:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: kInstagramGradient,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: CustomPaint(painter: _InstagramCameraPainter()),
        );
      case BrandType.facebook:
        return _circle(
          kFacebookColor,
          Icon(AppIcons.brandFacebook, color: Colors.white, size: size * 0.70),
        );
      case BrandType.whatsapp:
        return _circle(
          kWhatsappColor,
          FaIcon(AppIcons.brandWhatsapp,
              color: Colors.white, size: size * 0.58),
        );
      case BrandType.tiktok:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: kTiktokColor,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Center(
            child: FaIcon(AppIcons.brandTiktok,
                color: Colors.white, size: size * 0.50),
          ),
        );
    }
  }

  Widget _circle(Color color, Widget child) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(child: child),
    );
  }
}

/// White camera outline for the Instagram mark — drawn over the gradient.
class _InstagramCameraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Camera body — rounded square
    final inset = s * 0.20;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(inset, inset, s - inset, s - inset),
      Radius.circular(s * 0.17),
    );
    canvas.drawRRect(body, stroke);

    // Lens
    canvas.drawCircle(Offset(s / 2, s / 2), s * 0.16, stroke);

    // Flash dot
    final dot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(s * 0.69, s * 0.31), s * 0.042, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
