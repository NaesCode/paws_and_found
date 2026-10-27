import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/features/map/data/models/map_report_model.dart';
import 'package:paws_and_found/features/map/presentation/pages/map_page.dart';
import 'package:paws_and_found/features/map/presentation/widgets/interactive_map_canvas.dart';
import 'package:paws_and_found/features/map/presentation/widgets/map_pet_info_modal.dart';
import 'package:paws_and_found/features/map/presentation/widgets/map_pin_badge.dart';

void main() {
  final testReport = MapReportModel(
    id: 'test-report-001',
    reporterId: 'user-001',
    petId: 'pet-001',
    title: 'Thomas',
    animalType: 'Feline',
    description: 'Last seen outside gate in Lawaan. Moggy / Domestic Shorthair, Gray with white spots and paws.',
    status: 'missing',
    locationName: 'Lawaan, Talisay, Cebu',
    latitude: 10.2578,
    longitude: 123.8208,
    normalizedX: 0.5,
    normalizedY: 0.5,
    distanceMeters: 1500,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    tags: const ['Adult', 'Male', 'Gray & White'],
  );

  group('MapPetInfoModal Widget Tests', () {
    testWidgets('renders all pet details, tags, location, and wireframe action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => MapPetInfoModal.show(
                  context: ctx,
                  report: testReport,
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // Open the modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Verify Modal Content
      expect(find.byType(MapPetInfoModal), findsOneWidget);
      expect(find.text('Animal Details'), findsOneWidget);
      expect(find.text('Thomas'), findsOneWidget);
      expect(find.text('Feline'), findsOneWidget);
      expect(find.text('MISSING'), findsOneWidget);

      // Verify Tags
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Gray & White'), findsOneWidget);

      // Verify Location Details
      expect(find.text('Lawaan, Talisay, Cebu'), findsOneWidget);
      expect(find.textContaining('10.2578° N, 123.8208° E'), findsOneWidget);
      expect(find.textContaining('1.5 km away'), findsOneWidget);
      expect(find.textContaining('Reported 2h ago'), findsOneWidget);

      // Verify Sighting Notes
      expect(find.text('Last Seen / Sighting Details'), findsOneWidget);
      expect(
        find.text('Last seen outside gate in Lawaan. Moggy / Domestic Shorthair, Gray with white spots and paws.'),
        findsOneWidget,
      );

      // Verify Action Buttons
      expect(find.text('I Spotted This Animal'), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);

      // Verify Top-Right Close Button is present
      expect(find.byKey(const Key('map_pet_info_modal_close_button')), findsOneWidget);
    });

    testWidgets('close button at top right dismisses the popup modal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => MapPetInfoModal.show(
                  context: ctx,
                  report: testReport,
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();
      expect(find.byType(MapPetInfoModal), findsOneWidget);

      // Tap close button (X)
      await tester.tap(find.byKey(const Key('map_pet_info_modal_close_button')));
      await tester.pumpAndSettle();

      // Modal should be dismissed
      expect(find.byType(MapPetInfoModal), findsNothing);
    });

    testWidgets('tapping outside barrier dismisses the popup modal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => MapPetInfoModal.show(
                  context: ctx,
                  report: testReport,
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();
      expect(find.byType(MapPetInfoModal), findsOneWidget);

      // Tap outside the dialog modal content
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Modal should be dismissed
      expect(find.byType(MapPetInfoModal), findsNothing);
    });

    testWidgets('action buttons invoke provided callbacks or show placeholder feedback', (tester) async {
      bool spottedTapped = false;
      bool contactTapped = false;
      bool shareTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => MapPetInfoModal.show(
                  context: ctx,
                  report: testReport,
                  onReportSighting: () => spottedTapped = true,
                  onContact: () => contactTapped = true,
                  onShare: () => shareTapped = true,
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Ensure visible and tap Spotted Action
      final spottedBtn = find.byKey(const Key('modal_action_spotted_button'));
      await tester.ensureVisible(spottedBtn);
      await tester.tap(spottedBtn);
      expect(spottedTapped, isTrue);

      // Ensure visible and tap Contact Action
      final contactBtn = find.byKey(const Key('modal_action_contact_button'));
      await tester.ensureVisible(contactBtn);
      await tester.tap(contactBtn);
      expect(contactTapped, isTrue);

      // Ensure visible and tap Share Action
      final shareBtn = find.byKey(const Key('modal_action_share_button'));
      await tester.ensureVisible(shareBtn);
      await tester.tap(shareBtn);
      expect(shareTapped, isTrue);
    });

    testWidgets('MapPage opens MapPetInfoModal when a map pin is tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MapPage(
            showBottomNavPlaceholder: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify canvas rendered
      expect(find.byType(InteractiveMapCanvas), findsOneWidget);

      // Find pins rendered on the map canvas
      final canvasPins = find.descendant(
        of: find.byType(InteractiveMapCanvas),
        matching: find.byType(MapPinBadge),
      );
      expect(canvasPins, findsWidgets);

      // Tap the first pin
      await tester.tap(canvasPins.first);
      await tester.pumpAndSettle();

      // MapPetInfoModal should pop up
      expect(find.byType(MapPetInfoModal), findsOneWidget);
      expect(find.byKey(const Key('map_pet_info_modal_close_button')), findsOneWidget);

      // Tap close button
      await tester.tap(find.byKey(const Key('map_pet_info_modal_close_button')));
      await tester.pumpAndSettle();
      expect(find.byType(MapPetInfoModal), findsNothing);
    });
  });
}
