import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._prefs) {
    final mode = _prefs.getString(_key) ?? 'system';
    _themeMode = _parse(mode);
  }

  static const String _key = 'theme_mode';
  final SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleThemeMode() {
    if (_themeMode == ThemeMode.dark) {
      _set(ThemeMode.light);
    } else {
      _set(ThemeMode.dark);
    }
  }

  void _set(ThemeMode mode) {
    _themeMode = mode;
    _prefs.setString(_key, _stringify(mode));
    notifyListeners();
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

