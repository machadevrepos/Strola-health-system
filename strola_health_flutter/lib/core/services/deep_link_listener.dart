import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/data/repositories/challenge_repository.dart';
import 'package:strola_health/presentation/providers/challenge_providers.dart';
import 'package:strola_health/presentation/screens/private_challenge_detail_screen.dart';

/// Handles a challenge invite link opening the app — either
/// `https://link.strollahealth.com/join/{code}` (once iOS Associated
/// Domains / Android App Links are verified for that domain) or the
/// `strolahealth://join/{code}` custom-scheme fallback, which works
/// immediately since it needs no domain verification. Mirrors
/// push_message_listener.dart's pattern for navigating from outside the
/// widget tree via a global [GlobalKey<NavigatorState>] — there's no
/// BuildContext this early/this far outside any screen.
void registerDeepLinkListener(
  ProviderContainer container,
  GlobalKey<NavigatorState> navigatorKey,
) {
  AppLinks().uriLinkStream.listen(
    (uri) => _routeToInviteLink(container, navigatorKey, uri),
  );
}

/// The cold-start case: the tap is what launched the process, so there's no
/// stream event for it — the link that launched the app has to be fetched
/// once, explicitly, before the first frame.
Future<void> routeInitialDeepLink(
  ProviderContainer container,
  GlobalKey<NavigatorState> navigatorKey,
) async {
  final initialUri = await AppLinks().getInitialLink();
  if (initialUri != null) {
    await _routeToInviteLink(container, navigatorKey, initialUri);
  }
}

/// Handles two URI shapes, since a custom scheme has no separate host
/// component the way an https URL does:
///   - `https://link.strollahealth.com/join/{code}` → `join` is a real path
///     segment, so it shows up in [Uri.pathSegments].
///   - `strolahealthlink://join/{code}` → `join` parses as [Uri.host] (the
///     authority), leaving only `{code}` in [Uri.pathSegments].
String? _inviteCodeFrom(Uri uri) {
  final segments = uri.pathSegments;
  if (uri.host == 'join' && segments.length == 1 && segments.first.isNotEmpty) {
    return segments.first;
  }
  final joinIndex = segments.indexOf('join');
  if (joinIndex == -1 || joinIndex + 1 >= segments.length) return null;
  final code = segments[joinIndex + 1];
  return code.isEmpty ? null : code;
}

Future<void> _routeToInviteLink(
  ProviderContainer container,
  GlobalKey<NavigatorState> navigatorKey,
  Uri uri,
) async {
  final inviteCode = _inviteCodeFrom(uri);
  if (inviteCode == null) return;

  try {
    // Requires a signed-in user (the `joinChallenge` callable does its own
    // auth check) — a link tapped before sign-in/onboarding is complete
    // silently does nothing rather than queuing itself for later. Worth
    // revisiting if that turns out to be a common path in practice; not
    // built out now since there's no session/UI wiring in this app to
    // resume a pending action after onboarding today.
    final challengeId = await container
        .read(myChallengesProvider.notifier)
        .join(inviteCode: inviteCode);
    final challenge = await container
        .read(challengeRepositoryProvider)
        .getChallenge(challengeId);
    if (challenge == null) return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => PrivateChallengeDetailScreen(challenge: challenge),
      ),
    );
  } catch (_) {
    // Invalid/expired code, already a member, the challenge ended, or the
    // user isn't signed in yet — nothing to route to. Silent: there's no
    // BuildContext here to show an error, and this only ever fires once per
    // link tap. The Firebase Hosting landing page (strola_health_firebase's
    // joinPage function) is what a human sees before the app is even
    // open — this handler only runs once it already is.
  }
}
