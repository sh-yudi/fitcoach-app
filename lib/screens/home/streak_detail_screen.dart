import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_pinch_zoom.dart';

class StreakDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const StreakDetailScreen({super.key, this.initialData});

  @override
  State<StreakDetailScreen> createState() => _StreakDetailScreenState();
}

class _StreakDetailScreenState extends State<StreakDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await ApiClient.instance.getStreaks();
      if (mounted) setState(() => _data = s);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final current = intFrom(_data, ['currentStreak', 'current', 'streak']);
    final longest = intFrom(_data, ['longestStreak', 'longest', 'bestStreak', 'best']);
    final total = intFrom(_data, ['totalWorkouts', 'workouts', 'total']);
    final rawBadges = _data?['badges'];
    final List<Map<String, dynamic>> badgeList = rawBadges is List
        ? rawBadges.whereType<Map>().map((b) => Map<String, dynamic>.from(b)).toList()
        : [];

    final milestones = [
      (
        days: 1,
        label: 'First Step',
        emoji: '🎯',
        description: 'Complete your very first workout. Open the Workouts tab, pick any workout, and finish every set. One session — that\'s all it takes to ignite your journey!',
        doneDescription: 'You crushed it on Day 1! The hardest part is starting — and you already did it. 🎉',
      ),
      (
        days: 5,
        label: 'On Fire',
        emoji: '🔥',
        description: 'Log a workout 5 days in a row without missing one. Even a 20-minute session counts — the key is to show up every single day and keep the fire burning!',
        doneDescription: 'Five days straight — your body is adapting and your willpower is razor sharp. You\'re officially on fire! 🔥',
      ),
      (
        days: 7,
        label: 'Week Warrior',
        emoji: '⚔️',
        description: 'Complete a full 7-day streak. Plan your sessions the night before, lay out your gear, and treat each workout like an unbreakable appointment with yourself.',
        doneDescription: 'A full week, zero excuses! You\'ve built a real habit that most people only dream about. ⚔️',
      ),
      (
        days: 14,
        label: 'Unstoppable',
        emoji: '💎',
        description: 'Stay consistent for 14 straight days. Two solid weeks means your body is in full adaptation mode — muscles are growing, endurance is rising. Push through rest-day temptations!',
        doneDescription: 'Two weeks of zero breaks! At this point, working out is part of who you are — not just what you do. 💎',
      ),
      (
        days: 30,
        label: 'Month Master',
        emoji: '👑',
        description: 'Complete 30 consecutive days of workouts. Mix strength, cardio, and stretching to stay injury-free, and track your progress in the Progress tab to see how far you\'ve come!',
        doneDescription: 'One full month — you are in the top 1% of people who commit and follow through. Absolute royalty! 👑',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Streak & Progress',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          if (_loading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            )
          else
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.textSecondary, size: 20),
              onPressed: _load,
            ),
        ],
      ),
      body: AppPinchZoom(
        child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _HeroStreakCard(current: current, longest: longest, total: total),
            const SizedBox(height: 20),

            Text('Streak Milestones', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...milestones.map((m) {
              final reached = longest >= m.days;
              final progress = (longest / m.days).clamp(0.0, 1.0);
              return _MilestoneRow(
                emoji: m.emoji,
                label: m.label,
                days: m.days,
                reached: reached,
                progress: progress,
                description: m.description,
                doneDescription: m.doneDescription,
              );
            }),

            const SizedBox(height: 20),
            Text('Badges Earned', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (badgeList.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1,
                ),
                itemCount: badgeList.length,
                itemBuilder: (_, i) => _BadgeTile(badge: badgeList[i]),
              )
            else
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: Column(children: [
                  const Text('🏅', style: TextStyle(fontSize: 34)),
                  const SizedBox(height: 8),
                  Text('No badges yet', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Complete your first workout to start earning badges!',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]),
              ),

            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _StatCard(emoji: '🔥', label: 'Current Streak', value: '$current day${current == 1 ? '' : 's'}', color: AppColors.streak)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(emoji: '🏆', label: 'Best Streak', value: '$longest day${longest == 1 ? '' : 's'}', color: const Color(0xFFFFC107))),
            ]),
            const SizedBox(height: 12),
            _StatCard(emoji: '💪', label: 'Total Workouts Completed', value: '$total workout${total == 1 ? '' : 's'}', color: AppColors.primary),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('💡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('How streaks work', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    'Every day you complete a workout counts toward your streak. Miss a day and it resets to zero. Your best streak is saved forever — even if your current one breaks!',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
                  ),
                ])),
              ]),
            ),
          ],
        ),
      ),
    ));
  }
}

class _HeroStreakCard extends StatelessWidget {
  final int current, longest, total;
  const _HeroStreakCard({required this.current, required this.longest, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3A2410), Color(0xFF7C4A12)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Container(
          width: 64, height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
          child: const Text('🔥', style: TextStyle(fontSize: 36)),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('$current', style: const TextStyle(color: Color(0xFFFFE8B0), fontSize: 40, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(width: 8),
            const Text('day streak', style: TextStyle(color: Color(0xFFF3DFC0), fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 4),
          Text(
            current > 0 ? 'Keep it up — work out today to extend it! 💪' : 'Complete a workout to start your streak!',
            style: TextStyle(color: const Color(0xFFD9C6A6).withValues(alpha: 0.9), fontSize: 11.5),
          ),
        ])),
      ]),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final String emoji, label, description, doneDescription;
  final int days;
  final bool reached;
  final double progress;
  const _MilestoneRow({
    required this.emoji,
    required this.label,
    required this.days,
    required this.reached,
    required this.progress,
    required this.description,
    required this.doneDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: reached ? AppColors.streak.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: reached ? AppColors.streak.withValues(alpha: 0.4) : AppColors.surfaceLight),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(label, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
              Text(
                reached ? '✓ Unlocked' : '$days days',
                style: TextStyle(color: reached ? AppColors.streak : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceLight,
                color: reached ? AppColors.streak : AppColors.primary,
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reached ? doneDescription : description,
              style: TextStyle(
                color: reached ? AppColors.streak.withValues(alpha: 0.85) : AppColors.textSecondary,
                fontSize: 11.5,
                height: 1.5,
                fontStyle: reached ? FontStyle.normal : FontStyle.normal,
              ),
            ),
          ])),
        ]),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final Map<String, dynamic> badge;
  const _BadgeTile({required this.badge});

  String _emoji(String id) {
    final lower = id.toLowerCase();
    if (lower.contains('first')) return '🎯';
    if (lower.contains('week') && lower.contains('warrior')) return '⚔️';
    if (lower.contains('fire') || lower.contains('streak_5')) return '🔥';
    if (lower.contains('unstop') || lower.contains('streak_14')) return '💎';
    if (lower.contains('month')) return '👑';
    if (lower.contains('century')) return '💯';
    return '🏅';
  }

  @override
  Widget build(BuildContext context) {
    final id = badge['id']?.toString() ?? '';
    final name = badge['name']?.toString() ?? id;
    final desc = badge['desc']?.toString() ?? '';
    return Tooltip(
      message: desc.isNotEmpty ? desc : name,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.streak.withValues(alpha: 0.35)),
          gradient: LinearGradient(
            colors: [AppColors.streak.withValues(alpha: 0.08), AppColors.surface],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_emoji(id), style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _StatCard({required this.emoji, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.surfaceLight)),
      child: Row(children: [
        Container(
          width: 38, height: 38, alignment: Alignment.center,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 14)),
        ])),
      ]),
    );
  }
}
