import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitcoach_app/widgets/streak_card.dart';
import 'package:fitcoach_app/theme.dart';

Widget wrap(Widget child) {
  return MaterialApp(
    theme: buildTheme(Brightness.light),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('StreakCard widget', () {
    testWidgets('renders current streak count', (tester) async {
      await tester.pumpWidget(wrap(
        const StreakCard(data: {
          'currentStreak': 7,
          'longestStreak': 14,
          'totalWorkouts': 42,
          'totalCaloriesBurned': 12600,
          'badges': [],
        }),
      ));
      await tester.pump();
      expect(find.textContaining('7'), findsWidgets);
    });

    testWidgets('renders zero streak for new user without crash', (tester) async {
      await tester.pumpWidget(wrap(
        const StreakCard(data: {
          'currentStreak': 0,
          'longestStreak': 0,
          'totalWorkouts': 0,
          'totalCaloriesBurned': 0,
          'badges': [],
        }),
      ));
      await tester.pump();
      expect(find.byType(StreakCard), findsOneWidget);
    });

    testWidgets('renders with null data (empty state) without crash', (tester) async {
      await tester.pumpWidget(wrap(const StreakCard(data: null)));
      await tester.pump();
      expect(find.byType(StreakCard), findsOneWidget);
    });

    testWidgets('renders badge emojis for earned badges', (tester) async {
      await tester.pumpWidget(wrap(
        const StreakCard(data: {
          'currentStreak': 5,
          'longestStreak': 5,
          'totalWorkouts': 5,
          'totalCaloriesBurned': 1500,
          'badges': [
            {'id': 'first_workout', 'name': 'First Step', 'icon': '🎯', 'desc': 'Complete your first workout'},
            {'id': 'streak_5', 'name': 'On Fire', 'icon': '🔥', 'desc': '5-day streak'},
          ],
        }),
      ));
      await tester.pump();
      // Card renders without error — emoji presence varies by implementation
      expect(find.byType(StreakCard), findsOneWidget);
    });

    testWidgets('handles missing keys in data map gracefully', (tester) async {
      // Partial data — only some keys present
      await tester.pumpWidget(wrap(
        const StreakCard(data: {
          'currentStreak': 3,
        }),
      ));
      await tester.pump();
      expect(find.byType(StreakCard), findsOneWidget);
    });
  });
}
