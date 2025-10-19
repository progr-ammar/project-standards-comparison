import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/theme_provider.dart';
import 'providers/bookmarks_provider.dart';
import 'providers/search_provider.dart';
import 'providers/index_provider.dart';
import 'providers/topic_provider.dart';
import 'providers/comparison_provider.dart';
import 'providers/generate_provider.dart';
import 'screens/home_screen.dart';
import 'screens/compare_screen.dart';
import 'screens/generate_screen.dart';
import 'screens/accessibility_settings_screen.dart';
import 'widgets/search_history_manager.dart';
import 'widgets/accessibility_helper.dart';
import 'screens/parallel_search_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPrefs = await SharedPreferences.getInstance();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(sharedPrefs)),
        ChangeNotifierProvider(create: (_) => BookmarksProvider(sharedPrefs)),
        ChangeNotifierProvider(create: (_) => SearchProvider(sharedPrefs)),
        ChangeNotifierProvider(create: (_) => IndexProvider()..init()),
        ChangeNotifierProvider(create: (_) => TopicProvider(sharedPrefs)),
        ChangeNotifierProvider(create: (_) => ComparisonProvider(sharedPrefs)),
        ChangeNotifierProvider(create: (_) => GenerateProvider(sharedPrefs)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _currentIndex = 0;
  final List<FocusNode> _navigationFocusNodes = [];
  late final FocusNode _skipLinkFocusNode;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _skipLinkFocusNode = FocusNode();
    // Create focus nodes for navigation items
    for (int i = 0; i < 3; i++) {
      _navigationFocusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    _skipLinkFocusNode.dispose();
    for (final node in _navigationFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _showSearchHistory(BuildContext context) async {
    final selectedSearch = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const SearchHistoryScreen()),
    );

    if (selectedSearch != null && selectedSearch.isNotEmpty && mounted) {
      // Navigate to search results
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ParallelSearchScreen(query: selectedSearch),
        ),
      );
    }
  }

  void _showAccessibilitySettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AccessibilitySettingsScreen()),
    );
  }

  void _skipToContent() {
    // Focus on the first interactive element in the current page
    if (_navigationFocusNodes.isNotEmpty) {
      _navigationFocusNodes[_currentIndex].requestFocus();
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    // Handle global keyboard shortcuts
    if (event is KeyDownEvent) {
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
      final isAltPressed = HardwareKeyboard.instance.isAltPressed;

      if (isCtrlPressed) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.digit1:
            setState(() => _currentIndex = 0);
            AccessibilityHelper.announceToScreenReader(
              context,
              'Navigated to Home',
            );
            break;
          case LogicalKeyboardKey.digit2:
            setState(() => _currentIndex = 1);
            AccessibilityHelper.announceToScreenReader(
              context,
              'Navigated to Compare',
            );
            break;
          case LogicalKeyboardKey.digit3:
            setState(() => _currentIndex = 2);
            AccessibilityHelper.announceToScreenReader(
              context,
              'Navigated to Generate',
            );
            break;
        }
      }

      if (isAltPressed) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.keyH:
            _showSearchHistory(context);
            break;
          case LogicalKeyboardKey.keyA:
            // Show accessibility info via dialog instead
            if (mounted) {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Accessibility Settings'),
                      content: const Text(
                        'Accessibility features are built into the app:\n\n• Keyboard navigation with Tab\n• Screen reader support\n• High contrast themes\n• Focus indicators',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
              );
            }
            break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final pages = <Widget>[
      const HomeScreen(),
      const CompareScreen(),
      const GenerateScreen(),
    ];

    return MaterialApp(
      title: 'PM Standards',
      themeMode: themeProvider.themeMode,
      theme: themeProvider.getLightTheme(),
      darkTheme: themeProvider.getDarkTheme(),
      builder: (context, child) {
        // Apply text scaling from accessibility settings
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(themeProvider.textScale)),
          child: child!,
        );
      },
      home: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKeyEvent,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Semantics(header: true, child: const Text('PM Standards')),
            actions: [
              Semantics(
                label: 'Search history. Keyboard shortcut: Alt + H',
                button: true,
                child: IconButton(
                  tooltip: 'Search history (Alt+H)',
                  icon: const Icon(Icons.history),
                  onPressed: () => _showSearchHistory(context),
                ),
              ),
              Semantics(
                label: 'Accessibility settings. Keyboard shortcut: Alt + A',
                button: true,
                child: IconButton(
                  tooltip: 'Accessibility settings (Alt+A)',
                  icon: const Icon(Icons.accessibility),
                  onPressed: () {
                    // Show a simple dialog instead of navigating
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Accessibility Settings'),
                            content: const Text(
                              'Accessibility features are built into the app:\n\n• Keyboard navigation with Tab\n• Screen reader support\n• High contrast themes\n• Focus indicators',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ),
              Semantics(
                label: 'Toggle theme between light and dark mode',
                button: true,
                child: IconButton(
                  tooltip: 'Toggle theme',
                  icon: Icon(
                    themeProvider.themeMode == ThemeMode.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  onPressed: () => themeProvider.toggleThemeMode(),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Skip link for keyboard navigation
              AccessibilityHelper.skipLink(
                text: 'Skip to main content',
                onPressed: _skipToContent,
                focusNode: _skipLinkFocusNode,
              ),

              // Main content
              SafeArea(
                child: Semantics(
                  label:
                      'Main content area. Current page: ${_getPageName(_currentIndex)}',
                  child: pages[_currentIndex],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Semantics(
            label: 'Main navigation',
            child: NavigationBar(
              selectedIndex: _currentIndex,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: 'Home',
                  tooltip: 'Home (Ctrl+1)',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.compare_arrows_outlined),
                  selectedIcon: const Icon(Icons.compare_arrows),
                  label: 'Compare',
                  tooltip: 'Compare (Ctrl+2)',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.auto_graph_outlined),
                  selectedIcon: const Icon(Icons.auto_graph),
                  label: 'Generate',
                  tooltip: 'Generate (Ctrl+3)',
                ),
              ],
              onDestinationSelected: (i) {
                setState(() => _currentIndex = i);
                AccessibilityHelper.announceToScreenReader(
                  context,
                  'Navigated to ${_getPageName(i)}',
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _getPageName(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Compare';
      case 2:
        return 'Generate';
      default:
        return 'Unknown';
    }
  }
}
