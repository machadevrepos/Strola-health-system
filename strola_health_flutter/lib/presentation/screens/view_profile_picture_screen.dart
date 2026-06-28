import 'dart:io';

import 'package:flutter/material.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';

/// Full-screen, pinch-to-zoom view of the user's profile picture.
/// [photoPath] is null when no photo has been set yet — shows the same
/// placeholder icon used everywhere else rather than a broken image.
class ViewProfilePictureScreen extends StatelessWidget {
  const ViewProfilePictureScreen({super.key, required this.photoPath});

  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: photoPath != null
                ? InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.file(File(photoPath!)),
                  )
                : Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentSecondary.withValues(alpha: 0.3),
                    ),
                    child: const Icon(
                      AppIcons.profile,
                      color: AppColors.accent,
                      size: 80,
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.close,
                    color: Colors.white,
                    size: AppTheme.iconM,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
