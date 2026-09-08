import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';

const kMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

const kWaterExclude = {'preworkout', 'postworkout'};

String todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String mealTitle(String name) => switch (name) {
  'preworkout' => 'pre-workout snack',
  'postworkout' => 'post-workout meal',
  'snack1' => 'morning snack',
  'snack2' => 'evening snack',
  _ => name.replaceAll('_', ' '),
};

double? parseNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().replaceAll(',', '.'));
}

/// Reads the first matching numeric key from a map (num or numeric string).
/// Used by the streak summaries on Home and the streak detail screen so they
/// agree on the same defensive parsing.
int intFrom(Object? m, List<String> keys) {
  final d = m is Map ? m : const <String, dynamic>{};
  for (final k in keys) {
    final v = d[k];
    if (v is num) return v.toInt();
    if (v is String) {
      final n = int.tryParse(v);
      if (n != null) return n;
    }
  }
  return 0;
}

DateTime parseDate(dynamic e) {
  final d = e is Map ? e['date'] : e;
  if (d is String) return DateTime.tryParse(d) ?? DateTime.fromMillisecondsSinceEpoch(0);
  if (d is num) return DateTime.fromMillisecondsSinceEpoch(d.toInt());
  return DateTime.fromMillisecondsSinceEpoch(0);
}

String formatValue(double? v, {String unit = ''}) {
  if (v == null || v <= 0) return '—';
  final s = v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return '$s$unit';
}

Future<Set<String>> loadWaterDone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList('water_done_${todayKey()}')?.toSet() ?? {};
}

/// Water-chip ids used across the diet and Today's Progress screens. Keeping
/// them in one place guarantees both screens toggle the same keys.
String waterBeforeId(String mealName) => '${mealName}_before';

String waterAfterId(String mealName) => '${mealName}_after';

/// Converts an inch measurement to centimetres (rounded). Returns null when
/// the input is blank or unparseable.
int? inchesToCm(dynamic v) {
  if (v == null) return null;
  final n = v is num ? v.toDouble() : double.tryParse(v.toString());
  if (n == null) return null;
  return (n * 2.54).round();
}

Future<Set<String>> toggleWaterDone(Set<String> current, String id) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'water_done_${todayKey()}';
  final list = prefs.getStringList(key) ?? [];
  if (current.contains(id)) {
    list.remove(id);
  } else {
    list.add(id);
  }
  await prefs.setStringList(key, list);
  final updated = Set<String>.from(current);
  if (updated.contains(id)) {
    updated.remove(id);
  } else {
    updated.add(id);
  }
  return updated;
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
