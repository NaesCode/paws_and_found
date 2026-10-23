import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:paws_and_found/features/map/data/models/map_report_model.dart';
import 'package:paws_and_found/features/map/domain/entities/map_report_entity.dart';
import 'package:paws_and_found/features/map/presentation/pages/map_page.dart';
import 'package:paws_and_found/features/map/presentation/widgets/interactive_map_canvas.dart';
import 'package:paws_and_found/features/map/presentation/widgets/map_filter_bar.dart';
import 'package:paws_and_found/features/map/presentation/widgets/map_legend.dart';
import 'package:paws_and_found/features/map/presentation/widgets/map_pin_badge.dart';
import 'package:paws_and_found/features/map/presentation/widgets/map_report_card.dart';
import 'package:paws_and_found/features/map/presentation/widgets/user_location_marker.dart';
import 'package:paws_and_found/shared/atoms/wireframe_status_badge.dart';
import 'package:paws_and_found/shared/atoms/wireframe_tag.dart';
import 'package:paws_and_found/shared/organisms/custom_app_bar.dart';

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

    testWidgets('UserLocationMarker renders accurately', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserLocationMarker(),
          ),
        ),
      );

      expect(find.byType(UserLocationMarker), findsOneWidget);
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

    testWidgets('InteractiveMapCanvas renders FlutterMap and interactive markers', (tester) async {
      final mockReports = MapReportModel.getMockReports().take(2).toList();
      MapReportEntity? tappedReport;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveMapCanvas(
              reports: mockReports,
              userLocation: const LatLng(14.5995, 120.9842),
              onReportTap: (r) => tappedReport = r,
            ),
          ),
        ),
      );

      expect(find.byType(InteractiveMapCanvas), findsOneWidget);
      expect(find.byType(UserLocationMarker), findsOneWidget);
      expect(find.byType(MapPinBadge), findsNWidgets(2));

      await tester.tap(find.byType(MapPinBadge).first);
      expect(tappedReport, isNotNull);
      expect(tappedReport!.id, mockReports.first.id);
    });

    testWidgets('CustomAppBar renders in bottomNavigationBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomAppBar(
              currentIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(CustomAppBar), findsOneWidget);
    });

    testWidgets('MapPage full screen renders with InteractiveMapCanvas and CustomAppBar', (tester) async {
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

      // Verify interactive map canvas
      expect(find.byType(InteractiveMapCanvas), findsOneWidget);

      // Verify floating report card displays first report
      expect(find.text('Golden Retriever'), findsOneWidget);

      // Verify bottom nav
      expect(find.byType(CustomAppBar), findsOneWidget);
    });
  });
}
