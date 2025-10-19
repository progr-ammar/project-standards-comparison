import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/search_provider.dart';

class EnhancedSearchBar extends StatefulWidget {
  const EnhancedSearchBar({
    super.key,
    required this.hintText,
    required this.onSubmitted,
    this.onChanged,
    this.showSuggestions = true,
    this.autofocus = false,
  });

  final String hintText;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool showSuggestions;
  final bool autofocus;

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && widget.showSuggestions;
    });
  }

  void _onTextChanged(String value) {
    context.read<SearchProvider>().setCurrentQuery(value);
    widget.onChanged?.call(value);
    setState(() {
      _showSuggestions =
          value.isNotEmpty && _focusNode.hasFocus && widget.showSuggestions;
    });
  }

  void _onSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      context.read<SearchProvider>().addRecent(value.trim());
      widget.onSubmitted(value.trim());
      _focusNode.unfocus();
    }
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    _onSubmitted(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        final suggestions = searchProvider.getAutocompleteSuggestions(
          _controller.text,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _controller.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            _onTextChanged('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              onChanged: _onTextChanged,
              onSubmitted: _onSubmitted,
            ),

            // Recent searches chips - compact layout
            if (!_showSuggestions && searchProvider.recent.isNotEmpty) ...[
              const SizedBox(height: 4),
              SizedBox(
                height: 32,
                child: Row(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: searchProvider.recent.length,
                        itemBuilder: (context, index) {
                          final recent = searchProvider.recent[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InputChip(
                              label: Text(recent),
                              onPressed: () => _selectSuggestion(recent),
                              avatar: const Icon(Icons.history, size: 14),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () {
                                context.read<SearchProvider>().removeRecent(
                                  recent,
                                );
                              },
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        context.read<SearchProvider>().clearRecent();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recent searches cleared'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.clear_all, size: 16),
                      tooltip: 'Clear all',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ],

            // Suggestions dropdown
            if (_showSuggestions && suggestions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = suggestions[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        suggestion.type == 'recent'
                            ? Icons.history
                            : suggestion.type == 'topic'
                            ? Icons.topic
                            : Icons.search,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      title: Text(suggestion.text),
                      onTap: () => _selectSuggestion(suggestion.text),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
