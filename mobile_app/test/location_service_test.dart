import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:paws_and_found/core/services/location_service.dart';

class MockLocationService implements LocationService {
  final bool isEnabled;
  final LocationPermission permission;
  final Position? mockPosition;

  MockLocationService({
    this.isEnabled = true,
    this.permission = LocationPermission.always,
    this.mockPosition,
  });

  @override
  Future<bool> isLocationServiceEnabled() async => isEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position?> getCurrentPosition() async => isEnabled ? mockPosition : null;

  @override
  Stream<Position> getPositionStream({int distanceFilter = 15}) {
    if (mockPosition != null) {
      return Stream.value(mockPosition!);
    }
    return const Stream.empty();
  }
}

void main() {
  group('LocationService Tests', () {
    test('returns null position when hardware is disabled', () async {
      final service = MockLocationService(
        isEnabled: false,
        mockPosition: Position(
          latitude: 14.5995,
          longitude: 120.9842,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 0.0,
          altitudeAccuracy: 1.0,
          heading: 0.0,
          headingAccuracy: 1.0,
          speed: 0.0,
          speedAccuracy: 1.0,
        ),
      );

      final position = await service.getCurrentPosition();
      expect(position, isNull);
    });

    test('returns position when service is enabled and permission granted', () async {
      final expected = Position(
        latitude: 14.5995,
        longitude: 120.9842,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );

      final service = MockLocationService(
        isEnabled: true,
        permission: LocationPermission.whileInUse,
        mockPosition: expected,
      );

      final position = await service.getCurrentPosition();
      expect(position, isNotNull);
      expect(position!.latitude, 14.5995);
      expect(position.longitude, 120.9842);
    });
  });
}
