import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bookmarks_provider.dart';
import '../widgets/note_editor.dart';
import 'reader_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
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
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear search',
            onPressed: () {
              _searchController.clear();
              context.read<BookmarksProvider>().setSearchQuery('');
            },
          ),
        ],
      ),
      body: Consumer<BookmarksProvider>(
        builder: (context, bookmarksProvider, child) {
          // Filter bookmarks that have notes
          final bookmarksWithNotes =
              bookmarksProvider.allBookmarks
                  .where((bookmark) => bookmark.note.isNotEmpty)
                  .toList();

          // Apply search filter
          final searchQuery = _searchController.text.toLowerCase();
          final filteredNotes =
              searchQuery.isEmpty
                  ? bookmarksWithNotes
                  : bookmarksWithNotes.where((bookmark) {
                    return bookmark.note.toLowerCase().contains(searchQuery) ||
                        bookmark.snippet.toLowerCase().contains(searchQuery) ||
                        bookmark.tags.any(
                          (tag) => tag.toLowerCase().contains(searchQuery),
                        );
                  }).toList();

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                            : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),

              // Statistics
              if (bookmarksWithNotes.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Showing ${filteredNotes.length} of ${bookmarksWithNotes.length} notes',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),

              // Notes list
              Expanded(
                child:
                    filteredNotes.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.note_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                bookmarksWithNotes.isEmpty
                                    ? 'No notes yet'
                                    : 'No notes match your search',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                bookmarksWithNotes.isEmpty
                                    ? 'Add notes to your bookmarks to see them here'
                                    : 'Try adjusting your search terms',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          itemCount: filteredNotes.length,
                          itemBuilder: (context, index) {
                            final bookmark = filteredNotes[index];
                            return NoteCard(
                              bookmark: bookmark,
                              onTap: () => _openBookmark(context, bookmark),
                              onEdit: () => _editNote(context, bookmark),
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

  void _editNote(BuildContext context, Bookmark bookmark) {
    showDialog(
      context: context,
      builder:
          (context) => NoteEditor(
            initialText: bookmark.note,
            title: 'Edit Note',
            onSave: (text) {
              context.read<BookmarksProvider>().updateBookmark(
                bookmark.id,
                note: text,
              );
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Note updated')));
            },
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

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.bookmark,
    required this.onTap,
    required this.onEdit,
  });

  final Bookmark bookmark;
  final VoidCallback onTap;
  final VoidCallback onEdit;

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
              // Header
              Row(
                children: [
                  Icon(
                    Icons.note,
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
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: onEdit,
                    tooltip: 'Edit note',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Note content
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
                child: Text(
                  bookmark.note,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),

              // Context snippet
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Context:',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bookmark.snippet.length > 100
                          ? '${bookmark.snippet.substring(0, 100)}...'
                          : bookmark.snippet,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

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
