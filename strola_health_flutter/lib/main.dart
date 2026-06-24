import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';
import 'package:strola_health/presentation/screens/main_shell.dart';
import 'package:strola_health/presentation/screens/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const StrollaHealthApp(),
    ),
  );
}

class StrollaHealthApp extends StatelessWidget {
  const StrollaHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: Color(0xFFE07A7A),
        primaryContainer: Color(0xFFFFDADA),
        secondary: Color(0xFFF6B1B1),
        secondaryContainer: Color(0xFFFFE7E7),
        tertiary: Color(0xFFE9B44C),
        tertiaryContainer: Color(0xFFFFE8B8),
        appBarColor: Color(0xFFFFFFFF),
        error: Color(0xFFE25858),
      ),
      surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
      blendLevel: 8,
      subThemesData: const FlexSubThemesData(
        blendOnColors: true,
        defaultRadius: 16,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
    );

    return MaterialApp(
      title: 'Strolla Health',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: AppTypography.textTheme,
      ),
      home: const _RootGate(),
    );
  }
}

/// Decides between the first-run setup wizard and the main app.
class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarded = ref.watch(onboardingCompleteProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: onboarded
          ? const MainShell(key: ValueKey('shell'))
          : const OnboardingScreen(key: ValueKey('onboarding')),
    );
  }
}
