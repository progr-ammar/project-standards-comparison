import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bookmarks_provider.dart';
import '../providers/search_provider.dart';

class SearchResultsWidget extends StatelessWidget {
  const SearchResultsWidget({
    super.key,
    required this.results,
    required this.query,
    this.onResultTap,
    this.showBookNames = true,
    this.groupByBook = true,
  });

  final List<SearchResult> results;
  final String query;
  final ValueChanged<SearchResult>? onResultTap;
  final bool showBookNames;
  final bool groupByBook;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return _buildEmptyState(context);
    }

    if (groupByBook) {
      return _buildGroupedResults(context);
    } else {
      return _buildFlatResults(context);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              query.isEmpty ? 'Enter a search term' : 'No results found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            if (query.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Try different keywords or check spelling',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedResults(BuildContext context) {
    final groupedResults = <String, List<SearchResult>>{};
    for (final result in results) {
      groupedResults.putIfAbsent(result.bookId, () => []).add(result);
    }

    return ListView(
      children: [
        // Results summary
        if (results.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Found ${results.length} results across ${groupedResults.length} standards',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

        // Grouped results
        ...groupedResults.entries.map((entry) {
          final bookId = entry.key;
          final bookResults = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book header
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.menu_book,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_getBookDisplayName(bookId)} (${bookResults.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Results for this book
              ...bookResults.map((result) => _buildResultTile(context, result)),

              const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildFlatResults(BuildContext context) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return _buildResultTile(context, results[index]);
      },
    );
  }

  Widget _buildResultTile(BuildContext context, SearchResult result) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: _buildHighlightedText(result.snippet, query),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                if (showBookNames && !groupByBook) ...[
                  Text(
                    _getBookDisplayName(result.bookId),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(' • '),
                ],
                Text('Page ${result.pageNumber}'),
                if (result.topic.isNotEmpty) ...[
                  const Text(' • '),
                  Text(
                    result.topic,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Match score
            _buildMatchScore(context, result.matchScore),
            const SizedBox(width: 8),

            // Actions menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'open',
                      child: ListTile(
                        leading: Icon(Icons.open_in_new),
                        title: Text('Open in Reader'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'bookmark',
                      child: ListTile(
                        leading: Icon(Icons.bookmark_add),
                        title: Text('Add Bookmark'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: ListTile(
                        leading: Icon(Icons.share),
                        title: Text('Share'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
              onSelected: (action) => _handleAction(context, action, result),
            ),
          ],
        ),
        onTap: () {
          onResultTap?.call(result);
        },
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(text);
    }

    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();
    final spans = <TextSpan>[];

    int start = 0;
    int index = textLower.indexOf(queryLower);

    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      // Add highlighted match
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: const TextStyle(
            backgroundColor: Colors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + query.length;
      index = textLower.indexOf(queryLower, start);
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(text: TextSpan(style: const TextStyle(), children: spans));
  }

  Widget _buildMatchScore(BuildContext context, double score) {
    Color color;
    if (score >= 0.8) {
      color = Colors.green;
    } else if (score >= 0.6) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${(score * 100).round()}%',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
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
        return bookId.toUpperCase();
    }
  }

  void _handleAction(BuildContext context, String action, SearchResult result) {
    switch (action) {
      case 'open':
        _openInReader(context, result);
        break;
      case 'bookmark':
        _addBookmark(context, result);
        break;
      case 'share':
        _shareResult(context, result);
        break;
    }
  }

  void _openInReader(BuildContext context, SearchResult result) {
    // TODO: Navigate to reader screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening ${_getBookDisplayName(result.bookId)} at page ${result.pageNumber}',
        ),
      ),
    );
  }

  void _addBookmark(BuildContext context, SearchResult result) {
    final bookmarksProvider = context.read<BookmarksProvider>();

    bookmarksProvider.addBookmark(
      bookId: result.bookId,
      page: result.pageNumber,
      snippet: result.snippet,
      note: 'Found via search: "$query"',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark added successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareResult(BuildContext context, SearchResult result) {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing functionality coming soon')),
    );
  }
}
