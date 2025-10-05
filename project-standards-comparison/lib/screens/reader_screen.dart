import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../providers/bookmarks_provider.dart';
import '../providers/search_provider.dart';
import '../providers/index_provider.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.title,
    required this.assetPath,
    required this.bookId,
    this.initialSearch,
    this.initialPage,
  });

  final String title;
  final String assetPath;
  final String bookId;
  final String? initialSearch;
  final int? initialPage;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final PdfViewerController _controller = PdfViewerController();
  final TextEditingController _search = TextEditingController();
  PdfTextSearchResult? _searchResult;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
        _search.text = widget.initialSearch!;
        _doSearch();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  void _doSearch() {
    final query = _search.text.trim();
    if (query.isEmpty) return;
    context.read<SearchProvider>().addRecent(query);
    _searchResult = _controller.searchText(query);
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<BookmarksProvider>();
    final bookmarkPages = bookmarks.bookmarks[widget.bookId] ?? <int>[];
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
          IconButton(
            tooltip: 'Bookmarks & Index',
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.menu_open),
          ),
          IconButton(
            tooltip: 'Go to previous match',
            onPressed: () {
              if (_searchResult == null) {
                _doSearch();
              }
              _searchResult?.previousInstance();
            },
            icon: const Icon(Icons.keyboard_arrow_up),
          ),
          IconButton(
            tooltip: 'Go to next match',
            onPressed: () {
              if (_searchResult == null) {
                _doSearch();
              }
              _searchResult?.nextInstance();
            },
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
          IconButton(
            tooltip: 'Bookmark this page',
            onPressed: () {
              final page = _controller.pageNumber;
              bookmarks.toggleBookmark(bookId: widget.bookId, page: page);
              final isBm = bookmarks.isBookmarked(
                bookId: widget.bookId,
                page: page,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isBm ? 'Bookmarked page $page' : 'Removed bookmark $page',
                  ),
                ),
              );
            },
            icon: Icon(
              bookmarks.isBookmarked(
                    bookId: widget.bookId,
                    page: _controller.pageNumber,
                  )
                  ? Icons.bookmark
                  : Icons.bookmark_border,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Find in book...',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _doSearch(),
            ),
          ),
        ),
      ),
      body: SfPdfViewer.asset(
        widget.assetPath,
        controller: _controller,
        canShowPaginationDialog: true,
        canShowScrollHead: true,
      ),
      drawer: Drawer(
        child: DefaultTabController(
          length: 1,
          child: Column(
            children: [
              DrawerHeader(child: Text(widget.title)),
              const TabBar(
                tabs: [Tab(icon: Icon(Icons.bookmarks), text: 'Bookmarks')],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ListView(
                      children: [
                        _GoToTocTile(
                          bookId: widget.bookId,
                          onJump: (p) {
                            Navigator.of(context).pop();
                            _controller.jumpToPage(p);
                          },
                        ),
                        if (bookmarkPages.isEmpty)
                          const ListTile(
                            leading: Icon(Icons.info_outline),
                            title: Text('No bookmarks yet'),
                            subtitle: Text(
                              'Use the bookmark icon in the app bar to save pages.',
                            ),
                          ),
                        for (final page in bookmarkPages)
                          ListTile(
                            leading: const Icon(Icons.bookmark),
                            title: Text('Page $page'),
                            onTap: () {
                              Navigator.of(context).pop();
                              _controller.jumpToPage(page);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndexList extends StatelessWidget {
  const _IndexList({required this.bookId, required this.onJump});
  final String bookId;
  final ValueChanged<int> onJump;
  @override
  Widget build(BuildContext context) {
    final indexProvider = context.watch<IndexProvider>();
    if (!indexProvider.ready) {
      return const Center(child: CircularProgressIndicator());
    }
    final entries = indexProvider.getIndex(bookId);
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.only(
            left: 16.0 + e.level * 12.0,
            right: 16,
          ),
          title: Text(e.title),
          trailing: Text('p${e.page}'),
          onTap: () => onJump(e.page),
        );
      },
    );
  }
}

class _GoToIndexTile extends StatelessWidget {
  const _GoToIndexTile({required this.bookId, required this.onJump});
  final String bookId;
  final ValueChanged<int> onJump;
  @override
  Widget build(BuildContext context) {
    final indexProvider = context.read<IndexProvider>();
    final page = indexProvider.findIndexPage(bookId);
    return ListTile(
      leading: const Icon(Icons.list_alt),
      title: const Text('Go to Index'),
      subtitle: page != null ? Text('Page $page') : const Text('Scanning...'),
      enabled: page != null,
      onTap: page != null ? () => onJump(page) : null,
    );
  }
}

class _GoToTocTile extends StatelessWidget {
  const _GoToTocTile({required this.bookId, required this.onJump});
  final String bookId;
  final ValueChanged<int> onJump;
  @override
  Widget build(BuildContext context) {
    final indexProvider = context.read<IndexProvider>();
    final page = indexProvider.findTocPage(bookId);
    return ListTile(
      leading: const Icon(Icons.menu_book),
      title: const Text('Go to Table of Contents'),
      subtitle: page != null ? Text('Page $page') : const Text('Scanning...'),
      enabled: page != null,
      onTap: page != null ? () => onJump(page) : null,
    );
  }
}
