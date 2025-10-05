import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarksProvider extends ChangeNotifier {
  BookmarksProvider(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  static const String _key = 'bookmarks';
  // Map<bookId, List<int pageNumbers>>
  final Map<String, List<int>> _bookIdToPages = {};

  Map<String, List<int>> get bookmarks => {
    for (final entry in _bookIdToPages.entries)
      entry.key: List<int>.from(entry.value)..sort(),
  };

  void toggleBookmark({required String bookId, required int page}) {
    final pages = _bookIdToPages.putIfAbsent(bookId, () => <int>[]);
    if (pages.contains(page)) {
      pages.remove(page);
    } else {
      pages.add(page);
    }
    _save();
    notifyListeners();
  }

  bool isBookmarked({required String bookId, required int page}) {
    return _bookIdToPages[bookId]?.contains(page) ?? false;
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    final data = json.decode(raw) as Map<String, dynamic>;
    for (final entry in data.entries) {
      _bookIdToPages[entry.key] =
          (entry.value as List).map((e) => e as int).toList();
    }
  }

  void _save() {
    final raw = json.encode(_bookIdToPages);
    _prefs.setString(_key, raw);
  }
}
