import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme.dart';

class StatCard extends StatefulWidget {
  final String label;
  final String value;
  final String? sub;
  final Color? accent;
  final IconData icon;
  final VoidCallback? onTap;

  /// Highlight the card because the metric is out of the healthy range.
  final bool alert;

  /// Blink (red flash) for a few seconds after this widget first appears.
  final bool blink;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.accent,
    this.icon = Icons.insights,
    this.onTap,
    this.alert = false,
    this.blink = false,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> with SingleTickerProviderStateMixin {
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    if (widget.blink) _startBlink();
  }

  @override
  void didUpdateWidget(StatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blink && !oldWidget.blink) _startBlink();
  }

  void _startBlink() {
    _blinkTimer?.cancel();
    _flash.repeat(reverse: true);
    _blinkTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      _flash.stop();
      _flash.value = 0;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.alert ? AppColors.danger : (widget.accent ?? AppColors.primary);
    final showIcon = widget.alert ? Icons.warning_amber_rounded : widget.icon;

    Widget content = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.alert
              ? AppColors.danger.withValues(alpha: 0.6)
              : accent.withValues(alpha: 0.35),
          width: widget.alert ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(showIcon, color: accent, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.label,
                  style:  TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.value,
            style: TextStyle(
              color: accent,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          if (widget.sub != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.sub!,
              style: TextStyle(
                color: widget.alert ? AppColors.danger : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedBuilder(
        animation: _flash,
        builder: (context, child) {
          final opacity = _flash.isAnimating ? 0.10 + 0.25 * _flash.value : 0.0;
          return Stack(
            children: [
              child!,
              if (opacity > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        child: content,
      ),
    );
  }
}
