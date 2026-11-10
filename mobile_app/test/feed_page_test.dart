import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:paws_and_found/features/feed/presentation/pages/feed_page.dart';
import 'package:paws_and_found/shared/molecules/paw_segmented_control.dart';

void main() {
  // to work the camera
  Widget createTestWidget({
    Widget? generalReportsView,
    Widget? personalReportsView,
    VoidCallback? onCameraNavigated,
  }) {
    final router = GoRouter(
      initialLocation: '/feed',
      routes: [
        GoRoute(
          path: '/feed',
          builder: (context, state) => FeedPage(
            generalReportsView: generalReportsView ??
                const Center(child: Text('Mock General Reports')),
            personalReportsView: personalReportsView ??
                const Center(child: Text('Mock Personal Reports')),
          ),
        ),
        GoRoute(
          path: '/camera',
          builder: (context, state) {
            onCameraNavigated?.call();
            return const Scaffold(body: Text('Mock Camera Page'));
          },
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  group('FeedPage Shell & Interaction Tests', () {
    testWidgets('renders AppBar and PawSegmentedControl with General Reports default', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 1. Verify AppBar title
      expect(find.text('Reports'), findsOneWidget);

      // 2. Verify segmented control options
      expect(find.byType(PawSegmentedControl), findsOneWidget);
      expect(find.text('General Reports'), findsOneWidget);
      expect(find.text('Your Reports'), findsOneWidget);

      // 3. Verify General Reports is loaded by default
      expect(find.text('Mock General Reports'), findsOneWidget);
      expect(find.text('Mock Personal Reports'), findsNothing);

      // 4. Verify FAB is not present on General Reports tab
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('switching tab to Your Reports reveals FloatingActionButton with label', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap 'Your Reports' segment
      await tester.tap(find.text('Your Reports'));
      await tester.pumpAndSettle();

      // Verify page switched to Personal Reports
      expect(find.text('Mock Personal Reports'), findsOneWidget);
      expect(find.text('Mock General Reports'), findsNothing);

      // Verify FAB appears
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add_a_photo_rounded), findsOneWidget);
      expect(find.text('Report Sighting'), findsOneWidget);
    });

    testWidgets('switching back to General Reports hides FloatingActionButton', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to Your Reports
      await tester.tap(find.text('Your Reports'));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Switch back to General Reports
      await tester.tap(find.text('General Reports'));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Mock General Reports'), findsOneWidget);
    });

    testWidgets('tapping FloatingActionButton navigates to /camera', (tester) async {
      bool cameraOpened = false;

      await tester.pumpWidget(
        createTestWidget(
          onCameraNavigated: () => cameraOpened = true,
        ),
      );
      await tester.pumpAndSettle();

      // Go to Your Reports tab
      await tester.tap(find.text('Your Reports'));
      await tester.pumpAndSettle();

      // Tap the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify GoRouter routed to /camera
      expect(cameraOpened, isTrue);
      expect(find.text('Mock Camera Page'), findsOneWidget);
    });

    testWidgets('scrolling down collapses FAB label; scrolling up expands it', (tester) async {
      // Create a scrollable list view inside personal reports
      final scrollableListView = ListView.builder(
        itemCount: 50,
        itemBuilder: (context, index) => ListTile(
          title: Text('Personal Post #$index'),
        ),
      );

      await tester.pumpWidget(
        createTestWidget(
          personalReportsView: scrollableListView,
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Your Reports so FAB is visible
      await tester.tap(find.text('Your Reports'));
      await tester.pumpAndSettle();

      // Initially FAB label is visible
      expect(find.text('Report Sighting'), findsOneWidget);

      // Simulate scrolling down (reverse scroll direction)
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Text label collapses into SizedBox.shrink()
      expect(find.text('Report Sighting'), findsNothing);
      // Camera icon is still visible
      expect(find.byIcon(Icons.add_a_photo_rounded), findsOneWidget);

      // Simulate scrolling up (forward scroll direction)
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // FAB label re-expands
      expect(find.text('Report Sighting'), findsOneWidget);
    });
  });
}