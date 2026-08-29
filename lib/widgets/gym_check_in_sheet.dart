import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme.dart';
import '../utils/helpers.dart';

/// Bottom sheet to plan and record gym attendance for a specific date.
class GymCheckInSheet extends StatefulWidget {
  final String dateKey;
  final bool? planned;
  final bool? attended;
  final Future<void> Function() onChanged;

  const GymCheckInSheet({
    super.key,
    required this.dateKey,
    required this.planned,
    required this.attended,
    required this.onChanged,
  });

  @override
  State<GymCheckInSheet> createState() => _GymCheckInSheetState();
}

class _GymCheckInSheetState extends State<GymCheckInSheet> {
  bool _busy = false;

  String get _label {
    final parts = widget.dateKey.split('-');
    const months = kMonths;
    return '${months[int.parse(parts[1]) - 1]} ${int.parse(parts[2])}, ${parts[0]}';
  }

  Future<void> _update({
    required bool? planned,
    required bool? attended,
  }) async {
    setState(() => _busy = true);
    try {
      if (planned != null) {
        await ApiClient.instance.setGymPlan(widget.dateKey, planned);
      }
      if (attended != null) {
        await ApiClient.instance.setGymAttendance(widget.dateKey, attended);
      }
      await widget.onChanged();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            attended != null
                ? (attended ? 'Marked as attended' : 'Marked as skipped')
                : (planned! ? 'Planned gym day' : 'Marked as rest day'),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
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
              _label,
              style:  TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
             Text(
              'Plan your day and record attendance.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 18),
             Text(
              'Going to the gym?',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ChoiceButton(
                    label: 'Yes, gym day',
                    icon: Icons.fitness_center,
                    color: AppColors.success,
                    selected: widget.planned == true,
                    onTap: _busy ? null : () => _update(planned: true, attended: null),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ChoiceButton(
                    label: 'No, rest day',
                    icon: Icons.self_improvement,
                    color: AppColors.danger,
                    selected: widget.planned == false,
                    onTap: _busy ? null : () => _update(planned: false, attended: null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
             Text(
              'Did you attend?',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ChoiceButton(
                    label: 'Attended',
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                    selected: widget.attended == true,
                    onTap: _busy ? null : () => _update(planned: null, attended: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ChoiceButton(
                    label: 'Skipped',
                    icon: Icons.cancel_outlined,
                    color: AppColors.danger,
                    selected: widget.attended == false,
                    onTap: _busy ? null : () => _update(planned: null, attended: false),
                  ),
                ),
              ],
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
               Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const _ChoiceButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : AppColors.surfaceLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : AppColors.textSecondary, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? color : AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
