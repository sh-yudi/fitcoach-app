import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../theme.dart';

class FastingScreen extends StatefulWidget {
  const FastingScreen({super.key});

  @override
  State<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends State<FastingScreen> {
  static const _protocols = ['16:8', '18:6', '20:4'];

  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String _selectedProtocol = '16:8';
  Timer? _tick;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final data = await ApiClient.instance.getFasting();
      if (!mounted) return;
      final active = data['active'] == true;
      setState(() {
        _data = data;
        _loading = false;
        if (active) {
          _selectedProtocol = _currentProtocol;
          _startTicker();
        } else {
          _tick?.cancel();
        }
        if (data['protocol'] is String && !active) {
          _selectedProtocol = _normalizeProtocol(data['protocol'] as String);
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  String _normalizeProtocol(String p) => _protocols.contains(p) ? p : _selectedProtocol;

  void _startTicker() {
    _tick?.cancel();
    _now = DateTime.now();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  bool get _isActive => _data?['active'] == true;

  int get _fastHours {
    final p = (_data?['protocol'] as String?) ?? _selectedProtocol;
    final h = int.tryParse(p.split(':').first);
    return h ?? 16;
  }

  String get _currentProtocol {
    final p = _data?['protocol'];
    return p is String ? p : _selectedProtocol;
  }

  DateTime? get _startedAt {
    final s = _data?['startedAt'];
    if (s is num) return DateTime.fromMillisecondsSinceEpoch(s.toInt() * (s > 1e12 ? 1 : 1000));
    if (s is String && s.isNotEmpty) return DateTime.tryParse(s)?.toLocal();
    return null;
  }

  Duration get _target => Duration(hours: _fastHours);

  Duration get _elapsed {
    final start = _startedAt;
    if (!_isActive || start == null) return Duration.zero;
    final e = _now.difference(start);
    return e.isNegative ? Duration.zero : e;
  }

  double get _progress =>
      _target.inSeconds == 0 ? 0 : (_elapsed.inSeconds / _target.inSeconds).clamp(0.0, 1.0);

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ApiClient.instance.startFasting(_selectedProtocol);
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _stop() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('End fast?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          'Your fasting window will be closed and logged.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('End fast'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ApiClient.instance.stopFasting();
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
    if (mounted) setState(() => _busy = false);
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:${m.toString().padLeft(2, '0')}:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fasting')),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
            : RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_error!, style: TextStyle(color: AppColors.danger, fontSize: 13))),
                          ],
                        ),
                      ),
                    _ProtocolSelector(
                      protocols: _protocols,
                      selected: _selectedProtocol,
                      enabled: !_isActive && !_busy,
                      onSelect: (p) => setState(() => _selectedProtocol = p),
                    ),
                    const SizedBox(height: 24),
                    Center(child: _TimerRing(progress: _progress)),
                    const SizedBox(height: 28),
                    _buildStatusSection(),
                    const SizedBox(height: 24),
                    _buildHistory(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusSection() {
    if (!_isActive) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _start,
              icon: _busy
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(_busy ? 'Starting...' : 'Start $_selectedProtocol fast'),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Pick a protocol above and tap start when your eating window closes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
        ],
      );
    }

    final elapsed = _elapsed;
    final done = _progress >= 1.0;
    final remaining = done ? Duration.zero : _target - elapsed;
    final pct = (_progress * 100).round();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: done ? AppColors.success.withValues(alpha: 0.4) : AppColors.surfaceLight),
          ),
          child: Row(
            children: [
              Expanded(child: _miniStat('Elapsed', _fmtDuration(elapsed), AppColors.primary)),
              _divider(),
              Expanded(child: _miniStat(done ? 'Complete' : 'Remaining', done ? 'Done!' : _fmtDuration(remaining), done ? AppColors.success : AppColors.textSecondary)),
              _divider(),
              Expanded(child: _miniStat('Progress', '$pct%', AppColors.success)),
            ],
          ),
        ),
        if (done) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_outlined, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Fast complete — great discipline!',
                  style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: _busy ? null : _stop,
            icon: _busy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.stop_rounded),
            label: Text(_busy ? 'Ending...' : 'Stop fasting'),
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: AppColors.textSecondary, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 34, color: AppColors.surfaceLight);

  Widget _buildHistory() {
    final rawHistory = _data?['history'];
    final history = rawHistory is List ? rawHistory.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Text('Past fasts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 10),
        if (history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              children: [
                Icon(Icons.hourglass_empty, color: AppColors.textSecondary, size: 30),
                const SizedBox(height: 10),
                Text(
                  'No fasts yet',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Completed fasts will appear here.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          )
        else
          ...history.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _HistoryTile(entry: h),
              )),
      ],
    );
  }
}

// ---- Protocol chips ----

class _ProtocolSelector extends StatelessWidget {
  final List<String> protocols;
  final String selected;
  final bool enabled;
  final ValueChanged<String> onSelect;

  const _ProtocolSelector({
    required this.protocols,
    required this.selected,
    required this.enabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: protocols.map((p) {
        final sel = p == selected;
        final parts = p.split(':');
        return ChoiceChip(
          selected: sel,
          onSelected: enabled ? (_) => onSelect(p) : null,
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.5),
          side: BorderSide(color: sel ? AppColors.primary : Colors.transparent),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
          avatar: Icon(Icons.timer_outlined, size: 16, color: sel ? AppColors.onPrimary : AppColors.textSecondary),
          label: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: sel ? AppColors.onPrimary : AppColors.textPrimary),
              ),
              Text(
                '${parts[0]}h fast · ${parts.length > 1 ? parts[1] : ''}h eat',
                style: TextStyle(fontSize: 9.5, color: sel ? AppColors.onPrimary.withValues(alpha: 0.75) : AppColors.textSecondary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ---- Circular timer ----

class _TimerRing extends StatelessWidget {
  final double progress;
  const _TimerRing({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.fromRadius(112),
            painter: _RingPainter(progress: progress),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1),
              ),
              const SizedBox(height: 6),
              Text(
                progress >= 1.0 ? 'Target reached' : 'of fasting window',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const stroke = 14.0;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.surfaceLight;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = progress >= 1.0 ? AppColors.success : AppColors.primary;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress.clamp(0.0, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}

// ---- History tile ----

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _HistoryTile({required this.entry});

  double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  DateTime? _date(dynamic v) {
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt() * (v > 1e12 ? 1 : 1000));
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final completed = entry['completed'] == true || entry['completed'] == 1;
    final hours = _num(entry['durationHours']) ?? _num(entry['duration']) ?? _num(entry['hours']);
    final start = _date(entry['startedAt'] ?? entry['startTime'] ?? entry['date']);
    final protocol = entry['protocol']?.toString() ?? '';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateLabel = start != null ? '${start.day} ${months[start.month - 1]}, ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}' : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (completed ? AppColors.success : AppColors.danger).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              completed ? Icons.check_circle_outline : Icons.close,
              color: completed ? AppColors.success : AppColors.danger,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      protocol.isNotEmpty ? '$protocol fast' : 'Fast',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    if (dateLabel.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(dateLabel, style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  hours != null
                      ? '${hours % 1 == 0 ? hours.toStringAsFixed(0) : hours.toStringAsFixed(1)} hours · ${completed ? "completed" : "ended early"}'
                      : (completed ? 'Completed' : 'Ended early'),
                  style: TextStyle(color: completed ? AppColors.success : AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            completed ? '🔥' : '',
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
