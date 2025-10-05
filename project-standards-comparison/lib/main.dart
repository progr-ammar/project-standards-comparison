import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/theme_provider.dart';
import 'providers/bookmarks_provider.dart';
import 'providers/search_provider.dart';
import 'providers/index_provider.dart';
import 'screens/home_screen.dart';
import 'screens/compare_screen.dart';
import 'screens/generate_screen.dart';

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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PM Standards'),
          actions: [
            IconButton(
              tooltip: 'Toggle theme',
              icon: Icon(
                themeProvider.themeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              onPressed: () => themeProvider.toggleThemeMode(),
            ),
          ],
        ),
        body: SafeArea(child: pages[_currentIndex]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.compare_arrows_outlined),
              selectedIcon: Icon(Icons.compare_arrows),
              label: 'Compare',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_graph_outlined),
              selectedIcon: Icon(Icons.auto_graph),
              label: 'Generate',
            ),
          ],
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}
