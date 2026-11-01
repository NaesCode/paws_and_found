import 'package:paws_and_found/features/feed/data/models/comment_model.dart';
import 'package:paws_and_found/features/feed/data/models/feed_post_model.dart';

abstract class FeedRepository {
  Future<List<FeedPost>> getPersonalReports(String userId, {String? filterStatus});
  Future<List<FeedPost>> getGeneralReports(String userId, {String? filterStatus, bool sortOldest = false});
  Future<FeedPost?> getReportById(String reportId);
  Future<List<FeedComment>> getComments(String reportId);
  Future<FeedComment> addComment(String reportId, String content, {String? parentId});
  Future<List<FeedPost>> getLinkedSightings(String reportId);
}
