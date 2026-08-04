/// Mirrors `announcements/{id}` (see
/// strola_health_firebase/functions/src/lib/types.ts `Announcement`) —
/// only the fields the mobile banner actually renders/needs for audience
/// matching.
class Announcement {
  const Announcement({
    required this.id,
    required this.emoji,
    required this.message,
    required this.linkTarget,
    required this.audience,
    required this.audienceAppVersion,
    required this.audienceAppVersionMode,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;
  final String emoji;
  final String message;
  final String? linkTarget;
  final String audience;
  final String? audienceAppVersion;
  final String? audienceAppVersionMode;
  final DateTime startsAt;
  final DateTime? endsAt;

  factory Announcement.fromFirestore(Map<String, dynamic> data, String docId) {
    DateTime? toDate(Object? v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      // Firestore Timestamp — handled generically since this repo doesn't
      // import cloud_firestore's Timestamp type into the domain layer.
      final toDateMethod = (v as dynamic).toDate;
      return toDateMethod() as DateTime;
    }

    return Announcement(
      id: docId,
      emoji: data['emoji'] as String? ?? '📣',
      message: data['message'] as String? ?? '',
      linkTarget: data['link_target'] as String?,
      audience: data['audience'] as String? ?? 'everyone',
      audienceAppVersion: data['audience_app_version'] as String?,
      audienceAppVersionMode: data['audience_app_version_mode'] as String?,
      startsAt: toDate(data['starts_at']) ?? DateTime.now(),
      endsAt: toDate(data['ends_at']),
    );
  }
}
