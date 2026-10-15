import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paws_and_found/shared/atoms/paw_button.dart';
import 'package:paws_and_found/shared/atoms/paw_pill_button.dart';

void main() {
  testWidgets('PawButton renders and responds to tap', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PawButton(
            text: 'Click Me',
            color: Colors.blue,
            textColor: Colors.white,
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Click Me'), findsOneWidget);
    await tester.tap(find.text('Click Me'));
    expect(tapped, isTrue);
  });

  testWidgets('PawPillButton renders and responds to tap', (WidgetTester tester) async {
    bool pillTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PawPillButton.primary(
            text: 'Add pet',
            onPressed: () => pillTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Add pet'), findsOneWidget);
    await tester.tap(find.text('Add pet'));
    expect(pillTapped, isTrue);
  });
}
