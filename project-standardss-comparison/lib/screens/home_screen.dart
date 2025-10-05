import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/search_provider.dart';
import 'reader_screen.dart';
import 'parallel_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recent = context.watch<SearchProvider>().recent;
    final books = [
      _BookInfo('PMBOK 7', 'assets/pmbok7.pdf', 'pmbok7'),
      _BookInfo('PRINCE2 (7th)', 'assets/prince2.pdf', 'prince2'),
      _BookInfo('ISO 21502', 'assets/iso21502.pdf', 'iso21502'),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchBar(
            controller: _controller,
            recent: recent,
            onSubmitted: (q) {
              context.read<SearchProvider>().addRecent(q);
              // Navigate to parallel search showing results from all books
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ParallelSearchScreen(query: q),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text('Library', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [for (final b in books) _BookCard(book: b)],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.recent,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final List<String> recent;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search across all 3 standards (PMBOK, PRINCE2, ISO)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: onSubmitted,
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final q in recent)
                ActionChip(
                  avatar: const Icon(Icons.history, size: 16),
                  label: Text(q),
                  onPressed: () => onSubmitted(q),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book});

  final _BookInfo book;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (_) => ReaderScreen(
                  title: book.title,
                  assetPath: book.assetPath,
                  bookId: book.bookId,
                ),
          ),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Icon(
                    Icons.menu_book,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(book.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Tap to open', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookInfo {
  const _BookInfo(this.title, this.assetPath, this.bookId);
  final String title;
  final String assetPath;
  final String bookId;
}
