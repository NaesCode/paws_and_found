import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:paws_and_found/features/map/data/models/map_report_model.dart';
import 'package:paws_and_found/shared/atoms/map_pin_badge.dart';
import 'package:paws_and_found/shared/organisms/location_pin_picker_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationPinPickerSheet Tests', () {
    testWidgets('renders header, coordinates chip and confirm button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationPinPickerSheet(
              initialLocation: const LatLng(14.5995, 120.9842),
              title: 'Pin Location on Animal Map',
              subtitle: 'Tap anywhere on the map to set the alert pin',
              pinStatus: 'missing',
              onLocationConfirmed: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify Header
      expect(find.text('Pin Location on Animal Map'), findsOneWidget);
      expect(find.text('Tap anywhere on the map to set the alert pin'), findsOneWidget);

      // Verify Coordinates pill
      expect(find.textContaining('Pinned at: 14.59950° N, 120.98420° E'), findsOneWidget);

      // Verify Missing Pin Badge 'M' is rendered
      expect(find.byType(MapPinBadge), findsOneWidget);
      expect(find.text('M'), findsOneWidget);

      // Verify Confirm Action Button
      expect(find.text('Confirm Pin Location'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('tapping Confirm Pin Location triggers callback with coordinates', (tester) async {
      LatLng? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationPinPickerSheet(
              initialLocation: const LatLng(14.6000, 120.9800),
              title: 'Pin Location on Animal Map',
              pinStatus: 'missing',
              onLocationConfirmed: (point) {
                result = point;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Confirm Pin Location'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.latitude, 14.6000);
      expect(result!.longitude, 120.9800);
    });
  });

  group('MapReportModel Dynamic Registration Tests', () {
    setUp(() {
      MapReportModel.clearDynamicReports();
    });

    tearDown(() {
      MapReportModel.clearDynamicReports();
    });

    test('addReport prepends newly created missing report to getMockReports', () {
      final initialCount = MapReportModel.getMockReports().length;

      final newMissingReport = MapReportModel(
        id: 'new-missing-001',
        reporterId: 'user_001',
        title: 'Buster',
        animalType: 'Canine',
        description: 'Lost near the fountain park.',
        status: 'missing',
        locationName: 'Fountain Park',
        latitude: 14.6100,
        longitude: 120.9900,
        normalizedX: 0.5,
        normalizedY: 0.5,
        createdAt: DateTime.now(),
        tags: const ['Canine', 'Missing'],
      );

      MapReportModel.addReport(newMissingReport);

      final reports = MapReportModel.getMockReports();
      expect(reports.length, initialCount + 1);
      expect(reports.first.id, 'new-missing-001');
      expect(reports.first.status, 'missing');
      expect(reports.first.latitude, 14.6100);
      expect(reports.first.longitude, 120.9900);
    });
  });
}

