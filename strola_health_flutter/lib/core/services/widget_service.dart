import 'package:home_widget/home_widget.dart';

/// Bridges Flutter step data to the native home-screen and lock-screen widgets.
/// Android: writes to SharedPreferences, triggers StrollaWidgetProvider refresh.
/// iOS:     writes to App Group UserDefaults, triggers StrollaWidget refresh.
class WidgetService {
  static const _androidName = 'StrollaWidgetProvider';
  static const _iOSName = 'StrollaWidget';
  static const _qualifiedAndroid =
      'com.machadev.strola_health.StrollaWidgetProvider';

  /// Must be called once at app startup (main.dart or home screen initState).
  static Future<void> init() async {
    // iOS App Group — must match the group set in Xcode entitlements
    await HomeWidget.setAppGroupId('group.com.machadev.strola_health');
  }

  /// True only on Android 8+ launchers that support prompting the user to
  /// pin a widget directly (`AppWidgetManager.requestPinAppWidget`). False
  /// on iOS and unsupported launchers — there's no equivalent API on iOS,
  /// Apple deliberately keeps adding a widget a manual, user-driven action.
  static Future<bool> isPinSupported() async {
    final supported = await HomeWidget.isRequestPinWidgetSupported();
    return supported ?? false;
  }

  /// Shows the native Android system prompt to pin the home-screen widget.
  /// Only call this after checking [isPinSupported].
  static Future<void> requestPin() {
    return HomeWidget.requestPinWidget(
      androidName: _androidName,
      qualifiedAndroidName: _qualifiedAndroid,
    );
  }

  /// Pushes latest stats to native widgets and requests a redraw.
  /// Safe to call on every step update — writes are cheap and async.
  static Future<void> update({
    required int steps,
    required int goal,
    required String distance,
    required int calories,
    required int activeMin,
    required String motivation,
  }) async {
    await Future.wait([
      HomeWidget.saveWidgetData<int>('steps', steps),
      HomeWidget.saveWidgetData<int>('goal', goal),
      HomeWidget.saveWidgetData<String>('distance', distance),
      HomeWidget.saveWidgetData<int>('calories', calories),
      HomeWidget.saveWidgetData<int>('activeMin', activeMin),
      HomeWidget.saveWidgetData<String>('motivation', motivation),
    ]);
    await HomeWidget.updateWidget(
      name: _androidName,
      iOSName: _iOSName,
      qualifiedAndroidName: _qualifiedAndroid,
    );
  }
}
