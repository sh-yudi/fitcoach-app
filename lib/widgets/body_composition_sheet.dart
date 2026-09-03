import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../theme.dart';

/// Opens the rich Body Composition & Body Fat suite modal sheet.
void showBodyCompositionSheet(BuildContext context, {required User? user, required Assessment? assessment, required VoidCallback onUpdated}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BodyCompositionSheet(user: user, assessment: assessment, onUpdated: onUpdated),
  );
}

class _BodyCompositionSheet extends StatefulWidget {
  final User? user;
  final Assessment? assessment;
  final VoidCallback onUpdated;

  const _BodyCompositionSheet({required this.user, required this.assessment, required this.onUpdated});

  @override
  State<_BodyCompositionSheet> createState() => _BodyCompositionSheetState();
}

class _BodyCompositionSheetState extends State<_BodyCompositionSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assessment;
    final u = widget.user;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 25,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.speed_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Body Composition & Fat %',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'ACE Standards · FFMI · Lean Mass Breakdown',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textSecondary, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: AppColors.onPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'Meter'),
                  Tab(text: 'Calculator'),
                  Tab(text: 'Simulator'),
                  Tab(text: 'Guide'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(user: u, assessment: a),
                  _CalculatorTab(user: u, assessment: a, onSaved: () {
                    widget.onUpdated();
                    if (mounted) setState(() {});
                  }),
                  _SimulatorTab(user: u, assessment: a),
                  _GuideTab(gender: u?.gender ?? 'male'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 1. OVERVIEW TAB: GAUGE METER + COMPOSITION + FFMI
// ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final User? user;
  final Assessment? assessment;

  const _OverviewTab({required this.user, required this.assessment});

  @override
  Widget build(BuildContext context) {
    final a = assessment;
    final u = user;
    final bf = a?.bodyFatPct ?? 15.0;
    final category = a?.bodyFatCategory ?? 'Fitness';
    final isMale = (u?.gender ?? 'male') == 'male';

    final weight = u?.weightKg.toDouble() ?? 70.0;
    final leanMass = a?.leanMassKg ?? (weight * (1 - bf / 100));
    final fatMass = a?.fatMassKg ?? (weight * (bf / 100));
    final ffmi = a?.normalizedFfmi ?? a?.ffmi;
    final ffmiCat = a?.ffmiCategory ?? 'Average';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Semicircular Gauge Card
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.surface, AppColors.surfaceLight.withValues(alpha: 0.5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Body Fat Meter',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getCategoryColor(category).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _getCategoryColor(category),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Visual Gauge Meter
                SizedBox(
                  height: 155,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _BodyFatGaugePainter(
                      bodyFat: bf,
                      isMale: isMale,
                      targetMin: a?.targetFatMin ?? (isMale ? 14 : 21),
                      targetMax: a?.targetFatMax ?? (isMale ? 17 : 24),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${bf.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Target: ${(a?.targetFatMin ?? (isMale ? 14 : 21)).toInt()}–${(a?.targetFatMax ?? (isMale ? 17 : 24)).toInt()}%',
                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Category spectrum legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _legendItem('Essential', const Color(0xFF3B82F6)),
                    _legendItem('Athletic', const Color(0xFF10B981)),
                    _legendItem('Fitness', const Color(0xFF6366F1)),
                    _legendItem('Average', const Color(0xFFF59E0B)),
                    _legendItem('High', const Color(0xFFEF4444)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dual Body Composition Breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Body Composition',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Total: ${weight.toStringAsFixed(1)} kg',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Split Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 22,
                    child: Row(
                      children: [
                        Expanded(
                          flex: ((100 - bf) * 10).toInt().clamp(1, 1000),
                          child: Container(
                            color: const Color(0xFF10B981),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              'Lean ${(100 - bf).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: (bf * 10).toInt().clamp(1, 1000),
                          child: Container(
                            color: const Color(0xFFEF4444),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              'Fat ${bf.toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _compStat(
                        title: 'Lean Body Mass',
                        value: '${leanMass.toStringAsFixed(1)} kg',
                        subtitle: 'Muscles, Bones & Water',
                        accent: const Color(0xFF10B981),
                        icon: Icons.fitness_center_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _compStat(
                        title: 'Fat Mass',
                        value: '${fatMass.toStringAsFixed(1)} kg',
                        subtitle: 'Essential + Storage Fat',
                        accent: const Color(0xFFEF4444),
                        icon: Icons.pie_chart_outline_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // FFMI Muscularity Score Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.12),
                  AppColors.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.military_tech_rounded, color: const Color(0xFF6366F1), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'FFMI (Muscularity Index)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        ffmiCat,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF818CF8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ffmi != null ? ffmi.toStringAsFixed(1) : '—',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        'Normalized FFMI (Kouri Formula)',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlike BMI, FFMI evaluates your actual muscle mass relative to height. Natural muscular limit is ~25 for men and ~22 for women.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String name, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(name, style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _compStat({
    required String title,
    required String value,
    required String subtitle,
    required Color accent,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 2. MULTI-METHOD CALCULATOR TAB
// ─────────────────────────────────────────────────────────────
class _CalculatorTab extends StatefulWidget {
  final User? user;
  final Assessment? assessment;
  final VoidCallback onSaved;

  const _CalculatorTab({required this.user, required this.assessment, required this.onSaved});

  @override
  State<_CalculatorTab> createState() => _CalculatorTabState();
}

class _CalculatorTabState extends State<_CalculatorTab> {
  String _selectedMethod = 'navy';
  double _waist = 80;
  double _neck = 38;
  double _hip = 95;
  double _s1 = 12;
  double _s2 = 18;
  double _s3 = 14;
  double _directBf = 15.0;

  double? _computedBf;
  String? _computedCategory;
  double? _computedLean;
  double? _computedFat;
  double? _computedFfmi;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _waist = (widget.user?.waistCm ?? 80).toDouble();
    _neck = (widget.user?.neckCm ?? 38).toDouble();
    _hip = (widget.user?.hipCm ?? 95).toDouble();
    _directBf = widget.assessment?.bodyFatPct ?? 15.0;
    _runCalculation();
  }

  void _runCalculation() {
    final u = widget.user;
    final w = u?.weightKg.toDouble() ?? 70.0;
    final h = u?.heightCm.toDouble() ?? 175.0;
    final a = u?.age ?? 25;
    final g = u?.gender ?? 'male';

    double? bf;
    if (_selectedMethod == 'navy') {
      if (_waist > _neck) {
        final inH = h * 0.393701;
        final inW = _waist * 0.393701;
        final inN = _neck * 0.393701;
        if (g == 'male') {
          bf = 495 / (1.0324 - 0.19077 * (math.log(inW - inN) / math.ln10) + 0.15456 * (math.log(inH) / math.ln10)) - 450;
        } else {
          final inHi = _hip * 0.393701;
          bf = 495 / (1.29579 - 0.35004 * (math.log(inW + inHi - inN) / math.ln10) + 0.221 * (math.log(inH) / math.ln10)) - 450;
        }
      }
    } else if (_selectedMethod == 'rfm') {
      final base = g == 'female' ? 76.0 : 64.0;
      bf = base - 20.0 * (h / _waist);
    } else if (_selectedMethod == 'caliper') {
      final sum = _s1 + _s2 + _s3;
      double density;
      if (g == 'female') {
        density = 1.0994921 - 0.0009929 * sum + 0.0000023 * sum * sum - 0.0001392 * a;
      } else {
        density = 1.10938 - 0.0008267 * sum + 0.0000016 * sum * sum - 0.0002574 * a;
      }
      bf = 495 / density - 450;
    } else if (_selectedMethod == 'direct') {
      bf = _directBf;
    } else {
      final bmiVal = w / ((h / 100) * (h / 100));
      final sex = g == 'male' ? 1 : 0;
      bf = 1.2 * bmiVal + 0.23 * a - 10.8 * sex - 5.4;
    }

    if (bf != null && bf.isFinite) {
      bf = bf.clamp(2.0, 60.0);
      _computedBf = bf;
      _computedCategory = _classifyBf(bf, g);
      _computedLean = w * (1 - bf / 100);
      _computedFat = w * (bf / 100);
      final lbm = _computedLean!;
      final hM = h / 100;
      final rawFfmi = lbm / (hM * hM);
      _computedFfmi = rawFfmi + 6.1 * (1.8 - hM);
    }
    setState(() {});
  }

  String _classifyBf(double bf, String gender) {
    if (gender == 'female') {
      if (bf <= 13) return 'Essential Fat';
      if (bf <= 20) return 'Athletes';
      if (bf <= 24) return 'Fitness';
      if (bf <= 31) return 'Average';
      return 'High / Obese';
    } else {
      if (bf <= 5) return 'Essential Fat';
      if (bf <= 13) return 'Athletes';
      if (bf <= 17) return 'Fitness';
      if (bf <= 24) return 'Average';
      return 'High / Obese';
    }
  }

  Future<void> _saveToProfile() async {
    if (_computedBf == null) return;
    setState(() => _saving = true);
    try {
      final updates = <String, dynamic>{
        if (_selectedMethod == 'navy' || _selectedMethod == 'rfm') 'waistCm': _waist.toInt(),
        if (_selectedMethod == 'navy') 'neckCm': _neck.toInt(),
        if (_selectedMethod == 'navy' && widget.user?.gender == 'female') 'hipCm': _hip.toInt(),
      };
      if (updates.isNotEmpty) {
        await ApiClient.instance.updateProfile(updates);
      }
      await ApiClient.instance.logProgress(
        bodyFatPct: double.parse(_computedBf!.toStringAsFixed(1)),
        waistCm: updates.containsKey('waistCm') ? _waist : null,
        neckCm: updates.containsKey('neckCm') ? _neck : null,
        hipCm: updates.containsKey('hipCm') ? _hip : null,
      );
      widget.onSaved();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: ${_computedBf!.toStringAsFixed(1)}% ($_computedCategory) synced to profile!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMale = (widget.user?.gender ?? 'male') == 'male';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Method Selector Segmented Chips
          Text('Select Calculation Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _methodChip('navy', 'US Navy Tape', Icons.straighten_rounded),
                const SizedBox(width: 8),
                _methodChip('rfm', 'RFM (Cedars-Sinai)', Icons.calculate_rounded),
                const SizedBox(width: 8),
                _methodChip('caliper', '3-Site Caliper', Icons.pinch_rounded),
                const SizedBox(width: 8),
                _methodChip('direct', 'Smart Scale / DEXA', Icons.monitor_weight_outlined),
                const SizedBox(width: 8),
                _methodChip('bmi', 'Deurenberg BMI', Icons.speed_rounded),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Live Result Banner
          if (_computedBf != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getCategoryColor(_computedCategory ?? 'Fitness').withValues(alpha: 0.15),
                    AppColors.surfaceLight.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _getCategoryColor(_computedCategory ?? 'Fitness').withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Calculated Body Fat', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_computedBf!.toStringAsFixed(1)}%',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                _computedCategory ?? '',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _getCategoryColor(_computedCategory ?? '')),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lean: ${_computedLean?.toStringAsFixed(1)} kg · Fat: ${_computedFat?.toStringAsFixed(1)} kg · FFMI: ${_computedFfmi?.toStringAsFixed(1)}',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _saving ? null : _saveToProfile,
                    icon: _saving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check, size: 16),
                    label: Text(_saving ? 'Saving...' : 'Save', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Method inputs
          if (_selectedMethod == 'navy') ...[
            _sliderInput('Waist Circumference (at navel)', _waist, 50, 160, 'cm', (v) {
              _waist = v;
              _runCalculation();
            }),
            _sliderInput('Neck Circumference (below larynx)', _neck, 25, 70, 'cm', (v) {
              _neck = v;
              _runCalculation();
            }),
            if (!isMale)
              _sliderInput('Hip Circumference (widest point)', _hip, 60, 180, 'cm', (v) {
                _hip = v;
                _runCalculation();
              }),
          ] else if (_selectedMethod == 'rfm') ...[
            _sliderInput('Waist Circumference', _waist, 50, 160, 'cm', (v) {
              _waist = v;
              _runCalculation();
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                'Uses Cedars-Sinai Relative Fat Mass equation (Height & Waist only). Clinically proven to be more accurate than BMI.',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          ] else if (_selectedMethod == 'caliper') ...[
            Text(
              isMale ? 'Male 3-Site Skinfolds (mm)' : 'Female 3-Site Skinfolds (mm)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            _sliderInput(isMale ? 'Chest Skinfold' : 'Tricep Skinfold', _s1, 2, 50, 'mm', (v) {
              _s1 = v;
              _runCalculation();
            }),
            _sliderInput(isMale ? 'Abdominal Skinfold' : 'Suprailiac (Hip) Skinfold', _s2, 2, 60, 'mm', (v) {
              _s2 = v;
              _runCalculation();
            }),
            _sliderInput('Thigh Skinfold', _s3, 2, 60, 'mm', (v) {
              _s3 = v;
              _runCalculation();
            }),
          ] else if (_selectedMethod == 'direct') ...[
            _sliderInput('Direct Body Fat %', _directBf, 3, 50, '%', (v) {
              _directBf = v;
              _runCalculation();
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                'Enter reading directly from your Smart Scale (Withings, Renpho, InBody, Garmin) or DEXA Scan.',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Estimates body fat from current Weight (${widget.user?.weightKg} kg), Height (${widget.user?.heightCm} cm), and Age (${widget.user?.age}) via Deurenberg formula.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _methodChip(String key, String label, IconData icon) {
    final isSelected = _selectedMethod == key;
    return ChoiceChip(
      showCheckmark: false,
      selected: isSelected,
      avatar: Icon(icon, size: 16, color: isSelected ? AppColors.onPrimary : AppColors.textSecondary),
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? AppColors.onPrimary : AppColors.textPrimary)),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primary : Colors.transparent)),
      onSelected: (_) {
        setState(() => _selectedMethod = key);
        _runCalculation();
      },
    );
  }

  Widget _sliderInput(String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.toStringAsFixed(1)} $unit',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.primary,
              trackHeight: 3.5,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 3. TARGET BODY FAT SIMULATOR TAB
// ─────────────────────────────────────────────────────────────
class _SimulatorTab extends StatefulWidget {
  final User? user;
  final Assessment? assessment;

  const _SimulatorTab({required this.user, required this.assessment});

  @override
  State<_SimulatorTab> createState() => _SimulatorTabState();
}

class _SimulatorTabState extends State<_SimulatorTab> {
  double _targetBf = 14.0;

  @override
  void initState() {
    super.initState();
    final isMale = (widget.user?.gender ?? 'male') == 'male';
    _targetBf = (isMale ? 14.0 : 21.0);
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final a = widget.assessment;
    final curWeight = u?.weightKg.toDouble() ?? 75.0;
    final curBf = a?.bodyFatPct ?? 18.0;

    final curLbm = curWeight * (1 - curBf / 100);
    final targetWeight = curLbm / (1 - _targetBf / 100);
    final fatToLose = curWeight - targetWeight;
    final diffBf = (curBf - _targetBf).abs();
    final ratePerWeek = curBf > _targetBf ? 0.6 : 0.35;
    final estimatedWeeks = math.max(1, (diffBf / ratePerWeek).ceil());
    final isCutting = curBf > _targetBf;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Target Body Fat %', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        '${_targetBf.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.onPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.surfaceLight,
                    thumbColor: AppColors.primary,
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _targetBf.clamp(5.0, 35.0),
                    min: 5.0,
                    max: 35.0,
                    divisions: 60,
                    onChanged: (v) => setState(() => _targetBf = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text('Projected Recomposition Timeline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _simCard(
                  title: isCutting ? 'Fat to Lose' : 'Lean Surplus Target',
                  value: '${fatToLose.abs().toStringAsFixed(1)} kg',
                  sub: isCutting ? 'Preserving ${curLbm.toStringAsFixed(1)} kg muscle' : 'Clean lean mass focus',
                  accent: isCutting ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  icon: Icons.local_fire_department_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _simCard(
                  title: 'Goal Weight',
                  value: '${targetWeight.toStringAsFixed(1)} kg',
                  sub: 'At ${_targetBf.toStringAsFixed(1)}% body fat',
                  accent: AppColors.primary,
                  icon: Icons.flag_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _simCard(
            title: 'Estimated Duration',
            value: '~$estimatedWeeks weeks',
            sub: isCutting
                ? 'Based on sustainable 0.5–0.7% fat loss / week with 20% caloric deficit'
                : 'Based on clean caloric surplus for optimal lean muscle gain',
            accent: const Color(0xFF6366F1),
            icon: Icons.calendar_month_rounded,
          ),
        ],
      ),
    );
  }

  Widget _simCard({required String title, required String value, required String sub, required Color accent, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.8), height: 1.3)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 4. PHYSIQUE REFERENCE GUIDE TAB
// ─────────────────────────────────────────────────────────────
class _GuideTab extends StatelessWidget {
  final String gender;
  const _GuideTab({required this.gender});

  @override
  Widget build(BuildContext context) {
    final isMale = gender == 'male';

    final maleTiers = [
      {'range': '6–9%', 'title': 'Stage Shredded / Elite', 'desc': 'Visible muscle striations, deep ab definition, vascularity across arms and lower abdomen. Reserved for competition or athletes.', 'color': const Color(0xFF3B82F6)},
      {'range': '10–13%', 'title': 'Athletic / Six-Pack', 'desc': 'Clear 6-pack abs visible without flexing, shoulder & chest separation, lean facial features, very athletic build.', 'color': const Color(0xFF10B981)},
      {'range': '14–17%', 'title': 'Fitness / Lean Tone', 'desc': 'Flat stomach, upper abs visible in good lighting, healthy muscle tone. Optimal for long-term health and strength.', 'color': const Color(0xFF6366F1)},
      {'range': '18–24%', 'title': 'Average / Soft', 'desc': 'Soft midsection, little to no muscle definition visible under skin, healthy lifestyle standard.', 'color': const Color(0xFFF59E0B)},
      {'range': '25%+', 'title': 'Above Target / High', 'desc': 'Significant abdominal fat storage, high visceral fat risk. Recommended to engage in structured fat loss plan.', 'color': const Color(0xFFEF4444)},
    ];

    final femaleTiers = [
      {'range': '14–17%', 'title': 'Athletic / Competition', 'desc': 'Clear abdominal definition, vascularity, very low body fat. Typically seen in track athletes and physique competitors.', 'color': const Color(0xFF3B82F6)},
      {'range': '18–21%', 'title': 'Fitness / Toned', 'desc': 'Firm midsection, subtle ab outline, defined shoulders and quads, lean athletic appearance.', 'color': const Color(0xFF10B981)},
      {'range': '21–24%', 'title': 'Healthy Fit / Ideal', 'desc': 'Optimal hormonal health and sustainable fitness. Flat stomach, feminine curves, good energy levels.', 'color': const Color(0xFF6366F1)},
      {'range': '25–31%', 'title': 'Average', 'desc': 'Standard healthy female range with soft curves and normal adipose distribution.', 'color': const Color(0xFFF59E0B)},
      {'range': '32%+', 'title': 'Above Target / High', 'desc': 'Elevated body fat percentage. Recommended to begin a consistent resistance training and calorie management routine.', 'color': const Color(0xFFEF4444)},
    ];

    final tiers = isMale ? maleTiers : femaleTiers;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: tiers.length,
      itemBuilder: (context, i) {
        final t = tiers[i];
        final col = t['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: col.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: col.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  t['range'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: col),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['title'] as String,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t['desc'] as String,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GAUGE METER CUSTOM PAINTER
// ─────────────────────────────────────────────────────────────
class _BodyFatGaugePainter extends CustomPainter {
  final double bodyFat;
  final bool isMale;
  final double targetMin;
  final double targetMax;

  _BodyFatGaugePainter({required this.bodyFat, required this.isMale, required this.targetMin, required this.targetMax});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.88);
    final radius = size.height * 0.76;
    final strokeWidth = 14.0;

    const startAngle = math.pi * 0.9;
    const sweepAngle = math.pi * 1.2;

    final bgPaint = Paint()
      ..color = AppColors.surfaceLight.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // 5 ACE Segments
    final segments = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFF6366F1),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];

    final segSweep = sweepAngle / segments.length;
    for (int i = 0; i < segments.length; i++) {
      final segPaint = Paint()
        ..color = segments[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = i == 0 ? StrokeCap.round : (i == segments.length - 1 ? StrokeCap.round : StrokeCap.butt);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + i * segSweep,
        segSweep,
        false,
        segPaint,
      );
    }

    // Needle / Indicator position
    final minVal = isMale ? 3.0 : 10.0;
    final maxVal = isMale ? 30.0 : 40.0;
    final normalized = ((bodyFat - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);
    final needleAngle = startAngle + normalized * sweepAngle;

    final needlePoint = Offset(
      center.dx + (radius) * math.cos(needleAngle),
      center.dy + (radius) * math.sin(needleAngle),
    );

    // Draw glowing needle head
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(needlePoint, 11, glowPaint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(needlePoint, 6, dotPaint);

    final ringPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(needlePoint, 6, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _BodyFatGaugePainter oldDelegate) {
    return oldDelegate.bodyFat != bodyFat || oldDelegate.isMale != isMale;
  }
}

Color _getCategoryColor(String category) {
  final c = category.toLowerCase();
  if (c.contains('essential')) return const Color(0xFF3B82F6);
  if (c.contains('athlet')) return const Color(0xFF10B981);
  if (c.contains('fit')) return const Color(0xFF6366F1);
  if (c.contains('avg') || c.contains('average')) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}
