import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class TopicConfiguration {
  final String name;
  final List<String> keywords;
  final List<String> synonyms;
  final String description;
  final Map<String, int> pageMapping;
  final bool isCustom;
  final DateTime? createdAt;

  TopicConfiguration({
    required this.name,
    required this.keywords,
    required this.synonyms,
    required this.description,
    required this.pageMapping,
    this.isCustom = false,
    this.createdAt,
  });

  factory TopicConfiguration.fromJson(String name, Map<String, dynamic> json) {
    return TopicConfiguration(
      name: name,
      keywords: (json['keywords'] as List<dynamic>?)?.cast<String>() ?? [],
      synonyms: (json['synonyms'] as List<dynamic>?)?.cast<String>() ?? [],
      description: json['description'] as String? ?? '',
      pageMapping:
          (json['pageMapping'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
      isCustom: json['isCustom'] as bool? ?? false,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keywords': keywords,
      'synonyms': synonyms,
      'description': description,
      'pageMapping': pageMapping,
      'isCustom': isCustom,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  List<String> getAllSearchTerms() {
    return [...keywords, ...synonyms, name];
  }

  bool matchesQuery(String query) {
    final queryLower = query.toLowerCase();
    return getAllSearchTerms().any(
      (term) => term.toLowerCase().contains(queryLower),
    );
  }
}

class TopicManager extends ChangeNotifier {
  TopicManager(this._prefs) {
    _loadTopics();
  }

  final SharedPreferences _prefs;
  static const String _customTopicsKey = 'custom_topics_v1';
  static const String _topicUsageKey = 'topic_usage_stats';

  Map<String, TopicConfiguration> _predefinedTopics = {};
  Map<String, TopicConfiguration> _customTopics = {};
  Map<String, int> _topicUsageStats = {};
  bool _isLoading = false;
  String? _lastError;

  // Getters
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  List<TopicConfiguration> get predefinedTopics =>
      _predefinedTopics.values.toList();

  List<TopicConfiguration> get customTopics => _customTopics.values.toList();

  List<TopicConfiguration> get allTopics => [
    ..._predefinedTopics.values,
    ..._customTopics.values,
  ];

  List<String> get predefinedTopicNames => _predefinedTopics.keys.toList();

  List<String> get allTopicNames => [
    ..._predefinedTopics.keys,
    ..._customTopics.keys,
  ];

  // Topic retrieval
  TopicConfiguration? getTopic(String name) {
    return _predefinedTopics[name] ?? _customTopics[name];
  }

  List<String> getTopicKeywords(String topicName) {
    final topic = getTopic(topicName);
    return topic?.keywords ?? [];
  }

  List<String> getTopicSynonyms(String topicName) {
    final topic = getTopic(topicName);
    return topic?.synonyms ?? [];
  }

  List<String> getAllSearchTerms(String topicName) {
    final topic = getTopic(topicName);
    return topic?.getAllSearchTerms() ?? [];
  }

  Map<String, int> getTopicPageMapping(String topicName) {
    final topic = getTopic(topicName);
    return topic?.pageMapping ?? {};
  }

  // Topic search and filtering
  List<TopicConfiguration> searchTopics(String query) {
    if (query.trim().isEmpty) return allTopics;

    return allTopics.where((topic) => topic.matchesQuery(query)).toList()
      ..sort((a, b) {
        // Sort by relevance: exact name match first, then keyword matches
        final aNameMatch = a.name.toLowerCase().contains(query.toLowerCase());
        final bNameMatch = b.name.toLowerCase().contains(query.toLowerCase());

        if (aNameMatch && !bNameMatch) return -1;
        if (!aNameMatch && bNameMatch) return 1;

        // Then by usage frequency
        final aUsage = _topicUsageStats[a.name] ?? 0;
        final bUsage = _topicUsageStats[b.name] ?? 0;
        return bUsage.compareTo(aUsage);
      });
  }

  List<TopicConfiguration> getPopularTopics({int limit = 10}) {
    final topics =
        allTopics.toList()..sort((a, b) {
          final aUsage = _topicUsageStats[a.name] ?? 0;
          final bUsage = _topicUsageStats[b.name] ?? 0;
          return bUsage.compareTo(aUsage);
        });

    return topics.take(limit).toList();
  }

  List<TopicConfiguration> getRecentlyUsedTopics({int limit = 5}) {
    // For now, return popular topics as a proxy for recently used
    // In a full implementation, we'd track usage timestamps
    return getPopularTopics(limit: limit);
  }

  // Custom topic management
  Future<bool> createCustomTopic({
    required String name,
    required List<String> keywords,
    required List<String> synonyms,
    required String description,
    Map<String, int>? pageMapping,
  }) async {
    try {
      // Validate topic name
      if (name.trim().isEmpty) {
        _lastError = 'Topic name cannot be empty';
        notifyListeners();
        return false;
      }

      // Check for duplicates
      if (_predefinedTopics.containsKey(name) ||
          _customTopics.containsKey(name)) {
        _lastError = 'Topic with name "$name" already exists';
        notifyListeners();
        return false;
      }

      final topic = TopicConfiguration(
        name: name,
        keywords: keywords,
        synonyms: synonyms,
        description: description,
        pageMapping: pageMapping ?? {},
        isCustom: true,
        createdAt: DateTime.now(),
      );

      _customTopics[name] = topic;
      await _saveCustomTopics();

      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to create custom topic: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCustomTopic({
    required String name,
    List<String>? keywords,
    List<String>? synonyms,
    String? description,
    Map<String, int>? pageMapping,
  }) async {
    try {
      final existingTopic = _customTopics[name];
      if (existingTopic == null) {
        _lastError = 'Custom topic "$name" not found';
        notifyListeners();
        return false;
      }

      final updatedTopic = TopicConfiguration(
        name: name,
        keywords: keywords ?? existingTopic.keywords,
        synonyms: synonyms ?? existingTopic.synonyms,
        description: description ?? existingTopic.description,
        pageMapping: pageMapping ?? existingTopic.pageMapping,
        isCustom: true,
        createdAt: existingTopic.createdAt,
      );

      _customTopics[name] = updatedTopic;
      await _saveCustomTopics();

      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to update custom topic: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCustomTopic(String name) async {
    try {
      if (!_customTopics.containsKey(name)) {
        _lastError = 'Custom topic "$name" not found';
        notifyListeners();
        return false;
      }

      _customTopics.remove(name);
      _topicUsageStats.remove(name);
      await _saveCustomTopics();
      await _saveUsageStats();

      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to delete custom topic: $e';
      notifyListeners();
      return false;
    }
  }

  // Usage tracking
  void recordTopicUsage(String topicName) {
    _topicUsageStats[topicName] = (_topicUsageStats[topicName] ?? 0) + 1;
    _saveUsageStats();
    notifyListeners();
  }

  Map<String, int> getUsageStats() {
    return Map.unmodifiable(_topicUsageStats);
  }

  void clearUsageStats() {
    _topicUsageStats.clear();
    _saveUsageStats();
    notifyListeners();
  }

  // Topic comparison optimization
  List<String> getOptimizedSearchTerms(String topicName) {
    final topic = getTopic(topicName);
    if (topic == null) return [];

    // Prioritize keywords over synonyms for better search performance
    final prioritized = <String>[];
    prioritized.addAll(topic.keywords);
    prioritized.add(topic.name);
    prioritized.addAll(topic.synonyms);

    return prioritized.take(10).toList(); // Limit for performance
  }

  Map<String, List<String>> getTopicSimilarityMap() {
    final similarityMap = <String, List<String>>{};

    for (final topic in allTopics) {
      final similar = <String>[];
      final topicTerms =
          topic.getAllSearchTerms().map((t) => t.toLowerCase()).toSet();

      for (final otherTopic in allTopics) {
        if (topic.name == otherTopic.name) continue;

        final otherTerms =
            otherTopic.getAllSearchTerms().map((t) => t.toLowerCase()).toSet();
        final intersection = topicTerms.intersection(otherTerms);

        // If topics share significant terms, consider them similar
        if (intersection.length >= 2) {
          similar.add(otherTopic.name);
        }
      }

      similarityMap[topic.name] = similar;
    }

    return similarityMap;
  }

  // Data loading and persistence
  Future<void> _loadTopics() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load predefined topics
      await _loadPredefinedTopics();

      // Load custom topics
      await _loadCustomTopics();

      // Load usage stats
      await _loadUsageStats();

      _lastError = null;
    } catch (e) {
      _lastError = 'Failed to load topics: $e';
      debugPrint('Error loading topics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPredefinedTopics() async {
    try {
      final topicsJson = await rootBundle.loadString('assets/topics.json');
      final topicsData = json.decode(topicsJson) as Map<String, dynamic>;

      _predefinedTopics.clear();
      for (final entry in topicsData.entries) {
        final topic = TopicConfiguration.fromJson(entry.key, entry.value);
        _predefinedTopics[entry.key] = topic;
      }
    } catch (e) {
      debugPrint('Error loading predefined topics: $e');
      throw Exception('Failed to load predefined topics: $e');
    }
  }

  Future<void> _loadCustomTopics() async {
    try {
      final customTopicsJson = _prefs.getString(_customTopicsKey);
      if (customTopicsJson != null) {
        final customTopicsData =
            json.decode(customTopicsJson) as Map<String, dynamic>;

        _customTopics.clear();
        for (final entry in customTopicsData.entries) {
          final topic = TopicConfiguration.fromJson(entry.key, entry.value);
          _customTopics[entry.key] = topic;
        }
      }
    } catch (e) {
      debugPrint('Error loading custom topics: $e');
      // Don't throw here, custom topics are optional
    }
  }

  Future<void> _loadUsageStats() async {
    try {
      final usageStatsJson = _prefs.getString(_topicUsageKey);
      if (usageStatsJson != null) {
        final usageData = json.decode(usageStatsJson) as Map<String, dynamic>;
        _topicUsageStats = usageData.map((k, v) => MapEntry(k, v as int));
      }
    } catch (e) {
      debugPrint('Error loading usage stats: $e');
      // Don't throw here, usage stats are optional
    }
  }

  Future<void> _saveCustomTopics() async {
    try {
      final customTopicsData = <String, dynamic>{};
      for (final entry in _customTopics.entries) {
        customTopicsData[entry.key] = entry.value.toJson();
      }
      await _prefs.setString(_customTopicsKey, json.encode(customTopicsData));
    } catch (e) {
      debugPrint('Error saving custom topics: $e');
    }
  }

  Future<void> _saveUsageStats() async {
    try {
      await _prefs.setString(_topicUsageKey, json.encode(_topicUsageStats));
    } catch (e) {
      debugPrint('Error saving usage stats: $e');
    }
  }

  // Reload topics (useful for testing or manual refresh)
  Future<void> reloadTopics() async {
    await _loadTopics();
  }

  // Export/Import functionality for custom topics
  Map<String, dynamic> exportCustomTopics() {
    return _customTopics.map((k, v) => MapEntry(k, v.toJson()));
  }

  Future<bool> importCustomTopics(Map<String, dynamic> topicsData) async {
    try {
      final importedTopics = <String, TopicConfiguration>{};

      for (final entry in topicsData.entries) {
        final topic = TopicConfiguration.fromJson(entry.key, entry.value);
        importedTopics[entry.key] = topic;
      }

      // Merge with existing custom topics
      _customTopics.addAll(importedTopics);
      await _saveCustomTopics();

      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to import custom topics: $e';
      notifyListeners();
      return false;
    }
  }

  // Validation helpers
  bool isValidTopicName(String name) {
    final trimmed = name.trim();
    return trimmed.isNotEmpty &&
        trimmed.length <= 100 &&
        !_predefinedTopics.containsKey(trimmed) &&
        !_customTopics.containsKey(trimmed);
  }

  String? validateTopicName(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return 'Topic name cannot be empty';
    }

    if (trimmed.length > 100) {
      return 'Topic name must be 100 characters or less';
    }

    if (_predefinedTopics.containsKey(trimmed)) {
      return 'A predefined topic with this name already exists';
    }

    if (_customTopics.containsKey(trimmed)) {
      return 'A custom topic with this name already exists';
    }

    return null;
  }

  // Clear error state
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  // Get topic statistics
  Map<String, dynamic> getTopicStatistics() {
    return {
      'predefinedCount': _predefinedTopics.length,
      'customCount': _customTopics.length,
      'totalUsage': _topicUsageStats.values.fold(0, (a, b) => a + b),
      'mostUsedTopic':
          _topicUsageStats.entries.fold<MapEntry<String, int>?>(null, (
            prev,
            curr,
          ) {
            return prev == null || curr.value > prev.value ? curr : prev;
          })?.key,
      'averageKeywordsPerTopic':
          allTopics.isEmpty
              ? 0
              : allTopics
                      .map((t) => t.keywords.length)
                      .reduce((a, b) => a + b) /
                  allTopics.length,
    };
  }
}
