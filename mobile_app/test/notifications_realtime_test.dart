import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/features/notifications/domain/entities/app_notification.dart';
import 'package:paws_and_found/features/notifications/domain/repositories/notification_repository.dart';
import 'package:paws_and_found/features/notifications/presentation/pages/notifications_page.dart';

class MockNotificationRepository implements NotificationRepository {
  List<AppNotification> currentNotifications = [];
  final StreamController<List<AppNotification>> _streamController =
      StreamController<List<AppNotification>>.broadcast();

  int getNotificationsCallCount = 0;
  int markReadCallCount = 0;
  int markAllReadCallCount = 0;

  void emit(List<AppNotification> notifications) {
    currentNotifications = notifications;
    _streamController.add(notifications);
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    getNotificationsCallCount++;
    return currentNotifications;
  }

  @override
  Stream<List<AppNotification>> streamNotifications() {
    return _streamController.stream;
  }

  @override
  Stream<int> streamUnreadCount() {
    return _streamController.stream
        .map((list) => list.where((n) => !n.isRead).length);
  }

  @override
  Future<int> getUnreadCount() async {
    return currentNotifications.where((n) => !n.isRead).length;
  }

  @override
  Future<void> markRead(String notificationId) async {
    markReadCallCount++;
    currentNotifications = currentNotifications.map<AppNotification>((n) {
      if (n.id == notificationId) {
        return AppNotification(
          id: n.id,
          userId: n.userId,
          message: n.message,
          type: n.type,
          isRead: true,
          createdAt: n.createdAt,
          relatedMatchId: n.relatedMatchId,
        );
      }
      return n;
    }).toList();
  }

  @override
  Future<void> markAllRead() async {
    markAllReadCallCount++;
    currentNotifications = currentNotifications.map<AppNotification>((n) {
      return AppNotification(
        id: n.id,
        userId: n.userId,
        message: n.message,
        type: n.type,
        isRead: true,
        createdAt: n.createdAt,
        relatedMatchId: n.relatedMatchId,
      );
    }).toList();
  }

  void dispose() {
    _streamController.close();
  }
}

void main() {
  group('Notifications Realtime & Tab-Reactivation Tests', () {
    late MockNotificationRepository mockRepo;

    final sampleNotification = AppNotification(
      id: 'notif-1',
      userId: 'user-123',
      message: 'AI Match: A pet matching your report was spotted nearby!',
      type: 'match_found',
      isRead: false,
      createdAt: DateTime.now(),
    );

    setUp(() {
      mockRepo = MockNotificationRepository();
    });

    tearDown(() {
      mockRepo.dispose();
    });

    testWidgets('Renders empty state initially when repository has no notifications',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            repository: mockRepo,
            isActiveTab: true,
          ),
        ),
      );

      // Initial async load
      await tester.pumpAndSettle();

      expect(find.text('All caught up!'), findsOneWidget);
      expect(find.text('You have no notifications yet.'), findsOneWidget);
      expect(mockRepo.getNotificationsCallCount, equals(1));
    });

    testWidgets('Updates reactively in realtime when stream emits new notification',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            repository: mockRepo,
            isActiveTab: true,
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('All caught up!'), findsOneWidget);

      // Simulate AI pipeline inserting a notification via Realtime stream
      mockRepo.emit([sampleNotification]);
      await tester.pumpAndSettle();

      // Notification is displayed immediately without needing a page remount
      expect(
        find.text('AI Match: A pet matching your report was spotted nearby!'),
        findsOneWidget,
      );
    });

    testWidgets('didUpdateWidget re-fetches notifications when tab becomes active',
        (tester) async {
      // Start with inactive tab
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            repository: mockRepo,
            isActiveTab: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(mockRepo.getNotificationsCallCount, equals(1));

      // Simulate AI match added in database while user is on another tab
      mockRepo.currentNotifications = [sampleNotification];

      // User switches back to notifications tab (isActiveTab: true)
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            repository: mockRepo,
            isActiveTab: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verified: getNotifications was called again due to didUpdateWidget
      expect(mockRepo.getNotificationsCallCount, equals(2));
      expect(
        find.text('AI Match: A pet matching your report was spotted nearby!'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping notification marks it as read and updates state',
        (tester) async {
      mockRepo.currentNotifications = [sampleNotification];

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            repository: mockRepo,
            isActiveTab: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('AI Match: A pet matching your report was spotted nearby!'),
        findsOneWidget,
      );
      await tester.tap(
        find.text('AI Match: A pet matching your report was spotted nearby!'),
      );
      await tester.pumpAndSettle();

      expect(mockRepo.markReadCallCount, equals(1));
    });
  });
}
