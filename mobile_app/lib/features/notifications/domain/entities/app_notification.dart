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

  /// Whether the user has already seen / tapped this notification.
  final bool isRead;

  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    this.relatedMatchId,
    required this.isRead,
    required this.createdAt,
  });
}

