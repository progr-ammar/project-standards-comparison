import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._prefs) {
    _loadSettings();
  }

  static const String _themeModeKey = 'theme_mode';
  static const String _highContrastKey = 'high_contrast';
  static const String _textScaleKey = 'text_scale';
  static const String _reducedMotionKey = 'reduced_motion';

  final SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  bool _highContrast = false;
  double _textScale = 1.0;
  bool _reducedMotion = false;

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get highContrast => _highContrast;
  double get textScale => _textScale;
  bool get reducedMotion => _reducedMotion;

  // Theme mode management
  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }

  void toggleThemeMode() {
    toggleTheme();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs.setString(_themeModeKey, _stringify(mode));
    notifyListeners();
  }

  // Accessibility features
  void toggleHighContrast() {
    _highContrast = !_highContrast;
    _prefs.setBool(_highContrastKey, _highContrast);
    notifyListeners();
  }

  void setTextScale(double scale) {
    _textScale = scale.clamp(0.8, 2.0);
    _prefs.setDouble(_textScaleKey, _textScale);
    notifyListeners();
  }

  void toggleReducedMotion() {
    _reducedMotion = !_reducedMotion;
    _prefs.setBool(_reducedMotionKey, _reducedMotion);
    notifyListeners();
  }

  // Theme data generation with accessibility support
  ThemeData getLightTheme() {
    final colorScheme =
        _highContrast
            ? const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              secondary: Colors.black87,
              onSecondary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            )
            : ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      // Enhanced focus indicators for keyboard navigation
      focusColor: colorScheme.primary.withValues(alpha: 0.12),
      // Improved button themes for accessibility
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(44, 44), // Minimum touch target
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      // Enhanced input decoration for better visibility
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _highContrast ? Colors.black : colorScheme.outline,
            width: _highContrast ? 2.0 : 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
      ),
    );
  }

  ThemeData getDarkTheme() {
    final colorScheme =
        _highContrast
            ? const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              secondary: Colors.white70,
              onSecondary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
            )
            : ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      // Enhanced focus indicators for keyboard navigation
      focusColor: colorScheme.primary.withValues(alpha: 0.12),
      // Improved button themes for accessibility
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(44, 44), // Minimum touch target
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      // Enhanced input decoration for better visibility
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _highContrast ? Colors.white : colorScheme.outline,
            width: _highContrast ? 2.0 : 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
      ),
    );
  }

  // Animation duration based on reduced motion preference
  Duration get animationDuration =>
      _reducedMotion
          ? const Duration(milliseconds: 0)
          : const Duration(milliseconds: 300);

  void _loadSettings() {
    final mode = _prefs.getString(_themeModeKey) ?? 'system';
    _themeMode = _parse(mode);
    _highContrast = _prefs.getBool(_highContrastKey) ?? false;
    _textScale = _prefs.getDouble(_textScaleKey) ?? 1.0;
    _reducedMotion = _prefs.getBool(_reducedMotionKey) ?? false;
  }

  static ThemeMode _parse(String value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  static String _stringify(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }
}
