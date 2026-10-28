import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/features/feed/data/datasources/feed_remote_data_source.dart';
import 'package:paws_and_found/features/feed/data/models/feed_post_model.dart';
import 'package:paws_and_found/features/feed/data/repositories/feed_repository_impl.dart';

class MockFeedRemoteDataSource implements FeedRemoteDataSource {
  final List<Map<String, dynamic>> mockRemoteReports;
  final bool shouldThrow;

  MockFeedRemoteDataSource({
    this.mockRemoteReports = const [],
    this.shouldThrow = false,
  });

  @override
  Future<List<Map<String, dynamic>>> getFeedReports({
    int limit = 50,
    int offset = 0,
  }) async {
    if (shouldThrow) throw Exception('Network error');
    return mockRemoteReports;
  }

  @override
  Future<List<Map<String, dynamic>>> getUserFeedReports(
    String userId, {
    int limit = 50,
  }) async {
    if (shouldThrow) throw Exception('Network error');
    return mockRemoteReports.where((r) => r['reporter_id'] == userId).toList();
  }
}

void main() {
  group('PostGIS Coordinate Unpacking & Sanitization Tests', () {
    test('Converts raw PostGIS EWKB hex string into readable coordinates', () {
      // Hex string straight from the user\'s PostGIS database
      const rawHexEWKB = '0101000020E6100000492EFF21FD3E5E406DE7FBA9F1322D40';

      final rawDatabaseRow = {
        'id': '1d9a923b-9121-4968-9e59-07870fddb191',
        'reporter_id': '5533261d-53e5-4950-8548-37f0b9afa039',
        'reporter_name': 'Alex Rivera',
        'pet_id': null,
        'pet_name': 'Meowki',
        'animal_type': 'Cat',
        'description': 'Her name is Meowki.',
        'photo_url': 'https://example.com/meowki.jpg',
        'location': rawHexEWKB, // RAW MACHINE CODE FROM DATABASE
        'status': 'missing',
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'latitude': 14.5995,
        'longitude': 120.9842,
      };

      final post = PetPostModel.fromJson(rawDatabaseRow);

      // Verify the UI will NEVER display the raw hex machine code
      expect(post.location.contains('01010000'), isFalse);
      expect(post.location, equals('14.5995, 120.9842'));

      // Verify coordinate fields are accessible as numeric values
      expect(post.latitude, equals(14.5995));
      expect(post.longitude, equals(120.9842));
      expect(post.petName, equals('Meowki'));
      expect(post.postedBy, equals('Alex Rivera'));
    });

    test('Preserves human-readable address if location is already a street name', () {
      final rawRowWithAddress = {
        'id': 'post_101',
        'reporter_name': 'John Doe',
        'pet_name': 'Luna',
        'animal_type': 'Dog',
        'location': 'Lahug, Cebu City (Near IT Park)',
        'description': 'Friendly golden retriever.',
        'photo_url': 'https://example.com/luna.jpg',
        'status': 'missing',
        'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'latitude': 10.3297,
        'longitude': 123.9063,
      };

      final post = PetPostModel.fromJson(rawRowWithAddress);

      // Text address should be preserved
      expect(post.location, equals('Lahug, Cebu City (Near IT Park)'));
      expect(post.latitude, equals(10.3297));
      expect(post.longitude, equals(123.9063));
    });

    test('FeedRepository fetches live reports when remote data source returns rows', () async {
      final mockData = [
        {
          'id': 'report_live_1',
          'reporter_id': 'user_1',
          'reporter_name': 'Sarah Labra',
          'pet_name': 'Rocky',
          'animal_type': 'Dog',
          'location': '0101000020E61000003184526A65F85E4056140A6C29972440',
          'description': 'Seen near Guadalupe church',
          'photo_url': 'https://example.com/rocky.jpg',
          'status': 'spotted',
          'created_at': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
          'latitude': 10.3242,
          'longitude': 123.8821,
        }
      ];

      final repo = FeedRepositoryImpl(
        remoteDataSource: MockFeedRemoteDataSource(mockRemoteReports: mockData),
      );

      final reports = await repo.getGeneralReports();

      expect(reports, isNotEmpty);
      expect(reports.first.id, equals('report_live_1'));
      expect(reports.first.postedBy, equals('Sarah Labra'));
      expect(reports.first.location, equals('10.3242, 123.8821'));
      expect(reports.first.latitude, equals(10.3242));
      expect(reports.first.longitude, equals(123.8821));
    });

    test('FeedRepository smoothly falls back to mock data when network fails', () async {
      final repo = FeedRepositoryImpl(
        remoteDataSource: MockFeedRemoteDataSource(shouldThrow: true),
      );

      final reports = await repo.getGeneralReports();

      // Gracefully returns mock data instead of crashing
      expect(reports, isNotEmpty);
      expect(reports.first.petName, isNotEmpty);
    });
  });
}
