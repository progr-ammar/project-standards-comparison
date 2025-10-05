import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'reader_screen.dart';
import '../providers/index_provider.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  String _query = '';
  List<Map<String, dynamic>> _topics = [];
  Map<String, Map<String, dynamic>> _cache = {};

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/compare_topics.json',
      );
      final Map<String, dynamic> data = json.decode(jsonString);
      setState(() {
        _topics = List<Map<String, dynamic>>.from(data['topics'] ?? []);
      });
    } catch (e) {
      debugPrint('Error loading topics: $e');
    }
  }

  List<Map<String, dynamic>> _getFilteredTopics() {
    if (_query.isEmpty) return _topics;

    return _topics.where((topic) {
      final name = topic['name']?.toString().toLowerCase() ?? '';
      final synonyms =
          (topic['synonyms'] as List?)
              ?.map((s) => s.toString().toLowerCase())
              .toList() ??
          [];
      final searchQuery = _query.toLowerCase();

      return name.contains(searchQuery) ||
          synonyms.any((synonym) => synonym.contains(searchQuery));
    }).toList();
  }

  Map<String, dynamic> _getCachedInsights(String topicName) {
    if (_cache.containsKey(topicName)) {
      return _cache[topicName]!;
    }

    final topic = _topics.firstWhere(
      (t) => t['name'] == topicName,
      orElse: () => <String, dynamic>{},
    );

    if (topic.isEmpty) return {};

    final pages = topic['pages'] as Map<String, dynamic>? ?? {};
    final indexProvider = context.read<IndexProvider>();

    // Generate insights based on topic and pages
    final insights = _generateInsights(topicName, pages);

    _cache[topicName] = insights;
    return insights;
  }

  Map<String, dynamic> _generateInsights(
    String topicName,
    Map<String, dynamic> pages,
  ) {
    // Generate 3-4 line summaries for each category
    final similarities = _getSimilarities(topicName);
    final differences = _getDifferences(topicName);
    final unique = _getUniquePoints(topicName);

    return {
      'Similarities': similarities,
      'Differences': differences,
      'Unique': unique,
    };
  }

  List<String> _getSimilarities(String topicName) {
    switch (topicName) {
      case 'Risk Management':
        return [
          'All three standards emphasize proactive risk identification and assessment as fundamental to project success.',
          'Each framework requires systematic risk monitoring and response planning throughout the project lifecycle.',
          'Risk registers or similar documentation tools are mandated across all methodologies for tracking and communication.',
          'The importance of stakeholder involvement in risk management processes is consistently highlighted.',
        ];
      case 'Governance & Roles':
        return [
          'Clear definition of roles and responsibilities is a core principle across all three standards.',
          'Decision-making authority and escalation procedures are explicitly defined in each framework.',
          'Management by exception principles are consistently applied for efficient governance.',
          'Regular reporting and communication structures are established to maintain oversight.',
        ];
      case 'Stakeholder & Communication':
        return [
          'Stakeholder identification and analysis is a mandatory first step in all methodologies.',
          'Communication planning and execution are treated as critical success factors.',
          'Regular stakeholder engagement and feedback mechanisms are required throughout projects.',
          'Information distribution and reporting follow structured approaches across all standards.',
        ];
      default:
        return [
          'All three standards provide comprehensive frameworks for managing this aspect of project delivery.',
          'Systematic approaches to planning, execution, and monitoring are consistently emphasized.',
          'Documentation and communication requirements are clearly defined across methodologies.',
          'Continuous improvement and lessons learned integration is a common theme.',
        ];
    }
  }

  List<String> _getDifferences(String topicName) {
    switch (topicName) {
      case 'Risk Management':
        return [
          'PMBOK focuses on quantitative risk analysis and Monte Carlo simulations, while PRINCE2 emphasizes risk ownership and tolerance levels.',
          'ISO 21502 integrates risk management more closely with organizational governance structures.',
          'PRINCE2 uniquely requires risk owners for each identified risk, while PMBOK uses risk managers.',
          'ISO 21502 places greater emphasis on risk management maturity and organizational capability.',
        ];
      case 'Governance & Roles':
        return [
          'PMBOK defines project manager as primary authority, while PRINCE2 distributes authority across multiple roles.',
          'PRINCE2 uniquely implements Project Board structure with Executive, Senior User, and Senior Supplier roles.',
          'ISO 21502 emphasizes governance maturity levels and organizational project management capability.',
          'PMBOK focuses on individual project manager competencies, while others emphasize organizational structures.',
        ];
      case 'Stakeholder & Communication':
        return [
          'PMBOK provides detailed stakeholder analysis matrices, while PRINCE2 focuses on communication management strategy.',
          'ISO 21502 integrates stakeholder management with organizational communication frameworks.',
          'PRINCE2 uniquely requires communication management strategy as a mandatory project document.',
          'PMBOK emphasizes stakeholder engagement assessment, while others focus on communication planning.',
        ];
      default:
        return [
          'Terminology and specific processes vary significantly between the three standards.',
          'Each framework emphasizes different aspects based on their organizational focus and maturity.',
          'Implementation approaches differ based on project complexity and organizational context.',
          'Documentation requirements and templates vary across methodologies.',
        ];
    }
  }

  Map<String, String> _getUniquePoints(String topicName) {
    switch (topicName) {
      case 'Risk Management':
        return {
          'PMBOK':
              'Quantitative risk analysis using Monte Carlo simulations and decision tree analysis for complex risk scenarios.',
          'PRINCE2':
              'Risk tolerance levels and risk ownership model where each risk must have an assigned owner.',
          'ISO 21502':
              'Risk management maturity assessment and integration with organizational governance frameworks.',
        };
      case 'Governance & Roles':
        return {
          'PMBOK':
              'Project manager as single point of accountability with comprehensive competency framework.',
          'PRINCE2':
              'Project Board structure with three distinct roles and management by exception principles.',
          'ISO 21502':
              'Organizational project management capability maturity model and governance framework integration.',
        };
      case 'Stakeholder & Communication':
        return {
          'PMBOK':
              'Stakeholder engagement assessment matrix and comprehensive communication management plan.',
          'PRINCE2':
              'Communication management strategy as mandatory document with specific reporting requirements.',
          'ISO 21502':
              'Integration with organizational communication frameworks and stakeholder management maturity.',
        };
      default:
        return {
          'PMBOK':
              'Comprehensive knowledge areas with detailed processes and tools for each aspect.',
          'PRINCE2':
              'Product-based planning approach with focus on deliverables and quality criteria.',
          'ISO 21502':
              'Organizational maturity focus with emphasis on capability development and governance.',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final indexProvider = context.watch<IndexProvider>();
    if (!indexProvider.ready) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredTopics = _getFilteredTopics();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search topic (e.g., Risk Management, Governance)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredTopics.length,
            itemBuilder: (context, index) {
              final topic = filteredTopics[index];
              final topicName = topic['name'] as String;
              final pages = topic['pages'] as Map<String, dynamic>? ?? {};
              final insights = _getCachedInsights(topicName);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topicName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      _BookLinksRow(topic: topicName, pages: pages),
                      const SizedBox(height: 12),
                      if (insights.isNotEmpty)
                        _Insights(insight: insights, topic: topicName),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BookLinksRow extends StatelessWidget {
  const _BookLinksRow({required this.topic, required this.pages});

  final String topic;
  final Map<String, dynamic> pages;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _BookLink(
          label: 'PMBOK 7',
          page: pages['pmbok7'] as int?,
          onOpen:
              (page) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => ReaderScreen(
                        title: 'PMBOK 7',
                        assetPath: 'assets/pmbok7.pdf',
                        bookId: 'pmbok7',
                        initialPage: page,
                      ),
                ),
              ),
        ),
        _BookLink(
          label: 'PRINCE2',
          page: pages['prince2'] as int?,
          onOpen:
              (page) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => ReaderScreen(
                        title: 'PRINCE2 (7th)',
                        assetPath: 'assets/prince2.pdf',
                        bookId: 'prince2',
                        initialPage: page,
                      ),
                ),
              ),
        ),
        _BookLink(
          label: 'ISO 21502',
          page: pages['iso21502'] as int?,
          onOpen:
              (page) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => ReaderScreen(
                        title: 'ISO 21502',
                        assetPath: 'assets/iso21502.pdf',
                        bookId: 'iso21502',
                        initialPage: page,
                      ),
                ),
              ),
        ),
      ],
    );
  }
}

class _BookLink extends StatelessWidget {
  const _BookLink({
    required this.label,
    required this.page,
    required this.onOpen,
  });

  final String label;
  final int? page;
  final void Function(int page) onOpen;

  @override
  Widget build(BuildContext context) {
    final enabled = page != null;
    return FilledButton.tonalIcon(
      onPressed: enabled ? () => onOpen(page!) : null,
      icon: const Icon(Icons.open_in_new),
      label: Text(enabled ? '$label — page $page' : '$label — N/A'),
    );
  }
}

class _Insights extends StatelessWidget {
  const _Insights({required this.insight, required this.topic});
  final Map<String, dynamic> insight;
  final String topic;

  @override
  Widget build(BuildContext context) {
    final similarities =
        (insight['Similarities'] as List?)?.cast<String>() ?? const [];
    final differences =
        (insight['Differences'] as List?)?.cast<String>() ?? const [];
    final unique =
        (insight['Unique'] as Map?)?.cast<String, String>() ??
        const <String, String>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (similarities.isNotEmpty) ...[
          Text('Similarities', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          for (final s in similarities) _Bullet(s),
          const SizedBox(height: 8),
        ],
        if (differences.isNotEmpty) ...[
          Text('Differences', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          for (final s in differences) _Bullet(s),
          const SizedBox(height: 8),
        ],
        if (unique.isNotEmpty) ...[
          Text('Unique Points', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          for (final entry in unique.entries)
            _Bullet('${entry.key}: ${entry.value}'),
        ],
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [const Text('• '), Expanded(child: Text(text))],
      ),
    );
  }
}
