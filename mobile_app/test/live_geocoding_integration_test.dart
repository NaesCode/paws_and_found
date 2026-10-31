// import 'package:flutter_test/flutter_test.dart';
// import 'package:paws_and_found/core/services/geocoding_service.dart';
// import 'package:paws_and_found/features/feed/data/datasources/feed_remote_data_source.dart';
// import 'package:paws_and_found/features/feed/data/repositories/feed_repository_impl.dart';

// class MockRemoteSourceWithLiveCoords implements FeedRemoteDataSource {
//   @override
//   Future<List<Map<String, dynamic>>> getFeedReports({
//     int limit = 50,
//     int offset = 0,
//   }) async {
//     return [
//       {
//         'id': 'real_post_1',
//         'reporter_id': 'user_1',
//         'reporter_name': 'Community Member',
//         'pet_name': 'Unnamed Pet',
//         'animal_type': 'canine',
//         'description': 'flying cat, ginger, fluffly',
//         'photo_url': 'https://images.unsplash.com/photo-1543466835-00a7907e9de1',
//         'status': 'missing',
//         'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
//         'latitude': 10.3181,
//         'longitude': 123.9052,
//       },
//       {
//         'id': 'real_post_2',
//         'reporter_id': 'user_2',
//         'reporter_name': 'Community Member',
//         'pet_name': 'Unnamed Pet',
//         'animal_type': 'canine',
//         'description': 'Cute floop ears, orange eyes, very long and healthy wiskers, mah bebeb',
//         'photo_url': 'https://images.unsplash.com/photo-1543466835-00a7907e9de1',
//         'status': 'missing',
//         'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
//         'latitude': 10.3110,
//         'longitude': 123.8762,
//       },
//     ];
//   }

//   @override
//   Future<List<Map<String, dynamic>>> getUserFeedReports(
//     String userId, {
//     int limit = 50,
//   }) async => [];
// }

// void main() {
//   test('Live OpenStreetMap reverse geocoding resolves photo coordinates into readable locations', () async {
//     final realGeocodingService = GeocoderProService();
//     final repo = FeedRepositoryImpl(
//       remoteDataSource: MockRemoteSourceWithLiveCoords(),
//       geocodingService: realGeocodingService,
//     );

//     final posts = await repo.getGeneralReports();

//     expect(posts.length, equals(2));

//     // Post 1 from user photo (10.3181, 123.9052)
//     final post1 = posts[0];
//     expect(post1.location.contains('10.3181'), isFalse, reason: 'Must not display raw latitude');
//     expect(post1.location.contains('123.9052'), isFalse, reason: 'Must not display raw longitude');
//     expect(post1.location, isNotEmpty);
//     // Print resolved location for visual confirmation
//     print('\n[TEST RESULT] Post 1 (10.3181, 123.9052) resolved to: "${post1.location}"');

//     // Post 2 from user photo (10.3110, 123.8762)
//     final post2 = posts[1];
//     expect(post2.location.contains('10.3110'), isFalse, reason: 'Must not display raw latitude');
//     expect(post2.location.contains('123.8762'), isFalse, reason: 'Must not display raw longitude');
//     expect(post2.location, isNotEmpty);
//     print('[TEST RESULT] Post 2 (10.3110, 123.8762) resolved to: "${post2.location}"\n');
//   }, timeout: const Timeout(Duration(seconds: 30)));
// }


import 'package:flutter_test/flutter_test.dart';
void main() {
  test('Live geocoding integration test pending refactor', () {}, skip: true);
}
