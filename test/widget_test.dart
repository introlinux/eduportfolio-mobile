import 'package:eduportfolio/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: EduportfolioApp(),
      ),
    );

    // Verify that the app builds without errors
    expect(find.text('Eduportfolio'), findsOneWidget);
  });
}
