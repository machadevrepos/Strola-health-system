import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strola_health/core/services/firebase_client.dart';

/// Builds a map the way a platform channel actually decodes a nested JSON
/// object — `Map<Object?, Object?>`, not `Map<String, dynamic>` — so these
/// tests exercise the real failure mode instead of a map literal that's
/// already conveniently typed the way the code wants it.
Map<Object?, Object?> platformMap(Map<String, Object?> m) =>
    Map<Object?, Object?>.of(m);

void main() {
  group(
    'asMapList — regression coverage for the callable-response cast crash',
    () {
      test(
        'converts a list of platform-channel-shaped maps '
        '(the exact "_Map<Object?, Object?> is not a subtype of '
        'Map<String, dynamic>" crash a plain .cast<Map<String, dynamic>>() '
        'throws on)',
        () {
          final input = [
            platformMap({'id': 'u1', 'name': 'Alice'}),
            platformMap({'id': 'u2', 'name': 'Bob'}),
          ];

          // Sanity check the premise: this is exactly what used to throw.
          expect(
            () => input.cast<Map<String, dynamic>>().toList(),
            throwsA(isA<TypeError>()),
          );

          final result = asMapList(input);
          expect(result, [
            {'id': 'u1', 'name': 'Alice'},
            {'id': 'u2', 'name': 'Bob'},
          ]);
          // Genuinely retyped, not just structurally equal.
          expect(result, everyElement(isA<Map<String, dynamic>>()));
        },
      );

      test('an already-correctly-typed list still works', () {
        final input = <Map<String, dynamic>>[
          {'id': 'u1'},
        ];
        expect(asMapList(input), [
          {'id': 'u1'},
        ]);
      });

      test('an empty list stays empty', () {
        expect(asMapList(<Object?>[]), <Map<String, dynamic>>[]);
      });
    },
  );

  group(
    'convertFirestoreTimestamps — regression coverage for the nested-map '
    'cast crash (restoreProfileFromBackend / community feed author lookup)',
    () {
      test(
        'a nested platform-channel-shaped map is retyped to '
        'Map<String, dynamic>, not left as the loosely-typed source map',
        () {
          final doc = platformMap({
            'name': 'Alice',
            'subscription': platformMap({'tier': 'premium'}),
          });

          final result = convertFirestoreTimestamps(doc) as Map<String, dynamic>;

          // The exact downstream failure this guards against:
          // `me['subscription'] as Map<String, dynamic>?` used to throw
          // here because the nested map kept its Object?-keyed source type.
          final subscription = result['subscription'] as Map<String, dynamic>?;
          expect(subscription, {'tier': 'premium'});
        },
      );

      test('converts a Timestamp to an ISO 8601 string, at any depth', () {
        final timestamp = Timestamp.fromDate(DateTime.utc(2026, 8, 3, 12));
        final expected = timestamp.toDate().toIso8601String();
        final doc = platformMap({
          'created_at': timestamp,
          'nested': platformMap({'updated_at': timestamp}),
        });

        final result = convertFirestoreTimestamps(doc) as Map<String, dynamic>;
        expect(result['created_at'], expected);
        final nested = result['nested'] as Map<String, dynamic>;
        expect(nested['updated_at'], expected);
      });

      test('a list of nested maps is converted element-by-element', () {
        final doc = platformMap({
          'items': [
            platformMap({'a': 1}),
            platformMap({'b': 2}),
          ],
        });

        final result = convertFirestoreTimestamps(doc) as Map<String, dynamic>;
        final items = result['items'] as List;
        expect(items, [
          isA<Map<String, dynamic>>(),
          isA<Map<String, dynamic>>(),
        ]);
      });

      test('scalar values pass through unchanged', () {
        expect(convertFirestoreTimestamps('hello'), 'hello');
        expect(convertFirestoreTimestamps(42), 42);
        expect(convertFirestoreTimestamps(null), null);
      });
    },
  );
}
