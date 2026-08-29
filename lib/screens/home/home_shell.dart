import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../calendar/calendar_screen.dart';
import '../diet/diet_screen.dart';
import '../fasting/fasting_screen.dart';
import '../profile/profile_screen.dart';
import '../progress/progress_screen.dart';
import '../workout/workout_screen.dart';
import 'home_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _refreshToken = 0;
  User? _user;
  Assessment? _assessment;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiClient.instance.getProfile(),
        ApiClient.instance.getAssessment(),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as User;
        _assessment = results[1] as Assessment;
      });
      NotificationService.instance.sync();
    } catch (_) {}
  }

  void _selectTab(int i) => setState(() => _index = i);

  void _refreshProfile(User user) {
    setState(() => _user = user);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _index != 0) {
          _selectTab(0);
        }
      },
      child: Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(user: _user, assessment: _assessment, onRefresh: _load, onOpenProfile: () => _selectTab(6)),
          DietScreen(refreshToken: _refreshToken),
          WorkoutScreen(refreshToken: _refreshToken),
          CalendarScreen(refreshToken: _refreshToken),
          const ProgressScreen(),
          const FastingScreen(),
          ProfileScreen(user: _user, onUpdated: _refreshProfile),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Diet'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Workout'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.show_chart_outlined), selectedIcon: Icon(Icons.show_chart), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer), label: 'Fasting'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      ),
    );
  }
}
