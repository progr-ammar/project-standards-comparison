import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'error_handling_service.dart';

class PerformanceMetrics {
  final double memoryUsageMB;
  final int activeOperations;
  final Duration averageOperationTime;
  final DateTime timestamp;

  PerformanceMetrics({
    required this.memoryUsageMB,
    required this.activeOperations,
    required this.averageOperationTime,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'memoryUsageMB': memoryUsageMB,
      'activeOperations': activeOperations,
      'averageOperationTime': averageOperationTime.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class OperationProgress {
  final String id;
  final String name;
  final double progress;
  final String currentStep;
  final DateTime startTime;
  final bool isHeavy;

  OperationProgress({
    required this.id,
    required this.name,
    required this.progress,
    required this.currentStep,
    required this.startTime,
    this.isHeavy = false,
  });

  Duration get elapsed => DateTime.now().difference(startTime);
}

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final ErrorHandlingService _errorHandler = ErrorHandlingService();

  final Map<String, OperationProgress> _activeOperations = {};
  final List<PerformanceMetrics> _metricsHistory = [];
  final List<Duration> _operationTimes = [];

  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  static const int _maxHistorySize = 100;
  static const int _maxOperationTimes = 50;

  // Monitoring control
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _collectMetrics(),
    );

    debugPrint('Performance monitoring started');
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;

    debugPrint('Performance monitoring stopped');
  }

  void dispose() {
    stopMonitoring();
    _activeOperations.clear();
    _metricsHistory.clear();
    _operationTimes.clear();
  }

  // Operation tracking
  String startOperation(String name, {bool isHeavy = false}) {
    final id = '${name}_${DateTime.now().millisecondsSinceEpoch}';

    _activeOperations[id] = OperationProgress(
      id: id,
      name: name,
      progress: 0.0,
      currentStep: 'Starting...',
      startTime: DateTime.now(),
      isHeavy: isHeavy,
    );

    debugPrint('Started operation: $name (ID: $id)');
    return id;
  }

  void updateOperationProgress(
    String operationId,
    double progress, {
    String? currentStep,
  }) {
    final operation = _activeOperations[operationId];
    if (operation == null) return;

    _activeOperations[operationId] = OperationProgress(
      id: operation.id,
      name: operation.name,
      progress: progress.clamp(0.0, 1.0),
      currentStep: currentStep ?? operation.currentStep,
      startTime: operation.startTime,
      isHeavy: operation.isHeavy,
    );
  }

  void completeOperation(String operationId) {
    final operation = _activeOperations.remove(operationId);
    if (operation == null) return;

    final duration = operation.elapsed;
    _recordOperationTime(duration);

    debugPrint(
      'Completed operation: ${operation.name} in ${duration.inMilliseconds}ms',
    );
  }

  void cancelOperation(String operationId, {String? reason}) {
    final operation = _activeOperations.remove(operationId);
    if (operation == null) return;

    final error = AppError(
      type: ErrorType.processingError,
      severity: ErrorSeverity.medium,
      message: 'Operation cancelled: ${operation.name}',
      details: reason ?? 'Operation was cancelled',
      context: 'Performance monitoring',
    );

    _errorHandler.logError(error);

    debugPrint(
      'Cancelled operation: ${operation.name} (Reason: ${reason ?? 'Unknown'})',
    );
  }

  // Metrics collection
  void _collectMetrics() {
    try {
      final memoryUsage = _getMemoryUsage();
      final activeOpsCount = _activeOperations.length;
      final avgOperationTime = _getAverageOperationTime();

      final metrics = PerformanceMetrics(
        memoryUsageMB: memoryUsage,
        activeOperations: activeOpsCount,
        averageOperationTime: avgOperationTime,
        timestamp: DateTime.now(),
      );

      _metricsHistory.add(metrics);

      // Limit history size
      if (_metricsHistory.length > _maxHistorySize) {
        _metricsHistory.removeAt(0);
      }

      // Check for performance issues
      _checkPerformanceThresholds(metrics);
    } catch (e) {
      debugPrint('Error collecting performance metrics: $e');
    }
  }

  double _getMemoryUsage() {
    // Simplified memory usage calculation
    // In a real implementation, you might use more sophisticated methods
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile platforms - estimate based on active operations and cache
        return 50.0 + (_activeOperations.length * 10.0);
      } else {
        // Desktop platforms - basic estimation
        return 80.0 + (_activeOperations.length * 15.0);
      }
    } catch (e) {
      return 100.0; // Default fallback
    }
  }

  Duration _getAverageOperationTime() {
    if (_operationTimes.isEmpty) {
      return const Duration(milliseconds: 100);
    }

    final totalMs = _operationTimes
        .map((d) => d.inMilliseconds)
        .reduce((a, b) => a + b);

    return Duration(milliseconds: totalMs ~/ _operationTimes.length);
  }

  void _recordOperationTime(Duration duration) {
    _operationTimes.add(duration);

    // Limit operation times history
    if (_operationTimes.length > _maxOperationTimes) {
      _operationTimes.removeAt(0);
    }
  }

  void _checkPerformanceThresholds(PerformanceMetrics metrics) {
    // Memory usage threshold
    if (metrics.memoryUsageMB > 300) {
      final error = AppError(
        type: ErrorType.performanceError,
        severity: ErrorSeverity.medium,
        message: 'High memory usage detected',
        details: 'Memory usage: ${metrics.memoryUsageMB.toStringAsFixed(1)} MB',
        suggestion: 'Consider clearing cache or reducing active operations',
        context: 'Performance monitoring',
      );
      _errorHandler.logError(error);
    }

    // Too many active operations
    if (metrics.activeOperations > 10) {
      final error = AppError(
        type: ErrorType.performanceError,
        severity: ErrorSeverity.low,
        message: 'Many active operations',
        details: 'Active operations: ${metrics.activeOperations}',
        suggestion: 'Some operations may be taking longer than expected',
        context: 'Performance monitoring',
      );
      _errorHandler.logError(error);
    }
  }

  // Public getters
  List<OperationProgress> getActiveOperations() {
    return _activeOperations.values.toList();
  }

  bool hasActiveOperations() {
    return _activeOperations.isNotEmpty;
  }

  int getActiveOperationCount() {
    return _activeOperations.length;
  }

  PerformanceMetrics? getLatestMetrics() {
    return _metricsHistory.isNotEmpty ? _metricsHistory.last : null;
  }

  List<PerformanceMetrics> getMetricsHistory({int? limit}) {
    if (limit == null) return List.from(_metricsHistory);

    final startIndex = (_metricsHistory.length - limit).clamp(
      0,
      _metricsHistory.length,
    );
    return _metricsHistory.sublist(startIndex);
  }

  double getAverageMemoryUsage() {
    if (_metricsHistory.isEmpty) return 0.0;

    final totalMemory = _metricsHistory
        .map((m) => m.memoryUsageMB)
        .reduce((a, b) => a + b);

    return totalMemory / _metricsHistory.length;
  }

  double getPeakMemoryUsage() {
    if (_metricsHistory.isEmpty) return 0.0;

    return _metricsHistory
        .map((m) => m.memoryUsageMB)
        .reduce((a, b) => a > b ? a : b);
  }

  // Optimization suggestions
  List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];
    final latestMetrics = getLatestMetrics();

    if (latestMetrics == null) return suggestions;

    if (latestMetrics.memoryUsageMB > 200) {
      suggestions.add('Consider clearing cache to reduce memory usage');
    }

    if (latestMetrics.activeOperations > 5) {
      suggestions.add('Multiple operations running - some may be redundant');
    }

    if (latestMetrics.averageOperationTime.inMilliseconds > 2000) {
      suggestions.add(
        'Operations taking longer than expected - check network or processing',
      );
    }

    final heavyOps = _activeOperations.values.where((op) => op.isHeavy).length;
    if (heavyOps > 2) {
      suggestions.add(
        'Multiple heavy operations running - consider queuing them',
      );
    }

    return suggestions;
  }

  // Performance analysis
  Map<String, dynamic> getPerformanceReport() {
    final latestMetrics = getLatestMetrics();

    return {
      'currentMetrics': latestMetrics?.toJson(),
      'averageMemoryUsage': getAverageMemoryUsage(),
      'peakMemoryUsage': getPeakMemoryUsage(),
      'activeOperations': getActiveOperationCount(),
      'averageOperationTime': _getAverageOperationTime().inMilliseconds,
      'totalOperationsTracked': _operationTimes.length,
      'isMonitoring': _isMonitoring,
      'optimizationSuggestions': getOptimizationSuggestions(),
    };
  }

  // Health check
  bool isPerformanceHealthy() {
    final latestMetrics = getLatestMetrics();
    if (latestMetrics == null) return true;

    return latestMetrics.memoryUsageMB < 250 &&
        latestMetrics.activeOperations < 8 &&
        latestMetrics.averageOperationTime.inMilliseconds < 3000;
  }
}
