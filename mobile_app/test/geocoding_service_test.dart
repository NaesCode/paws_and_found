import 'package:flutter_test/flutter_test.dart';
import 'package:geocoder_pro/geocoder_pro.dart';
import 'package:paws_and_found/core/services/geocoding_service.dart';

class MockGeocoder implements BaseGeocoder {
  int callCount = 0;
  GeoData? mockResult;
  bool shouldThrow = false;

  @override
  Future<GeoData?> getDataFromCoordinates({
    required double latitude,
    required double longitude,
    String? language,
  }) async {
    callCount++;
    if (shouldThrow) throw Exception('Network timeout from Nominatim');
    return mockResult;
  }

  @override
  Future<GeoData?> getDataFromAddress(String address, {String? language}) async {
    callCount++;
    if (shouldThrow) throw Exception('Address not found');
    return mockResult;
  }

  @override
  Future<List<GeoData>> getAddressesFromCoordinates({
    required double latitude,
    required double longitude,
    String? language,
  }) async => mockResult != null ? [mockResult!] : [];

  @override
  Future<List<GeoData>> getAddressesFromAddress(
    String address, {
    String? language,
  }) async => mockResult != null ? [mockResult!] : [];
}

void main() {
  group('GeocoderProService Tests', () {
    late MockGeocoder mockGeocoder;
    late GeocoderProService service;

    setUp(() {
      mockGeocoder = MockGeocoder();
      service = GeocoderProService(geocoder: mockGeocoder);
    });

    test('reverseGeocode formats subLocality and city cleanly', () async {
      mockGeocoder.mockResult = const GeoData(
        address: 'Kasambagan, Cebu City, Cebu',
        city: 'Cebu City',
        country: 'Philippines',
        latitude: 10.3200,
        longitude: 123.9050,
        postalCode: '6000',
        state: 'Cebu',
        countryCode: 'PH',
        streetNumber: '',
        subLocality: 'Kasambagan',
      );

      final result = await service.reverseGeocode(10.3200, 123.9050);
      expect(result, equals('Kasambagan, Cebu City'));
      expect(mockGeocoder.callCount, equals(1));
    });

    test('reverseGeocode prioritizes high-accuracy POI and streets', () async {
      mockGeocoder.mockResult = const GeoData(
        address: 'V. Padriga Street, Cebu I.T. Park',
        city: 'Cebu City',
        country: 'Philippines',
        latitude: 10.3297,
        longitude: 123.9063,
        postalCode: '6000',
        state: 'Central Visayas',
        countryCode: 'PH',
        streetNumber: '',
        street: 'V. Padriga Street',
        subLocality: 'Kasambagan',
        raw: {
          'address': {
            'road': 'V. Padriga Street',
            'commercial': 'Cebu I.T. Park',
            'suburb': 'Kasambagan',
            'city': 'Cebu City',
          }
        },
      );

      final result = await service.reverseGeocode(10.3297, 123.9063);
      expect(result, equals('Cebu I.T. Park, Kasambagan'));
    });

    test('reverseGeocode caches result for subsequent nearby queries within ~11m', () async {
      mockGeocoder.mockResult = const GeoData(
        address: 'Banilad, Cebu City',
        city: 'Cebu City',
        country: 'Philippines',
        latitude: 10.3400,
        longitude: 123.9100,
        postalCode: '6000',
        state: 'Cebu',
        countryCode: 'PH',
        streetNumber: '',
        subLocality: 'Banilad',
      );

      // First call invokes geocoder
      final first = await service.reverseGeocode(10.3400, 123.9100);
      expect(first, equals('Banilad, Cebu City'));
      expect(mockGeocoder.callCount, equals(1));

      // Second call at identical coordinates hits in-memory cache
      final second = await service.reverseGeocode(10.3400, 123.9100);
      expect(second, equals('Banilad, Cebu City'));
      expect(mockGeocoder.callCount, equals(1)); // count NOT incremented
    });

    test('reverseGeocode handles errors defensively without throwing', () async {
      mockGeocoder.shouldThrow = true;

      final result = await service.reverseGeocode(10.0, 120.0);
      expect(result, isNull);
    });

    test('formatConciseAddress falls back across granularity levels', () {
      // 1. Street + City when subLocality is empty
      const streetData = GeoData(
        address: '',
        city: 'Cebu City',
        country: 'Philippines',
        latitude: 10.0,
        longitude: 123.0,
        postalCode: '6000',
        state: 'Cebu',
        countryCode: 'PH',
        streetNumber: '42',
        street: 'Salinas Drive',
      );
      expect(
        GeocoderProService.formatConciseAddress(streetData),
        equals('Salinas Drive, Cebu City'),
      );

      // 2. City + State when street and subLocality are empty
      const cityStateData = GeoData(
        address: '',
        city: 'Mandaue City',
        country: 'Philippines',
        latitude: 10.33,
        longitude: 123.93,
        postalCode: '6014',
        state: 'Cebu',
        countryCode: 'PH',
        streetNumber: '',
      );
      expect(
        GeocoderProService.formatConciseAddress(cityStateData),
        equals('Mandaue City, Cebu'),
      );

      // 3. Formatted address segments fallback
      const segmentsData = GeoData(
        address: 'IT Park, Apas, Cebu City',
        formattedAddress: 'IT Park, Apas, Cebu City',
        city: '',
        country: 'Philippines',
        latitude: 10.33,
        longitude: 123.93,
        postalCode: '',
        state: '',
        countryCode: 'PH',
        streetNumber: '',
      );
      expect(
        GeocoderProService.formatConciseAddress(segmentsData),
        equals('IT Park, Apas'),
      );
    });

    test('distanceBetween and formatDistance calculate accurately', () {
      // Distance between two points in Cebu City (~550 meters)
      final dist = service.distanceBetween(10.3157, 123.8854, 10.3200, 123.8880);
      expect(dist, greaterThan(400));
      expect(dist, lessThan(700));

      // Formatting
      expect(service.formatDistance(450), equals('450 m'));
      expect(service.formatDistance(2500), equals('2.5 km'));
    });
  });
}
