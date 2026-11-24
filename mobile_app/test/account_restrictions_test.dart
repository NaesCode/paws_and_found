import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:paws_and_found/core/services/location_service.dart';
import 'package:paws_and_found/core/services/user_restriction_service.dart';
import 'package:paws_and_found/features/profile/domain/entities/pet.dart';
import 'package:paws_and_found/features/profile/presentation/widgets/report_missing_sheet.dart';
import 'package:paws_and_found/features/report/presentation/providers/camera_report_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    const service = UserRestrictionService();
    await service.clearViolations('current_user');
  });

  tearDown(() async {
    const service = UserRestrictionService();
    await service.clearViolations('current_user');
  });

  group('CameraReportController Account Restrictions', () {
    test('blocks submission when account is suspended', () async {
      const restrictionService = UserRestrictionService();
      // Record 5 violations to suspend the account
      for (int i = 0; i < 5; i++) {
        await restrictionService.recordViolation(
          userId: 'current_user',
          prohibitedWord: 'buang',
        );
      }

      final controller = CameraReportController(
        restrictionService: restrictionService,
      );
      controller.descriptionController.text = 'Friendly brown dog found';

      final success = await controller.submitReport();
      expect(success, isFalse);
      expect(
        controller.errorMessage,
        contains('Your account has been suspended by administration'),
      );
    });

    test('blocks submission when description contains prohibited term', () async {
      const restrictionService = UserRestrictionService();
      final controller = CameraReportController(
        restrictionService: restrictionService,
      );
      controller.descriptionController.text = 'Ka buang ani nga iro oy';

      final success = await controller.submitReport();
      expect(success, isFalse);
      expect(controller.errorMessage, contains('prohibited language ("buang")'));
    });
  });

  group('ReportMissingSheet Account Restrictions', () {
    const testPet = Pet(
      petID: 'pet-uuid-001',
      name: 'Milo',
      species: 'Dog',
      breed: 'Golden Retriever',
      color: 'Golden',
      status: PetStatus.safe,
      photoURLs: ['https://example.com/pet.jpg'],
    );

    final testPosition = Position(
      latitude: 10.3157,
      longitude: 123.8854,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 10.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 1.0,
    );

    testWidgets('blocks missing report broadcast when account is suspended', (tester) async {
      const restrictionService = UserRestrictionService();
      for (int i = 0; i < 5; i++) {
        await restrictionService.recordViolation(
          userId: 'current_user',
          prohibitedWord: 'buang',
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportMissingSheet(
              pet: testPet,
              locationService: TestMockLocationService(
                isEnabled: true,
                mockPosition: testPosition,
              ),
              restrictionService: restrictionService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Broadcast Alert
      await tester.ensureVisible(find.text('Broadcast Alert'));
      await tester.tap(find.text('Broadcast Alert'));
      await tester.pumpAndSettle();

      // Alert dialog should appear stating account is suspended
      expect(find.text('Account Suspended'), findsOneWidget);
      expect(
        find.text('Your account has been suspended by administration. Suspended accounts cannot broadcast missing pet alerts.'),
        findsOneWidget,
      );

      // Tap OK
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Account Suspended'), findsNothing);
    });

    testWidgets('blocks missing report broadcast when note contains prohibited term', (tester) async {
      const restrictionService = UserRestrictionService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportMissingSheet(
              pet: testPet,
              locationService: TestMockLocationService(
                isEnabled: true,
                mockPosition: testPosition,
              ),
              restrictionService: restrictionService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter prohibited note
      final noteField = find.byType(TextField);
      expect(noteField, findsOneWidget);
      await tester.enterText(noteField, 'buang kaayo ni nga iro');
      await tester.pump();

      // Tap Broadcast Alert
      await tester.ensureVisible(find.text('Broadcast Alert'));
      await tester.tap(find.text('Broadcast Alert'));
      await tester.pumpAndSettle();

      // Community Warning dialog should appear
      expect(find.text('Community Warning'), findsOneWidget);
      expect(find.text('Detected: "buang"'), findsOneWidget);
    });
  });
}
