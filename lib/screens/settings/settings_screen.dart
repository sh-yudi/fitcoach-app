import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../../services/profile_photo.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/section_header.dart';
import 'developer_screen.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  NotificationSettingsData _settings = const NotificationSettingsData();
  bool _loaded = false;
  bool _saving = false;
  bool _oneTapEnabled = false;
  String? _profilePhoto;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await NotificationService.instance.getSettings();
    final oneTap = await Session.rememberToken();
    final photo = await Session.rememberPhoto();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _oneTapEnabled = oneTap != null && oneTap.isNotEmpty;
      _profilePhoto = photo;
      _loaded = true;
    });
  }

  Future<void> _toggleOneTap(bool enable) async {
    setState(() => _oneTapEnabled = enable);
    try {
      if (enable) {
        final result = await ApiClient.instance.enableOneTap();
        final email = await Session.email() ?? '';
        await Session.save(
          await Session.token() ?? '',
          email,
          name: result.user.name,
          rememberToken: result.rememberToken,
          photo: result.user.displayPhoto,
        );
      } else {
        await ApiClient.instance.disableOneTap();
        await Session.clearOneTap();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _oneTapEnabled = !enable);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _apply(NotificationSettingsData next) async {
    setState(() {
      _settings = next;
      _saving = true;
    });
    await NotificationService.instance.setSettings(next);
    if (mounted) setState(() => _saving = false);
    await NotificationService.instance.sync();
  }

  Future<void> _changeProfilePhoto() async {
    final base64 = await pickProfilePhoto(context);
    if (base64 == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final user = await ApiClient.instance.updateProfile({'profilePhoto': base64});
      await Session.setRememberPhoto(user.displayPhoto);
      if (!mounted) return;
      setState(() {
        _profilePhoto = user.displayPhoto;
        _saving = false;
      });
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
  Widget build(BuildContext context) {
    if (!_loaded) {
      return  Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
      );
    }
    final s = _settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const SectionHeader(title: 'Appearance'),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                for (final mode in ThemeMode.values)
                  _ThemeModeRow(mode: mode),
              ],
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Notifications'),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _SwitchRow(
                  icon: Icons.notifications_active_outlined,
                  title: 'Enable reminders',
                  subtitle: 'Meal & workout notifications',
                  value: s.enabled,
                  onChanged: (v) => _apply(s.copyWith(enabled: v)),
                ),
                 Divider(height: 1, color: AppColors.surfaceLight),
                                
              ],
            ),
            const SizedBox(height: 20),
            _SettingsCard(
              children: [
                _SwitchRow(
                  icon: Icons.restaurant_outlined,
                  title: 'Meal reminders',
                  subtitle: 'Notify ${s.mealMinutes} min before each meal',
                  value: s.enabled && s.mealEnabled,
                  onChanged: (v) => _apply(s.copyWith(mealEnabled: v)),
                ),
                 Divider(height: 1, color: AppColors.surfaceLight),
                _StepperRow(
                  icon: Icons.timer_outlined,
                  title: 'Minutes before meals',
                  value: s.mealMinutes,
                  min: 5,
                  max: 30,
                  step: 5,
                  enabled: s.enabled && s.mealEnabled,
                  onChanged: (v) => _apply(s.copyWith(mealMinutes: v)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsCard(
              children: [
                _SwitchRow(
                  icon: Icons.fitness_center_outlined,
                  title: 'Workout reminder',
                  subtitle: 'Notify ${s.workoutMinutes} min before workout',
                  value: s.enabled && s.workoutEnabled,
                  onChanged: (v) => _apply(s.copyWith(workoutEnabled: v)),
                ),
                 Divider(height: 1, color: AppColors.surfaceLight),
                _StepperRow(
                  icon: Icons.timer_outlined,
                  title: 'Minutes before workout',
                  value: s.workoutMinutes,
                  min: 5,
                  max: 60,
                  step: 5,
                  enabled: s.enabled && s.workoutEnabled,
                  onChanged: (v) => _apply(s.copyWith(workoutMinutes: v)),
                ),
              ],
            ),
            if (_saving)
                Padding(
                padding: EdgeInsets.only(top: 14),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Account'),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _PhotoRow(
                  photo: _profilePhoto,
                  saving: _saving,
                  onTap: _saving ? null : _changeProfilePhoto,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Login'),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _SwitchRow(
                  icon: Icons.bolt,
                  title: 'One-tap login',
                  subtitle: 'Log in with one tap on this device',
                  value: _oneTapEnabled,
                  onChanged: _toggleOneTap,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!kReleaseMode) ...[
              const SectionHeader(title: 'Developer'),
              const SizedBox(height: 10),
              _SettingsCard(
                children: [
                  _NavRow(
                    icon: Icons.code,
                    title: 'Developer Information',
                    subtitle: 'About the app developer',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DeveloperScreen()),
                      );
                    },
                  ),
                ],
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

class _PhotoRow extends StatelessWidget {
  final String? photo;
  final bool saving;
  final VoidCallback? onTap;
  const _PhotoRow({required this.photo, required this.saving, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 56,
                height: 56,
                color: AppColors.primary.withValues(alpha: 0.12),
                child: ProfileAvatar(
                  photoUrl: photo != null && !photo!.startsWith('data:') ? photo : null,
                  base64: photo != null && photo!.startsWith('data:') ? photo : null,
                  size: 56,
                  fallbackIcon: Icons.person,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile photo',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    photo != null ? 'Tap to change your photo' : 'Add a profile photo',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (saving)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else
              Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _noPhotoIcon() {
    return Center(
      child: Icon(Icons.person, color: AppColors.primary, size: 30),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _NavRow({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primaryDark,
      activeThumbColor: AppColors.primary,
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style:  TextStyle(color: AppColors.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style:  TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final int value;
  final int min;
  final int max;
  final int step;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _StepperRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: enabled ? AppColors.textSecondary : AppColors.textSecondary.withValues(alpha: 0.4), size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: enabled ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: enabled && value > min ? () => onChanged(value - step) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.primary,
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style:  TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: enabled && value < max ? () => onChanged(value + step) : null,
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ThemeModeRow extends StatelessWidget {
  final ThemeMode mode;

  const _ThemeModeRow({required this.mode});

  IconData get _icon {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
    }
  }

  String get _label {
    switch (mode) {
      case ThemeMode.system:
        return 'Follow device';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final current = ThemeController.instance.mode;
        final selected = current == mode;
        return RadioGroup<ThemeMode>(
          groupValue: current,
          onChanged: (v) {
            if (v != null) ThemeController.instance.setMode(v);
          },
          child: ListTile(
            onTap: () => ThemeController.instance.setMode(mode),
            selected: selected,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(_icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 20),
            ),
            title: Text(
              _label,
              style: TextStyle(
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: Radio<ThemeMode>(
              value: mode,
              activeColor: AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}
