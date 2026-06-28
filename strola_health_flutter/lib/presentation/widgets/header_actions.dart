import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_icons.dart';
import 'package:strola_health/core/constants/app_theme.dart';
import 'package:strola_health/presentation/providers/notification_providers.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';
import 'package:strola_health/presentation/screens/notifications_screen.dart';
import 'package:strola_health/presentation/screens/profile_screen.dart';

/// Standard top-right header actions used on every primary screen:
/// a notifications bell + the user's profile avatar. (No "..." menu — that is
/// reserved for viewing *other* people's profiles.)
class HeaderActions extends ConsumerWidget {
  const HeaderActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showBellDot = ref.watch(unreadNotificationCountProvider) > 0;
    final photoPath = ref.watch(userProfileProvider).photoPath;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Notifications bell
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.10),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  AppIcons.notifications,
                  color: AppColors.textSecondary,
                  size: AppTheme.iconM,
                ),
              ),
              if (showBellDot)
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Profile avatar
        GestureDetector(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentSecondary.withValues(alpha: 0.22),
              border: Border.all(
                color: AppColors.accentSecondary.withValues(alpha: 0.45),
                width: 1.5,
              ),
              image: photoPath != null
                  ? DecorationImage(
                      image: FileImage(File(photoPath)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photoPath == null
                ? Icon(
                    AppIcons.profile,
                    color: AppColors.accent,
                    size: AppTheme.iconM,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
