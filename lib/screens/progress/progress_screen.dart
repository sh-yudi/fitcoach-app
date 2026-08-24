import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_client.dart';
import '../../theme.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<Map<String, dynamic>> _entries = [];
  Map<String, dynamic>? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _entries.isEmpty;
      _error = null;
    });
    try {
      final entries = await ApiClient.instance.getProgress();
      final summary = await ApiClient.instance.getProgressSummary();
      if (!mounted) return;
      setState(() {
        _entries = _sorted(entries);
        _summary = summary;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _sorted(List<Map<String, dynamic>> entries) {
    final list = [...entries];
    list.sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));
    return list;
  }

  DateTime _dateOf(Map<String, dynamic> e) {
    final d = e['date'];
    if (d is String) return DateTime.tryParse(d) ?? DateTime.fromMillisecondsSinceEpoch(0);
    if (d is num) return DateTime.fromMillisecondsSinceEpoch(d.toInt());
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.'));
  }

  Future<void> _openLogSheet() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _LogProgressSheet(),
    );
    if (saved == true) _load();
  }

  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    final id = entry['id']?.toString();
    if (id == null || id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete entry?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          'This progress entry will be removed permanently.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiClient.instance.deleteProgress(id);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        onPressed: _openLogSheet,
        icon: const Icon(Icons.add),
        label: const Text('Log weight', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
            : RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: _load,
                child: _entries.isEmpty && _error == null
                    ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [_buildEmpty()])
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        children: [
                          if (_error != null) ...[
                            _ErrorBox(message: _error!),
                            const SizedBox(height: 16),
                          ],
                          _SummaryCard(summary: _summary),
                          const SizedBox(height: 16),
                          if (_weightSeries().length >= 2) ...[
                            _TrendChart(values: _weightSeries()),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Timeline',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                              const Spacer(),
                              Text(
                                '${_entries.length} ${_entries.length == 1 ? 'entry' : 'entries'}',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ..._entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _EntryTile(entry: e, onDelete: () => _deleteEntry(e)),
                              )),
                        ],
                      ),
              ),
      ),
    );
  }

  List<double> _weightSeries() {
    final values = <double>[];
    for (final e in _sorted([..._entries].reversed.toList())) {
      final w = _num(e['weightKg']);
      if (w != null && w > 0) values.add(w);
    }
    return values.length > 14 ? values.sublist(values.length - 14) : values;
  }

  Widget _buildEmpty() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.monitor_weight_outlined, color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'No progress yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Log your weight and measurements to see your transformation over time.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _openLogSheet,
            icon: const Icon(Icons.add),
            label: const Text('Log your first entry'),
          ),
        ],
      ),
    );
  }
}

// ---- Summary card ----

class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic>? summary;
  const _SummaryCard({this.summary});

  double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  @override
  Widget build(BuildContext context) {
    final s = summary ?? {};
    final hasData = s['hasData'] == true || _num(s['currentWeight']) != null;
    final start = _num(s['startWeight']);
    final current = _num(s['currentWeight']);
    final change = _num(s['weightChange']) ?? ((start != null && current != null) ? current - start : null);
    final bf = _num(s['bodyFatPct']) ?? _num(s['latestBodyFat']);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.surfaceLight.withValues(alpha: 0.55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: hasData
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _stat('Start', start != null ? '${_fmt(start)} kg' : '—')),
                    Expanded(child: _stat('Current', current != null ? '${_fmt(current)} kg' : '—')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _changeStat(change)),
                    Expanded(child: _stat('Body fat', bf != null ? '${_fmt(bf)}%' : '—')),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Icon(Icons.insights, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Log at least two entries to unlock your overall stats.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _changeStat(double? change) {
    final c = change ?? 0.0;
    final lost = c < 0;
    final neutral = c.abs() < 0.05;
    final color = neutral ? AppColors.textPrimary : (lost ? AppColors.success : const Color(0xFFFFB020));
    final arrow = neutral ? '→' : (lost ? '↓' : '↑');
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total change', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                neutral ? Icons.trending_flat : (lost ? Icons.south_east : Icons.north_east),
                color: color,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                '${neutral ? '' : '$arrow '}${c > 0 ? '+' : ''}${_fmt(c)} kg',
                style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

// ---- Weight trend chart (simple painted bars, no charting library) ----

class _TrendChart extends StatelessWidget {
  final List<double> values;
  const _TrendChart({required this.values});

  @override
  Widget build(BuildContext context) {
    final minV = values.reduce(min);
    final maxV = values.reduce(max);
    final range = (maxV - minV) < 0.5 ? 1.0 : maxV - minV;
    const maxBarHeight = 120.0;
    const minBarHeight = 28.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Weight trend',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(
                '${values.length} logs',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: maxBarHeight + 26,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++) ...[
                  Expanded(
                    child: Tooltip(
                      message: '${values[i].toStringAsFixed(1)} kg',
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: minBarHeight + ((values[i] - minV) / range) * (maxBarHeight - minBarHeight),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary.withValues(alpha: 0.45), AppColors.primary],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${minV.toStringAsFixed(1)} kg low', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              Text('${maxV.toStringAsFixed(1)} kg high', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- Timeline entry tile ----

class _EntryTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onDelete;
  const _EntryTile({required this.entry, required this.onDelete});

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  DateTime _date() {
    final d = entry['date'];
    if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
    if (d is num) return DateTime.fromMillisecondsSinceEpoch(d.toInt());
    return DateTime.now();
  }

  double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String _fmt(double? v, {String unit = ''}) {
    if (v == null || v <= 0) return '—';
    final s = v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return '$s$unit';
  }

  @override
  Widget build(BuildContext context) {
    final date = _date();
    final rows = <(String, String)>[
      ('Weight', _fmt(_num(entry['weightKg']), unit: ' kg')),
      ('Waist', _fmt(_num(entry['waistCm']), unit: ' cm')),
      ('Neck', _fmt(_num(entry['neckCm']), unit: ' cm')),
      ('Hip', _fmt(_num(entry['hipCm']), unit: ' cm')),
      ('Chest', _fmt(_num(entry['chestCm']), unit: ' cm')),
      ('Arm', _fmt(_num(entry['armCm']), unit: ' cm')),
      ('Body fat', _fmt(_num(entry['bodyFatPct']), unit: '%')),
    ];

    return InkWell(
      onLongPress: onDelete,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary, height: 1),
                  ),
                  const SizedBox(height: 2),
                  Text(_months[date.month - 1], style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _weekday(date),
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: rows
                        .where((r) => r.$2 != '—')
                        .map((r) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${r.$1} ${r.$2}',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 20),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  String _weekday(DateTime d) => _weekdays[d.weekday - 1];
}

// ---- Log bottom sheet ----

class _LogProgressSheet extends StatefulWidget {
  const _LogProgressSheet();

  @override
  State<_LogProgressSheet> createState() => _LogProgressSheetState();
}

class _LogProgressSheetState extends State<_LogProgressSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weight = TextEditingController();
  late final TextEditingController _waist = TextEditingController();
  late final TextEditingController _neck = TextEditingController();
  late final TextEditingController _hip = TextEditingController();
  late final TextEditingController _chest = TextEditingController();
  late final TextEditingController _arm = TextEditingController();
  late final TextEditingController _bf = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _weight.dispose();
    _waist.dispose();
    _neck.dispose();
    _hip.dispose();
    _chest.dispose();
    _arm.dispose();
    _bf.dispose();
    super.dispose();
  }

  double? _parse(String raw) {
    if (raw.trim().isEmpty) return null;
    final v = double.tryParse(raw.trim().replaceAll(',', '.'));
    return (v == null || v <= 0) ? null : v;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await ApiClient.instance.logProgress(
        weightKg: _parse(_weight.text),
        waistCm: _parse(_waist.text),
        neckCm: _parse(_neck.text),
        hipCm: _parse(_hip.text),
        chestCm: _parse(_chest.text),
        armCm: _parse(_arm.text),
        bodyFatPct: _parse(_bf.text),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomInset),
        child: Form(
          key: _formKey,
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
                'Log measurements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Weight is required · everything else is optional.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
              const SizedBox(height: 20),
              _field(_weight, 'Weight (kg)', Icons.monitor_weight_outlined,
                  validator: (v) => _parse(v ?? '') == null ? 'Enter your weight' : null),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field(_waist, 'Waist (cm)', Icons.square_foot)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_neck, 'Neck (cm)', Icons.person_outline)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field(_hip, 'Hip (cm)', Icons.chair_alt_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_chest, 'Chest (cm)', Icons.fitness_center)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field(_arm, 'Arm (cm)', Icons.back_hand_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_bf, 'Body fat (%)', Icons.water_drop_outlined)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                        )
                      : const Icon(Icons.check),
                  label: Text(_saving ? 'Saving...' : 'Save entry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      validator: validator,
      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

// ---- Error box ----

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: AppColors.danger, fontSize: 13))),
        ],
      ),
    );
  }
}
