import 'package:flutter/material.dart';
import 'package:strola_health/core/constants/app_colors.dart';

/// Hand-crafted icon set for Strolla Health.
/// All icons are drawn in a 24 × 24 coordinate space and scaled to [size].
/// Using CustomPainter so no external package is needed.

enum StrollaIconType {
  footstep, // distance stat chip
  flame, // calories stat chip
  clock, // time stat chip
  shoe, // step ring center
}

class StrollaIcon extends StatelessWidget {
  const StrollaIcon(
    this.type, {
    super.key,
    this.size = 24,
    this.color = AppColors.accent,
  });

  final StrollaIconType type;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StrollaIconPainter(type: type, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StrollaIconPainter extends CustomPainter {
  _StrollaIconPainter({required this.type, required this.color});

  final StrollaIconType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Scale from 24×24 design space to actual pixel size
    final s = size.width / 24.0;
    canvas.save();
    canvas.scale(s, s);

    switch (type) {
      case StrollaIconType.footstep:
        _drawFootstep(canvas);
      case StrollaIconType.flame:
        _drawFlame(canvas);
      case StrollaIconType.clock:
        _drawClock(canvas);
      case StrollaIconType.shoe:
        _drawShoe(canvas);
    }

    canvas.restore();
  }

  // ── Footstep — two offset footprint silhouettes ───────────────────────────
  // Inspiration: classic "steps" universal symbol refined for women's fitness.
  // Front foot is full-opacity; back foot is faded + slightly smaller.
  void _drawFootstep(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final paintFaded = Paint()
      ..color = color.withValues(alpha: 0.42)
      ..style = PaintingStyle.fill;

    // Front right foot — lower-right quadrant
    _singleFoot(canvas, paint, cx: 14.5, cy: 16.5, scale: 1.0);
    // Back left foot — upper-left quadrant, slightly smaller
    _singleFoot(canvas, paintFaded, cx: 7.5, cy: 8.5, scale: 0.76);
  }

  /// Draws one footprint with [cx],[cy] as heel-center and [scale] sizing.
  /// Foot points upward (toes above heel).
  void _singleFoot(
    Canvas canvas,
    Paint paint, {
    required double cx,
    required double cy,
    required double scale,
  }) {
    // ── Foot body (tapered rounded shape) ────────────────────────────────────
    // Heel-center is at (cx, cy).
    // Body goes up ~8 units and is ~5.5 units wide.
    final body = Path()
      ..moveTo(cx - 2.0, cy + 2.0) // heel bottom-left
      ..quadraticBezierTo(
        cx - 2.8 * scale,
        cy - 0.5,
        cx - 2.4 * scale,
        cy - 3.0,
      ) // left side up
      ..quadraticBezierTo(
        cx - 2.0 * scale,
        cy - 5.5,
        cx - 0.2 * scale,
        cy - 6.5,
      ) // upper left
      ..quadraticBezierTo(
        cx + 2.0 * scale,
        cy - 6.8,
        cx + 3.2 * scale,
        cy - 5.5,
      ) // upper right
      ..quadraticBezierTo(
        cx + 4.0 * scale,
        cy - 4.0,
        cx + 3.8 * scale,
        cy - 1.5,
      ) // right side
      ..quadraticBezierTo(
        cx + 3.5 * scale,
        cy + 1.0,
        cx + 2.5 * scale,
        cy + 2.2,
      ) // heel bottom-right
      ..quadraticBezierTo(cx + 0.5, cy + 2.8, cx - 2.0, cy + 2.0) // heel base
      ..close();
    canvas.drawPath(body, paint);

    // ── 5 toes in a gentle arc ────────────────────────────────────────────────
    final toeData = [
      // [dx from cx, dy from cy, radius]
      [-0.7 * scale, -7.5 * scale, 1.25 * scale], // big toe
      [1.2 * scale, -8.1 * scale, 1.05 * scale], // 2nd toe
      [2.8 * scale, -7.6 * scale, 0.95 * scale], // 3rd toe
      [4.0 * scale, -6.4 * scale, 0.85 * scale], // 4th toe
      [4.5 * scale, -4.8 * scale, 0.75 * scale], // pinky toe
    ];
    for (final t in toeData) {
      canvas.drawCircle(Offset(cx + t[0], cy + t[1]), t[2], paint);
    }
  }

  // ── Flame — organic teardrop with inner highlight ─────────────────────────
  // Multi-layer: deep coral outer body + semi-transparent white inner core.
  void _drawFlame(Canvas canvas) {
    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // ── Outer flame body ──────────────────────────────────────────────────────
    final body = Path()
      ..moveTo(12, 22) // base center
      ..quadraticBezierTo(6.5, 19, 6.8, 14) // left side curve
      ..quadraticBezierTo(7.0, 9.5, 10.5, 7.5) // upper-left
      ..quadraticBezierTo(
        9.8,
        11.5,
        12.5,
        13.5,
      ) // left inner scoop (realistic flame lean)
      ..quadraticBezierTo(13.5, 6.5, 11.8, 2.5) // flame tip — thin and tall
      ..quadraticBezierTo(17.0, 6.0, 17.2, 11.5) // right upper
      ..quadraticBezierTo(17.5, 16, 17.5, 18) // right lower
      ..quadraticBezierTo(17.0, 21, 12, 22) // right base
      ..close();
    canvas.drawPath(body, bodyPaint);

    // ── Inner highlight (adds depth and premium feel) ─────────────────────────
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    final highlight = Path()
      ..moveTo(12, 19.5) // inner base
      ..quadraticBezierTo(9.5, 17, 10.0, 13) // inner left
      ..quadraticBezierTo(10.5, 10.5, 12.2, 11.5) // scoop point
      ..quadraticBezierTo(13.0, 7.5, 12.5, 5.5) // going to inner tip
      ..quadraticBezierTo(14.5, 8.5, 14.5, 12) // right inner
      ..quadraticBezierTo(15.0, 16.5, 12, 19.5) // right base
      ..close();
    canvas.drawPath(highlight, highlightPaint);
  }

  // ── Clock — minimal watch face with hands at 10:10 ────────────────────────
  // Classic "time" icon redefined: circle, 4 cardinal dots, two stylised hands.
  void _drawClock(Canvas canvas) {
    const center = Offset(12, 12);
    const radius = 9.2;

    // ── Outer ring ────────────────────────────────────────────────────────────
    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, ringPaint);

    // ── 4 hour markers (small filled circles at N/E/S/W) ─────────────────────
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(12, 3.5), 0.9, dotPaint); // 12
    canvas.drawCircle(const Offset(20.5, 12), 0.9, dotPaint); // 3
    canvas.drawCircle(const Offset(12, 20.5), 0.9, dotPaint); // 6
    canvas.drawCircle(const Offset(3.5, 12), 0.9, dotPaint); // 9

    // ── Hour hand (10 o'clock, shorter) ──────────────────────────────────────
    final hourPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, const Offset(7.8, 7.2), hourPaint);

    // ── Minute hand (2 o'clock, longer) ──────────────────────────────────────
    final minutePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, const Offset(16.8, 5.8), minutePaint);

    // ── Center pivot dot ──────────────────────────────────────────────────────
    canvas.drawCircle(center, 1.4, dotPaint);
  }

  // ── Running Shoe — side-view athletic sneaker ─────────────────────────────
  // Detailed silhouette: sole, upper body, tongue, laces, side stripe.
  // Used at 36–48 px in the step ring center annotation.
  void _drawShoe(Canvas canvas) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // ── Sole (thick elongated pill at the bottom) ─────────────────────────────
    final sole = Path()
      ..moveTo(3, 21.5)
      ..quadraticBezierTo(3, 23.5, 5.5, 23.5) // heel bottom
      ..lineTo(18.5, 23.5)
      ..quadraticBezierTo(22.5, 23.5, 22.5, 21.5) // toe bottom
      ..quadraticBezierTo(22.5, 19.5, 20.5, 19.5) // toe top
      ..lineTo(4.5, 19.5)
      ..quadraticBezierTo(3, 19.5, 3, 21.5) // heel top
      ..close();
    canvas.drawPath(sole, fill);

    // ── Upper body (the shoe's main body above the sole) ─────────────────────
    final upper = Path()
      ..moveTo(4, 19.5) // bottom-left (resting on sole)
      ..lineTo(4, 13.5) // heel back — straight left wall
      ..quadraticBezierTo(4, 7.5, 7, 6.5) // heel curve upward
      ..quadraticBezierTo(9.5, 5.5, 11.5, 7) // ankle collar
      ..quadraticBezierTo(14.5, 8, 16.5, 8.5) // mid-upper
      ..quadraticBezierTo(19.5, 9.2, 21, 11.5) // toe box
      ..quadraticBezierTo(22, 13.5, 21.8, 16) // toe face curve
      ..quadraticBezierTo(21.5, 18.5, 20.5, 19.5) // toe front down
      ..close();
    canvas.drawPath(upper, fill);

    // ── Heel counter (slightly darker panel detail) ───────────────────────────
    final heelPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    final heel = Path()
      ..moveTo(4, 19.5)
      ..lineTo(4, 13.5)
      ..quadraticBezierTo(4, 9, 6.5, 7.5)
      ..quadraticBezierTo(8, 7, 9, 7.5)
      ..quadraticBezierTo(8, 10, 8, 13)
      ..lineTo(8, 19.5)
      ..close();
    canvas.drawPath(heel, heelPaint);

    // ── Tongue (centre panel between laces) ──────────────────────────────────
    final tonguePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final tongue = Path()
      ..moveTo(9.5, 7.8)
      ..quadraticBezierTo(11, 6.8, 12.5, 7.8)
      ..lineTo(13.2, 15.5)
      ..lineTo(8.8, 15.5)
      ..close();
    canvas.drawPath(tongue, tonguePaint);

    // ── Laces (three crisp horizontal lines) ─────────────────────────────────
    final lacePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(9.2, 10.0),
      const Offset(12.8, 10.0),
      lacePaint,
    );
    canvas.drawLine(
      const Offset(9.2, 12.0),
      const Offset(12.8, 12.0),
      lacePaint,
    );
    canvas.drawLine(
      const Offset(9.2, 14.0),
      const Offset(12.8, 14.0),
      lacePaint,
    );

    // ── Side swoosh / speed stripe ────────────────────────────────────────────
    final swooshPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final swoosh = Path()
      ..moveTo(8, 15.5)
      ..quadraticBezierTo(13, 13, 20.5, 15);
    canvas.drawPath(swoosh, swooshPaint);
  }

  @override
  bool shouldRepaint(covariant _StrollaIconPainter old) =>
      old.type != type || old.color != color;
}
