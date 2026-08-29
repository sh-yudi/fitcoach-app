import 'dart:async';

import 'package:flutter/material.dart';
import '../data/exercise_demos.dart';
import '../data/exercise_images.dart';
import '../theme.dart';

void showExerciseDemo(BuildContext context, String exerciseName) {
  final demo = getExerciseDemo(exerciseName);
  final images = exerciseImages[exerciseName];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ExerciseDemoSheet(demo: demo, images: images),
  );
}

Color _muscleColor(String muscle) {
  final m = muscle.toLowerCase();
  for (final entry in AppColors.muscleColors.entries) {
    if (m.contains(entry.key)) return entry.value;
  }
  if (m.contains('pec')) return AppColors.muscleColors['chest']!;
  if (m.contains('lat')) return AppColors.muscleColors['back']!;
  if (m.contains('delt')) return AppColors.muscleColors['shoulders']!;
  if (m.contains('arm')) return AppColors.muscleColors['arms']!;
  if (m.contains('leg')) return AppColors.muscleColors['legs']!;
  if (m.contains('glute')) return AppColors.muscleColors['hamstrings']!;
  if (m.contains('oblique')) return AppColors.muscleColors['core']!;
  if (m.contains('full')) return AppColors.muscleColors['cardio']!;
  return AppColors.textSecondary;
}

class _ExerciseDemoSheet extends StatefulWidget {
  final ExerciseDemo demo;
  final Map<String, String>? images;
  const _ExerciseDemoSheet({required this.demo, this.images});

  @override
  State<_ExerciseDemoSheet> createState() => _ExerciseDemoSheetState();
}

class _ExerciseDemoSheetState extends State<_ExerciseDemoSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  Timer? _dismissTimer;
  Timer? _frameTimer;
  int _currentStep = 0;
  bool _showPeak = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );
    _progressController.forward();

    _dismissTimer = Timer.periodic(const Duration(milliseconds: 1250), (t) {
      if (!mounted || _dismissed) return;
      setState(() {
        _currentStep = (_currentStep + 1) % widget.demo.steps.length;
      });
    });

    if (widget.images != null) {
      _frameTimer = Timer.periodic(const Duration(milliseconds: 700), (t) {
        if (!mounted || _dismissed) return;
        setState(() {
          _showPeak = !_showPeak;
        });
      });
    }

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_dismissed) {
        _dismissed = true;
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _frameTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demo = widget.demo;
    final images = widget.images;
    final hasImage = images != null;
    final muscleColor = _muscleColor(demo.muscle);

    return GestureDetector(
      onTap: () {
        _dismissed = true;
        Navigator.of(context).pop();
      },
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.78,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: muscleColor.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, -6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Image area with gradient background ──
                    if (hasImage)
                      Container(
                        width: double.infinity,
                        height: 220,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              muscleColor.withValues(alpha: 0.12),
                              muscleColor.withValues(alpha: 0.04),
                              AppColors.surface,
                            ],
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Decorative circles
                            Positioned(
                              top: -30,
                              right: -30,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: muscleColor.withValues(alpha: 0.06),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -20,
                              left: -20,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: muscleColor.withValues(alpha: 0.08),
                                ),
                              ),
                            ),
                            // Exercise illustration
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(opacity: anim, child: child),
                              child: Image.asset(
                                _showPeak ? images['peak']! : images['start']!,
                                key: ValueKey(_showPeak ? 'peak' : 'start'),
                                height: 190,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 190,
                                  width: 190,
                                  decoration: BoxDecoration(
                                    color: muscleColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.fitness_center,
                                    color: muscleColor,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                            // Muscle tag
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: muscleColor.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  demo.muscle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Content area ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title row
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: muscleColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  demo.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Steps
                          ...List.generate(demo.steps.length, (i) {
                            final isActive = i == _currentStep;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOut,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? LinearGradient(
                                        colors: [
                                          muscleColor.withValues(alpha: 0.12),
                                          muscleColor.withValues(alpha: 0.04),
                                        ],
                                      )
                                    : null,
                                color: isActive
                                    ? null
                                    : AppColors.surfaceLight.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(14),
                                border: isActive
                                    ? Border.all(
                                        color: muscleColor.withValues(alpha: 0.25),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? muscleColor
                                          : AppColors.surfaceLight,
                                      shape: BoxShape.circle,
                                      boxShadow: isActive
                                          ? [
                                              BoxShadow(
                                                color: muscleColor.withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: isActive
                                          ? Icon(
                                              Icons.play_arrow_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            )
                                          : Text(
                                              '${i + 1}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      demo.steps[i],
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: isActive
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isActive
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 10),

                          // Tip
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.lightbulb_rounded,
                                    size: 14,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    demo.tip,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Progress bar + close hint
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return LinearProgressIndicator(
                                  value: _progressAnimation.value,
                                  backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.5),
                                  valueColor: AlwaysStoppedAnimation<Color>(muscleColor),
                                  minHeight: 3,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Tap anywhere to close',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
