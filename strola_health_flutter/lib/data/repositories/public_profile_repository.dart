import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/services/firebase_client.dart';
import 'package:strola_health/domain/entities/public_profile.dart';

/// Batches and caches `getPublicProfiles` lookups for the process lifetime —
/// the same handful of authors/participants/friends get re-resolved across
/// many feed items and screens, and identity fields never change fast enough
/// to need re-fetching within a session.
class PublicProfileRepository {
  final Map<String, PublicProfile> _cache = {};

  Future<PublicProfile> getOne(String userId) async {
    final list = await getMany([userId]);
    return list.isEmpty ? PublicProfile.unknown(userId) : list.first;
  }

  Future<List<PublicProfile>> getMany(Iterable<String> userIds) async {
    final ids = userIds.toSet().toList();
    final uncached = ids.where((id) => !_cache.containsKey(id)).toList();
    if (uncached.isNotEmpty) {
      final result = await FirebaseClient.call('getPublicProfiles', {
        'userIds': uncached,
      });
      final profiles = asMapList(result['profiles']);
      for (final p in profiles) {
        final profile = PublicProfile.fromMap(p);
        _cache[profile.id] = profile;
      }
    }
    return [for (final id in ids) _cache[id] ?? PublicProfile.unknown(id)];
  }

  Future<List<PublicProfile>> search(String query) async {
    final result = await FirebaseClient.call('searchUsers', {'query': query});
    final profiles = asMapList(
      result['profiles'],
    ).map(PublicProfile.fromMap).toList();
    for (final p in profiles) {
      _cache[p.id] = p;
    }
    return profiles;
  }
}

final publicProfileRepositoryProvider = Provider<PublicProfileRepository>(
  (_) => PublicProfileRepository(),
);

/// One resolved profile by uid — thin wrapper so screens that only need a
/// single profile (PublicProfileScreen) don't have to call the repository
/// from inside a build method.
final publicProfileProvider = FutureProvider.family<PublicProfile, String>(
  (ref, userId) => ref.watch(publicProfileRepositoryProvider).getOne(userId),
);
