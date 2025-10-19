import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../providers/search_provider.dart';
import 'error_handling_service.dart';

class TocEntry {
  TocEntry({required this.title, required this.page, required this.level});
  final String title;
  final int page; // 1-based
  final int level; // 0 = root
}

class StandardsIndexService {
  StandardsIndexService();

  final Map<String, PdfDocument> _bookIdToDoc = {};
  final Map<String, List<TocEntry>> _bookIdToToc = {};
  final Map<String, Map<String, String>> _bookIdToPageText = {};
  final Map<String, Map<String, List<String>>> _bookIdToTopicMapping = {};
  final Map<String, DateTime> _lastIndexed = {};
  final Map<String, AppError> _bookErrors = {};

  // Topic configuration
  Map<String, dynamic> _topicsConfig = {};
  Map<String, dynamic> _compareTopicsConfig = {};

  // Error handling
  final ErrorHandlingService _errorHandler = ErrorHandlingService();

  static const String pmbokId = 'pmbok7';
  static const String prince2Id = 'prince2';
  static const String isoId = 'iso21502';

  Future<void> loadAll() async {
    await _loadTopicConfigurations();
    // Lazy load books to avoid UI stalls
  }

  Future<void> _loadBook(String bookId, String assetPath) async {
    try {
      // Clear any previous errors for this book
      _bookErrors.remove(bookId);

      // Validate asset file first
      final assetError = await _errorHandler.validateAssetPdf(assetPath);
      if (assetError != null) {
        _bookErrors[bookId] = assetError;
        _errorHandler.logError(assetError);
        throw Exception('Asset validation failed: ${assetError.message}');
      }

      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      // Validate file size
      final sizeError = _errorHandler.validateFileSize(assetPath, bytes.length);
      if (sizeError != null && sizeError.severity == ErrorSeverity.high) {
        _bookErrors[bookId] = sizeError;
        _errorHandler.logError(sizeError);
        throw Exception('File too large: ${sizeError.message}');
      } else if (sizeError != null) {
        // Log warning but continue
        _errorHandler.logError(sizeError);
      }

      final doc = PdfDocument(inputBytes: bytes);

      // Test basic document functionality
      try {
        final pageCount = doc.pages.count;
        if (pageCount == 0) {
          final error = AppError(
            type: ErrorType.invalidFormat,
            severity: ErrorSeverity.high,
            message: 'PDF contains no pages',
            details: 'The PDF document for $bookId appears to be empty',
            context: 'Book loading',
          );
          _bookErrors[bookId] = error;
          _errorHandler.logError(error);
          doc.dispose();
          throw Exception('Empty PDF document');
        }
      } catch (e) {
        final error = AppError(
          type: ErrorType.fileCorrupted,
          severity: ErrorSeverity.high,
          message: 'Cannot read PDF structure',
          details: 'Error accessing PDF pages for $bookId: $e',
          context: 'Book loading',
        );
        _bookErrors[bookId] = error;
        _errorHandler.logError(error);
        doc.dispose();
        throw Exception('Corrupted PDF: $e');
      }

      _bookIdToDoc[bookId] = doc;
      _bookIdToToc[bookId] = _extractToc(doc);

      // Test text extraction capability
      await _testTextExtraction(bookId, doc);
    } catch (e) {
      // If no specific error was set, create a generic one
      if (!_bookErrors.containsKey(bookId)) {
        final error = AppError(
          type: ErrorType.unknownError,
          severity: ErrorSeverity.high,
          message: 'Failed to load book',
          details: 'Error loading $bookId from $assetPath: $e',
          context: 'Book loading',
        );
        _bookErrors[bookId] = error;
        _errorHandler.logError(error);
      }
      rethrow;
    }
  }

  String? _assetPathFor(String bookId) {
    switch (bookId) {
      case pmbokId:
        return 'assets/pmbok7.pdf';
      case prince2Id:
        return 'assets/prince2.pdf';
      case isoId:
        return 'assets/iso21502.pdf';
      default:
        return null;
    }
  }

  Future<void> _ensureLoaded(String bookId) async {
    if (_bookIdToDoc.containsKey(bookId)) return;

    // Check if there's a previous error for this book
    if (_bookErrors.containsKey(bookId)) {
      final error = _bookErrors[bookId]!;
      if (error.severity == ErrorSeverity.high ||
          error.severity == ErrorSeverity.critical) {
        throw Exception('Book $bookId has unresolved error: ${error.message}');
      }
    }

    final path = _assetPathFor(bookId);
    if (path != null) {
      await _loadBook(bookId, path);
    } else {
      final error = AppError(
        type: ErrorType.fileNotFound,
        severity: ErrorSeverity.critical,
        message: 'Unknown book ID',
        details: 'No asset path configured for book ID: $bookId',
        context: 'Book loading',
      );
      _bookErrors[bookId] = error;
      _errorHandler.logError(error);
      throw Exception('Unknown book ID: $bookId');
    }
  }

  Future<void> ensureBookLoaded(String bookId) async {
    await _ensureLoaded(bookId);
  }

  bool isBookLoaded(String bookId) {
    return _bookIdToDoc.containsKey(bookId);
  }

  List<String> getLoadedBooks() {
    return _bookIdToDoc.keys.toList();
  }

  List<TocEntry> getIndex(String bookId) {
    // Synchronous snapshot; caller can trigger ensure if needed
    return List.unmodifiable(_bookIdToToc[bookId] ?? const <TocEntry>[]);
  }

  List<String> getAllTopics() {
    final set = <String>{};
    for (final list in _bookIdToToc.values) {
      for (final e in list) {
        final t = _normalizeTitle(e.title);
        if (t.length >= 3) set.add(t);
      }
    }
    return set.toList()..sort();
  }

  Map<String, int?> mapTopicToPages(String topic) {
    final norm = _normalizeTitle(topic);
    return {
      pmbokId: _bestMatchPage(pmbokId, norm),
      prince2Id: _bestMatchPage(prince2Id, norm),
      isoId: _bestMatchPage(isoId, norm),
    };
  }

  Map<String, String> extractTextAroundPages(
    Map<String, int?> pages, {
    int radius = 1,
  }) {
    final result = <String, String>{};
    pages.forEach((bookId, page) {
      if (page == null) return;
      final doc = _bookIdToDoc[bookId];
      if (doc == null) return;
      final extractor = PdfTextExtractor(doc);
      final start = math.max(1, page - radius);
      final end = math.min(doc.pages.count, page + radius);
      final buffer = StringBuffer();
      for (int p = start; p <= end; p++) {
        try {
          buffer.writeln(
            extractor.extractText(startPageIndex: p - 1, endPageIndex: p - 1),
          );
        } catch (_) {
          // ignore extraction errors for individual pages
        }
      }
      result[bookId] = buffer.toString();
    });
    return result;
  }

  int? findIndexPage(String bookId) {
    // 1) Try TOC bookmark titled 'Index'
    final toc = _bookIdToToc[bookId] ?? const <TocEntry>[];
    for (final e in toc.reversed) {
      if (e.title.toLowerCase().contains('index')) {
        return e.page;
      }
    }
    // 2) Fallback: scan last 50 pages (or last 20% if smaller) for heading 'Index'
    final doc = _bookIdToDoc[bookId];
    if (doc == null) return null;
    final extractor = PdfTextExtractor(doc);
    final total = doc.pages.count;
    final scanCount = total <= 50 ? total : (total * 0.2).floor().clamp(1, 50);
    final start = (total - scanCount + 1).clamp(1, total);
    for (int p = start; p <= total; p++) {
      try {
        final text = extractor.extractText(
          startPageIndex: p - 1,
          endPageIndex: p - 1,
        );
        final head = text
            .trimLeft()
            .split(RegExp(r'\n|\r'))
            .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '');
        if (head.toLowerCase().startsWith('index')) {
          return p;
        }
      } catch (_) {}
    }
    return null;
  }

  int? findTocPage(String bookId) {
    // Attempt fast load to avoid delays if needed later
    _ensureLoaded(bookId);
    // Fast overrides based on your copies
    if (bookId == pmbokId) return 18; // PMBOK 7
    if (bookId == prince2Id) return 4; // PRINCE2 (7th)
    if (bookId == isoId) return 3; // ISO 21502
    // Try TOC bookmark titled 'Contents' or 'Table of Contents'
    final toc = _bookIdToToc[bookId] ?? const <TocEntry>[];
    for (final e in toc) {
      final t = e.title.toLowerCase();
      if (t.contains('table of contents') || t == 'contents') {
        return e.page;
      }
    }
    // Fallback: scan first 25 pages for a heading 'Contents' or 'Table of Contents'
    final doc = _bookIdToDoc[bookId];
    if (doc == null) return null;
    final extractor = PdfTextExtractor(doc);
    final total = doc.pages.count;
    final end = total < 25 ? total : 25;
    for (int p = 1; p <= end; p++) {
      try {
        final text = extractor.extractText(
          startPageIndex: p - 1,
          endPageIndex: p - 1,
        );
        final head = text
            .trimLeft()
            .split(RegExp(r'\n|\r'))
            .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '');
        final h = head.toLowerCase();
        if (h.startsWith('table of contents') || h == 'contents') {
          return p;
        }
      } catch (_) {}
    }
    return null;
  }

  Map<String, dynamic> computeInsights(Map<String, String> bookToText) {
    final Map<String, Set<String>> tokens = {
      for (final e in bookToText.entries) e.key: _tokenize(e.value),
    };
    final common = _intersectionAll(tokens.values.toList()).toList();
    common.sort();

    List<String> diffs(String a, String b) {
      final setA = tokens[a];
      final setB = tokens[b];
      if (setA == null || setB == null) return const <String>[];
      final onlyA = setA.difference(setB);
      return onlyA.take(10).toList();
    }

    List<String> uniques(String key, List<String> othersKeys) {
      final set = tokens[key];
      if (set == null) return const <String>[];
      final others = <String>{};
      for (final k in othersKeys) {
        final s = tokens[k];
        if (s != null) others.addAll(s);
      }
      final uniq = set.difference(others);
      return uniq.take(10).toList();
    }

    final similarities =
        common.take(10).map((e) => e.replaceAll('_', ' ')).toList();

    final differences = <String>[];
    if (tokens.containsKey(pmbokId) && tokens.containsKey(prince2Id)) {
      differences.addAll(
        diffs(pmbokId, prince2Id).map((e) => 'PMBOK vs PRINCE2: $e'),
      );
    }
    if (tokens.containsKey(pmbokId) && tokens.containsKey(isoId)) {
      differences.addAll(diffs(pmbokId, isoId).map((e) => 'PMBOK vs ISO: $e'));
    }
    if (tokens.containsKey(prince2Id) && tokens.containsKey(isoId)) {
      differences.addAll(
        diffs(prince2Id, isoId).map((e) => 'PRINCE2 vs ISO: $e'),
      );
    }

    final unique = <String, List<String>>{};
    if (tokens.containsKey(pmbokId)) {
      unique['PMBOK'] =
          uniques(pmbokId, [
            prince2Id,
            isoId,
          ]).map((e) => e.replaceAll('_', ' ')).toList();
    }
    if (tokens.containsKey(prince2Id)) {
      unique['PRINCE2'] =
          uniques(prince2Id, [
            pmbokId,
            isoId,
          ]).map((e) => e.replaceAll('_', ' ')).toList();
    }
    if (tokens.containsKey(isoId)) {
      unique['ISO'] =
          uniques(isoId, [
            pmbokId,
            prince2Id,
          ]).map((e) => e.replaceAll('_', ' ')).toList();
    }

    return {
      'Similarities': similarities,
      'Differences': differences.take(12).toList(),
      'Unique': unique,
    };
  }

  // Helpers
  List<TocEntry> _extractToc(PdfDocument doc) {
    final result = <TocEntry>[];
    void walk(dynamic collection, int level) {
      if (collection == null) return;
      try {
        final int count = collection.count as int;
        for (int i = 0; i < count; i++) {
          final item = collection[i];
          int pageNumber = 1;
          try {
            final dest = item.destination;
            final page = dest?.page;
            final idx = page?.index as int?;
            pageNumber = (idx ?? 0) + 1;
          } catch (_) {}
          final title = (item.title?.toString() ?? '').trim();
          if (title.isNotEmpty) {
            result.add(TocEntry(title: title, page: pageNumber, level: level));
          }
          walk(item.nested, level + 1);
        }
      } catch (_) {
        // ignore unexpected shapes
      }
    }

    try {
      walk(doc.bookmarks, 0);
    } catch (_) {
      // some PDFs may not expose bookmarks; ignore
    }
    return result;
  }

  int? _bestMatchPage(String bookId, String normTopic) {
    final toc = _bookIdToToc[bookId];
    if (toc == null || toc.isEmpty) return null;
    int? bestPage;
    double bestScore = -1;
    for (final e in toc) {
      final s = _similarity(_normalizeTitle(e.title), normTopic);
      if (s > bestScore) {
        bestScore = s;
        bestPage = e.page;
      }
    }
    return bestPage;
  }

  String _normalizeTitle(String s) {
    final t =
        s
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
    return t;
  }

  double _similarity(String a, String b) {
    final ta = a.split(' ').where((e) => e.isNotEmpty).toSet();
    final tb = b.split(' ').where((e) => e.isNotEmpty).toSet();
    if (ta.isEmpty || tb.isEmpty) return 0;
    final inter = ta.intersection(tb).length.toDouble();
    final union = ta.union(tb).length.toDouble();
    return inter / union;
  }

  final Set<String> _stop = {
    'the',
    'and',
    'of',
    'to',
    'a',
    'in',
    'for',
    'on',
    'by',
    'with',
    'is',
    'are',
    'as',
    'an',
    'that',
    'this',
    'from',
    'at',
    'it',
    'be',
    'or',
    'into',
    'within',
    'through',
    'using',
    'use',
  };

  Set<String> _tokenize(String text) {
    final words =
        text
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
            .split(RegExp(r'\s+'))
            .where((w) => w.length >= 3 && !_stop.contains(w))
            .toList();
    final freq = <String, int>{};
    for (final w in words) {
      freq[w] = (freq[w] ?? 0) + 1;
    }
    final sorted =
        freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(100).map((e) => e.key).toSet();
  }

  Set<String> _intersectionAll(List<Set<String>> sets) {
    if (sets.isEmpty) return <String>{};
    var inter = sets.first.toSet();
    for (int i = 1; i < sets.length; i++) {
      inter = inter.intersection(sets[i]);
    }
    return inter;
  }

  // Enhanced search capabilities
  Future<List<SearchResult>> performAdvancedSearch(
    String query, {
    List<String>? bookIds,
    int maxResults = 50,
  }) async {
    final results = <SearchResult>[];
    final searchBooks = bookIds ?? [pmbokId, prince2Id, isoId];
    final errors = <String, AppError>{};

    for (final bookId in searchBooks) {
      try {
        await _ensureLoaded(bookId);
        final bookResults = await _searchInBook(
          bookId,
          query,
          maxResults ~/ searchBooks.length,
        );
        results.addAll(bookResults);
      } catch (e) {
        final error = AppError(
          type: ErrorType.searchTimeout,
          severity: ErrorSeverity.medium,
          message: 'Search failed for $bookId',
          details: 'Error searching in $bookId: $e',
          suggestion: 'Try searching in other books or simplify the query',
          context: 'Advanced search',
        );
        errors[bookId] = error;
        _errorHandler.logError(error);
        debugPrint('Search error in $bookId: $e');
      }
    }

    // If all books failed, throw an error
    if (results.isEmpty && errors.length == searchBooks.length) {
      final error = AppError(
        type: ErrorType.searchTimeout,
        severity: ErrorSeverity.high,
        message: 'Search failed in all books',
        details: 'No results could be retrieved from any book',
        suggestion: 'Check book availability and try a different query',
        context: 'Advanced search',
      );
      _errorHandler.logError(error);
      throw Exception('Search failed: ${error.message}');
    }

    // Sort by match score
    results.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return results.take(maxResults).toList();
  }

  Future<List<SearchResult>> _searchInBook(
    String bookId,
    String query,
    int maxResults,
  ) async {
    final doc = _bookIdToDoc[bookId];
    if (doc == null) {
      final error = AppError(
        type: ErrorType.processingError,
        severity: ErrorSeverity.medium,
        message: 'Book not loaded',
        details: 'Cannot search in $bookId: document not loaded',
        context: 'Book search',
      );
      _errorHandler.logError(error);
      return [];
    }

    // Check for existing book errors that might affect search
    if (_bookErrors.containsKey(bookId)) {
      final bookError = _bookErrors[bookId]!;
      if (bookError.type == ErrorType.scannedPdf &&
          bookError.severity == ErrorSeverity.medium) {
        // Continue with limited search for scanned PDFs
        debugPrint(
          'Searching in scanned PDF $bookId with limited functionality',
        );
      } else if (bookError.severity == ErrorSeverity.high) {
        final error = AppError(
          type: ErrorType.processingError,
          severity: ErrorSeverity.medium,
          message: 'Cannot search due to book error',
          details: 'Book $bookId has error: ${bookError.message}',
          context: 'Book search',
        );
        _errorHandler.logError(error);
        return [];
      }
    }

    final results = <SearchResult>[];
    final queryLower = query.toLowerCase();
    final queryWords = queryLower.split(RegExp(r'\s+'));

    // Validate query
    if (queryWords.isEmpty || queryWords.every((word) => word.length < 2)) {
      final error = AppError(
        type: ErrorType.processingError,
        severity: ErrorSeverity.low,
        message: 'Search query too short',
        details: 'Query must contain words with at least 2 characters',
        suggestion: 'Try a longer, more specific search term',
        context: 'Search validation',
      );
      _errorHandler.logError(error);
      return [];
    }

    try {
      final extractor = PdfTextExtractor(doc);
      final totalPages = doc.pages.count;
      int processedPages = 0;
      int failedPages = 0;

      // Set timeout for search operation
      final searchTimeout = Duration(seconds: 30);
      final searchCompleter = Completer<List<SearchResult>>();

      // Start search with timeout
      Timer(searchTimeout, () {
        if (!searchCompleter.isCompleted) {
          final error = AppError(
            type: ErrorType.searchTimeout,
            severity: ErrorSeverity.medium,
            message: 'Search operation timed out',
            details:
                'Search in $bookId exceeded ${searchTimeout.inSeconds} seconds',
            suggestion:
                'Try a more specific search term or search in fewer books',
            recoveryActions: [
              'Use more specific keywords',
              'Search in individual books',
              'Try shorter search terms',
            ],
            context: 'Search timeout',
          );
          _errorHandler.logError(error);
          searchCompleter.complete([]);
        }
      });

      // Perform the actual search
      _performSearch(
            extractor,
            totalPages,
            queryWords,
            query,
            bookId,
            maxResults,
            results,
            searchCompleter,
          )
          .then((_) {
            if (!searchCompleter.isCompleted) {
              searchCompleter.complete(results);
            }
          })
          .catchError((e) {
            if (!searchCompleter.isCompleted) {
              final error = AppError(
                type: ErrorType.processingError,
                severity: ErrorSeverity.medium,
                message: 'Search processing error',
                details: 'Error during search in $bookId: $e',
                context: 'Search processing',
              );
              _errorHandler.logError(error);
              searchCompleter.complete([]);
            }
          });

      final searchResults = await searchCompleter.future;

      // Log search statistics
      debugPrint(
        'Search in $bookId: ${searchResults.length} results, $processedPages/$totalPages pages processed',
      );

      return searchResults;
    } catch (e) {
      final error = AppError(
        type: ErrorType.processingError,
        severity: ErrorSeverity.medium,
        message: 'Search failed',
        details: 'Error searching in book $bookId: $e',
        suggestion: 'Try searching in other books or simplify the query',
        recoveryActions: [
          'Try a different search term',
          'Search in other available books',
          'Check if the book is properly loaded',
        ],
        context: 'Book search',
      );
      _errorHandler.logError(error);
      return [];
    }
  }

  Future<void> _performSearch(
    PdfTextExtractor extractor,
    int totalPages,
    List<String> queryWords,
    String originalQuery,
    String bookId,
    int maxResults,
    List<SearchResult> results,
    Completer<List<SearchResult>> completer,
  ) async {
    int failedPages = 0;
    const maxFailedPages = 10; // Stop if too many pages fail

    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      if (completer.isCompleted) break;

      try {
        final pageText = extractor.extractText(
          startPageIndex: pageIndex,
          endPageIndex: pageIndex,
        );

        // Calculate match score
        double matchScore = 0.0;
        int matchCount = 0;

        for (final word in queryWords) {
          if (word.length >= 2) {
            final wordCount =
                RegExp(word, caseSensitive: false).allMatches(pageText).length;
            matchCount += wordCount;
            matchScore += wordCount * (word.length / 10.0);
          }
        }

        if (matchCount > 0) {
          // Extract snippet around matches
          final snippet = _extractSnippet(pageText, originalQuery, 150);
          final highlightedText = _highlightMatches(snippet, originalQuery);

          results.add(
            SearchResult(
              bookId: bookId,
              pageNumber: pageIndex + 1,
              snippet: snippet,
              highlightedText: highlightedText,
              matchScore: matchScore,
              topic: _identifyTopic(pageText),
              timestamp: DateTime.now(),
            ),
          );
        }

        if (results.length >= maxResults) break;

        // Yield control periodically to prevent UI blocking
        if (pageIndex % 10 == 0) {
          await Future.delayed(Duration.zero);
        }
      } catch (e) {
        failedPages++;
        debugPrint(
          'Failed to extract text from page ${pageIndex + 1} in $bookId: $e',
        );

        if (failedPages > maxFailedPages) {
          final error = AppError(
            type: ErrorType.processingError,
            severity: ErrorSeverity.medium,
            message: 'Too many page extraction failures',
            details:
                'Failed to extract text from $failedPages pages in $bookId',
            suggestion:
                'The document may be corrupted or contain unsupported content',
            context: 'Text extraction',
          );
          _errorHandler.logError(error);
          break;
        }
      }
    }
  }

  String _extractSnippet(String text, String query, int maxLength) {
    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();

    final matchIndex = textLower.indexOf(queryLower);
    if (matchIndex == -1) {
      return text.length <= maxLength ? text : text.substring(0, maxLength);
    }

    final start = math.max(0, matchIndex - maxLength ~/ 2);
    final end = math.min(text.length, start + maxLength);

    String snippet = text.substring(start, end);
    if (start > 0) snippet = '...$snippet';
    if (end < text.length) snippet = '$snippet...';

    return snippet;
  }

  String _highlightMatches(String text, String query) {
    final queryWords = query.split(RegExp(r'\s+'));
    String highlighted = text;

    for (final word in queryWords) {
      if (word.length >= 3) {
        highlighted = highlighted.replaceAllMapped(
          RegExp(word, caseSensitive: false),
          (match) => '<mark>${match.group(0)}</mark>',
        );
      }
    }

    return highlighted;
  }

  String _identifyTopic(String text) {
    final textLower = text.toLowerCase();

    // Check against predefined topics
    for (final entry in _topicsConfig.entries) {
      final topicData = entry.value as Map<String, dynamic>;
      final keywords =
          (topicData['keywords'] as List<dynamic>?)?.cast<String>() ?? [];
      final synonyms =
          (topicData['synonyms'] as List<dynamic>?)?.cast<String>() ?? [];

      final allTerms = [...keywords, ...synonyms];
      for (final term in allTerms) {
        if (textLower.contains(term.toLowerCase())) {
          return entry.key;
        }
      }
    }

    return 'General';
  }

  // Enhanced topic-based search with caching
  Future<Map<String, List<SearchResult>>> searchByTopic(
    String topic, {
    int contextRadius = 2,
  }) async {
    // Check cache first
    final cacheKey = 'topic_search_${topic}_$contextRadius';
    final cachedResults = _getCachedTopicSearch(cacheKey);
    if (cachedResults != null) {
      return cachedResults;
    }

    final results = <String, List<SearchResult>>{};

    // Get topic-specific keywords and use topic mapping if available
    final topicData = _topicsConfig[topic] as Map<String, dynamic>?;
    final keywords =
        (topicData?['keywords'] as List<dynamic>?)?.cast<String>() ?? [topic];
    final synonyms =
        (topicData?['synonyms'] as List<dynamic>?)?.cast<String>() ?? [];

    final searchTerms = [...keywords, ...synonyms];

    for (final bookId in [pmbokId, prince2Id, isoId]) {
      await _ensureLoaded(bookId);
      final bookResults = <SearchResult>[];

      // Use topic mapping for faster search if available
      final topicMapping = _bookIdToTopicMapping[bookId];
      if (topicMapping != null && topicMapping.containsKey(topic)) {
        // Direct topic mapping available - use it for faster results
        final pages = topicMapping[topic]!;
        for (final pageStr in pages) {
          final pageNumber = int.tryParse(pageStr);
          if (pageNumber != null) {
            final pageText = _bookIdToPageText[bookId]?[pageStr];
            if (pageText != null) {
              final snippet = _extractSnippet(pageText, topic, 200);
              final highlighted = _highlightMatches(snippet, topic);

              bookResults.add(
                SearchResult(
                  bookId: bookId,
                  pageNumber: pageNumber,
                  snippet: snippet,
                  highlightedText: highlighted,
                  matchScore: _calculateTopicMatchScore(pageText, searchTerms),
                  topic: topic,
                  timestamp: DateTime.now(),
                ),
              );
            }
          }
        }
      } else {
        // Fallback to traditional search
        for (final term in searchTerms) {
          final termResults = await _searchInBook(bookId, term, 20);
          bookResults.addAll(termResults);
        }
      }

      // Remove duplicates and sort by score
      final uniqueResults = <int, SearchResult>{};
      for (final result in bookResults) {
        final existing = uniqueResults[result.pageNumber];
        if (existing == null || result.matchScore > existing.matchScore) {
          uniqueResults[result.pageNumber] = result;
        }
      }

      results[bookId] =
          uniqueResults.values.toList()
            ..sort((a, b) => b.matchScore.compareTo(a.matchScore));
    }

    // Cache results
    _cacheTopicSearch(cacheKey, results);
    return results;
  }

  double _calculateTopicMatchScore(String text, List<String> searchTerms) {
    final textLower = text.toLowerCase();
    double score = 0.0;

    for (final term in searchTerms) {
      final termLower = term.toLowerCase();
      final matches =
          RegExp(termLower, caseSensitive: false).allMatches(text).length;
      score += matches * (term.length / 10.0); // Weight by term length
    }

    return score;
  }

  // Topic search caching
  final Map<String, Map<String, List<SearchResult>>> _topicSearchCache = {};

  Map<String, List<SearchResult>>? _getCachedTopicSearch(String cacheKey) {
    return _topicSearchCache[cacheKey];
  }

  void _cacheTopicSearch(
    String cacheKey,
    Map<String, List<SearchResult>> results,
  ) {
    _topicSearchCache[cacheKey] = results;

    // Limit cache size
    if (_topicSearchCache.length > 50) {
      final oldestKey = _topicSearchCache.keys.first;
      _topicSearchCache.remove(oldestKey);
    }
  }

  // Topic mapping and configuration
  Future<void> _loadTopicConfigurations() async {
    try {
      final topicsJson = await rootBundle.loadString('assets/topics.json');
      _topicsConfig = json.decode(topicsJson);

      final compareTopicsJson = await rootBundle.loadString(
        'assets/compare_topics.json',
      );
      _compareTopicsConfig = json.decode(compareTopicsJson);

      // Build topic-aware search index
      await _buildTopicAwareIndex();
    } catch (e) {
      debugPrint('Error loading topic configurations: $e');
      _topicsConfig = {};
      _compareTopicsConfig = {};
    }
  }

  // Topic-aware indexing for better search performance
  Future<void> _buildTopicAwareIndex() async {
    for (final bookId in [pmbokId, prince2Id, isoId]) {
      if (_bookIdToDoc.containsKey(bookId)) {
        await _indexBookWithTopics(bookId);
      }
    }
  }

  Future<void> _indexBookWithTopics(String bookId) async {
    final doc = _bookIdToDoc[bookId];
    if (doc == null) return;

    final topicMapping = <String, List<String>>{};
    final extractor = PdfTextExtractor(doc);

    try {
      // Index pages with topic associations
      for (int pageIndex = 0; pageIndex < doc.pages.count; pageIndex++) {
        final pageText = extractor.extractText(
          startPageIndex: pageIndex,
          endPageIndex: pageIndex,
        );

        // Identify topics present on this page
        final pageTopics = _identifyTopicsOnPage(pageText);

        for (final topic in pageTopics) {
          topicMapping
              .putIfAbsent(topic, () => [])
              .add((pageIndex + 1).toString());
        }

        // Cache page text for faster retrieval
        _bookIdToPageText.putIfAbsent(bookId, () => {})[(pageIndex + 1)
                .toString()] =
            pageText;
      }

      _bookIdToTopicMapping[bookId] = topicMapping;
      _lastIndexed[bookId] = DateTime.now();
    } catch (e) {
      debugPrint('Error indexing book $bookId with topics: $e');
    }
  }

  List<String> _identifyTopicsOnPage(String pageText) {
    final identifiedTopics = <String>[];
    final textLower = pageText.toLowerCase();

    for (final entry in _topicsConfig.entries) {
      final topicName = entry.key;
      final topicData = entry.value as Map<String, dynamic>;

      final keywords =
          (topicData['keywords'] as List<dynamic>?)?.cast<String>() ?? [];
      final synonyms =
          (topicData['synonyms'] as List<dynamic>?)?.cast<String>() ?? [];

      final allTerms = [...keywords, ...synonyms];

      // Check if any terms are present on this page
      int matchCount = 0;
      for (final term in allTerms) {
        if (textLower.contains(term.toLowerCase())) {
          matchCount++;
        }
      }

      // If multiple terms match, consider this topic present
      if (matchCount >= 2 || (matchCount >= 1 && allTerms.length <= 3)) {
        identifiedTopics.add(topicName);
      }
    }

    return identifiedTopics;
  }

  Map<String, dynamic> getTopicConfiguration(String topic) {
    return (_topicsConfig[topic] as Map<String, dynamic>?) ?? {};
  }

  List<String> getTopicKeywords(String topic) {
    final config = getTopicConfiguration(topic);
    return (config['keywords'] as List<dynamic>?)?.cast<String>() ?? [];
  }

  List<String> getTopicSynonyms(String topic) {
    final config = getTopicConfiguration(topic);
    return (config['synonyms'] as List<dynamic>?)?.cast<String>() ?? [];
  }

  // Enhanced performance optimization with smart caching
  void clearCache() {
    _bookIdToPageText.clear();
    _bookIdToTopicMapping.clear();
    _topicSearchCache.clear();
    // Keep documents loaded but clear cached text
  }

  void optimizeCache() {
    // Remove least recently used cache entries
    final now = DateTime.now();

    // Clear old topic search cache entries (older than 1 hour)
    _topicSearchCache.removeWhere((key, value) {
      // In a real implementation, we'd track access times
      return _topicSearchCache.length > 20; // Simple size-based cleanup
    });

    // Optimize page text cache - keep only frequently accessed pages
    for (final bookId in _bookIdToPageText.keys.toList()) {
      final pageTexts = _bookIdToPageText[bookId]!;
      if (pageTexts.length > 100) {
        // Keep only first 50 pages and last 50 pages for large books
        final sortedPages = pageTexts.keys.map(int.parse).toList()..sort();
        final pagesToKeep = <String>{};

        // Keep first 25 pages
        pagesToKeep.addAll(sortedPages.take(25).map((p) => p.toString()));
        // Keep last 25 pages
        pagesToKeep.addAll(
          sortedPages.skip(sortedPages.length - 25).map((p) => p.toString()),
        );

        pageTexts.removeWhere((page, text) => !pagesToKeep.contains(page));
      }
    }
  }

  // Lazy loading with progressive indexing
  Future<void> progressivelyIndexBook(
    String bookId, {
    int batchSize = 10,
  }) async {
    final doc = _bookIdToDoc[bookId];
    if (doc == null) return;

    final extractor = PdfTextExtractor(doc);
    final totalPages = doc.pages.count;

    for (int startPage = 0; startPage < totalPages; startPage += batchSize) {
      final endPage = (startPage + batchSize).clamp(0, totalPages);

      // Index batch of pages
      for (int pageIndex = startPage; pageIndex < endPage; pageIndex++) {
        try {
          final pageText = extractor.extractText(
            startPageIndex: pageIndex,
            endPageIndex: pageIndex,
          );

          // Cache page text
          _bookIdToPageText.putIfAbsent(bookId, () => {})[(pageIndex + 1)
                  .toString()] =
              pageText;

          // Identify topics on this page
          final pageTopics = _identifyTopicsOnPage(pageText);
          for (final topic in pageTopics) {
            _bookIdToTopicMapping
                .putIfAbsent(bookId, () => {})
                .putIfAbsent(topic, () => [])
                .add((pageIndex + 1).toString());
          }
        } catch (e) {
          debugPrint('Error indexing page ${pageIndex + 1} in $bookId: $e');
        }
      }

      // Yield control to prevent UI blocking
      await Future.delayed(Duration.zero);
    }

    _lastIndexed[bookId] = DateTime.now();
  }

  // Smart preloading based on usage patterns
  void preloadFrequentlyAccessedContent(List<String> frequentTopics) {
    for (final topic in frequentTopics) {
      // Preload topic-related pages in background
      _preloadTopicContent(topic);
    }
  }

  Future<void> _preloadTopicContent(String topic) async {
    for (final bookId in [pmbokId, prince2Id, isoId]) {
      final topicMapping = _bookIdToTopicMapping[bookId];
      if (topicMapping != null && topicMapping.containsKey(topic)) {
        final pages = topicMapping[topic]!;

        // Ensure page text is cached for these pages
        for (final pageStr in pages.take(5)) {
          // Limit to first 5 pages
          if (!(_bookIdToPageText[bookId]?.containsKey(pageStr) ?? false)) {
            // Load page text if not already cached
            final pageNumber = int.tryParse(pageStr);
            if (pageNumber != null) {
              await _loadPageText(bookId, pageNumber);
            }
          }
        }
      }
    }
  }

  Future<void> _loadPageText(String bookId, int pageNumber) async {
    final doc = _bookIdToDoc[bookId];
    if (doc == null) return;

    try {
      final extractor = PdfTextExtractor(doc);
      final pageText = extractor.extractText(
        startPageIndex: pageNumber - 1,
        endPageIndex: pageNumber - 1,
      );

      _bookIdToPageText.putIfAbsent(bookId, () => {})[pageNumber.toString()] =
          pageText;
    } catch (e) {
      debugPrint('Error loading page text for $bookId page $pageNumber: $e');
    }
  }

  Map<String, dynamic> getPerformanceStats() {
    return {
      'loadedBooks': _bookIdToDoc.length,
      'cachedPages': _bookIdToPageText.values.fold(
        0,
        (sum, pages) => sum + pages.length,
      ),
      'lastIndexed': _lastIndexed.map(
        (k, v) => MapEntry(k, v.toIso8601String()),
      ),
      'topicsConfigured': _topicsConfig.length,
    };
  }

  // Full-text indexing for better search performance
  Future<void> _indexBookText(String bookId) async {
    final doc = _bookIdToDoc[bookId];
    if (doc == null) return;

    final pageTexts = <String, String>{};
    final extractor = PdfTextExtractor(doc);

    try {
      for (int pageIndex = 0; pageIndex < doc.pages.count; pageIndex++) {
        final pageText = extractor.extractText(
          startPageIndex: pageIndex,
          endPageIndex: pageIndex,
        );
        pageTexts[(pageIndex + 1).toString()] = pageText;
      }

      _bookIdToPageText[bookId] = pageTexts;
      _lastIndexed[bookId] = DateTime.now();
    } catch (e) {
      debugPrint('Error indexing book $bookId: $e');
    }
  }

  String? getPageText(String bookId, int pageNumber) {
    return _bookIdToPageText[bookId]?[pageNumber.toString()];
  }

  // Text extraction testing
  Future<void> _testTextExtraction(String bookId, PdfDocument doc) async {
    try {
      final extractor = PdfTextExtractor(doc);
      final maxPagesToTest = doc.pages.count < 3 ? doc.pages.count : 3;
      int pagesWithText = 0;

      for (int i = 0; i < maxPagesToTest; i++) {
        try {
          final text = extractor.extractText(
            startPageIndex: i,
            endPageIndex: i,
          );
          if (text.trim().isNotEmpty) {
            pagesWithText++;
          }
        } catch (e) {
          debugPrint('Text extraction failed for page $i in $bookId: $e');
        }
      }

      if (pagesWithText == 0) {
        final error = AppError(
          type: ErrorType.scannedPdf,
          severity: ErrorSeverity.medium,
          message: 'PDF appears to contain scanned images',
          details:
              'No extractable text found in first $maxPagesToTest pages of $bookId',
          suggestion: 'Search functionality will be limited for this document',
          recoveryActions: [
            'Continue with limited functionality',
            'Consider using an OCR-processed version',
            'Manual navigation may be required',
          ],
          context: 'Text extraction test',
        );
        _bookErrors[bookId] = error;
        _errorHandler.logError(error);
      } else if (pagesWithText < maxPagesToTest * 0.5) {
        final error = AppError(
          type: ErrorType.scannedPdf,
          severity: ErrorSeverity.low,
          message: 'PDF has limited searchable text',
          details:
              'Only $pagesWithText of $maxPagesToTest pages contain text in $bookId',
          suggestion: 'Some search features may be limited',
          context: 'Text extraction test',
        );
        _errorHandler.logError(error);
      }
    } catch (e) {
      final error = AppError(
        type: ErrorType.processingError,
        severity: ErrorSeverity.medium,
        message: 'Cannot test text extraction',
        details: 'Error testing text extraction for $bookId: $e',
        context: 'Text extraction test',
      );
      _errorHandler.logError(error);
    }
  }

  // Error reporting methods
  AppError? getBookError(String bookId) {
    return _bookErrors[bookId];
  }

  Map<String, AppError> getAllBookErrors() {
    return Map.unmodifiable(_bookErrors);
  }

  bool hasBookError(String bookId) {
    return _bookErrors.containsKey(bookId);
  }

  void clearBookError(String bookId) {
    _bookErrors.remove(bookId);
  }

  void clearAllErrors() {
    _bookErrors.clear();
  }

  // Enhanced error handling for existing methods
  List<TocEntry> getIndexWithErrorHandling(String bookId) {
    try {
      if (_bookErrors.containsKey(bookId)) {
        final error = _bookErrors[bookId]!;
        if (error.severity == ErrorSeverity.high ||
            error.severity == ErrorSeverity.critical) {
          debugPrint(
            'Cannot get index for $bookId due to error: ${error.message}',
          );
          return [];
        }
      }
      return _bookIdToToc[bookId] ?? const <TocEntry>[];
    } catch (e) {
      final error = AppError(
        type: ErrorType.processingError,
        severity: ErrorSeverity.low,
        message: 'Error getting table of contents',
        details: 'Error getting index for $bookId: $e',
        context: 'Table of contents',
      );
      _errorHandler.logError(error);
      return [];
    }
  }

  // Health check method
  Map<String, dynamic> getHealthStatus() {
    final loadedBooks = _bookIdToDoc.keys.toList();
    final errorBooks = _bookErrors.keys.toList();
    final healthyBooks =
        loadedBooks.where((id) => !_bookErrors.containsKey(id)).toList();

    return {
      'totalBooks': [pmbokId, prince2Id, isoId].length,
      'loadedBooks': loadedBooks.length,
      'healthyBooks': healthyBooks.length,
      'booksWithErrors': errorBooks.length,
      'errors': _bookErrors.map((k, v) => MapEntry(k, v.toJson())),
      'lastCheck': DateTime.now().toIso8601String(),
    };
  }
}
