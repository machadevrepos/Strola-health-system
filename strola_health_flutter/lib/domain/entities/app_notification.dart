import 'package:flutter/material.dart';
import 'package:strola_health/core/constants/app_icons.dart';

/// The 6 client-specified categories, plus `deviceDisconnected` and
/// `personalRecord` (both free to add — reuse existing data sources, no new
/// infrastructure needed).
enum NotificationCategory {
  goalReminder,
  goalAchieved,
  streak,
  challenge,
  community,
  lowBattery,
  deviceDisconnected,
  personalRecord,
}

extension NotificationCategoryX on NotificationCategory {
  IconData get icon {
    switch (this) {
      case NotificationCategory.goalReminder:
        return AppIcons.goal;
      case NotificationCategory.goalAchieved:
        return AppIcons.goalReached;
      case NotificationCategory.streak:
        return AppIcons.streak;
      case NotificationCategory.challenge:
        return AppIcons.trophy;
      case NotificationCategory.community:
        return AppIcons.people;
      case NotificationCategory.lowBattery:
        return AppIcons.battery;
      case NotificationCategory.deviceDisconnected:
        return AppIcons.bluetoothDisabled;
      case NotificationCategory.personalRecord:
        return AppIcons.premium;
    }
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.routeTarget,
  });

  final String id;
  final NotificationCategory category;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  /// Opaque hint for where tapping this notification should navigate — one
  /// of the keys in push_routing.dart's `pushLinkTargetTabIndex`
  /// ('home', 'stats', 'community', 'challenge'). Optional — null means
  /// no-op.
  final String? routeTarget;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    category: category,
    title: title,
    body: body,
    timestamp: timestamp,
    isRead: isRead ?? this.isRead,
    routeTarget: routeTarget,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.name,
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'routeTarget': routeTarget,
  };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as String,
    category: NotificationCategory.values.firstWhere(
      (c) => c.name == j['category'],
      orElse: () => NotificationCategory.community,
    ),
    title: j['title'] as String,
    body: j['body'] as String,
    timestamp: DateTime.parse(j['timestamp'] as String),
    isRead: j['isRead'] as bool? ?? false,
    routeTarget: j['routeTarget'] as String?,
  );
}
