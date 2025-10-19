import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../providers/search_provider.dart';

class InBookSearchWidget extends StatefulWidget {
  const InBookSearchWidget({
    super.key,
    required this.controller,
    required this.bookId,
    this.initialQuery,
  });

  final PdfViewerController controller;
  final String bookId;
  final String? initialQuery;

  @override
  State<InBookSearchWidget> createState() => _InBookSearchWidgetState();
}

class _InBookSearchWidgetState extends State<InBookSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  PdfTextSearchResult? _searchResult;
  bool _isSearching = false;
  int _currentMatchIndex = 0;
  int _totalMatches = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _searchResult?.clear();
    super.dispose();
  }

  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _clearSearch();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Clear previous search
      _searchResult?.clear();

      // Perform new search
      _searchResult = widget.controller.searchText(query);

      // Add to recent searches
      context.read<SearchProvider>().addRecent(query);

      // Update match count (this is a simplified approach)
      // In a real implementation, you'd need to track the actual match count
      setState(() {
        _currentMatchIndex = _searchResult?.currentInstanceIndex ?? 0;
        _totalMatches = _searchResult?.totalInstanceCount ?? 0;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Error performing search: $e');
      setState(() {
        _isSearching = false;
        _currentMatchIndex = 0;
        _totalMatches = 0;
      });
    }
  }

  void _clearSearch() {
    _searchResult?.clear();
    _searchResult = null;
    setState(() {
      _currentMatchIndex = 0;
      _totalMatches = 0;
      _isSearching = false;
    });
  }

  void _goToNextMatch() {
    if (_searchResult != null) {
      _searchResult!.nextInstance();
      setState(() {
        _currentMatchIndex = _searchResult!.currentInstanceIndex;
      });
    }
  }

  void _goToPreviousMatch() {
    if (_searchResult != null) {
      _searchResult!.previousInstance();
      setState(() {
        _currentMatchIndex = _searchResult!.currentInstanceIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _clearSearch();
                              },
                            )
                            : null,
                    hintText: 'Search in this book...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _performSearch(),
                  onChanged: (value) {
                    if (value.isEmpty) {
                      _clearSearch();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed:
                    _searchController.text.isNotEmpty ? _performSearch : null,
                icon:
                    _isSearching
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.search),
                tooltip: 'Search',
              ),
            ],
          ),
          if (_totalMatches > 0) ...[
            const SizedBox(height: 8),
            _buildSearchResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Text(
            _totalMatches > 0
                ? '${_currentMatchIndex + 1} of $_totalMatches matches'
                : 'No matches found',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          if (_totalMatches > 1) ...[
            IconButton(
              onPressed: _currentMatchIndex > 0 ? _goToPreviousMatch : null,
              icon: const Icon(Icons.keyboard_arrow_up),
              iconSize: 20,
              tooltip: 'Previous match',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              onPressed:
                  _currentMatchIndex < _totalMatches - 1
                      ? _goToNextMatch
                      : null,
              icon: const Icon(Icons.keyboard_arrow_down),
              iconSize: 20,
              tooltip: 'Next match',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
          IconButton(
            onPressed: () {
              _searchController.clear();
              _clearSearch();
            },
            icon: const Icon(Icons.close),
            iconSize: 20,
            tooltip: 'Clear search',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class InBookSearchBar extends StatelessWidget implements PreferredSizeWidget {
  const InBookSearchBar({
    super.key,
    required this.controller,
    required this.bookId,
    this.initialQuery,
    this.onSearchChanged,
  });

  final PdfViewerController controller;
  final String bookId;
  final String? initialQuery;
  final ValueChanged<String>? onSearchChanged;

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: InBookSearchWidget(
        controller: controller,
        bookId: bookId,
        initialQuery: initialQuery,
      ),
    );
  }
}

class SearchResultsOverlay extends StatelessWidget {
  const SearchResultsOverlay({
    super.key,
    required this.searchResult,
    required this.onClose,
  });

  final PdfTextSearchResult searchResult;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Search Results',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                    iconSize: 18,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${searchResult.currentInstanceIndex + 1} of ${searchResult.totalInstanceCount} matches',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: searchResult.previousInstance,
                    icon: const Icon(Icons.keyboard_arrow_up),
                    tooltip: 'Previous',
                  ),
                  IconButton(
                    onPressed: searchResult.nextInstance,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    tooltip: 'Next',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
