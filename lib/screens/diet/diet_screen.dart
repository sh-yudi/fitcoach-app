import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../../theme.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/section_header.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key, this.refreshToken = 0});

  final int refreshToken;

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  DietPlan? _diet;
  Assessment? _assessment;
  bool _gymToday = true;
  bool _toggling = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(DietScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) {
      _load();
    }
  }

  Future<void> _load() async {
    if (_diet == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final r = await ApiClient.instance.getDiet();
      if (!mounted) return;
      setState(() {
        _diet = r.diet;
        _assessment = r.assessment;
        _gymToday = r.gymToday;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _toggleGymDay() async {
    if (_toggling) return;
    setState(() => _toggling = true);
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final dateKey = '${now.year}-$m-$d';
    try {
      await ApiClient.instance.setGymPlan(dateKey, !_gymToday);
      await _load();
      NotificationService.instance.sync();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
    if (!mounted) return;
    setState(() => _toggling = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Diet Plan')),
      body: SafeArea(
        child: _loading
            ?  Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
            : _error != null
                ? _ErrorView(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        _MacroSummary(assessment: _assessment!),
                        const SizedBox(height: 16),
                        _GymDayBanner(gymDay: _gymToday, toggling: _toggling, onToggle: _toggleGymDay),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.water_drop, color: Color(0xFF3DA5FF)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Drink ${_diet!.waterLiters} L water daily · Target ${_diet!.calories} kcal · P ${_diet!.protein}g · C ${_diet!.carbs}g · F ${_diet!.fat}g',
                                  style:  TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const SectionHeader(title: 'Meals'),
                        ..._diet!.meals.map((m) => _MealCard(meal: m)),
                        const SizedBox(height: 12),
                        Text(
                          _diet!.note,
                          style:  TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        const AdBanner(),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _MacroSummary extends StatelessWidget {
  final Assessment assessment;
  const _MacroSummary({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final a = assessment;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Color(0xFFFFB020), size: 20),
              const SizedBox(width: 8),
              Text(
                '${a.calories} kcal / day',
                style:  TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(
                toTitleCase(a.goal),
                style:  TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _MacroBar(label: 'Protein', grams: a.protein, color: const Color(0xFF3DD68C))),
              const SizedBox(width: 10),
              Expanded(child: _MacroBar(label: 'Carbs', grams: a.carbs, color: const Color(0xFFFFB020))),
              const SizedBox(width: 10),
              Expanded(child: _MacroBar(label: 'Fat', grams: a.fat, color: const Color(0xFF6C8CFF))),
            ],
          ),
        ],
      ),
    );
  }
}

class _GymDayBanner extends StatelessWidget {
  final bool gymDay;
  final bool toggling;
  final VoidCallback onToggle;
  const _GymDayBanner({required this.gymDay, required this.toggling, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final color = gymDay ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(gymDay ? Icons.fitness_center : Icons.self_improvement, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gymDay ? 'Gym day today' : 'Rest day today',
                  style: TextStyle(color: color, fontSize: 13.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  gymDay
                      ? 'Plan includes pre & post-workout meals'
                      : 'Plan skips pre & post-workout meals',
                  style:  TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: toggling ? null : onToggle,
            style: TextButton.styleFrom(foregroundColor: color),
            child: toggling
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  )
                : Text(gymDay ? 'Switch to rest' : 'Switch to gym day'),
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final int grams;
  final Color color;
  const _MacroBar({required this.label, required this.grams, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 6,
          decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(3)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(width: 44, height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style:  TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
        Text('$grams g', style:  TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final Meal meal;
  const _MealCard({required this.meal});

  String _iconFor(String meal) {
    switch (meal) {
      case 'breakfast':
        return '🌅';
      case 'snack1':
        return '🥜';
      case 'lunch':
        return '🍽️';
      case 'preworkout':
        return '⚡';
      case 'postworkout':
        return '🏋️';
      case 'dinner':
        return '🌙';
      default:
        return '🍴';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_iconFor(meal.name), style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  toTitleCase(meal.name),
                  style:  TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
              if (meal.time.isNotEmpty) ...[
                 Icon(Icons.schedule, color: AppColors.textSecondary, size: 14),
                const SizedBox(width: 4),
                Text(
                  meal.time,
                  style:  TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
              const SizedBox(width: 10),
              Text(
                '${meal.kcal} kcal',
                style:  TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (meal.tip.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                   Icon(Icons.lightbulb_outline, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      meal.tip,
                      style:  TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...meal.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration:  BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.name,
                      style:  TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                    ),
                  ),
                  Text(
                    '${item.grams}g · ${item.kcal}kcal',
                    style:  TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ),
           Divider(color: AppColors.surfaceLight, height: 16),
          Text(
            'P ${meal.items.fold<int>(0, (s, i) => s + i.protein.round()).toString()}g · C ${meal.items.fold<int>(0, (s, i) => s + i.carbs.round()).toString()}g · F ${meal.items.fold<int>(0, (s, i) => s + i.fat.round()).toString()}g',
            style:  TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

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
            Text(message, textAlign: TextAlign.center, style:  TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
