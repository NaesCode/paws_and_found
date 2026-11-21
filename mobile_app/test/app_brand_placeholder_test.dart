import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/shared/atoms/app_logo.dart';
import 'package:paws_and_found/shared/atoms/app_logo_placeholder.dart';
import 'package:paws_and_found/shared/atoms/paw_status_badge.dart';
import 'package:paws_and_found/shared/atoms/paw_tag.dart';
import 'package:paws_and_found/shared/molecules/app_brand_title_placeholder.dart';

void main() {
  group('AppLogo and AppLogoPlaceholder Atom Tests', () {
    testWidgets('AppLogo renders official vector logo atom', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppLogo(size: 80.0),
            ),
          ),
        ),
      );

      expect(find.byType(AppLogo), findsOneWidget);
    });

    testWidgets('AppLogoPlaceholder renders pet emblem and rescue pin badge in placeholder mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppLogoPlaceholder(size: 80.0, showBadge: true, useSvg: false),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pets_rounded), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
      expect(find.text('LOGO PLACEHOLDER'), findsOneWidget);
    });

    testWidgets('AppLogoPlaceholder renders AppLogo when useSvg is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppLogoPlaceholder(size: 80.0, showBadge: false, useSvg: true),
            ),
          ),
        ),
      );

      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.text('LOGO PLACEHOLDER'), findsNothing);
    });

    testWidgets('hides placeholder text badge when showBadge is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppLogoPlaceholder(size: 60.0, showBadge: false),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pets_rounded), findsOneWidget);
      expect(find.text('LOGO PLACEHOLDER'), findsNothing);
    });
  });

  group('AppBrandTitlePlaceholder Molecule Tests', () {
    testWidgets('renders vertical layout with title and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppBrandTitlePlaceholder(
                layoutMode: BrandLayoutMode.vertical,
                logoSize: 72.0,
                showBadge: true,
                useSvgLogo: false,
                title: 'Paws and Found',
                subtitle: 'Community Lost & Found Animal Recovery',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Paws and Found'), findsOneWidget);
      expect(find.text('Community Lost & Found Animal Recovery'), findsOneWidget);
      expect(find.text('LOGO PLACEHOLDER'), findsOneWidget);
      expect(find.byType(AppLogoPlaceholder), findsOneWidget);
    });

    testWidgets('renders horizontal layout correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppBrandTitlePlaceholder(
                layoutMode: BrandLayoutMode.horizontal,
                logoSize: 48.0,
                showBadge: false,
                useSvgLogo: false,
                title: 'Custom Brand',
                subtitle: 'Sub-tagline',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Custom Brand'), findsOneWidget);
      expect(find.text('Sub-tagline'), findsOneWidget);
      // Horizontal mode hides badge by default inside logo
      expect(find.text('LOGO PLACEHOLDER'), findsNothing);
    });

    testWidgets('renders official SVG logo in brand header when useSvgLogo is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppBrandTitlePlaceholder(
                layoutMode: BrandLayoutMode.vertical,
                logoSize: 76.0,
                showBadge: false,
                useSvgLogo: true,
                title: 'Paws and Found',
                subtitle: 'Community Lost & Found Animal Recovery',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Paws and Found'), findsOneWidget);
      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.text('LOGO PLACEHOLDER'), findsNothing);
    });
  });

  group('PawStatusBadge and PawTag Atoms Tests', () {
    testWidgets('PawStatusBadge displays uppercase label and respects status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PawStatusBadge(status: 'missing'),
                PawStatusBadge(status: 'stray'),
                PawStatusBadge(status: 'found'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('MISSING'), findsOneWidget);
      expect(find.text('STRAY'), findsOneWidget);
      expect(find.text('FOUND'), findsOneWidget);
    });

    testWidgets('PawTag renders label and responds to tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PawTag(
              label: 'Golden Retriever',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Golden Retriever'), findsOneWidget);
      await tester.tap(find.text('Golden Retriever'));
      expect(tapped, isTrue);
    });
  });
}
