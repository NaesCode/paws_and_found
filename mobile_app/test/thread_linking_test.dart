import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/features/feed/data/models/comment_model.dart';
import 'package:paws_and_found/features/feed/data/models/feed_post_model.dart';
import 'package:paws_and_found/features/feed/domain/repositories/feed_repository.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_card_comments.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_comments_modal.dart';

class _FakeFeedRepo implements FeedRepository {
  final List<FeedComment> comments = const [];
  final List<FeedPost> sightings;

  _FakeFeedRepo({this.sightings = const []});

  @override
  Future<List<FeedComment>> getComments(String reportId) async => comments;

  @override
  Future<List<FeedPost>> getLinkedSightings(String reportId) async => sightings;

  @override
  Future<FeedPost?> getReportById(String reportId) async => null;

  @override
  Future<List<FeedPost>> getGeneralReports(String userId, {String? filterStatus, bool sortOldest = false}) async => [];

  @override
  Future<List<FeedPost>> getPersonalReports(String userId, {String? filterStatus}) async => [];

  @override
  Future<FeedComment> addComment(String reportId, String content, {String? parentId}) async =>
      FeedComment(id: 'c-new', postId: reportId, userId: 'u-1', content: content, createdAt: DateTime.now());

  @override
  Future<void> deleteComment(String commentId) async {}

  @override
  Future<void> deleteReport(String reportId, {String? reason, String? details}) async {}

  @override
  Future<List<FeedPost>> getGeneralReportsNearMe(String userId, {required double lat, required double lng, double? radiusMeters = 5000}) async => [];

  @override
  Future<bool> hasActiveClaimByOther(String reportId, String currentUserId) async => false;

  @override
  Future<void> markReportAsFound(String reportId) async {}

  @override
  Future<FeedComment> updateComment(String commentId, String content) async =>
      FeedComment(id: commentId, postId: 'p-1', userId: 'u-1', content: content, createdAt: DateTime.now());

  @override
  Future<void> updateReport(String reportId, {String? description, String? locationName, String? status, String? animalType, String? photoUrl, String? petId, String? petName, double? lat, double? lng, String? specie}) async {}

  @override
  Future<String> uploadReportPhoto(Uint8List bytes, {String extension = 'jpg'}) async => '';
}

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

  group('Thread to Post Redirection Widget Tests', () {
    testWidgets('FeedCardComments renders clickable View Linked Sighting Post button when linkedReportId is present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedCardComments(
              commentText: 'Check out this report!',
              timeAgo: '5m ago',
              username: 'Maria Santos',
              linkedReportId: 'report-uuid-999',
            ),
          ),
        ),
      );

      expect(find.text('Check out this report!'), findsOneWidget);
      expect(find.text('View Linked Sighting Post →'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_linked_report_report-uuid-999')), findsOneWidget);
    });

    testWidgets('FeedCommentsModal Sightings Log renders both View Post and View Map buttons for each sighting', (tester) async {
      final fakeRepo = _FakeFeedRepo(
        sightings: [
          FeedPost(
            id: 'sighting-uuid-123',
            reporterId: 'user-spotter',
            username: 'Carlo G.',
            location: 'Cebu IT Park',
            species: 'Dog',
            petName: 'Rocky',
            status: 'stray',
            analysisStatus: 'completed',
            createdAt: DateTime.now(),
            description: '[AI Match: 92%] Spotted near The Walk',
            imageUrl: '',
            userImageUrl: '',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCommentsModal(
              reportId: 'missing-report-001',
              petName: 'Rocky',
              initialTab: 0,
              repository: fakeRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Sightings tab shows the sighting with both View Post and View Map buttons
      expect(find.text('Spotted by Carlo G.'), findsOneWidget);
      expect(find.text('92% Match'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_sighting_view_post_sighting-uuid-123')), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_sighting_view_map_sighting-uuid-123')), findsOneWidget);
      expect(find.text('View Post'), findsOneWidget);
      expect(find.text('View Map'), findsOneWidget);
    });
  });
}
