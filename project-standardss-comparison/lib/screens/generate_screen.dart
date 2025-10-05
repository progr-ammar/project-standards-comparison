import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import '../providers/index_provider.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final _formKey = GlobalKey<FormState>();
  String _projectType = 'IT Software';
  String _complexity = 'Medium';
  String _delivery = 'Agile';
  String _governance = 'Moderate';
  String _riskAppetite = 'Balanced';
  bool _loading = false;
  bool _hasGenerated = false;
  late Future<Map<String, dynamic>> _rulesFuture;

  @override
  void initState() {
    super.initState();
    _rulesFuture = _loadRules();
  }

  Future<Map<String, dynamic>> _loadRules() async {
    final raw = await rootBundle.loadString('assets/tailoring_rules.json');
    final base = await rootBundle.loadString('assets/baseline_rules.json');
    final a = (json.decode(raw) as Map).cast<String, dynamic>();
    final b = (json.decode(base) as Map).cast<String, dynamic>();
    return {...b, ...a};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _rulesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final rules = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generate tailored process',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _Dropdown<String>(
                      label: 'Project type',
                      value: _projectType,
                      items: const [
                        'IT Software',
                        'Construction',
                        'Research',
                        'Event',
                        'Manufacturing',
                        'Healthcare',
                        'Education',
                        'Finance/Banking',
                        'Marketing',
                        'Telecommunications',
                        'Energy/Utilities',
                        'Oil & Gas',
                        'Mining',
                        'Agriculture',
                        'Logistics/Supply Chain',
                        'E‑commerce',
                        'Game Development',
                        'Data Science/AI',
                        'Cybersecurity',
                        'IoT/Embedded',
                        'Aerospace',
                        'Automotive',
                        'Pharmaceutical',
                        'Clinical Trial',
                        'Public Sector',
                        'Defense',
                        'Nonprofit/NGO',
                        'Real Estate Development',
                        'Hospitality',
                        'Retail',
                        'Media/Publishing',
                      ],
                      onChanged:
                          (v) => setState(() {
                            _projectType = v ?? _projectType;
                            _hasGenerated = false;
                          }),
                    ),
                    _Dropdown<String>(
                      label: 'Complexity',
                      value: _complexity,
                      items: const [
                        'Very Low',
                        'Low',
                        'Medium',
                        'High',
                        'Very High',
                      ],
                      onChanged:
                          (v) => setState(() {
                            _complexity = v ?? _complexity;
                            _hasGenerated = false;
                          }),
                    ),
                    _Dropdown<String>(
                      label: 'Delivery',
                      value: _delivery,
                      items: const [
                        'Agile',
                        'Hybrid',
                        'Predictive',
                        'Incremental',
                        'Iterative',
                      ],
                      onChanged:
                          (v) => setState(() {
                            _delivery = v ?? _delivery;
                            _hasGenerated = false;
                          }),
                    ),
                    _Dropdown<String>(
                      label: 'Governance',
                      value: _governance,
                      items: const ['Light', 'Moderate', 'Strict'],
                      onChanged:
                          (v) => setState(() {
                            _governance = v ?? _governance;
                            _hasGenerated = false;
                          }),
                    ),
                    _Dropdown<String>(
                      label: 'Risk appetite',
                      value: _riskAppetite,
                      items: const ['Low', 'Balanced', 'High'],
                      onChanged:
                          (v) => setState(() {
                            _riskAppetite = v ?? _riskAppetite;
                            _hasGenerated = false;
                          }),
                    ),
                    FilledButton.icon(
                      onPressed: () async {
                        setState(() {
                          _loading = true;
                          _hasGenerated = false;
                        });
                        await Future.delayed(const Duration(milliseconds: 400));
                        setState(() {
                          _loading = false;
                          _hasGenerated = true;
                        });
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_loading) const LinearProgressIndicator(),
              Expanded(
                child:
                    _loading || !_hasGenerated
                        ? const SizedBox.shrink()
                        : _Recommendations(
                          rules: rules,
                          projectType: _projectType,
                          complexity: _complexity,
                          delivery: _delivery,
                          governance: _governance,
                          riskAppetite: _riskAppetite,
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: [
          for (final it in items)
            DropdownMenuItem<T>(value: it, child: Text('$it')),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _Recommendations extends StatelessWidget {
  const _Recommendations({
    required this.rules,
    required this.projectType,
    required this.complexity,
    required this.delivery,
    required this.governance,
    required this.riskAppetite,
  });
  final Map<String, dynamic> rules;
  final String projectType;
  final String complexity;
  final String delivery;
  final String governance;
  final String riskAppetite;

  @override
  Widget build(BuildContext context) {
    final key = '$projectType|$complexity|$delivery';
    final rec = (rules[key] ?? const {}) as Map;
    final phases = (rec['phases'] as List?)?.cast<String>() ?? const [];
    final practices = (rec['practices'] as List?)?.cast<String>() ?? const [];
    final artifacts = (rec['artifacts'] as List?)?.cast<String>() ?? const [];
    final dynamicBoost = _aiBoost(context);

    // Merge baseline by project type
    final pt =
        (rules['projectType'] as Map?)?.cast<String, dynamic>()[projectType]
            as Map? ??
        const {};
    final ptPhases = (pt['phases'] as List?)?.cast<String>() ?? const [];
    final ptPractices = (pt['practices'] as List?)?.cast<String>() ?? const [];
    final ptArtifacts = (pt['artifacts'] as List?)?.cast<String>() ?? const [];

    final showPhases =
        (phases.isNotEmpty
            ? phases
            : (ptPhases.isNotEmpty ? ptPhases : _fallbackPhases()));
    final showPractices = _dedupe([
      if (practices.isEmpty && ptPractices.isEmpty) ..._fallbackPractices(),
      ...ptPractices,
      ...practices,
      ...dynamicBoost['practices']!,
    ]);
    final showArtifacts = _dedupe([
      if (artifacts.isEmpty && ptArtifacts.isEmpty) ..._fallbackArtifacts(),
      ...ptArtifacts,
      ...artifacts,
      ...dynamicBoost['artifacts']!,
    ]);

    return ListView(
      children: [
        _Section('Phases', showPhases),
        _Section('Key Practices', showPractices),
        _Section('Artifacts', showArtifacts),
      ],
    );
  }

  Map<String, List<String>> _aiBoost(BuildContext context) {
    final index = context.read<IndexProvider>();
    final hints = <String>[
      if (delivery == 'Agile' ||
          delivery == 'Incremental' ||
          delivery == 'Iterative')
        'iteration planning backlog scrum retrospective',
      if (delivery == 'Predictive')
        'wbs baseline plan change control stage gate earned value',
      if (delivery == 'Hybrid')
        'governance agile stage boundary change control backlog',
      if (riskAppetite == 'Low')
        'risk management mitigation contingency thresholds',
      if (riskAppetite == 'High') 'risk exploitation opportunity escalation',
      if (governance == 'Strict')
        'governance approvals stage boundaries exception reports tolerances',
      if (governance == 'Light') 'lightweight governance informal reviews',
      if (projectType.contains('Construction'))
        'quality assurance procurement contract safety method statements',
      if (projectType.contains('Research'))
        'ethics protocol hypothesis experiments findings reproducibility',
      if (projectType.contains('Manufacturing'))
        'process validation quality control sop',
      if (projectType.contains('Healthcare'))
        'clinical compliance privacy quality risk',
      if (projectType.contains('Education'))
        'curriculum stakeholders communication schedule',
      if (projectType.contains('Finance') || projectType.contains('Banking'))
        'compliance audit controls risk credit portfolio governance',
      if (projectType.contains('Marketing')) 'campaign brand channel analytics',
      if (projectType.contains('Telecommunications'))
        'network rollout sla qos spectrum',
      if (projectType.contains('Energy') || projectType.contains('Utilities'))
        'regulatory asset management outage safety',
      if (projectType.contains('Oil') || projectType.contains('Gas'))
        'hse permit drilling procurement',
      if (projectType.contains('Mining'))
        'site safety environmental permit logistics',
      if (projectType.contains('Agriculture'))
        'seasonal scheduling yield logistics',
      if (projectType.contains('Logistics') ||
          projectType.contains('Supply Chain'))
        'warehouse inventory routing lead time',
      if (projectType.contains('E‑commerce') ||
          projectType.contains('E-commerce'))
        'checkout conversion fulfillment returns',
      if (projectType.contains('Game Development'))
        'art assets gameplay engine release',
      if (projectType.contains('Data Science') || projectType.contains('AI'))
        'dataset bias model training evaluation mlops',
      if (projectType.contains('Cybersecurity'))
        'threat risk control incident response',
      if (projectType.contains('IoT') || projectType.contains('Embedded'))
        'firmware hardware certification',
      if (projectType.contains('Aerospace'))
        'certification safety testing configuration control',
      if (projectType.contains('Automotive')) 'apqp quality ppap testing',
      if (projectType.contains('Pharmaceutical')) 'gmp quality validation',
      if (projectType.contains('Clinical'))
        'protocol ethics enrollment regulatory',
      if (projectType.contains('Public Sector'))
        'procurement tender governance audit',
      if (projectType.contains('Defense')) 'security classification compliance',
      if (projectType.contains('Nonprofit') || projectType.contains('NGO'))
        'donor stakeholders impact reporting',
      if (projectType.contains('Real Estate')) 'permitting design build lease',
      if (projectType.contains('Hospitality'))
        'service quality operations rollout',
      if (projectType.contains('Retail')) 'store rollout merchandising supply',
      if (projectType.contains('Media') || projectType.contains('Publishing'))
        'editorial release rights licensing',
    ].join(' ');
    final pages = index.mapTopicToPages(hints);
    final texts = index.extractTextAroundPages(pages, radius: 0);
    final insight = index.computeInsights(texts);
    final practices = <String>[];
    final artifacts = <String>[];
    for (final s in (insight['Similarities'] as List? ?? const [])) {
      practices.add('Emphasize: $s');
    }
    for (final s in (insight['Differences'] as List? ?? const [])) {
      final ls = s.toString().toLowerCase();
      if (ls.contains('risk')) {
        practices.add('Risk review cadence');
        artifacts.add('Risk register updates');
      }
      if (ls.contains('baseline')) {
        practices.add('Baseline variance analysis');
      }
    }
    final unique = (insight['Unique'] as Map? ?? const {});
    for (final entry in unique.entries) {
      final source = entry.key.toString();
      final label =
          source == 'pmbok7'
              ? 'PMBOK'
              : source == 'iso21502'
              ? 'ISO'
              : source == 'prince2'
              ? 'PRINCE2'
              : source;
      final text = entry.value.toString();
      final cleaned = text
          .replaceAll(RegExp(r'[\[\]]'), '')
          .split(',')
          .take(3)
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .join(', ');
      if (cleaned.isNotEmpty) {
        artifacts.add('Reference: $label – $cleaned');
      }
    }

    if (delivery == 'Agile') {
      practices.addAll([
        'Sprint planning',
        'Daily stand-ups',
        'Sprint review',
        'Retrospective',
      ]);
      artifacts.addAll(['Product backlog', 'Sprint backlog', 'Increment']);
    } else if (delivery == 'Predictive') {
      practices.addAll([
        'Critical path scheduling',
        'Change control board',
        'Stage gate reviews',
      ]);
      artifacts.addAll([
        'WBS dictionary',
        'Schedule baseline',
        'Cost baseline',
      ]);
    } else if (delivery == 'Hybrid') {
      practices.addAll([
        'Stage boundary with backlog replan',
        'Dual-track discovery & delivery',
      ]);
      artifacts.addAll(['Roadmap', 'Release plan']);
    }

    if (governance == 'Strict') {
      practices.addAll([
        'Management by exception with tolerances',
        'Formal approvals at stage boundaries',
      ]);
      artifacts.addAll(['Exception report', 'Stage plan']);
    } else if (governance == 'Light') {
      practices.add('Lightweight change process');
    }

    if (complexity == 'High' || complexity == 'Very High') {
      practices.addAll([
        'Architecture/design reviews',
        'Risk workshop each stage',
        'Progressive elaboration',
      ]);
      artifacts.addAll(['Interface register', 'Technical debt log']);
    }

    if (projectType.contains('Research')) {
      practices.addAll(['Ethics review', 'Experiment protocol control']);
      artifacts.addAll(['Experiment log', 'Findings report']);
    }
    if (projectType.contains('Construction')) {
      practices.addAll(['Safety management plan', 'Quality inspections']);
      artifacts.addAll(['Method statements', 'Inspection test plan']);
    }

    return {
      'practices': practices.take(8).toList(),
      'artifacts': artifacts.take(8).toList(),
    };
  }

  List<String> _dedupe(List<String> items) {
    final seen = <String>{};
    final out = <String>[];
    for (final it in items) {
      final key = it.trim().toLowerCase();
      if (key.isEmpty) continue;
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(it);
    }
    return out;
  }

  List<String> _fallbackPhases() {
    if (projectType.contains('Research')) {
      return ['Concept', 'Exploration', 'Synthesis'];
    }
    if (projectType.contains('Construction') && delivery != 'Agile') {
      return ['Design', 'Procurement', 'Construction', 'Handover'];
    }
    if (projectType.contains('Clinical')) {
      return ['Protocol', 'Start-up', 'Enrollment', 'Analysis', 'Close-out'];
    }
    if (delivery == 'Agile') {
      return ['Inception', 'Iterations', 'Release'];
    }
    if (delivery == 'Predictive') {
      final base = [
        'Initiation',
        'Planning',
        'Execution',
        'Monitoring & Control',
        'Closing',
      ];
      if (governance == 'Strict' ||
          complexity == 'High' ||
          complexity == 'Very High') {
        return [
          'Initiation',
          'Planning',
          'Execution (Stage 1)',
          'Stage Boundary',
          'Execution (Stage 2)',
          'Monitoring & Control',
          'Closing',
        ];
      }
      return base;
    }
    return ['Initiate', 'Deliver', 'Close'];
  }

  List<String> _fallbackPractices() {
    final list = <String>[
      'Stakeholder engagement plan',
      'Risk identification workshop',
      'Change control procedure',
    ];
    if (projectType.contains('Research')) {
      list.addAll(['Ethics approval', 'Data management plan']);
    }
    if (projectType.contains('Construction')) {
      list.addAll(['Quality inspections', 'Safety briefings']);
    }
    if (projectType.contains('Clinical')) {
      list.addAll(['Site initiation visit', 'Monitoring plan']);
    }
    if (projectType.contains('Finance') || projectType.contains('Banking')) {
      list.addAll(['Compliance reviews', 'Controls testing']);
    }
    if (projectType.contains('Data Science') || projectType.contains('AI')) {
      list.addAll(['Model evaluation protocol', 'Bias assessment']);
    }
    return list;
  }

  List<String> _fallbackArtifacts() {
    final list = <String>['Project charter', 'Risk register', 'Decision log'];
    if (projectType.contains('Research')) {
      list.addAll(['Experiment log', 'Findings report']);
    }
    if (projectType.contains('Construction')) {
      list.addAll(['Method statements', 'Inspection test plan']);
    }
    if (projectType.contains('Clinical')) {
      list.addAll(['Trial master file', 'Case report forms']);
    }
    if (projectType.contains('Finance') || projectType.contains('Banking')) {
      list.addAll(['SOX controls matrix', 'Audit trail']);
    }
    if (projectType.contains('Data Science') || projectType.contains('AI')) {
      list.addAll(['Model card', 'Datasheet for datasets']);
    }
    return list;
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.items);
  final String title;
  final List<String> items;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final it in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• $it'),
              ),
          ],
        ),
      ),
    );
  }
}
