import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/features/notifications/domain/entities/app_notification.dart';
import 'package:paws_and_found/features/notifications/domain/repositories/notification_repository.dart';
import 'package:paws_and_found/features/notifications/presentation/pages/notifications_page.dart';
import 'package:paws_and_found/features/map/data/models/map_report_model.dart';
import 'package:paws_and_found/features/map/presentation/providers/map_controller.dart';

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
          relatedReportId: n.relatedReportId,
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
        relatedReportId: n.relatedReportId,
      );
    }).toList();
  }

  @override
  Future<Map<String, dynamic>?> getPostDetailsForNotification(
      AppNotification notification) async {
    if (notification.message.contains('Mingay')) {
      return {
        'id': notification.relatedReportId ?? '#MINGAY-01',
        'title': 'Mingay',
        'animalType': 'Cat',
        'status': 'missing',
        'description': notification.message,
        'photoUrl': '',
        'locationName': 'Cebu City, Philippines',
        'latitude': 10.3157,
        'longitude': 123.8854,
        'reporterName': 'Community Member',
        'createdAt': notification.createdAt,
        'moderationStatus': 'approved',
        'moderationNotes': null,
      };
    }
    return {
      'id': notification.relatedReportId ??
          notification.extractedPostId ??
          '#TEST-POST-1',
      'title': 'Husky Sighting',
      'animalType': 'Dog',
      'status': 'missing',
      'description':
          'Friendly Siberian Husky with blue eyes spotted near Lahug, Cebu City.',
      'photoUrl': '',
      'locationName': 'Lahug, Cebu City',
      'latitude': 10.330,
      'longitude': 123.905,
      'reporterName': 'Maria Santos',
      'createdAt': notification.createdAt,
      'moderationStatus':
          notification.type == 'warning' ? 'flagged' : 'approved',
      'moderationNotes': notification.type == 'warning'
          ? 'Admin requested clearer picture.'
          : null,
    };
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

    testWidgets('Pillar 1: Renders pet_safe, report_nearby, and report_update notification cards properly',
        (tester) async {
      final pillar1Notifications = [
        AppNotification(
          id: 'p1-1',
          userId: 'user-123',
          message: 'Wonderful news! Mochi is safely home and all active missing alerts have been closed.',
          type: 'pet_safe',
          isRead: false,
          createdAt: DateTime.now(),
        ),
        AppNotification(
          id: 'p1-2',
          userId: 'user-123',
          message: 'Urgent Alert: Luna (Dog) was reported missing in your community. Please keep an eye out!',
          type: 'report_nearby',
          isRead: false,
          createdAt: DateTime.now(),
        ),
        AppNotification(
          id: 'p1-3',
          userId: 'user-123',
          message: 'Search broadcast active: Mochi has been reported missing. Our AI is actively monitoring community sightings.',
          type: 'report_update',
          isRead: true,
          createdAt: DateTime.now(),
        ),
      ];

      mockRepo.currentNotifications = pillar1Notifications;

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            repository: mockRepo,
            isActiveTab: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Wonderful news! Mochi is safely home'), findsOneWidget);
      expect(find.textContaining('Urgent Alert: Luna (Dog) was reported missing'), findsOneWidget);
      expect(find.textContaining('Search broadcast active: Mochi has been reported missing'), findsOneWidget);

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
      expect(find.byIcon(Icons.campaign_rounded), findsOneWidget);
    });

    testWidgets('Pillars 2 & 4: Renders high-confidence match alerts, AI moderation warnings, and deletion confirmations',
        (tester) async {
      final pillar2And4Notifications = [
        AppNotification(
          id: 'p4-1',
          userId: 'user-123',
          message: '🚨 High-Confidence Match (92%): A pet strongly resembling Milo was reported nearby in Lahug (0.5 km away)!',
          type: 'match_found',
          isRead: false,
          createdAt: DateTime.now(),
        ),
        AppNotification(
          id: 'p2-1',
          userId: 'user-123',
          message: 'Post Under Review: Sighting #A1B2 was flagged by AI as no clear animal was detected. If this was a mistake, an admin will review it shortly.',
          type: 'warning',
          isRead: false,
          createdAt: DateTime.now(),
        ),
        AppNotification(
          id: 'p2-2',
          userId: 'user-123',
          message: 'Your sighting report has been successfully withdrawn.',
          type: 'report_update',
          isRead: true,
          createdAt: DateTime.now(),
        ),
        AppNotification(
          id: 'p4-2',
          userId: 'user-123',
          message: 'Pet Profile Removed: Banana has been removed from your account.',
          type: 'report_update',
          isRead: true,
          createdAt: DateTime.now(),
        ),
      ];

      mockRepo.currentNotifications = pillar2And4Notifications;

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            repository: mockRepo,
            isActiveTab: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('🚨 High-Confidence Match (92%)'), findsOneWidget);
      expect(find.textContaining('Post Under Review: Sighting #A1B2'), findsOneWidget);
      expect(find.textContaining('Your sighting report has been successfully withdrawn'), findsOneWidget);
      expect(find.textContaining('Pet Profile Removed: Banana has been removed'), findsOneWidget);

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.campaign_rounded), findsNWidgets(2));
    });

    testWidgets('Post-Related Notification is clickable and opens PostDetailsBottomSheet directly', (tester) async {
      final postNotification = AppNotification(
        id: 'post-notif-1',
        userId: 'user-123',
        message: '🚨 High-Confidence Match (95%): A pet strongly resembling Max was reported nearby (#A1B2)!',
        type: 'match_found',
        relatedReportId: 'rep-uuid-1111',
        isRead: false,
        createdAt: DateTime.now(),
      );

      mockRepo.currentNotifications = [postNotification];

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            repository: mockRepo,
            isActiveTab: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify 'View Post' indicator chip is visible
      expect(find.text('View Post'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      // Tap on the notification tile
      await tester.tap(find.textContaining('🚨 High-Confidence Match'));
      await tester.pumpAndSettle();

      // Verify PostDetailsBottomSheet opened
      expect(find.text('Husky Sighting'), findsOneWidget);
      expect(find.text('Category: Dog'), findsOneWidget);
      expect(find.text('MISSING'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.text('Reported by Maria Santos'), findsOneWidget);
      expect(find.text('Lahug, Cebu City'), findsOneWidget);
      expect(find.textContaining('10.330°, 123.905°'), findsOneWidget);
      expect(find.text('Full Description'), findsOneWidget);
      expect(find.textContaining('Friendly Siberian Husky with blue eyes'), findsOneWidget);
      expect(find.text('View on Community Map'), findsOneWidget);

      // Notification should be marked as read
      expect(mockRepo.markReadCallCount, equals(1));
    });

    testWidgets('Tapping View on Map in PostDetailsBottomSheet triggers callback with reportId and coordinates', (tester) async {
      String? tappedReportId;
      double? tappedLat;
      double? tappedLng;

      final flaggedWarningNotification = AppNotification(
        id: 'warn-notif-2',
        userId: 'user-123',
        message: 'Action Required: Sighting #042 was flagged by AI content moderation.',
        type: 'warning',
        relatedReportId: 'report-uuid-042',
        isRead: false,
        createdAt: DateTime.now(),
      );

      mockRepo.currentNotifications = [flaggedWarningNotification];

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            repository: mockRepo,
            isActiveTab: true,
            onViewOnMap: (id, lat, lng) {
              tappedReportId = id;
              tappedLat = lat;
              tappedLng = lng;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on notification
      await tester.tap(find.textContaining('Action Required: Sighting #042'));
      await tester.pumpAndSettle();

      // Verify Moderator Feedback Banner is shown
      expect(find.text('Moderator Feedback & Action Required'), findsOneWidget);
      expect(find.text('Admin requested clearer picture.'), findsOneWidget);

      // Ensure button is visible in scrollview and tap
      await tester.ensureVisible(find.text('View on Community Map'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View on Community Map'));
      await tester.pumpAndSettle();

      // Bottom sheet dismissed and callback invoked with coordinates
      expect(tappedReportId, equals('report-uuid-042'));
      expect(tappedLat, equals(10.330));
      expect(tappedLng, equals(123.905));
    });


    testWidgets('Mingay Cat notification displays actual pet title and clean placeholder (never Gollum meme)', (tester) async {
      MapReportModel.clearDynamicReports();

      final mingayNotification = AppNotification(
        id: 'notif-mingay-0539',
        userId: 'user-123',
        message: 'Urgent Alert: Mingay (Cat) was reported missing in your community. Please keep an eye out!',
        type: 'report_nearby',
        isRead: false,
        createdAt: DateTime.now(),
      );

      mockRepo.currentNotifications = [mingayNotification];

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsPage(
            repository: mockRepo,
            isActiveTab: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Mingay notification
      await tester.tap(find.textContaining('Urgent Alert: Mingay (Cat)'));
      await tester.pumpAndSettle();

      // Verify title is "Mingay" and Category is "Cat" (NOT "Community Animal Sighting")
      expect(find.text('Mingay'), findsOneWidget);
      expect(find.text('Category: Cat'), findsOneWidget);
      expect(find.text('MISSING'), findsOneWidget);

      // Verify clean placeholder is rendered without Gollum meme image
      expect(find.text('No Photo Available'), findsOneWidget);
      expect(find.text('Cat Sighting Report'), findsOneWidget);
      expect(find.byIcon(Icons.pets_rounded), findsWidgets);

      // Tap View on Community Map
      await tester.ensureVisible(find.text('View on Community Map'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View on Community Map'));
      await tester.pumpAndSettle();

      // Verify report was dynamically registered for Community Map canvas
      expect(MapReportModel.dynamicReports, isNotEmpty);
      final registered = MapReportModel.dynamicReports.first;
      expect(registered.title, equals('Mingay'));
      expect(registered.animalType, equals('Cat'));
      expect(registered.status, equals('missing'));
      expect(registered.pinLabel, equals('M'));
      expect(registered.latitude, equals(10.3157));
      expect(registered.longitude, equals(123.8854));
    });

    test('MapController registerAndSelectReport updates reports and selects pin', () {
      final controller = MapController();
      expect(controller.reports, isEmpty);

      final dynamicPin = MapReportModel(
        id: 'mingay-pin-1',
        reporterId: 'user-1',
        title: 'Mingay',
        animalType: 'Cat',
        description: 'Missing cat',
        status: 'missing',
        locationName: 'Cebu City',
        latitude: 10.3157,
        longitude: 123.8854,
        normalizedX: 0.5,
        normalizedY: 0.5,
        tags: const ['Cat', 'MISSING'],
        createdAt: DateTime(2026, 11, 4),
      );

      controller.registerAndSelectReport(dynamicPin);

      expect(controller.reports.length, equals(1));
      expect(controller.selectedReport?.id, equals('mingay-pin-1'));
      expect(controller.selectedReport?.title, equals('Mingay'));
      expect(controller.selectedReport?.pinLabel, equals('M'));
    });
  });
}