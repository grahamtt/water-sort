import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/test_mode_indicator.dart';
import '../models/level.dart';
import 'level_generator.dart';
import 'test_mode_error_handler.dart';

/// Manages test mode state and functionality for developer testing
class TestModeManager {
  static const String _testModeKey = 'test_mode_enabled';
  
  final SharedPreferences _prefs;
  final StreamController<bool> _testModeController = StreamController<bool>.broadcast();

  TestModeManager(this._prefs);

  /// Current test mode state (with fallback support)
  bool get isTestModeEnabled {
    // Check if fallback mode is active
    if (TestModeErrorHandler.isFallbackActive) {
      return TestModeErrorHandler.fallbackTestModeEnabled;
    }
    return _prefs.getBool(_testModeKey) ?? false;
  }

  /// Stream of test mode state changes for reactive UI updates
  Stream<bool> get testModeStream => _testModeController.stream;

  /// Enable or disable test mode (with error handling and fallback)
  Future<void> setTestMode(bool enabled) async {
    try {
      await _prefs.setBool(_testModeKey, enabled);
      _testModeController.add(enabled);
    } catch (e) {
      // Handle persistence failure with error handler
      final exception = TestModeException(
        TestModeErrorType.persistenceFailure,
        'Failed to persist test mode state: $e',
        e,
      );

      final recoveryResult = await TestModeErrorHandler.handleTestModeError(
        exception,
        context: {'testModeEnabled': enabled},
      );

      if (recoveryResult.success) {
        // Use fallback mechanism
        TestModeErrorHandler.setFallbackTestMode(enabled);
        _testModeController.add(enabled);
      } else {
        // Recovery failed, rethrow original exception
        throw exception;
      }
    }
  }

  /// Check if a level should be accessible considering test mode
  bool isLevelAccessible(int levelId, Set<int> normallyUnlockedLevels) {
    if (isTestModeEnabled) {
      return true; // All levels accessible in test mode
    }
    return normallyUnlockedLevels.contains(levelId);
  }

  /// Get visual indicator data for test mode UI display
  TestModeIndicator? getTestModeIndicator() {
    if (!isTestModeEnabled) return null;
    
    return const TestModeIndicator(
      text: 'TEST MODE',
      color: Colors.orange,
      icon: Icons.bug_report,
    );
  }

  /// Generate level with test mode context for unrestricted difficulty access
  Future<Level> generateLevelForTesting(
    int levelId,
    int difficulty,
    int containerCount,
    int colorCount,
    LevelGenerator levelGenerator,
  ) async {
    try {
      // In test mode, bypass normal progression restrictions
      return levelGenerator.generateLevel(
        levelId,
        difficulty,
        containerCount,
        colorCount,
        ignoreProgressionLimits: isTestModeEnabled,
      );
    } catch (e) {
      // Handle generation errors with error handler
      if (isTestModeEnabled) {
        final exception = TestModeException(
          TestModeErrorType.levelGenerationFailure,
          'Failed to generate level in test mode: levelId=$levelId, difficulty=$difficulty, '
          'containerCount=$containerCount, colorCount=$colorCount. Error: $e',
          e,
        );

        final recoveryResult = await TestModeErrorHandler.handleTestModeError(
          exception,
          context: {
            'levelId': levelId,
            'difficulty': difficulty,
            'containerCount': containerCount,
            'colorCount': colorCount,
          },
        );

        if (recoveryResult.success && recoveryResult.fallbackData?['level'] != null) {
          return recoveryResult.fallbackData!['level'] as Level;
        } else {
          throw exception;
        }
      } else {
        rethrow;
      }
    }
  }

  /// Generate level with automatic parameter calculation for test mode
  Future<Level> generateLevelForTestingAuto(
    int levelId,
    int difficulty,
    LevelGenerator levelGenerator,
  ) async {
    try {
      // Calculate appropriate parameters based on difficulty
      final containerCount = _calculateTestModeContainerCount(difficulty);
      final colorCount = _calculateTestModeColorCount(difficulty, containerCount);

      return await generateLevelForTesting(
        levelId,
        difficulty,
        containerCount,
        colorCount,
        levelGenerator,
      );
    } catch (e) {
      throw TestModeException(
        TestModeErrorType.levelGenerationFailure,
        'Failed to auto-generate level in test mode: levelId=$levelId, difficulty=$difficulty. Error: $e',
        e,
      );
    }
  }

  /// Calculate container count for test mode based on difficulty
  int _calculateTestModeContainerCount(int difficulty) {
    // In test mode, allow access to higher difficulty configurations
    // Ensure minimum of 4 containers for basic functionality
    if (difficulty <= 0) return 4;
    if (difficulty <= 2) return 4;
    if (difficulty <= 4) return 5;
    if (difficulty <= 6) return 6;
    if (difficulty <= 8) return 7;
    if (difficulty <= 10) return 8;
    // For extreme test cases, allow even more containers
    return min(12, 8 + (difficulty - 10));
  }

  /// Calculate color count for test mode based on difficulty and container count
  int _calculateTestModeColorCount(int difficulty, int containerCount) {
    // In test mode, allow more aggressive color-to-container ratios
    final maxColors = containerCount - 1; // Always leave room for at least one empty slot

    if (difficulty <= 0) return min(2, maxColors);
    if (difficulty <= 2) return min(2, maxColors);
    if (difficulty <= 4) return min(3, maxColors);
    if (difficulty <= 6) return min(4, maxColors);
    if (difficulty <= 8) return min(5, maxColors);
    if (difficulty <= 10) return min(6, maxColors);
    // For extreme test cases, allow more colors
    return min(maxColors, min(8, 6 + (difficulty - 10)));
  }

  /// Dispose of resources
  void dispose() {
    _testModeController.close();
  }
}

/// Exception thrown when test mode operations fail
class TestModeException implements Exception {
  final TestModeErrorType type;
  final String message;
  final dynamic cause;

  const TestModeException(this.type, this.message, [this.cause]);

  @override
  String toString() {
    return 'TestModeException: $message${cause != null ? ' (caused by: $cause)' : ''}';
  }
}

/// Types of test mode errors
enum TestModeErrorType {
  persistenceFailure,
  levelGenerationFailure,
  progressCorruption,
}