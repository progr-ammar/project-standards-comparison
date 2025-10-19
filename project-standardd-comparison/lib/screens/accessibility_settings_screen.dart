import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../widgets/accessibility_helper.dart';

class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility Settings')),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Theme Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visual Settings',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      // Theme Mode
                      ListTile(
                        title: const Text('Theme Mode'),
                        subtitle: Text(
                          _getThemeModeDescription(themeProvider.themeMode),
                        ),
                        trailing: DropdownButton<ThemeMode>(
                          value: themeProvider.themeMode,
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('System'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Light'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Dark'),
                            ),
                          ],
                          onChanged: (mode) {
                            if (mode != null) {
                              themeProvider.setThemeMode(mode);
                            }
                          },
                        ),
                      ),

                      // High Contrast
                      SwitchListTile(
                        title: const Text('High Contrast'),
                        subtitle: const Text(
                          'Increase color contrast for better visibility',
                        ),
                        value: themeProvider.highContrast,
                        onChanged: (_) => themeProvider.toggleHighContrast(),
                      ),

                      // Text Scale
                      ListTile(
                        title: const Text('Text Size'),
                        subtitle: Text(
                          'Current: ${(themeProvider.textScale * 100).round()}%',
                        ),
                      ),
                      Slider(
                        value: themeProvider.textScale,
                        min: 0.8,
                        max: 2.0,
                        divisions: 12,
                        label: '${(themeProvider.textScale * 100).round()}%',
                        onChanged: themeProvider.setTextScale,
                      ),

                      // Reduced Motion
                      SwitchListTile(
                        title: const Text('Reduce Motion'),
                        subtitle: const Text(
                          'Minimize animations and transitions',
                        ),
                        value: themeProvider.reducedMotion,
                        onChanged: (_) => themeProvider.toggleReducedMotion(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Keyboard Navigation
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keyboard Navigation',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      const ListTile(
                        leading: Icon(Icons.keyboard),
                        title: Text('Tab'),
                        subtitle: Text('Navigate between elements'),
                      ),
                      const ListTile(
                        leading: Icon(Icons.keyboard),
                        title: Text('Enter/Space'),
                        subtitle: Text('Activate buttons and links'),
                      ),
                      const ListTile(
                        leading: Icon(Icons.keyboard),
                        title: Text('Ctrl + 1, 2, 3'),
                        subtitle: Text('Switch between main sections'),
                      ),
                      const ListTile(
                        leading: Icon(Icons.keyboard),
                        title: Text('Alt + H'),
                        subtitle: Text('Open search history'),
                      ),
                      const ListTile(
                        leading: Icon(Icons.keyboard),
                        title: Text('Alt + A'),
                        subtitle: Text('Open accessibility settings'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Screen Reader Support
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Screen Reader Support',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'This app is optimized for screen readers with:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),

                      const ListTile(
                        leading: Icon(Icons.check),
                        title: Text(
                          'Semantic labels for all interactive elements',
                        ),
                        dense: true,
                      ),
                      const ListTile(
                        leading: Icon(Icons.check),
                        title: Text('Proper heading hierarchy'),
                        dense: true,
                      ),
                      const ListTile(
                        leading: Icon(Icons.check),
                        title: Text('Status announcements for dynamic content'),
                        dense: true,
                      ),
                      const ListTile(
                        leading: Icon(Icons.check),
                        title: Text('Skip links for efficient navigation'),
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Reset Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset Settings',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text(
                                    'Reset Accessibility Settings',
                                  ),
                                  content: const Text(
                                    'This will reset all accessibility settings to their default values. Are you sure?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Reset to defaults
                                        themeProvider.setThemeMode(
                                          ThemeMode.system,
                                        );
                                        themeProvider.setTextScale(1.0);
                                        if (themeProvider.highContrast) {
                                          themeProvider.toggleHighContrast();
                                        }
                                        if (themeProvider.reducedMotion) {
                                          themeProvider.toggleReducedMotion();
                                        }

                                        Navigator.of(context).pop();
                                        AccessibilityHelper.announceToScreenReader(
                                          context,
                                          'Accessibility settings reset to defaults',
                                        );
                                      },
                                      child: const Text('Reset'),
                                    ),
                                  ],
                                ),
                          );
                        },
                        icon: const Icon(Icons.restore),
                        label: const Text('Reset to Defaults'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getThemeModeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Follow system setting';
      case ThemeMode.light:
        return 'Always use light theme';
      case ThemeMode.dark:
        return 'Always use dark theme';
    }
  }
}
