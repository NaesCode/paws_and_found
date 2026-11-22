import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/shared/molecules/community_warning_dialog.dart';

void main() {
  group('CommunityWarningDialog Widget Tests', () {
    testWidgets('renders Community Warning dialog matching screenshot specs', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CommunityWarningDialog.show(
                    context: context,
                    detectedWord: 'buang',
                    violationCount: 3,
                    onDismiss: () => dismissed = true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify Title & Icon
      expect(find.text('Community Warning'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // Verify Body Text
      expect(
        find.text('Your comment was not posted because it contains prohibited language in our community guidelines.'),
        findsOneWidget,
      );

      // Verify Detected Word Badge
      expect(find.text('Detected: "buang"'), findsOneWidget);

      // Verify Escalation Warning Note
      expect(
        find.text('Warning: Continued use of prohibited language will result in account suspension (3 violations recorded).'),
        findsOneWidget,
      );

      // Verify 'Understood' button and dismiss
      final button = find.byKey(const Key('community_warning_understood_button'));
      expect(button, findsOneWidget);
      expect(find.text('Understood'), findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Community Warning'), findsNothing);
      expect(dismissed, isTrue);
    });

    testWidgets('displays suspended notice when isSuspended is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CommunityWarningDialog.show(
                    context: context,
                    detectedWord: 'yawa',
                    violationCount: 5,
                    isSuspended: true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Detected: "yawa"'), findsOneWidget);
      expect(
        find.text('Warning: Your account has been suspended due to repeated violations (5 violations recorded).'),
        findsOneWidget,
      );
    });
  });
}
