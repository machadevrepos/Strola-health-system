import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';

/// Whether the "add the home-screen widget" prompt has already been shown
/// once. Shown automatically the first time a signed-in user reaches Home;
/// also re-openable any time from Settings, which doesn't touch this flag.
class HasSeenWidgetPromptNotifier extends StateNotifier<bool> {
  HasSeenWidgetPromptNotifier(this._prefs)
    : super(_prefs.getBool(_key) ?? false);

  final SharedPreferences _prefs;
  static const _key = 'has_seen_widget_prompt';

  Future<void> markSeen() async {
    state = true;
    await _prefs.setBool(_key, true);
  }
}

final hasSeenWidgetPromptProvider =
    StateNotifierProvider<HasSeenWidgetPromptNotifier, bool>(
      (ref) =>
          HasSeenWidgetPromptNotifier(ref.watch(sharedPreferencesProvider)),
    );
