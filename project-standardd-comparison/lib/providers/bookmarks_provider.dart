import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Bookmark {
  final String id;
  final String bookId;
  final int page;
  final String snippet;
  final String note;
  final List<String> tags;
  final DateTime created;
  final DateTime? modified;
  final String? deepLink;

  Bookmark({
    required this.id,
    required this.bookId,
    required this.page,
    required this.snippet,
    this.note = '',
    this.tags = const [],
    required this.created,
    this.modified,
    this.deepLink,
  });

  Bookmark copyWith({
    String? id,
    String? bookId,
    int? page,
    String? snippet,
    String? note,
    List<String>? tags,
    DateTime? created,
    DateTime? modified,
    String? deepLink,
  }) {
    return Bookmark(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      page: page ?? this.page,
      snippet: snippet ?? this.snippet,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      created: created ?? this.created,
      modified: modified ?? this.modified,
      deepLink: deepLink ?? this.deepLink,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'page': page,
      'snippet': snippet,
      'note': note,
      'tags': tags,
      'created': created.toIso8601String(),
      'modified': modified?.toIso8601String(),
      'deepLink': deepLink,
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      page: json['page'] as int,
      snippet: json['snippet'] as String,
      note: json['note'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      created: DateTime.parse(json['created'] as String),
      modified:
          json['modified'] != null
              ? DateTime.parse(json['modified'] as String)
              : null,
      deepLink: json['deepLink'] as String?,
    );
  }
}

class BookmarksProvider extends ChangeNotifier {
  BookmarksProvider(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  static const String _bookmarksKey = 'bookmarks_v2';
  static const String _tagsKey = 'bookmark_tags';

  final Map<String, Bookmark> _bookmarks = {};
  final Set<String> _availableTags = {};

  // Filter state
  String _filterTag = '';
  String _filterBook = '';
  String _searchQuery = '';

  // Getters
  List<Bookmark> get bookmarks => _getFilteredBookmarks();
  List<Bookmark> get allBookmarks =>
      _bookmarks.values.toList()
        ..sort((a, b) => b.created.compareTo(a.created));
  Set<String> get availableTags => Set.unmodifiable(_availableTags);
  String get filterTag => _filterTag;
  String get filterBook => _filterBook;
  String get searchQuery => _searchQuery;

  // Legacy support for existing code
  Map<String, List<int>> get legacyBookmarks => {
    for (final bookmark in _bookmarks.values)
      bookmark.bookId:
          _bookmarks.values
              .where((b) => b.bookId == bookmark.bookId)
              .map((b) => b.page)
              .toList()
            ..sort(),
  };

  // Bookmark management
  String addBookmark({
    required String bookId,
    required int page,
    required String snippet,
    String note = '',
    List<String> tags = const [],
    String? deepLink,
  }) {
    final id = '${bookId}_${page}_${DateTime.now().millisecondsSinceEpoch}';
    final bookmark = Bookmark(
      id: id,
      bookId: bookId,
      page: page,
      snippet: snippet,
      note: note,
      tags: tags,
      created: DateTime.now(),
      deepLink: deepLink,
    );

    _bookmarks[id] = bookmark;
    _availableTags.addAll(tags);
    _save();
    notifyListeners();
    return id;
  }

  void updateBookmark(
    String id, {
    String? note,
    List<String>? tags,
    String? snippet,
    String? deepLink,
  }) {
    final bookmark = _bookmarks[id];
    if (bookmark == null) return;

    // Remove old tags from available tags if no longer used
    if (tags != null) {
      for (final oldTag in bookmark.tags) {
        if (!tags.contains(oldTag)) {
          final stillUsed = _bookmarks.values.any(
            (b) => b.id != id && b.tags.contains(oldTag),
          );
          if (!stillUsed) {
            _availableTags.remove(oldTag);
          }
        }
      }
      _availableTags.addAll(tags);
    }

    _bookmarks[id] = bookmark.copyWith(
      note: note,
      tags: tags,
      snippet: snippet,
      deepLink: deepLink,
      modified: DateTime.now(),
    );

    _save();
    notifyListeners();
  }

  void removeBookmark(String id) {
    final bookmark = _bookmarks.remove(id);
    if (bookmark == null) return;

    // Clean up unused tags
    for (final tag in bookmark.tags) {
      final stillUsed = _bookmarks.values.any((b) => b.tags.contains(tag));
      if (!stillUsed) {
        _availableTags.remove(tag);
      }
    }

    _save();
    notifyListeners();
  }

  // Legacy support
  void toggleBookmark({required String bookId, required int page}) {
    final existing =
        _bookmarks.values
            .where((b) => b.bookId == bookId && b.page == page)
            .firstOrNull;

    if (existing != null) {
      removeBookmark(existing.id);
    } else {
      addBookmark(
        bookId: bookId,
        page: page,
        snippet: 'Page $page', // Default snippet
      );
    }
  }

  bool isBookmarked({required String bookId, required int page}) {
    return _bookmarks.values.any((b) => b.bookId == bookId && b.page == page);
  }

  // Filtering and search
  void setFilterTag(String tag) {
    _filterTag = tag;
    notifyListeners();
  }

  void setFilterBook(String bookId) {
    _filterBook = bookId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _filterTag = '';
    _filterBook = '';
    _searchQuery = '';
    notifyListeners();
  }

  List<Bookmark> _getFilteredBookmarks() {
    var filtered = _bookmarks.values.toList();

    // Filter by tag
    if (_filterTag.isNotEmpty) {
      filtered = filtered.where((b) => b.tags.contains(_filterTag)).toList();
    }

    // Filter by book
    if (_filterBook.isNotEmpty) {
      filtered = filtered.where((b) => b.bookId == _filterBook).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered
              .where(
                (b) =>
                    b.snippet.toLowerCase().contains(query) ||
                    b.note.toLowerCase().contains(query) ||
                    b.tags.any((tag) => tag.toLowerCase().contains(query)),
              )
              .toList();
    }

    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.created.compareTo(a.created));
    return filtered;
  }

  // Tag management
  void addTag(String tag) {
    if (tag.trim().isNotEmpty) {
      _availableTags.add(tag.trim());
      _save();
      notifyListeners();
    }
  }

  void removeTag(String tag) {
    // Remove tag from all bookmarks
    final updatedBookmarks = <String, Bookmark>{};
    for (final entry in _bookmarks.entries) {
      final bookmark = entry.value;
      if (bookmark.tags.contains(tag)) {
        final newTags = bookmark.tags.where((t) => t != tag).toList();
        updatedBookmarks[entry.key] = bookmark.copyWith(
          tags: newTags,
          modified: DateTime.now(),
        );
      } else {
        updatedBookmarks[entry.key] = bookmark;
      }
    }

    _bookmarks.clear();
    _bookmarks.addAll(updatedBookmarks);
    _availableTags.remove(tag);

    _save();
    notifyListeners();
  }

  // Get bookmarks by book
  List<Bookmark> getBookmarksByBook(String bookId) {
    return _bookmarks.values.where((b) => b.bookId == bookId).toList()
      ..sort((a, b) => a.page.compareTo(b.page));
  }

  // Get bookmarks by tag
  List<Bookmark> getBookmarksByTag(String tag) {
    return _bookmarks.values.where((b) => b.tags.contains(tag)).toList()
      ..sort((a, b) => b.created.compareTo(a.created));
  }

  // Statistics
  int get totalBookmarks => _bookmarks.length;
  int get totalTags => _availableTags.length;
  Map<String, int> get bookmarksByBook {
    final counts = <String, int>{};
    for (final bookmark in _bookmarks.values) {
      counts[bookmark.bookId] = (counts[bookmark.bookId] ?? 0) + 1;
    }
    return counts;
  }

  void _load() {
    // Load new format bookmarks
    final bookmarksRaw = _prefs.getString(_bookmarksKey);
    if (bookmarksRaw != null) {
      try {
        final data = json.decode(bookmarksRaw) as Map<String, dynamic>;
        for (final entry in data.entries) {
          _bookmarks[entry.key] = Bookmark.fromJson(entry.value);
        }
      } catch (e) {
        // Handle parsing errors gracefully
        debugPrint('Error loading bookmarks: $e');
      }
    }

    // Load tags
    final tagsRaw = _prefs.getString(_tagsKey);
    if (tagsRaw != null) {
      try {
        final tags = (json.decode(tagsRaw) as List).cast<String>();
        _availableTags.addAll(tags);
      } catch (e) {
        debugPrint('Error loading tags: $e');
      }
    }

    // Migrate legacy bookmarks if needed
    _migrateLegacyBookmarks();

    // Rebuild available tags from bookmarks
    _rebuildAvailableTags();
  }

  void _migrateLegacyBookmarks() {
    final legacyRaw = _prefs.getString('bookmarks');
    if (legacyRaw != null && _bookmarks.isEmpty) {
      try {
        final data = json.decode(legacyRaw) as Map<String, dynamic>;
        for (final entry in data.entries) {
          final bookId = entry.key;
          final pages = (entry.value as List).cast<int>();
          for (final page in pages) {
            addBookmark(bookId: bookId, page: page, snippet: 'Page $page');
          }
        }
        // Remove legacy data after migration
        _prefs.remove('bookmarks');
      } catch (e) {
        debugPrint('Error migrating legacy bookmarks: $e');
      }
    }
  }

  void _rebuildAvailableTags() {
    _availableTags.clear();
    for (final bookmark in _bookmarks.values) {
      _availableTags.addAll(bookmark.tags);
    }
  }

  void _save() {
    // Save bookmarks
    final bookmarksData = <String, dynamic>{};
    for (final entry in _bookmarks.entries) {
      bookmarksData[entry.key] = entry.value.toJson();
    }
    _prefs.setString(_bookmarksKey, json.encode(bookmarksData));

    // Save tags
    _prefs.setString(_tagsKey, json.encode(_availableTags.toList()));
  }
}
