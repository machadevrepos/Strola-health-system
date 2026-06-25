import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/services/local_notification_service.dart';
import 'package:strola_health/core/services/purchase_service.dart';
import 'package:strola_health/presentation/providers/auth_providers.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';
import 'package:strola_health/presentation/screens/main_shell.dart';
import 'package:strola_health/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:strola_health/presentation/screens/auth/intro_screens.dart';
import 'package:strola_health/presentation/screens/auth/sign_in_screen.dart';
import 'package:strola_health/presentation/screens/auth/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait-only — every screen in this app is designed for it, and none
  // of the layouts (FlatCard grids, the step ring, forms) account for a
  // landscape rewrap. Locked here at the Flutter level; also locked
  // natively on Android (AndroidManifest.xml `screenOrientation`) and iOS
  // (Info.plist `UISupportedInterfaceOrientations`) so a device rotation
  // can't slip through before this call takes effect.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final prefs = await SharedPreferences.getInstance();
  await LocalNotificationService.init();

  // No Firebase project is configured yet (no google-services.json /
  // GoogleService-Info.plist) — that's expected during development. Rather
  // than crash the whole app on a backend feature that isn't set up, this
  // just flips `isSignedInProvider`/`splashResolvedProvider` over to their
  // local-only stand-ins so the full auth flow stays demoable either way.
  var firebaseAvailable = false;
  try {
    await Firebase.initializeApp();
    firebaseAvailable = true;
  } catch (_) {
    firebaseAvailable = false;
  }

  // Firebase Auth always persists the signed-in session natively on mobile
  // — there's no SDK flag to make a session "forget on restart" instead.
  // "Remember me" only means anything if unchecking it actually does
  // something, so this is where that happens: before the first frame, while
  // it's still cheap to force a sign-out without the user seeing a flash of
  // the wrong screen. `_RootGate` then sees no current user and naturally
  // lands on SignInScreen via `isSignedInProvider` below — no separate code
  // path needed there. Mirrored for the local-only stand-in sign-in when
  // Firebase isn't configured, so the checkbox behaves the same either way.
  final rememberMe = prefs.getBool(RememberMeNotifier.prefsKey) ?? true;
  if (!rememberMe) {
    if (firebaseAvailable && FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
    } else if (!firebaseAvailable) {
      await prefs.remove(LocalAuthNotifier.prefsKey);
    }
  }

  // No-op until a RevenueCat project's API keys are passed via
  // --dart-define — see PurchaseService.isConfigured.
  await PurchaseService.configure();

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
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firebaseAvailableProvider.overrideWithValue(firebaseAvailable),
      ],
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

/// Decides which screen owns the root: splash (while auth resolves) ->
/// welcome intro (once) -> sign in/up -> profile setup wizard -> main app.
///
/// Runs the same flow whether or not a Firebase project is configured —
/// `isSignedInProvider`/`splashResolvedProvider` abstract over a real
/// Firebase session vs. the local-only stand-in, so this flow stays
/// demoable end-to-end before a backend exists, and switches over to the
/// real thing automatically once one is wired in.
class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarded = ref.watch(onboardingCompleteProvider);
    final hasSeenIntro = ref.watch(hasSeenIntroProvider);
    final splashResolved = ref.watch(splashResolvedProvider);
    final signedIn = ref.watch(isSignedInProvider);

    Widget child;
    if (!splashResolved) {
      child = const SplashScreen(key: ValueKey('splash'));
    } else if (!hasSeenIntro) {
      child = const IntroScreens(key: ValueKey('intro'));
    } else if (!signedIn) {
      child = const SignInScreen(key: ValueKey('signin'));
    } else if (!onboarded) {
      child = const OnboardingScreen(key: ValueKey('onboarding'));
    } else {
      child = const MainShell(key: ValueKey('shell'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }
}
