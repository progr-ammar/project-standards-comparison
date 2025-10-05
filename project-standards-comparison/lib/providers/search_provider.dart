import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchProvider extends ChangeNotifier {
  SearchProvider(this._prefs) {
    _recent = _prefs.getStringList(_recentKey) ?? <String>[];
  }

  final SharedPreferences _prefs;
  static const String _recentKey = 'recent_searches';

  List<String> _recent = <String>[];
  List<String> get recent => List.unmodifiable(_recent);

  void addRecent(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _recent.removeWhere((q) => q.toLowerCase() == trimmed.toLowerCase());
    _recent.insert(0, trimmed);
    if (_recent.length > 10) _recent = _recent.sublist(0, 10);
    _prefs.setStringList(_recentKey, _recent);
    notifyListeners();
  }

  void removeRecent(String query) {
    _recent.remove(query);
    _prefs.setStringList(_recentKey, _recent);
    notifyListeners();
  }

  void clearRecent() {
    _recent.clear();
    _prefs.setStringList(_recentKey, _recent);
    notifyListeners();
  }
}
