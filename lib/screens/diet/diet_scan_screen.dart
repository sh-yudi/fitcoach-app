import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme.dart';

class DietScanScreen extends StatefulWidget {
  const DietScanScreen({super.key});

  @override
  State<DietScanScreen> createState() => _DietScanScreenState();
}

class _DietScanScreenState extends State<DietScanScreen> {
  File? _imageFile;
  bool _scanning = false;
  Map<String, dynamic>? _result;
  String? _error;
  String _selectedMeal = 'breakfast';
  bool _logging = false;
  bool _logged = false;
  Assessment? _assessment;
  Map<String, dynamic> _totals = {};

  static const _meals = [
    'breakfast', 'snack1', 'lunch', 'preworkout', 'postworkout', 'dinner', 'snack2',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogged();
  }

  Future<void> _loadLogged() async {
    try {
      final a = await ApiClient.instance.getAssessment();
      final logged = await ApiClient.instance.getLoggedFood();
      if (!mounted) return;
      setState(() {
        _assessment = a;
        _totals = (logged['totals'] as Map<String, dynamic>?) ?? {};
      });
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1024, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      _imageFile = File(picked.path);
      _result = null;
      _error = null;
      _logged = false;
    });
  }

  Future<void> _analyze() async {
    if (_imageFile == null || _scanning) return;
    setState(() { _scanning = true; _error = null; _result = null; });
    try {
      final bytes = await _imageFile!.readAsBytes();
      final b64 = base64Encode(bytes);
      final result = await ApiClient.instance.scanFood(b64, mealName: _selectedMeal);
      if (!mounted) return;
      setState(() { _result = result; _scanning = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _scanning = false; });
    }
  }

  Future<void> _logFood() async {
    if (_result == null || _logging) return;
    setState(() => _logging = true);
    try {
      await ApiClient.instance.logScannedFood(_selectedMeal, _result!);
      if (!mounted) return;
      setState(() { _logging = false; _logged = true; });
      await _loadLogged();
      if (!mounted) return;
      _showProgress();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _logging = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _showProgress() {
    final a = _assessment;
    final t = _totals;
    if (a == null) return;
    final consumedCal = (t['calories'] ?? 0) as int;
    final consumedP = (t['protein'] ?? 0) as int;
    final consumedC = (t['carbs'] ?? 0) as int;
    final consumedF = (t['fiber'] ?? 0) as int;
    final remainCal = a.calories - consumedCal;
    final pct = a.calories > 0 ? (consumedCal / a.calories * 100).clamp(0, 100).round() : 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 24),
            const SizedBox(width: 8),
            Text('Logged!', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Progress ($pct% of target)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            _progressRow('Calories', consumedCal, a.calories, 'kcal', const Color(0xFFFFB020)),
            _progressRow('Protein', consumedP, a.protein, 'g', const Color(0xFF3DD68C)),
            _progressRow('Carbs', consumedC, a.carbs, 'g', const Color(0xFFFFB020)),
            _progressRow('Fiber', consumedF, a.fiber, 'g', const Color(0xFF6C8CFF)),
            const SizedBox(height: 12),
            if (remainCal > 0)
              Text('You can still eat ~$remainCal kcal today.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
            else
              Text('Daily calorie target reached!',
                  style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  Widget _progressRow(String label, int current, int target, String unit, Color color) {
    final pct = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('$current / $target $unit',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  String _mealLabel(String m) => switch (m) {
    'breakfast' => 'Breakfast',
    'snack1' => 'Morning Snack',
    'lunch' => 'Lunch',
    'preworkout' => 'Pre-workout',
    'postworkout' => 'Post-workout',
    'dinner' => 'Dinner',
    'snack2' => 'Evening Snack',
    _ => m,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Food')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.camera_alt, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Take a photo or pick from gallery. AI will estimate calories and macros.',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Meal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _meals.map((m) {
                final sel = _selectedMeal == m;
                return ChoiceChip(
                  label: Text(_mealLabel(m), style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: sel ? AppColors.onPrimary : AppColors.textPrimary,
                  )),
                  selected: sel,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.5),
                  side: BorderSide(color: sel ? AppColors.primary : Colors.transparent),
                  onSelected: (_) => setState(() => _selectedMeal = m),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            if (_imageFile == null) ...[
              Row(
                children: [
                  Expanded(child: _ActionButton(icon: Icons.camera_alt, label: 'Camera', onTap: () => _pickImage(ImageSource.camera))),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionButton(icon: Icons.photo_library, label: 'Gallery', onTap: () => _pickImage(ImageSource.gallery))),
                ],
              ),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.file(_imageFile!, width: double.infinity, height: 200, fit: BoxFit.cover),
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() { _imageFile = null; _result = null; _error = null; _logged = false; }),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                          child: Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_scanning)
                Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
              else if (_result != null) ...[
                _ResultCard(result: _result!),
                const SizedBox(height: 16),
                if (!_logged)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _logging ? null : _logFood,
                      icon: _logging
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
                          : Icon(Icons.check),
                      label: Text(_logging ? 'Logging...' : 'Log to ${_mealLabel(_selectedMeal)}'),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 18),
                        const SizedBox(width: 8),
                        Text('Logged to ${_mealLabel(_selectedMeal)}',
                            style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                  ),
              ] else if (_error != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(_error!, style: TextStyle(color: AppColors.danger, fontSize: 13)),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(onPressed: _analyze, icon: Icon(Icons.auto_awesome), label: const Text('Analyze Food')),
                ),
            ],
            const SizedBox(height: 20),
            if (_totals.isNotEmpty) ...[
              Text("Today's Logged Food", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.surfaceLight)),
                child: Column(
                  children: [
                    _summaryRow('Calories', '${_totals['calories'] ?? 0} kcal', '${_assessment?.calories ?? 0} target'),
                    _summaryRow('Protein', '${_totals['protein'] ?? 0}g', '${_assessment?.protein ?? 0}g target'),
                    _summaryRow('Carbs', '${_totals['carbs'] ?? 0}g', '${_assessment?.carbs ?? 0}g target'),
                    _summaryRow('Fiber', '${_totals['fiber'] ?? 0}g', '${_assessment?.fiber ?? 0}g target'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, String target) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(target, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceLight)),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(result['name'] ?? 'Unknown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(result['servingSize'] ?? '', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              _MacroPill(label: 'Cal', value: '${result['calories'] ?? 0}', color: const Color(0xFFFFB020)),
              const SizedBox(width: 8),
              _MacroPill(label: 'P', value: '${result['protein'] ?? 0}g', color: const Color(0xFF3DD68C)),
              const SizedBox(width: 8),
              _MacroPill(label: 'C', value: '${result['carbs'] ?? 0}g', color: const Color(0xFFFFB020)),
              const SizedBox(width: 8),
              _MacroPill(label: 'F', value: '${result['fiber'] ?? 0}g', color: const Color(0xFF6C8CFF)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
