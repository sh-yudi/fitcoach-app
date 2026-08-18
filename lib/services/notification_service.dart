import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/models.dart';
import 'api_client.dart';

/// Local notification scheduling.
///
/// - Meal reminders: fires `mealMinutes` before each meal, one-shot per day,
///   using the gym calendar (gym days get pre/post-workout meals, rest days get
///   the rest schedule).
/// - Workout reminder: fires `workoutMinutes` before the gym slot, only on
///   planned gym days.
/// - Gym check-in reminder: for non-morning workouts it asks about TODAY around
///   9 AM; for morning workouts it asks about TOMORROW the evening before at
///   10 PM. Tapping it opens the calendar check-in.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  void Function(String payload)? _onTap;

  static const _enabledKey = 'notif_enabled';
  static const _mealEnabledKey = 'notif_meal_enabled';
  static const _workoutEnabledKey = 'notif_workout_enabled';
  static const _mealMinutesKey = 'notif_meal_minutes';
  static const _workoutMinutesKey = 'notif_workout_minutes';

  bool _initialized = false;

  Future<void> init({void Function(String payload)? onTap}) async {
    _onTap = onTap;
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (res) {
        final p = res.payload;
        if (p != null && p.isNotEmpty) _onTap?.call(p);
      },
    );
    tzdata.initializeTimeZones();
    _initialized = true;
  }

  Future<bool> _ensurePermission() async {
    await init();
    // Android
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final enabled = await android.areNotificationsEnabled() ?? true;
      if (!enabled) {
        final granted = await android.requestNotificationsPermission() ?? false;
        if (!granted) return false;
      }
    }
    // iOS — explicitly request authorization
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final settings = await ios.checkPermissions();
      debugPrint('iOS notification settings: alert=${settings?.isAlertEnabled} badge=${settings?.isBadgeEnabled} sound=${settings?.isSoundEnabled}');
      final granted = await ios.requestPermissions(alert: true, sound: true, badge: false) ?? true;
      if (!granted) {
        debugPrint('iOS notification permission denied by user');
        return false;
      }
    }
    return true;
  }

  // ---------------- Settings ----------------

  Future<NotificationSettingsData> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSettingsData(
      enabled: prefs.getBool(_enabledKey) ?? true,
      mealEnabled: prefs.getBool(_mealEnabledKey) ?? true,
      workoutEnabled: prefs.getBool(_workoutEnabledKey) ?? true,
      mealMinutes: prefs.getInt(_mealMinutesKey) ?? 10,
      workoutMinutes: prefs.getInt(_workoutMinutesKey) ?? 20,
    );
  }

  Future<void> setSettings(NotificationSettingsData s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, s.enabled);
    await prefs.setBool(_mealEnabledKey, s.mealEnabled);
    await prefs.setBool(_workoutEnabledKey, s.workoutEnabled);
    await prefs.setInt(_mealMinutesKey, s.mealMinutes);
    await prefs.setInt(_workoutMinutesKey, s.workoutMinutes);
  }

  // ---------------- Scheduling ----------------

  /// Re-reads settings and (re)builds all reminders for the next 7 days.
  Future<void> sync() async {
    final s = await getSettings();
    await _cancelAll();
    if (!s.enabled) return;
    if (!await _ensurePermission()) return;

    try {
      final schedule = await ApiClient.instance.getSchedule();
      final profile = await ApiClient.instance.getProfile();
      final calendar = await ApiClient.instance.getGymCalendar();
      await _scheduleDays(s, schedule, profile.workoutTime, calendar);
    } catch (e, st) {
      debugPrint('NotificationService.sync error: $e\n$st');
    }
  }

  Future<void> _scheduleDays(
    NotificationSettingsData s,
    MealSchedule schedule,
    String workoutTime,
    ({Map<String, bool> gymPlans, Map<String, bool> attendance}) calendar,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    final todayKey = _dateKey(now);

    for (var offset = 0; offset < 7; offset++) {
      final day = now.add(Duration(days: offset));
      final key = _dateKey(day);
      final gymDay = calendar.gymPlans[key] ?? true;

      if (s.mealEnabled) {
        final meals = gymDay ? schedule.gym : schedule.rest;
        for (final meal in meals) {
          final t = _parseTime(meal.time);
          if (t == null) continue;
          await _scheduleOneShot(
            id: 100000 + (day.difference(DateTime(day.year)).inDays * 10) + meals.indexOf(meal),
            title: 'Time for ${_mealTitle(meal.meal)}',
            body: gymDay
                ? 'Your ${_mealTitle(meal.meal)} is in ${s.mealMinutes} min — ${meal.time}.'
                : '${_mealTitle(meal.meal)} at ${meal.time}.',
            hour: t.hour,
            minute: t.minute - s.mealMinutes,
            day: day,
          );
        }
      }

      if (s.workoutEnabled && gymDay) {
        final anchor = _workoutAnchor(workoutTime);
        await _scheduleOneShot(
          id: 900000 + day.difference(DateTime(day.year)).inDays,
          title: 'Workout in ${s.workoutMinutes} min',
          body: 'Get ready — your workout starts around ${anchor.label}.',
          hour: anchor.hour,
          minute: anchor.minute - s.workoutMinutes,
          day: day,
        );
      }
    }

    // Gym check-in reminder.
    final askDate = workoutTime == 'morning' ? todayKey : null;
    if (workoutTime == 'morning') {
      // Plan tomorrow night-before at 10 PM.
      if (!calendar.gymPlans.containsKey(askDate!)) {
        await _scheduleOneShot(
          id: 800000,
          title: 'Gym tomorrow?',
          body: 'Plan tomorrow\'s training now — is tomorrow a gym day?',
          hour: 22,
          minute: 0,
          day: now.add(const Duration(days: 1)),
          payload: 'gym_checkin:$askDate',
        );
      }
    } else if (!calendar.gymPlans.containsKey(todayKey)) {
      // Ask about today around 9 AM (schedule for tomorrow if 9 AM already passed).
      final d = now.hour < 9 ? now : now.add(const Duration(days: 1));
      await _scheduleOneShot(
        id: 800001,
        title: 'Gym today?',
        body: 'Are you going to the gym today?',
        hour: 9,
        minute: 0,
        day: d,
        payload: 'gym_checkin:${_dateKey(d)}',
      );
    }
  }

  Future<void> _scheduleOneShot({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required DateTime day,
    String? payload,
  }) async {
    final total = hour * 60 + minute;
    final norm = ((total % 1440) + 1440) % 1440;
    final scheduled = tz.TZDateTime(
      tz.local,
      day.year,
      day.month,
      day.day,
      norm ~/ 60,
      norm % 60,
    );
    final now = tz.TZDateTime.now(tz.local);
    if (scheduled.isBefore(now)) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fitcoach_reminders',
          'FitCoach Reminders',
          channelDescription: 'Meal, workout and gym check-in reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> _cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<void> sendTestNotification() async {
    await init();
    final granted = await _ensurePermission();
    debugPrint('Notification permission granted: $granted');
    try {
      await _plugin.show(
        999999,
        'FitCoach Test',
        'Notifications are working! You will receive meal and workout reminders.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fitcoach_reminders',
            'FitCoach Reminders',
            channelDescription: 'Meal, workout and gym check-in reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBanner: true,
          ),
        ),
      );
      debugPrint('Test notification sent successfully');
    } catch (e, st) {
      debugPrint('sendTestNotification error: $e\n$st');
    }
  }

  // ---------------- Helpers ----------------

  String _dateKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  ({int hour, int minute})? _parseTime(String time) {
    final m = RegExp(r'(\d{1,2}):(\d{2})\s*([AP]M)').firstMatch(time.trim());
    if (m == null) return null;
    var hour = int.parse(m.group(1)!);
    final minute = int.parse(m.group(2)!);
    final ap = m.group(3)!.toUpperCase();
    if (ap == 'PM' && hour != 12) hour += 12;
    if (ap == 'AM' && hour == 12) hour = 0;
    return (hour: hour, minute: minute);
  }

  ({int hour, int minute, String label}) _workoutAnchor(String workoutTime) {
    switch (workoutTime) {
      case 'morning':
        return (hour: 6, minute: 30, label: '6:30 AM');
      case 'midday':
        return (hour: 13, minute: 0, label: '1:00 PM');
      case 'afternoon':
        return (hour: 17, minute: 0, label: '5:00 PM');
      case 'evening':
        return (hour: 19, minute: 0, label: '7:00 PM');
      default:
        return (hour: 17, minute: 0, label: '5:00 PM');
    }
  }

  String _mealTitle(String name) => switch (name) {
        'preworkout' => 'pre-workout snack',
        'postworkout' => 'post-workout meal',
        'snack1' => 'morning snack',
        'snack2' => 'evening snack',
        _ => name.replaceAll('_', ' '),
      };
}

class NotificationSettingsData {
  final bool enabled;
  final bool mealEnabled;
  final bool workoutEnabled;
  final int mealMinutes;
  final int workoutMinutes;

  const NotificationSettingsData({
    this.enabled = false,
    this.mealEnabled = true,
    this.workoutEnabled = true,
    this.mealMinutes = 10,
    this.workoutMinutes = 20,
  });

  NotificationSettingsData copyWith({
    bool? enabled,
    bool? mealEnabled,
    bool? workoutEnabled,
    int? mealMinutes,
    int? workoutMinutes,
  }) =>
      NotificationSettingsData(
        enabled: enabled ?? this.enabled,
        mealEnabled: mealEnabled ?? this.mealEnabled,
        workoutEnabled: workoutEnabled ?? this.workoutEnabled,
        mealMinutes: mealMinutes ?? this.mealMinutes,
        workoutMinutes: workoutMinutes ?? this.workoutMinutes,
      );
}
