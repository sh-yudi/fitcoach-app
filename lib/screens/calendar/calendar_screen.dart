import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../../theme.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/gym_check_in_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.refreshToken = 0, this.initialCheckInDate});

  final int refreshToken;
  final String? initialCheckInDate;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late int _year;
  late int _month;
  Map<String, bool> _plans = {};
  Map<String, bool> _attendance = {};
  bool _loading = true;
  bool _checkInShown = false;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _load();
  }

  @override
  void didUpdateWidget(CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ApiClient.instance.getGymCalendar();
      if (!mounted) return;
      setState(() {
        _plans = r.gymPlans;
        _attendance = r.attendance;
        _loading = false;
      });
      if (widget.initialCheckInDate != null && !_checkInShown) {
        _checkInShown = true;
        _openCheckIn(widget.initialCheckInDate!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _key(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  DateTime _firstOfMonth() => DateTime(_year, _month, 1);

  int _daysInMonth() => DateTime(_year, _month + 1, 0).day;

  // Monday-first offset: DateTime.monday = 1 .. sunday = 7
  int _leadingBlanks() {
    final w = _firstOfMonth().weekday;
    return w - 1;
  }

  void _prevMonth() {
    setState(() {
      _month--;
      if (_month == 0) {
        _month = 12;
        _year--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      _month++;
      if (_month == 13) {
        _month = 1;
        _year++;
      }
    });
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _year = now.year;
      _month = now.month;
    });
  }

  void _openCheckIn(String dateKey) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => GymCheckInSheet(
        dateKey: dateKey,
        planned: _plans[dateKey],
        attended: _attendance[dateKey],
        onChanged: () async {
          final r = await ApiClient.instance.getGymCalendar();
          if (!mounted) return;
          setState(() {
            _plans = r.gymPlans;
            _attendance = r.attendance;
          });
          NotificationService.instance.sync();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gym Calendar')),
      body: SafeArea(
        child: _loading
            ?  Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _buildSummary(),
                  const SizedBox(height: 16),
                  _buildMonthHeader(),
                  const SizedBox(height: 12),
                  _buildWeekdays(),
                  _buildGrid(),
                  const SizedBox(height: 14),
                  _buildLegend(),
                  const SizedBox(height: 20),
                  const AdBanner(),
                ],
              ),
      ),
    );
  }

  Widget _buildSummary() {
    final today = _key(DateTime.now());
    final answered = _plans.containsKey(today);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient:  LinearGradient(
          colors: [Color(0xFF24321A), AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              answered
                  ? (_plans[today]! ? Icons.fitness_center : Icons.self_improvement)
                  : Icons.event_available,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  answered
                      ? (_plans[today]! ? 'Gym day today' : 'Rest day today')
                      : 'Today: no plan yet',
                  style:  TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  answered
                      ? (_attendance.containsKey(today)
                          ? (_attendance[today]! ? 'You attended today' : 'You skipped today')
                          : 'Tap a day to mark attendance after training')
                      : 'Tap a day to plan or answer',
                  style: const TextStyle(color: Color(0xFFD8E4C2), fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return Row(
      children: [
        IconButton(
          onPressed: _prevMonth,
          icon:  Icon(Icons.chevron_left, color: AppColors.textPrimary),
        ),
        Expanded(
          child: Text(
            '${months[_month - 1]} $_year',
            textAlign: TextAlign.center,
            style:  TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ),
        IconButton(
          onPressed: _nextMonth,
          icon:  Icon(Icons.chevron_right, color: AppColors.textPrimary),
        ),
        IconButton(
          onPressed: _goToday,
          tooltip: 'Today',
          icon:  Icon(Icons.today, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildWeekdays() {
    return Row(
      children: _weekdays
          .map(
            (d) => Expanded(
              child: Text(
                d,
                textAlign: TextAlign.center,
                style:  TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildGrid() {
    final blanks = _leadingBlanks();
    final days = _daysInMonth();
    final today = DateTime.now();
    final todayKey = _key(today);

    final cells = <Widget>[];
    for (var i = 0; i < blanks; i++) {
      cells.add(const Expanded(child: SizedBox()));
    }

    for (var day = 1; day <= days; day++) {
      final date = DateTime(_year, _month, day);
      final key = _key(date);
      final isToday = key == todayKey;
      final planned = _plans[key];
      final attended = _attendance[key];
      final isFuture = date.isAfter(DateTime(today.year, today.month, today.day));

      cells.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: _DayCell(
              day: day,
              planned: planned,
              attended: attended,
              isToday: isToday,
              dimmed: isFuture || date.isBefore(DateTime(_year, _month, 1)),
              onTap: () => _openCheckIn(key),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var r = 0; r < (cells.length / 7).ceil(); r++)
          Row(
            children: cells.sublist(r * 7, ((r + 1) * 7).clamp(0, cells.length)).toList(),
          ),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children:  [
        _LegendItem(color: AppColors.success, label: 'Planned gym'),
        _LegendItem(color: AppColors.danger, label: 'Planned rest'),
        _LegendItem(icon: Icons.check_circle, color: AppColors.success, label: 'Attended'),
        _LegendItem(icon: Icons.cancel, color: AppColors.danger, label: 'Skipped'),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool? planned;
  final bool? attended;
  final bool isToday;
  final bool dimmed;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.planned,
    required this.attended,
    required this.isToday,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.surface;
    Color fg = AppColors.textPrimary;
    Widget? marker;

    if (attended == true) {
      bg = AppColors.success.withValues(alpha: 0.22);
      fg = AppColors.success;
      marker =  Icon(Icons.check, size: 14, color: AppColors.success);
    } else if (attended == false) {
      bg = AppColors.surfaceLight.withValues(alpha: 0.4);
      fg = AppColors.textSecondary;
      marker =  Icon(Icons.close, size: 14, color: AppColors.danger);
    } else if (planned == true) {
      bg = AppColors.surface;
      fg = AppColors.textPrimary;
    } else if (planned == false) {
      bg = AppColors.surface;
      fg = AppColors.textSecondary;
    }

    final bottomDot = (attended == null)
        ? Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: planned == true
                  ? AppColors.success
                  : planned == false
                      ? AppColors.danger
                      : Colors.transparent,
              shape: BoxShape.circle,
            ),
          )
        : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday ? AppColors.primary : AppColors.surfaceLight,
            width: isToday ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: dimmed ? fg.withValues(alpha: 0.5) : fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (marker != null) ...[const SizedBox(width: 3), marker],
              ],
            ),
            bottomDot ?? const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final IconData? icon;

  const _LegendItem({required this.color, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, color: color, size: 15)
        else
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: 5),
        Text(label, style:  TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
