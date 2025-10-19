import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bookmarks_provider.dart';
import '../widgets/bookmark_dialog.dart';
import 'reader_screen.dart';
import 'tag_management_screen.dart';
import 'notes_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.note),
            tooltip: 'View notes',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NotesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.label),
            tooltip: 'Manage tags',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TagManagementScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear filters',
            onPressed: () {
              context.read<BookmarksProvider>().clearFilters();
              _searchController.clear();
            },
          ),
        ],
      ),
      body: Consumer<BookmarksProvider>(
        builder: (context, bookmarksProvider, child) {
          final bookmarks = bookmarksProvider.bookmarks;
          final availableTags = bookmarksProvider.availableTags;
          final bookmarksByBook = bookmarksProvider.bookmarksByBook;

          return Column(
            children: [
              // Search and filters
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search bookmarks...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    bookmarksProvider.setSearchQuery('');
                                  },
                                )
                                : null,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: bookmarksProvider.setSearchQuery,
                    ),
                    const SizedBox(height: 12),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Book filter
                          if (bookmarksByBook.isNotEmpty) ...[
                            const Text('Books: '),
                            const SizedBox(width: 8),
                            ...bookmarksByBook.entries.map((entry) {
                              final isSelected =
                                  bookmarksProvider.filterBook == entry.key;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text('${entry.key} (${entry.value})'),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    bookmarksProvider.setFilterBook(
                                      selected ? entry.key : '',
                                    );
                                  },
                                ),
                              );
                            }),
                            const SizedBox(width: 16),
                          ],

                          // Tag filter
                          if (availableTags.isNotEmpty) ...[
                            const Text('Tags: '),
                            const SizedBox(width: 8),
                            ...availableTags.map((tag) {
                              final isSelected =
                                  bookmarksProvider.filterTag == tag;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(tag),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    bookmarksProvider.setFilterTag(
                                      selected ? tag : '',
                                    );
                                  },
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Statistics
              if (bookmarks.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Showing ${bookmarks.length} of ${bookmarksProvider.totalBookmarks} bookmarks',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),

              // Bookmarks list
              Expanded(
                child:
                    bookmarks.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bookmark_border,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                bookmarksProvider.totalBookmarks == 0
                                    ? 'No bookmarks yet'
                                    : 'No bookmarks match your filters',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                bookmarksProvider.totalBookmarks == 0
                                    ? 'Start reading and bookmark important passages'
                                    : 'Try adjusting your search or filters',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          itemCount: bookmarks.length,
                          itemBuilder: (context, index) {
                            final bookmark = bookmarks[index];
                            return BookmarkCard(
                              bookmark: bookmark,
                              onTap: () => _openBookmark(context, bookmark),
                              onEdit: () => _editBookmark(context, bookmark),
                              onDelete:
                                  () => _deleteBookmark(context, bookmark),
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openBookmark(BuildContext context, Bookmark bookmark) {
    // Navigate to reader screen at the bookmarked page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ReaderScreen(
              title: bookmark.bookId,
              assetPath: _getAssetPath(bookmark.bookId),
              bookId: bookmark.bookId,
              initialPage: bookmark.page,
              highlightText: bookmark.snippet,
            ),
      ),
    );
  }

  void _editBookmark(BuildContext context, Bookmark bookmark) {
    showDialog(
      context: context,
      builder:
          (context) => BookmarkDialog(
            bookId: bookmark.bookId,
            page: bookmark.page,
            snippet: bookmark.snippet,
            existingBookmark: bookmark,
            deepLink: bookmark.deepLink,
          ),
    );
  }

  void _deleteBookmark(BuildContext context, Bookmark bookmark) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Bookmark'),
            content: Text(
              'Are you sure you want to delete this bookmark from page ${bookmark.page}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  context.read<BookmarksProvider>().removeBookmark(bookmark.id);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bookmark deleted')),
                  );
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  String _getAssetPath(String bookId) {
    switch (bookId.toLowerCase()) {
      case 'pmbok':
      case 'pmbok7':
        return 'assets/pmbok7.pdf';
      case 'prince2':
        return 'assets/prince2.pdf';
      case 'iso21502':
      case 'iso':
        return 'assets/iso21502.pdf';
      default:
        return 'assets/pmbok7.pdf';
    }
  }
}

class BookmarkCard extends StatelessWidget {
  const BookmarkCard({
    super.key,
    required this.bookmark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Bookmark bookmark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with book and page info
              Row(
                children: [
                  Icon(
                    Icons.bookmark,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${bookmark.bookId} - Page ${bookmark.page}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Snippet
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bookmark.snippet,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

              // Note (if present)
              if (bookmark.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.note,
                            size: 16,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Note',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bookmark.note,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],

              // Tags (if present)
              if (bookmark.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children:
                      bookmark.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          labelStyle: Theme.of(context).textTheme.labelSmall,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                ),
              ],

              // Footer with timestamp
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(bookmark.created),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (bookmark.modified != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Modified ${_formatDate(bookmark.modified!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
