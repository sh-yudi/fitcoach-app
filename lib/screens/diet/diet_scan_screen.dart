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
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;

  static const _meals = [
    'breakfast', 'snack1', 'lunch', 'preworkout', 'postworkout', 'dinner', 'snack2',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogged();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Normalises different server payloads into a single food map.
  Map<String, dynamic>? _extractFood(Map<String, dynamic> j) {
    final f = j['food'] ?? j['product'] ?? j['item'];
    if (f is Map) return Map<String, dynamic>.from(f);
    if (j['found'] == false) return null;
    if (j.containsKey('name') || j.containsKey('calories')) return j;
    return null;
  }

  Future<void> _scanBarcode() async {
    final controller = TextEditingController();
    var busy = false;
    var dialogError = '';
    final food = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text('Scan Barcode', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type the digits printed under the product barcode.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                decoration: const InputDecoration(hintText: 'e.g. 5449000000996'),
                onSubmitted: (_) {},
              ),
              if (dialogError.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(dialogError, style: TextStyle(color: AppColors.danger, fontSize: 12.5)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final code = controller.text.trim();
                      if (code.isEmpty) return;
                      setDialogState(() { busy = true; dialogError = ''; });
                      try {
                        final j = await ApiClient.instance.lookupBarcode(code);
                        final f = _extractFood(j);
                        if (!ctx.mounted) return;
                        if (f == null) {
                          setDialogState(() { busy = false; dialogError = 'No product found for this barcode.'; });
                        } else {
                          Navigator.of(ctx).pop(f);
                        }
                      } on ApiException catch (e) {
                        setDialogState(() { busy = false; dialogError = e.message; });
                      }
                    },
              child: busy
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
                  : const Text('Find'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (food == null || !mounted) return;
    _useResult(food);
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    try {
      final results = await ApiClient.instance.searchFood(q);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _searching = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _useResult(Map<String, dynamic> food) {
    FocusScope.of(context).unfocus();
    setState(() {
      _result = food;
      _imageFile = null;
      _error = null;
      _logged = false;
    });
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
                      'Take a photo, scan a barcode or search by name. We will estimate calories and macros.',
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
            if (_imageFile != null) ...[
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
            ],
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
            else if (_imageFile != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(onPressed: _analyze, icon: Icon(Icons.auto_awesome), label: const Text('Analyze Food')),
              )
            else ...[
              Row(
                children: [
                  Expanded(child: _ActionButton(icon: Icons.camera_alt, label: 'Camera', onTap: () => _pickImage(ImageSource.camera))),
                  const SizedBox(width: 10),
                  Expanded(child: _ActionButton(icon: Icons.photo_library, label: 'Gallery', onTap: () => _pickImage(ImageSource.gallery))),
                  const SizedBox(width: 10),
                  Expanded(child: _ActionButton(icon: Icons.qr_code_scanner, label: 'Barcode', onTap: _scanBarcode)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _runSearch,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search food by name…',
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _searching
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                        )
                      : (_searchResults.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: AppColors.textSecondary, size: 20),
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _searchResults = [];
                              }),
                            )
                          : null),
                ),
              ),
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'}',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                ..._searchResults.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SearchResultTile(food: r, onTap: () => _useResult(r)),
                    )),
              ] else if (!_searching && _searchController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'No matches — try another name.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                ),
              ],
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceLight)),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Map<String, dynamic> food;
  final VoidCallback onTap;
  const _SearchResultTile({required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brand = food['brand']?.toString() ?? '';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.lunch_dining_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food['name']?.toString() ?? 'Unknown food',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w800),
                  ),
                  if (brand.isNotEmpty)
                    Text(brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${food['calories'] ?? 0} kcal',
              style: TextStyle(color: const Color(0xFFFFB020), fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
            Icon(Icons.add_circle_outline, color: AppColors.primary, size: 18),
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
