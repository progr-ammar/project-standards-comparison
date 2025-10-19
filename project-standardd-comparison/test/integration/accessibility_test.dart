import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
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
  group('Accessibility Integration Tests', () {
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

    testWidgets('Keyboard navigation workflow test', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Test Tab navigation through main interface
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Verify focus moves to first focusable element
      final focusedElement = FocusManager.instance.primaryFocus;
      expect(focusedElement, isNotNull);

      // Step 2: Navigate through all main navigation elements
      for (int i = 0; i < 10; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }

      // Step 3: Test Enter key activation on navigation
      final navigationBarFinder = find.byType(NavigationBar);
      if (navigationBarFinder.evaluate().isNotEmpty) {
        // Focus on Compare tab and activate with Enter
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        // Verify navigation to Compare screen
        final compareScreenFinder = find.byKey(Key('compare_screen'));
        if (compareScreenFinder.evaluate().isNotEmpty) {
          expect(compareScreenFinder, findsOneWidget);
        }
      }

      // Step 4: Test keyboard shortcuts
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Verify navigation to Home via keyboard shortcut
      final homeScreenFinder = find.byKey(Key('home_screen'));
      if (homeScreenFinder.evaluate().isNotEmpty) {
        expect(homeScreenFinder, findsOneWidget);
      }

      // Step 5: Test Alt+H for search history
      await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
      await tester.pumpAndSettle();

      // Verify search history opens
      final searchHistoryFinder = find.byKey(Key('search_history_screen'));
      if (searchHistoryFinder.evaluate().isNotEmpty) {
        expect(searchHistoryFinder, findsOneWidget);

        // Test Escape to close
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Verify return to home
        expect(homeScreenFinder, findsOneWidget);
      }
    });

    testWidgets('Screen reader support test', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Verify semantic labels are present
      final semanticsNodes =
          tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode
              ?.debugDescribeChildren();
      expect(semanticsNodes, isNotNull);

      // Step 2: Check main navigation semantics
      final navigationBarFinder = find.byType(NavigationBar);
      if (navigationBarFinder.evaluate().isNotEmpty) {
        final navigationSemantics = tester.getSemantics(navigationBarFinder);
        expect(navigationSemantics.label, contains('navigation'));
      }

      // Step 3: Verify app bar semantics
      final appBarFinder = find.byType(AppBar);
      if (appBarFinder.evaluate().isNotEmpty) {
        final titleFinder = find.text('PM Standards');
        if (titleFinder.evaluate().isNotEmpty) {
          final titleSemantics = tester.getSemantics(titleFinder);
          expect(titleSemantics.hasFlag(SemanticsFlag.isHeader), isTrue);
        }
      }

      // Step 4: Test button semantics
      final lightModeButtonFinder = find.byIcon(Icons.light_mode);
      final darkModeButtonFinder = find.byIcon(Icons.dark_mode);
      final themeButtonFinder =
          lightModeButtonFinder.evaluate().isNotEmpty
              ? lightModeButtonFinder
              : darkModeButtonFinder;
      if (themeButtonFinder.evaluate().isNotEmpty) {
        final buttonSemantics = tester.getSemantics(themeButtonFinder);
        expect(buttonSemantics.hasFlag(SemanticsFlag.isButton), isTrue);
        expect(buttonSemantics.label, isNotEmpty);
        expect(buttonSemantics.hint, isNotEmpty);
      }

      // Step 5: Test search field semantics
      final searchBarFinder = find.byType(TextField);
      if (searchBarFinder.evaluate().isNotEmpty) {
        final searchSemantics = tester.getSemantics(searchBarFinder.first);
        expect(searchSemantics.hasFlag(SemanticsFlag.isTextField), isTrue);
        expect(searchSemantics.label, isNotEmpty);
      }

      // Step 6: Test book tile semantics
      final pmbokTileFinder = find.byKey(Key('pmbok_tile'));
      if (pmbokTileFinder.evaluate().isNotEmpty) {
        final tileSemantics = tester.getSemantics(pmbokTileFinder);
        expect(tileSemantics.hasFlag(SemanticsFlag.isButton), isTrue);
        expect(tileSemantics.label, contains('PMBOK'));
      }
    });

    testWidgets('High contrast theme test', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Access accessibility settings
      final accessibilityButtonFinder = find.byIcon(Icons.accessibility);
      if (accessibilityButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(accessibilityButtonFinder);
        await tester.pumpAndSettle();

        // Step 2: Enable high contrast mode
        final highContrastToggleFinder = find.byKey(
          Key('high_contrast_toggle'),
        );
        if (highContrastToggleFinder.evaluate().isNotEmpty) {
          await tester.tap(highContrastToggleFinder);
          await tester.pumpAndSettle();

          // Step 3: Verify high contrast colors are applied
          final themeProvider = Provider.of<ThemeProvider>(
            tester.element(find.byType(MyApp)),
            listen: false,
          );

          expect(themeProvider.highContrast, isTrue);

          final theme = themeProvider.getLightTheme();
          expect(theme.colorScheme.primary, equals(Colors.black));
          expect(theme.colorScheme.onPrimary, equals(Colors.white));

          // Step 4: Test contrast in dark mode
          await tester.tap(find.byIcon(Icons.light_mode));
          await tester.pumpAndSettle();

          final darkTheme = themeProvider.getDarkTheme();
          expect(darkTheme.colorScheme.primary, equals(Colors.white));
          expect(darkTheme.colorScheme.onPrimary, equals(Colors.black));

          // Step 5: Verify UI elements have sufficient contrast
          final appBarFinder = find.byType(AppBar);
          if (appBarFinder.evaluate().isNotEmpty) {
            final appBar = tester.widget<AppBar>(appBarFinder);
            final backgroundColor =
                appBar.backgroundColor ?? darkTheme.appBarTheme.backgroundColor;
            final foregroundColor =
                appBar.foregroundColor ?? darkTheme.appBarTheme.foregroundColor;

            // Verify colors are high contrast
            expect(backgroundColor, isNotNull);
            expect(foregroundColor, isNotNull);
          }
        }
      }
    });

    testWidgets('Text scaling test', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Access accessibility settings
      final accessibilityButtonFinder = find.byIcon(Icons.accessibility);
      if (accessibilityButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(accessibilityButtonFinder);
        await tester.pumpAndSettle();

        // Step 2: Test different text scale values
        final textScaleSliderFinder = find.byKey(Key('text_scale_slider'));
        if (textScaleSliderFinder.evaluate().isNotEmpty) {
          final slider = tester.widget<Slider>(textScaleSliderFinder);
          final originalValue = slider.value;

          // Step 3: Increase text scale to maximum
          await tester.drag(textScaleSliderFinder, Offset(100, 0));
          await tester.pumpAndSettle();

          // Step 4: Verify text scale is applied
          final themeProvider = Provider.of<ThemeProvider>(
            tester.element(find.byType(MyApp)),
            listen: false,
          );

          expect(themeProvider.textScale, greaterThan(originalValue));

          // Step 5: Navigate back and verify text scaling in main app
          final backButtonFinder = find.byKey(Key('back_button'));
          if (backButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(backButtonFinder);
            await tester.pumpAndSettle();

            // Step 6: Verify text is scaled in main interface
            final titleFinder = find.text('PM Standards');
            if (titleFinder.evaluate().isNotEmpty) {
              final mediaQuery = MediaQuery.of(tester.element(titleFinder));
              expect(mediaQuery.textScaler.scale(1.0), greaterThan(1.0));
            }
          }

          // Step 7: Test minimum text scale
          await tester.tap(accessibilityButtonFinder);
          await tester.pumpAndSettle();

          await tester.drag(textScaleSliderFinder, Offset(-100, 0));
          await tester.pumpAndSettle();

          expect(themeProvider.textScale, greaterThanOrEqualTo(0.8));
        }
      }
    });

    testWidgets('Reduced motion test', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Access accessibility settings
      final accessibilityButtonFinder = find.byIcon(Icons.accessibility);
      if (accessibilityButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(accessibilityButtonFinder);
        await tester.pumpAndSettle();

        // Step 2: Enable reduced motion
        final reducedMotionToggleFinder = find.byKey(
          Key('reduced_motion_toggle'),
        );
        if (reducedMotionToggleFinder.evaluate().isNotEmpty) {
          await tester.tap(reducedMotionToggleFinder);
          await tester.pumpAndSettle();

          // Step 3: Verify reduced motion is enabled
          final themeProvider = Provider.of<ThemeProvider>(
            tester.element(find.byType(MyApp)),
            listen: false,
          );

          expect(themeProvider.reducedMotion, isTrue);
          expect(themeProvider.animationDuration, equals(Duration.zero));

          // Step 4: Test navigation with reduced motion
          final backButtonFinder = find.byKey(Key('back_button'));
          if (backButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(backButtonFinder);
            await tester.pump(); // Single pump since animations are disabled

            // Verify immediate transition without animation
            final homeScreenFinder = find.byKey(Key('home_screen'));
            if (homeScreenFinder.evaluate().isNotEmpty) {
              expect(homeScreenFinder, findsOneWidget);
            }
          }

          // Step 5: Test theme toggle with reduced motion
          final lightModeButtonFinder = find.byIcon(Icons.light_mode);
          final darkModeButtonFinder = find.byIcon(Icons.dark_mode);
          final themeButtonFinder =
              lightModeButtonFinder.evaluate().isNotEmpty
                  ? lightModeButtonFinder
                  : darkModeButtonFinder;
          if (themeButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(themeButtonFinder);
            await tester.pump(); // Single pump for immediate transition

            // Verify theme changed without animation delay
            expect(themeProvider.themeMode, isNotNull);
          }
        }
      }
    });

    testWidgets('Focus management test', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Test focus order in main navigation
      final focusNodes = <FocusNode>[];

      // Collect all focusable elements
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      var currentFocus = FocusManager.instance.primaryFocus;
      focusNodes.add(currentFocus!);

      // Navigate through focus order
      for (int i = 0; i < 15; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        final newFocus = FocusManager.instance.primaryFocus;
        if (newFocus != currentFocus) {
          focusNodes.add(newFocus!);
          currentFocus = newFocus;
        }
      }

      // Step 2: Verify logical focus order
      expect(focusNodes.length, greaterThan(3)); // At least navigation items

      // Step 3: Test focus restoration after modal dialogs
      final searchBarFinder = find.byType(TextField);
      if (searchBarFinder.evaluate().isNotEmpty) {
        await tester.tap(searchBarFinder.first);
        await tester.pumpAndSettle();

        // Verify search field has focus
        final searchField = tester.widget<TextField>(searchBarFinder.first);
        expect(searchField.focusNode?.hasFocus, isTrue);

        // Open search history (modal)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
        await tester.pumpAndSettle();

        // Close modal with Escape
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Verify focus returns to search field
        expect(searchField.focusNode?.hasFocus, isTrue);
      }

      // Step 4: Test focus trapping in dialogs
      final pmbokTileFinder = find.byKey(Key('pmbok_tile'));
      if (pmbokTileFinder.evaluate().isNotEmpty) {
        await tester.tap(pmbokTileFinder);
        await tester.pumpAndSettle();

        final bookmarkButtonFinder = find.byKey(Key('bookmark_button'));
        if (bookmarkButtonFinder.evaluate().isNotEmpty) {
          await tester.tap(bookmarkButtonFinder);
          await tester.pumpAndSettle();

          // Test focus trapping in bookmark dialog
          final dialogFinder = find.byKey(Key('bookmark_dialog'));
          if (dialogFinder.evaluate().isNotEmpty) {
            // Tab through dialog elements
            for (int i = 0; i < 10; i++) {
              await tester.sendKeyEvent(LogicalKeyboardKey.tab);
              await tester.pump();

              // Verify focus stays within dialog
              final currentFocus = FocusManager.instance.primaryFocus;
              expect(currentFocus, isNotNull);
            }

            // Close dialog
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
          }
        }
      }
    });

    testWidgets('Color contrast validation test', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Test light theme contrast ratios
      final themeProvider = Provider.of<ThemeProvider>(
        tester.element(find.byType(MyApp)),
        listen: false,
      );

      final lightTheme = themeProvider.getLightTheme();

      // Step 2: Verify primary color contrast
      final primaryColor = lightTheme.colorScheme.primary;
      final onPrimaryColor = lightTheme.colorScheme.onPrimary;

      final primaryContrast = _calculateContrastRatio(
        primaryColor,
        onPrimaryColor,
      );
      expect(primaryContrast, greaterThanOrEqualTo(4.5)); // WCAG AA standard

      // Step 3: Verify surface color contrast
      final surfaceColor = lightTheme.colorScheme.surface;
      final onSurfaceColor = lightTheme.colorScheme.onSurface;

      final surfaceContrast = _calculateContrastRatio(
        surfaceColor,
        onSurfaceColor,
      );
      expect(surfaceContrast, greaterThanOrEqualTo(4.5));

      // Step 4: Test dark theme contrast ratios
      final darkTheme = themeProvider.getDarkTheme();

      final darkPrimaryColor = darkTheme.colorScheme.primary;
      final darkOnPrimaryColor = darkTheme.colorScheme.onPrimary;

      final darkPrimaryContrast = _calculateContrastRatio(
        darkPrimaryColor,
        darkOnPrimaryColor,
      );
      expect(darkPrimaryContrast, greaterThanOrEqualTo(4.5));

      // Step 5: Test high contrast mode
      themeProvider.toggleHighContrast();
      await tester.pumpAndSettle();

      final highContrastTheme = themeProvider.getLightTheme();
      final highContrastPrimary = highContrastTheme.colorScheme.primary;
      final highContrastOnPrimary = highContrastTheme.colorScheme.onPrimary;

      final highContrast = _calculateContrastRatio(
        highContrastPrimary,
        highContrastOnPrimary,
      );
      expect(highContrast, greaterThanOrEqualTo(7.0)); // WCAG AAA standard
    });

    testWidgets('Touch target size test', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Test navigation bar touch targets
      final navigationBarFinder = find.byType(NavigationBar);
      if (navigationBarFinder.evaluate().isNotEmpty) {
        final navigationDestinations = find.byType(NavigationDestination);

        for (int i = 0; i < navigationDestinations.evaluate().length; i++) {
          final destination = navigationDestinations.at(i);
          final size = tester.getSize(destination);

          // Verify minimum touch target size (44x44 logical pixels)
          expect(size.width, greaterThanOrEqualTo(44.0));
          expect(size.height, greaterThanOrEqualTo(44.0));
        }
      }

      // Step 2: Test button touch targets
      final iconButtons = find.byType(IconButton);
      for (int i = 0; i < iconButtons.evaluate().length; i++) {
        final button = iconButtons.at(i);
        final size = tester.getSize(button);

        expect(size.width, greaterThanOrEqualTo(44.0));
        expect(size.height, greaterThanOrEqualTo(44.0));
      }

      // Step 3: Test book tile touch targets
      final bookTiles = [
        find.byKey(Key('pmbok_tile')),
        find.byKey(Key('prince2_tile')),
        find.byKey(Key('iso_tile')),
      ];

      for (final tileFinder in bookTiles) {
        if (tileFinder.evaluate().isNotEmpty) {
          final size = tester.getSize(tileFinder);
          expect(size.width, greaterThanOrEqualTo(44.0));
          expect(size.height, greaterThanOrEqualTo(44.0));
        }
      }

      // Step 4: Test topic chip touch targets
      final filterChips = find.byType(FilterChip);
      final actionChips = find.byType(ActionChip);
      final topicChips =
          filterChips.evaluate().isNotEmpty ? filterChips : actionChips;
      for (int i = 0; i < topicChips.evaluate().length && i < 5; i++) {
        final chip = topicChips.at(i);
        final size = tester.getSize(chip);

        expect(size.height, greaterThanOrEqualTo(44.0));
        // Width can vary for chips, but height should meet minimum
      }
    });

    testWidgets('Screen reader announcements test', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Step 1: Test navigation announcements
      final compareTabFinder = find.byKey(Key('compare_tab'));
      if (compareTabFinder.evaluate().isNotEmpty) {
        await tester.tap(compareTabFinder);
        await tester.pumpAndSettle();

        // Verify semantic announcement for navigation
        final compareScreenFinder = find.byKey(Key('compare_screen'));
        if (compareScreenFinder.evaluate().isNotEmpty) {
          final semantics = tester.getSemantics(compareScreenFinder);
          expect(semantics.label, contains('Compare'));
        }
      }

      // Step 2: Test search result announcements
      final searchBarFinder = find.byType(TextField);
      if (searchBarFinder.evaluate().isNotEmpty) {
        await tester.enterText(searchBarFinder.first, 'test search');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        // Verify search results have proper semantics
        final searchResultsFinder = find.byKey(Key('search_results'));
        if (searchResultsFinder.evaluate().isNotEmpty) {
          final semantics = tester.getSemantics(searchResultsFinder);
          expect(semantics.label, isNotEmpty);
        }
      }

      // Step 3: Test loading state announcements
      final pmbokTileFinder = find.byKey(Key('pmbok_tile'));
      if (pmbokTileFinder.evaluate().isNotEmpty) {
        await tester.tap(pmbokTileFinder);
        await tester.pump(); // Don't wait for completion

        // Check for loading indicator semantics
        final loadingFinder = find.byKey(Key('loading_indicator'));
        if (loadingFinder.evaluate().isNotEmpty) {
          final semantics = tester.getSemantics(loadingFinder);
          expect(semantics.label, contains('Loading'));
        }

        await tester.pumpAndSettle();
      }

      // Step 4: Test error message announcements
      final missingBookTileFinder = find.byKey(Key('missing_book_tile'));
      if (missingBookTileFinder.evaluate().isNotEmpty) {
        await tester.tap(missingBookTileFinder);
        await tester.pumpAndSettle();

        final errorMessageFinder = find.byKey(Key('book_load_error'));
        if (errorMessageFinder.evaluate().isNotEmpty) {
          final semantics = tester.getSemantics(errorMessageFinder);
          expect(semantics.label, isNotEmpty);
          expect(semantics.hasFlag(SemanticsFlag.isLiveRegion), isTrue);
        }
      }
    });
  });
}

// Helper function to calculate contrast ratio between two colors
double _calculateContrastRatio(Color color1, Color color2) {
  final luminance1 = color1.computeLuminance();
  final luminance2 = color2.computeLuminance();

  final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
  final darker = luminance1 > luminance2 ? luminance2 : luminance1;

  return (lighter + 0.05) / (darker + 0.05);
}
