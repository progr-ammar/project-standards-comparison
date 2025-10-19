import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/search_provider.dart';
import '../providers/index_provider.dart';
import '../providers/bookmarks_provider.dart';
import '../widgets/enhanced_search_bar.dart';
import 'reader_screen.dart';

class ParallelSearchScreen extends StatefulWidget {
  const ParallelSearchScreen({super.key, required this.query});

  final String query;

  @override
  State<ParallelSearchScreen> createState() => _ParallelSearchScreenState();
}

class _ParallelSearchScreenState extends State<ParallelSearchScreen> {
  late TextEditingController _searchController;
  bool _isSearching = false;
  List<SearchResult> _results = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query);
    if (widget.query.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.query);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _results = [];
    });

    try {
      final indexProvider = context.read<IndexProvider>();
      final searchProvider = context.read<SearchProvider>();

      // Add to recent searches
      searchProvider.addRecent(query);

      // Perform search across all books
      final results = await indexProvider.performSearch(query);

      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text('Search Results'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: EnhancedSearchBar(
              hintText: 'Search across all standards',
              onSubmitted: _performSearch,
              autofocus: false,
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching across all standards...'),
          ],
        ),
      );
    }

    if (_results.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No results found for "${_searchController.text}"',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try different keywords or check spelling',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Enter a search term to get started',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Group results by book
    final groupedResults = <String, List<SearchResult>>{};
    for (final result in _results) {
      groupedResults.putIfAbsent(result.bookId, () => []).add(result);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Results summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 8),
              Text(
                'Found ${_results.length} results across ${groupedResults.length} standards',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Results by book
        ...groupedResults.entries.map((entry) {
          final bookId = entry.key;
          final results = entry.value;
          final bookName = _getBookDisplayName(bookId);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.menu_book,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$bookName (${results.length} results)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              ...results.map((result) => _buildResultCard(result)),

              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildResultCard(SearchResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          result.snippet,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Page ${result.pageNumber}'),
            if (result.topic.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Topic: ${result.topic}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Match score indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getScoreColor(result.matchScore).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(result.matchScore * 100).round()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(result.matchScore),
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton(
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'open',
                      child: Row(
                        children: [
                          Icon(Icons.open_in_new),
                          SizedBox(width: 8),
                          Text('Open in Reader'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'bookmark',
                      child: Row(
                        children: [
                          Icon(Icons.bookmark_add),
                          SizedBox(width: 8),
                          Text('Bookmark'),
                        ],
                      ),
                    ),
                  ],
              onSelected: (value) {
                switch (value) {
                  case 'open':
                    _openInReader(result);
                    break;
                  case 'bookmark':
                    _bookmarkResult(result);
                    break;
                }
              },
            ),
          ],
        ),
        onTap: () => _openInReader(result),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getBookDisplayName(String bookId) {
    switch (bookId) {
      case 'pmbok7':
        return 'PMBOK 7th Edition';
      case 'prince2':
        return 'PRINCE2 7th Edition';
      case 'iso21502':
        return 'ISO 21502';
      default:
        return bookId;
    }
  }

  String _getBookAssetPath(String bookId) {
    switch (bookId) {
      case 'pmbok7':
        return 'assets/pmbok7.pdf';
      case 'prince2':
        return 'assets/prince2.pdf';
      case 'iso21502':
        return 'assets/iso21502.pdf';
      default:
        return 'assets/$bookId.pdf';
    }
  }

  void _openInReader(SearchResult result) {
    // Navigate to reader screen with the specific page and highlight
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => ReaderScreen(
              title: _getBookDisplayName(result.bookId),
              assetPath: _getBookAssetPath(result.bookId),
              bookId: result.bookId,
              initialPage: result.pageNumber,
              highlightText: result.highlightedText,
            ),
      ),
    );
  }

  void _bookmarkResult(SearchResult result) {
    final bookmarksProvider = context.read<BookmarksProvider>();

    bookmarksProvider.addBookmark(
      bookId: result.bookId,
      page: result.pageNumber,
      snippet: result.snippet,
      note: 'Found via search: "${_searchController.text}"',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark added successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
