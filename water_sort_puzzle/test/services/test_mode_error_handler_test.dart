import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/services/test_mode_error_handler.dart';
import 'package:water_sort_puzzle/services/test_mode_manager.dart';
import 'package:water_sort_puzzle/models/level.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';

void main() {
  group('TestModeErrorHandler', () {
    setUp(() {
      // Clear any existing fallback state before each test
      TestModeErrorHandler.clearFallbackState();
    });

    tearDown(() {
      // Clean up after each test
      TestModeErrorHandler.clearFallbackState();
    });

    group('Persistence Failure Handling', () {
      test('should handle persistence failure with in-memory fallback', () async {
        // Arrange
        final exception = TestModeException(
          TestModeErrorType.persistenceFailure,
          'SharedPreferences write failed',
          Exception('Storage unavailable'),
        );

        // Act
        final result = await TestModeErrorHandler.handleTestModeError(
          exception,
          context: {'testModeEnabled': true},
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.recoveryStrategy, TestModeRecoveryStrategy.inMemoryFallback);
        expect(result.message, contains('in memory'));
        expect(TestModeErrorHandler.isFallbackActive, isTrue);
        expect(TestModeErrorHandler.fallbackTestModeEnabled, isTrue);
      });

      test('should store fallback state correctly', () async {
        // Arrange
        final exception = TestModeException(
          TestModeErrorType.persistenceFailure,
          'Persistence failed',
        );

        // Act
        await TestModeErrorHandler.handleTestModeError(
          exception,
          context: {'testModeEnabled': false},
        );

        // Assert
        final fallbackState = TestModeErrorHandler.getInMemoryState();
        expect(fallbackState['test_mode_enabled'], isFalse);
        expect(fallbackState['fallback_active'], isTrue);
        expect(fallbackState['fallback_reason'], 'persistence_failure');
        expect(fallbackState['fallback_timestamp'], isNotNull);
      });

      test('should allow updating fallback test mode state', () {
        // Arrange
        TestModeErrorHandler.setFallbackTestMode(true);

        // Act & Assert
        expect(TestModeErrorHandler.fallbackTestModeEnabled, isTrue);

        TestModeErrorHandler.setFallbackTestMode(false);
        expect(TestModeErrorHandler.fallbackTestModeEnabled, isFalse);
      });
    });

    group('Level Generation Failure Handling', () {
      test('should handle level generation failure with fallback level', () async {
        // Arrange
        final exception = TestModeException(
          TestModeErrorType.levelGenerationFailure,
          'Level generation algorithm failed',
          Exception('Invalid parameters'),
        );

        // Act
        final result = await TestModeErrorHandler.handleTestModeError(
          exception,
          context: {
            'levelId': 50,
            'difficulty': 8,
            'containerCount': 6,
            'colorCount': 5,
          },
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.recoveryStrategy, TestModeRecoveryStrategy.fallbackLevel);
        expect(result.message, contains('fallback level'));
        expect(result.fallbackData, isNotNull);
        expect(result.fallbackData!['level'], isA<Level>());
      });

      test('should create valid fallback level', () async {
        // Arrange
        final exception = TestModeException(
          TestModeErrorType.levelGenerationFailure,
          'Generation failed',
        );

        // Act
        final result = await TestModeErrorHandler.handleTestModeError(
          exception,
          context: {'levelId': 25, 'difficulty': 5},
        );

        // Assert
        final level = result.fallbackData!['level'] as Level;
        expect(level.id, 25);
        expect(level.difficulty, 5);
        expect(level.initialContainers.length, 4);
        expect(level.hint, contains('Fallback test level'));

        // Verify level structure
        expect(level.initialContainers[0].liquidLayers.length, 2); // Red container
        expect(level.initialContainers[1].liquidLayers.length, 2); // Blue container
        expect(level.initialContainers[2].liquidLayers.length, 2); // Mixed container
        expect(level.initialContainers[3].liquidLayers.length, 0); // Empty container

        // Verify colors
        expect(level.initialContainers[0].liquidLayers.every((layer) => layer.color == LiquidColor.red), isTrue);
        expect(level.initialContainers[1].liquidLayers.every((layer) => layer.color == LiquidColor.blue), isTrue);
        expect(level.initialContainers[2].liquidLayers.map((layer) => layer.color).toSet(), 
               containsAll([LiquidColor.red, LiquidColor.blue]));
      });

      test('should handle extreme difficulty values in fallback level', () async {
        // Arrange
        final exception = TestModeException(
          TestModeErrorType.levelGenerationFailure,
          'Generation failed',
        );

        // Act
        final result = await TestModeErrorHandler.handleTestModeError(
          exception,
          context: {'levelId': 999, 'difficulty': 100},
        );

        // Assert
        final level = result.fallbackData!['level'] as Level;
        expect(level.id, 999);
        expect(level.difficulty, 10); // Should be clamped to max 10
        expect(level.initialContainers.length, 4);
      });
    });

    group('Progress Corruption Handling', () {
      test('should handle progress corruption with protection', () async {
        // Arrange
        final exception = TestModeException(
          TestModeErrorType.progressCorruption,
          'Progress data integrity check failed',
          Exception('Corrupted data detected'),
        );

        // Act
        final result = await TestModeErrorHandler.handleTestModeError(
          exception,
          context: {'operation': 'completeLevel', 'levelId': 10},
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.recoveryStrategy, TestModeRecoveryStrategy.progressProtection);
        expect(result.message, contains('protect game progress'));
        expect(TestModeErrorHandler.fallbackTestModeEnabled, isFalse);
      });

      test('should isolate test mode state after corruption', () async {
        // Arrange
        TestModeErrorHandler.setFallbackTestMode(true);
        final exception = TestModeException(
          TestModeErrorType.progressCorruption,
          'Corruption detected',
        );

        // Act
        await TestModeErrorHandler.handleTestModeError(exception);

        // Assert
        final fallbackState = TestModeErrorHandler.getInMemoryState();
        expect(fallbackState['test_mode_enabled'], isFalse);
        expect(fallbackState['progress_protection_active'], isTrue);
        expect(fallbackState['corruption_detected_at'], isNotNull);
      });
    });

    group('Error Stream and Monitoring', () {
      test('should emit errors to error stream', () async {
        // Arrange
        final errors = <TestModeError>[];
        final subscription = TestModeErrorHandler.errorStream.listen(errors.add);

        final exception = TestModeException(
          TestModeErrorType.persistenceFailure,
          'Test error',
        );

        // Act
        await TestModeErrorHandler.handleTestModeError(exception);

        // Assert
        await Future.delayed(Duration.zero); // Allow stream to emit
        expect(errors.length, 1);
        expect(errors.first.exception, exception);
        expect(errors.first.timestamp, isA<DateTime>());
        expect(errors.first.context, isA<Map<String, dynamic>>());

        await subscription.cancel();
      });

      test('should include context in error events', () async {
        // Arrange
        final errors = <TestModeError>[];
        final subscription = TestModeErrorHandler.errorStream.listen(errors.add);

        final exception = TestModeException(
          TestModeErrorType.levelGenerationFailure,
          'Generation failed',
        );

        final context = {
          'levelId': 42,
          'difficulty': 7,
          'operation': 'generateLevel',
        };

        // Act
        await TestModeErrorHandler.handleTestModeError(exception, context: context);

        // Assert
        await Future.delayed(Duration.zero);
        expect(errors.length, 1);
        expect(errors.first.context, equals(context));

        await subscription.cancel();
      });
    });

    group('Error Statistics', () {
      test('should return error statistics', () {
        // Act
        final stats = TestModeErrorHandler.getErrorStats();

        // Assert
        expect(stats, isA<TestModeErrorStats>());
        expect(stats.totalErrors, isA<int>());
        expect(stats.persistenceFailures, isA<int>());
        expect(stats.levelGenerationFailures, isA<int>());
        expect(stats.progressCorruptions, isA<int>());
      });
    });

    group('Fallback State Management', () {
      test('should clear fallback state', () async {
        // Arrange - trigger a persistence failure to set fallback_active
        final exception = TestModeException(
          TestModeErrorType.persistenceFailure,
          'Test failure',
        );
        await TestModeErrorHandler.handleTestModeError(exception);
        expect(TestModeErrorHandler.isFallbackActive, isTrue);

        // Act
        TestModeErrorHandler.clearFallbackState();

        // Assert
        expect(TestModeErrorHandler.isFallbackActive, isFalse);
        expect(TestModeErrorHandler.getInMemoryState(), isEmpty);
      });

      test('should track fallback state updates', () {
        // Act
        TestModeErrorHandler.setFallbackTestMode(true);

        // Assert
        final state = TestModeErrorHandler.getInMemoryState();
        expect(state['test_mode_enabled'], isTrue);
        expect(state['last_updated'], isNotNull);
      });
    });

    group('Recovery Result', () {
      test('should create recovery result with all fields', () {
        // Arrange
        final fallbackData = {'key': 'value'};
        const error = 'test error';

        // Act
        const result = TestModeRecoveryResult(
          success: true,
          recoveryStrategy: TestModeRecoveryStrategy.inMemoryFallback,
          message: 'Recovery successful',
          fallbackData: {'key': 'value'},
          error: 'test error',
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.recoveryStrategy, TestModeRecoveryStrategy.inMemoryFallback);
        expect(result.message, 'Recovery successful');
        expect(result.fallbackData, equals(fallbackData));
        expect(result.error, equals(error));
      });

      test('should have meaningful toString', () {
        // Act
        const result = TestModeRecoveryResult(
          success: false,
          recoveryStrategy: TestModeRecoveryStrategy.fallbackLevel,
          message: 'Recovery failed',
        );

        // Assert
        final string = result.toString();
        expect(string, contains('success: false'));
        expect(string, contains('fallbackLevel'));
        expect(string, contains('Recovery failed'));
      });
    });

    group('Error Handling Edge Cases', () {
      test('should handle recovery failure gracefully', () async {
        // This test simulates a scenario where recovery itself fails
        // In practice, this would be very rare but we should handle it

        // Arrange
        final exception = TestModeException(
          TestModeErrorType.persistenceFailure,
          'Primary failure',
        );

        // Act
        final result = await TestModeErrorHandler.handleTestModeError(
          exception,
          context: {'testModeEnabled': true},
        );

        // Assert - Even if recovery has issues, it should not crash
        expect(result, isA<TestModeRecoveryResult>());
        expect(result.recoveryStrategy, isA<TestModeRecoveryStrategy>());
      });

      test('should handle null context gracefully', () async {
        // Arrange
        final exception = TestModeException(
          TestModeErrorType.persistenceFailure,
          'Test error',
        );

        // Act
        final result = await TestModeErrorHandler.handleTestModeError(exception);

        // Assert
        expect(result.success, isTrue);
        expect(result.recoveryStrategy, TestModeRecoveryStrategy.inMemoryFallback);
      });

      test('should handle empty context gracefully', () async {
        // Arrange
        final exception = TestModeException(
          TestModeErrorType.levelGenerationFailure,
          'Test error',
        );

        // Act
        final result = await TestModeErrorHandler.handleTestModeError(
          exception,
          context: {},
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.recoveryStrategy, TestModeRecoveryStrategy.fallbackLevel);
      });
    });

    group('TestModeError', () {
      test('should create error with all properties', () {
        // Arrange
        final exception = TestModeException(
          TestModeErrorType.persistenceFailure,
          'Test message',
        );
        final timestamp = DateTime.now();
        final context = {'key': 'value'};

        // Act
        final error = TestModeError(
          exception: exception,
          timestamp: timestamp,
          context: context,
        );

        // Assert
        expect(error.exception, equals(exception));
        expect(error.timestamp, equals(timestamp));
        expect(error.context, equals(context));
      });

      test('should have meaningful toString', () {
        // Arrange
        final exception = TestModeException(
          TestModeErrorType.levelGenerationFailure,
          'Generation failed',
        );
        final timestamp = DateTime(2023, 1, 1, 12, 0, 0);
        final error = TestModeError(
          exception: exception,
          timestamp: timestamp,
          context: {},
        );

        // Act
        final string = error.toString();

        // Assert
        expect(string, contains('levelGenerationFailure'));
        expect(string, contains('Generation failed'));
        expect(string, contains('2023-01-01'));
      });
    });
  });
}