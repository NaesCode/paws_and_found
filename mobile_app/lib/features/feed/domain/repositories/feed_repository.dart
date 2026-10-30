import 'package:paws_and_found/features/feed/data/models/feed_post_model.dart';
abstract class FeedRepository {
  Future<List<FeedPost>> getPersonalReports(String userId, {String? filterStatus});
  Future<List<FeedPost>> getGeneralReports(String userId, {String? filterStatus, bool sortOldest = false}); 
}
