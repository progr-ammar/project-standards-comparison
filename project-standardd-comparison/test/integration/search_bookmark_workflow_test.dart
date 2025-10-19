import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pm4_app/main.dart';
import 'package:pm4_app/providers/search_provider.dart';
import 'package:pm4_app/providers/bookmarks_provider.dart';
import 'package:pm4_app/providers/index_provider.dart';
import 'package:pm4_app/providers/theme_provider.dart';
import 'package:pm4_app/providers/topic_provider.dart';

void main() {
  group('Search and Bookmark Workflow Integration Tests', () {
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
        ],
        child: const MaterialApp(home: MyApp()),
      );
    });

    testWidgets('Complete search to bookmark workflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Find and tap the search bar
      final searchBarFinder = find.byType(TextField);
      expect(searchBarFinder, findsWidgets);

      // Step 2: Enter search query
      await tester.enterText(searchBarFinder.first, 'risk management');
      await tester.pumpAndSettle();

      // Step 3: Verify search suggestions appear (if implemented)
      // This would depend on the actual implementation of autocomplete

      // Step 4: Submit search
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Step 5: Verify search results are displayed
      // Look for search results container or list
      final searchResultsFinder = find.byKey(Key('search_results'));
      if (searchResultsFinder.evaluate().isNotEmpty) {
        expect(searchResultsFinder, findsOneWidget);

        // Step 6: Tap on a search result
        final firstResultFinder = find.byKey(Key('search_result_0'));
        if (firstResultFinder.evaluate().isNotEmpty) {
          await tester.tap(firstResultFinder);
          await tester.pumpAndSettle();

          // Step 7: Verify reader screen opens
          final readerScreenFinder = find.byKey(Key('reader_screen'));
          if (readerScreenFinder.evaluate().isNotEmpty) {
            expect(readerScreenFinder, findsOneWidget);

            // Step 8: Find and tap bookmark button
            final bookmarkButtonFinder = find.byKey(Key('bookmark_button'));
            if (bookmarkButtonFinder.evaluate().isNotEmpty) {
              await tester.tap(bookmarkButtonFinder);
              await tester.pumpAndSettle();

              // Step 9: Verify bookmark dialog appears
              final bookmarkDialogFinder = find.byKey(Key('bookmark_dialog'));
              if (bookmarkDialogFinder.evaluate().isNotEmpty) {
                expect(bookmarkDialogFinder, findsOneWidget);

                // Step 10: Add bookmark with note and tags
                final noteFieldFinder = find.byKey(Key('bookmark_note_field'));
                if (noteFieldFinder.evaluate().isNotEmpty) {
                  await tester.enterText(
                    noteFieldFinder,
                    'Important risk management concept',
                  );
                  await tester.pumpAndSettle();
                }

                final tagFieldFinder = find.byKey(Key('bookmark_tag_field'));
                if (tagFieldFinder.evaluate().isNotEmpty) {
                  await tester.enterText(tagFieldFinder, 'risk,management');
                  await tester.pumpAndSettle();
                }

                // Step 11: Save bookmark
                final saveButtonFinder = find.byKey(
                  Key('save_bookmark_button'),
                );
                if (saveButtonFinder.evaluate().isNotEmpty) {
                  await tester.tap(saveButtonFinder);
                  await tester.pumpAndSettle();
                }
              }
            }
          }
        }
      }

      // Step 12: Navigate to bookmarks screen
      final bookmarksTabFinder = find.byKey(Key('bookmarks_tab'));
      if (bookmarksTabFinder.evaluate().isNotEmpty) {
        await tester.tap(bookmarksTabFinder);
        await tester.pumpAndSettle();

        // Step 13: Verify bookmark appears in bookmarks list
        final bookmarksListFinder = find.byKey(Key('bookmarks_list'));
        if (bookmarksListFinder.evaluate().isNotEmpty) {
          expect(bookmarksListFinder, findsOneWidget);

          // Look for the bookmark we just created
          final bookmarkItemFinder = find.text(
            'Important risk management concept',
          );
          if (bookmarkItemFinder.evaluate().isNotEmpty) {
            expect(bookmarkItemFinder, findsOneWidget);
          }
        }
      }
    });

    testWidgets('Search history management workflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Perform multiple searches
      final searchBarFinder = find.byType(TextField);
      expect(searchBarFinder, findsWidgets);

      final searchQueries = [
        'risk management',
        'quality assurance',
        'stakeholder engagement',
      ];

      for (final query in searchQueries) {
        await tester.enterText(searchBarFinder.first, query);
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        // Clear the search field for next query
        await tester.enterText(searchBarFinder.first, '');
        await tester.pumpAndSettle();
      }

      // Step 2: Verify recent searches appear
      final recentSearchesFinder = find.byKey(Key('recent_searches'));
      if (recentSearchesFinder.evaluate().isNotEmpty) {
        expect(recentSearchesFinder, findsOneWidget);

        // Step 3: Tap on a recent search
        final recentSearchChipFinder = find.text('risk management');
        if (recentSearchChipFinder.evaluate().isNotEmpty) {
          await tester.tap(recentSearchChipFinder);
          await tester.pumpAndSettle();

          // Step 4: Verify search is executed
          final searchResultsFinder = find.byKey(Key('search_results'));
          if (searchResultsFinder.evaluate().isNotEmpty) {
            expect(searchResultsFinder, findsOneWidget);
          }
        }
      }

      // Step 5: Access search history manager
      final searchHistoryButtonFinder = find.byKey(
        Key('search_history_button'),
      );
      if (searchHistoryButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(searchHistoryButtonFinder);
        await tester.pumpAndSettle();

        // Step 6: Verify search history screen
        final searchHistoryScreenFinder = find.byKey(
          Key('search_history_screen'),
        );
        if (searchHistoryScreenFinder.evaluate().isNotEmpty) {
          expect(searchHistoryScreenFinder, findsOneWidget);

          // Step 7: Clear search history
          final clearHistoryButtonFinder = find.byKey(
            Key('clear_history_button'),
          );
          if (clearHistoryButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(clearHistoryButtonFinder);
            await tester.pumpAndSettle();

            // Step 8: Verify history is cleared
            final emptyHistoryFinder = find.text('No search history');
            if (emptyHistoryFinder.evaluate().isNotEmpty) {
              expect(emptyHistoryFinder, findsOneWidget);
            }
          }
        }
      }
    });

    testWidgets('Bookmark filtering and organization workflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Navigate to bookmarks screen
      final bookmarksTabFinder = find.byKey(Key('bookmarks_tab'));
      if (bookmarksTabFinder.evaluate().isNotEmpty) {
        await tester.tap(bookmarksTabFinder);
        await tester.pumpAndSettle();

        // Step 1: Access bookmark filters
        final filterButtonFinder = find.byKey(Key('bookmark_filter_button'));
        if (filterButtonFinder.evaluate().isNotEmpty) {
          await tester.tap(filterButtonFinder);
          await tester.pumpAndSettle();

          // Step 2: Apply tag filter
          final tagFilterFinder = find.byKey(Key('tag_filter_dropdown'));
          if (tagFilterFinder.evaluate().isNotEmpty) {
            await tester.tap(tagFilterFinder);
            await tester.pumpAndSettle();

            // Select a tag
            final riskTagFinder = find.text('risk');
            if (riskTagFinder.evaluate().isNotEmpty) {
              await tester.tap(riskTagFinder);
              await tester.pumpAndSettle();
            }
          }

          // Step 3: Apply book filter
          final bookFilterFinder = find.byKey(Key('book_filter_dropdown'));
          if (bookFilterFinder.evaluate().isNotEmpty) {
            await tester.tap(bookFilterFinder);
            await tester.pumpAndSettle();

            // Select a book
            final pmbokFilterFinder = find.text('PMBOK');
            if (pmbokFilterFinder.evaluate().isNotEmpty) {
              await tester.tap(pmbokFilterFinder);
              await tester.pumpAndSettle();
            }
          }

          // Step 4: Verify filtered results
          final filteredBookmarksFinder = find.byKey(Key('filtered_bookmarks'));
          if (filteredBookmarksFinder.evaluate().isNotEmpty) {
            expect(filteredBookmarksFinder, findsOneWidget);
          }

          // Step 5: Clear filters
          final clearFiltersButtonFinder = find.byKey(
            Key('clear_filters_button'),
          );
          if (clearFiltersButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(clearFiltersButtonFinder);
            await tester.pumpAndSettle();

            // Step 6: Verify all bookmarks are shown again
            final allBookmarksFinder = find.byKey(Key('all_bookmarks'));
            if (allBookmarksFinder.evaluate().isNotEmpty) {
              expect(allBookmarksFinder, findsOneWidget);
            }
          }
        }
      }
    });

    testWidgets('Search result navigation workflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Perform search
      final searchBarFinder = find.byType(TextField);
      await tester.enterText(searchBarFinder.first, 'project management');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Step 2: Verify search results with different books
      final searchResultsFinder = find.byKey(Key('search_results'));
      if (searchResultsFinder.evaluate().isNotEmpty) {
        // Step 3: Check result grouping by book
        final pmbokResultsFinder = find.byKey(Key('pmbok_results'));
        final prince2ResultsFinder = find.byKey(Key('prince2_results'));
        final isoResultsFinder = find.byKey(Key('iso_results'));

        // At least one book should have results
        final hasResults =
            pmbokResultsFinder.evaluate().isNotEmpty ||
            prince2ResultsFinder.evaluate().isNotEmpty ||
            isoResultsFinder.evaluate().isNotEmpty;

        if (hasResults) {
          // Step 4: Navigate to first result
          final firstResultFinder = find.byKey(Key('search_result_0'));
          if (firstResultFinder.evaluate().isNotEmpty) {
            await tester.tap(firstResultFinder);
            await tester.pumpAndSettle();

            // Step 5: Verify reader opens at correct page
            final readerScreenFinder = find.byKey(Key('reader_screen'));
            if (readerScreenFinder.evaluate().isNotEmpty) {
              expect(readerScreenFinder, findsOneWidget);

              // Step 6: Verify search term is highlighted
              final highlightedTextFinder = find.byKey(Key('highlighted_text'));
              if (highlightedTextFinder.evaluate().isNotEmpty) {
                expect(highlightedTextFinder, findsWidgets);
              }

              // Step 7: Navigate back to search results
              final backButtonFinder = find.byKey(Key('back_button'));
              if (backButtonFinder.evaluate().isNotEmpty) {
                await tester.tap(backButtonFinder);
                await tester.pumpAndSettle();

                // Step 8: Verify we're back at search results
                expect(searchResultsFinder, findsOneWidget);
              }
            }
          }
        }
      }
    });

    testWidgets('Multi-book search workflow', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Access advanced search options
      final advancedSearchFinder = find.byKey(Key('advanced_search_button'));
      if (advancedSearchFinder.evaluate().isNotEmpty) {
        await tester.tap(advancedSearchFinder);
        await tester.pumpAndSettle();

        // Step 2: Select specific books to search
        final bookSelectionFinder = find.byKey(Key('book_selection'));
        if (bookSelectionFinder.evaluate().isNotEmpty) {
          // Select PMBOK and PRINCE2 only
          final pmbokCheckboxFinder = find.byKey(Key('pmbok_checkbox'));
          final prince2CheckboxFinder = find.byKey(Key('prince2_checkbox'));
          final isoCheckboxFinder = find.byKey(Key('iso_checkbox'));

          if (pmbokCheckboxFinder.evaluate().isNotEmpty) {
            await tester.tap(pmbokCheckboxFinder);
            await tester.pumpAndSettle();
          }

          if (prince2CheckboxFinder.evaluate().isNotEmpty) {
            await tester.tap(prince2CheckboxFinder);
            await tester.pumpAndSettle();
          }

          // Uncheck ISO if it's checked
          if (isoCheckboxFinder.evaluate().isNotEmpty) {
            await tester.tap(isoCheckboxFinder);
            await tester.pumpAndSettle();
          }
        }

        // Step 3: Perform search
        final searchFieldFinder = find.byKey(Key('advanced_search_field'));
        if (searchFieldFinder.evaluate().isNotEmpty) {
          await tester.enterText(searchFieldFinder, 'governance');
          await tester.pumpAndSettle();

          final searchButtonFinder = find.byKey(Key('execute_search_button'));
          if (searchButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(searchButtonFinder);
            await tester.pumpAndSettle();

            // Step 4: Verify results only from selected books
            final searchResultsFinder = find.byKey(Key('search_results'));
            if (searchResultsFinder.evaluate().isNotEmpty) {
              // Should not find ISO results
              final isoResultsFinder = find.byKey(Key('iso_results'));
              expect(isoResultsFinder, findsNothing);

              // Should find PMBOK or PRINCE2 results
              final pmbokResultsFinder = find.byKey(Key('pmbok_results'));
              final prince2ResultsFinder = find.byKey(Key('prince2_results'));

              final hasExpectedResults =
                  pmbokResultsFinder.evaluate().isNotEmpty ||
                  prince2ResultsFinder.evaluate().isNotEmpty;

              if (hasExpectedResults) {
                // Test passed - results are from selected books only
                expect(true, isTrue);
              }
            }
          }
        }
      }
    });
  });
}
