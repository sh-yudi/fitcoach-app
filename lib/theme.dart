import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPalette {
  final Color bg;
  final Color surface;
  final Color surfaceLight;
  final Color primary;
  final Color primaryDark;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color danger;
  final Color success;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceLight,
    required this.primary,
    required this.primaryDark,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.danger,
    required this.success,
  });
}

const _darkPalette = AppPalette(
  bg: Color(0xFF0E1218),
  surface: Color(0xFF171D26),
  surfaceLight: Color(0xFF202936),
  primary: Color(0xFFB8F531),
  primaryDark: Color(0xFF7CC510),
  onPrimary: Color(0xFF11140A),
  textPrimary: Color(0xFFF2F5F7),
  textSecondary: Color(0xFF9AA7B4),
  danger: Color(0xFFFF5C5C),
  success: Color(0xFF3DD68C),
);

const _lightPalette = AppPalette(
  bg: Color(0xFFF5F7FA),
  surface: Color(0xFFFFFFFF),
  surfaceLight: Color(0xFFE2E8F0),
  primary: Color(0xFF6AA60A),
  primaryDark: Color(0xFF51840A),
  onPrimary: Color(0xFF11140A),
  textPrimary: Color(0xFF151A21),
  textSecondary: Color(0xFF5B6873),
  danger: Color(0xFFE5484D),
  success: Color(0xFF1FA971),
);

class AppColors {
  AppColors._();

  static Brightness _brightness = Brightness.dark;

  static void setBrightness(Brightness value) {
    _brightness = value;
  }

  static bool get isDark => _brightness == Brightness.dark;

  static AppPalette get _p => isDark ? _darkPalette : _lightPalette;

  static Color get bg => _p.bg;
  static Color get surface => _p.surface;
  static Color get surfaceLight => _p.surfaceLight;
  static Color get primary => _p.primary;
  static Color get primaryDark => _p.primaryDark;
  static Color get onPrimary => _p.onPrimary;
  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get danger => _p.danger;
  static Color get success => _p.success;

  // Semantic colors — used across multiple screens
  static const Color water = Color(0xFF3DA5FF);
  static const Color macroProtein = Color(0xFF3DD68C);
  static const Color macroCarbs = Color(0xFFFFB020);
  static const Color macroFiber = Color(0xFF6C8CFF);
  static const Color whatsapp = Color(0xFF25D366);
  static const Color avatarFallback = Color(0xFF2A2A3E);
  static const Color darkGreen = Color(0xFF24321A);
  static const Color darkGreenLight = Color(0xFFD8E4C2);
  static const Color cream = Color(0xFFFFF7E2);

  // Muscle group colors
  static const Map<String, Color> muscleColors = {
    'chest': Color(0xFFE74C3C),
    'back': Color(0xFF3498DB),
    'shoulders': Color(0xFF9B59B6),
    'arms': Color(0xFFE67E22),
    'biceps': Color(0xFFE67E22),
    'triceps': Color(0xFFE67E22),
    'core': Color(0xFFF1C40F),
    'abs': Color(0xFFF1C40F),
    'legs': Color(0xFF2ECC71),
    'quads': Color(0xFF2ECC71),
    'hamstrings': Color(0xFF27AE60),
    'glutes': Color(0xFF1ABC9C),
    'calves': Color(0xFF16A085),
    'cardio': Color(0xFFE91E63),
  };
}

class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const _prefsKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    _mode = ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.system,
    );
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}

ThemeData buildTheme(Brightness brightness) {
  AppColors.setBrightness(brightness);
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: isDark
        ? ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            secondary: AppColors.primaryDark,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
            error: AppColors.danger,
          )
        : ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            secondary: AppColors.primaryDark,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
            error: _lightPalette.danger,
          ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: AppColors.surfaceLight),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: TextStyle(color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.18),
      height: 68,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
