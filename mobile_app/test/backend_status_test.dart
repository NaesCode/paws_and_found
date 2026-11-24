import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paws_and_found/core/services/backend_status_service.dart';
import 'package:paws_and_found/shared/atoms/backend_status_chip.dart';

void main() {
  group('BackendStatusService tests', () {
    final service = BackendStatusService.instance;

    tearDown(() {
      service.dispose();
      service.status.value = BackendStatus.unknown;
    });

    test('HTTP 200 sets status to online', () async {
      service.httpClient = MockClient((request) async {
        return http.Response('{"status": "ok", "db": "ok"}', 200);
      });

      final result = await service.ping();
      expect(result, BackendStatus.online);
      expect(service.status.value, BackendStatus.online);
    });

    test('HTTP 401 sets status to online (warm container awaiting auth)', () async {
      service.httpClient = MockClient((request) async {
        return http.Response('{"detail": "Authentication credentials were not provided."}', 401);
      });

      final result = await service.ping();
      expect(result, BackendStatus.online);
      expect(service.status.value, BackendStatus.online);
    });

    test('HTTP 500 or 503 sets status to degraded', () async {
      service.httpClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final result = await service.ping();
      expect(result, BackendStatus.degraded);
      expect(service.status.value, BackendStatus.degraded);
    });

    test('Network timeout or exception sets status to offline', () async {
      service.httpClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final result = await service.ping();
      expect(result, BackendStatus.offline);
      expect(service.status.value, BackendStatus.offline);
    });
  });

  group('BackendStatusChip widget tests', () {
    testWidgets('Renders "AI Online" when online', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BackendStatusChip(status: BackendStatus.online),
          ),
        ),
      );

      expect(find.text('AI Online'), findsOneWidget);
    });

    testWidgets('Renders "AI Warming Up…" when offline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BackendStatusChip(status: BackendStatus.offline),
          ),
        ),
      );

      expect(find.text('AI Warming Up…'), findsOneWidget);
    });

    testWidgets('Renders "AI Degraded" when degraded', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BackendStatusChip(status: BackendStatus.degraded),
          ),
        ),
      );

      expect(find.text('AI Degraded'), findsOneWidget);
    });

    testWidgets('Renders "Checking AI…" when checking', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BackendStatusChip(status: BackendStatus.checking),
          ),
        ),
      );

      expect(find.text('Checking AI…'), findsOneWidget);
    });

    testWidgets('Tapping chip triggers onTap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BackendStatusChip(
              status: BackendStatus.online,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('AI Online'));
      expect(tapped, isTrue);
    });
  });
}
