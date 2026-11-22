import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/core/services/local_notification_service.dart';
import 'package:paws_and_found/features/notifications/domain/entities/app_notification.dart';

void main() {
  group('LocalNotificationService Tests', () {
    test('Service instance is a singleton', () {
      final s1 = LocalNotificationService.instance;
      final s2 = LocalNotificationService.instance;
      expect(identical(s1, s2), isTrue);
    });

    test('showAppNotification safely handles platform execution in tests', () async {
      final notification = AppNotification(
        id: 'test-uuid-1234',
        userId: 'user-abc',
        type: 'match_found',
        message: 'A potential match was discovered nearby.',
        relatedReportId: 'report-xyz',
        isRead: false,
        createdAt: DateTime.now(),
      );

      // Verify showAppNotification executes without throwing uncaught errors
      await expectLater(
        LocalNotificationService.instance.showAppNotification(notification),
        completes,
      );
    });

    test('Notification tap listener responds to value updates', () {
      String? tappedPayload;
      final service = LocalNotificationService.instance;

      void listener() {
        tappedPayload = service.onNotificationTapped.value;
      }

      service.onNotificationTapped.addListener(listener);
      service.onNotificationTapped.value = 'test-report-payload';

      expect(tappedPayload, equals('test-report-payload'));

      service.onNotificationTapped.removeListener(listener);
    });
  });
}
