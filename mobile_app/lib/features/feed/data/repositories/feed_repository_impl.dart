import '../../domain/entities/feed_post.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_mock_data.dart';
import '../datasources/feed_remote_data_source.dart';
import '../models/feed_post_model.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDataSource _remoteDataSource;

  FeedRepositoryImpl({FeedRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? FeedRemoteDataSourceImpl();

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
    // 1. Attempt to fetch live community reports from the Supabase view
    try {
      final remoteRows = await _remoteDataSource.getFeedReports();
      if (remoteRows.isNotEmpty) {
        return remoteRows.map(PetPostModel.fromJson).toList();
      }
    } catch (_) {
      // Fallback below
    }

    // 2. Fallback to calibrated local mock data if offline or remote returns empty
    await Future.delayed(const Duration(milliseconds: 300));
    return _joinAndMapReports(mockPosts);
  }

  @override
  Future<List<FeedPost>> getPersonalReports(String currentUserId) async {
    // 1. Attempt to fetch user's live reports from Supabase
    try {
      final remoteRows = await _remoteDataSource.getUserFeedReports(currentUserId);
      if (remoteRows.isNotEmpty) {
        return remoteRows.map(PetPostModel.fromJson).toList();
      }
    } catch (_) {
      // Fallback below
    }

    // 2. Fallback to calibrated local mock data
    await Future.delayed(const Duration(milliseconds: 300));
    final List<Map<String, dynamic>> userSpecificPosts = mockPosts
        .where((post) => post['user_id'] == currentUserId)
        .toList();

    return _joinAndMapReports(userSpecificPosts);
  }
}
