import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/personal_training_card.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key, this.refreshToken = 0});

  final int refreshToken;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  WorkoutPlan? _workout;
  bool _loading = true;
  String? _error;
  String _split = '';
  bool _changingSplit = false;

  // Ticked exercises per day (day -> set of exercise names), persisted
  // server-side so ticks survive scrolling, split changes, refreshes and
  // app restarts.
  final Map<int, Set<String>> _ticked = {};

  // Serializes tick saves so rapid toggles never write out of order.
  Future<void> _saveChain = Future.value();

  // Which archived (done) day is expanded to peek at its completed exercises.
  // Only one previous day can be expanded at a time.
  int? _expandedDay;

  static const _splits = [
    (value: 'upperlower', label: 'Upper / Lower', subtitle: '4 days/week'),
    (value: 'ppl', label: 'Push / Pull / Legs', subtitle: 'Push → Pull → Legs → Repeat'),
    (value: 'single', label: 'Single Body Part', subtitle: '6 days/week'),
    (value: 'two', label: 'Two Body Parts', subtitle: '4 days/week'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(WorkoutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) {
      _load();
    }
  }

  Future<void> _load({bool awaitPending = true}) async {
    // Wait for in-flight tick saves to flush first so a refresh doesn't
    // clobber locally ticked exercises with stale server state. When called
    // from inside the save chain itself, skip the await to avoid a deadlock.
    if (awaitPending) await _saveChain;
    if (_workout == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final r = await ApiClient.instance.getWorkout();
      if (!mounted) return;
      setState(() {
        _workout = r.workout;
        _split = r.workout.split;
        _ticked
          ..clear()
          ..addEntries(r.ticks.entries.map(
            (e) => MapEntry(
              int.tryParse(e.key.toString()) ?? 0,
              ((e.value as List?) ?? []).whereType<String>().toSet(),
            ),
          ));
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _toggleExercise(int day, String name) {
    setState(() {
      final set = _ticked.putIfAbsent(day, () => {});
      if (!set.remove(name)) set.add(name);
      _expandedDay = null;
    });
    final names = List<String>.from(_ticked[day] ?? const []);
    _saveChain = _saveChain.then((_) async {
      try {
        await ApiClient.instance.saveWorkoutTicks(day, names);
      } on ApiException {
        // Best-effort: next toggle or refresh will resync from the server.
      }
    });
    _maybeAutoComplete(day);
  }

  // When every exercise of a day is ticked, the day completes automatically
  // and a motivational message celebrates the progress.
  void _maybeAutoComplete(int day) {
    final dayPlan = _workout?.weekly.where((d) => d.day == day).firstOrNull;
    final exercises = dayPlan?.workout ?? const <Exercise>[];
    final absExercises = dayPlan?.abs ?? const <Exercise>[];
    final allExercises = [...exercises, ...absExercises];
    if (allExercises.isEmpty || dayPlan?.done == true) return;
    final ticked = _ticked[day] ?? const <String>{};
    if (!allExercises.every((e) => ticked.contains(e.name))) return;

    _saveChain = _saveChain.then((_) async {
      try {
        await ApiClient.instance.completeWorkout(day);
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    });
    // Reload AFTER the chain resolves (not inside it) so the refresh can safely
    // await the chain without deadlocking, then celebrate the completed day.
    _saveChain.then((_) async {
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      _showMotivation(day);
    });
  }

  static const _motivations = [
    'Another day checked off! Every workout is a brick in the foundation of the stronger, fitter you.',
    'That is one more step forward on your fitness journey. Small days done consistently build big results.',
    'Day complete! Your future self is thanking you for showing up and putting in the work.',
    'You just got stronger — both in body and in discipline. Keep stacking these wins!',
    'One workout down. The version of you that reaches the goal is built by days exactly like this one.',
    'Progress is not a sprint, it is a journey — and today you walked further on it. Well done!',
    'The hardest rep was showing up. You did. Celebrate today, come back stronger tomorrow.',
    'Every completed day adds up. You are not just working out, you are becoming a new person.',
    'Today\'s effort is tomorrow\'s strength. Great session — your journey is moving forward!',
    'Consistency beats intensity. Another consistent day means another step toward your goal.',
    'You showed up for yourself today — that is what a real fitness journey is made of. Keep going!',
    'Perfect is not the goal, progress is. And today, you made progress. Fantastic work!',
  ];

  void _showMotivation(int day) {
    final msg = _motivations[Random().nextInt(_motivations.length)];
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child:  Icon(Icons.emoji_events, color: AppColors.success, size: 26),
            ),
            const SizedBox(height: 14),
             Text(
              'Day $day complete!',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
        content:  Text(
          msg,
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
            child: const Text('Keep going'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeSplit(String value) async {
    if (value == _split) return;

    // Only warn when a ticked exercise is actually part of the current plan
    // (stale ticks from an older plan or a previous week should not trigger it).
    final planNames = <String>{
      for (final day in _workout?.weekly ?? const <WorkoutDay>[])
        for (final ex in day.workout ?? const <Exercise>[]) ex.name,
    };
    final hasTickedInPlan = _ticked.values.any((set) => set.any(planNames.contains));
    if (hasTickedInPlan) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Change workout split?'),
          content: const Text(
            'You have already started exercises in this week\'s plan. '
            'Changing the split will replace today\'s workout and your ticked progress may be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Change Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    setState(() => _changingSplit = true);
    try {
      await ApiClient.instance.updateProfile({'workoutSplit': value});
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _changingSplit = false);
    }
  }

  void _toggleExpand(int day) {
    setState(() => _expandedDay = _expandedDay == day ? null : day);
  }

  void _onUndoComplete(int day) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Undo completion?'),
        content: Text(
          'This will reopen Day $day so you can modify your exercises.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Reopen'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    _saveChain = _saveChain.then((_) async {
      try {
        await ApiClient.instance.uncompleteWorkout(day);
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    });
    _saveChain.then((_) async {
      if (!mounted) return;
      await _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training Program')),
      body: SafeArea(
        child: _loading
            ?  Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
            : _error != null
                ? _ErrorView(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        _SplitSelector(
                          splits: _splits,
                          current: _split,
                          busy: _changingSplit,
                          onSelect: _changeSplit,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _ProgramCard(workout: _workout!),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CardioCard(workout: _workout!),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InfoBox(icon: Icons.self_improvement, text: 'Warm-up: ${_workout!.warmup}'),
                        const SizedBox(height: 10),
                        _InfoBox(icon: Icons.sports_gymnastics, text: 'Cool-down: ${_workout!.cooldown}'),
                        const SizedBox(height: 16),
                         Text(
                          'Weekly Schedule',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(
                          7,
                          (i) {
                            final wd = _workout!.weekly[i];
                            return _WorkoutDayCard(
                              day: wd,
                              ticked: _ticked[i + 1] ?? {},
                              expanded: _expandedDay == i + 1,
                              onToggle: (name) => _toggleExercise(i + 1, name),
                              onUndo: wd.done ? () => _onUndoComplete(wd.day) : null,
                              onHeaderTap: wd.done
                                  ? () => _toggleExpand(wd.day)
                                  : () => setState(() => _expandedDay = null),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const PersonalTrainingCard(),
                        const SizedBox(height: 20),
                        const AdBanner(),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final WorkoutPlan workout;
  const _ProgramCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Icon(Icons.fitness_center, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            workout.program,
            style:  TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '${toTitleCase(workout.level)} · ${workout.cycle + 1}/4 week',
            style:  TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _CardioCard extends StatelessWidget {
  final WorkoutPlan workout;
  const _CardioCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    final pick = (workout.cardioGuidance['pick'] as Map<String, dynamic>?) ?? {};
    final minutes = (workout.cardioGuidance['minutesPerSession'] as num?)?.toInt() ?? 20;
    final sessions = (workout.cardioGuidance['sessionsPerWeek'] as num?)?.toInt() ?? 2;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Icon(Icons.directions_run, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            '$sessions×$minutes min',
            style:  TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            pick['name'] as String? ?? 'Treadmill',
            style:  TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _WorkoutDayCard extends StatelessWidget {
  final WorkoutDay day;
  final Set<String> ticked;
  final bool expanded;
  final ValueChanged<String> onToggle;
  final VoidCallback? onHeaderTap;
  final VoidCallback? onUndo;
  const _WorkoutDayCard({
    required this.day,
    required this.ticked,
    required this.expanded,
    required this.onToggle,
    this.onHeaderTap,
    this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final day = this.day;
    final exercises = day.workout ?? [];
    final absExercises = day.abs ?? [];
    final cardio = day.cardio ?? [];
    final isRest = exercises.isEmpty && absExercises.isEmpty && cardio.isEmpty;
    final allExercises = [...exercises, ...absExercises];
    final doneCount = allExercises.where((e) => ticked.contains(e.name)).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: day.done
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.surfaceLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onHeaderTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isRest ? AppColors.surfaceLight : AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Day ${day.day}',
                      style: TextStyle(
                        color: isRest ? AppColors.textSecondary : AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      day.label.isEmpty ? (day.day == 7 ? 'Rest / Recovery' : 'Workout') : day.label,
                      style:  TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: day.done ? AppColors.success : AppColors.textPrimary,
                        decoration: day.done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  if (day.done) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Icon(Icons.check_circle, color: AppColors.success, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Done',
                            style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                     Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ] else if (!isRest && allExercises.isNotEmpty)
                    Text(
                      '$doneCount/${allExercises.length}',
                      style:  TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),
          ),
          if (day.done) ...[
            const SizedBox(height: 8),
            if (exercises.isEmpty && (day.abs ?? []).isEmpty)
              Text(
                'Completed — archived for this week. Fresh sets next week.',
                style:  TextStyle(color: AppColors.textSecondary, fontSize: 12),
              )
            else if (expanded) ...[
              Container(
                padding: const.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...exercises.map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                             Icon(Icons.check, color: AppColors.success, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${e.sets}×${e.reps}',
                              style:  TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if ((day.abs ?? []).isNotEmpty) ...[
                      const Divider(height: 16),
                      Text(
                        'Abs',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      ...day.abs!.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                               Icon(Icons.check, color: AppColors.success, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '${e.sets}×${e.reps}',
                                style:  TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (cardio.isNotEmpty) ...[
                      const Divider(height: 16),
                      ...cardio.map(
                        (c) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                               Icon(Icons.directions_run, color: AppColors.success, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${c.name} (${c.reps})',
                                  style:  TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (onUndo != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onUndo,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.undo, color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Undo completion',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ] else if (exercises.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...exercises.map(
              (e) => InkWell(
                onTap: () => onToggle(e.name),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: ticked.contains(e.name) ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: ticked.contains(e.name) ? AppColors.primary : AppColors.textSecondary,
                            width: 1.5,
                          ),
                        ),
                        child: ticked.contains(e.name)
                            ?  Icon(Icons.check, color: AppColors.onPrimary, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                decoration: ticked.contains(e.name) ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${e.muscle} · ${e.rest}s rest',
                              style:  TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${e.sets}×${e.reps}',
                        style:  TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if ((day.abs ?? []).isNotEmpty) ...[
              const Divider(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Abs',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
              ...day.abs!.map(
                (e) => InkWell(
                  onTap: () => onToggle(e.name),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: ticked.contains(e.name) ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: ticked.contains(e.name) ? AppColors.primary : AppColors.textSecondary,
                              width: 1.5,
                            ),
                          ),
                          child: ticked.contains(e.name)
                              ?  Icon(Icons.check, color: AppColors.onPrimary, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.name,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  decoration: ticked.contains(e.name) ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${e.muscle} · ${e.rest}s rest',
                                style:  TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${e.sets}×${e.reps}',
                          style:  TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
          if (cardio.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...cardio.map(
              (c) => Row(
                children: [
                   Icon(Icons.directions_run, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Cardio: ${c.name} (${c.reps})', style:  TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style:  TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4))),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(Icons.cloud_off, color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style:  TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _SplitSelector extends StatelessWidget {
  final List<({String value, String label, String subtitle})> splits;
  final String current;
  final bool busy;
  final ValueChanged<String> onSelect;
  const _SplitSelector({
    required this.splits,
    required this.current,
    required this.busy,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final selected = splits.where((s) => s.value == current).firstOrNull;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               Icon(Icons.tune, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Workout Split',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      TextSpan(
                        text: ' · Your weekly training split',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selected?.value,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'Select a split',
              prefixIcon: Icon(Icons.fitness_center, color: AppColors.primary, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: splits
                .map(
                  (s) => DropdownMenuItem(
                    value: s.value,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.label, style:  TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                        Text(s.subtitle, style:  TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                )
                .toList(),
            selectedItemBuilder: (ctx) => splits
                .map(
                  (s) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      s.label,
                      style:  TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                )
                .toList(),
            onChanged: busy ? null : (v) {
              if (v != null) onSelect(v);
            },
          ),
          if (busy) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                 Text('Saving split…', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
