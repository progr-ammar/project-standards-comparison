import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/generate_provider.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();

  // Project characteristics
  String _projectType = 'Software Development';
  String _projectSize = 'Medium';
  String _complexity = 'Medium';
  String _duration = '3-6 months';
  String _industry = 'Technology';
  String _riskLevel = 'Medium';
  String _governanceLevel = 'Moderate';

  bool _loading = false;
  bool _hasGenerated = false;

  @override
  void initState() {
    super.initState();
    _projectNameController.text = 'New Project Process';
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GenerateProvider>(
      builder: (context, generateProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuickScenarios(context),
                        const SizedBox(height: 24),
                        _buildProjectConfiguration(context, generateProvider),
                        const SizedBox(height: 24),
                        if (_hasGenerated &&
                            generateProvider.currentProcess != null)
                          _buildResults(context, generateProvider),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                _buildActionButtons(context, generateProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.auto_awesome,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Process Design Generator',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'Create tailored project management processes based on PMBOK, PRINCE2, and ISO 21502',
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

  Widget _buildQuickScenarios(BuildContext context) {
    final scenarios = [
      {
        'title': 'Custom Software Development',
        'description': 'Well-defined requirements, <6 months, <7 team members',
        'icon': Icons.code,
        'config': {
          'projectType': 'Software Development',
          'size': 'Small',
          'complexity': 'Medium',
          'duration': '3-6 months',
          'industry': 'Technology',
          'riskLevel': 'Low',
          'governanceLevel': 'Light',
        },
      },
      {
        'title': 'Innovative Product Development',
        'description': 'R&D-heavy, uncertain outcomes, ~1 year duration',
        'icon': Icons.lightbulb,
        'config': {
          'projectType': 'Product Development',
          'size': 'Medium',
          'complexity': 'High',
          'duration': '6-12 months',
          'industry': 'Technology',
          'riskLevel': 'High',
          'governanceLevel': 'Moderate',
        },
      },
      {
        'title': 'Large Government Project',
        'description': 'Civil, electrical, and IT components, 2-year duration',
        'icon': Icons.account_balance,
        'config': {
          'projectType': 'Infrastructure',
          'size': 'Large',
          'complexity': 'High',
          'duration': '1-2 years',
          'industry': 'Government',
          'riskLevel': 'High',
          'governanceLevel': 'Heavy',
        },
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.rocket_launch,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Start Scenarios',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a pre-configured scenario based on industry best practices:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            ...scenarios.map(
              (scenario) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap:
                      () => _applyScenarioConfiguration(
                        scenario['config'] as Map<String, dynamic>,
                      ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          scenario['icon'] as IconData,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scenario['title'] as String,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                scenario['description'] as String,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectConfiguration(
    BuildContext context,
    GenerateProvider provider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Project Name
            TextFormField(
              controller: _projectNameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a project name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Configuration Grid
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildSimpleDropdown(
                  'Project Type',
                  _projectType,
                  provider.availableProjectTypes,
                  (value) {
                    setState(() => _projectType = value ?? _projectType);
                  },
                ),
                _buildSimpleDropdown(
                  'Size',
                  _projectSize,
                  provider.availableSizes,
                  (value) {
                    setState(() => _projectSize = value ?? _projectSize);
                  },
                ),
                _buildSimpleDropdown(
                  'Complexity',
                  _complexity,
                  provider.availableComplexities,
                  (value) {
                    setState(() => _complexity = value ?? _complexity);
                  },
                ),
                _buildSimpleDropdown(
                  'Duration',
                  _duration,
                  provider.availableDurations,
                  (value) {
                    setState(() => _duration = value ?? _duration);
                  },
                ),
                _buildSimpleDropdown(
                  'Industry',
                  _industry,
                  provider.availableIndustries,
                  (value) {
                    setState(() => _industry = value ?? _industry);
                  },
                ),
                _buildSimpleDropdown(
                  'Risk Level',
                  _riskLevel,
                  provider.availableRiskLevels,
                  (value) {
                    setState(() => _riskLevel = value ?? _riskLevel);
                  },
                ),
                _buildSimpleDropdown(
                  'Governance',
                  _governanceLevel,
                  provider.availableGovernanceLevels,
                  (value) {
                    setState(
                      () => _governanceLevel = value ?? _governanceLevel,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items:
            items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildResults(BuildContext context, GenerateProvider provider) {
    final process = provider.currentProcess!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Process Generated Successfully',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              process.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),

            Text(
              'Generated ${process.recommendations.length} recommendations from PMBOK 7th, PRINCE2 7th, and ISO 21502',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Sample recommendations
            ...process.recommendations
                .take(3)
                .map(
                  (rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          rec.isRequired ? Icons.check_circle : Icons.info,
                          size: 16,
                          color: rec.isRequired ? Colors.green : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rec.name,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Source: ${rec.source} | ${rec.category}',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

            if (process.recommendations.length > 3) ...[
              const SizedBox(height: 8),
              Text(
                '... and ${process.recommendations.length - 3} more recommendations',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, GenerateProvider provider) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _canGenerate() ? () => _generateProcess(provider) : null,
            icon:
                _loading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.auto_awesome),
            label: Text(
              _loading
                  ? 'Generating...'
                  : _hasGenerated
                  ? 'Regenerate'
                  : 'Generate Process',
            ),
          ),
        ),
        if (_hasGenerated) ...[
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _exportProcess(context, provider),
              icon: const Icon(Icons.download),
              label: const Text('Export'),
            ),
          ),
        ],
      ],
    );
  }

  bool _canGenerate() {
    return _formKey.currentState?.validate() ?? false;
  }

  void _applyScenarioConfiguration(Map<String, dynamic> config) {
    setState(() {
      _projectType = config['projectType'] as String;
      _projectSize = config['size'] as String;
      _complexity = config['complexity'] as String;
      _duration = config['duration'] as String;
      _industry = config['industry'] as String;
      _riskLevel = config['riskLevel'] as String;
      _governanceLevel = config['governanceLevel'] as String;
      _hasGenerated = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Applied ${config['projectType']} scenario configuration',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _generateProcess(GenerateProvider provider) async {
    if (!_canGenerate()) return;

    setState(() {
      _loading = true;
    });

    try {
      // Update provider with current configuration
      provider.updateProjectCharacteristics(
        projectType: _projectType,
        size: _projectSize,
        complexity: _complexity,
        duration: _duration,
        industry: _industry,
        riskLevel: _riskLevel,
        constraints: [],
      );

      provider.updateGovernanceConfiguration(
        level: _governanceLevel,
        requiredProcesses: [],
        optionalProcesses: [],
        roleAssignments: {},
        deliverables: [],
      );

      // Generate the process
      await provider.generateProcess(
        customName: _projectNameController.text.trim(),
      );

      setState(() {
        _hasGenerated = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating process: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _exportProcess(BuildContext context, GenerateProvider provider) {
    final process = provider.currentProcess;
    if (process == null) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Process Design Document'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Process: ${process.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Executive Summary:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This tailored process integrates best practices from PMBOK 7th Edition, PRINCE2 7th Edition, and ISO 21502:2020. '
                      'The process is specifically designed for ${process.characteristics.projectType.toLowerCase()} projects with '
                      '${process.characteristics.complexity.toLowerCase()} complexity and ${process.governance.level.toLowerCase()} governance.',
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Key Recommendations:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...process.recommendations
                        .take(5)
                        .map(
                          (rec) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• ${rec.name} (${rec.source})'),
                          ),
                        ),

                    const SizedBox(height: 16),
                    const Text(
                      'Standards Integration:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• PMBOK 7th Edition: Provides the foundational project management processes\n'
                      '• PRINCE2 7th Edition: Contributes governance and control frameworks\n'
                      '• ISO 21502:2020: Ensures organizational alignment and best practices',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Process design document generated successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Done'),
              ),
            ],
          ),
    );
  }
}
