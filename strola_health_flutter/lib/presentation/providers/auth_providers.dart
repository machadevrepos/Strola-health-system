import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strola_health/presentation/providers/profile_providers.dart';

/// Whether `Firebase.initializeApp()` succeeded at startup — overridden in
/// `main()`. False whenever no Firebase project is configured yet (no
/// `google-services.json`/`GoogleService-Info.plist`), which is expected
/// during development before that's set up. The root gate falls back to the
/// old direct-to-onboarding flow rather than hard-blocking the whole app on
/// a backend feature that isn't configured yet.
final firebaseAvailableProvider = Provider<bool>(
  (_) => throw UnimplementedError('firebaseAvailableProvider must be overridden in main()'),
);

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

/// Null while Firebase is still resolving the cached session, then the
/// signed-in user or null.
final authStateProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(firebaseAvailableProvider)) return const Stream.empty();
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// ── Welcome carousel — shown once, before the auth screens ───────────────────

class HasSeenIntroNotifier extends StateNotifier<bool> {
  HasSeenIntroNotifier(this._prefs) : super(_prefs.getBool(_key) ?? false);

  final SharedPreferences _prefs;
  static const _key = 'has_seen_intro';

  Future<void> markSeen() async {
    state = true;
    await _prefs.setBool(_key, true);
  }
}

final hasSeenIntroProvider = StateNotifierProvider<HasSeenIntroNotifier, bool>(
  (ref) => HasSeenIntroNotifier(ref.watch(sharedPreferencesProvider)),
);

// ── Local-only sign-in (no backend yet) ──────────────────────────────────────
//
// `authStateProvider` falls back to `Stream.empty()` when Firebase isn't
// configured, which never emits — so there's no real session to gate on in
// that mode. This is the stand-in: sign-in/up just record "the user went
// through this screen" locally, with no credential check (there's nothing
// to check against yet), so the full splash → intro → sign-in → onboarding
// flow stays demoable end-to-end without a real backend. Once a Firebase
// project exists, `isSignedInProvider` below switches to the real thing on
// its own — nothing else needs to change.

class LocalAuthNotifier extends StateNotifier<bool> {
  LocalAuthNotifier(this._prefs) : super(_prefs.getBool(prefsKey) ?? false);

  final SharedPreferences _prefs;
  static const prefsKey = 'local_signed_in';

  Future<void> signIn() async {
    state = true;
    await _prefs.setBool(prefsKey, true);
  }

  Future<void> signOut() async {
    state = false;
    await _prefs.remove(prefsKey);
  }
}

final localSignedInProvider = StateNotifierProvider<LocalAuthNotifier, bool>(
  (ref) => LocalAuthNotifier(ref.watch(sharedPreferencesProvider)),
);

/// A fixed short delay standing in for "Firebase resolving the cached
/// session" when there's no Firebase to resolve — so Splash still shows
/// briefly as part of the demoable flow instead of being skipped outright.
final localSplashDelayProvider = FutureProvider<void>((ref) {
  return Future.delayed(const Duration(milliseconds: 900));
});

/// One question `_RootGate` can ask regardless of which mode is active:
/// a real Firebase session when configured, the local stand-in when not.
final isSignedInProvider = Provider<bool>((ref) {
  if (ref.watch(firebaseAvailableProvider)) {
    return ref.watch(authStateProvider).value != null;
  }
  return ref.watch(localSignedInProvider);
});

/// Whether the splash screen's loading phase is done — Firebase resolving
/// its cached session, or the fixed local delay above.
final splashResolvedProvider = Provider<bool>((ref) {
  if (ref.watch(firebaseAvailableProvider)) {
    return !ref.watch(authStateProvider).isLoading;
  }
  return ref.watch(localSplashDelayProvider).hasValue;
});

// ── Remember me ──────────────────────────────────────────────────────────────
//
// Firebase Auth always persists the signed-in session natively on mobile —
// there's no SDK-level "don't remember this session" mode to call instead.
// This flag is what makes the checkbox real: unchecked, `main()` explicitly
// signs the cached session back out on the next launch (see `main.dart`),
// so the user lands on SignInScreen instead of resuming where they left off.
// Checked (the default — matches today's de-facto always-persisted behavior)
// leaves the native session alone.

class RememberMeNotifier extends StateNotifier<bool> {
  RememberMeNotifier(this._prefs) : super(_prefs.getBool(prefsKey) ?? true);

  final SharedPreferences _prefs;

  /// Public so `main()` can read it directly with the same prefs instance,
  /// before the ProviderScope (and this notifier) exist.
  static const prefsKey = 'remember_me';

  Future<void> set(bool value) async {
    state = value;
    await _prefs.setBool(prefsKey, value);
  }
}

final rememberMeProvider = StateNotifierProvider<RememberMeNotifier, bool>(
  (ref) => RememberMeNotifier(ref.watch(sharedPreferencesProvider)),
);

// ── Auth actions ───────────────────────────────────────────────────────────────

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService(this._auth);
  final FirebaseAuth _auth;

  Future<void> signIn({required String email, required String password}) =>
      _run(() => _auth.signInWithEmailAndPassword(email: email.trim(), password: password));

  Future<void> signUp({required String email, required String password}) =>
      _run(() => _auth.createUserWithEmailAndPassword(email: email.trim(), password: password));

  Future<void> sendPasswordResetEmail(String email) =>
      _run(() => _auth.sendPasswordResetEmail(email: email.trim()));

  Future<void> signOut() => _auth.signOut();

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code));
    } catch (_) {
      throw const AuthException(
        "Couldn't connect to your account right now. Please try again shortly.",
      );
    }
  }

  String _friendlyMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return "That email doesn't look right — give it another check.";
      case 'user-disabled':
        return 'This account has been disabled. Contact support if that seems wrong.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return "We couldn't find an account with that email and password.";
      case 'email-already-in-use':
        return 'An account already exists with that email — try signing in instead.';
      case 'weak-password':
        return 'Choose a slightly stronger password (at least 6 characters).';
      case 'network-request-failed':
        return "Couldn't reach the network. Check your connection and try again.";
      case 'too-many-requests':
        return 'Too many attempts — please wait a moment and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(firebaseAuthProvider)),
);
