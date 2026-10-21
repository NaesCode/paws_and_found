import '../../domain/entities/feed_post.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_mock_data.dart';
import '../models/feed_post_model.dart';

class FeedRepositoryImpl implements FeedRepository {
  List<PetPostModel> _joinAndMapReports(List<Map<String, dynamic>> rawPostList) {
    return rawPostList.map((postRaw) {
      final Map<String, dynamic> userRaw = mockUsers.firstWhere(
        (user) => user['id'] == postRaw['user_id'],
        orElse: () => <String, dynamic>{},
      );

      return PetPostModel.fromJoinedData(
        postRaw,
        userRaw.isEmpty ? null : userRaw,
      );
    }).toList();
  }

  @override
  Future<List<FeedPost>> getGeneralReports() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _joinAndMapReports(mockPosts);
  }

  @override
  Future<List<FeedPost>> getPersonalReports(String currentUserId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final List<Map<String, dynamic>> userSpecificPosts = mockPosts
        .where((post) => post['user_id'] == currentUserId)
        .toList();

    return _joinAndMapReports(userSpecificPosts);
  }
}
