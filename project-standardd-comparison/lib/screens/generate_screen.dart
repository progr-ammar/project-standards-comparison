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

  int _currentStep = 0;
  bool _loading = false;
  bool _hasGenerated = false;

  // Project characteristics
  String _projectType = 'Software Development';
  String _projectSize = 'Medium';
  String _complexity = 'Medium';
  String _duration = '3-6 months';
  String _industry = 'Technology';
  String _riskLevel = 'Medium';
  List<String> _constraints = [];
  List<String> _requiredProcesses = [];

  // Governance configuration
  String _governanceLevel = 'Moderate';
  List<String> _optionalProcesses = [];
  Map<String, String> _roleAssignments = {};
  List<String> _deliverables = [];

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildStepIndicator(context),
              const SizedBox(height: 24),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: _buildCurrentStep(context, generateProvider),
                ),
              ),
              const SizedBox(height: 16),
              _buildNavigationButtons(context, generateProvider),
            ],
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
                'Create tailored project management processes based on PMBOK 7th, PRINCE2 7th, and ISO 21502',
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

  Widget _buildStepIndicator(BuildContext context) {
    final steps = [
      'Project Characteristics',
      'Governance Configuration',
      'Risk Assessment',
      'Review & Generate',
    ];

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? Theme.of(context).colorScheme.primary
                            : isCompleted
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            isActive || isCompleted
                                ? Colors.white
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : isCompleted
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          steps[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                isActive || isCompleted
                                    ? Colors.white
                                    : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (index < steps.length - 1)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep(BuildContext context, GenerateProvider provider) {
    switch (_currentStep) {
      case 0:
        return _buildProjectCharacteristicsStep(context, provider);
      case 1:
        return _buildGovernanceConfigurationStep(context, provider);
      case 2:
        return _buildRiskAssessmentStep(context, provider);
      case 3:
        return _buildReviewStep(context, provider);
      default:
        return Container();
    }
  }

  Widget _buildProjectCharacteristicsStep(
    BuildContext context,
    GenerateProvider provider,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Characteristics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Define the key characteristics of your project to enable tailored process recommendations.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Quick scenario selection
          _buildScenarioSelection(context),
          const SizedBox(height: 24),

          // Project Name
          TextFormField(
            controller: _projectNameController,
            decoration: const InputDecoration(
              labelText: 'Project Name',
              border: OutlineInputBorder(),
              helperText: 'Enter a descriptive name for your project',
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
              _buildDropdownField(
                label: 'Project Type',
                value: _projectType,
                items: provider.availableProjectTypes,
                onChanged:
                    (value) =>
                        setState(() => _projectType = value ?? _projectType),
                helpText: 'The primary domain or nature of your project',
              ),
              _buildDropdownField(
                label: 'Project Size',
                value: _projectSize,
                items: provider.availableSizes,
                onChanged:
                    (value) =>
                        setState(() => _projectSize = value ?? _projectSize),
                helpText: 'Scale in terms of team size, budget, and scope',
              ),
              _buildDropdownField(
                label: 'Complexity',
                value: _complexity,
                items: provider.availableComplexities,
                onChanged:
                    (value) =>
                        setState(() => _complexity = value ?? _complexity),
                helpText: 'Technical and organizational complexity level',
              ),
              _buildDropdownField(
                label: 'Duration',
                value: _duration,
                items: provider.availableDurations,
                onChanged:
                    (value) => setState(() => _duration = value ?? _duration),
                helpText: 'Expected project timeline',
              ),
              _buildDropdownField(
                label: 'Industry',
                value: _industry,
                items: provider.availableIndustries,
                onChanged:
                    (value) => setState(() => _industry = value ?? _industry),
                helpText: 'Industry sector and regulatory context',
              ),
              _buildDropdownField(
                label: 'Risk Level',
                value: _riskLevel,
                items: provider.availableRiskLevels,
                onChanged:
                    (value) => setState(() => _riskLevel = value ?? _riskLevel),
                helpText: 'Overall project risk assessment',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Constraints
          _buildConstraintsSection(context, provider),
        ],
      ),
    );
  }

  Widget _buildScenarioSelection(BuildContext context) {
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
          'constraints': ['Time Critical', 'Resource Constrained'],
          'requiredProcesses': [
            'Scope Management',
            'Schedule Management',
            'Quality Assurance',
            'Change Control',
          ],
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
          'constraints': [
            'High Security Requirements',
            'Stakeholder Complexity',
          ],
          'requiredProcesses': [
            'Risk Management',
            'Stakeholder Management',
            'Quality Assurance',
            'Change Control',
            'Integration Management',
          ],
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
          'constraints': [
            'Regulatory Compliance',
            'Budget Limited',
            'Stakeholder Complexity',
            'Legacy System Integration',
          ],
          'requiredProcesses': [
            'Risk Management',
            'Quality Assurance',
            'Stakeholder Management',
            'Procurement Management',
            'Communication Management',
            'Integration Management',
            'Cost Management',
          ],
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
              'Choose a pre-configured scenario to get started quickly, or configure manually below.',
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

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? helpText,
  }) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            items:
                items
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
            onChanged: onChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select $label';
              }
              return null;
            },
          ),
          if (helpText != null) ...[
            const SizedBox(height: 4),
            Text(
              helpText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConstraintsSection(
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
              'Project Constraints',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Select any constraints that apply to your project:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  provider.availableConstraints.map((constraint) {
                    final isSelected = _constraints.contains(constraint);
                    return FilterChip(
                      label: Text(constraint),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _constraints.add(constraint);
                          } else {
                            _constraints.remove(constraint);
                          }
                        });
                      },
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGovernanceConfigurationStep(
    BuildContext context,
    GenerateProvider provider,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Governance Configuration',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Configure the governance structure and oversight requirements for your project.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          _buildDropdownField(
            label: 'Governance Level',
            value: _governanceLevel,
            items: provider.availableGovernanceLevels,
            onChanged:
                (value) => setState(
                  () => _governanceLevel = value ?? _governanceLevel,
                ),
            helpText: 'Level of formal oversight and control required',
          ),

          const SizedBox(height: 24),

          _buildProcessSelectionSection(context, provider),
        ],
      ),
    );
  }

  Widget _buildProcessSelectionSection(
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
              'Required Processes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Select the processes that are mandatory for your project:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  provider.availableProcesses.map((process) {
                    final isSelected = _requiredProcesses.contains(process);
                    return FilterChip(
                      label: Text(process),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _requiredProcesses.add(process);
                          } else {
                            _requiredProcesses.remove(process);
                          }
                        });
                      },
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAssessmentStep(
    BuildContext context,
    GenerateProvider provider,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Assessment',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Assess the risk factors and uncertainty levels for your project.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Risk Level: $_riskLevel',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRiskDescription(_riskLevel),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Based on your selections, the following risk management approaches will be recommended:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  ..._getRiskRecommendations().map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(rec)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(BuildContext context, GenerateProvider provider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Generate',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Review your configuration and generate the tailored process.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          if (_hasGenerated && provider.currentProcess != null)
            _buildGeneratedResults(context, provider)
          else
            _buildConfigurationSummary(context),
        ],
      ),
    );
  }

  Widget _buildConfigurationSummary(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Project Name', _projectNameController.text),
            _buildSummaryRow('Project Type', _projectType),
            _buildSummaryRow('Size', _projectSize),
            _buildSummaryRow('Complexity', _complexity),
            _buildSummaryRow('Duration', _duration),
            _buildSummaryRow('Industry', _industry),
            _buildSummaryRow('Risk Level', _riskLevel),
            _buildSummaryRow('Governance Level', _governanceLevel),
            if (_constraints.isNotEmpty)
              _buildSummaryRow('Constraints', _constraints.join(', ')),
            if (_requiredProcesses.isNotEmpty)
              _buildSummaryRow(
                'Required Processes',
                '${_requiredProcesses.length} selected',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedResults(
    BuildContext context,
    GenerateProvider provider,
  ) {
    final currentProcess = provider.currentProcess!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Process Generated Successfully!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Your tailored process \"${currentProcess.name}\" is ready.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Process details
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Process Overview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Generated ${currentProcess.recommendations.length} recommendations from PMBOK 7th Edition, PRINCE2 7th Edition, and ISO 21502:2020.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Sample recommendations
                Text(
                  'Key Recommendations:',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...currentProcess.recommendations
                    .take(5)
                    .map(
                      (rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              rec.isRequired ? Icons.check_circle : Icons.info,
                              size: 16,
                              color:
                                  rec.isRequired ? Colors.green : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rec.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Source: ${rec.source} | Category: ${rec.category}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (rec.rationale.isNotEmpty)
                                    Text(
                                      rec.rationale,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                if (currentProcess.recommendations.length > 5) ...[
                  const SizedBox(height: 8),
                  Text(
                    '... and ${currentProcess.recommendations.length - 5} more recommendations',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Regenerate with current settings
                  _generateProcess(provider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Regenerate'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _exportProcessDocument(context, provider),
                icon: const Icon(Icons.download),
                label: const Text('Export'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    GenerateProvider provider,
  ) {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _currentStep--;
                });
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),

        Expanded(
          child:
              _currentStep < 3
                  ? ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        setState(() {
                          _currentStep++;
                        });
                      }
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  )
                  : ElevatedButton.icon(
                    onPressed:
                        _canGenerate()
                            ? () => _generateProcess(provider)
                            : null,
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

      _constraints.clear();
      _constraints.addAll((config['constraints'] as List<String>));

      _requiredProcesses.clear();
      _requiredProcesses.addAll((config['requiredProcesses'] as List<String>));

      _hasGenerated = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Applied ${config['projectType']} scenario configuration',
        ),
        action: SnackBarAction(
          label: 'Next Step',
          onPressed: () {
            setState(() {
              _currentStep = 1;
            });
          },
        ),
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
        constraints: _constraints,
      );

      provider.updateGovernanceConfiguration(
        level: _governanceLevel,
        requiredProcesses: _requiredProcesses,
        optionalProcesses: _optionalProcesses,
        roleAssignments: _roleAssignments,
        deliverables: _deliverables,
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

  void _exportProcessDocument(BuildContext context, GenerateProvider provider) {
    final currentProcess = provider.currentProcess;
    if (currentProcess == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No process to export')));
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Export Process Design Document'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Process: ${currentProcess.name}',
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
                      'The process is specifically designed for ${currentProcess.characteristics.projectType.toLowerCase()} projects with '
                      '${currentProcess.characteristics.complexity.toLowerCase()} complexity and ${currentProcess.governance.level.toLowerCase()} governance.',
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Key Recommendations:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...currentProcess.recommendations
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
              ElevatedButton.icon(
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
                icon: const Icon(Icons.check),
                label: const Text('Done'),
              ),
            ],
          ),
    );
  }

  String _getRiskDescription(String level) {
    switch (level) {
      case 'Low':
        return 'Minimal risk factors, well-understood domain';
      case 'Medium':
        return 'Some uncertainty, manageable risk factors';
      case 'High':
        return 'Significant uncertainty, complex risk factors';
      case 'Critical':
        return 'High uncertainty, mission-critical with severe consequences';
      default:
        return '';
    }
  }

  List<String> _getRiskRecommendations() {
    switch (_riskLevel) {
      case 'Low':
        return [
          'Basic risk identification and monitoring',
          'Simple risk register maintenance',
          'Monthly risk reviews',
        ];
      case 'Medium':
        return [
          'Structured risk assessment processes',
          'Risk response planning',
          'Bi-weekly risk monitoring',
          'Stakeholder risk communication',
        ];
      case 'High':
        return [
          'Comprehensive risk management framework',
          'Quantitative risk analysis',
          'Weekly risk monitoring',
          'Risk escalation procedures',
          'Contingency planning',
        ];
      case 'Critical':
        return [
          'Enterprise risk management integration',
          'Daily risk monitoring',
          'Executive risk reporting',
          'Multiple contingency scenarios',
          'Risk-based decision making',
        ];
      default:
        return [];
    }
  }
}
