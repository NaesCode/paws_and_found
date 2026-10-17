import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/shared/atoms/camera_viewfinder_brackets.dart';
import 'package:paws_and_found/shared/molecules/camera_viewfinder_placeholder.dart';
import 'package:paws_and_found/shared/organisms/create_report_form.dart';
import 'package:paws_and_found/shared/organisms/wireframe_bottom_nav_bar.dart';
import 'package:paws_and_found/features/report/presentation/pages/camera_report_page.dart';

void main() {
  group('Camera & Report Atomic Design Components', () {
    testWidgets('CameraViewfinderBrackets renders properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: CameraViewfinderBrackets(),
            ),
          ),
        ),
      );

      expect(find.byType(CameraViewfinderBrackets), findsOneWidget);
    });

    testWidgets('CameraViewfinderPlaceholder renders gallery button and dashed center', (tester) async {
      bool galleryTapped = false;
      bool captureTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraViewfinderPlaceholder(
              onGalleryTap: () => galleryTapped = true,
              onCaptureTap: () => captureTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Gallery'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);

      await tester.tap(find.text('Gallery'));
      expect(galleryTapped, isTrue);

      await tester.tap(find.byIcon(Icons.camera_alt_outlined));
      expect(captureTapped, isTrue);
    });

    testWidgets('CreateReportForm renders all fields and submits', (tester) async {
      final controller = TextEditingController(text: 'Spotted near park');
      bool submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CreateReportForm(
                animalType: 'Canine',
                status: 'Stray',
                descriptionController: controller,
                dateTimeString: '10/17/26 04:00',
                isGpsAuto: true,
                onAnimalTypeChanged: (_) {},
                onStatusChanged: (_) {},
                onToggleGps: () {},
                onSubmit: () => submitted = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('CREATE REPORT'), findsOneWidget);
      expect(find.text('Canine'), findsOneWidget);
      expect(find.text('Stray'), findsOneWidget);
      expect(find.text('Spotted near park'), findsOneWidget);
      expect(find.text('10/17/26 04:00'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Submit Report'), findsOneWidget);

      await tester.tap(find.text('Submit Report'));
      expect(submitted, isTrue);
    });

    testWidgets('WireframeBottomNavBar renders Camera active on index 2', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: WireframeBottomNavBar(currentIndex: 2),
          ),
        ),
      );

      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    });

    testWidgets('CameraReportPage full wireframe screen renders and is interactive', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CameraReportPage(showBottomNavPlaceholder: true),
        ),
      );
      await tester.pumpAndSettle();

      // Viewfinder
      expect(find.byType(CameraViewfinderPlaceholder), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);

      // Form
      expect(find.text('CREATE REPORT'), findsOneWidget);
      expect(find.text('Submit Report'), findsOneWidget);

      // Bottom bar
      expect(find.byType(WireframeBottomNavBar), findsOneWidget);

      // Submit report and check confirmation dialog
      await tester.ensureVisible(find.text('Submit Report'));
      await tester.tap(find.text('Submit Report'));
      await tester.pumpAndSettle();

      expect(find.text('Report Submitted'), findsOneWidget);
      expect(find.text('View on Map'), findsOneWidget);
    });
  });
}
