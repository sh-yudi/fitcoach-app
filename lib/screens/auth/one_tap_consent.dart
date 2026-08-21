import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../theme.dart';

// One-tap login consent dialog. Shown once, right after the very first
// successful login or registration on this device. The user can skip it;
// they can enable or disable one-tap login anytime from Settings.

const _promptedKey = 'one_tap_prompted';

Future<bool> oneTapPrompted() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_promptedKey) ?? false;
}

Future<void> markOneTapPrompted() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_promptedKey, true);
}

// Shows the consent dialog. Returns true if the user enabled one-tap login.
Future<bool> promptOneTapConsent(BuildContext context) async {
  final enabled = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
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
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child:  Icon(Icons.bolt, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 14),
           Text(
            'Skip login next time?',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
          ),
        ],
      ),
      content:  Text(
        'Enable one-tap login so you can get back into the app with a single '
        'tap — no need to type your email and password again on this device.\n\n'
        'We\'ll securely store a login token on this device. You can turn it '
        'on or off anytime from Settings.',
        style: TextStyle(color: AppColors.textSecondary, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child:  Text('Skip for now', style: TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
          child: const Text('Enable one-tap login'),
        ),
      ],
    ),
  );
  return enabled == true;
}

// Called right after a successful login/registration. Shows the consent
// dialog once (only the first time on this device), and if accepted, issues
// and stores the one-tap token.
Future<void> maybePromptOneTapConsent(BuildContext context) async {
  if (await oneTapPrompted()) return;
  await markOneTapPrompted();
  if (!context.mounted) return;
  final agreed = await promptOneTapConsent(context);
  if (!agreed) return;
  try {
    final result = await ApiClient.instance.enableOneTap();
    final email = await Session.email() ?? '';
    await Session.save(
      await Session.token() ?? '',
      email,
      name: result.user.name,
      rememberToken: result.rememberToken,
      photo: result.user.displayPhoto,
    );
  } catch (_) {
    // Non-fatal: one-tap login simply stays off.
  }
}
