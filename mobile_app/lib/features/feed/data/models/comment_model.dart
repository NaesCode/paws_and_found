class FeedComment {
  final String id;
  final String postId;
  final String userId;
  final String? parentId;
  final String content;
  final DateTime createdAt;
  final String authorName;
  final String authorPhotoUrl;

  FeedComment({
    required this.id,
    required this.postId,
    required this.userId,
    this.parentId,
    required this.content,
    required this.createdAt,
    this.authorName = 'Community Member',
    this.authorPhotoUrl = '',
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  /// Detects if this comment contains an embedded sighting report link.
  /// Formats matched:
  /// - `https://pawsandfound.org/report/{id}`
  /// - `pawsandfound://report/{id}`
  /// - `/report/{id}`
  String? get linkedReportId {
    final regex = RegExp(
      r'(?:https?:\/\/pawsandfound\.(?:org|app)\/report\/|pawsandfound:\/\/report\/|\/report\/)([a-f0-9\-]{36})',
      caseSensitive: false,
    );
    final match = regex.firstMatch(content);
    return match?.group(1);
  }

  /// Returns user's comment text with the raw report link removed for aesthetic display.
  String get cleanContent {
    final regex = RegExp(
      r'(?:https?:\/\/pawsandfound\.(?:org|app)\/report\/|pawsandfound:\/\/report\/|\/report\/)([a-f0-9\-]{36})',
      caseSensitive: false,
    );
    final stripped = content.replaceAll(regex, '').trim();
    return stripped.isEmpty ? 'Reported an animal sighting below:' : stripped;
  }

  factory FeedComment.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? profile,
  }) {
    final profileName = profile?['name'] as String? ?? '';
    final profilePhoto = profile?['profile_photo_url'] as String? ?? '';

    return FeedComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      parentId: json['parent_id'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      authorName: profileName.isNotEmpty ? profileName : 'Community Member',
      authorPhotoUrl: profilePhoto,
    );
  }
}
