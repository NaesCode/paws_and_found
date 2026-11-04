/// Represents a single in-app notification for the user.
///
/// Maps to the `public.notifications` table in Supabase.
/// Fields match the snake_case columns defined in the schema.
class AppNotification {
  final String id;
  final String userId;

  /// The notification category (e.g. 'match_found', 'report_nearby', 'pet_safe').
  final String type;

  /// The human-readable message shown to the user.
  final String message;

  /// Optional reference to a match row (used for deep-linking).
  final String? relatedMatchId;

  /// Optional reference to a report/post row (used for direct post viewing).
  final String? relatedReportId;

  /// Whether the user has already seen / tapped this notification.
  final bool isRead;

  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    this.relatedMatchId,
    this.relatedReportId,
    required this.isRead,
    required this.createdAt,
  });

  /// Whether this notification is linked to an animal sighting or missing pet post.
  bool get isPostRelated {
    if (relatedReportId != null && relatedReportId!.isNotEmpty) return true;
    if (relatedMatchId != null && relatedMatchId!.isNotEmpty) return true;
    switch (type) {
      case 'match_found':
      case 'report_nearby':
      case 'report_update':
      case 'verification_request':
      case 'match_confirmed':
      case 'pet_safe':
        return true;
      case 'warning':
        return message.toLowerCase().contains('sighting') ||
            message.toLowerCase().contains('post') ||
            message.contains('#');
      default:
        return false;
    }
  }

  /// Extracts the post / report identifier if embedded in the message or references.
  String? get extractedPostId {
    if (relatedReportId != null && relatedReportId!.isNotEmpty) {
      return relatedReportId;
    }
    final hashMatch = RegExp(r'#([A-Za-z0-9\-]+)').firstMatch(message);
    if (hashMatch != null) {
      return hashMatch.group(1);
    }
    return null;
  }
}
