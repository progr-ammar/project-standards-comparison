import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bookmarks_provider.dart';
import 'note_editor.dart';

class BookmarkDialog extends StatefulWidget {
  const BookmarkDialog({
    super.key,
    required this.bookId,
    required this.page,
    required this.snippet,
    this.existingBookmark,
    this.deepLink,
  });

  final String bookId;
  final int page;
  final String snippet;
  final Bookmark? existingBookmark;
  final String? deepLink;

  @override
  State<BookmarkDialog> createState() => _BookmarkDialogState();
}

class _BookmarkDialogState extends State<BookmarkDialog> {
  late final TextEditingController _noteController;
  late final TextEditingController _snippetController;
  late final TextEditingController _tagController;
  late final Set<String> _selectedTags;
  final FocusNode _tagFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(
      text: widget.existingBookmark?.note ?? '',
    );
    _snippetController = TextEditingController(
      text: widget.existingBookmark?.snippet ?? widget.snippet,
    );
    _tagController = TextEditingController();
    _selectedTags = Set.from(widget.existingBookmark?.tags ?? <String>[]);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _snippetController.dispose();
    _tagController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !_selectedTags.contains(trimmedTag)) {
      setState(() {
        _selectedTags.add(trimmedTag);
      });
      _tagController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksProvider = context.watch<BookmarksProvider>();
    final availableTags = bookmarksProvider.availableTags;
    final isEditing = widget.existingBookmark != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Bookmark' : 'Add Bookmark'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.book, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.bookId} - Page ${widget.page}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Snippet
              Text('Snippet', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _snippetController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter or edit the text snippet...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Note
              Text(
                'Note (Optional)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              QuickNoteWidget(
                note: _noteController.text,
                onEdit: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => NoteEditor(
                          initialText: _noteController.text,
                          title: 'Edit Bookmark Note',
                          onSave: (text) {
                            setState(() {
                              _noteController.text = text;
                            });
                          },
                        ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Tags
              Text('Tags', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),

              // Selected tags
              if (_selectedTags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      _selectedTags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () => _removeTag(tag),
                        );
                      }).toList(),
                ),
              const SizedBox(height: 8),

              // Tag input
              TextField(
                controller: _tagController,
                focusNode: _tagFocusNode,
                decoration: InputDecoration(
                  hintText: 'Add tags...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addTag(_tagController.text),
                  ),
                ),
                onSubmitted: _addTag,
              ),
              const SizedBox(height: 8),

              // Available tags
              if (availableTags.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Tags',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children:
                          availableTags
                              .where((tag) => !_selectedTags.contains(tag))
                              .map((tag) {
                                return ActionChip(
                                  label: Text(tag),
                                  onPressed: () => _addTag(tag),
                                );
                              })
                              .toList(),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (isEditing)
          TextButton(
            onPressed: () {
              bookmarksProvider.removeBookmark(widget.existingBookmark!.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Bookmark deleted')));
            },
            child: const Text('Delete'),
          ),
        FilledButton(
          onPressed: () {
            final snippet = _snippetController.text.trim();
            final note = _noteController.text.trim();
            final tags = _selectedTags.toList();

            if (snippet.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Snippet cannot be empty')),
              );
              return;
            }

            if (isEditing) {
              bookmarksProvider.updateBookmark(
                widget.existingBookmark!.id,
                snippet: snippet,
                note: note,
                tags: tags,
                deepLink: widget.deepLink,
              );
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Bookmark updated')));
            } else {
              bookmarksProvider.addBookmark(
                bookId: widget.bookId,
                page: widget.page,
                snippet: snippet,
                note: note,
                tags: tags,
                deepLink: widget.deepLink,
              );
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Bookmark added')));
            }

            Navigator.of(context).pop();
          },
          child: Text(isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}
