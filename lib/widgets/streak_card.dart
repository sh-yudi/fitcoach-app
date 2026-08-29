import 'package:flutter/material.dart';

/// Gamification card showing the current streak, personal bests and earned
/// badges. Data comes straight from `GET /api/streaks` — all fields are parsed
/// defensively so partial payloads never crash the home screen.
class StreakCard extends StatelessWidget {
  final Map<String, dynamic>? data;

  const StreakCard({super.key, this.data});

  int _int(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is num) return v.toInt();
      if (v is String) {
        final n = int.tryParse(v);
        if (n != null) return n;
      }
    }
    return 0;
  }

  String _badgeEmoji(String id) {
    final lower = id.toLowerCase();
    if (lower.contains('first')) return '🎯';
    if (lower.contains('week') && lower.contains('streak')) return '🔥';
    if (lower.contains('month')) return '🌟';
    if (lower.contains('ten') || lower.contains('10')) return '💪';
    if (lower.contains('fifty') || lower.contains('50')) return '🏆';
    if (lower.contains('century') || lower.contains('100')) return '👑';
    if (lower.contains('early')) return '🌅';
    if (lower.contains('perfect')) return '💎';
    return '🏅';
  }

  @override
  Widget build(BuildContext context) {
    final d = data ?? const {};
    final current = _int(d, ['currentStreak', 'current', 'streak']);
    final longest = _int(d, ['longestStreak', 'longest', 'bestStreak', 'best']);
    final total = _int(d, ['totalWorkouts', 'workouts', 'total']);
    final rawBadges = d['badges'];
    final badges = rawBadges is List ? rawBadges.map((b) => b.toString()).toList() : <String>[];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A2410), Color(0xFF7C4A12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🔥', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$current',
                          style: const TextStyle(color: Color(0xFFFFE8B0), fontSize: 26, fontWeight: FontWeight.w900, height: 1),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'day streak',
                          style: const TextStyle(color: Color(0xFFF3DFC0), fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      current > 0
                          ? 'Keep it going — work out today to extend it!'
                          : 'Complete a workout to start your streak',
                      style: TextStyle(color: const Color(0xFFD9C6A6).withValues(alpha: 0.9), fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _MiniStat(emoji: '🏆', label: 'Longest streak', value: '$longest ${longest == 1 ? 'day' : 'days'}')),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(emoji: '💪', label: 'Total workouts', value: '$total')),
            ],
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: badges.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Center(
                      child: Text(
                        'Badges',
                        style: TextStyle(color: const Color(0xFFD9C6A6).withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    );
                  }
                  final badge = badges[i - 1];
                  return Tooltip(
                    message: badge,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Text(_badgeEmoji(badge), style: const TextStyle(fontSize: 19)),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _MiniStat({required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: const Color(0xFFD9C6A6).withValues(alpha: 0.85), fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Color(0xFFFFF3DC), fontSize: 13.5, fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
