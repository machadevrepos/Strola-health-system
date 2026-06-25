import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strola_health/domain/entities/app_notification.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';

/// Persists the in-app notification feed via SharedPreferences (JSON-encoded
/// list) — matching the precedent set by `blockedUsersProvider` /
/// `userProfileProvider` for small persisted state, rather than adding a
/// SQLite table for something this size and shape.
class NotificationRepository {
  NotificationRepository(this._prefs);

  final SharedPreferences _prefs;
  static const prefsKey = 'notification_feed';
  static const _maxStored = 50;

  Future<List<AppNotification>> getAll() async {
    final raw = _prefs.getString(prefsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((j) => AppNotification.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<AppNotification>> add(AppNotification notification) async {
    final current = await getAll();
    final updated = [notification, ...current].take(_maxStored).toList();
    await _save(updated);
    return updated;
  }

  Future<List<AppNotification>> markRead(String id) async {
    final current = await getAll();
    final updated = [
      for (final n in current) n.id == id ? n.copyWith(isRead: true) : n,
    ];
    await _save(updated);
    return updated;
  }

  Future<List<AppNotification>> markAllRead() async {
    final current = await getAll();
    final updated = [for (final n in current) n.copyWith(isRead: true)];
    await _save(updated);
    return updated;
  }

  Future<void> _save(List<AppNotification> notifications) {
    return _prefs.setString(
      prefsKey,
      jsonEncode(notifications.map((n) => n.toJson()).toList()),
    );
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(sharedPreferencesProvider)),
);
