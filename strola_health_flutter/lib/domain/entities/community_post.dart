class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorName,
    required this.content,
    required this.timestamp,
    this.avatarColor,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.stepCount,
    this.badgeEmoji,
    this.imageUrl,
  });

  final String id;
  final String authorName;
  final String content;
  final DateTime timestamp;
  final int? avatarColor;
  final int likes;
  final int comments;
  final bool isLiked;
  final int? stepCount;
  final String? badgeEmoji;
  final String? imageUrl;

  String get initials {
    final parts = authorName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return authorName.substring(0, 2).toUpperCase();
  }

  CommunityPost copyWith({bool? isLiked, int? likes}) => CommunityPost(
    id: id,
    authorName: authorName,
    content: content,
    timestamp: timestamp,
    avatarColor: avatarColor,
    likes: likes ?? this.likes,
    comments: comments,
    isLiked: isLiked ?? this.isLiked,
    stepCount: stepCount,
    badgeEmoji: badgeEmoji,
    imageUrl: imageUrl,
  );
}
