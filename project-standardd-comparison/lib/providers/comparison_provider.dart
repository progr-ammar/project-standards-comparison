import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'search_provider.dart';

class ComparisonSnippet {
  final String bookId;
  final int pageNumber;
  final String text;
  final List<String> similarities;
  final bool isSelected;
  final bool isUnique;
  final double relevanceScore;

  ComparisonSnippet({
    required this.bookId,
    required this.pageNumber,
    required this.text,
    this.similarities = const [],
    this.isSelected = false,
    this.isUnique = false,
    this.relevanceScore = 0.0,
  });

  ComparisonSnippet copyWith({
    String? bookId,
    int? pageNumber,
    String? text,
    List<String>? similarities,
    bool? isSelected,
    bool? isUnique,
    double? relevanceScore,
  }) {
    return ComparisonSnippet(
      bookId: bookId ?? this.bookId,
      pageNumber: pageNumber ?? this.pageNumber,
      text: text ?? this.text,
      similarities: similarities ?? this.similarities,
      isSelected: isSelected ?? this.isSelected,
      isUnique: isUnique ?? this.isUnique,
      relevanceScore: relevanceScore ?? this.relevanceScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'pageNumber': pageNumber,
      'text': text,
      'similarities': similarities,
      'isSelected': isSelected,
      'isUnique': isUnique,
      'relevanceScore': relevanceScore,
    };
  }

  factory ComparisonSnippet.fromJson(Map<String, dynamic> json) {
    return ComparisonSnippet(
      bookId: json['bookId'] as String,
      pageNumber: json['pageNumber'] as int,
      text: json['text'] as String,
      similarities:
          (json['similarities'] as List<dynamic>?)?.cast<String>() ?? [],
      isSelected: json['isSelected'] as bool? ?? false,
      isUnique: json['isUnique'] as bool? ?? false,
      relevanceScore: (json['relevanceScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InsightPoint {
  final String content;
  final String rationale;
  final List<String> relatedBooks;
  final double confidence;
  final String type; // 'similarity', 'difference', 'unique'

  InsightPoint({
    required this.content,
    required this.rationale,
    required this.relatedBooks,
    required this.confidence,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'rationale': rationale,
      'relatedBooks': relatedBooks,
      'confidence': confidence,
      'type': type,
    };
  }

  factory InsightPoint.fromJson(Map<String, dynamic> json) {
    return InsightPoint(
      content: json['content'] as String,
      rationale: json['rationale'] as String,
      relatedBooks: (json['relatedBooks'] as List<dynamic>).cast<String>(),
      confidence: (json['confidence'] as num).toDouble(),
      type: json['type'] as String,
    );
  }
}

class ComparisonInsights {
  final List<InsightPoint> similarities;
  final List<InsightPoint> differences;
  final List<InsightPoint> uniquePoints;
  final Map<String, double> overlapScores;

  ComparisonInsights({
    this.similarities = const [],
    this.differences = const [],
    this.uniquePoints = const [],
    this.overlapScores = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'similarities': similarities.map((s) => s.toJson()).toList(),
      'differences': differences.map((d) => d.toJson()).toList(),
      'uniquePoints': uniquePoints.map((u) => u.toJson()).toList(),
      'overlapScores': overlapScores,
    };
  }

  factory ComparisonInsights.fromJson(Map<String, dynamic> json) {
    return ComparisonInsights(
      similarities:
          (json['similarities'] as List<dynamic>?)
              ?.map((s) => InsightPoint.fromJson(s))
              .toList() ??
          [],
      differences:
          (json['differences'] as List<dynamic>?)
              ?.map((d) => InsightPoint.fromJson(d))
              .toList() ??
          [],
      uniquePoints:
          (json['uniquePoints'] as List<dynamic>?)
              ?.map((u) => InsightPoint.fromJson(u))
              .toList() ??
          [],
      overlapScores:
          (json['overlapScores'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
    );
  }
}

class Comparison {
  final String id;
  final String name;
  final String topic;
  final DateTime created;
  final List<ComparisonSnippet> snippets;
  final ComparisonInsights insights;
  final List<String> tags;

  Comparison({
    required this.id,
    required this.name,
    required this.topic,
    required this.created,
    required this.snippets,
    required this.insights,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'topic': topic,
      'created': created.toIso8601String(),
      'snippets': snippets.map((s) => s.toJson()).toList(),
      'insights': insights.toJson(),
      'tags': tags,
    };
  }

  factory Comparison.fromJson(Map<String, dynamic> json) {
    return Comparison(
      id: json['id'] as String,
      name: json['name'] as String,
      topic: json['topic'] as String,
      created: DateTime.parse(json['created'] as String),
      snippets:
          (json['snippets'] as List<dynamic>)
              .map((s) => ComparisonSnippet.fromJson(s))
              .toList(),
      insights: ComparisonInsights.fromJson(json['insights']),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

class ComparisonProvider extends ChangeNotifier {
  ComparisonProvider(this._prefs) {
    _loadData();
  }

  final SharedPreferences _prefs;
  static const String _comparisonsKey = 'saved_comparisons_v1';
  static const String _expandedInsightsKey = 'expanded_insights';

  final Map<String, Comparison> _savedComparisons = {};
  Comparison? _currentComparison;
  final Set<String> _expandedInsights = {};
  bool _isGenerating = false;
  String _generationStatus = '';

  // Getters
  Map<String, Comparison> get savedComparisons =>
      Map.unmodifiable(_savedComparisons);
  Comparison? get currentComparison => _currentComparison;
  bool get hasCurrentComparison => _currentComparison != null;
  bool get isGenerating => _isGenerating;
  String get generationStatus => _generationStatus;

  // Generate comparison
  Future<void> generateComparison({
    required String topic,
    required Map<String, String> bookTexts,
    String? customName,
  }) async {
    _isGenerating = true;
    _generationStatus = 'Analyzing content across standards...';
    notifyListeners();

    try {
      // Simulate processing time for demo
      await Future.delayed(const Duration(milliseconds: 500));

      _generationStatus = 'Identifying similarities and differences...';
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));

      // Create comparison snippets from the provided texts
      final snippets = <ComparisonSnippet>[];

      for (final entry in bookTexts.entries) {
        if (entry.value.isNotEmpty) {
          snippets.add(
            ComparisonSnippet(
              bookId: entry.key,
              pageNumber: _getEstimatedPageNumber(entry.key, topic),
              text: entry.value,
              similarities: _findSimilarities(entry.value, bookTexts),
              isUnique: _isUniqueContent(entry.value, bookTexts, entry.key),
              relevanceScore: _calculateRelevanceScore(entry.value, topic),
            ),
          );
        }
      }

      _generationStatus = 'Generating insights...';
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 300));

      // Generate insights
      final insights = _generateInsights(snippets, topic);

      // Create comparison
      _currentComparison = Comparison(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: customName ?? 'Comparison: $topic',
        topic: topic,
        created: DateTime.now(),
        snippets: snippets,
        insights: insights,
      );

      _generationStatus = 'Comparison complete!';
    } catch (e) {
      _generationStatus = 'Error generating comparison: $e';
      debugPrint('Comparison generation error: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  int _getEstimatedPageNumber(String bookId, String topic) {
    // Simulate page mapping based on topic
    final topicPageMap = {
      'pmbok7': {
        'Risk Management': 125,
        'Governance & Roles': 45,
        'Quality Management': 89,
        'Stakeholder Management': 156,
        'Planning and Scope Management': 67,
      },
      'prince2': {
        'Risk Management': 78,
        'Governance & Roles': 23,
        'Quality Management': 134,
        'Stakeholder Management': 98,
        'Planning and Scope Management': 45,
      },
      'iso21502': {
        'Risk Management': 34,
        'Governance & Roles': 12,
        'Quality Management': 67,
        'Stakeholder Management': 89,
        'Planning and Scope Management': 23,
      },
    };

    return topicPageMap[bookId]?[topic] ?? 1;
  }

  List<String> _findSimilarities(String text, Map<String, String> allTexts) {
    final similarities = <String>[];
    final words = text.toLowerCase().split(' ');

    for (final entry in allTexts.entries) {
      if (entry.value != text) {
        final otherWords = entry.value.toLowerCase().split(' ');
        final commonWords =
            words
                .where((word) => word.length > 4 && otherWords.contains(word))
                .toList();

        if (commonWords.length > 3) {
          similarities.addAll(commonWords.take(3));
        }
      }
    }

    return similarities.toSet().toList();
  }

  bool _isUniqueContent(
    String text,
    Map<String, String> allTexts,
    String currentBookId,
  ) {
    final currentWords =
        text.toLowerCase().split(' ').where((w) => w.length > 4).toSet();

    for (final entry in allTexts.entries) {
      if (entry.key != currentBookId) {
        final otherWords =
            entry.value
                .toLowerCase()
                .split(' ')
                .where((w) => w.length > 4)
                .toSet();
        final overlap = currentWords.intersection(otherWords);
        if (overlap.length > currentWords.length * 0.3) {
          return false;
        }
      }
    }

    return true;
  }

  double _calculateRelevanceScore(String text, String topic) {
    final topicWords = topic.toLowerCase().split(' ');
    final textWords = text.toLowerCase().split(' ');

    int matches = 0;
    for (final topicWord in topicWords) {
      if (textWords.any(
        (word) => word.contains(topicWord) || topicWord.contains(word),
      )) {
        matches++;
      }
    }

    return matches / topicWords.length;
  }

  ComparisonInsights _generateInsights(
    List<ComparisonSnippet> snippets,
    String topic,
  ) {
    final similarities = <InsightPoint>[];
    final differences = <InsightPoint>[];
    final uniquePoints = <InsightPoint>[];
    final overlapScores = <String, double>{};

    // Generate similarities
    if (snippets.length >= 2) {
      similarities.add(
        InsightPoint(
          content:
              'All standards emphasize the importance of $topic in project success',
          rationale: 'Common terminology and concepts found across standards',
          relatedBooks: snippets.map((s) => s.bookId).toList(),
          confidence: 0.85,
          type: 'similarity',
        ),
      );
    }

    // Generate differences
    for (final snippet in snippets) {
      if (snippet.isUnique) {
        differences.add(
          InsightPoint(
            content:
                '${_getBookDisplayName(snippet.bookId)} provides unique perspective on $topic',
            rationale: 'Distinct approach not found in other standards',
            relatedBooks: [snippet.bookId],
            confidence: 0.75,
            type: 'difference',
          ),
        );
      }
    }

    // Generate unique points
    for (final snippet in snippets.where((s) => s.isUnique)) {
      uniquePoints.add(
        InsightPoint(
          content:
              'Specialized ${_getBookDisplayName(snippet.bookId)} approach to $topic',
          rationale: 'Framework-specific methodology',
          relatedBooks: [snippet.bookId],
          confidence: 0.80,
          type: 'unique',
        ),
      );
    }

    // Calculate overlap scores
    for (final snippet in snippets) {
      overlapScores[_getBookDisplayName(snippet.bookId)] =
          snippet.relevanceScore;
    }

    return ComparisonInsights(
      similarities: similarities,
      differences: differences,
      uniquePoints: uniquePoints,
      overlapScores: overlapScores,
    );
  }

  String _getBookDisplayName(String bookId) {
    switch (bookId) {
      case 'pmbok7':
        return 'PMBOK 7';
      case 'prince2':
        return 'PRINCE2';
      case 'iso21502':
        return 'ISO 21502';
      default:
        return bookId.toUpperCase();
    }
  }

  // Insight expansion management
  bool isInsightExpanded(String insightId) {
    return _expandedInsights.contains(insightId);
  }

  void toggleInsightExpansion(String insightId) {
    if (_expandedInsights.contains(insightId)) {
      _expandedInsights.remove(insightId);
    } else {
      _expandedInsights.add(insightId);
    }
    _saveExpandedInsights();
    notifyListeners();
  }

  // Comparison management
  void clearCurrentComparison() {
    _currentComparison = null;
    _expandedInsights.clear();
    notifyListeners();
  }

  void updateCurrentComparison({String? name, List<String>? tags}) {
    if (_currentComparison != null) {
      _currentComparison = Comparison(
        id: _currentComparison!.id,
        name: name ?? _currentComparison!.name,
        topic: _currentComparison!.topic,
        created: _currentComparison!.created,
        snippets: _currentComparison!.snippets,
        insights: _currentComparison!.insights,
        tags: tags ?? _currentComparison!.tags,
      );
      notifyListeners();
    }
  }

  void saveCurrentComparison() {
    if (_currentComparison != null) {
      _savedComparisons[_currentComparison!.id] = _currentComparison!;
      _saveComparisons();
      notifyListeners();
    }
  }

  void deleteComparison(String id) {
    _savedComparisons.remove(id);
    _saveComparisons();
    notifyListeners();
  }

  // Data persistence
  void _loadData() {
    // Load saved comparisons
    final comparisonsRaw = _prefs.getString(_comparisonsKey);
    if (comparisonsRaw != null) {
      try {
        final data = json.decode(comparisonsRaw) as Map<String, dynamic>;
        for (final entry in data.entries) {
          _savedComparisons[entry.key] = Comparison.fromJson(entry.value);
        }
      } catch (e) {
        debugPrint('Error loading comparisons: $e');
      }
    }

    // Load expanded insights
    final expandedRaw = _prefs.getStringList(_expandedInsightsKey);
    if (expandedRaw != null) {
      _expandedInsights.addAll(expandedRaw);
    }
  }

  void _saveComparisons() {
    final data = <String, dynamic>{};
    for (final entry in _savedComparisons.entries) {
      data[entry.key] = entry.value.toJson();
    }
    _prefs.setString(_comparisonsKey, json.encode(data));
  }

  void _saveExpandedInsights() {
    _prefs.setStringList(_expandedInsightsKey, _expandedInsights.toList());
  }
}
