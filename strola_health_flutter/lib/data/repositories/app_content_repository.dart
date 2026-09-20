import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/services/firebase_client.dart';

/// Real Firestore-backed editable UI copy (`appContent/{key}`, admin-authored
/// via the "App Content" panel — see strola_health_admin_next's
/// app-content-view.tsx). Client-readable for any signed-in user per
/// firestore.rules; nothing here ever writes to it.
///
/// Currently the only real consumer of this collection anywhere in the app —
/// every other screen's copy is still a hardcoded Dart string literal, not
/// wired to app_content at all, regardless of whether an admin-panel entry
/// exists for it. This wires up the one example the admin explicitly asked
/// to confirm (the bottom-nav tab labels) as a working proof of the whole
/// pipeline; the other ~50 entries (onboarding, errors, buttons, etc.) are a
/// separate, much larger follow-up if the admin wants the rest wired too.
class AppContentRepository {
  AppContentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// key -> value, e.g. `{"challenges.nav_label": "Challenges"}`. Missing
  /// entirely (not just empty) if the fetch fails — callers must fall back
  /// to a hardcoded default per key rather than assume this succeeded.
  Future<Map<String, String>> getAll() async {
    final snap = await _firestore.collection('appContent').get();
    return {
      for (final doc in snap.docs)
        doc.id: (doc.data()['value'] as String?) ?? '',
    };
  }
}

final appContentRepositoryProvider = Provider<AppContentRepository>(
  (ref) => AppContentRepository(FirebaseClient.firestore),
);

/// Fetched once per app session (not per screen) — this is copy text, not
/// live data, so there's no reason to refetch on every nav rebuild.
final appContentProvider = FutureProvider<Map<String, String>>((ref) {
  return ref.watch(appContentRepositoryProvider).getAll();
});

/// `ref.watch(appContentProvider).valueOrNull?[key] ?? fallback` inline
/// everywhere would work identically — this just names the pattern so call
/// sites read as "app content lookup" rather than unwrapping an AsyncValue
/// by hand. Always returns [fallback] while loading or on error/missing key,
/// never a loading spinner or blank text in its place.
String appContentText(WidgetRef ref, String key, String fallback) {
  final content = ref.watch(appContentProvider).valueOrNull;
  final value = content?[key];
  return (value == null || value.isEmpty) ? fallback : value;
}
