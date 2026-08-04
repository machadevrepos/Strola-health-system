import 'package:strola_health/domain/entities/public_profile.dart';

/// Mirrors `communityPosts/{id}` (see
/// strola_health_firebase/functions/src/lib/types.ts `CommunityPost`),
/// merged with the resolved author identity (`getPublicProfiles`) — `users/`
/// isn't client-readable, so the repository always joins these before
/// handing a post to the UI.
class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.author,
    required this.content,
    required this.timestamp,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    this.stepCount,
    this.badgeEmoji,
    this.imageUrl,
    required this.pinned,
    required this.commentsLocked,
    required this.isMine,
  });

  final String id;
  final String authorId;
  final PublicProfile author;
  final String content;
  final DateTime timestamp;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final int? stepCount;
  final String? badgeEmoji;
  final String? imageUrl;
  final bool pinned;
  final bool commentsLocked;
  final bool isMine;

  String get authorName => author.displayName;
  String get initials => author.initials;

  CommunityPost copyWith({
    bool? isLiked,
    int? likesCount,
    int? commentsCount,
  }) => CommunityPost(
    id: id,
    authorId: authorId,
    author: author,
    content: content,
    timestamp: timestamp,
    likesCount: likesCount ?? this.likesCount,
    commentsCount: commentsCount ?? this.commentsCount,
    isLiked: isLiked ?? this.isLiked,
    stepCount: stepCount,
    badgeEmoji: badgeEmoji,
    imageUrl: imageUrl,
    pinned: pinned,
    commentsLocked: commentsLocked,
    isMine: isMine,
  );

  factory CommunityPost.fromFirestore(
    Map<String, dynamic> data,
    String docId, {
    required PublicProfile author,
    required bool isLiked,
    required String currentUserId,
  }) {
    final timestamp = data['timestamp'];
    return CommunityPost(
      id: docId,
      authorId: data['author_id'] as String,
      author: author,
      content: data['content'] as String? ?? '',
      timestamp: timestamp is DateTime ? timestamp : DateTime.now(),
      likesCount: (data['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (data['comments_count'] as num?)?.toInt() ?? 0,
      isLiked: isLiked,
      stepCount: (data['step_count'] as num?)?.toInt(),
      badgeEmoji: data['badge_emoji'] as String?,
      imageUrl: data['image_url'] as String?,
      pinned: data['pinned'] as bool? ?? false,
      commentsLocked: data['comments_locked'] as bool? ?? false,
      isMine: data['author_id'] == currentUserId,
    );
  }
}

/// Mirrors `communityPosts/{postId}/comments/{id}` (`CommunityComment`).
class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.author,
    required this.content,
    required this.timestamp,
    required this.isMine,
  });

  final String id;
  final String postId;
  final String authorId;
  final PublicProfile author;
  final String content;
  final DateTime timestamp;
  final bool isMine;

  String get authorName => author.displayName;
  String get initials => author.initials;

  factory CommunityComment.fromFirestore(
    Map<String, dynamic> data,
    String docId, {
    required PublicProfile author,
    required String currentUserId,
  }) {
    final timestamp = data['timestamp'];
    return CommunityComment(
      id: docId,
      postId: data['post_id'] as String,
      authorId: data['author_id'] as String,
      author: author,
      content: data['content'] as String? ?? '',
      timestamp: timestamp is DateTime ? timestamp : DateTime.now(),
      isMine: data['author_id'] == currentUserId,
    );
  }
}
