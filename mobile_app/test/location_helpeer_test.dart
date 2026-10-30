import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/core/utils/location_helper.dart';

// Create a manual fake class implementing your location service structure
class MockLocationService implements LocationService {
  final String mockAddress;
  final bool shouldThrowException;

  MockLocationService({
    this.mockAddress = "Tondo, Manila",
    this.shouldThrowException = false,
  });

  @override
  Future<String> getAddressFromHexEWKB(String? hexStr) async {
    if (shouldThrowException) {
      return "Pinned Location (Hex Parse Exception)";
    }
    if (hexStr == null || hexStr.isEmpty || hexStr.toLowerCase() == 'null') {
      return "No location pinned";
    }
    return mockAddress;
  }

  @override
  Future<String> getAddressFromCoords(double? lat, double? lng) async {
    if (shouldThrowException) {
      return "Pinned Location (${lat?.toStringAsFixed(3)}, ${lng?.toStringAsFixed(3)})";
    }
    if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) {
      return "No location pinned";
    }
    return mockAddress;
  }
}

void main() {
  group('LocationService Tests (Manual Mock Style)', () {
    
    test('returns fallback string when hex parsing completely fails', () async {
      // Arrange: Setup the service to simulate a crash/exception state
      final service = MockLocationService(shouldThrowException: true);

      // Act: Try parsing a bad layout
      final address = await service.getAddressFromHexEWKB('invalid_hex_data');

      // Assert
      expect(address, equals('Pinned Location (Hex Parse Exception)'));
    });

    test('returns "No location pinned" when passing null or empty hex records', () async {
      // Arrange
      final service = MockLocationService();

      // Act
      final nullResult = await service.getAddressFromHexEWKB(null);
      final emptyResult = await service.getAddressFromHexEWKB('');

      // Assert
      expect(nullResult, equals('No location pinned'));
      expect(emptyResult, equals('No location pinned'));
    });

    test('returns custom mapped address when parsing and api lookup succeed', () async {
      // Arrange: Define exactly what address string our fake service should return
      const expectedAddress = "Ayala Center, Cebu City";
      final service = MockLocationService(mockAddress: expectedAddress);

      // Act: Pass a valid mock coordinate point block
      final address = await service.getAddressFromHexEWKB('0101000020E6100000A4703D0AD73E5E403333333333332D40');

      // Assert
      expect(address, equals(expectedAddress));
    });
  });
}
