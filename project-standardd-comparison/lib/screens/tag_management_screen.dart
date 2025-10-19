import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bookmarks_provider.dart';

class TagManagementScreen extends StatefulWidget {
  const TagManagementScreen({super.key});

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  final TextEditingController _newTagController = TextEditingController();

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Tags')),
      body: Consumer<BookmarksProvider>(
        builder: (context, bookmarksProvider, child) {
          final availableTags =
              bookmarksProvider.availableTags.toList()..sort();

          return Column(
            children: [
              // Add new tag section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Tag',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newTagController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter tag name...',
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted:
                                    (value) =>
                                        _addTag(bookmarksProvider, value),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed:
                                  () => _addTag(
                                    bookmarksProvider,
                                    _newTagController.text,
                                  ),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tags list
              Expanded(
                child:
                    availableTags.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.label_outline,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tags yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create tags to organize your bookmarks',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          itemCount: availableTags.length,
                          itemBuilder: (context, index) {
                            final tag = availableTags[index];
                            final bookmarksWithTag = bookmarksProvider
                                .getBookmarksByTag(tag);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 4.0,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                  child: Text(
                                    tag.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(tag),
                                subtitle: Text(
                                  '${bookmarksWithTag.length} bookmark${bookmarksWithTag.length == 1 ? '' : 's'}',
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'view':
                                        _viewBookmarksWithTag(
                                          context,
                                          bookmarksProvider,
                                          tag,
                                        );
                                        break;
                                      case 'rename':
                                        _renameTag(
                                          context,
                                          bookmarksProvider,
                                          tag,
                                        );
                                        break;
                                      case 'delete':
                                        _deleteTag(
                                          context,
                                          bookmarksProvider,
                                          tag,
                                        );
                                        break;
                                    }
                                  },
                                  itemBuilder:
                                      (context) => [
                                        const PopupMenuItem(
                                          value: 'view',
                                          child: Row(
                                            children: [
                                              Icon(Icons.visibility),
                                              SizedBox(width: 8),
                                              Text('View Bookmarks'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'rename',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit),
                                              SizedBox(width: 8),
                                              Text('Rename'),
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
                                onTap:
                                    () => _viewBookmarksWithTag(
                                      context,
                                      bookmarksProvider,
                                      tag,
                                    ),
                              ),
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

  void _addTag(BookmarksProvider provider, String tagName) {
    final trimmedTag = tagName.trim();
    if (trimmedTag.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tag name cannot be empty')));
      return;
    }

    if (provider.availableTags.contains(trimmedTag)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tag already exists')));
      return;
    }

    provider.addTag(trimmedTag);
    _newTagController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Tag "$trimmedTag" added')));
  }

  void _viewBookmarksWithTag(
    BuildContext context,
    BookmarksProvider provider,
    String tag,
  ) {
    provider.setFilterTag(tag);
    provider.clearFilters();
    provider.setFilterTag(tag);
    Navigator.of(context).pop(); // Go back to bookmarks screen
  }

  void _renameTag(
    BuildContext context,
    BookmarksProvider provider,
    String oldTag,
  ) {
    final controller = TextEditingController(text: oldTag);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Rename Tag'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Tag name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final newTag = controller.text.trim();
                  if (newTag.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tag name cannot be empty')),
                    );
                    return;
                  }

                  if (newTag == oldTag) {
                    Navigator.of(context).pop();
                    return;
                  }

                  if (provider.availableTags.contains(newTag)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tag already exists')),
                    );
                    return;
                  }

                  // Update all bookmarks with the old tag
                  final bookmarksWithTag = provider.getBookmarksByTag(oldTag);
                  for (final bookmark in bookmarksWithTag) {
                    final newTags =
                        bookmark.tags
                            .map((tag) => tag == oldTag ? newTag : tag)
                            .toList();
                    provider.updateBookmark(bookmark.id, tags: newTags);
                  }

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tag renamed to "$newTag"')),
                  );
                },
                child: const Text('Rename'),
              ),
            ],
          ),
    );
  }

  void _deleteTag(
    BuildContext context,
    BookmarksProvider provider,
    String tag,
  ) {
    final bookmarksWithTag = provider.getBookmarksByTag(tag);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Tag'),
            content: Text(
              'Are you sure you want to delete the tag "$tag"?\n\n'
              'This will remove the tag from ${bookmarksWithTag.length} bookmark${bookmarksWithTag.length == 1 ? '' : 's'}.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  provider.removeTag(tag);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Tag "$tag" deleted')));
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
