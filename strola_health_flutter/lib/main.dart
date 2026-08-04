import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:strola_health/core/services/account_service.dart';
import 'package:strola_health/core/services/local_notification_service.dart';
import 'package:strola_health/core/services/purchase_service.dart';
import 'package:strola_health/core/services/push_message_listener.dart';
import 'package:strola_health/presentation/providers/auth_providers.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';
import 'package:strola_health/presentation/screens/main_shell.dart';
import 'package:strola_health/presentation/widgets/app_error_fallback.dart';
import 'package:strola_health/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:strola_health/presentation/screens/auth/intro_screens.dart';
import 'package:strola_health/presentation/screens/auth/sign_in_screen.dart';
import 'package:strola_health/presentation/screens/auth/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Replaces Flutter's default red-screen-of-death — which ignores this
  // app's design system entirely — with an on-brand fallback for any widget
  // that throws during build. Doesn't change *why* something failed, only
  // how it looks when it does; the underlying error should still get fixed.
  ErrorWidget.builder = (details) => AppErrorFallback(details: details);

  // Portrait-only — every screen in this app is designed for it, and none
  // of the layouts (FlatCard grids, the step ring, forms) account for a
  // landscape rewrap. Locked here at the Flutter level; also locked
  // natively on Android (AndroidManifest.xml `screenOrientation`) and iOS
  // (Info.plist `UISupportedInterfaceOrientations`) so a device rotation
  // can't slip through before this call takes effect.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  await LocalNotificationService.init();

  // Falls back to local-only stand-ins (`isSignedInProvider`/
  // `splashResolvedProvider`) rather than crashing if Firebase ever isn't
  // configured on a given build (e.g. a platform with no
  // google-services.json/GoogleService-Info.plist yet) — kept even though a
  // real project is wired in now, since it costs nothing and the app stays
  // demoable either way.
  //
  // Retried with backoff: on iOS, `AppDelegate` uses Flutter's "implicit
  // engine" plugin-registration hook (`didInitializeImplicitFlutterEngine`),
  // which on some cold starts hasn't finished registering the native
  // Firebase Core plugin's method channel by the time this call fires — a
  // real, observed `[core/not-initialized]` race, not a config problem
  // (confirmed: the exact same build succeeds on most launches). An earlier,
  // shorter retry budget (3 attempts / ~900ms) still lost the race on a slow
  // launch — this is deliberately much more generous (up to 8s) because the
  // fallback path isn't actually safe here: multiple providers built this
  // session (community/challenges/friends/etc.) call Firestore/Functions
  // unconditionally with no per-call availability guard, so losing this race
  // doesn't just disable a feature, it crashes screens outright. Retrying
  // past the native delay is far cheaper than auditing every call site.
  var firebaseAvailable = false;
  const maxAttempts = 10;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await Firebase.initializeApp();
      firebaseAvailable = true;
      break;
    } catch (e, st) {
      if (attempt == maxAttempts) {
        // Was previously silently swallowed on the only attempt — logged now
        // so a genuine init failure is diagnosable instead of surfacing
        // later as a confusing "no-app" crash the first time something reads
        // a Firebase-backed provider.
        debugPrint(
          '[Firebase] initializeApp() failed after $attempt attempts, '
          'falling back to local-only mode: $e\n$st',
        );
      } else {
        debugPrint(
          '[Firebase] initializeApp() attempt $attempt failed, retrying: $e',
        );
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }
  }
  if (firebaseAvailable) {
    // App Check attests that calls to Cloud Functions/Firestore are coming
    // from this genuine app build, not a script replaying its API. Debug
    // providers are used in debug builds (simulator/emulator have no real
    // attestation hardware) — each debug-build install prints a debug token
    // to the device log on first launch, which must be pasted into Firebase
    // Console → App Check → this app → "Manage debug tokens" once per
    // install/device before its calls will be recognized. Enforcement
    // itself is a separate Console toggle per product (Functions,
    // Firestore) — left off until App Check metrics have been observed for
    // a few days with no false rejections; until then this only attaches
    // tokens; nothing is actually blocked yet.
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );

    // Must be registered before runApp — this is what lets FCM show a
    // system notification (and, on Android, run this isolate) while the
    // app is backgrounded/terminated.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Crash reporting — routes both the Flutter framework's own error
    // channel (widget build/layout errors) and the Dart VM's uncaught-error
    // channel (async errors outside any widget) to Crashlytics. Without the
    // second one, an error thrown in a bare `Future`/`Timer` callback (no
    // surrounding try/catch) would never be reported at all.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
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

  // An explicit container (rather than a plain ProviderScope) so
  // registerForegroundPushListener below can read/write providers from
  // outside the widget tree — FCM's onMessage stream isn't a widget.
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      firebaseAvailableProvider.overrideWithValue(firebaseAvailable),
    ],
  );
  if (firebaseAvailable) {
    registerForegroundPushListener(container);
    // Backgrounded (tapped from the tray while the app process was still
    // alive) and terminated (tapped, which cold-launches the app) both need
    // separate handling from onMessage above — that stream only fires while
    // the app is already in the foreground.
    registerPushTapHandler(container, rootNavigatorKey);
    await routeInitialPushMessage(container, rootNavigatorKey);
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: StrollaHealthApp(firebaseAvailable: firebaseAvailable),
    ),
  );
}

/// Lets push_message_listener.dart navigate from outside the widget tree —
/// FCM's tap-handling streams aren't widgets, so there's no BuildContext to
/// reach the Navigator through any other way.
final rootNavigatorKey = GlobalKey<NavigatorState>();

class StrollaHealthApp extends StatelessWidget {
  const StrollaHealthApp({super.key, required this.firebaseAvailable});

  final bool firebaseAvailable;

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
      navigatorKey: rootNavigatorKey,
      title: 'Strolla Health',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: AppTypography.textTheme,
      ),
      navigatorObservers: [
        if (firebaseAvailable)
          FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
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
/// Set once per app process the first time `_RootGate` checks a signed-in
/// user's profile — see the comment where it's used, below. Deliberately a
/// plain top-level flag rather than a provider: this needs to survive and
/// stay true for the rest of the process regardless of how many times
/// `_RootGate` itself rebuilds, which is exactly what a `const` root
/// widget's non-reactive state should be.
bool _hasCheckedInitialSession = false;

class _RootGate extends ConsumerWidget {
  const _RootGate();

  /// Fires `restoreProfileFromBackend` off `_RootGate`'s own `ref` — stable
  /// for the app's entire lifetime, unlike SignInScreen's, which gets torn
  /// down by this very gate the instant `isSignedInProvider` flips (a
  /// disposed-widget crash this used to hit when the call lived there
  /// instead). `profileRestoreInProgressProvider` is what makes the gate
  /// wait here rather than deciding onboarded-vs-not off stale local data
  /// while this is still in flight.
  Future<void> _restoreProfile(WidgetRef ref) async {
    ref.read(profileRestoreInProgressProvider.notifier).state = true;
    try {
      await restoreProfileFromBackend(ref);
    } finally {
      ref.read(profileRestoreInProgressProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<bool>(isSignedInProvider, (previous, next) {
      if (next && previous == false && ref.read(firebaseAvailableProvider)) {
        _restoreProfile(ref);
      }
    });

    final onboarded = ref.watch(onboardingCompleteProvider);
    final hasSeenIntro = ref.watch(hasSeenIntroProvider);
    final splashResolved = ref.watch(splashResolvedProvider);
    final signedIn = ref.watch(isSignedInProvider);
    final restoringProfile = ref.watch(profileRestoreInProgressProvider);

    // Covers a persisted session that's already signed in on the very
    // first build — the `ref.listen` above only fires on a live
    // false->true transition. Firebase Auth's own session survives even an
    // app uninstall/reinstall (it lives in the OS Keychain, not this app's
    // sandboxed storage), while this device's local SharedPreferences
    // profile does not — so a returning user can launch already "signed
    // in" with onboardingComplete still reading false from empty local
    // storage, and would otherwise see the onboarding wizard with blank
    // fields instead of picking up where they left off.
    if (splashResolved &&
        signedIn &&
        !onboarded &&
        !_hasCheckedInitialSession &&
        ref.read(firebaseAvailableProvider)) {
      _hasCheckedInitialSession = true;
      _restoreProfile(ref);
    }

    Widget child;
    if (!splashResolved) {
      child = const SplashScreen(key: ValueKey('splash'));
    } else if (!hasSeenIntro) {
      child = const IntroScreens(key: ValueKey('intro'));
    } else if (!signedIn) {
      child = const SignInScreen(key: ValueKey('signin'));
    } else if (restoringProfile) {
      // Signed in, but the real profile (in particular: was onboarding
      // already completed on another device?) is still being fetched from
      // the backend — hold here rather than deciding off stale/empty local
      // data, which would show onboarding again just for the second it
      // takes the fetch to land.
      child = const SplashScreen(key: ValueKey('restoring'));
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
