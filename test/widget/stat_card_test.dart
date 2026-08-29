import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitcoach_app/widgets/stat_card.dart';
import 'package:fitcoach_app/theme.dart';

/// Helper: wrap a widget in a minimal MaterialApp so ThemeData is available.
Widget wrap(Widget child) {
  return MaterialApp(
    theme: buildTheme(Brightness.light),
    home: Scaffold(body: child),
  );
}

void main() {
  group('StatCard widget', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(wrap(
        const StatCard(label: 'BMI', value: '22.4', icon: Icons.monitor_weight),
      ));
      expect(find.text('BMI'), findsOneWidget);
      expect(find.text('22.4'), findsOneWidget);
    });

    testWidgets('renders sub-label when provided', (tester) async {
      await tester.pumpWidget(wrap(
        const StatCard(
          label: 'Body Fat',
          value: '18%',
          sub: 'Healthy range',
          icon: Icons.percent,
        ),
      ));
      expect(find.text('Healthy range'), findsOneWidget);
    });

    testWidgets('does not render sub-label when omitted', (tester) async {
      await tester.pumpWidget(wrap(
        const StatCard(label: 'Weight', value: '75 kg', icon: Icons.fitness_center),
      ));
      // No sub — nothing with that style should appear beyond label+value
      expect(find.text('BMI'), findsNothing);
    });

    testWidgets('shows warning icon in alert mode', (tester) async {
      await tester.pumpWidget(wrap(
        const StatCard(
          label: 'Calories',
          value: '1800',
          icon: Icons.local_fire_department,
          alert: true,
        ),
      ));
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('uses normal icon when not in alert mode', (tester) async {
      await tester.pumpWidget(wrap(
        const StatCard(
          label: 'Protein',
          value: '120 g',
          icon: Icons.egg_alt,
          alert: false,
        ),
      ));
      expect(find.byIcon(Icons.egg_alt), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('fires onTap callback when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        StatCard(
          label: 'Steps',
          value: '8,200',
          icon: Icons.directions_walk,
          onTap: () => tapped = true,
        ),
      ));
      await tester.tap(find.byType(StatCard));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('is not tappable when onTap is null', (tester) async {
      // Should render without errors; tap silently ignored
      await tester.pumpWidget(wrap(
        const StatCard(label: 'Water', value: '2.5 L', icon: Icons.water_drop),
      ));
      await tester.tap(find.byType(StatCard), warnIfMissed: false);
      await tester.pump();
      // No exception means pass
    });
  });
}
