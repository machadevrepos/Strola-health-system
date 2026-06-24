import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/domain/entities/workout_session.dart';

// ── Speed → colour mapping (coral palette only) ───────────────────────────────
//
//  < 0.5 m/s  stopped      → blush 25%
//  0.5–1.5    slow walk    → blush (#F6B1B1)
//  1.5–2.5    brisk walk   → medium coral (#EC9393)
//  > 2.5      jog / run    → full coral (#E07A7A)

Color routeSpeedColor(double speedMps) {
  if (speedMps < 0.5) return AppColors.accentSecondary.withValues(alpha: 0.3);
  if (speedMps < 1.5) return AppColors.accentSecondary;
  if (speedMps < 2.5) return AppColors.accent.withValues(alpha: 0.72);
  return AppColors.accent;
}

/// Builds one short polyline per segment, each coloured by the speed at that GPS fix.
List<Polyline> buildRouteSpeedPolylines(List<RoutePoint> points) {
  if (points.length < 2) return [];
  return [
    for (int i = 0; i < points.length - 1; i++)
      Polyline(
        points: [points[i].position, points[i + 1].position],
        color: routeSpeedColor(points[i].speedMps),
        strokeWidth: 5.0,
        borderStrokeWidth: 1.5,
        borderColor: routeSpeedColor(points[i].speedMps).withValues(alpha: 0.3),
      ),
  ];
}

// ── Speed legend ──────────────────────────────────────────────────────────────

class RouteSpeedLegend extends StatelessWidget {
  const RouteSpeedLegend({super.key});

  static final _entries = [
    (AppColors.accentSecondary, 'Walk'),
    (AppColors.accent.withValues(alpha: 0.72), 'Brisk'),
    (AppColors.accent, 'Run'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentSecondary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: _entries.map((e) {
          final (color, label) = e;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.labelS.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Static route map (for session summary) ────────────────────────────────────

class StaticRouteMap extends StatelessWidget {
  const StaticRouteMap({
    super.key,
    required this.routePoints,
    this.height = 200,
    this.borderRadius = const BorderRadius.vertical(
      bottom: Radius.circular(20),
    ),
  });

  final List<RoutePoint> routePoints;
  final double height;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    if (routePoints.length < 2) {
      return Container(
        height: height,
        alignment: Alignment.center,
        child: Text(
          '🗺️  No GPS data for this session',
          style: AppTypography.bodyS.copyWith(letterSpacing: 0),
        ),
      );
    }

    final latLngs = routePoints.map((p) => p.position).toList();
    final bounds = LatLngBounds.fromPoints(latLngs);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        children: [
          SizedBox(
            height: height,
            child: FlutterMap(
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(40),
                ),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.strola.health',
                  retinaMode: true,
                ),
                // Speed heat-map segments
                PolylineLayer(polylines: buildRouteSpeedPolylines(routePoints)),
                // Start marker (white + coral border), End marker (solid coral)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: routePoints.first.position,
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          AppIcons.controlPlay,
                          color: AppColors.accent,
                          size: AppTheme.iconXS,
                        ),
                      ),
                    ),
                    // End marker (coral dot)
                    Marker(
                      point: routePoints.last.position,
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          AppIcons.controlStop,
                          color: Colors.white,
                          size: AppTheme.iconXS,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Speed legend — bottom-right
          Positioned(bottom: 10, right: 10, child: const RouteSpeedLegend()),

          // Subtle top fade to blend with card header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 28,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.bgSurface.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
