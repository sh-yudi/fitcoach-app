import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../../theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/section_header.dart';
import 'diet_scan_screen.dart';
import 'today_progress_screen.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key, this.refreshToken = 0});

  final int refreshToken;

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> with SingleTickerProviderStateMixin {
  DietPlan? _diet;
  Assessment? _assessment;
  bool _gymToday = true;
  bool _toggling = false;
  bool _loading = true;
  String? _error;
  late AnimationController _scanAnimController;
  Set<String> _waterDone = {};

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    super.dispose();
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
      await _loadWaterDone();
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
    try {
      await ApiClient.instance.setGymPlan(todayKey(), !_gymToday);
      await _load();
      NotificationService.instance.sync();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
    if (!mounted) return;
    setState(() => _toggling = false);
  }

  Future<void> _loadWaterDone() async {
    final done = await loadWaterDone();
    if (!mounted) return;
    setState(() { _waterDone = done; });
  }

  Future<void> _toggleWater(String id) async {
    final updated = await toggleWaterDone(_waterDone, id);
    setState(() { _waterDone = updated; });
  }

  List<Widget> _buildMealsWithWater() {
    if (_diet == null) return [];
    final widgets = <Widget>[];
    for (final meal in _diet!.meals) {
      // ── Before water chip ──
      if (!kWaterExclude.contains(meal.name)) {
        final id = '${meal.name}_before';
        widgets.add(_WaterChip(
          ml: '300–500',
          label: 'Drink before ${mealTitle(meal.name)}',
          hint: '30–40 min before your meal',
          done: _waterDone.contains(id),
          onToggle: () => _toggleWater(id),
        ));
        widgets.add(const SizedBox(height: 8));
      }
      // ── Meal card ──
      widgets.add(_MealCard(meal: meal));
      widgets.add(const SizedBox(height: 8));
      // ── After water chip ──
      if (!kWaterExclude.contains(meal.name)) {
        final id = '${meal.name}_after';
        widgets.add(_WaterChip(
          ml: '300–500',
          label: 'Drink after ${mealTitle(meal.name)}',
          hint: '30–40 min after your meal',
          done: _waterDone.contains(id),
          onToggle: () => _toggleWater(id),
        ));
        widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Diet Plan'),
      ),
      body: SafeArea(
        child: _loading
            ?  Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        _MacroSummary(assessment: _assessment!),
                        const SizedBox(height: 16),
                        _ScanFoodBanner(animController: _scanAnimController),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _GymDayBanner(gymDay: _gymToday, toggling: _toggling, onToggle: _toggleGymDay)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const TodayProgressScreen()),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.water_drop, color: Color(0xFF3DA5FF), size: 18),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${_diet!.waterLiters} L',
                                            style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                                          ),
                                          const Spacer(),
                                          Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 12),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${_diet!.calories} kcal',
                                        style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'P ${_diet!.protein}g · C ${_diet!.carbs}g · F ${_diet!.fiber}g',
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const SectionHeader(title: 'Meals'),
                        ..._buildMealsWithWater(),
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
              Expanded(child: _MacroBar(label: 'Protein', grams: a.protein, color: AppColors.macroProtein)),
              const SizedBox(width: 10),
              Expanded(child: _MacroBar(label: 'Carbs', grams: a.carbs, color: AppColors.macroCarbs)),
              const SizedBox(width: 10),
              Expanded(child: _MacroBar(label: 'Fiber', grams: a.fiber, color: AppColors.macroFiber)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(gymDay ? Icons.fitness_center : Icons.self_improvement, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  gymDay ? 'Gym Day' : 'Rest Day',
                  style: TextStyle(color: color, fontSize: 13.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            gymDay ? 'Pre & post-workout meals' : 'No workout meals',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: toggling ? null : onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: toggling
                  ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                  : Text(
                      gymDay ? 'Switch to rest' : 'Switch to gym',
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFoodBanner extends StatelessWidget {
  final AnimationController animController;
  const _ScanFoodBanner({required this.animController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animController,
      builder: (context, child) {
        final glow = 0.15 + (animController.value * 0.25);
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DietScanScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.9),
                  AppColors.primary.withValues(alpha: 0.65),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: glow),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan Your Food',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Take a photo to log calories instantly',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.7), size: 18),
              ],
            ),
          ),
        );
      },
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

  static String _iconFor(String meal) => switch (meal) {
    'breakfast' => '🌅',
    'snack1' => '🥜',
    'lunch' => '🍽️',
    'preworkout' => '⚡',
    'postworkout' => '🏋️',
    'dinner' => '🌙',
    _ => '🍴',
  };

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
            'P ${meal.items.fold<int>(0, (s, i) => s + i.protein.round()).toString()}g · C ${meal.items.fold<int>(0, (s, i) => s + i.carbs.round()).toString()}g',
            style:  TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _WaterChip extends StatelessWidget {
  final String ml;
  final String label;
  final String hint;
  final bool done;
  final VoidCallback? onToggle;
  const _WaterChip({required this.ml, required this.label, required this.hint, this.done = false, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: done
              ? AppColors.water.withValues(alpha: 0.12)
              : AppColors.water.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: done
                ? AppColors.water.withValues(alpha: 0.45)
                : AppColors.water.withValues(alpha: 0.20),
          ),
        ),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.water_drop,
              color: AppColors.water,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$ml ml · $label',
                    style: TextStyle(
                      color: done ? AppColors.textSecondary : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
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
            if (done)
              Icon(Icons.check_rounded, color: AppColors.water, size: 16),
          ],
        ),
      ),
    );
  }
}
