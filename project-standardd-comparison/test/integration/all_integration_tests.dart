import 'package:flutter_test/flutter_test.dart';

// Import all integration test files
import 'search_bookmark_workflow_test.dart' as search_bookmark_tests;
import 'comparison_export_workflow_test.dart' as comparison_export_tests;
import 'multi_book_navigation_test.dart' as multi_book_tests;
import 'deep_link_workflow_test.dart' as deep_link_tests;
import 'performance_test.dart' as performance_tests;
import 'accessibility_test.dart' as accessibility_tests;

void main() {
  group('All Integration Tests', () {
    group('Search and Bookmark Workflows', () {
      search_bookmark_tests.main();
    });

    group('Comparison and Export Workflows', () {
      comparison_export_tests.main();
    });

    group('Multi-Book Navigation', () {
      multi_book_tests.main();
    });

    group('Deep Link Workflows', () {
      deep_link_tests.main();
    });

    group('Performance Tests', () {
      performance_tests.main();
    });

    group('Accessibility Tests', () {
      accessibility_tests.main();
    });
  });
}
