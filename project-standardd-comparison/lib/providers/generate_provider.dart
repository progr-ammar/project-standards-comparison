import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProjectCharacteristics {
  final String projectType;
  final String size;
  final String complexity;
  final String duration;
  final String industry;
  final String riskLevel;
  final List<String> constraints;
  final Map<String, dynamic> customAttributes;

  ProjectCharacteristics({
    required this.projectType,
    required this.size,
    required this.complexity,
    required this.duration,
    required this.industry,
    required this.riskLevel,
    this.constraints = const [],
    this.customAttributes = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'projectType': projectType,
      'size': size,
      'complexity': complexity,
      'duration': duration,
      'industry': industry,
      'riskLevel': riskLevel,
      'constraints': constraints,
      'customAttributes': customAttributes,
    };
  }

  factory ProjectCharacteristics.fromJson(Map<String, dynamic> json) {
    return ProjectCharacteristics(
      projectType: json['projectType'] as String,
      size: json['size'] as String,
      complexity: json['complexity'] as String,
      duration: json['duration'] as String,
      industry: json['industry'] as String,
      riskLevel: json['riskLevel'] as String,
      constraints:
          (json['constraints'] as List<dynamic>?)?.cast<String>() ?? [],
      customAttributes:
          (json['customAttributes'] as Map<String, dynamic>?) ?? {},
    );
  }
}

class GovernanceConfiguration {
  final String level; // 'light', 'moderate', 'heavy'
  final List<String> requiredProcesses;
  final List<String> optionalProcesses;
  final Map<String, String> roleAssignments;
  final List<String> deliverables;

  GovernanceConfiguration({
    required this.level,
    this.requiredProcesses = const [],
    this.optionalProcesses = const [],
    this.roleAssignments = const {},
    this.deliverables = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'requiredProcesses': requiredProcesses,
      'optionalProcesses': optionalProcesses,
      'roleAssignments': roleAssignments,
      'deliverables': deliverables,
    };
  }

  factory GovernanceConfiguration.fromJson(Map<String, dynamic> json) {
    return GovernanceConfiguration(
      level: json['level'] as String,
      requiredProcesses:
          (json['requiredProcesses'] as List<dynamic>?)?.cast<String>() ?? [],
      optionalProcesses:
          (json['optionalProcesses'] as List<dynamic>?)?.cast<String>() ?? [],
      roleAssignments:
          (json['roleAssignments'] as Map<String, dynamic>?)
              ?.cast<String, String>() ??
          {},
      deliverables:
          (json['deliverables'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

class ProcessRecommendation {
  final String id;
  final String name;
  final String description;
  final String source; // 'PMBOK', 'PRINCE2', 'ISO21502'
  final String category;
  final bool isRequired;
  final List<String> inputs;
  final List<String> outputs;
  final List<String> tools;
  final String rationale;
  final double confidence;

  ProcessRecommendation({
    required this.id,
    required this.name,
    required this.description,
    required this.source,
    required this.category,
    this.isRequired = false,
    this.inputs = const [],
    this.outputs = const [],
    this.tools = const [],
    required this.rationale,
    this.confidence = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'source': source,
      'category': category,
      'isRequired': isRequired,
      'inputs': inputs,
      'outputs': outputs,
      'tools': tools,
      'rationale': rationale,
      'confidence': confidence,
    };
  }

  factory ProcessRecommendation.fromJson(Map<String, dynamic> json) {
    return ProcessRecommendation(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      source: json['source'] as String,
      category: json['category'] as String,
      isRequired: json['isRequired'] as bool? ?? false,
      inputs: (json['inputs'] as List<dynamic>?)?.cast<String>() ?? [],
      outputs: (json['outputs'] as List<dynamic>?)?.cast<String>() ?? [],
      tools: (json['tools'] as List<dynamic>?)?.cast<String>() ?? [],
      rationale: json['rationale'] as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class GeneratedProcess {
  final String id;
  final String name;
  final DateTime created;
  final ProjectCharacteristics characteristics;
  final GovernanceConfiguration governance;
  final List<ProcessRecommendation> recommendations;
  final Map<String, dynamic> tailoringDecisions;
  final List<String> tags;

  GeneratedProcess({
    required this.id,
    required this.name,
    required this.created,
    required this.characteristics,
    required this.governance,
    this.recommendations = const [],
    this.tailoringDecisions = const {},
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created': created.toIso8601String(),
      'characteristics': characteristics.toJson(),
      'governance': governance.toJson(),
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'tailoringDecisions': tailoringDecisions,
      'tags': tags,
    };
  }

  factory GeneratedProcess.fromJson(Map<String, dynamic> json) {
    return GeneratedProcess(
      id: json['id'] as String,
      name: json['name'] as String,
      created: DateTime.parse(json['created'] as String),
      characteristics: ProjectCharacteristics.fromJson(json['characteristics']),
      governance: GovernanceConfiguration.fromJson(json['governance']),
      recommendations:
          (json['recommendations'] as List<dynamic>?)
              ?.map((r) => ProcessRecommendation.fromJson(r))
              .toList() ??
          [],
      tailoringDecisions:
          (json['tailoringDecisions'] as Map<String, dynamic>?) ?? {},
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

class GenerateProvider extends ChangeNotifier {
  GenerateProvider(this._prefs) {
    _loadData();
    _loadConfigurationData();
  }

  final SharedPreferences _prefs;
  static const String _generatedProcessesKey = 'generated_processes';
  static const String _currentProcessKey = 'current_process';

  // Configuration data loaded from assets
  Map<String, dynamic> _tailoringRules = {};
  Map<String, dynamic> _baselineRules = {};

  // State
  final Map<String, GeneratedProcess> _generatedProcesses = {};
  GeneratedProcess? _currentProcess;
  bool _isGenerating = false;
  String _generationStatus = '';

  // Current input state
  ProjectCharacteristics? _currentCharacteristics;
  GovernanceConfiguration? _currentGovernance;

  // Getters
  List<GeneratedProcess> get generatedProcesses =>
      _generatedProcesses.values.toList()
        ..sort((a, b) => b.created.compareTo(a.created));
  GeneratedProcess? get currentProcess => _currentProcess;
  bool get isGenerating => _isGenerating;
  String get generationStatus => _generationStatus;
  ProjectCharacteristics? get currentCharacteristics => _currentCharacteristics;
  GovernanceConfiguration? get currentGovernance => _currentGovernance;

  // Configuration getters
  List<String> get availableProjectTypes => [
    'Software Development',
    'Product Development',
    'Infrastructure',
    'Business Transformation',
    'Research & Development',
    'Construction',
    'Marketing Campaign',
    'Product Launch',
    'Organizational Change',
  ];

  List<String> get availableSizes => ['Small', 'Medium', 'Large', 'Enterprise'];
  List<String> get availableComplexities => [
    'Low',
    'Medium',
    'High',
    'Very High',
  ];
  List<String> get availableDurations => [
    '< 3 months',
    '3-6 months',
    '6-12 months',
    '1-2 years',
    '> 2 years',
  ];
  List<String> get availableIndustries => [
    'Technology',
    'Healthcare',
    'Finance',
    'Manufacturing',
    'Education',
    'Government',
    'Retail',
    'Energy',
    'Other',
  ];
  List<String> get availableRiskLevels => ['Low', 'Medium', 'High', 'Critical'];
  List<String> get availableGovernanceLevels => ['Light', 'Moderate', 'Heavy'];

  List<String> get availableConstraints => [
    'Time Critical',
    'Budget Limited',
    'Resource Constrained',
    'High Security Requirements',
    'Regulatory Compliance',
    'Stakeholder Complexity',
    'Legacy System Integration',
    'Geographic Distribution',
    'Technology Constraints',
    'Quality Critical',
  ];

  List<String> get availableProcesses => [
    'Scope Management',
    'Schedule Management',
    'Cost Management',
    'Quality Assurance',
    'Risk Management',
    'Stakeholder Management',
    'Communication Management',
    'Procurement Management',
    'Integration Management',
    'Change Control',
    'Issue Management',
    'Resource Management',
    'Performance Monitoring',
    'Knowledge Management',
  ];

  // Project characteristics management
  void setProjectCharacteristics(ProjectCharacteristics characteristics) {
    _currentCharacteristics = characteristics;
    notifyListeners();
  }

  void updateProjectCharacteristics({
    String? projectType,
    String? size,
    String? complexity,
    String? duration,
    String? industry,
    String? riskLevel,
    List<String>? constraints,
    Map<String, dynamic>? customAttributes,
  }) {
    if (_currentCharacteristics == null) {
      _currentCharacteristics = ProjectCharacteristics(
        projectType: projectType ?? availableProjectTypes.first,
        size: size ?? availableSizes.first,
        complexity: complexity ?? availableComplexities.first,
        duration: duration ?? availableDurations.first,
        industry: industry ?? availableIndustries.first,
        riskLevel: riskLevel ?? availableRiskLevels.first,
        constraints: constraints ?? [],
        customAttributes: customAttributes ?? {},
      );
    } else {
      _currentCharacteristics = ProjectCharacteristics(
        projectType: projectType ?? _currentCharacteristics!.projectType,
        size: size ?? _currentCharacteristics!.size,
        complexity: complexity ?? _currentCharacteristics!.complexity,
        duration: duration ?? _currentCharacteristics!.duration,
        industry: industry ?? _currentCharacteristics!.industry,
        riskLevel: riskLevel ?? _currentCharacteristics!.riskLevel,
        constraints: constraints ?? _currentCharacteristics!.constraints,
        customAttributes:
            customAttributes ?? _currentCharacteristics!.customAttributes,
      );
    }
    notifyListeners();
  }

  // Governance configuration management
  void setGovernanceConfiguration(GovernanceConfiguration governance) {
    _currentGovernance = governance;
    notifyListeners();
  }

  void updateGovernanceConfiguration({
    String? level,
    List<String>? requiredProcesses,
    List<String>? optionalProcesses,
    Map<String, String>? roleAssignments,
    List<String>? deliverables,
  }) {
    if (_currentGovernance == null) {
      _currentGovernance = GovernanceConfiguration(
        level: level ?? availableGovernanceLevels.first,
        requiredProcesses: requiredProcesses ?? [],
        optionalProcesses: optionalProcesses ?? [],
        roleAssignments: roleAssignments ?? {},
        deliverables: deliverables ?? [],
      );
    } else {
      _currentGovernance = GovernanceConfiguration(
        level: level ?? _currentGovernance!.level,
        requiredProcesses:
            requiredProcesses ?? _currentGovernance!.requiredProcesses,
        optionalProcesses:
            optionalProcesses ?? _currentGovernance!.optionalProcesses,
        roleAssignments: roleAssignments ?? _currentGovernance!.roleAssignments,
        deliverables: deliverables ?? _currentGovernance!.deliverables,
      );
    }
    notifyListeners();
  }

  // Process generation
  Future<void> generateProcess({String? customName}) async {
    if (_currentCharacteristics == null || _currentGovernance == null) {
      throw StateError(
        'Project characteristics and governance configuration must be set',
      );
    }

    _isGenerating = true;
    _generationStatus = 'Analyzing project requirements...';
    notifyListeners();

    try {
      _generationStatus = 'Applying tailoring rules...';
      notifyListeners();

      final recommendations = await _generateRecommendations(
        _currentCharacteristics!,
        _currentGovernance!,
      );

      _generationStatus = 'Finalizing process design...';
      notifyListeners();

      final process = GeneratedProcess(
        id: 'proc_${DateTime.now().millisecondsSinceEpoch}',
        name: customName ?? _generateProcessName(_currentCharacteristics!),
        created: DateTime.now(),
        characteristics: _currentCharacteristics!,
        governance: _currentGovernance!,
        recommendations: recommendations,
        tailoringDecisions: _generateTailoringDecisions(
          _currentCharacteristics!,
          _currentGovernance!,
        ),
      );

      _currentProcess = process;
      _saveCurrentProcess();
      _generationStatus = 'Process generated successfully';
    } catch (e) {
      _generationStatus = 'Error: $e';
      debugPrint('Error generating process: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<List<ProcessRecommendation>> _generateRecommendations(
    ProjectCharacteristics characteristics,
    GovernanceConfiguration governance,
  ) async {
    final recommendations = <ProcessRecommendation>[];

    // Step 1: Get baseline processes based on governance level
    final baselineProcesses = _getBaselineProcesses(governance.level);

    // Step 2: Apply tailoring rules based on project characteristics
    for (final process in baselineProcesses) {
      final tailored = _applyTailoringRules(process, characteristics);
      if (tailored != null) {
        recommendations.add(tailored);
      }
    }

    // Step 3: Add additional processes based on specific characteristics
    recommendations.addAll(_getAdditionalProcesses(characteristics));

    // Step 4: Apply cross-standard analysis and evidence-based recommendations
    final crossStandardRecommendations =
        await _generateCrossStandardRecommendations(
          characteristics,
          governance,
        );
    recommendations.addAll(crossStandardRecommendations);

    // Step 5: Apply dynamic content generation based on project context
    final dynamicRecommendations = _generateDynamicRecommendations(
      characteristics,
      governance,
      recommendations,
    );
    recommendations.addAll(dynamicRecommendations);

    // Step 6: Calculate confidence scores and prioritize recommendations
    final prioritizedRecommendations = _prioritizeRecommendations(
      recommendations,
      characteristics,
      governance,
    );

    return prioritizedRecommendations;
  }

  /// Generates cross-standard recommendations by analyzing all three standards
  Future<List<ProcessRecommendation>> _generateCrossStandardRecommendations(
    ProjectCharacteristics characteristics,
    GovernanceConfiguration governance,
  ) async {
    final recommendations = <ProcessRecommendation>[];

    // Analyze project type against all three standards
    final projectTypeAnalysis = _analyzeProjectTypeAcrossStandards(
      characteristics.projectType,
    );

    // Generate recommendations based on cross-standard analysis
    for (final analysis in projectTypeAnalysis) {
      if (analysis['confidence'] >= 0.7) {
        recommendations.add(
          ProcessRecommendation(
            id: 'cross_standard_${analysis['id']}',
            name: analysis['name'] as String,
            description: analysis['description'] as String,
            source: 'Cross-Standard Analysis',
            category: analysis['category'] as String,
            isRequired: analysis['isRequired'] as bool,
            inputs:
                (analysis['inputs'] as List<dynamic>?)?.cast<String>() ?? [],
            outputs:
                (analysis['outputs'] as List<dynamic>?)?.cast<String>() ?? [],
            tools: (analysis['tools'] as List<dynamic>?)?.cast<String>() ?? [],
            rationale: analysis['rationale'] as String,
            confidence: analysis['confidence'] as double,
          ),
        );
      }
    }

    // Add industry-specific cross-standard recommendations
    final industryRecommendations = _generateIndustrySpecificRecommendations(
      characteristics.industry,
      characteristics.riskLevel,
    );
    recommendations.addAll(industryRecommendations);

    return recommendations;
  }

  /// Analyzes project type against all three PM standards
  List<Map<String, dynamic>> _analyzeProjectTypeAcrossStandards(
    String projectType,
  ) {
    final analysis = <Map<String, dynamic>>[];

    switch (projectType) {
      case 'Software Development':
        analysis.addAll([
          {
            'id': 'lightweight_agile_process',
            'name': 'Lightweight Agile Process Framework',
            'description':
                'Streamlined process for small software teams with well-defined requirements',
            'category': 'Process Framework',
            'isRequired': true,
            'inputs': [
              'Product Requirements',
              'User Stories',
              'Definition of Done',
            ],
            'outputs': [
              'Working Software',
              'Sprint Reviews',
              'Retrospective Actions',
            ],
            'tools': ['Scrum/Kanban', 'Version Control', 'Automated Testing'],
            'rationale':
                'PMBOK 7th Edition emphasizes value delivery and adaptive approaches. PRINCE2 provides light governance through stage boundaries. ISO 21502 supports tailored processes for small teams.',
            'confidence': 0.95,
          },
          {
            'id': 'rapid_delivery_management',
            'name': 'Rapid Delivery Management',
            'description':
                'Fast-track delivery processes optimized for speed and flexibility',
            'category': 'Delivery',
            'isRequired': true,
            'inputs': ['Sprint Backlog', 'Acceptance Criteria'],
            'outputs': ['Potentially Shippable Increments', 'Burn-down Charts'],
            'tools': ['CI/CD Pipeline', 'Automated Testing', 'Feature Flags'],
            'rationale':
                'PMBOK 7th supports iterative delivery. PRINCE2 Managing Product Delivery process adapted for continuous delivery. ISO 21502 emphasizes value realization.',
            'confidence': 0.9,
          },
          {
            'id': 'minimal_documentation',
            'name': 'Minimal Documentation Strategy',
            'description':
                'Essential documentation for small, time-critical projects',
            'category': 'Documentation',
            'isRequired': true,
            'inputs': ['Requirements', 'Architecture Decisions'],
            'outputs': [
              'User Documentation',
              'Technical Specifications',
              'Deployment Guides',
            ],
            'tools': ['Wiki Systems', 'Code Comments', 'README Files'],
            'rationale':
                'PMBOK 7th promotes just-enough documentation. PRINCE2 Product Descriptions adapted for agile. ISO 21502 supports proportionate documentation.',
            'confidence': 0.85,
          },
        ]);
        break;

      case 'Infrastructure':
        analysis.addAll([
          {
            'id': 'comprehensive_governance',
            'name': 'Comprehensive Multi-Domain Governance',
            'description':
                'Integrated governance for civil, electrical, and IT components',
            'category': 'Governance',
            'isRequired': true,
            'inputs': [
              'Regulatory Requirements',
              'Stakeholder Register',
              'Compliance Matrix',
            ],
            'outputs': [
              'Governance Framework',
              'Decision Records',
              'Compliance Reports',
            ],
            'tools': [
              'Governance Dashboards',
              'Decision Logs',
              'Compliance Tracking',
            ],
            'rationale':
                'PMBOK 7th governance domain with PRINCE2 comprehensive governance model. ISO 21502 provides organizational governance framework.',
            'confidence': 0.95,
          },
          {
            'id': 'integrated_procurement',
            'name': 'Integrated Multi-Domain Procurement',
            'description':
                'Complex procurement across civil, electrical, and IT domains',
            'category': 'Procurement',
            'isRequired': true,
            'inputs': [
              'Procurement Strategy',
              'Technical Specifications',
              'Vendor Qualifications',
            ],
            'outputs': [
              'Contract Awards',
              'Supplier Integration Plans',
              'Performance Metrics',
            ],
            'tools': [
              'E-Procurement Systems',
              'Contract Management',
              'Supplier Portals',
            ],
            'rationale':
                'PMBOK 7th procurement management with PRINCE2 Managing Product Delivery. ISO 21502 supports complex procurement governance.',
            'confidence': 0.9,
          },
          {
            'id': 'regulatory_compliance',
            'name': 'Regulatory Compliance Management',
            'description':
                'Comprehensive compliance across multiple regulatory domains',
            'category': 'Compliance',
            'isRequired': true,
            'inputs': [
              'Regulatory Framework',
              'Compliance Requirements',
              'Audit Schedules',
            ],
            'outputs': [
              'Compliance Plans',
              'Audit Reports',
              'Regulatory Submissions',
            ],
            'tools': [
              'Compliance Management Systems',
              'Audit Tools',
              'Regulatory Databases',
            ],
            'rationale':
                'PMBOK 7th compliance considerations with PRINCE2 quality theme. ISO 21502 emphasizes regulatory governance.',
            'confidence': 0.95,
          },
          {
            'id': 'integrated_risk_management',
            'name': 'Integrated Multi-Domain Risk Management',
            'description':
                'Comprehensive risk management across technical and organizational domains',
            'category': 'Risk Management',
            'isRequired': true,
            'inputs': [
              'Risk Register',
              'Technical Assessments',
              'Stakeholder Concerns',
            ],
            'outputs': [
              'Risk Management Plans',
              'Mitigation Strategies',
              'Contingency Plans',
            ],
            'tools': [
              'Risk Management Software',
              'Monte Carlo Analysis',
              'Risk Dashboards',
            ],
            'rationale':
                'PMBOK 7th uncertainty management with PRINCE2 risk theme. ISO 21502 supports enterprise risk management.',
            'confidence': 0.9,
          },
        ]);
        break;

      case 'Construction':
        analysis.addAll([
          {
            'id': 'safety_management',
            'name': 'Health, Safety & Environmental Management',
            'description':
                'Comprehensive HSE management system (ISO 21502 + PRINCE2)',
            'category': 'Risk & Safety',
            'isRequired': true,
            'inputs': ['Safety Regulations', 'Environmental Impact Assessment'],
            'outputs': [
              'Safety Plans',
              'Incident Reports',
              'Compliance Certificates',
            ],
            'tools': ['Risk Assessment Tools', 'Safety Management Systems'],
            'rationale':
                'Construction projects require rigorous safety management as emphasized by ISO 21502 governance principles and PRINCE2 risk management.',
            'confidence': 0.95,
          },
          {
            'id': 'procurement_management',
            'name': 'Complex Procurement Management',
            'description': 'Multi-tier procurement and contract management',
            'category': 'Procurement',
            'isRequired': true,
            'inputs': ['Procurement Strategy', 'Vendor Qualifications'],
            'outputs': ['Contract Awards', 'Supplier Performance Reports'],
            'tools': ['Contract Management Systems', 'Supplier Portals'],
            'rationale':
                'Construction projects involve complex procurement chains requiring PMBOK procurement processes with PRINCE2 stage gates.',
            'confidence': 0.9,
          },
        ]);
        break;

      case 'Product Development':
        analysis.addAll([
          {
            'id': 'innovation_stage_gate',
            'name': 'Innovation Stage-Gate Process',
            'description':
                'Hybrid adaptive-predictive approach for R&D-heavy product development',
            'category': 'Innovation Management',
            'isRequired': true,
            'inputs': [
              'Market Research',
              'Technology Roadmap',
              'Innovation Hypotheses',
            ],
            'outputs': [
              'Prototype Iterations',
              'Market Validation',
              'Go/No-Go Decisions',
            ],
            'tools': ['Design Thinking', 'Lean Startup', 'Stage-Gate Reviews'],
            'rationale':
                'PMBOK 7th adaptive life cycle combined with PRINCE2 stage boundaries for investment decisions. ISO 21502 provides governance for uncertain outcomes.',
            'confidence': 0.9,
          },
          {
            'id': 'iterative_stakeholder_engagement',
            'name': 'Iterative Stakeholder Engagement',
            'description':
                'Continuous stakeholder feedback loops for product-market fit',
            'category': 'Stakeholder Management',
            'isRequired': true,
            'inputs': ['Stakeholder Map', 'Feedback Channels', 'User Personas'],
            'outputs': [
              'Stakeholder Feedback',
              'Product Pivots',
              'Market Insights',
            ],
            'tools': [
              'User Interviews',
              'A/B Testing',
              'Customer Advisory Boards',
            ],
            'rationale':
                'PMBOK 7th stakeholder engagement with PRINCE2 Managing Stakeholder Interests. ISO 21502 emphasizes stakeholder value creation.',
            'confidence': 0.85,
          },
          {
            'id': 'adaptive_risk_management',
            'name': 'Adaptive Risk Management',
            'description':
                'Dynamic risk management for high-uncertainty innovation projects',
            'category': 'Risk Management',
            'isRequired': true,
            'inputs': [
              'Risk Hypotheses',
              'Market Assumptions',
              'Technical Risks',
            ],
            'outputs': [
              'Risk Experiments',
              'Pivot Decisions',
              'Learning Outcomes',
            ],
            'tools': [
              'Risk Canvas',
              'Assumption Mapping',
              'Experimentation Framework',
            ],
            'rationale':
                'PMBOK 7th uncertainty management with PRINCE2 risk theme. ISO 21502 supports adaptive risk approaches for innovation.',
            'confidence': 0.8,
          },
        ]);
        break;

      case 'Research & Development':
        analysis.addAll([
          {
            'id': 'innovation_management',
            'name': 'Innovation and Discovery Management',
            'description': 'Manage uncertainty and discovery in R&D projects',
            'category': 'Innovation',
            'isRequired': true,
            'inputs': ['Research Hypotheses', 'Literature Review'],
            'outputs': [
              'Research Findings',
              'Patent Applications',
              'Publications',
            ],
            'tools': [
              'Research Management Systems',
              'Statistical Analysis Tools',
            ],
            'rationale':
                'R&D projects require adaptive approaches (PMBOK 7th) with stage-gate reviews (PRINCE2) within ISO 21502 governance framework.',
            'confidence': 0.85,
          },
        ]);
        break;

      case 'Healthcare':
        analysis.addAll([
          {
            'id': 'regulatory_compliance',
            'name': 'Healthcare Regulatory Compliance',
            'description':
                'Ensure compliance with healthcare regulations and standards',
            'category': 'Compliance',
            'isRequired': true,
            'inputs': ['Regulatory Requirements', 'Clinical Protocols'],
            'outputs': [
              'Compliance Reports',
              'Audit Trails',
              'Regulatory Submissions',
            ],
            'tools': [
              'Compliance Management Systems',
              'Clinical Trial Management Systems',
            ],
            'rationale':
                'Healthcare projects require strict regulatory compliance as mandated by ISO 21502 with PMBOK quality management and PRINCE2 governance.',
            'confidence': 0.95,
          },
        ]);
        break;

      default:
        // Generic cross-standard recommendations
        analysis.addAll([
          {
            'id': 'stakeholder_engagement',
            'name': 'Enhanced Stakeholder Engagement',
            'description':
                'Comprehensive stakeholder management across project lifecycle',
            'category': 'Stakeholder Management',
            'isRequired': true,
            'inputs': ['Stakeholder Register', 'Communication Requirements'],
            'outputs': ['Engagement Plans', 'Stakeholder Feedback'],
            'tools': ['Stakeholder Analysis Tools', 'Communication Platforms'],
            'rationale':
                'All three standards emphasize stakeholder engagement as critical for project success.',
            'confidence': 0.8,
          },
        ]);
    }

    return analysis;
  }

  /// Generates industry-specific recommendations
  List<ProcessRecommendation> _generateIndustrySpecificRecommendations(
    String industry,
    String riskLevel,
  ) {
    final recommendations = <ProcessRecommendation>[];

    switch (industry) {
      case 'Finance':
        recommendations.addAll([
          ProcessRecommendation(
            id: 'financial_risk_management',
            name: 'Financial Risk Management',
            description:
                'Comprehensive financial risk assessment and mitigation',
            source: 'Industry Best Practice',
            category: 'Risk Management',
            isRequired: true,
            outputs: ['Risk Assessment Reports', 'Mitigation Plans'],
            rationale:
                'Financial industry requires enhanced risk management due to regulatory requirements and market volatility.',
            confidence: 0.9,
          ),
        ]);
        break;

      case 'Healthcare':
        recommendations.addAll([
          ProcessRecommendation(
            id: 'patient_safety_management',
            name: 'Patient Safety Management',
            description: 'Ensure patient safety throughout project lifecycle',
            source: 'Healthcare Standards',
            category: 'Safety',
            isRequired: true,
            outputs: ['Safety Protocols', 'Incident Reports'],
            rationale:
                'Healthcare projects must prioritize patient safety above all other considerations.',
            confidence: 0.95,
          ),
        ]);
        break;

      case 'Manufacturing':
        recommendations.addAll([
          ProcessRecommendation(
            id: 'quality_assurance',
            name: 'Manufacturing Quality Assurance',
            description: 'Implement comprehensive quality management system',
            source: 'Manufacturing Standards',
            category: 'Quality',
            isRequired: true,
            outputs: ['Quality Plans', 'Inspection Reports'],
            rationale:
                'Manufacturing projects require rigorous quality control to meet product specifications.',
            confidence: 0.9,
          ),
        ]);
        break;
    }

    return recommendations;
  }

  /// Generates dynamic recommendations based on project context
  List<ProcessRecommendation> _generateDynamicRecommendations(
    ProjectCharacteristics characteristics,
    GovernanceConfiguration governance,
    List<ProcessRecommendation> existingRecommendations,
  ) {
    final recommendations = <ProcessRecommendation>[];

    // Analyze gaps in existing recommendations
    final categories = existingRecommendations.map((r) => r.category).toSet();

    // Add missing critical categories
    if (!categories.contains('Communication')) {
      recommendations.add(
        ProcessRecommendation(
          id: 'dynamic_communication',
          name: 'Tailored Communication Management',
          description:
              'Communication strategy tailored to project characteristics',
          source: 'Dynamic Generation',
          category: 'Communication',
          isRequired: characteristics.constraints.contains('Distributed Team'),
          outputs: ['Communication Plan', 'Stakeholder Updates'],
          rationale: _generateDynamicRationale(
            'Communication',
            characteristics,
          ),
          confidence: 0.75,
        ),
      );
    }

    // Add constraint-specific recommendations
    for (final constraint in characteristics.constraints) {
      final constraintRecommendation = _generateConstraintRecommendation(
        constraint,
        characteristics,
      );
      if (constraintRecommendation != null) {
        recommendations.add(constraintRecommendation);
      }
    }

    return recommendations;
  }

  /// Generates constraint-specific recommendations
  ProcessRecommendation? _generateConstraintRecommendation(
    String constraint,
    ProjectCharacteristics characteristics,
  ) {
    switch (constraint) {
      case 'Budget Limited':
        return ProcessRecommendation(
          id: 'budget_optimization',
          name: 'Budget Optimization Management',
          description:
              'Enhanced cost control and budget optimization techniques',
          source: 'Constraint Analysis',
          category: 'Cost Management',
          isRequired: true,
          outputs: ['Cost Optimization Plans', 'Budget Variance Reports'],
          rationale:
              'Budget constraints require enhanced cost management and optimization techniques from PMBOK cost management processes.',
          confidence: 0.85,
        );

      case 'Time Critical':
        return ProcessRecommendation(
          id: 'fast_track_management',
          name: 'Fast-Track Project Management',
          description:
              'Accelerated delivery techniques and parallel processing',
          source: 'Constraint Analysis',
          category: 'Schedule Management',
          isRequired: true,
          outputs: ['Fast-Track Plans', 'Critical Path Analysis'],
          rationale:
              'Time-critical projects benefit from fast-tracking and crashing techniques as outlined in PMBOK schedule management.',
          confidence: 0.8,
        );

      case 'Distributed Team':
        return ProcessRecommendation(
          id: 'virtual_team_management',
          name: 'Virtual Team Management',
          description:
              'Enhanced collaboration and communication for distributed teams',
          source: 'Constraint Analysis',
          category: 'Team Management',
          isRequired: true,
          outputs: ['Virtual Collaboration Plans', 'Team Performance Metrics'],
          rationale:
              'Distributed teams require enhanced communication and collaboration processes as emphasized in PMBOK team management.',
          confidence: 0.9,
        );

      case 'High Security Requirements':
        return ProcessRecommendation(
          id: 'security_management',
          name: 'Information Security Management',
          description: 'Comprehensive information security and data protection',
          source: 'Constraint Analysis',
          category: 'Security',
          isRequired: true,
          outputs: ['Security Plans', 'Access Control Matrices'],
          rationale:
              'High security requirements necessitate comprehensive security management processes throughout the project lifecycle.',
          confidence: 0.95,
        );

      default:
        return null;
    }
  }

  /// Generates dynamic rationale based on project characteristics
  String _generateDynamicRationale(
    String category,
    ProjectCharacteristics characteristics,
  ) {
    final rationales = <String>[];

    rationales.add('Based on project type: ${characteristics.projectType}');
    rationales.add('Complexity level: ${characteristics.complexity}');
    rationales.add('Risk level: ${characteristics.riskLevel}');

    if (characteristics.constraints.isNotEmpty) {
      rationales.add(
        'Addressing constraints: ${characteristics.constraints.join(', ')}',
      );
    }

    return rationales.join('. ') +
        '. This recommendation combines best practices from PMBOK, PRINCE2, and ISO 21502.';
  }

  /// Prioritizes recommendations based on confidence scores and project characteristics
  List<ProcessRecommendation> _prioritizeRecommendations(
    List<ProcessRecommendation> recommendations,
    ProjectCharacteristics characteristics,
    GovernanceConfiguration governance,
  ) {
    // Remove duplicates based on ID
    final uniqueRecommendations = <String, ProcessRecommendation>{};
    for (final rec in recommendations) {
      if (!uniqueRecommendations.containsKey(rec.id) ||
          uniqueRecommendations[rec.id]!.confidence < rec.confidence) {
        uniqueRecommendations[rec.id] = rec;
      }
    }

    final prioritized = uniqueRecommendations.values.toList();

    // Sort by priority: required first, then by confidence score
    prioritized.sort((a, b) {
      if (a.isRequired && !b.isRequired) return -1;
      if (!a.isRequired && b.isRequired) return 1;
      return b.confidence.compareTo(a.confidence);
    });

    // Limit recommendations based on project size
    final maxRecommendations = _getMaxRecommendations(characteristics.size);
    return prioritized.take(maxRecommendations).toList();
  }

  /// Gets maximum number of recommendations based on project size
  int _getMaxRecommendations(String size) {
    switch (size) {
      case 'Small':
        return 8;
      case 'Medium':
        return 12;
      case 'Large':
        return 16;
      case 'Enterprise':
        return 20;
      default:
        return 12;
    }
  }

  List<ProcessRecommendation> _getBaselineProcesses(String governanceLevel) {
    final processes = <ProcessRecommendation>[];

    // Get baseline processes from loaded rules
    final governanceRules =
        _baselineRules['governance'] as Map<String, dynamic>?;
    final governanceData =
        governanceRules?[governanceLevel] as Map<String, dynamic>?;

    // Core processes for all governance levels
    processes.addAll([
      ProcessRecommendation(
        id: 'initiate',
        name: 'Project Initiation',
        description: 'Define project charter and initial scope',
        source: 'PMBOK',
        category: 'Initiating',
        isRequired: true,
        outputs: ['Project Charter', 'Stakeholder Register'],
        rationale:
            'Essential for all projects regardless of size or complexity',
      ),
      ProcessRecommendation(
        id: 'plan_scope',
        name: 'Plan Scope Management',
        description: 'Define how scope will be managed',
        source: 'PMBOK',
        category: 'Planning',
        isRequired: true,
        outputs: ['Scope Management Plan', 'Requirements Documentation'],
        rationale: 'Critical for project success and stakeholder alignment',
      ),
    ]);

    // Add processes from baseline rules based on governance level
    if (governanceData != null) {
      final practices =
          (governanceData['practices'] as List<dynamic>?)?.cast<String>() ?? [];
      final artifacts =
          (governanceData['artifacts'] as List<dynamic>?)?.cast<String>() ?? [];

      for (final practice in practices) {
        processes.add(
          ProcessRecommendation(
            id: 'governance_${practice.toLowerCase().replaceAll(' ', '_')}',
            name: practice,
            description: 'Governance practice: $practice',
            source: 'Baseline Rules',
            category: 'Governance',
            isRequired: governanceLevel.toLowerCase() == 'heavy',
            outputs: artifacts,
            rationale: 'Required for $governanceLevel governance level',
          ),
        );
      }
    }

    // Add processes based on governance level
    switch (governanceLevel.toLowerCase()) {
      case 'heavy':
        processes.addAll([
          ProcessRecommendation(
            id: 'manage_stage_boundaries',
            name: 'Manage Stage Boundaries',
            description: 'Control progression between project stages',
            source: 'PRINCE2',
            category: 'Controlling',
            isRequired: true,
            rationale: 'Heavy governance requires formal stage gates',
          ),
          ProcessRecommendation(
            id: 'monitor_control',
            name: 'Monitor and Control Project Work',
            description: 'Track, review and regulate project progress',
            source: 'PMBOK',
            category: 'Monitoring',
            isRequired: true,
            rationale: 'Essential for heavy governance oversight',
          ),
        ]);
        break;
      case 'moderate':
        processes.add(
          ProcessRecommendation(
            id: 'control_stage',
            name: 'Control a Stage',
            description: 'Manage day-to-day activities within a stage',
            source: 'PRINCE2',
            category: 'Controlling',
            isRequired: false,
            rationale:
                'Useful for moderate governance without being overly bureaucratic',
          ),
        );
        break;
    }

    return processes;
  }

  ProcessRecommendation? _applyTailoringRules(
    ProcessRecommendation baseProcess,
    ProjectCharacteristics characteristics,
  ) {
    // Check tailoring rules for specific combinations
    final key =
        '${characteristics.projectType}|${characteristics.complexity}|Predictive';
    final tailoringRule = _tailoringRules[key] as Map<String, dynamic>?;

    // Apply tailoring based on project size
    if (characteristics.size == 'Small' && !baseProcess.isRequired) {
      // Skip optional processes for small projects
      return null;
    }

    // Apply specific tailoring rules if available
    if (tailoringRule != null) {
      final practices =
          (tailoringRule['practices'] as List<dynamic>?)?.cast<String>() ?? [];
      final artifacts =
          (tailoringRule['artifacts'] as List<dynamic>?)?.cast<String>() ?? [];

      // If this process matches a tailoring rule, enhance it
      if (practices.any(
        (practice) =>
            practice.toLowerCase().contains(baseProcess.name.toLowerCase()),
      )) {
        return ProcessRecommendation(
          id: baseProcess.id,
          name: baseProcess.name,
          description:
              '${baseProcess.description} (Tailored for ${characteristics.projectType})',
          source: baseProcess.source,
          category: baseProcess.category,
          isRequired: baseProcess.isRequired,
          inputs: baseProcess.inputs,
          outputs: [...baseProcess.outputs, ...artifacts],
          tools: baseProcess.tools,
          rationale:
              '${baseProcess.rationale}. Tailored based on project characteristics.',
          confidence: baseProcess.confidence,
        );
      }
    }

    // Apply tailoring based on complexity
    if (characteristics.complexity == 'High' ||
        characteristics.complexity == 'Very High') {
      // Get complexity-specific rules
      final complexityRules =
          _baselineRules['complexity'] as Map<String, dynamic>?;
      final complexityData =
          complexityRules?[characteristics.complexity] as Map<String, dynamic>?;
      final complexityPractices =
          (complexityData?['practices'] as List<dynamic>?)?.cast<String>() ??
          [];
      final complexityArtifacts =
          (complexityData?['artifacts'] as List<dynamic>?)?.cast<String>() ??
          [];

      // Add additional rigor for complex projects
      return ProcessRecommendation(
        id: baseProcess.id,
        name: baseProcess.name,
        description:
            '${baseProcess.description} (Enhanced for high complexity)',
        source: baseProcess.source,
        category: baseProcess.category,
        isRequired: true, // Make required for high complexity
        inputs: [...baseProcess.inputs, 'Complexity Assessment'],
        outputs: [
          ...baseProcess.outputs,
          'Risk Register',
          ...complexityArtifacts,
        ],
        tools: [...baseProcess.tools, 'Risk Analysis Tools'],
        rationale:
            '${baseProcess.rationale}. Enhanced due to high project complexity. Additional practices: ${complexityPractices.join(', ')}',
        confidence: baseProcess.confidence * 0.9,
      );
    }

    return baseProcess;
  }

  List<ProcessRecommendation> _getAdditionalProcesses(
    ProjectCharacteristics characteristics,
  ) {
    final additional = <ProcessRecommendation>[];

    // Get project type specific processes from baseline rules
    final projectTypeRules =
        _baselineRules['projectType'] as Map<String, dynamic>?;
    final projectTypeData =
        projectTypeRules?[characteristics.projectType] as Map<String, dynamic>?;

    if (projectTypeData != null) {
      final practices =
          (projectTypeData['practices'] as List<dynamic>?)?.cast<String>() ??
          [];
      final artifacts =
          (projectTypeData['artifacts'] as List<dynamic>?)?.cast<String>() ??
          [];

      for (final practice in practices) {
        additional.add(
          ProcessRecommendation(
            id: 'project_type_${practice.toLowerCase().replaceAll(' ', '_')}',
            name: practice,
            description: 'Project type specific practice: $practice',
            source: 'Baseline Rules',
            category: 'Project Type Specific',
            isRequired: false,
            outputs: artifacts,
            rationale:
                'Recommended for ${characteristics.projectType} projects',
          ),
        );
      }
    }

    // Get risk level specific processes
    final riskRules = _baselineRules['riskAppetite'] as Map<String, dynamic>?;
    final riskData =
        riskRules?[characteristics.riskLevel] as Map<String, dynamic>?;

    if (riskData != null) {
      final practices =
          (riskData['practices'] as List<dynamic>?)?.cast<String>() ?? [];
      final artifacts =
          (riskData['artifacts'] as List<dynamic>?)?.cast<String>() ?? [];

      for (final practice in practices) {
        additional.add(
          ProcessRecommendation(
            id: 'risk_${practice.toLowerCase().replaceAll(' ', '_')}',
            name: practice,
            description: 'Risk management practice: $practice',
            source: 'Baseline Rules',
            category: 'Risk Management',
            isRequired:
                characteristics.riskLevel == 'High' ||
                characteristics.riskLevel == 'Critical',
            outputs: artifacts,
            rationale:
                'Required for ${characteristics.riskLevel} risk level projects',
          ),
        );
      }
    }

    // Add risk management for high-risk projects
    if (characteristics.riskLevel == 'High' ||
        characteristics.riskLevel == 'Critical') {
      additional.add(
        ProcessRecommendation(
          id: 'risk_management',
          name: 'Plan Risk Management',
          description: 'Define risk management approach and activities',
          source: 'PMBOK',
          category: 'Planning',
          isRequired: true,
          outputs: ['Risk Management Plan', 'Risk Register'],
          rationale: 'Critical for high-risk projects to ensure success',
        ),
      );
    }

    // Add quality management for certain industries
    if ([
      'Healthcare',
      'Finance',
      'Manufacturing',
    ].contains(characteristics.industry)) {
      additional.add(
        ProcessRecommendation(
          id: 'quality_management',
          name: 'Plan Quality Management',
          description: 'Define quality standards and assurance activities',
          source: 'ISO21502',
          category: 'Planning',
          isRequired: true,
          outputs: ['Quality Management Plan', 'Quality Metrics'],
          rationale:
              'Essential for regulated industries with strict quality requirements',
        ),
      );
    }

    return additional;
  }

  String _generateProcessName(ProjectCharacteristics characteristics) {
    return '${characteristics.projectType} Process (${characteristics.size}, ${characteristics.complexity} complexity)';
  }

  /// Generates a comprehensive process design document
  Map<String, dynamic> generateProcessDesignDocument(GeneratedProcess process) {
    return {
      'title': 'Process Design Document: ${process.name}',
      'generated_date': process.created.toIso8601String(),
      'project_characteristics': process.characteristics.toJson(),
      'governance_configuration': process.governance.toJson(),
      'executive_summary': _generateExecutiveSummary(process),
      'process_overview': _generateProcessOverview(process),
      'phases_and_activities': _generatePhasesAndActivities(process),
      'roles_and_responsibilities': _generateRolesAndResponsibilities(process),
      'deliverables_and_artifacts': _generateDeliverablesAndArtifacts(process),
      'decision_gates': _generateDecisionGates(process),
      'tailoring_justification': _generateTailoringJustification(process),
      'standards_references': _generateStandardsReferences(process),
      'process_diagrams': _generateProcessDiagrams(process),
      'implementation_guidance': _generateImplementationGuidance(process),
    };
  }

  String _generateExecutiveSummary(GeneratedProcess process) {
    final characteristics = process.characteristics;
    final governance = process.governance;

    return '''
This document presents a tailored project management process for a ${characteristics.projectType.toLowerCase()} project with ${characteristics.complexity.toLowerCase()} complexity, ${characteristics.size.toLowerCase()} scale, and ${governance.level.toLowerCase()} governance requirements.

The process integrates best practices from PMBOK 7th Edition, PRINCE2 7th Edition, and ISO 21502:2020, specifically tailored for:
- Duration: ${characteristics.duration}
- Industry: ${characteristics.industry}
- Risk Level: ${characteristics.riskLevel}
- Team Size: ${characteristics.size}

Key tailoring decisions include ${governance.level.toLowerCase()} governance oversight, ${process.recommendations.where((r) => r.isRequired).length} required processes, and ${process.recommendations.where((r) => !r.isRequired).length} optional processes to optimize for project success while maintaining appropriate controls.
''';
  }

  Map<String, dynamic> _generateProcessOverview(GeneratedProcess process) {
    final requiredProcesses =
        process.recommendations.where((r) => r.isRequired).toList();
    final optionalProcesses =
        process.recommendations.where((r) => !r.isRequired).toList();

    return {
      'life_cycle_approach': _determineLifeCycleApproach(
        process.characteristics,
      ),
      'governance_model': process.governance.level,
      'required_processes':
          requiredProcesses
              .map(
                (r) => {
                  'name': r.name,
                  'source': r.source,
                  'category': r.category,
                  'rationale': r.rationale,
                },
              )
              .toList(),
      'optional_processes':
          optionalProcesses
              .map(
                (r) => {
                  'name': r.name,
                  'source': r.source,
                  'category': r.category,
                  'rationale': r.rationale,
                },
              )
              .toList(),
      'key_success_factors': _generateKeySuccessFactors(process),
    };
  }

  String _determineLifeCycleApproach(ProjectCharacteristics characteristics) {
    switch (characteristics.projectType) {
      case 'Software Development':
        return 'Adaptive/Agile with iterative delivery cycles';
      case 'Product Development':
        return 'Hybrid (Predictive planning with adaptive execution)';
      case 'Infrastructure':
        return 'Predictive with stage-gate governance';
      default:
        return 'Hybrid approach balancing predictability and adaptability';
    }
  }

  List<String> _generateKeySuccessFactors(GeneratedProcess process) {
    final factors = <String>[];
    final characteristics = process.characteristics;

    if (characteristics.constraints.contains('Time Critical')) {
      factors.add('Rapid decision-making and streamlined approvals');
    }
    if (characteristics.constraints.contains('Resource Constrained')) {
      factors.add(
        'Efficient resource utilization and multi-skilled team members',
      );
    }
    if (characteristics.constraints.contains('Regulatory Compliance')) {
      factors.add('Comprehensive compliance management and audit readiness');
    }
    if (characteristics.riskLevel == 'High' ||
        characteristics.riskLevel == 'Critical') {
      factors.add('Proactive risk management and contingency planning');
    }
    if (characteristics.complexity == 'High' ||
        characteristics.complexity == 'Very High') {
      factors.add('Strong integration management and stakeholder coordination');
    }

    factors.addAll([
      'Clear communication channels and regular stakeholder engagement',
      'Quality-focused delivery with appropriate testing and validation',
      'Continuous learning and process improvement',
    ]);

    return factors;
  }

  Map<String, dynamic> _generateStandardsReferences(GeneratedProcess process) {
    final references = <String, List<String>>{
      'PMBOK_7th_Edition': [],
      'PRINCE2_7th_Edition': [],
      'ISO_21502_2020': [],
    };

    for (final recommendation in process.recommendations) {
      switch (recommendation.source) {
        case 'PMBOK':
          references['PMBOK_7th_Edition']!.add(
            '${recommendation.name}: ${recommendation.rationale}',
          );
          break;
        case 'PRINCE2':
          references['PRINCE2_7th_Edition']!.add(
            '${recommendation.name}: ${recommendation.rationale}',
          );
          break;
        case 'ISO21502':
          references['ISO_21502_2020']!.add(
            '${recommendation.name}: ${recommendation.rationale}',
          );
          break;
        case 'Cross-Standard Analysis':
          // Add to all three standards
          references['PMBOK_7th_Edition']!.add(
            'Cross-reference: ${recommendation.name}',
          );
          references['PRINCE2_7th_Edition']!.add(
            'Cross-reference: ${recommendation.name}',
          );
          references['ISO_21502_2020']!.add(
            'Cross-reference: ${recommendation.name}',
          );
          break;
      }
    }

    return {
      'standards_integration':
          'This process integrates practices from all three major PM standards',
      'pmbok_references': references['PMBOK_7th_Edition'],
      'prince2_references': references['PRINCE2_7th_Edition'],
      'iso21502_references': references['ISO_21502_2020'],
      'tailoring_rationale': _generateTailoringJustification(process),
    };
  }

  String _generateTailoringJustification(GeneratedProcess process) {
    final characteristics = process.characteristics;
    final governance = process.governance;
    final justifications = <String>[];

    // Size-based tailoring
    switch (characteristics.size) {
      case 'Small':
        justifications.add(
          'Lightweight processes selected due to small team size, reducing overhead while maintaining essential controls.',
        );
        break;
      case 'Medium':
        justifications.add(
          'Balanced process approach appropriate for medium-scale project with moderate resource requirements.',
        );
        break;
      case 'Large':
        justifications.add(
          'Comprehensive processes implemented to manage large-scale complexity and coordination requirements.',
        );
        break;
    }

    // Duration-based tailoring
    if (characteristics.duration.contains('<') ||
        characteristics.duration.contains('3-6')) {
      justifications.add(
        'Accelerated processes and simplified documentation to meet tight timeline constraints.',
      );
    } else if (characteristics.duration.contains('>') ||
        characteristics.duration.contains('12')) {
      justifications.add(
        'Extended governance and comprehensive planning processes to manage long-term project risks.',
      );
    }

    // Risk-based tailoring
    switch (characteristics.riskLevel) {
      case 'Low':
        justifications.add(
          'Simplified risk management processes appropriate for low-risk project environment.',
        );
        break;
      case 'High':
      case 'Critical':
        justifications.add(
          'Enhanced risk management and contingency planning due to high-risk project profile.',
        );
        break;
    }

    // Governance-based tailoring
    switch (governance.level) {
      case 'Light':
        justifications.add(
          'Minimal governance overhead to enable agility and rapid decision-making.',
        );
        break;
      case 'Heavy':
        justifications.add(
          'Comprehensive governance framework to ensure proper oversight and compliance.',
        );
        break;
    }

    return justifications.join(' ');
  }

  Map<String, dynamic> _generatePhasesAndActivities(GeneratedProcess process) {
    final phases = <Map<String, dynamic>>[];

    // Generate phases based on governance level and project type
    switch (process.governance.level) {
      case 'Light':
        phases.addAll([
          {
            'name': 'Project Start',
            'description': 'Quick project initiation and team formation',
            'activities': [
              'Define objectives',
              'Form team',
              'Create initial plan',
            ],
            'duration': '1-2 weeks',
          },
          {
            'name': 'Execution',
            'description': 'Iterative delivery of project outcomes',
            'activities': [
              'Develop deliverables',
              'Regular reviews',
              'Stakeholder feedback',
            ],
            'duration': '80% of project',
          },
          {
            'name': 'Closure',
            'description': 'Project completion and handover',
            'activities': [
              'Final delivery',
              'Lessons learned',
              'Team dissolution',
            ],
            'duration': '1 week',
          },
        ]);
        break;
      case 'Moderate':
        phases.addAll([
          {
            'name': 'Initiation',
            'description': 'Project charter and initial planning',
            'activities': [
              'Business case',
              'Charter approval',
              'Team formation',
            ],
            'duration': '2-3 weeks',
          },
          {
            'name': 'Planning',
            'description': 'Detailed project planning',
            'activities': [
              'Scope definition',
              'Schedule planning',
              'Risk assessment',
            ],
            'duration': '3-4 weeks',
          },
          {
            'name': 'Execution',
            'description': 'Project delivery with regular monitoring',
            'activities': [
              'Deliverable creation',
              'Quality control',
              'Progress monitoring',
            ],
            'duration': '70% of project',
          },
          {
            'name': 'Closure',
            'description': 'Project completion and evaluation',
            'activities': [
              'Final delivery',
              'Benefits review',
              'Documentation',
            ],
            'duration': '1-2 weeks',
          },
        ]);
        break;
      case 'Heavy':
        phases.addAll([
          {
            'name': 'Pre-Project',
            'description': 'Business case development and approval',
            'activities': [
              'Strategic alignment',
              'Business case',
              'Initial risk assessment',
            ],
            'duration': '4-6 weeks',
          },
          {
            'name': 'Initiation',
            'description': 'Formal project initiation',
            'activities': [
              'Project charter',
              'Governance setup',
              'Team establishment',
            ],
            'duration': '3-4 weeks',
          },
          {
            'name': 'Planning',
            'description': 'Comprehensive project planning',
            'activities': [
              'Detailed planning',
              'Risk management',
              'Procurement planning',
            ],
            'duration': '6-8 weeks',
          },
          {
            'name': 'Execution Stages',
            'description': 'Multiple execution stages with gates',
            'activities': [
              'Stage delivery',
              'Quality assurance',
              'Stage reviews',
            ],
            'duration': '60% of project',
          },
          {
            'name': 'Closure',
            'description': 'Formal project closure',
            'activities': [
              'Final delivery',
              'Benefits realization',
              'Post-project review',
            ],
            'duration': '2-3 weeks',
          },
        ]);
        break;
    }

    return {
      'life_cycle_model': _determineLifeCycleApproach(process.characteristics),
      'phases': phases,
      'total_phases': phases.length,
    };
  }

  Map<String, dynamic> _generateRolesAndResponsibilities(
    GeneratedProcess process,
  ) {
    final roles = <Map<String, dynamic>>[];

    // Core roles based on governance level
    switch (process.governance.level) {
      case 'Light':
        roles.addAll([
          {
            'role': 'Project Leader',
            'responsibilities': [
              'Overall project coordination',
              'Stakeholder communication',
              'Decision making',
            ],
            'authority': 'Full project authority within budget',
            'skills': ['Leadership', 'Communication', 'Technical knowledge'],
          },
          {
            'role': 'Team Members',
            'responsibilities': [
              'Deliverable creation',
              'Quality assurance',
              'Progress reporting',
            ],
            'authority': 'Work package authority',
            'skills': [
              'Technical expertise',
              'Collaboration',
              'Problem solving',
            ],
          },
        ]);
        break;
      case 'Moderate':
        roles.addAll([
          {
            'role': 'Project Manager',
            'responsibilities': [
              'Project planning',
              'Risk management',
              'Team coordination',
            ],
            'authority': 'Project execution authority',
            'skills': ['Project management', 'Leadership', 'Risk management'],
          },
          {
            'role': 'Project Sponsor',
            'responsibilities': [
              'Business case ownership',
              'Strategic guidance',
              'Resource approval',
            ],
            'authority': 'Budget and resource authority',
            'skills': [
              'Business acumen',
              'Strategic thinking',
              'Decision making',
            ],
          },
          {
            'role': 'Team Leads',
            'responsibilities': [
              'Work package delivery',
              'Team management',
              'Quality control',
            ],
            'authority': 'Team and work package authority',
            'skills': [
              'Technical leadership',
              'Team management',
              'Quality assurance',
            ],
          },
        ]);
        break;
      case 'Heavy':
        roles.addAll([
          {
            'role': 'Project Board',
            'responsibilities': [
              'Strategic oversight',
              'Major decisions',
              'Resource authorization',
            ],
            'authority': 'Full project authority',
            'skills': ['Strategic leadership', 'Governance', 'Decision making'],
          },
          {
            'role': 'Project Manager',
            'responsibilities': [
              'Day-to-day management',
              'Planning',
              'Risk management',
            ],
            'authority': 'Operational authority within tolerances',
            'skills': ['Project management', 'Leadership', 'Communication'],
          },
          {
            'role': 'Team Managers',
            'responsibilities': [
              'Team delivery',
              'Resource management',
              'Quality assurance',
            ],
            'authority': 'Team and resource authority',
            'skills': [
              'Team management',
              'Technical expertise',
              'Quality management',
            ],
          },
          {
            'role': 'Project Assurance',
            'responsibilities': [
              'Independent oversight',
              'Compliance monitoring',
              'Risk assessment',
            ],
            'authority': 'Assurance and reporting authority',
            'skills': ['Audit', 'Risk management', 'Compliance'],
          },
        ]);
        break;
    }

    return {
      'governance_model': process.governance.level,
      'roles': roles,
      'role_assignments': process.governance.roleAssignments,
    };
  }

  Map<String, dynamic> _generateDeliverablesAndArtifacts(
    GeneratedProcess process,
  ) {
    final deliverables = <Map<String, dynamic>>[];

    // Core deliverables based on recommendations
    for (final recommendation in process.recommendations.where(
      (r) => r.isRequired,
    )) {
      if (recommendation.outputs.isNotEmpty) {
        deliverables.add({
          'category': recommendation.category,
          'process': recommendation.name,
          'outputs': recommendation.outputs,
          'source_standard': recommendation.source,
        });
      }
    }

    // Add governance-specific deliverables
    switch (process.governance.level) {
      case 'Light':
        deliverables.add({
          'category': 'Project Management',
          'process': 'Project Coordination',
          'outputs': ['Project Charter', 'Progress Reports', 'Final Report'],
          'source_standard': 'Tailored',
        });
        break;
      case 'Moderate':
        deliverables.add({
          'category': 'Project Management',
          'process': 'Project Management',
          'outputs': [
            'Project Management Plan',
            'Status Reports',
            'Stage Reports',
            'Lessons Learned',
          ],
          'source_standard': 'Tailored',
        });
        break;
      case 'Heavy':
        deliverables.add({
          'category': 'Project Management',
          'process': 'Comprehensive Management',
          'outputs': [
            'Business Case',
            'Project Management Plan',
            'Stage Reports',
            'Benefits Report',
            'Post-Project Review',
          ],
          'source_standard': 'Tailored',
        });
        break;
    }

    return {
      'total_deliverables': deliverables.length,
      'deliverables_by_category': deliverables,
      'quality_criteria':
          'All deliverables must meet defined quality criteria and stakeholder acceptance',
    };
  }

  Map<String, dynamic> _generateDecisionGates(GeneratedProcess process) {
    final gates = <Map<String, dynamic>>[];

    // Decision gates based on governance level
    switch (process.governance.level) {
      case 'Light':
        gates.addAll([
          {
            'name': 'Project Start Gate',
            'criteria': [
              'Objectives clear',
              'Team ready',
              'Initial plan approved',
            ],
            'authority': 'Project Leader',
            'deliverables': ['Project Charter', 'Initial Plan'],
          },
          {
            'name': 'Mid-Project Review',
            'criteria': [
              'Progress on track',
              'Quality acceptable',
              'Risks managed',
            ],
            'authority': 'Project Leader + Stakeholders',
            'deliverables': ['Progress Report', 'Quality Review'],
          },
          {
            'name': 'Project Closure',
            'criteria': [
              'Deliverables complete',
              'Stakeholder acceptance',
              'Lessons captured',
            ],
            'authority': 'Project Leader',
            'deliverables': ['Final Report', 'Lessons Learned'],
          },
        ]);
        break;
      case 'Moderate':
        gates.addAll([
          {
            'name': 'Project Authorization',
            'criteria': [
              'Business case approved',
              'Resources allocated',
              'Charter signed',
            ],
            'authority': 'Project Sponsor',
            'deliverables': [
              'Business Case',
              'Project Charter',
              'Resource Plan',
            ],
          },
          {
            'name': 'Planning Approval',
            'criteria': ['Plans complete', 'Risks assessed', 'Budget approved'],
            'authority': 'Project Sponsor',
            'deliverables': [
              'Project Management Plan',
              'Risk Register',
              'Budget',
            ],
          },
          {
            'name': 'Stage Reviews',
            'criteria': [
              'Stage objectives met',
              'Quality criteria satisfied',
              'Next stage ready',
            ],
            'authority': 'Project Manager',
            'deliverables': [
              'Stage Report',
              'Quality Review',
              'Next Stage Plan',
            ],
          },
          {
            'name': 'Project Closure',
            'criteria': [
              'All objectives met',
              'Benefits delivered',
              'Handover complete',
            ],
            'authority': 'Project Sponsor',
            'deliverables': [
              'Final Report',
              'Benefits Report',
              'Handover Documentation',
            ],
          },
        ]);
        break;
      case 'Heavy':
        gates.addAll([
          {
            'name': 'Business Case Approval',
            'criteria': [
              'Strategic alignment',
              'Financial justification',
              'Risk acceptable',
            ],
            'authority': 'Project Board',
            'deliverables': [
              'Business Case',
              'Financial Analysis',
              'Risk Assessment',
            ],
          },
          {
            'name': 'Project Initiation',
            'criteria': [
              'Charter approved',
              'Governance established',
              'Team formed',
            ],
            'authority': 'Project Board',
            'deliverables': [
              'Project Charter',
              'Governance Framework',
              'Team Structure',
            ],
          },
          {
            'name': 'Planning Gate',
            'criteria': [
              'Comprehensive plans',
              'Budget approved',
              'Risks mitigated',
            ],
            'authority': 'Project Board',
            'deliverables': [
              'Project Management Plan',
              'Budget',
              'Risk Management Plan',
            ],
          },
          {
            'name': 'Stage Gates',
            'criteria': [
              'Stage completion',
              'Quality assured',
              'Business case valid',
            ],
            'authority': 'Project Board',
            'deliverables': [
              'Stage Report',
              'Quality Audit',
              'Business Case Update',
            ],
          },
          {
            'name': 'Benefits Review',
            'criteria': [
              'Benefits realized',
              'ROI achieved',
              'Success measured',
            ],
            'authority': 'Project Board',
            'deliverables': [
              'Benefits Report',
              'ROI Analysis',
              'Success Metrics',
            ],
          },
        ]);
        break;
    }

    return {
      'governance_level': process.governance.level,
      'decision_gates': gates,
      'gate_criteria':
          'All gates must be passed before proceeding to next phase',
    };
  }

  Map<String, dynamic> _generateProcessDiagrams(GeneratedProcess process) {
    // This would generate process flow diagrams
    // For now, return a description of the process flow
    return {
      'process_flow_description': _generateProcessFlowDescription(process),
      'governance_structure': _generateGovernanceStructure(process),
      'decision_flow':
          'Decision points aligned with governance level and project complexity',
    };
  }

  String _generateProcessFlowDescription(GeneratedProcess process) {
    switch (process.governance.level) {
      case 'Light':
        return 'Linear flow: Start → Execute → Review → Close with minimal gates';
      case 'Moderate':
        return 'Structured flow: Initiate → Plan → Execute → Monitor → Close with regular reviews';
      case 'Heavy':
        return 'Comprehensive flow: Pre-Project → Initiate → Plan → Execute (Stages) → Close with formal gates';
      default:
        return 'Adaptive flow based on project needs';
    }
  }

  String _generateGovernanceStructure(GeneratedProcess process) {
    switch (process.governance.level) {
      case 'Light':
        return 'Flat structure with Project Leader and Team Members';
      case 'Moderate':
        return 'Hierarchical structure with Sponsor, Project Manager, and Team Leads';
      case 'Heavy':
        return 'Formal structure with Project Board, Project Manager, Team Managers, and Assurance';
      default:
        return 'Flexible structure adapted to project needs';
    }
  }

  Map<String, dynamic> _generateImplementationGuidance(
    GeneratedProcess process,
  ) {
    final guidance = <String, dynamic>{};

    guidance['getting_started'] = [
      'Review and customize the process to fit your specific context',
      'Ensure all stakeholders understand their roles and responsibilities',
      'Set up the governance structure and communication channels',
      'Establish the project management tools and systems',
    ];

    guidance['success_factors'] = _generateKeySuccessFactors(process);

    guidance['common_pitfalls'] = [
      'Insufficient stakeholder engagement',
      'Inadequate risk management',
      'Poor communication',
      'Scope creep without proper change control',
    ];

    guidance['tools_and_techniques'] = [];
    for (final recommendation in process.recommendations.where(
      (r) => r.tools.isNotEmpty,
    )) {
      guidance['tools_and_techniques'].addAll(recommendation.tools);
    }

    guidance['monitoring_and_control'] = [
      'Regular progress reviews against plan',
      'Quality checkpoints at key milestones',
      'Risk monitoring and mitigation',
      'Stakeholder feedback and engagement',
    ];

    return guidance;
  }

  Map<String, dynamic> _generateTailoringDecisions(
    ProjectCharacteristics characteristics,
    GovernanceConfiguration governance,
  ) {
    return {
      'governanceLevel': governance.level,
      'projectSize': characteristics.size,
      'complexity': characteristics.complexity,
      'riskLevel': characteristics.riskLevel,
      'industry': characteristics.industry,
      'tailoringRationale':
          'Process tailored based on project characteristics and governance requirements',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Saved processes management
  String saveProcess(GeneratedProcess process) {
    _generatedProcesses[process.id] = process;
    _saveProcesses();
    notifyListeners();
    return process.id;
  }

  String saveCurrentProcess({String? customName}) {
    if (_currentProcess == null) {
      throw StateError('No current process to save');
    }

    final process =
        customName != null
            ? GeneratedProcess(
              id: _currentProcess!.id,
              name: customName,
              created: _currentProcess!.created,
              characteristics: _currentProcess!.characteristics,
              governance: _currentProcess!.governance,
              recommendations: _currentProcess!.recommendations,
              tailoringDecisions: _currentProcess!.tailoringDecisions,
              tags: _currentProcess!.tags,
            )
            : _currentProcess!;

    return saveProcess(process);
  }

  void deleteProcess(String id) {
    _generatedProcesses.remove(id);
    _saveProcesses();
    notifyListeners();
  }

  void loadProcess(String id) {
    final process = _generatedProcesses[id];
    if (process != null) {
      _currentProcess = process;
      _currentCharacteristics = process.characteristics;
      _currentGovernance = process.governance;
      _saveCurrentProcess();
      notifyListeners();
    }
  }

  void clearCurrentProcess() {
    _currentProcess = null;
    _currentCharacteristics = null;
    _currentGovernance = null;
    _prefs.remove(_currentProcessKey);
    notifyListeners();
  }

  // Statistics and analytics
  int get totalProcesses => _generatedProcesses.length;

  Map<String, int> getProjectTypeFrequency() {
    final frequency = <String, int>{};
    for (final process in _generatedProcesses.values) {
      final type = process.characteristics.projectType;
      frequency[type] = (frequency[type] ?? 0) + 1;
    }
    return frequency;
  }

  Map<String, int> getGovernanceLevelFrequency() {
    final frequency = <String, int>{};
    for (final process in _generatedProcesses.values) {
      final level = process.governance.level;
      frequency[level] = (frequency[level] ?? 0) + 1;
    }
    return frequency;
  }

  // Configuration data loading
  Future<void> _loadConfigurationData() async {
    try {
      final tailoringRulesJson = await rootBundle.loadString(
        'assets/tailoring_rules.json',
      );
      _tailoringRules = json.decode(tailoringRulesJson);

      final baselineRulesJson = await rootBundle.loadString(
        'assets/baseline_rules.json',
      );
      _baselineRules = json.decode(baselineRulesJson);
    } catch (e) {
      debugPrint('Error loading configuration data: $e');
    }
  }

  // Data persistence
  void _loadData() {
    // Load generated processes
    final processesRaw = _prefs.getString(_generatedProcessesKey);
    if (processesRaw != null) {
      try {
        final data = json.decode(processesRaw) as Map<String, dynamic>;
        for (final entry in data.entries) {
          _generatedProcesses[entry.key] = GeneratedProcess.fromJson(
            entry.value,
          );
        }
      } catch (e) {
        debugPrint('Error loading generated processes: $e');
      }
    }

    // Load current process
    final currentRaw = _prefs.getString(_currentProcessKey);
    if (currentRaw != null) {
      try {
        final processData = json.decode(currentRaw) as Map<String, dynamic>;
        _currentProcess = GeneratedProcess.fromJson(processData);
        _currentCharacteristics = _currentProcess!.characteristics;
        _currentGovernance = _currentProcess!.governance;
      } catch (e) {
        debugPrint('Error loading current process: $e');
      }
    }
  }

  void _saveProcesses() {
    final data = <String, dynamic>{};
    for (final entry in _generatedProcesses.entries) {
      data[entry.key] = entry.value.toJson();
    }
    _prefs.setString(_generatedProcessesKey, json.encode(data));
  }

  void _saveCurrentProcess() {
    if (_currentProcess != null) {
      _prefs.setString(
        _currentProcessKey,
        json.encode(_currentProcess!.toJson()),
      );
    }
  }
}
