import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'services/api_client.dart';
import 'services/notification_service.dart';
import 'services/session.dart';
import 'theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.instance.init(onTap: _handleNotificationTap);
  ThemeController.instance.load();
  runApp(const FitCoachApp());
}

/// Watches the app lifecycle: records when the app goes to the background so
/// the session can be ended if the user stays away too long (or kills the app
/// from recents).
class _AppLifecycleObserver with WidgetsBindingObserver {
  bool _loggingOut = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        Session.markBackgrounded();
      case AppLifecycleState.resumed:
        _checkIdleLogout();
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _checkIdleLogout() async {
    if (_loggingOut) return;
    final token = await Session.token();
    if (token == null) return;
    final away = await Session.backgroundedFor();
    if (away == null || away < Session.idleLogout) {
      await Session.clearBackgrounded();
      return;
    }
    _loggingOut = true;
    await Session.logoutIfIdle();
    ApiClient.instance.setToken(null);
    if (_loggingOut) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
    _loggingOut = false;
  }
}

void _handleNotificationTap(String payload) {
  final nav = navigatorKey.currentState;
  if (nav == null) return;
  if (payload.startsWith('gym_checkin:')) {
    final date = payload.split(':').last;
    nav.push(
      MaterialPageRoute(builder: (_) => CalendarScreen(initialCheckInDate: date)),
    );
  }
}

class FitCoachApp extends StatelessWidget {
  const FitCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return _LifecycleWrapper(
          child: MaterialApp(
            title: 'FitCoach',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: ThemeController.instance.mode,
            builder: (context, child) {
              AppColors.setBrightness(Theme.of(context).brightness);
              return child!;
            },
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}

/// Attaches the lifecycle observer for idle auto-logout.
class _LifecycleWrapper extends StatefulWidget {
  final Widget child;
  const _LifecycleWrapper({required this.child});

  @override
  State<_LifecycleWrapper> createState() => _LifecycleWrapperState();
}

class _LifecycleWrapperState extends State<_LifecycleWrapper>
    with WidgetsBindingObserver {
  final _observer = _AppLifecycleObserver();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_observer);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
