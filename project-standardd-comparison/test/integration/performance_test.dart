import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pm4_app/main.dart';
import 'package:pm4_app/providers/theme_provider.dart';
import 'package:pm4_app/providers/search_provider.dart';
import 'package:pm4_app/providers/bookmarks_provider.dart';
import 'package:pm4_app/providers/index_provider.dart';
import 'package:pm4_app/providers/topic_provider.dart';
import 'package:pm4_app/providers/comparison_provider.dart';

void main() {
  group('Performance Integration Tests', () {
    late Widget testApp;
    late SharedPreferences mockPrefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();

      testApp = MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(mockPrefs)),
          ChangeNotifierProvider(create: (_) => SearchProvider(mockPrefs)),
          ChangeNotifierProvider(create: (_) => BookmarksProvider(mockPrefs)),
          ChangeNotifierProvider(create: (_) => IndexProvider()..init()),
          ChangeNotifierProvider(create: (_) => TopicProvider(mockPrefs)),
          ChangeNotifierProvider(create: (_) => ComparisonProvider(mockPrefs)),
        ],
        child: const MaterialApp(home: MyApp()),
      );
    });

    testWidgets('App startup performance test', (WidgetTester tester) async {
      // Step 1: Measure app startup time
      final startTime = DateTime.now();

      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      final endTime = DateTime.now();
      final startupDuration = endTime.difference(startTime);

      // Step 2: Verify startup time is reasonable (under 3 seconds)
      expect(startupDuration.inMilliseconds, lessThan(3000));

      // Step 3: Verify all essential UI elements are rendered
      final homeScreenFinder = find.byKey(Key('home_screen'));
      if (homeScreenFinder.evaluate().isNotEmpty) {
        expect(homeScreenFinder, findsOneWidget);
      }

      final navigationBarFinder = find.byType(NavigationBar);
      expect(navigationBarFinder, findsOneWidget);

      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);
    });

    testWidgets('Large document loading performance test', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Measure large PDF loading time
      final loadStartTime = DateTime.now();

      final pmbokTileFinder = find.byKey(Key('pmbok_tile'));
      if (pmbokTileFinder.evaluate().isNotEmpty) {
        await tester.tap(pmbokTileFinder);

        // Step 2: Wait for loading to complete
        await tester.pumpAndSettle(Duration(seconds: 10));

        final loadEndTime = DateTime.now();
        final loadDuration = loadEndTime.difference(loadStartTime);

        // Step 3: Verify loading time is acceptable (under 10 seconds)
        expect(loadDuration.inSeconds, lessThan(10));

        // Step 4: Verify document is loaded and responsive
        final readerScreenFinder = find.byKey(Key('reader_screen'));
        if (readerScreenFinder.evaluate().isNotEmpty) {
          expect(readerScreenFinder, findsOneWidget);

          // Step 5: Test page navigation responsiveness
          final nextPageStartTime = DateTime.now();

          final nextPageButtonFinder = find.byKey(Key('next_page_button'));
          if (nextPageButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(nextPageButtonFinder);
            await tester.pumpAndSettle();

            final nextPageEndTime = DateTime.now();
            final navigationDuration = nextPageEndTime.difference(
              nextPageStartTime,
            );

            // Step 6: Verify page navigation is fast (under 1 second)
            expect(navigationDuration.inMilliseconds, lessThan(1000));
          }
        }
      }
    });

    testWidgets('Search performance test', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Measure search response time
      final searchStartTime = DateTime.now();

      final searchBarFinder = find.byType(TextField);
      if (searchBarFinder.evaluate().isNotEmpty) {
        await tester.enterText(
          searchBarFinder.first,
          'project management methodology',
        );
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        final searchEndTime = DateTime.now();
        final searchDuration = searchEndTime.difference(searchStartTime);

        // Step 2: Verify search completes quickly (under 2 seconds)
        expect(searchDuration.inSeconds, lessThan(2));

        // Step 3: Verify search results are displayed
        final searchResultsFinder = find.byKey(Key('search_results'));
        if (searchResultsFinder.evaluate().isNotEmpty) {
          expect(searchResultsFinder, findsOneWidget);

          // Step 4: Test search result navigation performance
          final resultNavigationStartTime = DateTime.now();

          final firstResultFinder = find.byKey(Key('search_result_0'));
          if (firstResultFinder.evaluate().isNotEmpty) {
            await tester.tap(firstResultFinder);
            await tester.pumpAndSettle();

            final resultNavigationEndTime = DateTime.now();
            final navigationDuration = resultNavigationEndTime.difference(
              resultNavigationStartTime,
            );

            // Step 5: Verify result navigation is fast (under 1 second)
            expect(navigationDuration.inMilliseconds, lessThan(1000));
          }
        }
      }
    });

    testWidgets('Comparison generation performance test', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Navigate to Compare screen
      final compareTabFinder = find.byKey(Key('compare_tab'));
      if (compareTabFinder.evaluate().isNotEmpty) {
        await tester.tap(compareTabFinder);
        await tester.pumpAndSettle();

        // Step 2: Measure comparison generation time
        final comparisonStartTime = DateTime.now();

        final topicDropdownFinder = find.byKey(Key('topic_dropdown'));
        if (topicDropdownFinder.evaluate().isNotEmpty) {
          await tester.tap(topicDropdownFinder);
          await tester.pumpAndSettle();

          final riskTopicFinder = find.text('Risk and Uncertainty');
          if (riskTopicFinder.evaluate().isNotEmpty) {
            await tester.tap(riskTopicFinder);
            await tester.pumpAndSettle(Duration(seconds: 5));

            final comparisonEndTime = DateTime.now();
            final comparisonDuration = comparisonEndTime.difference(
              comparisonStartTime,
            );

            // Step 3: Verify comparison generation is reasonable (under 5 seconds)
            expect(comparisonDuration.inSeconds, lessThan(5));

            // Step 4: Verify comparison results are displayed
            final comparisonResultsFinder = find.byKey(
              Key('comparison_results'),
            );
            if (comparisonResultsFinder.evaluate().isNotEmpty) {
              expect(comparisonResultsFinder, findsOneWidget);

              // Step 5: Test insights generation performance
              final insightsStartTime = DateTime.now();

              final insightsPanelFinder = find.byKey(Key('insights_panel'));
              if (insightsPanelFinder.evaluate().isNotEmpty) {
                await tester.pumpAndSettle();

                final insightsEndTime = DateTime.now();
                final insightsDuration = insightsEndTime.difference(
                  insightsStartTime,
                );

                // Step 6: Verify insights are generated quickly (under 2 seconds)
                expect(insightsDuration.inSeconds, lessThan(2));
              }
            }
          }
        }
      }
    });

    testWidgets('Memory usage test with multiple operations', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Perform multiple memory-intensive operations
      for (int i = 0; i < 5; i++) {
        // Open different books
        final bookTiles = [
          find.byKey(Key('pmbok_tile')),
          find.byKey(Key('prince2_tile')),
          find.byKey(Key('iso_tile')),
        ];

        for (final tileFinder in bookTiles) {
          if (tileFinder.evaluate().isNotEmpty) {
            await tester.tap(tileFinder);
            await tester.pumpAndSettle();

            // Navigate through pages
            final nextPageButtonFinder = find.byKey(Key('next_page_button'));
            if (nextPageButtonFinder.evaluate().isNotEmpty) {
              for (int page = 0; page < 10; page++) {
                await tester.tap(nextPageButtonFinder);
                await tester.pump();
              }
            }

            // Go back to home
            final backButtonFinder = find.byKey(Key('back_button'));
            if (backButtonFinder.evaluate().isNotEmpty) {
              await tester.tap(backButtonFinder);
              await tester.pumpAndSettle();
            }
          }
        }

        // Perform searches
        final searchBarFinder = find.byType(TextField);
        if (searchBarFinder.evaluate().isNotEmpty) {
          final searchQueries = [
            'project management',
            'risk assessment',
            'quality control',
            'stakeholder engagement',
            'resource planning',
          ];

          for (final query in searchQueries) {
            await tester.enterText(searchBarFinder.first, query);
            await tester.testTextInput.receiveAction(TextInputAction.search);
            await tester.pump();

            // Clear search
            await tester.enterText(searchBarFinder.first, '');
            await tester.pump();
          }
        }

        // Create comparisons
        final compareTabFinder = find.byKey(Key('compare_tab'));
        if (compareTabFinder.evaluate().isNotEmpty) {
          await tester.tap(compareTabFinder);
          await tester.pumpAndSettle();

          final topicDropdownFinder = find.byKey(Key('topic_dropdown'));
          if (topicDropdownFinder.evaluate().isNotEmpty) {
            await tester.tap(topicDropdownFinder);
            await tester.pump();

            final topics = [
              'Risk and Uncertainty',
              'Quality Management',
              'Planning and Scope Management',
            ];

            for (final topic in topics) {
              final topicFinder = find.text(topic);
              if (topicFinder.evaluate().isNotEmpty) {
                await tester.tap(topicFinder);
                await tester.pump();
                break;
              }
            }
          }

          // Go back to home
          final homeTabFinder = find.byKey(Key('home_tab'));
          if (homeTabFinder.evaluate().isNotEmpty) {
            await tester.tap(homeTabFinder);
            await tester.pumpAndSettle();
          }
        }
      }

      // Step 2: Verify app is still responsive after intensive operations
      final finalResponseStartTime = DateTime.now();

      final searchBarFinder = find.byType(TextField);
      if (searchBarFinder.evaluate().isNotEmpty) {
        await tester.enterText(searchBarFinder.first, 'final test');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        final finalResponseEndTime = DateTime.now();
        final finalResponseDuration = finalResponseEndTime.difference(
          finalResponseStartTime,
        );

        // Step 3: Verify app remains responsive (under 3 seconds)
        expect(finalResponseDuration.inSeconds, lessThan(3));
      }
    });

    testWidgets('UI responsiveness during background operations test', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Start a background operation (indexing)
      final indexProvider = Provider.of<IndexProvider>(
        tester.element(find.byType(MyApp)),
        listen: false,
      );

      // Simulate heavy indexing operation
      indexProvider.init();

      // Step 2: Test UI responsiveness during background operation
      final uiResponseStartTime = DateTime.now();

      // Navigate between tabs
      final compareTabFinder = find.byKey(Key('compare_tab'));
      if (compareTabFinder.evaluate().isNotEmpty) {
        await tester.tap(compareTabFinder);
        await tester.pump();

        final generateTabFinder = find.byKey(Key('generate_tab'));
        if (generateTabFinder.evaluate().isNotEmpty) {
          await tester.tap(generateTabFinder);
          await tester.pump();

          final homeTabFinder = find.byKey(Key('home_tab'));
          if (homeTabFinder.evaluate().isNotEmpty) {
            await tester.tap(homeTabFinder);
            await tester.pump();
          }
        }
      }

      final uiResponseEndTime = DateTime.now();
      final uiResponseDuration = uiResponseEndTime.difference(
        uiResponseStartTime,
      );

      // Step 3: Verify UI remains responsive (under 500ms for navigation)
      expect(uiResponseDuration.inMilliseconds, lessThan(500));

      // Step 4: Test theme toggle responsiveness during background operation
      final themeToggleStartTime = DateTime.now();

      final lightModeButtonFinder = find.byIcon(Icons.light_mode);
      final darkModeButtonFinder = find.byIcon(Icons.dark_mode);
      final themeButtonFinder =
          lightModeButtonFinder.evaluate().isNotEmpty
              ? lightModeButtonFinder
              : darkModeButtonFinder;
      if (themeButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(themeButtonFinder);
        await tester.pump();

        final themeToggleEndTime = DateTime.now();
        final themeToggleDuration = themeToggleEndTime.difference(
          themeToggleStartTime,
        );

        // Step 5: Verify theme toggle is responsive (under 200ms)
        expect(themeToggleDuration.inMilliseconds, lessThan(200));
      }
    });

    testWidgets('Export performance test', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Create a comparison for export
      final compareTabFinder = find.byKey(Key('compare_tab'));
      if (compareTabFinder.evaluate().isNotEmpty) {
        await tester.tap(compareTabFinder);
        await tester.pumpAndSettle();

        final topicDropdownFinder = find.byKey(Key('topic_dropdown'));
        if (topicDropdownFinder.evaluate().isNotEmpty) {
          await tester.tap(topicDropdownFinder);
          await tester.pumpAndSettle();

          final qualityTopicFinder = find.text('Quality Management');
          if (qualityTopicFinder.evaluate().isNotEmpty) {
            await tester.tap(qualityTopicFinder);
            await tester.pumpAndSettle();

            // Step 2: Measure export performance
            final exportStartTime = DateTime.now();

            final exportButtonFinder = find.byKey(Key('export_button'));
            if (exportButtonFinder.evaluate().isNotEmpty) {
              await tester.tap(exportButtonFinder);
              await tester.pumpAndSettle();

              final pdfExportFinder = find.byKey(Key('export_pdf_button'));
              if (pdfExportFinder.evaluate().isNotEmpty) {
                await tester.tap(pdfExportFinder);
                await tester.pumpAndSettle(Duration(seconds: 10));

                final exportEndTime = DateTime.now();
                final exportDuration = exportEndTime.difference(
                  exportStartTime,
                );

                // Step 3: Verify export completes in reasonable time (under 10 seconds)
                expect(exportDuration.inSeconds, lessThan(10));

                // Step 4: Verify export success indication
                final exportSuccessFinder = find.text('Export completed');
                if (exportSuccessFinder.evaluate().isNotEmpty) {
                  expect(exportSuccessFinder, findsOneWidget);
                }
              }
            }
          }
        }
      }
    });

    testWidgets('Concurrent operations performance test', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Start multiple concurrent operations
      final concurrentStartTime = DateTime.now();

      // Start search
      final searchBarFinder = find.byType(TextField);
      if (searchBarFinder.evaluate().isNotEmpty) {
        await tester.enterText(searchBarFinder.first, 'concurrent test');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        // Don't wait for completion
      }

      // Navigate to comparison while search is running
      final compareTabFinder = find.byKey(Key('compare_tab'));
      if (compareTabFinder.evaluate().isNotEmpty) {
        await tester.tap(compareTabFinder);
        // Don't wait for completion

        final topicDropdownFinder = find.byKey(Key('topic_dropdown'));
        if (topicDropdownFinder.evaluate().isNotEmpty) {
          await tester.tap(topicDropdownFinder);

          final riskTopicFinder = find.text('Risk and Uncertainty');
          if (riskTopicFinder.evaluate().isNotEmpty) {
            await tester.tap(riskTopicFinder);
            // Don't wait for completion
          }
        }
      }

      // Open a book while other operations are running
      final homeTabFinder = find.byKey(Key('home_tab'));
      if (homeTabFinder.evaluate().isNotEmpty) {
        await tester.tap(homeTabFinder);

        final pmbokTileFinder = find.byKey(Key('pmbok_tile'));
        if (pmbokTileFinder.evaluate().isNotEmpty) {
          await tester.tap(pmbokTileFinder);
        }
      }

      // Step 2: Wait for all operations to complete
      await tester.pumpAndSettle(Duration(seconds: 15));

      final concurrentEndTime = DateTime.now();
      final concurrentDuration = concurrentEndTime.difference(
        concurrentStartTime,
      );

      // Step 3: Verify concurrent operations complete in reasonable time (under 15 seconds)
      expect(concurrentDuration.inSeconds, lessThan(15));

      // Step 4: Verify app is still responsive after concurrent operations
      final responsiveTestStartTime = DateTime.now();

      final backButtonFinder = find.byKey(Key('back_button'));
      if (backButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(backButtonFinder);
        await tester.pumpAndSettle();

        final responsiveTestEndTime = DateTime.now();
        final responsiveDuration = responsiveTestEndTime.difference(
          responsiveTestStartTime,
        );

        // Step 5: Verify app remains responsive (under 1 second)
        expect(responsiveDuration.inMilliseconds, lessThan(1000));
      }
    });
  });
}
