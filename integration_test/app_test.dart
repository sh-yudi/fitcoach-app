import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitcoach_app/main.dart' as app;
import 'package:fitcoach_app/screens/home/home_shell.dart';
import 'package:fitcoach_app/services/session.dart';
import 'package:fitcoach_app/services/api_client.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDuration(WidgetTester tester, [Duration duration = const Duration(milliseconds: 600)]) async {
    await tester.pump(duration);
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text);
    if (f.evaluate().isNotEmpty) {
      await tester.ensureVisible(f);
      await tester.tap(f, warnIfMissed: false);
      await pumpDuration(tester);
    }
  }

  group('FitCoach End-to-End Regression Suite', () {
    testWidgets('Full User Journey across all 10 screens', (tester) async {
      // Clear session to ensure clean state
      await Session.clearAll();
      ApiClient.instance.setToken(null);

      // Launch the app
      app.main();
      await pumpDuration(tester, const Duration(seconds: 2));

      // ==========================================
      // Flow 1: Auth Negative Scenarios
      // ==========================================
      final loginTitle = find.text('Welcome back');
      await pumpUntilFound(tester, loginTitle);
      expect(loginTitle, findsOneWidget);
      expect(find.text('Log in'), findsWidgets);

      // Tap login with empty fields -> should trigger form validation
      final loginBtns = find.byType(FilledButton);
      if (loginBtns.evaluate().isNotEmpty) {
        await tester.ensureVisible(loginBtns.first);
        await tester.tap(loginBtns.first, warnIfMissed: false);
        await pumpDuration(tester);
      }
      // Should still be on the login screen (blocked by validation)
      expect(find.text('Welcome back'), findsOneWidget);

      // ==========================================
      // Flow 2: Registration Validation Flow
      // ==========================================
      await tapText(tester, 'Create account');
      await pumpDuration(tester, const Duration(seconds: 1));
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.textContaining('Step 1 of 3'), findsOneWidget);

      // Empty Continue -> validation keeps us on step 1
      await tapText(tester, 'Continue');
      await pumpDuration(tester, const Duration(seconds: 1));
      expect(find.textContaining('Step 1 of 3'), findsOneWidget);

      // Back returns cleanly to login
      final backBtn = find.byType(BackButton);
      if (backBtn.evaluate().isNotEmpty) {
        await tester.tap(backBtn);
        await pumpDuration(tester, const Duration(seconds: 1));
      }
      expect(find.text('Welcome back'), findsOneWidget);

      // ==========================================
      // Flow 3: Successful Login & One-Tap Modal
      // ==========================================
      await pumpUntilFound(tester, find.text('Welcome back'));
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().length >= 2) {
        await tester.enterText(textFields.at(0), 'deviceuser@fitcoach.in');
        await pumpDuration(tester);
        await tester.enterText(textFields.at(1), 'Pass123456');
        await pumpDuration(tester);
      }

      final submitLogin = find.byType(FilledButton);
      if (submitLogin.evaluate().isNotEmpty) {
        await tester.ensureVisible(submitLogin.last);
        await tester.tap(submitLogin.last, warnIfMissed: false);
        await pumpDuration(tester, const Duration(seconds: 4));
      }

      // One-tap consent modal (only on first login) — opt in if shown
      final oneTapModal = find.text('Skip login next time?');
      if (oneTapModal.evaluate().isNotEmpty) {
        await tapText(tester, 'Enable one-tap login');
        await pumpDuration(tester, const Duration(seconds: 3));
      }

      // ==========================================
      // Flow 4: Home Dashboard Screen
      // ==========================================
      await pumpUntilFound(tester, find.byType(HomeShell));
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      expect(find.textContaining('Hi '), findsWidgets);
      expect(find.textContaining('Body Fat'), findsWidgets);
      expect(find.textContaining('Daily Calories'), findsWidgets);
      expect(find.textContaining('streak'), findsWidgets);
      expect(find.textContaining('Workout'), findsWidgets);
      // Phase badge (one of the phases is guaranteed)
      if (find.textContaining('Maintenance phase').evaluate().isEmpty &&
          find.textContaining('Fat loss phase').evaluate().isEmpty) {
        expect(find.textContaining('Lean bulk phase'), findsWidgets);
      }

      await pumpDuration(tester, const Duration(seconds: 2));

      // ==========================================
      // Flow 5: Diet Screen & Water 300-500ml
      // ==========================================
      await tapText(tester, 'Diet');
      await pumpDuration(tester, const Duration(seconds: 2));
      expect(find.textContaining('Diet Plan'), findsWidgets);
      expect(find.textContaining('300–500'), findsWidgets);
      expect(find.textContaining('Scan Your Food'), findsWidgets);
      // Gym/Rest Day banner shows exactly one of the two labels
      final dayLabel = find.textContaining('Gym Day').evaluate().isNotEmpty
          ? 'Gym Day'
          : 'Rest Day';
      expect(find.textContaining(dayLabel), findsOneWidget);

      // Water chip toggle — flip a 300–500 chip to confirm interactivity
      final waterChip = find.text('300–500');
      if (waterChip.evaluate().isNotEmpty) {
        await tester.tap(waterChip.first, warnIfMissed: false);
        await pumpDuration(tester);
      }

      // ==========================================
      // Flow 6: Workout Screen & Exercise Demo
      // ==========================================
      await tapText(tester, 'Workout');
      await pumpDuration(tester, const Duration(seconds: 2));
      expect(find.textContaining('Workout'), findsWidgets);
      expect(find.textContaining('Warm-up'), findsWidgets);
      // 'Rest / Recovery' may start below the fold; scroll lazily-built list
      final restRecovery = find.textContaining('Rest / Recovery');
      if (restRecovery.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          restRecovery,
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await pumpDuration(tester);
      }
      expect(restRecovery, findsWidgets);

      // ==========================================
      // Flow 7: Calendar Screen
      // ==========================================
      await tapText(tester, 'Calendar');
      await pumpDuration(tester, const Duration(seconds: 2));
      expect(find.textContaining('Gym Calendar'), findsWidgets);
      // A day status line is always shown (plan / attendance prompt)
      expect(
        find.textContaining('Tap a day'),
        findsWidgets,
      );

      // ==========================================
      // Flow 8: Progress Screen
      // ==========================================
      await tapText(tester, 'Progress');
      await pumpDuration(tester, const Duration(seconds: 2));
      expect(find.textContaining('Progress'), findsWidgets);
      if (find.textContaining('No progress yet').evaluate().isNotEmpty) {
        // Empty state — both the prompt and first-entry button are shown
        expect(find.textContaining('Log your first entry'), findsOneWidget);
      } else {
        // Has data — trend chart header and log button are shown
        expect(find.textContaining('Weight trend'), findsWidgets);
        expect(find.textContaining('Log measurements'), findsWidgets);
      }

      // ==========================================
      // Flow 9: Fasting Screen
      // ==========================================
      await tapText(tester, 'Fasting');
      await pumpDuration(tester, const Duration(seconds: 2));
      expect(find.textContaining('Fasting'), findsWidgets);
      expect(find.textContaining('16:8'), findsWidgets);
      expect(find.textContaining('18:6'), findsWidgets);

      // ==========================================
      // Flow 10: Profile Screen & Session Persistence
      // ==========================================
      await tapText(tester, 'Profile');
      await pumpDuration(tester, const Duration(seconds: 2));
      expect(find.textContaining('Profile'), findsWidgets);
      // The logged-in user's email renders at the top of the profile body
      expect(find.textContaining('deviceuser@fitcoach.in'), findsOneWidget);

      // Session persistence — session token should still be present in storage
      final storedToken = await Session.token();
      expect(storedToken, isNotNull, reason: 'session token must persist after login');
      final storedEmail = await Session.email();
      expect(storedEmail, contains('deviceuser@fitcoach.in'));
    });
  });
}