import '../../domain/entities/app_notification.dart';

/// Data model that extends the domain entity with a `fromJson` factory.
///
/// `fromJson` maps Supabase column names (snake_case) to Dart fields.
class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.message,
    super.relatedMatchId,
    required super.isRead,
    required super.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: (json['id'] ?? '') as String,
      userId: (json['user_id'] ?? '') as String,
      type: (json['type'] ?? 'general') as String,
      message: (json['message'] ?? '') as String,
      relatedMatchId: json['related_match_id'] as String?,
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

