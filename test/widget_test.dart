// This is a basic Flutter widget test for Jaikisan Card app.

import 'package:flutter_test/flutter_test.dart';

import 'package:jaikisan_card/main.dart';

void main() {
  testWidgets('Jaikisan Card app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for the splash screen to complete
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Verify that the app name appears
    expect(find.text('Jaikisan Card'), findsOneWidget);

    // Verify that main sections are present
    expect(find.text('Money Transfer'), findsOneWidget);
    expect(find.text('Recharges & Bills'), findsOneWidget);
    expect(find.text('Travel and More'), findsOneWidget);

    // Verify that the Scan QR button is present
    expect(find.text('Scan QR'), findsOneWidget);

    // Test tapping the Scan QR button
    await tester.tap(find.text('Scan QR'));
    await tester.pump();

    // Verify that the snackbar appears
    expect(find.text('QR Scanner functionality will be implemented'), findsOneWidget);
  });
}
