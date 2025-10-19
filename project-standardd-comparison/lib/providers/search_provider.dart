import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/error_handling_service.dart';

class SearchResult {
  final String bookId;
  final int pageNumber;
  final String snippet;
  final String highlightedText;
  final double matchScore;
  final String topic;
  final DateTime timestamp;

  SearchResult({
    required this.bookId,
    required this.pageNumber,
    required this.snippet,
    required this.highlightedText,
    required this.matchScore,
    required this.topic,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'pageNumber': pageNumber,
      'snippet': snippet,
      'highlightedText': highlightedText,
      'matchScore': matchScore,
      'topic': topic,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      bookId: json['bookId'] as String,
      pageNumber: json['pageNumber'] as int,
      snippet: json['snippet'] as String,
      highlightedText: json['highlightedText'] as String,
      matchScore: (json['matchScore'] as num).toDouble(),
      topic: json['topic'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class SearchSuggestion {
  final String text;
  final String type; // 'topic', 'recent', 'autocomplete'
  final double relevance;

  SearchSuggestion({
    required this.text,
    required this.type,
    this.relevance = 1.0,
  });
}

class SearchProvider extends ChangeNotifier {
  SearchProvider(this._prefs) {
    _loadData();
  }

  final SharedPreferences _prefs;
  final ErrorHandlingService _errorHandler = ErrorHandlingService();

  static const String _recentKey = 'recent_searches_v2';
  static const String _suggestionsKey = 'search_suggestions';
  static const String _resultsKey = 'search_results_cache';
  static const int _maxRecentSearches = 5;
  static const int _maxCachedResults = 20;

  List<String> _recent = <String>[];
  List<String> _suggestions = <String>[];
  Map<String, List<SearchResult>> _cachedResults = {};
  String _currentQuery = '';
  bool _isSearching = false;
  List<SearchResult> _currentResults = [];
  AppError? _lastSearchError;
  bool _hasPartialResults = false;

  // Getters
  List<String> get recent => List.unmodifiable(_recent);
  List<String> get suggestions => List.unmodifiable(_suggestions);
  String get currentQuery => _currentQuery;
  bool get isSearching => _isSearching;
  List<SearchResult> get currentResults => List.unmodifiable(_currentResults);
  AppError? get lastSearchError => _lastSearchError;
  bool get hasPartialResults => _hasPartialResults;

  // Search management
  void setCurrentQuery(String query) {
    _currentQuery = query;
    notifyListeners();
  }

  void setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  void setCurrentResults(
    List<SearchResult> results, {
    AppError? error,
    bool isPartial = false,
  }) {
    _currentResults = results;
    _lastSearchError = error;
    _hasPartialResults = isPartial;

    // Cache results for the current query if successful
    if (_currentQuery.isNotEmpty && error == null) {
      _cacheResults(_currentQuery, results);
    }

    // Log error if present
    if (error != null) {
      _errorHandler.logError(error);
    }

    notifyListeners();
  }

  void clearCurrentResults() {
    _currentResults = [];
    _currentQuery = '';
    _lastSearchError = null;
    _hasPartialResults = false;
    notifyListeners();
  }

  // Recent searches management
  void addRecent(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty || trimmed.length < 2) return;

    // Remove if already exists (case-insensitive)
    _recent.removeWhere((q) => q.toLowerCase() == trimmed.toLowerCase());

    // Add to beginning
    _recent.insert(0, trimmed);

    // Limit to max recent searches
    if (_recent.length > _maxRecentSearches) {
      _recent = _recent.sublist(0, _maxRecentSearches);
    }

    _saveRecentSearches();
    notifyListeners();
  }

  void removeRecent(String query) {
    _recent.remove(query);
    _saveRecentSearches();
    notifyListeners();
  }

  void clearRecent() {
    _recent.clear();
    _saveRecentSearches();
    notifyListeners();
  }

  // Autocomplete and suggestions
  List<SearchSuggestion> getAutocompleteSuggestions(String query) {
    if (query.trim().isEmpty) {
      // Return recent searches when no query
      return _recent
          .map(
            (text) =>
                SearchSuggestion(text: text, type: 'recent', relevance: 1.0),
          )
          .toList();
    }

    final suggestions = <SearchSuggestion>[];
    final queryLower = query.toLowerCase();

    // Add matching recent searches
    for (final recent in _recent) {
      if (recent.toLowerCase().contains(queryLower)) {
        suggestions.add(
          SearchSuggestion(text: recent, type: 'recent', relevance: 0.9),
        );
      }
    }

    // Add matching predefined suggestions
    for (final suggestion in _suggestions) {
      if (suggestion.toLowerCase().contains(queryLower)) {
        suggestions.add(
          SearchSuggestion(text: suggestion, type: 'topic', relevance: 0.8),
        );
      }
    }

    // Add autocomplete variations
    if (query.length >= 3) {
      final variations = _generateAutocompleteVariations(query);
      for (final variation in variations) {
        suggestions.add(
          SearchSuggestion(
            text: variation,
            type: 'autocomplete',
            relevance: 0.7,
          ),
        );
      }
    }

    // Sort by relevance and remove duplicates
    suggestions.sort((a, b) => b.relevance.compareTo(a.relevance));
    final seen = <String>{};
    return suggestions
        .where((s) => seen.add(s.text.toLowerCase()))
        .take(8)
        .toList();
  }

  List<String> _generateAutocompleteVariations(String query) {
    final variations = <String>[];
    final words = query.split(' ').where((w) => w.isNotEmpty).toList();

    if (words.isEmpty) return variations;

    // Add common PM terms that might complete the query
    final pmTerms = [
      'management',
      'process',
      'planning',
      'execution',
      'monitoring',
      'control',
      'closure',
      'stakeholder',
      'risk',
      'quality',
      'scope',
      'schedule',
      'cost',
      'resource',
      'communication',
      'procurement',
      'integration',
      'governance',
      'methodology',
      'framework',
      'lifecycle',
    ];

    final lastWord = words.last.toLowerCase();
    for (final term in pmTerms) {
      if (term.startsWith(lastWord) && term != lastWord) {
        final newWords = [...words.sublist(0, words.length - 1), term];
        variations.add(newWords.join(' '));
      }
    }

    return variations;
  }

  void updateSuggestions(List<String> newSuggestions) {
    _suggestions = newSuggestions;
    _saveSuggestions();
    notifyListeners();
  }

  // Results caching
  List<SearchResult>? getCachedResults(String query) {
    return _cachedResults[query.toLowerCase()];
  }

  void _cacheResults(String query, List<SearchResult> results) {
    final key = query.toLowerCase();
    _cachedResults[key] = results;

    // Limit cache size
    if (_cachedResults.length > _maxCachedResults) {
      final oldestKey = _cachedResults.keys.first;
      _cachedResults.remove(oldestKey);
    }

    _saveResultsCache();
  }

  void clearCache() {
    _cachedResults.clear();
    _prefs.remove(_resultsKey);
    notifyListeners();
  }

  // Search history analytics
  Map<String, int> getSearchFrequency() {
    final frequency = <String, int>{};
    for (final query in _recent) {
      frequency[query] = (frequency[query] ?? 0) + 1;
    }
    return frequency;
  }

  List<String> getPopularSearches() {
    final frequency = getSearchFrequency();
    final sorted =
        frequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).take(5).toList();
  }

  // Search validation and error handling
  AppError? validateSearchQuery(String query) {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      return AppError(
        type: ErrorType.processingError,
        severity: ErrorSeverity.low,
        message: 'Empty search query',
        details: 'Search query cannot be empty',
        suggestion: 'Enter a search term to find relevant content',
        context: 'Search validation',
      );
    }

    if (trimmed.length < 2) {
      return AppError(
        type: ErrorType.processingError,
        severity: ErrorSeverity.low,
        message: 'Search query too short',
        details: 'Search query must be at least 2 characters long',
        suggestion: 'Try a longer, more specific search term',
        context: 'Search validation',
      );
    }

    if (trimmed.length > 100) {
      return AppError(
        type: ErrorType.processingError,
        severity: ErrorSeverity.low,
        message: 'Search query too long',
        details: 'Search query should be less than 100 characters',
        suggestion: 'Try a shorter, more focused search term',
        context: 'Search validation',
      );
    }

    // Check for potentially problematic characters
    if (RegExp(r'[<>{}[\]\\|`~]').hasMatch(trimmed)) {
      return AppError(
        type: ErrorType.processingError,
        severity: ErrorSeverity.low,
        message: 'Invalid characters in search query',
        details:
            'Search query contains special characters that may cause issues',
        suggestion: 'Use only letters, numbers, and basic punctuation',
        context: 'Search validation',
      );
    }

    return null; // Query is valid
  }

  // Generate helpful search suggestions when no results found
  List<String> generateNoResultsSuggestions(String query) {
    final suggestions = <String>[];

    // Basic suggestions
    suggestions.addAll([
      'Try different keywords',
      'Use more general terms',
      'Check spelling',
      'Try searching for related concepts',
    ]);

    // Query-specific suggestions
    final words = query.toLowerCase().split(RegExp(r'\s+'));

    if (words.length > 3) {
      suggestions.add('Try using fewer keywords');
    }

    if (words.any((word) => word.length > 10)) {
      suggestions.add('Try shorter, simpler terms');
    }

    // Domain-specific suggestions
    final pmTerms = ['management', 'process', 'planning', 'risk', 'quality'];
    if (!words.any((word) => pmTerms.contains(word))) {
      suggestions.add(
        'Try adding project management terms like "process", "planning", or "management"',
      );
    }

    return suggestions;
  }

  // Retry mechanism for failed searches
  Future<bool> retryLastSearch() async {
    if (_currentQuery.isEmpty) return false;

    try {
      // Clear previous error
      _lastSearchError = null;
      setSearching(true);

      // This would typically call the search service again
      // For now, we'll simulate a retry
      await Future.delayed(const Duration(milliseconds: 500));

      setSearching(false);
      return true;
    } catch (e) {
      final error = AppError(
        type: ErrorType.processingError,
        severity: ErrorSeverity.medium,
        message: 'Search retry failed',
        details: 'Failed to retry search for "$_currentQuery": $e',
        context: 'Search retry',
      );
      setCurrentResults([], error: error);
      setSearching(false);
      return false;
    }
  }

  // Search performance monitoring
  void recordSearchPerformance(
    String query,
    Duration duration,
    int resultCount,
    bool hasErrors,
  ) {
    final performanceData = {
      'query': query,
      'duration_ms': duration.inMilliseconds,
      'result_count': resultCount,
      'has_errors': hasErrors,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // In a real implementation, this would be logged to analytics
    debugPrint('Search performance: $performanceData');
  }

  // Clear search errors
  void clearSearchError() {
    _lastSearchError = null;
    notifyListeners();
  }

  // Data persistence
  void _loadData() {
    // Load recent searches
    final recentRaw = _prefs.getString(_recentKey);
    if (recentRaw != null) {
      try {
        _recent = (json.decode(recentRaw) as List).cast<String>();
      } catch (e) {
        debugPrint('Error loading recent searches: $e');
        _recent = [];
      }
    }

    // Load suggestions
    final suggestionsRaw = _prefs.getString(_suggestionsKey);
    if (suggestionsRaw != null) {
      try {
        _suggestions = (json.decode(suggestionsRaw) as List).cast<String>();
      } catch (e) {
        debugPrint('Error loading suggestions: $e');
        _suggestions = [];
      }
    }

    // Load cached results
    final resultsRaw = _prefs.getString(_resultsKey);
    if (resultsRaw != null) {
      try {
        final data = json.decode(resultsRaw) as Map<String, dynamic>;
        _cachedResults = {};
        for (final entry in data.entries) {
          final results =
              (entry.value as List)
                  .map((r) => SearchResult.fromJson(r))
                  .toList();
          _cachedResults[entry.key] = results;
        }
      } catch (e) {
        debugPrint('Error loading cached results: $e');
        _cachedResults = {};
      }
    }

    // Migrate legacy data if needed
    _migrateLegacyData();
  }

  void _migrateLegacyData() {
    final legacyRecent = _prefs.getStringList('recent_searches');
    if (legacyRecent != null && _recent.isEmpty) {
      _recent = legacyRecent.take(_maxRecentSearches).toList();
      _saveRecentSearches();
      _prefs.remove('recent_searches');
    }
  }

  void _saveRecentSearches() {
    _prefs.setString(_recentKey, json.encode(_recent));
  }

  void _saveSuggestions() {
    _prefs.setString(_suggestionsKey, json.encode(_suggestions));
  }

  void _saveResultsCache() {
    final data = <String, dynamic>{};
    for (final entry in _cachedResults.entries) {
      data[entry.key] = entry.value.map((r) => r.toJson()).toList();
    }
    _prefs.setString(_resultsKey, json.encode(data));
  }
}
