import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:strola_health/core/services/firebase_client.dart';

/// Registers/unregisters this device's FCM token against the backend
/// (`registerDeviceToken`/`unregisterDeviceToken` — see
/// strola_health_firebase/functions/src/push/registerDeviceToken.ts), the
/// piece that was entirely missing before this migration: `firebase_messaging`
/// wasn't even a dependency, so none of the real push notifications the
/// backend already sends (new comment, new like, challenge joined) had
/// anywhere to land on a device.
///
/// Static-method pattern, mirroring PurchaseService — call [register] once
/// after a successful sign-in, [unregister] before signing out.
class PushTokenService {
  PushTokenService._();

  static String? _lastKnownToken;

  /// Requests notification permission (iOS prompts; Android 13+ prompts,
  /// older Android is granted implicitly) and, if granted, registers this
  /// device's current FCM token. Also listens for token refresh (FCM
  /// rotates tokens periodically) and keeps the backend in sync for the
  /// lifetime of the app process. Best-effort — a denied permission or a
  /// registration failure shouldn't block sign-in.
  static Future<void> register() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }

      messaging.onTokenRefresh.listen(_registerToken);
    } catch (e) {
      debugPrint('PushTokenService.register failed: $e');
    }
  }

  static Future<void> _registerToken(String token) async {
    try {
      await FirebaseClient.call('registerDeviceToken', {
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
      });
      _lastKnownToken = token;
    } catch (e) {
      debugPrint('PushTokenService._registerToken failed: $e');
    }
  }

  /// Best-effort — called right before sign-out. If it fails, the token
  /// stays registered server-side and this device just keeps receiving
  /// pushes for an account that's no longer signed in on it until
  /// [register] runs again for whoever signs in next (which re-registers
  /// the same token doc id, so it self-corrects).
  static Future<void> unregister() async {
    final token = _lastKnownToken;
    if (token == null) return;
    try {
      await FirebaseClient.call('unregisterDeviceToken', {'token': token});
      _lastKnownToken = null;
    } catch (e) {
      debugPrint('PushTokenService.unregister failed: $e');
    }
  }
}
