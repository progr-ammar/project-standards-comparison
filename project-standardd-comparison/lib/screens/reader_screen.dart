import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../providers/bookmarks_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/in_book_search_widget.dart';
import '../widgets/bookmark_dialog.dart';
import '../widgets/note_editor.dart';
import '../widgets/sharing_dialog.dart';
import 'bookmarks_screen.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.title,
    required this.assetPath,
    required this.bookId,
    this.initialSearch,
    this.initialPage,
    this.highlightText,
  });

  final String title;
  final String assetPath;
  final String bookId;
  final String? initialSearch;
  final int? initialPage;
  final String? highlightText;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final PdfViewerController _controller = PdfViewerController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showSearchBar = false;
  bool _showToolbar = true;
  // Sidebar removed - using direct TOC jump instead
  double _zoomLevel = 1.0;

  // TOC page shortcuts for each book
  int get _tocPage {
    switch (widget.bookId) {
      case 'pmbok7':
        return 17; // PMBOK TOC is at page 17
      case 'prince2':
        return 4; // PRINCE2 TOC is around page 4
      case 'iso21502':
        return 3; // ISO TOC is around page 3
      default:
        return 1;
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.initialPage != null && widget.initialPage! > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.jumpToPage(widget.initialPage!);
      });
    }
    if (widget.initialSearch != null &&
        widget.initialSearch!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _showSearchBar = true;
        });
      });
    }

    // Handle highlightText parameter by triggering search
    if (widget.highlightText != null &&
        widget.highlightText!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _showSearchBar = true;
        });
      });
    }
  }

  // TOC loading removed since sidebar is removed

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleMenuAction(String action, BuildContext context) {
    final bookmarks = context.read<BookmarksProvider>();
    final page = _controller.pageNumber;

    switch (action) {
      case 'bookmark':
        final existingBookmark =
            bookmarks.allBookmarks
                .where((b) => b.bookId == widget.bookId && b.page == page)
                .firstOrNull;

        showDialog(
          context: context,
          builder:
              (context) => BookmarkDialog(
                bookId: widget.bookId,
                page: page,
                snippet: existingBookmark?.snippet ?? 'Page $page',
                existingBookmark: existingBookmark,
              ),
        );
        break;

      case 'note':
        showDialog(
          context: context,
          builder:
              (context) => NoteEditor(
                initialText: '',
                title: 'Add Note for Page $page',
                onSave: (text) {
                  bookmarks.addBookmark(
                    bookId: widget.bookId,
                    page: page,
                    snippet: 'Page $page',
                    note: text,
                  );
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Note added')));
                },
              ),
        );
        break;

      case 'share':
        showDialog(
          context: context,
          builder:
              (context) => SharingDialog(
                title: '${widget.title} - Page $page',
                content: 'Check out page $page in ${widget.title}',
                deepLink: 'pm4app://book/${widget.bookId}/page/$page',
              ),
        );
        break;

      case 'theme':
        // Theme toggle functionality - get provider when needed
        context.read<ThemeProvider>().toggleTheme();
        break;

      case 'bookmarks':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const BookmarksScreen()),
        );
        break;
    }
  }

  Widget _buildEnhancedToolbar(
    BuildContext context,
    BookmarksProvider bookmarks,
    List<Bookmark> currentPageBookmarks,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Page navigation
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_controller.pageNumber > 1) {
                    _controller.previousPage();
                  }
                },
                icon: const Icon(Icons.navigate_before),
                tooltip: 'Previous page',
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Page ${_controller.pageNumber}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                onPressed: () {
                  _controller.nextPage();
                },
                icon: const Icon(Icons.navigate_next),
                tooltip: 'Next page',
              ),
            ],
          ),

          // Zoom controls
          Row(
            children: [
              IconButton(
                onPressed: () {
                  _controller.zoomLevel = math.max(
                    0.5,
                    _controller.zoomLevel - 0.25,
                  );
                },
                icon: const Icon(Icons.zoom_out),
                tooltip: 'Zoom out',
              ),
              IconButton(
                onPressed: () {
                  _controller.zoomLevel = 1.0;
                },
                icon: const Icon(Icons.zoom_out_map),
                tooltip: 'Fit to page',
              ),
              IconButton(
                onPressed: () {
                  _controller.zoomLevel = math.min(
                    3.0,
                    _controller.zoomLevel + 0.25,
                  );
                },
                icon: const Icon(Icons.zoom_in),
                tooltip: 'Zoom in',
              ),
            ],
          ),

          // Quick actions
          Row(
            children: [
              IconButton(
                onPressed: () => _handleMenuAction('bookmark', context),
                icon: Icon(
                  bookmarks.isBookmarked(
                        bookId: widget.bookId,
                        page: _controller.pageNumber,
                      )
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),
                tooltip: 'Bookmark page',
              ),
              IconButton(
                onPressed: () => _handleMenuAction('note', context),
                icon: const Icon(Icons.note_add),
                tooltip: 'Add note',
              ),
              IconButton(
                onPressed: () => _handleMenuAction('share', context),
                icon: const Icon(Icons.share),
                tooltip: 'Share page',
              ),
            ],
          ),

          // Toolbar toggle
          IconButton(
            onPressed: () {
              setState(() {
                _showToolbar = !_showToolbar;
              });
            },
            icon: const Icon(Icons.keyboard_arrow_down),
            tooltip: 'Hide toolbar',
          ),
        ],
      ),
    );
  }

  void _showPageNotes(BuildContext context, List<Bookmark> pageBookmarks) {
    final notesBookmarks =
        pageBookmarks.where((b) => b.note.isNotEmpty).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.5,
            maxChildSize: 0.9,
            minChildSize: 0.3,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.note,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Notes for Page ${_controller.pageNumber}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),

                      // Notes list
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: notesBookmarks.length,
                          itemBuilder: (context, index) {
                            final bookmark = notesBookmarks[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 4.0,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Context snippet
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceVariant
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        bookmark.snippet,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Note
                                    Text(
                                      bookmark.note,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                    ),

                                    // Tags
                                    if (bookmark.tags.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 4,
                                        children:
                                            bookmark.tags.map((tag) {
                                              return Chip(
                                                label: Text(tag),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                labelStyle:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.labelSmall,
                                              );
                                            }).toList(),
                                      ),
                                    ],

                                    // Edit button
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          showDialog(
                                            context: context,
                                            builder:
                                                (context) => NoteEditor(
                                                  initialText: bookmark.note,
                                                  title: 'Edit Note',
                                                  onSave: (text) {
                                                    context
                                                        .read<
                                                          BookmarksProvider
                                                        >()
                                                        .updateBookmark(
                                                          bookmark.id,
                                                          note: text,
                                                        );
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Note updated',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                          );
                                        },
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Edit'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<BookmarksProvider>();
    final currentPageBookmarks =
        bookmarks.allBookmarks
            .where(
              (b) =>
                  b.bookId == widget.bookId && b.page == _controller.pageNumber,
            )
            .toList();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(widget.title),
        actions: [
          // Quick TOC shortcut
          IconButton(
            tooltip: 'Go to Table of Contents (Page $_tocPage)',
            onPressed: () {
              _controller.jumpToPage(_tocPage);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Jumped to Table of Contents (Page $_tocPage)'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.list_alt),
          ),
          // Removed sidebar and duplicate zoom controls - using bottom toolbar only
          IconButton(
            tooltip: 'Search in book',
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
              });
            },
            icon: Icon(_showSearchBar ? Icons.search_off : Icons.search),
          ),
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (value) => _handleMenuAction(value, context),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'bookmark',
                    child: ListTile(
                      leading: Icon(Icons.bookmark_add),
                      title: Text('Bookmark Page'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'note',
                    child: ListTile(
                      leading: Icon(Icons.note_add),
                      title: Text('Add Note'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                      leading: Icon(Icons.share),
                      title: Text('Share Page'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'theme',
                    child: ListTile(
                      leading: Icon(Icons.palette),
                      title: Text('Toggle Theme'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'bookmarks',
                    child: ListTile(
                      leading: Icon(Icons.bookmarks),
                      title: Text('View Bookmarks'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
          ),
        ],
        bottom:
            _showSearchBar
                ? InBookSearchBar(
                  controller: _controller,
                  bookId: widget.bookId,
                  initialQuery: widget.initialSearch ?? widget.highlightText,
                )
                : null,
      ),
      body: Stack(
        children: [
          SfPdfViewer.asset(
            widget.assetPath,
            controller: _controller,
            canShowPaginationDialog: true,
            canShowScrollHead: true,
            onZoomLevelChanged: (PdfZoomDetails details) {
              setState(() {
                _zoomLevel = details.newZoomLevel;
              });
            },
            onPageChanged: (PdfPageChangedDetails details) {
              // Force UI update when page changes
              setState(() {
                // This will trigger a rebuild and update all page-dependent widgets
              });
            },
          ),

          // Enhanced toolbar overlay
          if (_showToolbar)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildEnhancedToolbar(
                context,
                bookmarks,
                currentPageBookmarks,
              ),
            ),

          // Notes overlay for current page
          if (currentPageBookmarks.any((b) => b.note.isNotEmpty))
            Positioned(
              right: 16,
              top: 16,
              child: FloatingActionButton.small(
                onPressed: () => _showPageNotes(context, currentPageBookmarks),
                tooltip: 'View notes for this page',
                child: Badge(
                  label: Text(
                    '${currentPageBookmarks.where((b) => b.note.isNotEmpty).length}',
                  ),
                  child: const Icon(Icons.note),
                ),
              ),
            ),

          // Zoom level indicator
          if (_zoomLevel != 1.0)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '${(_zoomLevel * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),

          // Show toolbar button when toolbar is hidden
          if (!_showToolbar)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _showToolbar = true;
                  });
                },
                tooltip: 'Show toolbar',
                child: const Icon(Icons.more_horiz),
              ),
            ),
        ],
      ),
    );
  }
}
