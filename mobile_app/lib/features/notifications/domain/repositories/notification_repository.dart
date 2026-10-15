import '../entities/app_notification.dart';

/// Abstract contract for the notifications feature.
/// The presentation layer depends ONLY on this interface, never on the
/// concrete implementation, keeping the app testable and swappable.
abstract class NotificationRepository {
  /// Fetches all notifications for the currently-authenticated user,
  /// ordered newest-first.
  Future<List<AppNotification>> getNotifications();

  /// Marks a single notification as read.
  Future<void> markRead(String notificationId);

  /// Marks ALL unread notifications as read.
  Future<void> markAllRead();

  /// Returns the current unread count (used for the badge).
  Future<int> getUnreadCount();
}

