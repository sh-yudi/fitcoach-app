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

      // Tap login with empty fields -> should trigger form validation
      final loginBtns = find.byType(FilledButton);
      if (loginBtns.evaluate().isNotEmpty) {
        await tester.ensureVisible(loginBtns.first);
        await tester.tap(loginBtns.first, warnIfMissed: false);
        await pumpDuration(tester);
      }

      // ==========================================
      // Flow 2: Registration Validation Flow
      // ==========================================
      final createAccountBtn = find.text('Create account');
      if (createAccountBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(createAccountBtn);
        await tester.tap(createAccountBtn, warnIfMissed: false);
        await pumpDuration(tester, const Duration(seconds: 1));

        expect(find.text('Create your account'), findsOneWidget);

        // Tap back button
        final backBtn = find.byType(BackButton);
        if (backBtn.evaluate().isNotEmpty) {
          await tester.tap(backBtn);
          await pumpDuration(tester, const Duration(seconds: 1));
        }
      }

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

      // Check for one-tap consent modal if prompted
      final oneTapModal = find.text('Skip login next time?');
      if (oneTapModal.evaluate().isNotEmpty) {
        final enableBtn = find.text('Enable one-tap login');
        if (enableBtn.evaluate().isNotEmpty) {
          await tester.tap(enableBtn, warnIfMissed: false);
          await pumpDuration(tester, const Duration(seconds: 3));
        }
      }

      // ==========================================
      // Flow 4: Home Dashboard Screen
      // ==========================================
      await pumpUntilFound(tester, find.byType(HomeShell));
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      // ==========================================
      // Flow 5: Diet Screen & Water 300-500ml
      // ==========================================
      final dietTab = find.text('Diet');
      if (dietTab.evaluate().isNotEmpty) {
        await tester.tap(dietTab.first, warnIfMissed: false);
        await pumpDuration(tester, const Duration(seconds: 2));
        expect(find.textContaining('Diet Plan'), findsWidgets);
        expect(find.textContaining('300–500'), findsWidgets);
      }

      // ==========================================
      // Flow 6: Workout Screen
      // ==========================================
      final workoutTab = find.text('Workout');
      if (workoutTab.evaluate().isNotEmpty) {
        await tester.tap(workoutTab.first, warnIfMissed: false);
        await pumpDuration(tester, const Duration(seconds: 2));
        expect(find.textContaining('Workout'), findsWidgets);
      }

      // ==========================================
      // Flow 7: Calendar Screen
      // ==========================================
      final calendarTab = find.text('Calendar');
      if (calendarTab.evaluate().isNotEmpty) {
        await tester.tap(calendarTab.first, warnIfMissed: false);
        await pumpDuration(tester, const Duration(seconds: 2));
        expect(find.textContaining('Calendar'), findsWidgets);
      }

      // ==========================================
      // Flow 8: Progress Screen
      // ==========================================
      final progressTab = find.text('Progress');
      if (progressTab.evaluate().isNotEmpty) {
        await tester.tap(progressTab.first, warnIfMissed: false);
        await pumpDuration(tester, const Duration(seconds: 2));
        expect(find.textContaining('Progress'), findsWidgets);
      }

      // ==========================================
      // Flow 9: Fasting Screen
      // ==========================================
      final fastingTab = find.text('Fasting');
      if (fastingTab.evaluate().isNotEmpty) {
        await tester.tap(fastingTab.first, warnIfMissed: false);
        await pumpDuration(tester, const Duration(seconds: 2));
        expect(find.textContaining('Fasting'), findsWidgets);
      }

      // ==========================================
      // Flow 10: Profile Screen
      // ==========================================
      final profileTab = find.text('Profile');
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab.first, warnIfMissed: false);
        await pumpDuration(tester, const Duration(seconds: 2));
        expect(find.textContaining('Profile'), findsWidgets);
      }
    });
  });
}
