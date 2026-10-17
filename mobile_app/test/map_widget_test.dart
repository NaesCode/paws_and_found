import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/shared/atoms/map_pin_badge.dart';
import 'package:paws_and_found/shared/atoms/wireframe_status_badge.dart';
import 'package:paws_and_found/shared/atoms/wireframe_tag.dart';
import 'package:paws_and_found/shared/molecules/map_filter_bar.dart';
import 'package:paws_and_found/shared/molecules/map_legend.dart';
import 'package:paws_and_found/shared/organisms/map_report_card.dart';
import 'package:paws_and_found/shared/organisms/wireframe_bottom_nav_bar.dart';
import 'package:paws_and_found/features/map/presentation/pages/map_page.dart';

void main() {
  group('Map Atomic Design Components', () {
    testWidgets('MapPinBadge renders label and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapPinBadge(
              label: 'M',
              status: 'missing',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('M'), findsOneWidget);
      await tester.tap(find.text('M'));
      expect(tapped, isTrue);
    });

    testWidgets('WireframeStatusBadge displays status label correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WireframeStatusBadge(status: 'missing'),
          ),
        ),
      );

      expect(find.text('MISSING'), findsOneWidget);
    });

    testWidgets('WireframeTag renders trait tag', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WireframeTag(label: 'Golden'),
          ),
        ),
      );

      expect(find.text('Golden'), findsOneWidget);
    });

    testWidgets('MapFilterBar triggers filter selection', (tester) async {
      String selected = 'all';
      bool animalTypeClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapFilterBar(
              selectedFilter: selected,
              onFilterSelected: (val) => selected = val,
              onAnimalTypePressed: () => animalTypeClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('For You'), findsOneWidget);
      expect(find.text('Animal Type'), findsOneWidget);

      await tester.tap(find.text('For You'));
      expect(selected, 'for_you');

      await tester.tap(find.text('Animal Type'));
      expect(animalTypeClicked, isTrue);
    });

    testWidgets('MapLegend renders M, S, F descriptions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapLegend(),
          ),
        ),
      );

      expect(find.text('Missing'), findsOneWidget);
      expect(find.text('Stray'), findsOneWidget);
      expect(find.text('Found'), findsOneWidget);
    });

    testWidgets('MapReportCard renders title, status, subtitle and tags', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapReportCard(
              title: 'Golden Retriever',
              subtitle: 'Near Elm St · 2h ago',
              status: 'missing',
              tags: ['Male', 'Adult', 'Golden'],
            ),
          ),
        ),
      );

      expect(find.text('Golden Retriever'), findsOneWidget);
      expect(find.text('MISSING'), findsOneWidget);
      expect(find.text('Near Elm St · 2h ago'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Adult'), findsOneWidget);
      expect(find.text('Golden'), findsOneWidget);
    });

    testWidgets('WireframeBottomNavBar renders 5 placeholder icons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: WireframeBottomNavBar(),
          ),
        ),
      );

      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    });

    testWidgets('MapPage full wireframe screen renders and is interactive', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MapPage(showBottomNavPlaceholder: true),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Animal Map'), findsOneWidget);

      // Verify Filter Bar
      expect(find.text('All'), findsOneWidget);
      expect(find.text('For You'), findsOneWidget);

      // Verify Legend
      expect(find.text('Missing'), findsOneWidget);
      expect(find.text('Stray'), findsOneWidget);
      expect(find.text('Found'), findsOneWidget);

      // Verify floating report card displays first report
      expect(find.text('Golden Retriever'), findsOneWidget);

      // Verify bottom nav placeholder
      expect(find.byType(WireframeBottomNavBar), findsOneWidget);
    });
  });
}
