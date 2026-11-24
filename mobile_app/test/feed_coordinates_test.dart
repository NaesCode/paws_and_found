import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/features/feed/data/models/feed_post_model.dart';

void main() {
  group('FeedPost Location & Coordinate Parsing Tests', () {
    test('Unpacks PostGIS EWKB hex string and resolves to Cebu City when location_name is null', () {
      // EWKB for Point(123.8854, 10.3157, 4326) - Cebu City
      // Byte 0: 01
      // Type: 01000020 (Point with SRID)
      // SRID: E6100000 (4326)
      // X (lng): 123.8854
      // Y (lat): 10.3157
      const cebuHexEWKB = '0101000020E61000003184526A65F85E4056140A6C29972440';

      final rawDatabaseRow = {
        'id': '1d9a923b-9121-4968-9e59-07870fddb191',
        'reporter_id': '5533261d-53e5-4950-8548-37f0b9afa039',
        'profiles': {'name': 'Alex Rivera'},
        'animal_name': 'Mingay',
        'animal_type': 'Cat',
        'description': '[Mobility: roaming]',
        'photo_url': 'https://example.com/mingay.jpg',
        'location': cebuHexEWKB,
        'location_name': null, // NULL in database just like Mingay!
        'status': 'missing',
        'created_at': DateTime.now().subtract(const Duration(hours: 19)).toIso8601String(),
      };

      final post = FeedPost.fromJson(rawDatabaseRow);

      // Verify location is NOT empty and does NOT say 'No location pinned'
      expect(post.location, isNotEmpty);
      expect(post.location, equals('Cebu City'));
      expect(post.latitude, isNotNull);
      expect(post.longitude, isNotNull);
      expect((post.latitude! - 10.295).abs() < 0.01, isTrue);
      expect((post.longitude! - 123.881).abs() < 0.01, isTrue);
    });

    test('Preserves human-readable location_name when already set in database', () {
      final rawRowWithAddress = {
        'id': 'post_101',
        'profiles': {'name': 'John Doe'},
        'pets': {'name': 'Luna'},
        'animal_type': 'Dog',
        'location_name': 'Lahug, Cebu City (Near IT Park)',
        'description': 'Friendly golden retriever.',
        'photo_url': 'https://example.com/luna.jpg',
        'status': 'missing',
        'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'latitude': 10.3297,
        'longitude': 123.9063,
      };

      final post = FeedPost.fromJson(rawRowWithAddress);

      expect(post.location, equals('Lahug, Cebu City (Near IT Park)'));
      expect(post.latitude, equals(10.3297));
      expect(post.longitude, equals(123.9063));
    });

    test('Parses GeoJSON coordinates when location is a Map', () {
      final rawRowWithGeoJson = {
        'id': 'post_102',
        'animal_name': 'Bruno',
        'animal_type': 'Dog',
        'location': {
          'type': 'Point',
          'coordinates': [123.8933, 10.2993],
        },
        'location_name': '',
        'status': 'found',
        'created_at': DateTime.now().toIso8601String(),
      };

      final post = FeedPost.fromJson(rawRowWithGeoJson);

      expect(post.location, equals('Cebu City'));
      expect(post.latitude, closeTo(10.2993, 0.001));
      expect(post.longitude, closeTo(123.8933, 0.001));
    });
  });
}
