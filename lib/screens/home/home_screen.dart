import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/personal_training_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/streak_card.dart';
import '../diet/diet_screen.dart';
import '../workout/workout_screen.dart';

class HomeScreen extends StatefulWidget {
  final User? user;
  final Assessment? assessment;
  final Future<void> Function() onRefresh;
  final VoidCallback? onOpenProfile;

  const HomeScreen({super.key, this.user, this.assessment, required this.onRefresh, this.onOpenProfile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _blinked = false;
  Map<String, dynamic>? _streaks;

  @override
  void initState() {
    super.initState();
    _loadStreaks();
  }

  Future<void> _loadStreaks() async {
    try {
      final s = await ApiClient.instance.getStreaks();
      if (!mounted) return;
      setState(() => _streaks = s);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final a = widget.assessment;
    final firstName = u?.name.split(' ').first ?? 'there';

    final bmiOut = a?.bmi != null && (a!.bmi! < 18.5 || a.bmi! >= 25);
    final bf = a?.bodyFatPct;
    final bfOut = bf != null && (bf < a!.targetFatMin || bf > a.targetFatMax);
    // Blink only on the very first render after the assessment loads.
    final blink = !_blinked;
    if (a != null) _blinked = true;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await widget.onRefresh();
            await _loadStreaks();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi $firstName,',
                          style:  TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: widget.onOpenProfile,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    u != null ? '${u.weightKg} kg · ${u.heightCm} cm · ${_cap(u.activityLevel)}' : 'Loading profile…',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                ),
                                if (u != null) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 14),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child:  Icon(Icons.fitness_center, color: AppColors.onPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _GoalBanner(assessment: a),
              const SizedBox(height: 20),
              if (_streaks != null) ...[
                StreakCard(data: _streaks),
                const SizedBox(height: 20),
              ],
              if (a != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Body Fat',
                        value: a.bodyFatPct != null ? '${a.bodyFatPct}%' : '—',
                        sub: bfOut
                            ? (bf > a.targetFatMax
                                ? 'Above target (${a.targetFatMin}–${a.targetFatMax}%)'
                                : 'Below target (${a.targetFatMin}–${a.targetFatMax}%)')
                            : 'Target ${a.targetFatMin}–${a.targetFatMax}%',
                        icon: Icons.water_drop_outlined,
                        accent: AppColors.primary,
                        alert: bfOut,
                        blink: blink && bfOut,
                        onTap: () => _showBodyFatInfo(context, u, a),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'BMI',
                        value: a.bmi?.toString() ?? '—',
                        sub: _bmiSub(a),
                        icon: Icons.speed,
                        accent: AppColors.success,
                        alert: bmiOut,
                        blink: blink && bmiOut,
                        onTap: () => _showBmiInfo(context, u, a),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Daily Calories',
                        value: a.calories > 0 ? '${a.calories} kcal' : '—',
                        sub: '${a.protein}g P · ${a.carbs}g C · ${a.fiber}g F',
                        icon: Icons.local_fire_department_outlined,
                        accent: AppColors.macroCarbs,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Goal',
                        value: _goalLabel(a.goal),
                        sub: a.weeksToTarget != null && a.weeksToTarget! > 0
                            ? '~${a.weeksToTarget} weeks to target'
                            : 'On target',
                        icon: Icons.flag_outlined,
                        accent: AppColors.macroFiber,
                        onTap: () => _showGoalPicker(context, u, a),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Today\'s plan'),
                Row(
                  children: [
                    Expanded(
                      child: _PlanTile(
                        icon: Icons.restaurant,
                        title: 'Diet Plan',
                        subtitle: '${a.calories} kcal · ${a.protein}g protein',
                        color: AppColors.macroCarbs,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DietScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PlanTile(
                        icon: Icons.fitness_center,
                        title: 'Workout',
                        subtitle: 'Weekly schedule',
                        color: AppColors.primary,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const WorkoutScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else
                 Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                  ),
                ),
              const SizedBox(height: 24),
              const PersonalTrainingCard(),
              const SizedBox(height: 24),
              const AdBanner(),
            ],
          ),
        ),
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  String _goalLabel(String g) => g == 'cut' ? 'Cut fat' : g == 'bulk' ? 'Build muscle' : 'Maintain';

  static const _bmiMin = 18.5;
  static const _bmiMax = 24.9;
  String _bmiSub(Assessment a) {
    final b = a.bmi;
    if (b == null) return 'Target $_bmiMin–$_bmiMax';
    if (b < _bmiMin) return 'Below target ($_bmiMin–$_bmiMax)';
    if (b > _bmiMax) return 'Above target ($_bmiMin–$_bmiMax)';
    return 'Target $_bmiMin–$_bmiMax';
  }

  void _showGoalPicker(BuildContext context, User? u, Assessment a) {
    final recommended = _recommendedGoal(u, a);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
               Text(
                'Choose your goal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
               Text(
                'Plans and calorie targets update instantly.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              _GoalOption(
                value: 'cut',
                title: 'Cut fat',
                subtitle: '20% calorie deficit · faster fat loss',
                icon: Icons.trending_down,
                recommended: recommended == 'cut',
                selected: a.goal == 'cut',
                onTap: () => _selectGoal(ctx, 'cut'),
              ),
              const SizedBox(height: 10),
              _GoalOption(
                value: 'bulk',
                title: 'Build muscle',
                subtitle: 'Lean surplus · steady muscle gain',
                icon: Icons.trending_up,
                recommended: recommended == 'bulk',
                selected: a.goal == 'bulk',
                onTap: () => _selectGoal(ctx, 'bulk'),
              ),
              const SizedBox(height: 10),
              _GoalOption(
                value: 'maintain',
                title: 'Maintain',
                subtitle: 'Hold your current physique',
                icon: Icons.eco,
                recommended: recommended == 'maintain',
                selected: a.goal == 'maintain',
                onTap: () => _selectGoal(ctx, 'maintain'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _recommendedGoal(User? u, Assessment a) {
    final bf = a.bodyFatPct ?? 0;
    if (bf > a.targetFatMax) return 'cut';
    if (bf < a.targetFatMin) return 'bulk';
    return 'maintain';
  }

  void _selectGoal(BuildContext ctx, String goal) {
    Navigator.of(ctx).pop();
    ApiClient.instance.updateGoal(goal).then((_) {
      if (mounted) widget.onRefresh();
    }).catchError((_) {});
  }

  void _showBmiInfo(BuildContext context, User? u, Assessment a) {
    _showMetricSheet(
      context,
      title: 'BMI',
      value: a.bmi?.toString() ?? '—',
      category: a.bmiCategory,
      inputs: {
        'Weight': u != null ? '${u.weightKg} kg' : '—',
        'Height': u != null ? '${u.heightCm} cm' : '—',
      },
      steps: [
        'Convert height to metres: height (cm) ÷ 100',
        'Square it: height (m) × height (m)',
        'Divide: weight (kg) ÷ height (m)²',
      ],
      formula: 'BMI = weight (kg) / height (m)²',
    );
  }

  void _showBodyFatInfo(BuildContext context, User? u, Assessment a) {
    final hasNavy = (u?.waistCm ?? 0) > 0 && (u?.neckCm ?? 0) > 0;

    String inches(num? cm) => (cm! / 2.54).toStringAsFixed(1);
    _showMetricSheet(
      context,
      title: 'Body Fat %',
      value: a.bodyFatPct != null ? '${a.bodyFatPct}%' : '—',
      category: 'Estimated',
      inputs: {
        if (u != null) 'Gender': _cap(u.gender),
        if (u != null) 'Age': '${u.age} years',
        if (u != null) 'Height': '${u.heightCm} cm',
        if (u != null && hasNavy) 'Waist': '${u.waistCm} cm (${inches(u.waistCm!)} in)',
        if (u != null && hasNavy) 'Neck': '${u.neckCm} cm (${inches(u.neckCm!)} in)',
        if (u != null && hasNavy && u.hipCm != null) 'Hip': '${u.hipCm} cm (${inches(u.hipCm!)} in)',
      },
      steps: hasNavy
          ? u!.gender == 'male'
              ? [
                  'Convert height, waist & neck to inches',
                  'Compute waist − neck',
                  'Substitute into the US Navy equation',
                ]
              : [
                  'Convert height, waist, neck & hip to inches',
                  'Compute waist + hip − neck',
                  'Substitute into the US Navy equation',
                ]
          : [
              'Uses BMI and age (Deurenberg formula)',
              'Applied when no waist/neck measurements are saved',
              'Add waist & neck measurements for a more accurate estimate',
            ],
      formula: hasNavy
          ? u!.gender == 'male'
              ? 'BF% = 495 / (1.0324 − 0.19077·log10(waist−neck) + 0.15456·log10(height)) − 450'
              : 'BF% = 495 / (1.29579 − 0.35004·log10(waist+hip−neck) + 0.221·log10(height)) − 450'
          : 'BF% = 1.2·BMI + 0.23·age − 10.8·sex − 5.4',
    );
  }

  void _showMetricSheet(
    BuildContext context, {
    required String title,
    required String value,
    required String category,
    required Map<String, String> inputs,
    required List<String> steps,
    required String formula,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style:  TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '$title · $category',
                      style:  TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
               Text(
                'Values used',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: inputs.entries
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(e.key, style:  TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              ),
                              Text(e.value, style:  TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
               Text(
                'Formula',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  formula,
                  style:  TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5),
                ),
              ),
              const SizedBox(height: 20),
               Text(
                'How it is calculated',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              ...steps.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(right: 10, top: 1),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text(
                              '${e.key + 1}',
                              style:  TextStyle(color: AppColors.onPrimary, fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                          Expanded(
                            child: Text(e.value, style:  TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalBanner extends StatelessWidget {
  final Assessment? assessment;
  const _GoalBanner({this.assessment});

  @override
  Widget build(BuildContext context) {
    final a = assessment;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkGreen, Color(0xFF4A6B1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              a?.goal == 'cut' ? Icons.trending_down : a?.goal == 'bulk' ? Icons.trending_up : Icons.eco,
              color: const Color(0xFFFFF3D6),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a != null ? _title(a.goal) : 'Preparing your plan…',
                  style: TextStyle(color: AppColors.cream, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  a != null
                      ? 'Body fat ${a.bodyFatPct ?? '—'}% → target ${a.targetFatMin}–${a.targetFatMax}%'
                      : 'Calculating your numbers',
                  style: const TextStyle(color: Color(0xFFDDE6C2), fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _title(String g) => g == 'cut' ? 'Fat loss phase' : g == 'bulk' ? 'Lean bulk phase' : 'Maintenance phase';
}

class _PlanTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _PlanTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title, style:  TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 3),
            Text(subtitle, style:  TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 10),
             Text('Open  →', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool recommended;
  final bool selected;
  final VoidCallback onTap;

  const _GoalOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.recommended,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: selected ? AppColors.onPrimary : AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: selected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child:  Text(
                            'Recommended',
                            style: TextStyle(color: AppColors.success, fontSize: 9.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style:  TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (selected)
               Icon(Icons.check_circle, color: AppColors.primary, size: 20)
            else
               Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
