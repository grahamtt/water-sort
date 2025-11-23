import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/level.dart';
import '../models/container.dart';
import '../models/liquid_layer.dart';
import '../models/liquid_color.dart';
import 'test_mode_manager.dart';
import 'level_generator.dart';

/// Handles test mode errors and provides recovery strategies
class TestModeErrorHandler {
  static final Map<String, dynamic> _inMemoryFallbackState = {};
  static final StreamController<TestModeError> _errorController = 
      StreamController<TestModeError>.broadcast();

  /// Stream of test mode errors for monitoring and logging
  static Stream<TestModeError> get errorStream => _errorController.stream;

  /// Handle test mode errors with appropriate recovery strategies
  static Future<TestModeRecoveryResult> handleTestModeError(
    TestModeException error, {
    Map<String, dynamic>? context,
  }) async {
    final testModeError = TestModeError(
      exception: error,
      timestamp: DateTime.now(),
      context: context ?? {},
    );

    _errorController.add(testModeError);
    
    // Log error for debugging
    developer.log(
      'Test mode error: ${error.message}',
      name: 'TestModeErrorHandler',
      error: error,
      stackTrace: StackTrace.current,
    );

    switch (error.type) {
      case TestModeErrorType.persistenceFailure:
        return await _handlePersistenceFailure(error, context);
      case TestModeErrorType.levelGenerationFailure:
        return await _handleLevelGenerationFailure(error, context);
      case TestModeErrorType.progressCorruption:
        return await _handleProgressCorruption(error, context);
    }
  }

  /// Handle persistence failures with in-memory fallback
  static Future<TestModeRecoveryResult> _handlePersistenceFailure(
    TestModeException error,
    Map<String, dynamic>? context,
  ) async {
    try {
      // Store test mode state in memory as fallback
      final testModeEnabled = context?['testModeEnabled'] as bool? ?? false;
      _inMemoryFallbackState['test_mode_enabled'] = testModeEnabled;
      _inMemoryFallbackState['fallback_active'] = true;
      _inMemoryFallbackState['fallback_reason'] = 'persistence_failure';
      _inMemoryFallbackState['fallback_timestamp'] = DateTime.now().toIso8601String();

      developer.log(
        'Test mode persistence failed, using in-memory fallback',
        name: 'TestModeErrorHandler',
      );

      return TestModeRecoveryResult(
        success: true,
        recoveryStrategy: TestModeRecoveryStrategy.inMemoryFallback,
        message: 'Test mode state preserved in memory. Changes will not persist across app restarts.',
        fallbackData: Map<String, dynamic>.from(_inMemoryFallbackState),
      );
    } catch (e) {
      return TestModeRecoveryResult(
        success: false,
        recoveryStrategy: TestModeRecoveryStrategy.inMemoryFallback,
        message: 'Failed to create in-memory fallback: $e',
        error: e,
      );
    }
  }

  /// Handle level generation failures with fallback level creation
  static Future<TestModeRecoveryResult> _handleLevelGenerationFailure(
    TestModeException error,
    Map<String, dynamic>? context,
  ) async {
    try {
      final levelId = context?['levelId'] as int? ?? 1;
      final difficulty = context?['difficulty'] as int? ?? 1;
      
      // Create a simple fallback level that's guaranteed to work
      final fallbackLevel = _createFallbackLevel(levelId, difficulty);

      developer.log(
        'Level generation failed, created fallback level',
        name: 'TestModeErrorHandler',
      );

      return TestModeRecoveryResult(
        success: true,
        recoveryStrategy: TestModeRecoveryStrategy.fallbackLevel,
        message: 'Generated simplified fallback level due to generation failure.',
        fallbackData: {'level': fallbackLevel},
      );
    } catch (e) {
      return TestModeRecoveryResult(
        success: false,
        recoveryStrategy: TestModeRecoveryStrategy.fallbackLevel,
        message: 'Failed to create fallback level: $e',
        error: e,
      );
    }
  }

  /// Handle progress corruption with data protection
  static Future<TestModeRecoveryResult> _handleProgressCorruption(
    TestModeException error,
    Map<String, dynamic>? context,
  ) async {
    try {
      // Isolate test mode state from actual progress
      _inMemoryFallbackState.clear();
      _inMemoryFallbackState['test_mode_enabled'] = false;
      _inMemoryFallbackState['progress_protection_active'] = true;
      _inMemoryFallbackState['corruption_detected_at'] = DateTime.now().toIso8601String();

      developer.log(
        'Progress corruption detected, isolated test mode state',
        name: 'TestModeErrorHandler',
      );

      return TestModeRecoveryResult(
        success: true,
        recoveryStrategy: TestModeRecoveryStrategy.progressProtection,
        message: 'Test mode disabled to protect game progress. Actual progress preserved.',
        fallbackData: Map<String, dynamic>.from(_inMemoryFallbackState),
      );
    } catch (e) {
      return TestModeRecoveryResult(
        success: false,
        recoveryStrategy: TestModeRecoveryStrategy.progressProtection,
        message: 'Failed to protect progress from corruption: $e',
        error: e,
      );
    }
  }

  /// Create a simple fallback level for testing
  static Level _createFallbackLevel(int levelId, int difficulty) {
    // Create a very simple level that's guaranteed to be solvable
    final containers = <Container>[];
    
    // Create 4 containers with simple configuration
    // Container 1: Red liquid only
    containers.add(Container(
      id: 1,
      capacity: 4,
      liquidLayers: [
        const LiquidLayer(color: LiquidColor.red, volume: 2),
        const LiquidLayer(color: LiquidColor.red, volume: 2),
      ],
    ));

    // Container 2: Blue liquid only  
    containers.add(Container(
      id: 2,
      capacity: 4,
      liquidLayers: [
        const LiquidLayer(color: LiquidColor.blue, volume: 2),
        const LiquidLayer(color: LiquidColor.blue, volume: 2),
      ],
    ));

    // Container 3: Mixed red and blue (needs sorting)
    containers.add(Container(
      id: 3,
      capacity: 4,
      liquidLayers: [
        const LiquidLayer(color: LiquidColor.red, volume: 2),
        const LiquidLayer(color: LiquidColor.blue, volume: 2),
      ],
    ));

    // Container 4: Empty (for sorting)
    containers.add(Container(
      id: 4,
      capacity: 4,
      liquidLayers: [],
    ));

    return Level(
      id: levelId,
      difficulty: difficulty.clamp(1, 10),
      containerCount: 4,
      colorCount: 2,
      initialContainers: containers,
      isValidated: true,
      hint: 'Fallback test level (difficulty: $difficulty)',
      tags: ['fallback', 'test'],
    );
  }

  /// Get current in-memory fallback state
  static Map<String, dynamic> getInMemoryState() {
    return Map<String, dynamic>.from(_inMemoryFallbackState);
  }

  /// Check if fallback mode is active
  static bool get isFallbackActive => _inMemoryFallbackState['fallback_active'] == true;

  /// Get fallback test mode state
  static bool get fallbackTestModeEnabled => 
      _inMemoryFallbackState['test_mode_enabled'] == true;

  /// Set fallback test mode state
  static void setFallbackTestMode(bool enabled) {
    _inMemoryFallbackState['test_mode_enabled'] = enabled;
    _inMemoryFallbackState['last_updated'] = DateTime.now().toIso8601String();
  }

  /// Clear fallback state
  static void clearFallbackState() {
    _inMemoryFallbackState.clear();
  }

  /// Get error statistics for monitoring
  static TestModeErrorStats getErrorStats() {
    // This would typically be implemented with persistent storage
    // For now, return basic stats
    return const TestModeErrorStats(
      totalErrors: 0,
      persistenceFailures: 0,
      levelGenerationFailures: 0,
      progressCorruptions: 0,
      lastErrorTime: null,
    );
  }

  /// Dispose of resources
  static void dispose() {
    _errorController.close();
    _inMemoryFallbackState.clear();
  }
}

/// Represents a test mode error with context
class TestModeError {
  final TestModeException exception;
  final DateTime timestamp;
  final Map<String, dynamic> context;

  const TestModeError({
    required this.exception,
    required this.timestamp,
    required this.context,
  });

  @override
  String toString() {
    return 'TestModeError(${exception.type}: ${exception.message} at $timestamp)';
  }
}

/// Result of test mode error recovery
class TestModeRecoveryResult {
  final bool success;
  final TestModeRecoveryStrategy recoveryStrategy;
  final String message;
  final Map<String, dynamic>? fallbackData;
  final dynamic error;

  const TestModeRecoveryResult({
    required this.success,
    required this.recoveryStrategy,
    required this.message,
    this.fallbackData,
    this.error,
  });

  @override
  String toString() {
    return 'TestModeRecoveryResult(success: $success, strategy: $recoveryStrategy, message: $message)';
  }
}

/// Recovery strategies for test mode errors
enum TestModeRecoveryStrategy {
  inMemoryFallback,
  fallbackLevel,
  progressProtection,
  none,
}

/// Statistics about test mode errors
class TestModeErrorStats {
  final int totalErrors;
  final int persistenceFailures;
  final int levelGenerationFailures;
  final int progressCorruptions;
  final DateTime? lastErrorTime;

  const TestModeErrorStats({
    required this.totalErrors,
    required this.persistenceFailures,
    required this.levelGenerationFailures,
    required this.progressCorruptions,
    this.lastErrorTime,
  });
}