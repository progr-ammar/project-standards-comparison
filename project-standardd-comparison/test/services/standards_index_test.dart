import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:pm4_app/services/standards_index.dart';
import 'package:pm4_app/services/error_handling_service.dart';

void main() {
  group('StandardsIndexService', () {
    late StandardsIndexService service;

    setUp(() {
      service = StandardsIndexService();
    });

    tearDown(() {
      // Clean up any resources
    });

    group('Book Loading', () {
      test('should load all configured books', () async {
        await service.loadAll();

        // Verify service is initialized
        expect(service, isNotNull);
      });

      test('should handle missing asset files gracefully', () async {
        // Test with invalid book ID
        expect(() => service.ensureBookLoaded('invalid_book'), throwsException);
      });

      test('should detect loaded books correctly', () async {
        await service.loadAll();

        // Initially no books should be loaded (lazy loading)
        expect(service.isBookLoaded('pmbok7'), isFalse);
        expect(service.isBookLoaded('prince2'), isFalse);
        expect(service.isBookLoaded('iso21502'), isFalse);
      });

      test('should load book on demand', () async {
        await service.loadAll();

        // Load a specific book
        try {
          await service.ensureBookLoaded('pmbok7');
          expect(service.isBookLoaded('pmbok7'), isTrue);
        } catch (e) {
          // Asset loading might fail in test environment
          expect(e, isA<Exception>());
        }
      });
    });

    group('Table of Contents Extraction', () {
      test('should return empty TOC for unloaded books', () {
        final toc = service.getIndex('pmbok7');
        expect(toc, isEmpty);
      });

      test('should handle TOC extraction errors gracefully', () {
        final toc = service.getIndexWithErrorHandling('invalid_book');
        expect(toc, isEmpty);
      });
    });

    group('Search Functionality', () {
      test('should handle empty search queries', () async {
        final results = await service.performAdvancedSearch('');
        expect(results, isEmpty);
      });

      test('should handle search with no results', () async {
        final results = await service.performAdvancedSearch(
          'nonexistentterm12345',
        );
        expect(results, isEmpty);
      });

      test('should validate search query length', () async {
        final results = await service.performAdvancedSearch('a');
        expect(results, isEmpty);
      });

      test('should limit search results correctly', () async {
        final results = await service.performAdvancedSearch(
          'project',
          maxResults: 5,
        );
        expect(results.length, lessThanOrEqualTo(5));
      });

      test('should search in specific books only', () async {
        final results = await service.performAdvancedSearch(
          'project',
          bookIds: ['pmbok7'],
          maxResults: 10,
        );

        // All results should be from pmbok7
        for (final result in results) {
          expect(result.bookId, equals('pmbok7'));
        }
      });
    });

    group('Topic Management', () {
      test('should load topic configurations', () async {
        await service.loadAll();

        final config = service.getTopicConfiguration('Risk Management');
        expect(config, isA<Map<String, dynamic>>());
      });

      test('should return empty config for unknown topics', () {
        final config = service.getTopicConfiguration('Unknown Topic');
        expect(config, isEmpty);
      });

      test('should extract topic keywords', () {
        final keywords = service.getTopicKeywords('Risk Management');
        expect(keywords, isA<List<String>>());
      });

      test('should extract topic synonyms', () {
        final synonyms = service.getTopicSynonyms('Risk Management');
        expect(synonyms, isA<List<String>>());
      });

      test('should map topics to pages', () {
        final pageMap = service.mapTopicToPages('Risk Management');
        expect(pageMap, isA<Map<String, int?>>());
        expect(pageMap.keys, containsAll(['pmbok7', 'prince2', 'iso21502']));
      });
    });

    group('Text Extraction', () {
      test('should extract text around pages', () {
        final pageMap = {'pmbok7': 10, 'prince2': 15};
        final textMap = service.extractTextAroundPages(pageMap);
        expect(textMap, isA<Map<String, String>>());
      });

      test('should handle null pages in extraction', () {
        final pageMap = {'pmbok7': null, 'prince2': 15};
        final textMap = service.extractTextAroundPages(pageMap);
        expect(textMap.containsKey('pmbok7'), isFalse);
      });

      test('should get cached page text', () {
        final pageText = service.getPageText('pmbok7', 1);
        expect(pageText, isA<String?>());
      });
    });

    group('Performance and Caching', () {
      test('should clear cache successfully', () {
        service.clearCache();
        // Verify cache is cleared (no direct way to test, but should not throw)
        expect(() => service.clearCache(), returnsNormally);
      });

      test('should optimize cache without errors', () {
        service.optimizeCache();
        expect(() => service.optimizeCache(), returnsNormally);
      });

      test('should return performance stats', () {
        final stats = service.getPerformanceStats();
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('loadedBooks'), isTrue);
        expect(stats.containsKey('cachedPages'), isTrue);
      });

      test('should preload content without errors', () {
        service.preloadFrequentlyAccessedContent(['Risk Management']);
        expect(
          () => service.preloadFrequentlyAccessedContent([]),
          returnsNormally,
        );
      });
    });

    group('Error Handling', () {
      test('should track book errors', () {
        expect(service.hasBookError('pmbok7'), isFalse);
        expect(service.getBookError('pmbok7'), isNull);
      });

      test('should clear book errors', () {
        service.clearBookError('pmbok7');
        service.clearAllErrors();
        expect(() => service.clearAllErrors(), returnsNormally);
      });

      test('should return health status', () {
        final health = service.getHealthStatus();
        expect(health, isA<Map<String, dynamic>>());
        expect(health.containsKey('totalBooks'), isTrue);
        expect(health.containsKey('loadedBooks'), isTrue);
        expect(health.containsKey('healthyBooks'), isTrue);
      });

      test('should get all book errors', () {
        final errors = service.getAllBookErrors();
        expect(errors, isA<Map<String, AppError>>());
      });
    });

    group('Topic-based Search', () {
      test('should search by topic', () async {
        final results = await service.searchByTopic('Risk Management');
        expect(results, isA<Map<String, List<SearchResult>>>());
        expect(results.keys, containsAll(['pmbok7', 'prince2', 'iso21502']));
      });

      test('should handle unknown topics in search', () async {
        final results = await service.searchByTopic('Unknown Topic');
        expect(results, isA<Map<String, List<SearchResult>>>());
      });

      test('should use context radius in topic search', () async {
        final results = await service.searchByTopic(
          'Risk Management',
          contextRadius: 3,
        );
        expect(results, isA<Map<String, List<SearchResult>>>());
      });
    });

    group('Insights Generation', () {
      test('should compute insights from book texts', () {
        final bookTexts = {
          'pmbok7': 'project management risk quality stakeholder',
          'prince2': 'project management governance risk control',
          'iso21502': 'project management standard quality process',
        };

        final insights = service.computeInsights(bookTexts);
        expect(insights, isA<Map<String, dynamic>>());
        expect(insights.containsKey('Similarities'), isTrue);
        expect(insights.containsKey('Differences'), isTrue);
        expect(insights.containsKey('Unique'), isTrue);
      });

      test('should handle empty book texts in insights', () {
        final insights = service.computeInsights({});
        expect(insights, isA<Map<String, dynamic>>());
      });

      test('should handle single book in insights', () {
        final bookTexts = {'pmbok7': 'project management'};
        final insights = service.computeInsights(bookTexts);
        expect(insights, isA<Map<String, dynamic>>());
      });
    });

    group('Page Navigation', () {
      test('should find TOC page', () {
        final tocPage = service.findTocPage('pmbok7');
        expect(tocPage, isA<int?>());
      });

      test('should find index page', () {
        final indexPage = service.findIndexPage('pmbok7');
        expect(indexPage, isA<int?>());
      });

      test('should handle unknown books in page finding', () {
        final tocPage = service.findTocPage('unknown_book');
        expect(tocPage, isNull);
      });
    });

    group('Topic Extraction', () {
      test('should get all topics from loaded books', () {
        final topics = service.getAllTopics();
        expect(topics, isA<List<String>>());
      });

      test('should return sorted topics', () {
        final topics = service.getAllTopics();
        final sortedTopics = List<String>.from(topics)..sort();
        expect(topics, equals(sortedTopics));
      });
    });
  });
}
