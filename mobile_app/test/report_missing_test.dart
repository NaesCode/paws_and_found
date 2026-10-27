import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:paws_and_found/core/services/location_service.dart';
import 'package:paws_and_found/features/profile/domain/entities/pet.dart';
import 'package:paws_and_found/features/profile/presentation/widgets/report_missing_sheet.dart';

class TestMockLocationService implements LocationService {
  final bool isEnabled;
  final Position? mockPosition;

  TestMockLocationService({
    this.isEnabled = true,
    this.mockPosition,
  });

  @override
  Future<bool> isLocationServiceEnabled() async => isEnabled;

  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.always;

  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.always;

  @override
  Future<Position?> getCurrentPosition() async => isEnabled ? mockPosition : null;

  @override
  Future<Position?> getLastKnownPosition() async => isEnabled ? mockPosition : null;

  @override
  Stream<Position> getPositionStream({int distanceFilter = 15}) {
    if (mockPosition != null) {
      return Stream.value(mockPosition!);
    }
    return const Stream.empty();
  }
}

void main() {
  final testPet = Pet(
    petID: 'pet-123',
    name: 'Mochi',
    species: 'Cat',
    breed: 'Calico',
    description: 'Very gentle and friendly',
    status: PetStatus.safe,
    photoURLs: const [],
  );

  final testPosition = Position(
    latitude: 14.5547,
    longitude: 121.0244,
    timestamp: DateTime.now(),
    accuracy: 5.0,
    altitude: 10.0,
    altitudeAccuracy: 1.0,
    heading: 0.0,
    headingAccuracy: 1.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );

  group('ReportMissingSheet Widget Tests', () {
    testWidgets('renders pet details and acquires GPS coordinates', (tester) async {
      final mockLocation = TestMockLocationService(
        isEnabled: true,
        mockPosition: testPosition,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportMissingSheet(
              pet: testPet,
              locationService: mockLocation,
            ),
          ),
        ),
      );

      // Verify header and pet details
      expect(find.text('Report Mochi Missing'), findsOneWidget);
      expect(find.text('Mochi'), findsOneWidget);
      expect(find.text('Cat • Calico'), findsOneWidget);
      expect(find.text('MISSING'), findsOneWidget);

      // Pump to allow async GPS acquisition to finish
      await tester.pumpAndSettle();

      // Verify coordinates displayed
      expect(find.text('14.5547° N, 121.0244° E'), findsOneWidget);
      expect(find.text('Device GPS Location'), findsOneWidget);
      expect(find.text('Broadcast Alert'), findsOneWidget);
    });

    testWidgets('falls back gracefully when GPS hardware is disabled', (tester) async {
      final mockLocation = TestMockLocationService(
        isEnabled: false,
        mockPosition: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportMissingSheet(
              pet: testPet,
              locationService: mockLocation,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Displays default fallback coordinates
      expect(find.text('10.3157° N, 123.8854° E'), findsOneWidget);
      expect(find.text('Hardware GPS unavailable (Default Cebu City)'), findsOneWidget);
    });

    testWidgets('submitting returns ReportMissingResult with coordinates and note', (tester) async {
      final mockLocation = TestMockLocationService(
        isEnabled: true,
        mockPosition: testPosition,
      );

      ReportMissingResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ReportMissingSheet.show(
                    context: context,
                    pet: testPet,
                    locationService: mockLocation,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      // Tap button to open bottom sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Enter last seen details
      final noteField = find.byType(TextField);
      expect(noteField, findsOneWidget);
      await tester.enterText(noteField, 'Last seen near the neighborhood park at 5 PM');
      await tester.pump();

      // Tap Broadcast Alert
      await tester.ensureVisible(find.text('Broadcast Alert'));
      await tester.tap(find.text('Broadcast Alert'));
      await tester.pumpAndSettle();

      // Verify result
      expect(result, isNotNull);
      expect(result!.latitude, 14.5547);
      expect(result!.longitude, 121.0244);
      expect(result!.note, 'Last seen near the neighborhood park at 5 PM');
    });

    testWidgets('cancelling returns null', (tester) async {
      final mockLocation = TestMockLocationService(
        isEnabled: true,
        mockPosition: testPosition,
      );

      ReportMissingResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ReportMissingSheet.show(
                    context: context,
                    pet: testPet,
                    locationService: mockLocation,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
