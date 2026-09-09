import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/body_composition_sheet.dart';
import '../../widgets/personal_training_card.dart';
import '../../widgets/section_header.dart';

import '../diet/today_progress_screen.dart';
import 'streak_detail_screen.dart';
import '../../widgets/app_pinch_zoom.dart';

class HomeScreen extends StatefulWidget {
  final User? user;
  final Assessment? assessment;
  final Future<void> Function() onRefresh;
  final VoidCallback? onOpenProfile;
  final int refreshToken;

  const HomeScreen({
    super.key,
    this.user,
    this.assessment,
    required this.onRefresh,
    this.onOpenProfile,
    this.refreshToken = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _streaks;
  int _todayCalories = 0;
  int _todayProtein  = 0;
  int _todayCarbs    = 0;
  int _todayFiber    = 0;

  @override
  void initState() {
    super.initState();
    _loadStreaks();
    _loadTodayMacros();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) {
      _loadStreaks();
      _loadTodayMacros();
    }
  }

  Future<void> _loadStreaks() async {
    try {
      final s = await ApiClient.instance.getStreaks();
      if (!mounted) return;
      setState(() => _streaks = s);
    } catch (_) {}
  }

  Future<void> _loadTodayMacros() async {
    try {
      final log = await ApiClient.instance.getLoggedFood();
      if (!mounted) return;
      final totals = log['totals'];
      int cal = 0, pro = 0, carb = 0, fib = 0;
      if (totals is Map) {
        int parse(dynamic v) => v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
        cal  = parse(totals['calories']);
        pro  = parse(totals['protein']);
        carb = parse(totals['carbs']);
        fib  = parse(totals['fiber']);
      }
      setState(() {
        _todayCalories = cal;
        _todayProtein  = pro;
        _todayCarbs    = carb;
        _todayFiber    = fib;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final a = widget.assessment;
    final firstName = u?.name.split(' ').first ?? 'there';

    return Scaffold(
      body: AppPinchZoom(
        child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await widget.onRefresh();
            await _loadStreaks();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // Top Greeting & Profile Header
              _buildHeader(u, firstName),
              const SizedBox(height: 18),

              if (a != null) ...[
                // Unified Daily Momentum Hero Card
                _DailyMomentumCard(
                  user: u,
                  assessment: a,
                  streaks: _streaks,
                  todayCalories: _todayCalories,
                  todayProtein: _todayProtein,
                  todayCarbs: _todayCarbs,
                  todayFiber: _todayFiber,
                  onSelectGoal: () => _showGoalPicker(context, u, a),
                  onOpenStreak: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => StreakDetailScreen(initialData: _streaks)),
                  ),
                  onOpenTodayProgress: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TodayProgressScreen()),
                  ),
                ),
                const SizedBox(height: 18),

                // Health & Body Composition 2-Column Hub
                const SectionHeader(title: 'Body & Health Metrics'),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _MetricHubCard(
                        title: 'Body Fat',
                        value: a.bodyFatPct != null ? '${a.bodyFatPct}%' : '—',
                        category: a.bodyFatCategory.isNotEmpty ? a.bodyFatCategory : 'Estimated',
                        badgeColor: (a.bodyFatPct ?? 0) > a.targetFatMax
                            ? AppColors.danger
                            : ((a.bodyFatPct ?? 0) < a.targetFatMin ? AppColors.macroCarbs : AppColors.primary),
                        subtitle: 'Target ${a.targetFatMin.toInt()}–${a.targetFatMax.toInt()}%',
                        detailText: a.leanMassKg != null && a.fatMassKg != null
                            ? '${a.leanMassKg}kg Lean · ${a.fatMassKg}kg Fat'
                            : (a.ffmi != null ? 'FFMI ${a.ffmi} (${a.ffmiCategory})' : 'Tap for suite & gauge'),
                        icon: Icons.water_drop_outlined,
                        onTap: () => showBodyCompositionSheet(
                          context,
                          user: u,
                          assessment: a,
                          onUpdated: widget.onRefresh,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricHubCard(
                        title: 'BMI',
                        value: a.bmi?.toString() ?? '—',
                        category: a.bmiCategory.isNotEmpty ? a.bmiCategory : 'Normal',
                        badgeColor: (a.bmi ?? 22) < 18.5 || (a.bmi ?? 22) >= 25 ? AppColors.macroCarbs : AppColors.success,
                        subtitle: 'Target 18.5–24.9',
                        detailText: a.weeksToTarget != null && a.weeksToTarget! > 0
                            ? '~${a.weeksToTarget} wks to goal'
                            : 'Healthy weight range',
                        icon: Icons.speed,
                        onTap: () => _showBmiInfo(context, u, a),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                  ),
                ),
              ],

              const PersonalTrainingCard(),
              const SizedBox(height: 20),
              const AdBanner(),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildHeader(User? u, String firstName) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi $firstName,',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
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
        InkWell(
          onTap: widget.onOpenProfile,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.fitness_center, color: AppColors.onPrimary),
          ),
        ),
      ],
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

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

// ─────────────────────────────────────────────────────────────────────────────
// UNIFIED DAILY MOMENTUM HERO CARD
// ─────────────────────────────────────────────────────────────────────────────
class _DailyMomentumCard extends StatelessWidget {
  final User? user;
  final Assessment assessment;
  final Map<String, dynamic>? streaks;
  final int todayCalories;
  final int todayProtein;
  final int todayCarbs;
  final int todayFiber;
  final VoidCallback onSelectGoal;
  final VoidCallback onOpenStreak;
  final VoidCallback onOpenTodayProgress;

  const _DailyMomentumCard({
    required this.user,
    required this.assessment,
    required this.streaks,
    required this.todayCalories,
    required this.todayProtein,
    required this.todayCarbs,
    required this.todayFiber,
    required this.onSelectGoal,
    required this.onOpenStreak,
    required this.onOpenTodayProgress,
  });

  String _goalTitle(String g) => g == 'cut' ? 'Fat loss phase' : g == 'bulk' ? 'Lean bulk phase' : 'Maintenance phase';

  @override
  Widget build(BuildContext context) {
    final a = assessment;
    final streak = intFrom(streaks, ['currentStreak', 'current', 'streak']);
    final calTarget = a.calories > 0 ? a.calories : 1;
    final overCal = todayCalories > calTarget;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLight, width: 1.2),
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.surfaceLight.withValues(alpha: 0.35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Goal Phase Chip + Tappable Streak Pill ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onSelectGoal,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        a.goal == 'cut' ? Icons.trending_down : (a.goal == 'bulk' ? Icons.trending_up : Icons.eco),
                        color: AppColors.primary, size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(_goalTitle(a.goal),
                          style: TextStyle(color: AppColors.primary, fontSize: 12.5, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, color: AppColors.primary, size: 14),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: onOpenStreak,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.streak.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.streak.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12.5)),
                      const SizedBox(width: 4),
                      Text('$streak day${streak == 1 ? '' : 's'} streak',
                          style: const TextStyle(color: AppColors.streak, fontSize: 12.5, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: AppColors.streak, size: 13),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Daily Target + Macro Progress (tappable -> TodayProgressScreen) ──
          GestureDetector(
            onTap: onOpenTodayProgress,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.local_fire_department, color: AppColors.macroCarbs, size: 18),
                        const SizedBox(width: 6),
                        Text('Daily Target',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
                      ]),
                      Row(children: [
                        Text(
                          '$todayCalories',
                          style: TextStyle(
                            color: overCal ? AppColors.danger : AppColors.primary,
                            fontSize: 15, fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          ' / ${a.calories} kcal',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (todayCalories / calTarget).clamp(0.0, 1.0),
                      backgroundColor: AppColors.surfaceLight,
                      color: overCal ? AppColors.danger : AppColors.macroCarbs,
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _MacroPill(
                        label: 'Protein',
                        consumed: todayProtein,
                        target: a.protein,
                        color: AppColors.macroProtein,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _MacroPill(
                        label: 'Carbs',
                        consumed: todayCarbs,
                        target: a.carbs,
                        color: AppColors.macroCarbs,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _MacroPill(
                        label: 'Fiber',
                        consumed: todayFiber,
                        target: a.fiber,
                        color: AppColors.macroFiber,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MACRO PILL (progress box)
// ─────────────────────────────────────────────────────────────────────────────
class _MacroPill extends StatelessWidget {
  final String label;
  final int consumed;
  final int target;
  final Color color;

  const _MacroPill({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = target > 0 ? target : 1;
    final progress = (consumed / t).clamp(0.0, 1.0);
    final over = consumed > t;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$consumed',
                  style: TextStyle(color: over ? AppColors.danger : color, fontSize: 14, fontWeight: FontWeight.w900),
                ),
                Text(
                  ' / ${target}g',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceLight,
              color: over ? AppColors.danger : color,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2-COLUMN METRIC HUB CARD
// ─────────────────────────────────────────────────────────────────────────────
class _MetricHubCard extends StatelessWidget {
  final String title;
  final String value;
  final String category;
  final Color badgeColor;
  final String subtitle;
  final String detailText;
  final IconData icon;
  final VoidCallback onTap;

  const _MetricHubCard({
    required this.title,
    required this.value,
    required this.category,
    required this.badgeColor,
    required this.subtitle,
    required this.detailText,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      detailText,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 9.5, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 8, color: AppColors.textSecondary),
                ],
              ),
            ),
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
