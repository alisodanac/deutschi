import 'package:flutter_test/flutter_test.dart';

import 'package:dutschi/main.dart';

void main() {
  testWidgets('Navigation smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our Test screen is displayed initially.
    expect(find.text('Start your test here!'), findsOneWidget);
    expect(find.text('Start Test'), findsOneWidget);

    // Tap the 'Statistics' tab
    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();

    // Verify that we are on the statistics screen.
    expect(find.text('Your learning progress'), findsOneWidget);

    // Tap the 'Settings' tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Verify that we are on the settings screen.
    expect(find.text('App Preferences'), findsOneWidget);
  });
}
