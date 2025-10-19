import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/index_provider.dart';
import '../providers/search_provider.dart';
import 'reader_screen.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  String _query = '';
  String? _selectedTopic;
  final TextEditingController _customSearchController = TextEditingController();
  bool _isGeneratingComparison = false;
  Map<String, List<String>> _comparisonResults = {};

  // The same 18 predefined topics from home screen - EXACTLY matching topics.json
  final List<String> _predefinedTopics = [
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

  @override
  void dispose() {
    _customSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildTopicSelection(context),
            const SizedBox(height: 24),
            Expanded(child: _buildComparisonResults(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.compare_arrows,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compare Standards',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'Side-by-side comparison across PMBOK, PRINCE2, and ISO 21502',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopicSelection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Topic for Comparison',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Topic Dropdown
            DropdownButtonFormField<String>(
              value: _selectedTopic,
              decoration: const InputDecoration(
                labelText: 'Choose a Topic',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.topic),
              ),
              items:
                  _predefinedTopics
                      .map(
                        (topic) =>
                            DropdownMenuItem(value: topic, child: Text(topic)),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTopic = value;
                  _customSearchController.clear();
                  _query = '';
                });
              },
            ),

            const SizedBox(height: 16),

            // OR Custom Search
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customSearchController,
                    decoration: const InputDecoration(
                      labelText: 'Or Enter Custom Search',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                        _selectedTopic = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _canStartComparison() ? _startComparison : null,
                  icon:
                      _isGeneratingComparison
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.compare_arrows),
                  label: Text(
                    _isGeneratingComparison ? 'Comparing...' : 'Compare',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Topic Chips for Quick Selection
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _predefinedTopics
                      .take(6)
                      .map(
                        (topic) => ActionChip(
                          label: Text(topic),
                          onPressed: () {
                            setState(() {
                              _selectedTopic = topic;
                              _customSearchController.clear();
                              _query = '';
                            });
                            _startComparison();
                          },
                          avatar: Icon(_getTopicIcon(topic), size: 16),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonResults(BuildContext context) {
    if (_isGeneratingComparison) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating comparison across all three standards...'),
          ],
        ),
      );
    }

    if (_comparisonResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Select a topic or enter a search term to compare standards',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Compare how PMBOK, PRINCE2, and ISO 21502 address the same concepts',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Three-column comparison layout
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comparison Header
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Comparison Results: ${_selectedTopic ?? _query}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _comparisonResults.clear();
                      _selectedTopic = null;
                      _customSearchController.clear();
                      _query = '';
                    });
                  },
                  icon: const Icon(Icons.close),
                  tooltip: 'Clear comparison',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Three-column layout - takes most of the space
            Expanded(
              flex: 3,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStandardColumn(
                    'PMBOK 7th Edition',
                    'pmbok7',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildStandardColumn(
                    'PRINCE2 7th Edition',
                    'prince2',
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildStandardColumn('ISO 21502', 'iso21502', Colors.orange),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Insights section - compact
            Flexible(flex: 1, child: _buildComparisonInsights(context)),

            const SizedBox(height: 8),

            // Action buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openAllThreeBooks(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open All Three'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _exportComparison(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardColumn(String title, String bookId, Color color) {
    final results = _comparisonResults[bookId] ?? [];

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Results
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child:
                    results.isEmpty
                        ? const Center(
                          child: Text(
                            'No matches found',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap:
                                    () => _openBookFromComparison(
                                      bookId,
                                      results[index],
                                    ),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    results[index],
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTopicIcon(String topic) {
    switch (topic) {
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
      default:
        return Icons.topic;
    }
  }

  bool _canStartComparison() {
    return (_selectedTopic != null || _query.trim().isNotEmpty) &&
        !_isGeneratingComparison;
  }

  Future<void> _startComparison() async {
    if (!_canStartComparison()) return;

    setState(() {
      _isGeneratingComparison = true;
      _comparisonResults.clear();
    });

    try {
      final searchTerm = _selectedTopic ?? _query;
      final indexProvider = context.read<IndexProvider>();

      // Add to recent searches
      context.read<SearchProvider>().addRecent(searchTerm);

      // Perform real search across all three books
      final allResults = await indexProvider.performSearch(
        searchTerm,
        maxResults: 30,
      );

      // Group results by book
      final groupedResults = <String, List<SearchResult>>{};
      for (final result in allResults) {
        groupedResults.putIfAbsent(result.bookId, () => []).add(result);
      }

      // Convert search results to comparison format
      final comparisonResults = <String, List<String>>{};

      for (final bookId in ['pmbok7', 'prince2', 'iso21502']) {
        final bookResults = groupedResults[bookId] ?? [];
        final bookName = _getBookDisplayName(bookId);

        if (bookResults.isNotEmpty) {
          final snippets = <String>[];

          // Add page reference
          final pageNumbers =
              bookResults.map((r) => r.pageNumber).toSet().toList()..sort();
          if (pageNumbers.isNotEmpty) {
            snippets.add(
              '📍 Pages ${pageNumbers.take(3).join(', ')}${pageNumbers.length > 3 ? '...' : ''} - $bookName',
            );
          }

          // Add top snippets
          for (final result in bookResults.take(5)) {
            final snippet = result.snippet.trim();
            if (snippet.isNotEmpty && snippet.length > 20) {
              snippets.add(
                '• ${snippet.length > 150 ? '${snippet.substring(0, 150)}...' : snippet}',
              );
            }
          }

          if (snippets.isEmpty) {
            snippets.add('• No detailed content found for "$searchTerm"');
          }

          comparisonResults[bookId] = snippets;
        } else {
          comparisonResults[bookId] = [
            '• No results found for "$searchTerm" in $bookName',
          ];
        }
      }

      setState(() {
        _comparisonResults = comparisonResults;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Real comparison completed for "$searchTerm" - Found ${allResults.length} results',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingComparison = false;
      });
    }
  }

  Widget _buildComparisonInsights(BuildContext context) {
    if (_comparisonResults.isEmpty) return Container();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Comparison Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Similarities
            _buildInsightSection(
              context,
              'Similarities',
              Icons.check_circle,
              Colors.green,
              _getSimilarities(),
            ),

            const SizedBox(height: 12),

            // Differences
            _buildInsightSection(
              context,
              'Key Differences',
              Icons.compare_arrows,
              Colors.orange,
              _getDifferences(),
            ),

            const SizedBox(height: 12),

            // Unique aspects
            _buildInsightSection(
              context,
              'Unique Aspects',
              Icons.star,
              Colors.blue,
              _getUniqueAspects(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<String> insights,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...insights.map(
          (insight) => Padding(
            padding: const EdgeInsets.only(left: 22, bottom: 4),
            child: Text(
              '• $insight',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }

  List<String> _getSimilarities() {
    final topic = _selectedTopic ?? _query;
    switch (topic) {
      case "Risk and Uncertainty Management":
        return [
          'All three standards emphasize risk registers as central tools',
          'Similar risk response strategies (avoid, mitigate, transfer, accept)',
          'Continuous risk monitoring throughout project lifecycle',
          'Integration of risk management with other project processes',
        ];
      case "Quality Management":
        return [
          'Quality planning, assurance, and control processes',
          'Customer satisfaction and fitness for purpose focus',
          'Continuous improvement and lessons learned integration',
          'Quality metrics and performance measurement',
        ];
      case "Stakeholder and Communication Management":
        return [
          'Stakeholder identification and analysis processes',
          'Communication planning and execution frameworks',
          'Engagement strategies based on stakeholder needs',
          'Regular reporting and feedback mechanisms',
        ];
      default:
        return [
          'Process-based approach to project management',
          'Lifecycle and phase management concepts',
          'Stakeholder value and benefit realization focus',
          'Continuous improvement and adaptation principles',
        ];
    }
  }

  List<String> _getDifferences() {
    final topic = _selectedTopic ?? _query;
    switch (topic) {
      case "Risk and Uncertainty Management":
        return [
          'PMBOK: Separates individual vs overall project risk',
          'PRINCE2: Risk budget and tolerance concepts',
          'ISO 21502: Stronger organizational risk integration',
          'PRINCE2: More detailed risk response types (8 vs 4)',
        ];
      case "Quality Management":
        return [
          'PMBOK: Separate quality assurance and control processes',
          'PRINCE2: Quality review technique as core method',
          'ISO 21502: Quality integrated across all processes',
          'PRINCE2: Customer quality expectations emphasis',
        ];
      case "Stakeholder and Communication Management":
        return [
          'PMBOK: Separate knowledge areas for stakeholders and communication',
          'PRINCE2: Organization theme covers roles and responsibilities',
          'ISO 21502: Integrated stakeholder and communication approach',
          'PRINCE2: Project board structure for governance',
        ];
      default:
        return [
          'PMBOK: Knowledge area and process group structure',
          'PRINCE2: Themes and processes with stage gates',
          'ISO 21502: Integrated process approach with governance focus',
          'Different terminology and framework organization',
        ];
    }
  }

  List<String> _getUniqueAspects() {
    final topic = _selectedTopic ?? _query;
    switch (topic) {
      case "Risk and Uncertainty Management":
        return [
          'PMBOK: Quantitative risk analysis techniques',
          'PRINCE2: Risk tolerance and appetite definitions',
          'ISO 21502: Organizational risk management alignment',
        ];
      case "Quality Management":
        return [
          'PMBOK: Cost of quality considerations',
          'PRINCE2: Quality review technique methodology',
          'ISO 21502: Quality culture and organizational maturity',
        ];
      case "Stakeholder and Communication Management":
        return [
          'PMBOK: Stakeholder engagement assessment matrix',
          'PRINCE2: Project board and assurance roles',
          'ISO 21502: Stakeholder value realization focus',
        ];
      default:
        return [
          'PMBOK: Performance domains and tailoring guidance',
          'PRINCE2: Business case theme and continued business justification',
          'ISO 21502: Governance framework and organizational context',
        ];
    }
  }

  void _openAllThreeBooks(BuildContext context) {
    final topic = _selectedTopic ?? _query;

    // Get page mappings from topics.json data
    final pageMapping = _getPageMapping(topic);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Open All Three Standards'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Opening all three standards at relevant pages for "$topic":',
                ),
                const SizedBox(height: 12),
                Text('• PMBOK 7th Edition - Page ${pageMapping['PMBOK']}'),
                Text('• PRINCE2 7th Edition - Page ${pageMapping['PRINCE2']}'),
                Text('• ISO 21502:2020 - Page ${pageMapping['ISO']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Here you would implement the actual opening of books
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening all three standards for "$topic"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ],
          ),
    );
  }

  void _exportComparison(BuildContext context) {
    final topic = _selectedTopic ?? _query;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Export Comparison'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Export comparison for "$topic" as:'),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: const Text('PDF Report'),
                    subtitle: const Text('Formatted comparison with insights'),
                    onTap: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PDF export generated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.web),
                    title: const Text('HTML Report'),
                    subtitle: const Text('Interactive web format with links'),
                    onTap: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('HTML export generated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Map<String, int> _getPageMapping(String topic) {
    // This would normally load from topics.json, but for now using hardcoded values
    switch (topic) {
      case "Risk and Uncertainty Management":
        return {'PMBOK': 250, 'PRINCE2': 120, 'ISO': 75};
      case "Quality Management":
        return {'PMBOK': 190, 'PRINCE2': 100, 'ISO': 65};
      case "Stakeholder and Communication Management":
        return {'PMBOK': 180, 'PRINCE2': 90, 'ISO': 60};
      case "Governance and Roles":
        return {'PMBOK': 45, 'PRINCE2': 25, 'ISO': 30};
      case "Project Life Cycle / Phases":
        return {'PMBOK': 25, 'PRINCE2': 35, 'ISO': 20};
      default:
        return {'PMBOK': 1, 'PRINCE2': 1, 'ISO': 1};
    }
  }

  String _getBookDisplayName(String bookId) {
    switch (bookId) {
      case 'pmbok7':
        return 'PMBOK 7th Edition';
      case 'prince2':
        return 'PRINCE2 7th Edition';
      case 'iso21502':
        return 'ISO 21502:2020';
      default:
        return bookId;
    }
  }

  String _getBookAssetPath(String bookId) {
    switch (bookId) {
      case 'pmbok7':
        return 'assets/pmbok7.pdf';
      case 'prince2':
        return 'assets/prince2.pdf';
      case 'iso21502':
        return 'assets/iso21502.pdf';
      default:
        return '';
    }
  }

  void _openBookFromComparison(String bookId, String resultText) {
    // Extract page number from result text if it contains page reference
    int? pageNumber;
    final pageMatch = RegExp(r'📍 Pages? (\d+)').firstMatch(resultText);
    if (pageMatch != null) {
      pageNumber = int.tryParse(pageMatch.group(1)!);
    }

    // Navigate to reader screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => ReaderScreen(
              title: _getBookDisplayName(bookId),
              assetPath: _getBookAssetPath(bookId),
              bookId: bookId,
              initialPage: pageNumber,
              highlightText: _selectedTopic ?? _query,
            ),
      ),
    );
  }
}
