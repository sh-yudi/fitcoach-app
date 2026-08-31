import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../utils/helpers.dart';

class TodayProgressScreen extends StatefulWidget {
  const TodayProgressScreen({super.key});

  @override
  State<TodayProgressScreen> createState() => _TodayProgressScreenState();
}

class _TodayProgressScreenState extends State<TodayProgressScreen> {
  DietPlan? _diet;
  Assessment? _assessment;
  bool _gymToday = true;
  bool _loading = true;
  String? _error;
  Set<String> _waterDone = {};
  Map<String, dynamic> _totals = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiClient.instance.getDiet(),
        ApiClient.instance.getLoggedFood(),
      ]);
      final r = results[0] as dynamic;
      final logged = results[1] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _diet = r.diet;
        _assessment = r.assessment;
        _gymToday = r.gymToday;
        _totals = (logged['totals'] as Map<String, dynamic>?) ?? {};
        _loading = false;
      });
      await _loadLocal();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    }
  }

  Future<void> _loadLocal() async {
    final done = await loadWaterDone();
    setState(() => _waterDone = done);
  }

  Future<void> _toggleWater(String id) async {
    final updated = await toggleWaterDone(_waterDone, id);
    setState(() { _waterDone = updated; });
  }

  List<_WaterSlot> _buildWaterSlots() {
    if (_diet == null) return [];
    final visible = _diet!.meals.where((m) => !kWaterExclude.contains(m.name)).toList();
    final slots = <_WaterSlot>[];
    for (final m in visible) {
      final beforeId = '${m.name}_before';
      final afterId = '${m.name}_after';
      slots.add(_WaterSlot(
        id: beforeId,
        ml: '300–500 ml',
        label: 'Before ${mealTitle(m.name)}',
        hint: '30–40 min before meal',
      ));
      slots.add(_WaterSlot(
        id: afterId,
        ml: '300–500 ml',
        label: 'After ${mealTitle(m.name)}',
        hint: '30–40 min after meal',
      ));
    }
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Progress")),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      _buildFoodProgress(),
                      const SizedBox(height: 16),
                      _buildWaterProgress(),
                      const SizedBox(height: 16),
                      _buildMacroSummary(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildWaterProgress() {
    final slots = _buildWaterSlots();
    final doneCount = slots.where((s) => _waterDone.contains(s.id)).length;
    final totalCount = slots.length;
    final pct = totalCount > 0 ? (doneCount / totalCount).clamp(0.0, 1.0) : 0.0;

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
              const Icon(Icons.water_drop, color: Color(0xFF3DA5FF), size: 20),
              const SizedBox(width: 8),
              Text(
                'Water Intake (300–500 ml)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(
                '$doneCount / $totalCount done',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.water.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF3DA5FF)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(pct * 100).round()}% complete · 300–500 ml before & after meals',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 14),
          ...slots.map((s) {
            final done = _waterDone.contains(s.id);
            return GestureDetector(
              onTap: () => _toggleWater(s.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: done
                      ? AppColors.water.withValues(alpha: 0.12)
                      : AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: done ? AppColors.water.withValues(alpha: 0.4) : AppColors.surfaceLight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: done ? AppColors.water : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s.ml} · ${s.label}',
                            style: TextStyle(
                              color: done ? AppColors.textSecondary : AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.hint,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              decoration: done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMacroSummary() {
    final a = _assessment!;
    final diet = _diet!;
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
              Icon(
                _gymToday ? Icons.fitness_center : Icons.self_improvement,
                color: _gymToday ? AppColors.success : AppColors.danger,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _gymToday ? 'Gym Day' : 'Rest Day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _gymToday ? AppColors.success : AppColors.danger,
                ),
              ),
              const Spacer(),
              Text(
                '${diet.calories} kcal target',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _MacroPill(label: 'Protein', value: '${a.protein}g', color: AppColors.macroProtein)),
              const SizedBox(width: 8),
              Expanded(child: _MacroPill(label: 'Carbs', value: '${a.carbs}g', color: AppColors.macroCarbs)),
              const SizedBox(width: 8),
              Expanded(child: _MacroPill(label: 'Fiber', value: '${a.fiber}g', color: AppColors.macroFiber)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'BMI ${(a.bmi ?? 0).toStringAsFixed(1)} \u00B7 BMR ${a.bmr} kcal \u00B7 TDEE ${a.tdee} kcal',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodProgress() {
    final a = _assessment;
    if (a == null) return const SizedBox();
    final consumedCal = (_totals['calories'] ?? 0) as num;
    final consumedP = (_totals['protein'] ?? 0) as num;
    final consumedC = (_totals['carbs'] ?? 0) as num;
    final consumedF = (_totals['fiber'] ?? 0) as num;
    final pct = a.calories > 0 ? (consumedCal / a.calories).clamp(0.0, 1.0) : 0.0;

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
              const Icon(Icons.restaurant, color: Color(0xFFFFB020), size: 20),
              const SizedBox(width: 8),
              Text(
                'Food Log',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(
                '${(pct * 100).round()}%',
                style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _logBar('Calories', consumedCal.toInt(), a.calories, 'kcal', AppColors.macroCarbs),
          const SizedBox(height: 10),
          _logBar('Protein', consumedP.toInt(), a.protein, 'g', AppColors.macroProtein),
          const SizedBox(height: 10),
          _logBar('Carbs', consumedC.toInt(), a.carbs, 'g', AppColors.macroCarbs),
          const SizedBox(height: 10),
          _logBar('Fiber', consumedF.toInt(), a.fiber, 'g', AppColors.macroFiber),
          const SizedBox(height: 12),
          Text(
            a.calories - consumedCal.toInt() > 0
                ? '${a.calories - consumedCal.toInt()} kcal remaining'
                : 'Daily calorie target reached!',
            style: TextStyle(
              color: a.calories - consumedCal.toInt() > 0
                  ? AppColors.textSecondary
                  : AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _logBar(String label, int current, int target, String unit, Color color) {
    final pct = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            Text(
              '$current / $target $unit',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _WaterSlot {
  final String id;
  final String ml;
  final String label;
  final String hint;
  const _WaterSlot({required this.id, required this.ml, required this.label, required this.hint});
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
