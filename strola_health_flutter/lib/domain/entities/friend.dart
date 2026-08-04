import 'package:strola_health/domain/entities/public_profile.dart';

enum FriendshipStatus { pending, accepted }

/// One row of "my relationship to another user" — merges a `friendships/{id}`
/// doc (see strola_health_firebase/functions/src/community/friends.ts) with
/// that user's resolved identity.
class FriendSummary {
  const FriendSummary({
    required this.profile,
    required this.status,
    required this.isIncomingRequest,
  });

  final PublicProfile profile;
  final FriendshipStatus status;

  /// True when the *other* person sent the request — only then can the
  /// caller accept/decline it. A pending request the caller sent themselves
  /// is shown as "Requested", not actionable.
  final bool isIncomingRequest;
}
