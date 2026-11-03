import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/features/feed/data/models/comment_model.dart';

void main() {
  group('FeedComment & Embedded Sighting Link Tests', () {
    test('extracts linkedReportId correctly from standard pawsandfound URLs', () {
      final comment = FeedComment(
        id: 'c-1',
        postId: 'post-1',
        userId: 'user-1',
        content: 'I saw this dog! https://pawsandfound.org/report/3f24ddf7-1f99-45f9-87c6-8136c030e263',
        createdAt: DateTime.now(),
      );

      expect(comment.linkedReportId, equals('3f24ddf7-1f99-45f9-87c6-8136c030e263'));
      expect(comment.cleanContent, equals('I saw this dog!'));
    });

    test('extracts linkedReportId from custom pawsandfound scheme', () {
      final comment = FeedComment(
        id: 'c-2',
        postId: 'post-1',
        userId: 'user-2',
        content: 'Check sighting: pawsandfound://report/d785589d-e3bf-407b-85d9-57d4b24591e5',
        createdAt: DateTime.now(),
      );

      expect(comment.linkedReportId, equals('d785589d-e3bf-407b-85d9-57d4b24591e5'));
      expect(comment.cleanContent, equals('Check sighting:'));
    });

    test('returns null linkedReportId for standard comments without links', () {
      final comment = FeedComment(
        id: 'c-3',
        postId: 'post-1',
        userId: 'user-3',
        content: 'I hope the owner finds him soon!',
        createdAt: DateTime.now(),
      );

      expect(comment.linkedReportId, isNull);
      expect(comment.cleanContent, equals('I hope the owner finds him soon!'));
    });

    test('cleanContent provides default message if comment text was only the link', () {
      final comment = FeedComment(
        id: 'c-4',
        postId: 'post-1',
        userId: 'user-4',
        content: 'https://pawsandfound.org/report/3f24ddf7-1f99-45f9-87c6-8136c030e263',
        createdAt: DateTime.now(),
      );

      expect(comment.linkedReportId, equals('3f24ddf7-1f99-45f9-87c6-8136c030e263'));
      expect(comment.cleanContent, equals('Reported an animal sighting below:'));
    });
  });
}
