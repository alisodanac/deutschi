import 'package:flutter_test/flutter_test.dart';

import 'package:dutschi/main.dart';

void main() {
  testWidgets('Navigation smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our home screen is displayed.
    // Note: Since we changed the theme and added AppConstants, the text might be the same
    // but we should ensure the test environment can find the new imports if they were relative.
    // The previous test content should still be valid logic-wise.

    expect(find.text('Welcome to Deutschi!'), findsOneWidget);
    expect(find.text('Go to Details'), findsOneWidget);

    // Tap the 'Go to Details' button and add duration for animation
    await tester.tap(find.text('Go to Details'));
    await tester.pumpAndSettle();

    // Verify that we are on the details screen.
    expect(find.text('This is the Details Screen'), findsOneWidget);
    expect(find.text('Back to Home'), findsOneWidget);
  });
}
