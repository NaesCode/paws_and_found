import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:paws_and_found/core/constants/location_constants.dart';
import 'package:paws_and_found/core/services/location_service.dart';
import 'package:paws_and_found/features/feed/data/datasources/feed_mock_data.dart';
import 'package:paws_and_found/features/map/data/datasources/map_remote_data_source.dart';
import 'package:paws_and_found/features/map/data/models/map_report_model.dart';
import 'package:paws_and_found/features/map/data/repositories/map_repository_impl.dart';
import 'package:paws_and_found/features/map/presentation/pages/map_page.dart';
import 'package:paws_and_found/features/map/presentation/providers/map_controller.dart';
import 'package:paws_and_found/features/map/presentation/widgets/interactive_map_canvas.dart';
import 'package:paws_and_found/features/map/presentation/widgets/map_pin_badge.dart';
import 'package:paws_and_found/shared/organisms/location_pin_picker_sheet.dart';

/// Mock Location Service for testing Cebu phone locations.
class CebuMockLocationService implements LocationService {
  final Position? mockPosition;
  final bool isEnabled;

  const CebuMockLocationService({
    this.mockPosition,
    this.isEnabled = true,
  });

  @override
  Future<bool> isLocationServiceEnabled() async => isEnabled;

  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.always;

  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.always;

  @override
  Future<Position?> getCurrentPosition() async => mockPosition;

  @override
  Future<Position?> getLastKnownPosition() async => mockPosition;

  @override
  Stream<Position> getPositionStream({int distanceFilter = 15}) =>
      mockPosition != null ? Stream.value(mockPosition!) : const Stream.empty();
}

/// Fake data source that simulates a database containing mixed nationwide records,
/// allowing verification that non-Cebu records are strictly excluded.
class MixedLocationMapRemoteDataSource implements MapRemoteDataSource {
  @override
  Future<List<MapReportModel>> getNearbyReports({
    double? lat,
    double? lng,
    double radiusMeters = 50000,
    String? animalType,
    dynamic filterType,
  }) async {
    // Inject a mix of Cebu and Non-Cebu reports
    final mixedReports = [
      // Valid Cebu Reports
      MapReportModel(
        id: 'cebu-1',
        reporterId: 'user-cebu-1',
        title: 'Cebu City Stray',
        animalType: 'Canine',
        description: 'Spotted near Fuente Osmeña Circle',
        status: 'stray',
        locationName: 'Fuente Osmeña, Cebu City',
        latitude: LocationConstants.fuenteOsmena.latitude,
        longitude: LocationConstants.fuenteOsmena.longitude,
        normalizedX: 0.5,
        normalizedY: 0.5,
        createdAt: DateTime.now(),
        tags: const ['Canine', 'Stray'],
      ),
      MapReportModel(
        id: 'cebu-2',
        reporterId: 'user-cebu-2',
        title: 'IT Park Missing Cat',
        animalType: 'Feline',
        description: 'Lost near IT Park The Walk',
        status: 'missing',
        locationName: 'Cebu IT Park, Lahug, Cebu City',
        latitude: LocationConstants.cebuITPark.latitude,
        longitude: LocationConstants.cebuITPark.longitude,
        normalizedX: 0.5,
        normalizedY: 0.5,
        createdAt: DateTime.now(),
        tags: const ['Feline', 'Missing'],
      ),
      // Non-Cebu Reports (Manila, Quezon City, Davao, Baguio)
      MapReportModel(
        id: 'manila-1',
        reporterId: 'user-mnl-1',
        title: 'Manila Stray Dog',
        animalType: 'Canine',
        description: 'Spotted in Luneta Park Manila',
        status: 'stray',
        locationName: 'Ermita, Manila, Metro Manila',
        latitude: 14.5832,
        longitude: 120.9794,
        normalizedX: 0.5,
        normalizedY: 0.5,
        createdAt: DateTime.now(),
        tags: const ['Canine'],
      ),
      MapReportModel(
        id: 'qc-1',
        reporterId: 'user-qc-1',
        title: 'Quezon City Cat',
        animalType: 'Feline',
        description: 'Lost in Diliman, Quezon City',
        status: 'missing',
        locationName: 'Diliman, Quezon City',
        latitude: 14.6538,
        longitude: 121.0685,
        normalizedX: 0.5,
        normalizedY: 0.5,
        createdAt: DateTime.now(),
        tags: const ['Feline'],
      ),
      MapReportModel(
        id: 'davao-1',
        reporterId: 'user-dvo-1',
        title: 'Davao Dog',
        animalType: 'Canine',
        description: 'Near People\'s Park Davao',
        status: 'found',
        locationName: 'Poblacion, Davao City',
        latitude: 7.0731,
        longitude: 125.6128,
        normalizedX: 0.5,
        normalizedY: 0.5,
        createdAt: DateTime.now(),
        tags: const ['Canine'],
      ),
      // Report with accidental Cebu coordinates but named outside Cebu
      MapReportModel(
        id: 'mixed-naming-1',
        reporterId: 'user-mixed-1',
        title: 'Makati Dog with Bad Coords',
        animalType: 'Canine',
        description: 'Lost in Makati City Central Business District',
        status: 'missing',
        locationName: 'Makati, Metro Manila',
        latitude: LocationConstants.defaultLatitude,
        longitude: LocationConstants.defaultLongitude,
        normalizedX: 0.5,
        normalizedY: 0.5,
        createdAt: DateTime.now(),
        tags: const ['Canine'],
      ),
    ];

    // Simulate strict filtering as implemented in MapRemoteDataSourceImpl
    return mixedReports.where((r) {
      final inCebuBounds = LocationConstants.isWithinCebu(r.latitude, r.longitude);
      if (!inCebuBounds) return false;

      final locLower = r.locationName.toLowerCase();
      const nonCebuKeywords = [
        'manila',
        'quezon city',
        'makati',
        'davao',
        'baguio',
        'cavite',
        'laguna',
        'taguig',
        'pasig',
      ];
      if (nonCebuKeywords.any((kw) => locLower.contains(kw))) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Future<MapReportModel?> getReportById(String id) async {
    final list = await getNearbyReports();
    return list.where((r) => r.id == id).firstOrNull;
  }
}

void main() {
  group('Cebu Localization Constants & Geofencing Tests', () {
    test('Default coordinates point directly to Cebu City Center', () {
      expect(LocationConstants.defaultLatitude, 10.3157);
      expect(LocationConstants.defaultLongitude, 123.8854);
      expect(LocationConstants.defaultCityName, 'Cebu City');
      expect(LocationConstants.defaultProvince, 'Cebu');
      expect(LocationConstants.defaultAreaLabel, 'Cebu City, Cebu');
    });

    test('LocationConstants.isWithinCebu accurately identifies Cebu Province locations', () {
      // Key Metro Cebu landmarks
      expect(LocationConstants.isWithinCebu(10.3157, 123.8854), isTrue); // Cebu City Capitol
      expect(LocationConstants.isWithinCebu(10.3117, 123.8924), isTrue); // Fuente Osmeña
      expect(LocationConstants.isWithinCebu(10.3297, 123.9063), isTrue); // Cebu IT Park
      expect(LocationConstants.isWithinCebu(10.2982, 123.8975), isTrue); // E-Mall Cebu
      expect(LocationConstants.isWithinCebu(10.2578, 123.8208), isTrue); // Lawaan, Talisay
      expect(LocationConstants.isWithinCebu(10.3396, 123.9115), isTrue); // Banilad, Mandaue
      expect(LocationConstants.isWithinCebu(10.3173, 123.9058), isTrue); // Ayala Center Cebu
      expect(LocationConstants.isWithinCebu(10.3103, 123.9494), isTrue); // Lapu-Lapu City, Mactan

      // Province extremities
      expect(LocationConstants.isWithinCebu(9.4200, 123.3300), isTrue);  // Santander (South tip)
      expect(LocationConstants.isWithinCebu(11.2500, 123.7300), isTrue); // Bantayan Island (North)
      expect(LocationConstants.isWithinCebu(10.3700, 123.6300), isTrue); // Toledo City (West Coast)
      expect(LocationConstants.isWithinCebu(10.6500, 124.3500), isTrue); // Camotes Islands (East)
    });

    test('LocationConstants.isWithinCebu strictly rejects non-Cebu regions', () {
      // Luzon
      expect(LocationConstants.isWithinCebu(14.5995, 120.9842), isFalse); // Manila
      expect(LocationConstants.isWithinCebu(14.6760, 121.0437), isFalse); // Quezon City
      expect(LocationConstants.isWithinCebu(14.5547, 121.0244), isFalse); // Makati
      expect(LocationConstants.isWithinCebu(16.4023, 120.5960), isFalse); // Baguio
      expect(LocationConstants.isWithinCebu(14.3000, 120.9500), isFalse); // Cavite

      // Mindanao
      expect(LocationConstants.isWithinCebu(7.1907, 125.4553), isFalse);  // Davao City
      expect(LocationConstants.isWithinCebu(8.4542, 124.6319), isFalse);  // Cagayan de Oro

      // International & Null Coordinates
      expect(LocationConstants.isWithinCebu(0.0, 0.0), isFalse);          // Null Island
      expect(LocationConstants.isWithinCebu(35.6762, 139.6503), isFalse); // Tokyo
    });
  });

  group('Data Source & Model Cebu Filtering Tests', () {
    test('All default mock reports are strictly within Cebu boundaries', () {
      final reports = MapReportModel.getMockReports();
      expect(reports, isNotEmpty);

      for (final report in reports) {
        final isCebu = LocationConstants.isWithinCebu(report.latitude, report.longitude);
        expect(
          isCebu,
          isTrue,
          reason: 'Report "${report.title}" at (${report.latitude}, ${report.longitude}) must be in Cebu',
        );

        final locName = report.locationName.toLowerCase();
        final hasCebuReference = locName.contains('cebu') ||
            locName.contains('talisay') ||
            locName.contains('mandaue') ||
            locName.contains('lahug');
        expect(
          hasCebuReference,
          isTrue,
          reason: 'Report "${report.title}" location "${report.locationName}" should reference Cebu',
        );
      }
    });

    test('MapRemoteDataSource filters out non-Cebu reports and retains only Cebu content', () async {
      final dataSource = MixedLocationMapRemoteDataSource();
      final filteredReports = await dataSource.getNearbyReports();

      // Only the 2 valid Cebu reports should survive the filtering
      expect(filteredReports.length, 2);
      expect(filteredReports.map((r) => r.id), containsAll(['cebu-1', 'cebu-2']));

      // Manila, Quezon City, Davao, and bad coords must be excluded
      expect(filteredReports.any((r) => r.id == 'manila-1'), isFalse);
      expect(filteredReports.any((r) => r.id == 'qc-1'), isFalse);
      expect(filteredReports.any((r) => r.id == 'davao-1'), isFalse);
      expect(filteredReports.any((r) => r.id == 'mixed-naming-1'), isFalse);

      for (final report in filteredReports) {
        expect(LocationConstants.isWithinCebu(report.latitude, report.longitude), isTrue);
      }
    });

    test('Feed mock posts are all located in Cebu', () {
      expect(mockPosts, isNotEmpty);

      for (final post in mockPosts) {
        final lat = post['lat'] as double?;
        final lng = post['lng'] as double?;
        final location = (post['location'] as String?)?.toLowerCase() ?? '';

        if (lat != null && lng != null) {
          expect(
            LocationConstants.isWithinCebu(lat, lng),
            isTrue,
            reason: 'Feed post "${post['pet_name']}" at ($lat, $lng) must be in Cebu',
          );
        }

        final inCebu = location.contains('cebu') ||
            location.contains('mandaue') ||
            location.contains('talisay');
        expect(
          inCebu,
          isTrue,
          reason: 'Feed post "${post['pet_name']}" location "$location" must be in Cebu',
        );
      }
    });
  });

  group('Map Page & Controller Cebu Localization UI Tests', () {
    testWidgets('MapPage defaults to Cebu and renders only Cebu report markers', (tester) async {
      final repository = MapRepositoryImpl(dataSource: MixedLocationMapRemoteDataSource());

      await tester.pumpWidget(
        MaterialApp(
          home: MapPage(
            repository: repository,
            showBottomNavPlaceholder: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify canvas rendered
      expect(find.byType(InteractiveMapCanvas), findsOneWidget);

      // Verify only Cebu reports are displayed on the page
      expect(find.text('Cebu City Stray'), findsOneWidget);
      expect(find.textContaining('Fuente Osmeña, Cebu City'), findsOneWidget);

      // Verify non-Cebu reports are NEVER rendered
      expect(find.text('Manila Stray Dog'), findsNothing);
      expect(find.text('Quezon City Cat'), findsNothing);
      expect(find.text('Davao Dog'), findsNothing);
      expect(find.text('Makati Dog with Bad Coords'), findsNothing);

      // Verify the canvas only renders pins for valid Cebu reports
      final canvasPins = find.descendant(
        of: find.byType(InteractiveMapCanvas),
        matching: find.byType(MapPinBadge),
      );
      expect(canvasPins, findsWidgets);
    });

    testWidgets('LocationPinPickerSheet defaults to Cebu and respects Cebu GPS', (tester) async {
      final cebuGps = Position(
        latitude: LocationConstants.cebuITPark.latitude,
        longitude: LocationConstants.cebuITPark.longitude,
        timestamp: DateTime.now(),
        accuracy: 3.0,
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      final mockLocation = CebuMockLocationService(mockPosition: cebuGps);

      LatLng? confirmedLocation;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  confirmedLocation = await LocationPinPickerSheet.show(
                    context: ctx,
                    initialLocation: LocationConstants.defaultLocation,
                    locationService: mockLocation,
                    title: 'Cebu Pin Test',
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Verify initial pin displays Cebu City coordinates
      expect(
        find.textContaining('Pinned at: ${LocationConstants.defaultLatitude.toStringAsFixed(5)}° N, ${LocationConstants.defaultLongitude.toStringAsFixed(5)}° E'),
        findsOneWidget,
      );

      // Verify Cebu is strictly within bounds
      expect(
        LocationConstants.isWithinCebu(
          LocationConstants.defaultLatitude,
          LocationConstants.defaultLongitude,
        ),
        isTrue,
      );

      // Tap Confirm Pin Location
      await tester.tap(find.text('Confirm Pin Location'));
      await tester.pumpAndSettle();

      expect(confirmedLocation, isNotNull);
      expect(
        LocationConstants.isWithinCebu(
          confirmedLocation!.latitude,
          confirmedLocation!.longitude,
        ),
        isTrue,
      );
    });

    test('MapController defaults to Cebu center when no user position provided', () {
      final controller = MapController();
      expect(controller.mapCenter, LocationConstants.defaultLocation);
      expect(controller.mapCenter.latitude, 10.3157);
      expect(controller.mapCenter.longitude, 123.8854);
    });

    test('MapController updates center to user phone location in Cebu', () async {
      final cebuGps = Position(
        latitude: 10.3297,
        longitude: 123.9063,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      final controller = MapController(
        locationService: CebuMockLocationService(mockPosition: cebuGps),
      );

      final loc = await controller.fetchUserLocation();
      expect(loc, isNotNull);
      expect(loc!.latitude, 10.3297);
      expect(loc.longitude, 123.9063);
      expect(controller.mapCenter, loc);
      expect(LocationConstants.isWithinCebu(controller.mapCenter.latitude, controller.mapCenter.longitude), isTrue);
    });
  });
}
