import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/search_provider.dart';
import '../providers/index_provider.dart';
import '../widgets/enhanced_search_bar.dart';
import '../widgets/visual_feedback_helper.dart';
import 'reader_screen.dart';
import 'parallel_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('first_time_user') ?? true;
    if (isFirstTime) {
      setState(() {
        _showOnboarding = true;
      });
    }
  }

  Future<void> _dismissOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time_user', false);
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IndexProvider>(
      builder: (context, indexProvider, child) {
        final books = [
          _BookInfo(
            'PMBOK 7',
            'assets/pmbok7.pdf',
            'pmbok7',
            'Project Management Body of Knowledge',
            'PDF • 7th Edition',
            indexProvider.isBookIndexed('pmbok7'),
            indexProvider.getBookProgress('pmbok7'),
          ),
          _BookInfo(
            'PRINCE2 (7th)',
            'assets/prince2.pdf',
            'prince2',
            'PRojects IN Controlled Environments',
            'PDF • 7th Edition',
            indexProvider.isBookIndexed('prince2'),
            indexProvider.getBookProgress('prince2'),
          ),
          _BookInfo(
            'ISO 21502',
            'assets/iso21502.pdf',
            'iso21502',
            'Project, programme and portfolio management',
            'PDF • ISO Standard',
            indexProvider.isBookIndexed('iso21502'),
            indexProvider.getBookProgress('iso21502'),
          ),
        ];

        return Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EnhancedSearchBar(
                      hintText:
                          'Search across all 3 standards (PMBOK, PRINCE2, ISO)',
                      onSubmitted: (query) {
                        // Navigate to parallel search showing results from all books
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ParallelSearchScreen(query: query),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildTopicChips(context),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Library',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (indexProvider.isIndexing)
                          Row(
                            children: [
                              VisualFeedbackHelper.pulsingDot(
                                color: Theme.of(context).colorScheme.primary,
                                size: 12,
                              ),
                              const SizedBox(width: 8),
                              VisualFeedbackHelper.statusIndicator(
                                status: 'indexing',
                                size: 14,
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 700 ? 3 : 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                      children: [for (final b in books) _BookCard(book: b)],
                    ),
                  ],
                ),
              ),
            ),
            if (_showOnboarding) _buildOnboardingOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildTopicChips(BuildContext context) {
    // 18 predefined topics - EXACTLY matching topics.json
    final predefinedTopics = [
      "Governance and Roles",
      "Project Life Cycle / Phases",
      "Planning and Scope Management",
      "Risk and Uncertainty Management",
      "Quality Management",
      "Stakeholder and Communication Management",
      "Change and Issue Management",
      "Benefits / Value Realization",
      "Tailoring and Adaptability",
      "Lessons Learned / Continuous Improvement",
      "Integration and Coordination",
      "Procurement and Resource Management",
      "Communication Management",
      "Performance Measurement and Progress",
      "Sustainability and Social Responsibility",
      "Schedule Management",
      "Cost Management",
      "LifeCycle and Approach",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.topic,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Topic Search',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () {
                // Navigate to Compare screen
                DefaultTabController.of(context).animateTo(1);
              },
              icon: const Icon(Icons.compare_arrows, size: 18),
              label: const Text('Compare All'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Enhanced topic chips grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              predefinedTopics.map((topicName) {
                return _buildEnhancedTopicChip(context, topicName);
              }).toList(),
        ),

        const SizedBox(height: 16),

        // Quick stats
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${predefinedTopics.length} predefined topics available for instant comparison across all standards',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedTopicChip(BuildContext context, String topicName) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Add to recent searches
          context.read<SearchProvider>().addRecent(topicName);

          // Navigate directly to search results (this is what users expect)
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ParallelSearchScreen(query: topicName),
            ),
          );

          // Show brief feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Searching for "$topicName" across all standards...',
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.1),
                Theme.of(
                  context,
                ).colorScheme.secondaryContainer.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getTopicIcon(topicName),
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  topicName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTopicIcon(String topicName) {
    switch (topicName) {
      case "Governance and Roles":
        return Icons.account_tree;
      case "Project Life Cycle / Phases":
        return Icons.timeline;
      case "Planning and Scope Management":
        return Icons.assignment;
      case "Risk and Uncertainty":
        return Icons.warning_amber;
      case "Quality Management":
        return Icons.verified;
      case "Stakeholder and Communication":
        return Icons.people;
      case "Change and Issue Management":
        return Icons.change_circle;
      case "Benefits / Value Realization":
        return Icons.trending_up;
      case "Tailoring and Adaptability":
        return Icons.tune;
      case "Lessons Learned / Continuous Improvement":
        return Icons.school;
      case "Integration and Coordination":
        return Icons.hub;
      case "Procurement and Resource Management":
        return Icons.inventory;
      case "Communication Management":
        return Icons.forum;
      case "Performance Measurement and Progress":
        return Icons.analytics;
      case "Sustainability and Social Responsibility":
        return Icons.eco;
      case "Schedule Management":
        return Icons.schedule;
      case "Cost Management":
        return Icons.attach_money;
      case "LifeCycle and Approach":
        return Icons.route;
      default:
        return Icons.topic;
    }
  }

  Widget _buildOnboardingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.library_books,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome to PM Standards App',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Compare and analyze project management standards:\n'
                '• Search across PMBOK, PRINCE2, and ISO 21502\n'
                '• Use topic chips for quick comparisons\n'
                '• Bookmark important passages\n'
                '• Export and share your findings',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: _dismissOnboarding,
                    child: const Text('Skip'),
                  ),
                  ElevatedButton(
                    onPressed: _dismissOnboarding,
                    child: const Text('Get Started'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
            color:
                book.isIndexed
                    ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.outlineVariant,
          ),
          color:
              book.isIndexed
                  ? Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.1)
                  : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  VisualFeedbackHelper.statusIndicator(
                    status: book.isIndexed ? 'ready' : 'indexing',
                    size: 12,
                  ),
                  if (book.progress > 0)
                    Text(
                      '${(book.progress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Book icon and progress
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (book.progress > 0 && book.progress < 1)
                          SizedBox(
                            width: 72,
                            height: 72,
                            child: CircularProgressIndicator(
                              value: book.progress,
                              strokeWidth: 3,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        Icon(
                          Icons.menu_book,
                          size: 48,
                          color:
                              book.isIndexed
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Book title and metadata
              Text(
                book.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                book.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                book.metadata,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Action text
              Text(
                book.isIndexed ? 'Tap to open' : 'Preparing...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      book.isIndexed
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookInfo {
  const _BookInfo(
    this.title,
    this.assetPath,
    this.bookId,
    this.subtitle,
    this.metadata,
    this.isIndexed,
    this.progress,
  );

  final String title;
  final String assetPath;
  final String bookId;
  final String subtitle;
  final String metadata;
  final bool isIndexed;
  final double progress;
}
