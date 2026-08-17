import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitcoach_app/main.dart';
import 'package:fitcoach_app/theme.dart';

void main() {
  testWidgets('App renders splash screen with branding', (WidgetTester tester) async {
    await tester.pumpWidget(const FitCoachApp());
    expect(find.text('FITCOACH'), findsOneWidget);
    expect(find.text('Train. Fuel. Transform.'), findsOneWidget);
  });

  test('Theme uses dark background', () {
    final theme = buildTheme(Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppColors.bg);
  });
}
