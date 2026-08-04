import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Normalizes a [FirebaseFunctionsException] into something screens can
/// show directly — `message` is already the human-readable string the
/// backend's `invalidArgument`/`notFound`/`failedPrecondition` helpers set
/// (see strola_health_firebase/functions/src/lib/auth-helpers.ts), not a
/// generic Firebase error string.
class BackendException implements Exception {
  BackendException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

/// Firestore + Cloud Functions access point — the Dart-side equivalent of
/// super_admin_next's firestore-helpers.ts. Every mutation, and every read
/// of an admin-locked-down collection, goes through [call]; direct
/// [firestore] reads are for whatever a signed-in user's own
/// firestore.rules already allow (their own docs, public collections like
/// challenges/badges/announcements).
class FirebaseClient {
  FirebaseClient._();

  static const region = 'us-central1';

  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  static FirebaseFunctions get functions =>
      FirebaseFunctions.instanceFor(region: region);

  static FirebaseStorage get storage => FirebaseStorage.instance;

  /// Uploads a community post's picked image to
  /// `community_post_images/{uid}/{fileName}` (storage.rules only allows
  /// each uid to write under its own folder) and returns the public
  /// download URL to send through `createPost`'s `imageUrl` field.
  static Future<String> uploadCommunityPostImage(File file) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in.');
    final fileName = '${DateTime.now().millisecondsSinceEpoch}${_extensionOf(file.path)}';
    final ref = storage.ref('community_post_images/$uid/$fileName');
    await ref.putFile(
      file,
      SettableMetadata(contentType: _contentTypeOf(file.path)),
    );
    return ref.getDownloadURL();
  }

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    return dot == -1 ? '.jpg' : path.substring(dot);
  }

  static String _contentTypeOf(String path) {
    switch (path.toLowerCase().split('.').last) {
      case 'png':
        return 'image/png';
      case 'heic':
        return 'image/heic';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Invokes a deployed callable and unwraps its `.data` as a
  /// `Map<String, dynamic>` — every callable in this backend returns a
  /// JSON object (`{success: true, ...}` at minimum), never a bare
  /// scalar/array, so this one return shape covers all of them.
  static Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic>? data,
  ]) async {
    try {
      final callable = functions.httpsCallable(name);
      final result = await callable.call<Map<String, dynamic>>(data ?? {});
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      throw BackendException(e.code, e.message ?? 'Something went wrong.');
    }
  }
}

/// A Firestore doc's `created_at`/`updated_at`/etc. arrive as native
/// [Timestamp]s; every domain entity in this app uses [DateTime]. Small
/// helper so each entity's `fromFirestore` doesn't repeat the same
/// Timestamp-or-null dance.
DateTime? timestampToDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

DateTime timestampToDateTimeOr(Object? value, DateTime fallback) =>
    timestampToDateTime(value) ?? fallback;

/// Recursively converts every [Timestamp] in a Firestore doc's data (at any
/// depth — top-level fields and nested maps like `subscription.comp_until`)
/// into an ISO 8601 string, so callers that read a doc as a loosely-typed
/// `Map<String, dynamic>` (e.g. `BackendApi.getMe`) can treat every date
/// field as a plain string uniformly, matching what the rest of this app
/// (and the two admin panels' equivalent `convertTimestamps` in
/// firestore-helpers.ts) already expects.
Object? convertFirestoreTimestamps(Object? value) {
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is Map) {
    // `key.toString()` (not the bare `key`) is what forces this map's
    // *inferred* type to `Map<String, Object?>` regardless of the source
    // map's own declared key type. Without it, a nested map decoded from a
    // platform channel — every Firestore doc field one level deeper than
    // the top-level document itself — comes through as `Map<Object?,
    // Object?>`, and simply re-mapping it with `MapEntry(key, ...)`
    // preserves that same imprecise type. A caller that then does
    // `data['nestedField'] as Map<String, dynamic>` throws `type
    // '_Map<Object?, Object?>' is not a subtype of type 'Map<String,
    // dynamic>'` — this was the real cause behind both `restoreProfileFromBackend`'s
    // recurring failure and (once real post data started flowing) the
    // community feed's author-lookup crash.
    return value.map(
      (key, val) => MapEntry(key.toString(), convertFirestoreTimestamps(val)),
    );
  }
  if (value is List) {
    return value.map(convertFirestoreTimestamps).toList();
  }
  return value;
}

/// Cloud Functions callable responses have the identical problem for a
/// different reason: nested objects in the JSON response decode through
/// `cloud_functions`' own platform channel as `Map<Object?, Object?>`, not
/// `Map<String, dynamic>` — so `(list as List).cast<Map<String,
/// dynamic>>()` throws the first time it's actually exercised (`.cast` is a
/// strict runtime type check, not a conversion). This does a real copy of
/// each element instead, which works regardless of the source map's
/// declared generic type.
List<Map<String, dynamic>> asMapList(Object? value) =>
    (value as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
