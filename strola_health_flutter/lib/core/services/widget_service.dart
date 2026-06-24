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
