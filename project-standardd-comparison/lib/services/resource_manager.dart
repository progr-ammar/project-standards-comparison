import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

import 'error_handling_service.dart';
import 'performance_monitor.dart';

class CacheStats {
  final int totalItems;
  final int totalSizeBytes;
  final int hitCount;
  final int missCount;
  final double hitRate;

  CacheStats({
    required this.totalItems,
    required this.totalSizeBytes,
    required this.hitCount,
    required this.missCount,
    required this.hitRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalItems': totalItems,
      'totalSizeBytes': totalSizeBytes,
      'hitCount': hitCount,
      'missCount': missCount,
      'hitRate': hitRate,
    };
  }
}

class ResourceManager {
  static final ResourceManager _instance = ResourceManager._internal();
  factory ResourceManager() => _instance;
  ResourceManager._internal();

  final ErrorHandlingService _errorHandler = ErrorHandlingService();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  // Cache management
  final Map<String, dynamic> _cache = {};
  final Queue<String> _cacheAccessOrder = Queue<String>();
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, int> _cacheSizes = {};

  int _currentCacheSizeBytes = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;

  Timer? _cleanupTimer;

  static const int _maxCacheItems = 100;
  static const int _maxCacheSizeBytes = 50 * 1024 * 1024; // 50MB
  static const Duration _cacheExpiry = Duration(hours: 1);
  static const Duration _cleanupInterval = Duration(minutes: 5);

  void initialize() {
    _startPeriodicCleanup();
    _performanceMonitor.startMonitoring();

    debugPrint('Resource manager initialized');
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
    _cacheAccessOrder.clear();
    _currentCacheSizeBytes = 0;
    _performanceMonitor.dispose();

    debugPrint('Resource manager disposed');
  }

  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _performCleanup();
    });
  }

  // Cache operations
  T? getCachedData<T>(String key) {
    if (!_cache.containsKey(key)) {
      _cacheMisses++;
      return null;
    }

    // Check expiry
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null &&
        DateTime.now().difference(timestamp) > _cacheExpiry) {
      _removeCacheItem(key);
      _cacheMisses++;
      return null;
    }

    // Update access order
    _cacheAccessOrder.remove(key);
    _cacheAccessOrder.addLast(key);

    _cacheHits++;
    return _cache[key] as T?;
  }

  void cacheData<T>(String key, T data, {int? sizeBytes}) {
    try {
      // Estimate size if not provided
      final estimatedSize = sizeBytes ?? _estimateDataSize(data);

      // Remove existing item if present
      if (_cache.containsKey(key)) {
        _removeCacheItem(key);
      }

      // Check if we need to make space
      _ensureCacheSpace(estimatedSize);

      // Add new item
      _cache[key] = data;
      _cacheTimestamps[key] = DateTime.now();
      _cacheSizes[key] = estimatedSize;
      _currentCacheSizeBytes += estimatedSize;
      _cacheAccessOrder.addLast(key);

      debugPrint('Cached data: $key (${estimatedSize} bytes)');
    } catch (e) {
      final error = AppError(
        type: ErrorType.processingError,
        severity: ErrorSeverity.low,
        message: 'Failed to cache data',
        details: 'Key: $key, Error: $e',
        context: 'Resource manager',
      );
      _errorHandler.logError(error);
    }
  }

  void _ensureCacheSpace(int requiredBytes) {
    // Remove expired items first
    _removeExpiredItems();

    // Remove least recently used items if needed
    while ((_cache.length >= _maxCacheItems ||
            _currentCacheSizeBytes + requiredBytes > _maxCacheSizeBytes) &&
        _cacheAccessOrder.isNotEmpty) {
      final oldestKey = _cacheAccessOrder.removeFirst();
      _removeCacheItem(oldestKey);
    }
  }

  void _removeCacheItem(String key) {
    if (_cache.containsKey(key)) {
      final size = _cacheSizes[key] ?? 0;
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      _cacheSizes.remove(key);
      _currentCacheSizeBytes -= size;
      _cacheAccessOrder.remove(key);
    }
  }

  void _removeExpiredItems() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _removeCacheItem(key);
    }

    if (expiredKeys.isNotEmpty) {
      debugPrint('Removed ${expiredKeys.length} expired cache items');
    }
  }

  int _estimateDataSize(dynamic data) {
    if (data == null) return 0;

    if (data is String) {
      return data.length * 2; // Rough estimate for UTF-16
    } else if (data is List) {
      return data.length * 100; // Rough estimate
    } else if (data is Map) {
      return data.length * 200; // Rough estimate
    } else {
      return 1000; // Default estimate
    }
  }

  // Cache management
  void clearCache() {
    final itemCount = _cache.length;
    final sizeBytes = _currentCacheSizeBytes;

    _cache.clear();
    _cacheAccessOrder.clear();
    _cacheTimestamps.clear();
    _cacheSizes.clear();
    _currentCacheSizeBytes = 0;

    debugPrint('Cleared cache: $itemCount items, ${sizeBytes} bytes');
  }

  void _performCleanup() {
    try {
      final initialItems = _cache.length;
      final initialSize = _currentCacheSizeBytes;

      // Remove expired items
      _removeExpiredItems();

      // Check memory pressure and perform additional cleanup if needed
      final metrics = _performanceMonitor.getLatestMetrics();
      if (metrics != null && metrics.memoryUsageMB > 400) {
        // 400MB threshold
        _performAggressiveCleanup();
      }

      final removedItems = initialItems - _cache.length;
      final freedBytes = initialSize - _currentCacheSizeBytes;

      if (removedItems > 0) {
        debugPrint(
          'Cleanup completed: removed $removedItems items, freed $freedBytes bytes',
        );
      }
    } catch (e) {
      debugPrint('Error during cache cleanup: $e');
    }
  }

  void _performAggressiveCleanup() {
    // Remove half of the least recently used items
    final itemsToRemove = _cache.length ~/ 2;

    for (int i = 0; i < itemsToRemove && _cacheAccessOrder.isNotEmpty; i++) {
      final key = _cacheAccessOrder.removeFirst();
      _removeCacheItem(key);
    }

    debugPrint('Performed aggressive cleanup: removed $itemsToRemove items');
  }

  // Statistics and monitoring
  CacheStats getCacheStats() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 ? _cacheHits / totalRequests : 0.0;

    return CacheStats(
      totalItems: _cache.length,
      totalSizeBytes: _currentCacheSizeBytes,
      hitCount: _cacheHits,
      missCount: _cacheMisses,
      hitRate: hitRate,
    );
  }

  Map<String, dynamic> getHealthStatus() {
    final stats = getCacheStats();

    return {
      'cacheStats': stats.toJson(),
      'isHealthy': isHealthy(),
      'memoryPressure': _getMemoryPressureLevel(),
      'optimizationSuggestions': getResourceOptimizationSuggestions(),
    };
  }

  bool isHealthy() {
    return _currentCacheSizeBytes < _maxCacheSizeBytes * 0.8 &&
        _cache.length < _maxCacheItems * 0.8;
  }

  String _getMemoryPressureLevel() {
    final sizeRatio = _currentCacheSizeBytes / _maxCacheSizeBytes;
    final itemRatio = _cache.length / _maxCacheItems;
    final maxRatio = sizeRatio > itemRatio ? sizeRatio : itemRatio;

    if (maxRatio > 0.9) return 'high';
    if (maxRatio > 0.7) return 'medium';
    return 'low';
  }

  List<String> getResourceOptimizationSuggestions() {
    final suggestions = <String>[];
    final stats = getCacheStats();

    if (stats.totalSizeBytes > _maxCacheSizeBytes * 0.8) {
      suggestions.add('Cache size is high - consider clearing cache');
    }

    if (stats.totalItems > _maxCacheItems * 0.8) {
      suggestions.add('Many cached items - some may be unused');
    }

    if (stats.hitRate < 0.5 && stats.hitCount + stats.missCount > 20) {
      suggestions.add('Low cache hit rate - cache may not be effective');
    }

    // Add performance monitor suggestions
    suggestions.addAll(_performanceMonitor.getOptimizationSuggestions());

    return suggestions;
  }

  // Manual resource management
  void optimizeResources() {
    final operationId = _performanceMonitor.startOperation(
      'Resource optimization',
    );

    try {
      _performanceMonitor.updateOperationProgress(
        operationId,
        0.2,
        currentStep: 'Analyzing cache',
      );

      final initialStats = getCacheStats();

      // Remove expired items
      _removeExpiredItems();

      _performanceMonitor.updateOperationProgress(
        operationId,
        0.4,
        currentStep: 'Removing expired items',
      );

      // Perform cleanup based on memory pressure
      final memoryPressure = _getMemoryPressureLevel();
      if (memoryPressure == 'high') {
        _performAggressiveCleanup();
      }

      _performanceMonitor.updateOperationProgress(
        operationId,
        0.6,
        currentStep: 'Optimizing cache size',
      );

      // Reset statistics for fresh monitoring
      if (initialStats.hitRate < 0.3 &&
          initialStats.hitCount + initialStats.missCount > 50) {
        _cacheHits = 0;
        _cacheMisses = 0;
      }

      _performanceMonitor.updateOperationProgress(
        operationId,
        1.0,
        currentStep: 'Optimization complete',
      );
      _performanceMonitor.completeOperation(operationId);

      debugPrint('Resource optimization completed');
    } catch (e) {
      _performanceMonitor.cancelOperation(
        operationId,
        reason: 'Optimization failed: $e',
      );
      rethrow;
    }
  }

  // Preloading and prefetching
  void preloadData(String key, Future<dynamic> dataFuture) {
    dataFuture
        .then((data) {
          if (data != null) {
            cacheData(key, data);
          }
        })
        .catchError((e) {
          debugPrint('Failed to preload data for key $key: $e');
        });
  }

  // Cache warming
  void warmCache(Map<String, dynamic> initialData) {
    for (final entry in initialData.entries) {
      cacheData(entry.key, entry.value);
    }

    debugPrint('Cache warmed with ${initialData.length} items');
  }
}
