import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/utils/push_routing.dart';
import 'package:strola_health/domain/entities/app_notification.dart';
import 'package:strola_health/presentation/providers/navigation_providers.dart';
import 'package:strola_health/presentation/providers/notification_providers.dart';

/// Must be a top-level (or static) function — FCM runs this in a separate
/// isolate when a data/notification message arrives while the app is fully
/// backgrounded/terminated. There's no UI to update at that point, this
/// just lets the OS show the notification tray entry FCM already builds
/// from the payload's `notification` field; nothing else to do here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Foreground messages don't get an automatic OS banner from FCM (that only
/// happens in background/terminated) — this bridges an incoming push into
/// the same in-app notification feed/local-banner path
/// `registerNotificationDetectors` uses for on-device triggers, via the same
/// [NotificationsNotifier.add], so a server-sent push (new comment, new
/// like, challenge joined — see functions/src/push/notifyEvents.ts) shows
/// up identically whether the app was open or not.
void registerForegroundPushListener(ProviderContainer container) {
  FirebaseMessaging.onMessage.listen((message) {
    final notification = message.notification;
    if (notification == null) return;

    container
        .read(notificationsProvider.notifier)
        .add(
          AppNotification(
            id:
                message.messageId ??
                DateTime.now().microsecondsSinceEpoch.toString(),
            category: _categoryFor(message.data['link_target']),
            title: notification.title ?? 'Strolla',
            body: notification.body ?? '',
            timestamp: DateTime.now(),
            routeTarget: message.data['link_target'] as String?,
          ),
        );
  });
}

NotificationCategory _categoryFor(Object? linkTarget) {
  switch (linkTarget) {
    case 'challenge':
      return NotificationCategory.challenge;
    case 'community':
    default:
      return NotificationCategory.community;
  }
}

/// Registers the tap handler for a push notification that arrives while the
/// app is backgrounded (process alive, user taps the tray entry to bring it
/// back to the foreground). Call once, alongside [registerForegroundPushListener].
void registerPushTapHandler(
  ProviderContainer container,
  GlobalKey<NavigatorState> navigatorKey,
) {
  FirebaseMessaging.onMessageOpenedApp.listen(
    (message) => _routeToPushTarget(container, navigatorKey, message),
  );
}

/// The terminated-app case: the tap is what cold-launched the process, so
/// there's no stream event for it — the tapped message has to be fetched
/// once, explicitly, after `Firebase.initializeApp()` but before `runApp`.
Future<void> routeInitialPushMessage(
  ProviderContainer container,
  GlobalKey<NavigatorState> navigatorKey,
) async {
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    _routeToPushTarget(container, navigatorKey, initialMessage);
  }
}

/// Shared by both tap paths above — same `link_target` → tab mapping
/// notifications_screen.dart uses for an in-app notification tap (see
/// push_routing.dart), so a server push routes identically whether it's
/// tapped from the in-app feed or straight from the OS notification tray.
void _routeToPushTarget(
  ProviderContainer container,
  GlobalKey<NavigatorState> navigatorKey,
  RemoteMessage message,
) {
  final tabIndex = tabIndexForLinkTarget(message.data['link_target'] as String?);
  if (tabIndex == null) return;
  // Whatever screen the tap landed on (could be several pushes deep, or a
  // dialog), the target tab needs to actually be visible, so unwind back to
  // MainShell first.
  navigatorKey.currentState?.popUntil((route) => route.isFirst);
  container.read(mainTabIndexProvider.notifier).state = tabIndex;
}
