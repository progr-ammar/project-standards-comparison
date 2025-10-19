import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class AccessibilityHelper {
  // Skip link for keyboard navigation
  static Widget skipLink({
    required String text,
    required VoidCallback onPressed,
    required FocusNode focusNode,
  }) {
    return Positioned(
      top: -100, // Hidden by default
      left: 16,
      child: Focus(
        focusNode: focusNode,
        onFocusChange: (hasFocus) {
          // Move skip link into view when focused
        },
        child: ElevatedButton(onPressed: onPressed, child: Text(text)),
      ),
    );
  }

  // Screen reader announcements
  static void announceToScreenReader(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  // Focus management
  static void requestFocus(FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  // Semantic labels for complex widgets
  static Widget semanticLabel({
    required String label,
    required Widget child,
    bool isButton = false,
    bool isHeader = false,
    bool isLink = false,
  }) {
    return Semantics(
      label: label,
      button: isButton,
      header: isHeader,
      link: isLink,
      child: child,
    );
  }

  // High contrast color helper
  static Color getContrastColor(
    BuildContext context, {
    bool isBackground = false,
  }) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    if (isBackground) {
      return brightness == Brightness.dark ? Colors.black : Colors.white;
    } else {
      return brightness == Brightness.dark ? Colors.white : Colors.black;
    }
  }

  // Focus indicator
  static Widget focusIndicator({
    required Widget child,
    required FocusNode focusNode,
    Color? focusColor,
  }) {
    return Focus(
      focusNode: focusNode,
      child: Builder(
        builder: (context) {
          final hasFocus = focusNode.hasFocus;
          return Container(
            decoration:
                hasFocus
                    ? BoxDecoration(
                      border: Border.all(
                        color:
                            focusColor ?? Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    )
                    : null,
            child: child,
          );
        },
      ),
    );
  }

  // Keyboard shortcuts helper
  static Widget keyboardShortcut({
    required Widget child,
    required LogicalKeySet keySet,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Shortcuts(
      shortcuts: {keySet: CallbackIntent(onPressed)},
      child: Actions(
        actions: {CallbackIntent: CallbackAction(onInvoke: (_) => onPressed())},
        child:
            tooltip != null ? Tooltip(message: tooltip, child: child) : child,
      ),
    );
  }

  // Text scaling helper
  static double getScaledFontSize(BuildContext context, double baseFontSize) {
    final mediaQuery = MediaQuery.of(context);
    return baseFontSize * mediaQuery.textScaler.scale(1.0);
  }

  // Color contrast checker
  static bool hasGoodContrast(Color foreground, Color background) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();

    final lighter =
        foregroundLuminance > backgroundLuminance
            ? foregroundLuminance
            : backgroundLuminance;
    final darker =
        foregroundLuminance > backgroundLuminance
            ? backgroundLuminance
            : foregroundLuminance;

    final contrastRatio = (lighter + 0.05) / (darker + 0.05);
    return contrastRatio >= 4.5; // WCAG AA standard
  }

  // Touch target size helper
  static Widget ensureMinimumTouchTarget({
    required Widget child,
    double minSize = 44.0,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      child: child,
    );
  }
}

class CallbackIntent extends Intent {
  const CallbackIntent(this.callback);
  final VoidCallback callback;
}

class CallbackAction extends Action<CallbackIntent> {
  CallbackAction({required this.onInvoke});
  final void Function(CallbackIntent) onInvoke;

  @override
  Object? invoke(CallbackIntent intent) {
    onInvoke(intent);
    return null;
  }
}
