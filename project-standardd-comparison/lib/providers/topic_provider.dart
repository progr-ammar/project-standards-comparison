import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/topic_manager.dart';

class TopicProvider extends ChangeNotifier {
  TopicProvider(SharedPreferences prefs) : _topicManager = TopicManager(prefs) {
    _topicManager.addListener(_onTopicManagerChanged);
  }

  final TopicManager _topicManager;
  String? _selectedTopic;
  List<String> _recentTopics = [];
  String _searchQuery = '';
  List<TopicConfiguration> _filteredTopics = [];

  // Getters
  TopicManager get topicManager => _topicManager;
  String? get selectedTopic => _selectedTopic;
  List<String> get recentTopics => List.unmodifiable(_recentTopics);
  String get searchQuery => _searchQuery;
  List<TopicConfiguration> get filteredTopics =>
      List.unmodifiable(_filteredTopics);

  bool get isLoading => _topicManager.isLoading;
  String? get lastError => _topicManager.lastError;

  // Predefined topics for UI display
  List<TopicConfiguration> get predefinedTopics =>
      _topicManager.predefinedTopics;
  List<TopicConfiguration> get customTopics => _topicManager.customTopics;
  List<TopicConfiguration> get allTopics => _topicManager.allTopics;

  // Topic selection and management
  void selectTopic(String? topicName) {
    if (_selectedTopic != topicName) {
      _selectedTopic = topicName;

      if (topicName != null) {
        _topicManager.recordTopicUsage(topicName);
        _addToRecentTopics(topicName);
      }

      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedTopic = null;
    notifyListeners();
  }

  // Search functionality
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _updateFilteredTopics();
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredTopics.clear();
    notifyListeners();
  }

  void _updateFilteredTopics() {
    if (_searchQuery.trim().isEmpty) {
      _filteredTopics.clear();
    } else {
      _filteredTopics = _topicManager.searchTopics(_searchQuery);
    }
  }

  // Recent topics management
  void _addToRecentTopics(String topicName) {
    _recentTopics.remove(topicName); // Remove if already exists
    _recentTopics.insert(0, topicName); // Add to beginning

    // Keep only last 5 recent topics
    if (_recentTopics.length > 5) {
      _recentTopics = _recentTopics.sublist(0, 5);
    }
  }

  void clearRecentTopics() {
    _recentTopics.clear();
    notifyListeners();
  }

  // Topic information getters
  TopicConfiguration? getTopicConfiguration(String topicName) {
    return _topicManager.getTopic(topicName);
  }

  List<String> getTopicKeywords(String topicName) {
    return _topicManager.getTopicKeywords(topicName);
  }

  List<String> getTopicSynonyms(String topicName) {
    return _topicManager.getTopicSynonyms(topicName);
  }

  Map<String, int> getTopicPageMapping(String topicName) {
    return _topicManager.getTopicPageMapping(topicName);
  }

  // Popular and suggested topics
  List<TopicConfiguration> getPopularTopics({int limit = 10}) {
    return _topicManager.getPopularTopics(limit: limit);
  }

  List<TopicConfiguration> getSuggestedTopics({int limit = 6}) {
    // Return a mix of popular and recent topics for suggestions
    final popular = _topicManager.getPopularTopics(limit: limit ~/ 2);
    final recent = _topicManager.getRecentlyUsedTopics(limit: limit ~/ 2);

    final suggested = <TopicConfiguration>[];
    final seen = <String>{};

    // Add popular topics first
    for (final topic in popular) {
      if (seen.add(topic.name)) {
        suggested.add(topic);
      }
    }

    // Add recent topics if not already included
    for (final topic in recent) {
      if (seen.add(topic.name) && suggested.length < limit) {
        suggested.add(topic);
      }
    }

    // Fill remaining slots with predefined topics if needed
    if (suggested.length < limit) {
      for (final topic in predefinedTopics) {
        if (seen.add(topic.name) && suggested.length < limit) {
          suggested.add(topic);
        }
      }
    }

    return suggested;
  }

  // Custom topic management
  Future<bool> createCustomTopic({
    required String name,
    required List<String> keywords,
    required List<String> synonyms,
    required String description,
    Map<String, int>? pageMapping,
  }) async {
    final success = await _topicManager.createCustomTopic(
      name: name,
      keywords: keywords,
      synonyms: synonyms,
      description: description,
      pageMapping: pageMapping,
    );

    if (success) {
      // Auto-select the newly created topic
      selectTopic(name);
    }

    return success;
  }

  Future<bool> updateCustomTopic({
    required String name,
    List<String>? keywords,
    List<String>? synonyms,
    String? description,
    Map<String, int>? pageMapping,
  }) async {
    return await _topicManager.updateCustomTopic(
      name: name,
      keywords: keywords,
      synonyms: synonyms,
      description: description,
      pageMapping: pageMapping,
    );
  }

  Future<bool> deleteCustomTopic(String name) async {
    final success = await _topicManager.deleteCustomTopic(name);

    if (success && _selectedTopic == name) {
      clearSelection();
    }

    return success;
  }

  // Topic validation
  bool isValidTopicName(String name) {
    return _topicManager.isValidTopicName(name);
  }

  String? validateTopicName(String name) {
    return _topicManager.validateTopicName(name);
  }

  // Comparison optimization
  List<String> getOptimizedSearchTerms(String topicName) {
    return _topicManager.getOptimizedSearchTerms(topicName);
  }

  Map<String, List<String>> getTopicSimilarityMap() {
    return _topicManager.getTopicSimilarityMap();
  }

  // Statistics and analytics
  Map<String, int> getUsageStats() {
    return _topicManager.getUsageStats();
  }

  Map<String, dynamic> getTopicStatistics() {
    return _topicManager.getTopicStatistics();
  }

  void clearUsageStats() {
    _topicManager.clearUsageStats();
  }

  // Export/Import
  Map<String, dynamic> exportCustomTopics() {
    return _topicManager.exportCustomTopics();
  }

  Future<bool> importCustomTopics(Map<String, dynamic> topicsData) async {
    return await _topicManager.importCustomTopics(topicsData);
  }

  // Error handling
  void clearError() {
    _topicManager.clearError();
  }

  // Reload functionality
  Future<void> reloadTopics() async {
    await _topicManager.reloadTopics();
  }

  // Topic chip display helpers
  List<TopicConfiguration> getTopicsForChipDisplay({int limit = 18}) {
    // Return predefined topics first, then popular custom topics
    final chipTopics = <TopicConfiguration>[];
    final seen = <String>{};

    // Add all predefined topics first
    for (final topic in predefinedTopics) {
      if (seen.add(topic.name) && chipTopics.length < limit) {
        chipTopics.add(topic);
      }
    }

    // Fill remaining slots with popular custom topics
    if (chipTopics.length < limit) {
      final popularCustom =
          customTopics.toList()..sort((a, b) {
            final aUsage = _topicManager.getUsageStats()[a.name] ?? 0;
            final bUsage = _topicManager.getUsageStats()[b.name] ?? 0;
            return bUsage.compareTo(aUsage);
          });

      for (final topic in popularCustom) {
        if (seen.add(topic.name) && chipTopics.length < limit) {
          chipTopics.add(topic);
        }
      }
    }

    return chipTopics;
  }

  bool isTopicSelected(String topicName) {
    return _selectedTopic == topicName;
  }

  bool hasCustomTopics() {
    return customTopics.isNotEmpty;
  }

  // Topic interaction helpers
  void onTopicChipTapped(String topicName) {
    selectTopic(topicName);
  }

  void onTopicSearched(String topicName) {
    selectTopic(topicName);
    _topicManager.recordTopicUsage(topicName);
  }

  // Performance optimization integration
  List<String> getFrequentlyUsedTopics({int limit = 10}) {
    final usageStats = _topicManager.getUsageStats();
    final sortedTopics =
        usageStats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sortedTopics.take(limit).map((e) => e.key).toList();
  }

  void optimizeForPerformance() {
    // This could trigger preloading of frequently used topics
    // The IndexProvider would use this information for smart preloading
    // Implementation would depend on integration with IndexProvider
  }

  // Listener management
  void _onTopicManagerChanged() {
    // Update filtered topics if search is active
    if (_searchQuery.isNotEmpty) {
      _updateFilteredTopics();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _topicManager.removeListener(_onTopicManagerChanged);
    super.dispose();
  }
}
