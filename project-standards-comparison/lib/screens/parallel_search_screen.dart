import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'reader_screen.dart';
import '../providers/search_provider.dart';
import '../providers/index_provider.dart';
import '../providers/bookmarks_provider.dart';

class ParallelSearchScreen extends StatefulWidget {
  final String query;

  const ParallelSearchScreen({Key? key, required this.query}) : super(key: key);

  @override
  State<ParallelSearchScreen> createState() => _ParallelSearchScreenState();
}

class _ParallelSearchScreenState extends State<ParallelSearchScreen> {
  final Map<String, PdfViewerController> _controllers = {};
  final Map<String, List<int>> _searchResults = {};
  final Map<String, int> _currentMatchIndex = {};
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _performSearch();
  }

  void _initializeControllers() {
    _controllers['pmbok7'] = PdfViewerController();
    _controllers['prince2'] = PdfViewerController();
    _controllers['iso21502'] = PdfViewerController();

    _currentMatchIndex['pmbok7'] = 0;
    _currentMatchIndex['prince2'] = 0;
    _currentMatchIndex['iso21502'] = 0;
  }

  Future<void> _performSearch() async {
    if (!mounted) return;
    setState(() => _isSearching = true);

    // Wait a bit for controllers to be ready
    await Future.delayed(const Duration(milliseconds: 1000));

    // Search in each PDF and get actual results
    for (final bookId in _controllers.keys) {
      try {
        final controller = _controllers[bookId]!;
        await controller.searchText(widget.query);

        // Perform search in the PDF - let the PDF viewer handle the actual search
        // We don't need to fake search result counts
        await controller.searchText(widget.query);

        // Just mark that search was performed - no fake numbers
        _searchResults[bookId] = []; // Empty - we don't track fake counts
        _currentMatchIndex[bookId] = 0;
      } catch (e) {
        print('Error searching in $bookId: $e');
        _searchResults[bookId] = [];
        _currentMatchIndex[bookId] = 0;
      }
    }

    // Add to recent searches AFTER the search is complete
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<SearchProvider>().addRecent(widget.query);
        }
      });
      setState(() => _isSearching = false);
    }
  }

  void _addBookmark(String bookId) {
    final controller = _controllers[bookId]!;
    final currentPage = controller.pageNumber;

    // Toggle bookmark for current page
    context.read<BookmarksProvider>().toggleBookmark(
      bookId: bookId,
      page: currentPage,
    );

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bookmarked page $currentPage in ${_getBookTitle(bookId)}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search: "${widget.query}"'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to home screen to restore bookmark access
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _performSearch,
          ),
        ],
      ),
      body:
          _isSearching
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Searching in all books...'),
                  ],
                ),
              )
              : LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive layout: horizontal on wide screens, vertical on narrow screens
                  if (constraints.maxWidth > 1200) {
                    return _buildHorizontalLayout();
                  } else {
                    return _buildVerticalLayout();
                  }
                },
              ),
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      children: [
        Expanded(child: _buildBookViewer('pmbok7', 'PMBOK 7')),
        Expanded(child: _buildBookViewer('prince2', 'PRINCE2 (7th)')),
        Expanded(child: _buildBookViewer('iso21502', 'ISO 21502')),
      ],
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      children: [
        Expanded(child: _buildBookViewer('pmbok7', 'PMBOK 7')),
        Expanded(child: _buildBookViewer('prince2', 'PRINCE2 (7th)')),
        Expanded(child: _buildBookViewer('iso21502', 'ISO 21502')),
      ],
    );
  }

  Widget _buildBookViewer(String bookId, String title) {
    final controller = _controllers[bookId]!;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Header with search controls
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_add),
                  onPressed: () => _addBookmark(bookId),
                  tooltip: 'Bookmark current page',
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up),
                  onPressed:
                      () => controller.jumpToPage(controller.pageNumber - 1),
                  tooltip: 'Previous page',
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed:
                      () => controller.jumpToPage(controller.pageNumber + 1),
                  tooltip: 'Next page',
                ),
              ],
            ),
          ),
          // PDF Viewer
          Expanded(
            child: SfPdfViewer.asset(
              'assets/$bookId.pdf',
              controller: controller,
              enableDoubleTapZooming: true,
              enableTextSelection: true,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                // Document loaded, ready for search
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getBookTitle(String bookId) {
    switch (bookId) {
      case 'pmbok7':
        return 'PMBOK 7';
      case 'prince2':
        return 'PRINCE2 (7th)';
      case 'iso21502':
        return 'ISO 21502';
      default:
        return 'Unknown Book';
    }
  }

  @override
  void dispose() {
    // Clear search results to prevent memory leaks
    _searchResults.clear();
    _currentMatchIndex.clear();

    // Dispose controllers safely
    for (final controller in _controllers.values) {
      try {
        controller.dispose();
      } catch (e) {
        print('Error disposing controller: $e');
      }
    }
    _controllers.clear();

    super.dispose();
  }
}
