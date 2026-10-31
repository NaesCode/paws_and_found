import '../entities/app_notification.dart';

/// Abstract contract for the notifications feature.
/// The presentation layer depends ONLY on this interface, never on the
/// concrete implementation, keeping the app testable and swappable.
abstract class NotificationRepository {
  /// Fetches all notifications for the currently-authenticated user,
  /// ordered newest-first.
  Future<List<AppNotification>> getNotifications();

  /// Real-time stream of notifications for the authenticated user,
  /// automatically updating when new records (e.g. AI matches) arrive.
  Stream<List<AppNotification>> streamNotifications();

  /// Real-time stream of the unread notification count for badges.
  Stream<int> streamUnreadCount();

  /// Marks a single notification as read.
  Future<void> markRead(String notificationId);

  /// Marks ALL unread notifications as read.
  Future<void> markAllRead();

  /// Returns the current unread count (used for the badge).
  Future<int> getUnreadCount();
}
