import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';

/// The five share destinations, plus the platform-integration sources synced
/// from Settings → Connected Apps. `community` is Strolla's own feed; the
/// share destinations render their real brand identity. The integration
/// sources deliberately do NOT — see the comment on `BrandLogo` below.
enum BrandType {
  community,
  instagram,
  facebook,
  whatsapp,
  tiktok,
  healthkit,
  healthConnect,
  strava,
  oura,
  garmin,
}

// ── Brand colors — external identities, NOT part of the app palette ───────────
const Color kFacebookColor  = Color(0xFF1877F2);
const Color kWhatsappColor  = Color(0xFF25D366);
const Color kTiktokColor    = Color(0xFF010101);
const Color kInstagramColor = Color(0xFFD62976);
const Color kAppleHealthColor    = Color(0xFFFF2D55);
const Color kHealthConnectColor  = Color(0xFF4285F4);
const Color kStravaColor         = Color(0xFFFC4C02);
const Color kOuraColor           = Color(0xFF1A1A1A);
const Color kGarminColor         = Color(0xFF007CC3);

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
    case BrandType.healthkit:
      return kAppleHealthColor;
    case BrandType.healthConnect:
      return kHealthConnectColor;
    case BrandType.strava:
      return kStravaColor;
    case BrandType.oura:
      return kOuraColor;
    case BrandType.garmin:
      return kGarminColor;
  }
}

/// A self-contained app-icon style mark for a share destination or a synced
/// platform.
///
/// The five share destinations above use each platform's real glyph — well
/// established "share to X" fair use. The five health-platform marks below
/// deliberately do NOT: badge usage for Apple Health, Health Connect,
/// Strava, Oura, and Garmin is governed by each platform's own brand
/// program, most of which require formal approval before their actual logo
/// can be displayed. Until that approval lands, these render as a neutral
/// icon in the platform's brand color, with `IntegrationsScreen` carrying an
/// explicit note that the real badges are pending.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.type, this.size = 44});

  final BrandType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case BrandType.healthkit:
        return _circle(
          kAppleHealthColor,
          Icon(AppIcons.heart, color: Colors.white, size: size * 0.50),
        );
      case BrandType.healthConnect:
        return _circle(
          kHealthConnectColor,
          Icon(AppIcons.integrations, color: Colors.white, size: size * 0.50),
        );
      case BrandType.strava:
        return _circle(
          kStravaColor,
          Icon(AppIcons.run, color: Colors.white, size: size * 0.50),
        );
      case BrandType.oura:
        return _circle(
          kOuraColor,
          Icon(AppIcons.heartRate, color: Colors.white, size: size * 0.50),
        );
      case BrandType.garmin:
        return _circle(
          kGarminColor,
          Icon(AppIcons.watch, color: Colors.white, size: size * 0.50),
        );
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
