import 'package:flutter_test/flutter_test.dart';

/// Waits until a widget matching [finder] is present in the widget tree,
/// pumping every 100ms up to [timeout].
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  expect(finder, findsOneWidget, reason: 'Timed out waiting for $finder');
}

/// Waits until a widget matching [finder] disappears from the widget tree.
Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isEmpty) {
      return;
    }
  }
  expect(finder, findsNothing, reason: 'Timed out waiting for $finder to disappear');
}

/// Taps a widget and pumps the widget tree until animations settle.
Future<void> tapAndSettle(
  WidgetTester tester,
  Finder finder, {
  Duration settleTimeout = const Duration(seconds: 5),
}) async {
  await pumpUntilFound(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Enters text into a TextField/TextFormField and pumps until settled.
Future<void> enterTextAndSettle(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await pumpUntilFound(tester, finder);
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}
