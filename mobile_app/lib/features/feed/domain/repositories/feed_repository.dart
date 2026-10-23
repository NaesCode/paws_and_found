import '../entities/feed_post.dart';

abstract class FeedRepository {
  Future<List<FeedPost>> getGeneralReports();
  Future<List<FeedPost>> getPersonalReports(String currentUserId);
}
