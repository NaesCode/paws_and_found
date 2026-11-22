import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/core/services/user_restriction_service.dart';
import 'package:paws_and_found/features/feed/presentation/widgets/feed_comments_modal.dart';
import 'package:paws_and_found/shared/molecules/community_warning_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    const service = UserRestrictionService();
    await service.clearViolations('current_user');
  });

  tearDown(() async {
    const service = UserRestrictionService();
    await service.clearViolations('current_user');
  });

  group('FeedCommentsModal Moderation & Restriction Tests', () {
    testWidgets('entering prohibited word "buang" blocks comment and triggers CommunityWarningDialog', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedCommentsModal(
              reportId: 'test-report-uuid',
              petName: 'Thomas',
              initialTab: 1, // Chat Tab
              reporterName: 'Sean Tads',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the comment input field
      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);

      // Enter prohibited word
      await tester.enterText(inputField, 'Grabe ka buang ani oy');
      await tester.pumpAndSettle();

      // Tap Send (Paper Plane icon)
      final sendButton = find.byIcon(Icons.send_rounded);
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Community Warning dialog should appear
      expect(find.byType(CommunityWarningDialog), findsOneWidget);
      expect(find.text('Community Warning'), findsOneWidget);
      expect(find.text('Detected: "buang"'), findsOneWidget);
      expect(
        find.text('Warning: Continued use of prohibited language will result in account suspension (1 violations recorded).'),
        findsOneWidget,
      );

      // Dismiss dialog
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();
      expect(find.byType(CommunityWarningDialog), findsNothing);
    });

    testWidgets('after 5 violations, comment input is locked with suspension banner', (tester) async {
      const service = UserRestrictionService();
      // Record 5 violations to trigger suspension
      for (int i = 0; i < 5; i++) {
        await service.recordViolation(userId: 'current_user', prohibitedWord: 'buang');
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedCommentsModal(
              reportId: 'test-report-uuid',
              petName: 'Thomas',
              initialTab: 1, // Chat Tab
              reporterName: 'Sean Tads',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Comment input should be replaced by the suspended banner
      expect(find.byKey(const Key('feed_comment_suspended_banner')), findsOneWidget);
      expect(
        find.text('Your account is suspended. You cannot post or edit comments.'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
    });
  });
}
