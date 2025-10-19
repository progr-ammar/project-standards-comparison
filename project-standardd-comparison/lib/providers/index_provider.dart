import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/standards_index.dart';
import '../services/performance_monitor.dart';
import '../services/resource_manager.dart';
import 'search_provider.dart';

class IndexProvider extends ChangeNotifier {
  IndexProvider();

  final StandardsIndexService _service = StandardsIndexService();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final ResourceManager _resourceManager = ResourceManager();

  bool _ready = false;
  bool _isLoading = false;
  String _loadingStatus = '';
  final Map<String, bool> _bookLoadingStatus = {};
  final Map<String, DateTime> _lastIndexed = {};

  // Performance tracking
  final Map<String, Duration> _indexingTimes = {};
  final Map<String, int> _searchCounts = {};

  // Getters
  bool get ready => _ready;
  bool get isLoading => _isLoading;
  String get loadingStatus => _loadingStatus;
  Map<String, bool> get bookLoadingStatus =>
      Map.unmodifiable(_bookLoadingStatus);
  Map<String, DateTime> get lastIndexed => Map.unmodifiable(_lastIndexed);
  Map<String, Duration> get indexingTimes => Map.unmodifiable(_indexingTimes);

  // Initialization with progress tracking
  Future<void> init() async {
    if (_ready || _isLoading) return;

    final operationId = _performanceMonitor.startOperation(
      'Index initialization',
    );
    _isLoading = true;
    _loadingStatus = 'Initializing standards index...';
    notifyListeners();

    try {
      _performanceMonitor.updateOperationProgress(
        operationId,
        0.1,
        currentStep: 'Starting resource manager',
      );
      _resourceManager.initialize();

      _performanceMonitor.updateOperationProgress(
        operationId,
        0.3,
        currentStep: 'Loading standards service',
      );
      await _service.loadAll();

      _performanceMonitor.updateOperationProgress(
        operationId,
        0.5,
        currentStep: 'Loading PDF books',
      );

      // Actually load the PDF books for real-time search
      await _loadAllBooks();

      _performanceMonitor.updateOperationProgress(
        operationId,
        1.0,
        currentStep: 'Initialization complete',
      );
      _ready = true;
      _loadingStatus = 'Ready';
      _performanceMonitor.completeOperation(operationId);
    } catch (e) {
      _loadingStatus = 'Error: $e';
      _performanceMonitor.cancelOperation(
        operationId,
        reason: 'Initialization failed: $e',
      );
      debugPrint('IndexProvider init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAllBooks() async {
    final books = ['pmbok7', 'prince2', 'iso21502'];

    for (final bookId in books) {
      try {
        _loadingStatus = 'Loading $bookId...';
        notifyListeners();

        await _service.ensureBookLoaded(bookId);
        _lastIndexed[bookId] = DateTime.now();

        debugPrint('Successfully loaded $bookId');
      } catch (e) {
        debugPrint('Failed to load $bookId: $e');
        // Continue with other books even if one fails
      }
    }
  }

  // Enhanced book loading with progress tracking
  Future<void> ensureBookLoaded(String bookId) async {
    if (_bookLoadingStatus[bookId] == true) return;

    final operationId = _performanceMonitor.startOperation(
      'Loading book: $bookId',
      isHeavy: true,
    );
    _bookLoadingStatus[bookId] = true;
    _loadingStatus = 'Loading $bookId...';
    notifyListeners();

    try {
      _performanceMonitor.updateOperationProgress(
        operationId,
        0.2,
        currentStep: 'Validating book file',
      );

      final stopwatch = Stopwatch()..start();
      await _service.ensureBookLoaded(bookId);
      stopwatch.stop();

      _performanceMonitor.updateOperationProgress(
        operationId,
        0.8,
        currentStep: 'Indexing content',
      );

      _indexingTimes[bookId] = stopwatch.elapsed;
      _lastIndexed[bookId] = DateTime.now();
      _loadingStatus = 'Ready';

      _performanceMonitor.updateOperationProgress(
        operationId,
        1.0,
        currentStep: 'Book loaded successfully',
      );
      _performanceMonitor.completeOperation(operationId);
    } catch (e) {
      _loadingStatus = 'Error loading $bookId: $e';
      _performanceMonitor.cancelOperation(
        operationId,
        reason: 'Book loading failed: $e',
      );
      debugPrint('Error loading book $bookId: $e');
    } finally {
      _bookLoadingStatus[bookId] = false;
      notifyListeners();
    }
  }

  // Enhanced search with performance tracking
  Future<List<SearchResult>> performSearch(
    String query, {
    List<String>? bookIds,
    int maxResults = 50,
  }) async {
    if (!_ready) {
      await init();
    }

    debugPrint('🔍 Starting search for: "$query"');
    debugPrint('📚 Books loaded: ${_service.getLoadedBooks()}');

    // Check cache first
    final cacheKey =
        'search_${query}_${bookIds?.join(',') ?? 'all'}_$maxResults';
    final cachedResults = _resourceManager.getCachedData<List<SearchResult>>(
      cacheKey,
    );
    if (cachedResults != null) {
      debugPrint(
        '💾 Returning cached search results for: $query (${cachedResults.length} results)',
      );
      return cachedResults;
    }

    final operationId = _performanceMonitor.startOperation('Search: $query');
    _searchCounts[query] = (_searchCounts[query] ?? 0) + 1;

    try {
      _performanceMonitor.updateOperationProgress(
        operationId,
        0.2,
        currentStep: 'Preparing search',
      );

      final stopwatch = Stopwatch()..start();
      final results = await _service.performAdvancedSearch(
        query,
        bookIds: bookIds,
        maxResults: maxResults,
      );
      stopwatch.stop();

      _performanceMonitor.updateOperationProgress(
        operationId,
        0.9,
        currentStep: 'Caching results',
      );

      // Cache results for future use
      _resourceManager.cacheData(cacheKey, results);

      _performanceMonitor.updateOperationProgress(
        operationId,
        1.0,
        currentStep: 'Search complete',
      );
      _performanceMonitor.completeOperation(operationId);

      debugPrint(
        '✅ Search completed in ${stopwatch.elapsed.inMilliseconds}ms: ${results.length} results for "$query"',
      );

      // Log first few results for debugging
      for (int i = 0; i < math.min(3, results.length); i++) {
        final result = results[i];
        debugPrint(
          '   📄 ${result.bookId} page ${result.pageNumber}: ${result.snippet.substring(0, math.min(100, result.snippet.length))}...',
        );
      }

      return results;
    } catch (e) {
      _performanceMonitor.cancelOperation(
        operationId,
        reason: 'Search failed: $e',
      );
      debugPrint('❌ Search error for "$query": $e');
      return [];
    }
  }

  // Topic-based search with caching
  Future<Map<String, List<SearchResult>>> searchByTopic(
    String topic, {
    int contextRadius = 2,
  }) async {
    if (!_ready) {
      await init();
    }

    debugPrint('🎯 Starting topic search for: "$topic"');

    try {
      // Get the predefined topic configuration
      final topicConfig = _getPredefinedTopicConfig(topic);
      if (topicConfig != null) {
        debugPrint('📋 Found predefined topic config for: $topic');
        return await _searchPredefinedTopic(topicConfig);
      } else {
        debugPrint('🔍 Custom topic search for: $topic');
        return await _service.searchByTopic(
          topic,
          contextRadius: contextRadius,
        );
      }
    } catch (e) {
      debugPrint('❌ Topic search error for "$topic": $e');
      return {};
    }
  }

  Map<String, dynamic>? _getPredefinedTopicConfig(String topic) {
    final predefinedTopics = {
      "Governance and Roles": {
        "keywords": [
          "governance",
          "roles",
          "responsibilities",
          "authority",
          "accountability",
          "steering",
          "board",
          "sponsor",
        ],
        "synonyms": [
          "management structure",
          "organizational roles",
          "project governance",
          "leadership",
          "oversight",
        ],
        "pageMapping": {"PMBOK": 45, "PRINCE2": 25, "ISO": 30},
      },
      "Project Life Cycle / Phases": {
        "keywords": [
          "lifecycle",
          "phases",
          "stage",
          "gate",
          "milestone",
          "initiation",
          "planning",
          "execution",
          "closure",
        ],
        "synonyms": [
          "project phases",
          "stage gates",
          "project stages",
          "lifecycle management",
        ],
        "pageMapping": {"PMBOK": 25, "PRINCE2": 35, "ISO": 20},
      },
      "Planning and Scope Management": {
        "keywords": [
          "planning",
          "scope",
          "requirements",
          "deliverables",
          "work breakdown",
          "WBS",
          "scope creep",
        ],
        "synonyms": [
          "project planning",
          "scope definition",
          "requirements management",
          "deliverable management",
        ],
        "pageMapping": {"PMBOK": 140, "PRINCE2": 80, "ISO": 55},
      },
      "Risk and Uncertainty": {
        "keywords": [
          "risk",
          "uncertainty",
          "threat",
          "opportunity",
          "mitigation",
          "contingency",
          "risk register",
        ],
        "synonyms": [
          "risk management",
          "uncertainty management",
          "threat analysis",
          "opportunity management",
        ],
        "pageMapping": {"PMBOK": 250, "PRINCE2": 120, "ISO": 75},
      },
      "Quality Management": {
        "keywords": [
          "quality",
          "assurance",
          "control",
          "standards",
          "testing",
          "inspection",
          "acceptance criteria",
        ],
        "synonyms": [
          "quality assurance",
          "quality control",
          "quality planning",
          "acceptance management",
        ],
        "pageMapping": {"PMBOK": 190, "PRINCE2": 100, "ISO": 65},
      },
      "Stakeholder and Communication": {
        "keywords": [
          "stakeholder",
          "communication",
          "engagement",
          "consultation",
          "feedback",
          "reporting",
        ],
        "synonyms": [
          "stakeholder management",
          "communications management",
          "stakeholder engagement",
        ],
        "pageMapping": {"PMBOK": 180, "PRINCE2": 90, "ISO": 60},
      },
      "Change and Issue Management": {
        "keywords": [
          "change",
          "issue",
          "problem",
          "exception",
          "change control",
          "change request",
        ],
        "synonyms": [
          "change management",
          "issue resolution",
          "problem management",
          "exception handling",
        ],
        "pageMapping": {"PMBOK": 260, "PRINCE2": 140, "ISO": 85},
      },
      "Benefits / Value Realization": {
        "keywords": [
          "benefits",
          "value",
          "realization",
          "outcome",
          "business case",
          "ROI",
          "value delivery",
        ],
        "synonyms": [
          "benefit realization",
          "value management",
          "outcome delivery",
          "business value",
        ],
        "pageMapping": {"PMBOK": 65, "PRINCE2": 50, "ISO": 40},
      },
      "Tailoring and Adaptability": {
        "keywords": [
          "tailoring",
          "adaptability",
          "customization",
          "flexibility",
          "agile",
          "adaptive",
          "scaling",
        ],
        "synonyms": [
          "methodology tailoring",
          "process adaptation",
          "flexible approaches",
          "scaling methods",
        ],
        "pageMapping": {"PMBOK": 85, "PRINCE2": 60, "ISO": 45},
      },
      "Lessons Learned / Continuous Improvement": {
        "keywords": [
          "lessons learned",
          "continuous improvement",
          "retrospective",
          "knowledge management",
          "best practices",
        ],
        "synonyms": [
          "knowledge capture",
          "improvement processes",
          "learning organization",
          "experience management",
        ],
        "pageMapping": {"PMBOK": 320, "PRINCE2": 180, "ISO": 120},
      },
      "Integration and Coordination": {
        "keywords": [
          "integration",
          "coordination",
          "alignment",
          "synchronization",
          "dependencies",
          "interfaces",
        ],
        "synonyms": [
          "project integration",
          "coordination management",
          "interface management",
          "dependency management",
        ],
        "pageMapping": {"PMBOK": 105, "PRINCE2": 70, "ISO": 50},
      },
      "Procurement and Resource Management": {
        "keywords": [
          "procurement",
          "resource",
          "supplier",
          "contract",
          "vendor",
          "outsourcing",
          "human resources",
        ],
        "synonyms": [
          "resource management",
          "procurement management",
          "supplier management",
          "contract management",
        ],
        "pageMapping": {"PMBOK": 230, "PRINCE2": 130, "ISO": 78},
      },
      "Communication Management": {
        "keywords": [
          "communication",
          "reporting",
          "information",
          "documentation",
          "meetings",
          "status updates",
        ],
        "synonyms": [
          "communications management",
          "information management",
          "reporting processes",
          "meeting management",
        ],
        "pageMapping": {"PMBOK": 210, "PRINCE2": 105, "ISO": 68},
      },
      "Performance Measurement and Progress": {
        "keywords": [
          "performance",
          "measurement",
          "progress",
          "monitoring",
          "KPI",
          "metrics",
          "tracking",
        ],
        "synonyms": [
          "performance monitoring",
          "progress tracking",
          "measurement systems",
          "performance indicators",
        ],
        "pageMapping": {"PMBOK": 280, "PRINCE2": 150, "ISO": 95},
      },
      "Sustainability and Social Responsibility": {
        "keywords": [
          "sustainability",
          "social responsibility",
          "environment",
          "ethics",
          "CSR",
          "green",
          "sustainable",
        ],
        "synonyms": [
          "environmental management",
          "corporate social responsibility",
          "sustainable development",
          "ethical practices",
        ],
        "pageMapping": {"PMBOK": 75, "PRINCE2": 45, "ISO": 35},
      },
      "Schedule Management": {
        "keywords": [
          "schedule",
          "timeline",
          "duration",
          "critical path",
          "scheduling",
          "time management",
          "deadlines",
        ],
        "synonyms": [
          "time management",
          "scheduling processes",
          "timeline management",
          "duration estimation",
        ],
        "pageMapping": {"PMBOK": 160, "PRINCE2": 95, "ISO": 58},
      },
      "Cost Management": {
        "keywords": [
          "cost",
          "budget",
          "estimation",
          "financial",
          "expenditure",
          "cost control",
          "earned value",
        ],
        "synonyms": [
          "budget management",
          "financial management",
          "cost control",
          "expenditure management",
        ],
        "pageMapping": {"PMBOK": 170, "PRINCE2": 96, "ISO": 59},
      },
      "LifeCycle and Approach": {
        "keywords": [
          "lifecycle",
          "approach",
          "methodology",
          "framework",
          "process",
          "model",
          "method",
        ],
        "synonyms": [
          "project approach",
          "methodology selection",
          "process framework",
          "delivery model",
        ],
        "pageMapping": {"PMBOK": 30, "PRINCE2": 40, "ISO": 25},
      },
    };

    return predefinedTopics[topic];
  }

  Future<Map<String, List<SearchResult>>> _searchPredefinedTopic(
    Map<String, dynamic> topicConfig,
  ) async {
    final results = <String, List<SearchResult>>{};
    final pageMapping = topicConfig['pageMapping'] as Map<String, dynamic>;
    final keywords = (topicConfig['keywords'] as List).cast<String>();
    final synonyms = (topicConfig['synonyms'] as List).cast<String>();

    // Combine all search terms
    final allTerms = [...keywords, ...synonyms];
    final searchQuery = allTerms.take(5).join(' OR '); // Use top 5 terms

    debugPrint('🔍 Searching with terms: $searchQuery');

    // Search in each book around the mapped pages
    final bookMappings = {
      'pmbok7': pageMapping['PMBOK'] as int?,
      'prince2': pageMapping['PRINCE2'] as int?,
      'iso21502': pageMapping['ISO'] as int?,
    };

    for (final entry in bookMappings.entries) {
      final bookId = entry.key;
      final targetPage = entry.value;

      if (targetPage != null) {
        try {
          await _service.ensureBookLoaded(bookId);

          // Search around the target page (±5 pages)
          final bookResults = await _searchAroundPage(
            bookId,
            targetPage,
            allTerms,
          );
          if (bookResults.isNotEmpty) {
            results[bookId] = bookResults;
            debugPrint(
              '📄 Found ${bookResults.length} results in $bookId around page $targetPage',
            );
          }
        } catch (e) {
          debugPrint('❌ Error searching in $bookId: $e');
        }
      }
    }

    return results;
  }

  Future<List<SearchResult>> _searchAroundPage(
    String bookId,
    int targetPage,
    List<String> searchTerms,
  ) async {
    final results = <SearchResult>[];

    try {
      // Search with each term and combine results
      for (final term in searchTerms.take(3)) {
        // Limit to top 3 terms for performance
        final termResults = await _service.performAdvancedSearch(
          term,
          bookIds: [bookId],
          maxResults: 10,
        );

        // Filter results to those near the target page (±10 pages)
        final nearbyResults =
            termResults.where((result) {
              final pageDiff = (result.pageNumber - targetPage).abs();
              return pageDiff <= 10;
            }).toList();

        results.addAll(nearbyResults);
      }

      // Remove duplicates and sort by proximity to target page
      final uniqueResults = <SearchResult>[];
      final seenPages = <int>{};

      for (final result in results) {
        if (!seenPages.contains(result.pageNumber)) {
          seenPages.add(result.pageNumber);
          uniqueResults.add(result);
        }
      }

      // Sort by proximity to target page
      uniqueResults.sort((a, b) {
        final aDiff = (a.pageNumber - targetPage).abs();
        final bDiff = (b.pageNumber - targetPage).abs();
        return aDiff.compareTo(bDiff);
      });

      return uniqueResults.take(5).toList(); // Return top 5 most relevant
    } catch (e) {
      debugPrint('❌ Error in _searchAroundPage for $bookId: $e');
      return [];
    }
  }

  // Multi-book comparison
  Future<Map<String, dynamic>> compareAcrossBooks(
    String topic, {
    List<String>? bookIds,
  }) async {
    if (!_ready) {
      await init();
    }

    try {
      final pages = mapTopicToPages(topic);
      final texts = extractTextAroundPages(pages, radius: 2);
      final insights = computeInsights(texts);

      return {
        'topic': topic,
        'pages': pages,
        'texts': texts,
        'insights': insights,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Comparison error: $e');
      return {};
    }
  }

  // Existing methods with enhanced error handling
  List<TocEntry> getIndex(String bookId) {
    try {
      return _service.getIndexWithErrorHandling(bookId);
    } catch (e) {
      debugPrint('Error getting index for $bookId: $e');
      return [];
    }
  }

  List<String> getAllTopics() {
    try {
      return _service.getAllTopics();
    } catch (e) {
      debugPrint('Error getting all topics: $e');
      return [];
    }
  }

  Map<String, int?> mapTopicToPages(String topic) {
    try {
      return _service.mapTopicToPages(topic);
    } catch (e) {
      debugPrint('Error mapping topic to pages: $e');
      return {};
    }
  }

  Map<String, String> extractTextAroundPages(
    Map<String, int?> pages, {
    int radius = 1,
  }) {
    try {
      return _service.extractTextAroundPages(pages, radius: radius);
    } catch (e) {
      debugPrint('Error extracting text around pages: $e');
      return {};
    }
  }

  Map<String, dynamic> computeInsights(Map<String, String> bookToText) {
    try {
      return _service.computeInsights(bookToText);
    } catch (e) {
      debugPrint('Error computing insights: $e');
      return {};
    }
  }

  int? findIndexPage(String bookId) {
    try {
      return _service.findIndexPage(bookId);
    } catch (e) {
      debugPrint('Error finding index page for $bookId: $e');
      return null;
    }
  }

  int? findTocPage(String bookId) {
    try {
      return _service.findTocPage(bookId);
    } catch (e) {
      debugPrint('Error finding TOC page for $bookId: $e');
      return null;
    }
  }

  // Performance and analytics
  Map<String, int> getSearchAnalytics() {
    return Map.unmodifiable(_searchCounts);
  }

  List<String> getPopularSearches() {
    final sorted =
        _searchCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).map((e) => e.key).toList();
  }

  Duration? getIndexingTime(String bookId) {
    return _indexingTimes[bookId];
  }

  bool isBookLoaded(String bookId) {
    return _service.isBookLoaded(bookId);
  }

  // Additional methods for UI state management
  bool isBookIndexed(String bookId) {
    return _service.isBookLoaded(bookId) &&
        !(_bookLoadingStatus[bookId] ?? false);
  }

  double getBookProgress(String bookId) {
    if (_bookLoadingStatus[bookId] == true) {
      // Return a simulated progress for loading state
      return 0.5; // 50% progress when loading
    }
    return isBookIndexed(bookId) ? 1.0 : 0.0;
  }

  bool get isIndexing {
    return _isLoading || _bookLoadingStatus.values.any((loading) => loading);
  }

  // Enhanced cache management
  void clearCache() {
    _service.clearCache();
    _resourceManager.clearCache();
    _searchCounts.clear();
    notifyListeners();
  }

  void optimizeCache() {
    _service.optimizeCache();
    _resourceManager.optimizeResources();
    notifyListeners();
  }

  // Progressive indexing for better performance
  Future<void> progressivelyIndexBook(String bookId) async {
    final operationId = _performanceMonitor.startOperation(
      'Progressive indexing: $bookId',
      isHeavy: true,
    );

    try {
      await _service.progressivelyIndexBook(bookId);
      _performanceMonitor.completeOperation(operationId);
    } catch (e) {
      _performanceMonitor.cancelOperation(
        operationId,
        reason: 'Progressive indexing failed: $e',
      );
      debugPrint('Progressive indexing error for $bookId: $e');
    }
  }

  // Smart preloading based on topic usage
  void preloadFrequentTopics(List<String> topics) {
    _service.preloadFrequentlyAccessedContent(topics);
  }

  void preloadBooks(List<String> bookIds) async {
    for (final bookId in bookIds) {
      if (!isBookLoaded(bookId)) {
        unawaited(ensureBookLoaded(bookId));
      }
    }
  }

  // Status and diagnostics
  Map<String, dynamic> getStatus() {
    return {
      'ready': _ready,
      'isLoading': _isLoading,
      'loadingStatus': _loadingStatus,
      'booksLoaded': _service.getLoadedBooks(),
      'totalSearches': _searchCounts.values.fold(0, (a, b) => a + b),
      'indexingTimes': _indexingTimes.map(
        (k, v) => MapEntry(k, v.inMilliseconds),
      ),
      'lastIndexed': _lastIndexed.map(
        (k, v) => MapEntry(k, v.toIso8601String()),
      ),
      'performance': _performanceMonitor.getLatestMetrics()?.toJson(),
      'resources': _resourceManager.getHealthStatus(),
    };
  }

  // Performance and resource management
  List<OperationProgress> getActiveOperations() {
    return _performanceMonitor.getActiveOperations();
  }

  bool hasActiveOperations() {
    return _performanceMonitor.hasActiveOperations();
  }

  Map<String, dynamic> getPerformanceStats() {
    return {
      'latestMetrics': _performanceMonitor.getLatestMetrics()?.toJson(),
      'averageMemory': _performanceMonitor.getAverageMemoryUsage(),
      'peakMemory': _performanceMonitor.getPeakMemoryUsage(),
      'activeOperations': _performanceMonitor.getActiveOperationCount(),
      'cacheStats': _resourceManager.getCacheStats(),
    };
  }

  List<String> getOptimizationSuggestions() {
    return _resourceManager.getResourceOptimizationSuggestions();
  }

  void optimizeResources() {
    _resourceManager.optimizeResources();
  }

  bool isSystemHealthy() {
    return _resourceManager.isHealthy() &&
        !_performanceMonitor.hasActiveOperations();
  }

  @override
  void dispose() {
    _resourceManager.dispose();
    super.dispose();
  }
}
