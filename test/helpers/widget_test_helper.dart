import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper to pump a widget with ProviderScope and MaterialApp
Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget widget, {
  List<dynamic> overrides = const [],
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(
        theme: theme,
        home: widget,
      ),
    ),
  );
}

/// Helper to pump a widget with full app navigation
Future<void> pumpTestApp(
  WidgetTester tester,
  Widget home, {
  List<dynamic> overrides = const [],
  Map<String, WidgetBuilder>? routes,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(
        home: home,
        routes: routes ?? {},
      ),
    ),
  );
}

/// Helper to find a widget by text within a specific parent
Finder findTextInWidget(Finder parent, String text) {
  return find.descendant(
    of: parent,
    matching: find.text(text),
  );
}

/// Helper to find icon button by icon
Finder findIconButton(IconData icon) {
  return find.widgetWithIcon(IconButton, icon);
}

/// Helper to verify a snackbar is shown with specific text
void expectSnackBar(String text) {
  expect(find.text(text), findsOneWidget);
  expect(find.byType(SnackBar), findsOneWidget);
}

/// Helper to tap and settle (common pattern)
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Helper to enter text and settle
Future<void> enterTextAndSettle(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

/// Helper to scroll until visible
Future<void> scrollUntilVisible(
  WidgetTester tester,
  Finder finder,
  Finder scrollable, {
  double delta = 100,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: scrollable,
  );
}
