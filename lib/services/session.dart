import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static const _tokenKey = 'auth_token';
  static const _emailKey = 'user_email';
  static const _nameKey = 'user_name';
  static const _rememberTokenKey = 'remember_token';
  static const _rememberEmailKey = 'remember_email';
  static const _rememberNameKey = 'remember_name';
  static const _rememberPhotoKey = 'remember_photo';
  static const _backgroundedAtKey = 'backgrounded_at';

  /// Auto-logout threshold: if the app stays backgrounded longer than this and
  /// is then resumed, the session is ended.
  static const Duration idleLogout = Duration(minutes: 30);

  static Future<void> save(String token, String email, {String? name, String? rememberToken, String? photo}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, email);
    if (name != null) await prefs.setString(_nameKey, name);
    if (rememberToken != null && rememberToken.isNotEmpty) {
      await prefs.setString(_rememberTokenKey, rememberToken);
      await prefs.setString(_rememberEmailKey, email);
      if (name != null) await prefs.setString(_rememberNameKey, name);
      await prefs.setString(_rememberPhotoKey, photo ?? '');
    }
  }

  static Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> email() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<String?> name() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<String?> rememberToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rememberTokenKey);
  }

  static Future<String?> rememberEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rememberEmailKey);
  }

  static Future<String?> rememberName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rememberNameKey);
  }

  static Future<String?> rememberPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_rememberPhotoKey);
    return (v == null || v.isEmpty) ? null : v;
  }

  static Future<void> setRememberPhoto(String? photo) async {
    final prefs = await SharedPreferences.getInstance();
    if (photo == null || photo.isEmpty) {
      await prefs.remove(_rememberPhotoKey);
    } else {
      await prefs.setString(_rememberPhotoKey, photo);
    }
  }

  // Logs out: clears the session but keeps the one-tap login token.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
  }

  // Records when the app moved to the background (or was killed from recents).
  static Future<void> markBackgrounded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_backgroundedAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Clears the backgrounded marker (on a normal foreground return).
  static Future<void> clearBackgrounded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backgroundedAtKey);
  }

  // Returns how long the app has been away, or null if never backgrounded.
  static Future<Duration?> backgroundedFor() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_backgroundedAtKey);
    if (ms == null) return null;
    return DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
  }

  // Ends the current session (keeps one-tap login).
  static Future<void> logoutIfIdle() async {
    final away = await backgroundedFor();
    await clearBackgrounded();
    if (away != null && away >= idleLogout) {
      await clear();
    }
  }

  // Called on cold start. If the app was killed while it was in the
  // background (e.g. swiped away from recents), the session is ended so the
  // next launch starts logged out.
  static Future<void> clearAfterKill() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_backgroundedAtKey);
    if (ms == null) return;
    await prefs.remove(_backgroundedAtKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
  }

  // Clears only the one-tap login token (keeps the active session).
  static Future<void> clearOneTap() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberTokenKey);
    await prefs.remove(_rememberEmailKey);
    await prefs.remove(_rememberNameKey);
    await prefs.remove(_rememberPhotoKey);
  }

  // Fully forgets the user including the one-tap login token.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_rememberTokenKey);
    await prefs.remove(_rememberEmailKey);
    await prefs.remove(_rememberNameKey);
    await prefs.remove(_rememberPhotoKey);
  }
}
