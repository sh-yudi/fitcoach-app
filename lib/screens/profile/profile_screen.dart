import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/profile_photo.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/profile_avatar.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User? user;
  final void Function(User) onUpdated;
  const ProfileScreen({super.key, this.user, required this.onUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _heightText;
  late String _activity;
  late String _fitnessLevel;
  late String _workoutTime;
  late bool _veg;
  String? _wakeTime;
  String? _sleepTime;
  String? _gymTime;

  late final TextEditingController _weight;
  late final TextEditingController _waist;
  late final TextEditingController _neck;
  late final TextEditingController _hip;
  bool _saving = false;
  String? _message;
  bool _oneTapEnabled = false;

  @override
  void initState() {
    super.initState();
    _weight = TextEditingController();
    _waist = TextEditingController();
    _neck = TextEditingController();
    _hip = TextEditingController();
    _syncFromUser(widget.user);
    _loadOneTap();
  }

  Future<void> _loadOneTap() async {
    final token = await Session.rememberToken();
    if (!mounted) return;
    setState(() => _oneTapEnabled = token != null && token.isNotEmpty);
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      _syncFromUser(widget.user);
    }
  }

  void _syncFromUser(User? u) {
    _heightText = u?.heightCm.toString() ?? _heightText;
    _activity = u?.activityLevel ?? _activity;
    _fitnessLevel = u?.fitnessLevel ?? _fitnessLevel;
    _workoutTime = u?.workoutTime ?? _workoutTime;
    _veg = u?.veg ?? _veg;
    _wakeTime = u?.wakeTime;
    _sleepTime = u?.sleepTime;
    _gymTime = u?.gymTime;
  }

  Future<void> _changePhoto() async {
    final base64 = await pickProfilePhoto(context);
    if (base64 == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final user = await ApiClient.instance.updateProfile({'profilePhoto': base64});
      await Session.setRememberPhoto(user.displayPhoto);
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onUpdated(user);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _waist.dispose();
    _neck.dispose();
    _hip.dispose();
    super.dispose();
  }

  String get _workoutTimeLabel => switch (_workoutTime) {
        'morning' => 'Morning (5-9 AM)',
        'midday' => 'Midday (11 AM - 2 PM)',
        'afternoon' => 'Afternoon (3-6 PM)',
        'evening' => 'Evening (6-9 PM)',
        _ => 'Afternoon (3-6 PM)',
      };

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    final heightCm = int.tryParse(_heightText);
    final weightKg = int.tryParse(_weight.text);
    if (heightCm == null || weightKg == null) {
      setState(() {
        _saving = false;
        _message = 'Enter valid Height and Weight.';
      });
      return;
    }
    int? toCm(String text) {
      final v = text.isNotEmpty ? double.tryParse(text) : null;
      return v == null ? null : (v * 2.54).round();
    }

    final waistCm = toCm(_waist.text);
    final neckCm = toCm(_neck.text);
    final hipCm = toCm(_hip.text);
    final body = <String, dynamic>{
      'heightCm': heightCm,
      'weightKg': weightKg,
      'activityLevel': _activity,
      'fitnessLevel': _fitnessLevel,
      'workoutTime': _workoutTime,
      'veg': _veg,
    };
    if (waistCm != null) body['waistCm'] = waistCm;
    if (neckCm != null) body['neckCm'] = neckCm;
    if (hipCm != null) body['hipCm'] = hipCm;
    try {
      final updated = await ApiClient.instance.updateProfile(body);
      widget.onUpdated(updated);
      setState(() {
        _saving = false;
        _message = 'Saved — your plans were recalculated.';
      });
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _message = e.message;
      });
    }
  }

  Future<void> _logout() async {
    await ApiClient.instance.logout();
    await Session.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _editHeight() {
    showDialog<void>(
      context: context,
      builder: (_) => _HeightDialog(
        initial: _heightText,
        onSave: (v) {
          setState(() => _heightText = v);
          _patchProfile({'heightCm': int.parse(v)}, successMsg: 'Height updated');
        },
      ),
    );
  }

  Widget _genderIcon(User u) {
    return Icon(
      u.gender == 'male' ? Icons.man : Icons.woman,
      color: AppColors.onPrimary,
      size: 30,
    );
  }

  Future<void> _editName() async {
    final u = widget.user;
    if (u == null) return;
    final controller = TextEditingController(text: u.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title:  Text('Change name', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Full name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || name == u.name) return;
    await _patchProfile({'name': name}, successMsg: 'Name updated');
  }

  Future<void> _editPassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title:  Text('Change password', style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: current,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Current password'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: next,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'New password (min 6)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirm,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Confirm new password'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (next.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('New password must be at least 6 characters')),
                        );
                        return;
                      }
                      if (next.text != confirm.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Passwords do not match')),
                        );
                        return;
                      }
                      setDialogState(() => saving = true);
                      try {
                        await ApiClient.instance.changePassword(current.text, next.text);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password changed')),
                          );
                        }
                      } on ApiException catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                        }
                        setDialogState(() => saving = false);
                      }
                    },
              child: saving
                  ?  SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
    current.dispose();
    next.dispose();
    confirm.dispose();
  }

  void _showOptionPicker({
    required String title,
    required String current,
    required List<({String value, String label})> options,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
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
                title,
                style:  TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              ...options.map(
                (o) => InkWell(
                  onTap: () {
                    onSelect(o.value);
                    Navigator.of(ctx).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            o.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: o.value == current ? FontWeight.w800 : FontWeight.w500,
                              color: o.value == current ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (o.value == current)
                           Icon(Icons.check, color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
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
                'Account options',
                style:  TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  Navigator.of(ctx).pop();
                  _editPassword();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child:  Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Change password',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                       Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _OneTapRow(
                enabled: _oneTapEnabled,
                onToggle: _toggleOneTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleOneTap(bool enable) async {
    setState(() => _oneTapEnabled = enable);
    try {
      if (enable) {
        final result = await ApiClient.instance.enableOneTap();
        await Session.save(
          await Session.token() ?? '',
          result.user.email,
          name: result.user.name,
          rememberToken: result.rememberToken,
        );
      } else {
        await ApiClient.instance.disableOneTap();
        await Session.clearOneTap();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(enable ? 'One-tap login enabled' : 'One-tap login disabled')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _oneTapEnabled = !enable);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _patchProfile(Map<String, dynamic> body, {String? successMsg}) async {
    try {
      final updated = await ApiClient.instance.updateProfile(body);
      if (!mounted) return;
      widget.onUpdated(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg ?? 'Saved'), duration: const Duration(seconds: 1)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String _fmtTime24(String v) {
    if (v.isEmpty) return '--:--';
    return v;
  }

  Future<void> _pickTime(String field, String? current) async {
    TimeOfDay initial;
    if (current != null && current.contains(':')) {
      final parts = current.split(':');
      initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } else {
      initial = TimeOfDay.now();
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) {
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      final val = '$hh:$mm';
      setState(() {
        if (field == 'wakeTime') _wakeTime = val;
        if (field == 'sleepTime') _sleepTime = val;
        if (field == 'gymTime') _gymTime = val;
      });
      _patchProfile({field: val}, successMsg: '${field.replaceAll('Time', ' time')} saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon:  Icon(Icons.settings_outlined, color: AppColors.textSecondary),
          tooltip: 'Settings',
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
            // Refresh so a profile photo set in Settings shows right away.
            if (!mounted) return;
            try {
              final refreshed = await ApiClient.instance.getProfile();
              if (mounted) widget.onUpdated(refreshed);
            } catch (_) {}
          },
        ),
        actions: [
          IconButton(
            icon:  Icon(Icons.logout, color: AppColors.danger),
            tooltip: 'Log out',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: u == null
            ?  Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: _changePhoto,
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: ProfileAvatar(
                                photoUrl: u.isPhotoUrl ? u.profilePhotoUrl : null,
                                base64: u.isPhotoUrl ? null : u.profilePhoto,
                                size: 56,
                                fallbackIcon: u.gender == 'female' ? Icons.female : Icons.male,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.bg, width: 2),
                                ),
                                child:  Icon(Icons.camera_alt, color: AppColors.onPrimary, size: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: _editName,
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(u.name, style:  TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                                    ),
                                    const SizedBox(width: 4),
                                     Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 15),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            InkWell(
                              onTap: _showAccountOptions,
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(u.email, style:  TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                    ),
                                    const SizedBox(width: 4),
                                     Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 16),
                                  ],
                                ),
                              ),
                            ),
                            if (u.userId.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.tag, color: AppColors.primary, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ID: ${u.userId}',
                                          style:  TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceLight),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(label: 'Age', value: '${u.age} years'),
                        _EditRow(
                          label: 'Height',
                          value: '$_heightText cm',
                          onTap: _editHeight,
                        ),
                        _InfoRow(label: 'Gender', value: u.gender == 'male' ? 'Male' : 'Female'),
                        _EditRow(
                          label: 'Activity',
                          value: toTitleCase(_activity),
                          onTap: () => _showOptionPicker(
                            title: 'Activity level',
                            current: _activity,
                            options: const [
                              (value: 'sedentary', label: 'Sedentary (desk job)'),
                              (value: 'light', label: 'Light (1-3 workouts/week)'),
                              (value: 'moderate', label: 'Moderate (3-5 workouts/week)'),
                              (value: 'active', label: 'Active (6-7 workouts/week)'),
                              (value: 'athlete', label: 'Athlete (hard daily training)'),
                            ],
                            onSelect: (v) {
                              setState(() => _activity = v);
                              _patchProfile({'activityLevel': v});
                            },
                          ),
                        ),
                        _EditRow(
                          label: 'Experience',
                          value: toTitleCase(_fitnessLevel),
                          onTap: () => _showOptionPicker(
                            title: 'Training experience',
                            current: _fitnessLevel,
                            options: const [
                              (value: 'beginner', label: 'Beginner (new to gym)'),
                              (value: 'intermediate', label: 'Intermediate (1-3 years)'),
                              (value: 'advanced', label: 'Advanced (3+ years)'),
                            ],
                            onSelect: (v) {
                              setState(() => _fitnessLevel = v);
                              _patchProfile({'fitnessLevel': v});
                            },
                          ),
                        ),
                        _EditRow(
                          label: 'Diet',
                          value: _veg ? 'Vegetarian' : 'Mixed',
                          onTap: () => _showOptionPicker(
                            title: 'Diet',
                            current: _veg ? 'veg' : 'mixed',
                            options: const [
                              (value: 'mixed', label: 'Mixed diet'),
                              (value: 'veg', label: 'Vegetarian diet'),
                            ],
                            onSelect: (v) {
                              setState(() => _veg = v == 'veg');
                              _patchProfile({'veg': v == 'veg'});
                            },
                          ),
                        ),
                        _EditRow(
                          label: 'Workout time',
                          value: _workoutTimeLabel,
                          onTap: () => _showOptionPicker(
                            title: 'Workout time',
                            current: _workoutTime,
                            options: const [
                              (value: 'morning', label: 'Morning (5-9 AM)'),
                              (value: 'midday', label: 'Midday (11 AM - 2 PM)'),
                              (value: 'afternoon', label: 'Afternoon (3-6 PM)'),
                              (value: 'evening', label: 'Evening (6-9 PM)'),
                            ],
                            onSelect: (v) {
                              setState(() => _workoutTime = v);
                              _patchProfile({'workoutTime': v}, successMsg: 'Workout time saved');
                            },
                          ),
                        ),
                        Divider(height: 1, color: AppColors.surfaceLight),
                        _EditRow(
                          label: 'Wake up',
                          value: _wakeTime != null && _wakeTime!.isNotEmpty ? _fmtTime24(_wakeTime!) : 'Not set',
                          onTap: () => _pickTime('wakeTime', _wakeTime),
                        ),
                        _EditRow(
                          label: 'Gym time',
                          value: _gymTime != null && _gymTime!.isNotEmpty ? _fmtTime24(_gymTime!) : 'Not set',
                          onTap: () => _pickTime('gymTime', _gymTime),
                        ),
                        _EditRow(
                          label: 'Sleep time',
                          value: _sleepTime != null && _sleepTime!.isNotEmpty ? _fmtTime24(_sleepTime!) : 'Not set',
                          onTap: () => _pickTime('sleepTime', _sleepTime),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                   Text(
                    'Update your measurements',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                   Text(
                    'Plans recalculate automatically after saving.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _NumberField(controller: _weight, hint: 'Weight (kg)', icon: Icons.monitor_weight_outlined),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _NumberField(controller: _waist, hint: 'Waist (in)', icon: Icons.straighten),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _NumberField(controller: _neck, hint: 'Neck (in)', icon: Icons.straighten),
                      ),
                      const SizedBox(width: 10),
                      if (u.gender == 'female')
                        Expanded(
                          child: _NumberField(controller: _hip, hint: 'Hip (in)', icon: Icons.straighten),
                        )
                      else
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ?  SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onPrimary),
                          )
                        : const Text('Save & recalculate'),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _message!.startsWith('Saved') ? AppColors.success : AppColors.danger,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const AdBanner(),
                ],
              ),
      ),
    );
  }
}

class _HeightDialog extends StatefulWidget {
  final String initial;
  final ValueChanged<String> onSave;
  const _HeightDialog({required this.initial, required this.onSave});

  @override
  State<_HeightDialog> createState() => _HeightDialogState();
}

class _HeightDialogState extends State<_HeightDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title:  Text('Height', style: TextStyle(color: AppColors.textPrimary)),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Height (cm)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final v = int.tryParse(_controller.text);
            if (v != null) widget.onSave(v.toString());
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style:  TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
          const Spacer(),
          Text(value, style:  TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EditRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _EditRow({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(label, style:  TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
            const Spacer(),
            Text(value, style:  TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
             Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  const _NumberField({required this.controller, required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20)),
    );
  }
}

class _OneTapRow extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onToggle;
  const _OneTapRow({required this.enabled, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child:  Icon(Icons.bolt, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'One-tap login',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  enabled
                      ? 'On — log in with one tap on this device'
                      : 'Off — you\'ll enter email & password',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onToggle,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
