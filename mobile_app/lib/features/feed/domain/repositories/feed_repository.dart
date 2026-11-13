import 'package:paws_and_found/features/feed/data/models/comment_model.dart';
import 'package:paws_and_found/features/feed/data/models/feed_post_model.dart';
import 'dart:typed_data';

abstract class FeedRepository {
  Future<List<FeedPost>> getPersonalReports(String userId, {String? filterStatus});
  Future<List<FeedPost>> getGeneralReports(String userId, {String? filterStatus, bool sortOldest = false});
  Future<FeedPost?> getReportById(String reportId);
  Future<List<FeedComment>> getComments(String reportId);
  Future<FeedComment> addComment(String reportId, String content, {String? parentId});
  Future<List<FeedPost>> getLinkedSightings(String reportId);
  Future<void> deleteReport(String reportId, {String? reason, String? details});
  Future<String> uploadReportPhoto(Uint8List bytes, {String extension = 'jpg'});
  Future<void> updateReport(
    String reportId, {
      String? description,
      String? locationName,
      String? status,
      String? animalType,
      String? photoUrl,
      String? petId,
      String? petName,
      double? lat,
      double? lng,
      String? specie,
    }
  );
}
