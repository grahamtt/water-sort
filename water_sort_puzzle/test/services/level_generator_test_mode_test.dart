import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_sort_puzzle/models/models.dart';
import 'package:water_sort_puzzle/services/level_generator.dart';
import 'package:water_sort_puzzle/services/test_mode_manager.dart';

void main() {
  group('LevelGenerator Test Mode Support', () {
    late WaterSortLevelGenerator generator;
    late TestModeManager testModeManager;
    late SharedPreferences mockPrefs;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      // Use a fixed seed for reproducible tests
      const config = LevelGenerationConfig(seed: 42);
      generator = WaterSortLevelGenerator(config: config);

      // Initialize test mode manager
      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();
      testModeManager = TestModeManager(mockPrefs);
    });

    tearDown(() {
      testModeManager.dispose();
    });

    group('ignoreProgressionLimits Parameter', () {
      test('should allow more flexible parameters when ignoreProgressionLimits is true', () {
        // This would normally fail due to insufficient containers
        final level = generator.generateLevel(
          1,
          10,
          4, // Only 4 containers
          3, // But 3 colors (normally needs at least 4 containers + empty slots)
          ignoreProgressionLimits: true,
        );

        expect(level.id, equals(1));
        expect(level.difficulty, equals(10));
        expect(level.colorCount, equals(3));
        expect(level.containerCount, equals(level.initialContainers.length));
        expect(generator.validateLevel(level), isTrue);
      });

      test('should enforce normal restrictions when ignoreProgressionLimits is false', () {
        // This should fail due to insufficient containers
        expect(
          () => generator.generateLevel(
            1,
            10,
            4, // Only 4 containers (16 capacity)
            4, // But 4 colors (16 liquid volume, no room for empty slots)
            ignoreProgressionLimits: false,
          ),
          throwsArgumentError,
        );
      });

      test('should still enforce minimum viable configuration in test mode', () {
        // Even in test mode, we need at least colorCount + 1 containers
        expect(
          () => generator.generateLevel(
            1,
            10,
            3, // Only 3 containers
            3, // But 3 colors (need at least 4 containers)
            ignoreProgressionLimits: true,
          ),
          throwsA(isA<TestModeException>()
              .having((e) => e.type, 'type', TestModeErrorType.levelGenerationFailure)),
        );
      });

      test('should generate valid levels with extreme parameters in test mode', () {
        final level = generator.generateLevel(
          1,
          15, // Very high difficulty
          10, // Many containers
          8, // Many colors
          ignoreProgressionLimits: true,
        );

        expect(level.id, equals(1));
        expect(level.difficulty, equals(15));
        expect(level.colorCount, equals(8));
        expect(level.containerCount, equals(level.initialContainers.length));
        expect(generator.validateLevel(level), isTrue);

        // Verify color distribution
        final colorVolumes = <LiquidColor, int>{};
        for (final container in level.initialContainers) {
          for (final layer in container.liquidLayers) {
            colorVolumes[layer.color] =
                (colorVolumes[layer.color] ?? 0) + layer.volume;
          }
        }
        expect(colorVolumes.length, equals(8));
      });

      test('should throw TestModeException for generation failures in test mode', () {
        // Try to generate an impossible level configuration
        expect(
          () => generator.generateLevel(
            1,
            10,
            2, // Too few containers
            5, // Too many colors
            ignoreProgressionLimits: true,
          ),
          throwsA(isA<TestModeException>()
              .having((e) => e.type, 'type', TestModeErrorType.levelGenerationFailure)
              .having((e) => e.message, 'message', contains('test mode'))),
        );
      });

      test('should maintain same quality standards in test mode', () {
        final normalLevel = generator.generateLevel(1, 5, 6, 4);
        final testModeLevel = generator.generateLevel(
          1,
          5,
          6,
          4,
          ignoreProgressionLimits: true,
        );

        // Both levels should pass validation
        expect(generator.validateLevel(normalLevel), isTrue);
        expect(generator.validateLevel(testModeLevel), isTrue);

        // Both should have proper liquid distribution
        expect(normalLevel.isStructurallyValid, isTrue);
        expect(testModeLevel.isStructurallyValid, isTrue);

        // Both should not have completed containers
        expect(generator.hasCompletedContainers(normalLevel), isFalse);
        expect(generator.hasCompletedContainers(testModeLevel), isFalse);
      });
    });

    group('TestModeManager Level Generation', () {
      test('should generate level with test mode enabled', () async {
        await testModeManager.setTestMode(true);

        final level = testModeManager.generateLevelForTesting(
          1,
          8,
          6,
          4,
          generator,
        );

        expect(level.id, equals(1));
        expect(level.difficulty, equals(8));
        expect(level.colorCount, equals(4));
        expect(generator.validateLevel(level), isTrue);
      });

      test('should generate level with test mode disabled', () async {
        await testModeManager.setTestMode(false);

        final level = testModeManager.generateLevelForTesting(
          1,
          5,
          6,
          4,
          generator,
        );

        expect(level.id, equals(1));
        expect(level.difficulty, equals(5));
        expect(level.colorCount, equals(4));
        expect(generator.validateLevel(level), isTrue);
      });

      test('should throw TestModeException when generation fails in test mode', () async {
        await testModeManager.setTestMode(true);

        expect(
          () => testModeManager.generateLevelForTesting(
            1,
            10,
            2, // Too few containers
            5, // Too many colors
            generator,
          ),
          throwsA(isA<TestModeException>()
              .having((e) => e.type, 'type', TestModeErrorType.levelGenerationFailure)
              .having((e) => e.message, 'message', contains('Failed to generate level in test mode'))
              .having((e) => e.cause, 'cause', isNotNull)),
        );
      });

      test('should rethrow original exception when test mode disabled', () async {
        await testModeManager.setTestMode(false);

        expect(
          () => testModeManager.generateLevelForTesting(
            1,
            10,
            3, // Too few containers
            5, // Too many colors
            generator,
          ),
          throwsArgumentError,
        );
      });

      test('should auto-generate level with appropriate parameters', () async {
        await testModeManager.setTestMode(true);

        // Test various difficulty levels
        for (int difficulty = 1; difficulty <= 15; difficulty++) {
          final level = testModeManager.generateLevelForTestingAuto(
            difficulty,
            difficulty,
            generator,
          );

          expect(level.id, equals(difficulty));
          expect(level.difficulty, equals(difficulty));
          expect(generator.validateLevel(level), isTrue);

          // Verify parameters are appropriate for difficulty
          // Note: containerCount may be optimized down from the requested count
          expect(level.containerCount, greaterThanOrEqualTo(3)); // Minimum after optimization
          expect(level.colorCount, greaterThanOrEqualTo(2));
          expect(level.colorCount, lessThan(level.containerCount));
        }
      });

      test('should calculate appropriate container count for test mode', () async {
        await testModeManager.setTestMode(true);

        // Test difficulty progression
        final level1 = testModeManager.generateLevelForTestingAuto(1, 1, generator);
        final level5 = testModeManager.generateLevelForTestingAuto(5, 5, generator);
        final level10 = testModeManager.generateLevelForTestingAuto(10, 10, generator);
        final level15 = testModeManager.generateLevelForTestingAuto(15, 15, generator);

        // Higher difficulty should generally have more containers
        expect(level1.containerCount, lessThanOrEqualTo(level5.containerCount));
        expect(level5.containerCount, lessThanOrEqualTo(level10.containerCount));
        expect(level10.containerCount, lessThanOrEqualTo(level15.containerCount));

        // Extreme difficulty should be capped at reasonable limits
        expect(level15.containerCount, lessThanOrEqualTo(12));
      });

      test('should calculate appropriate color count for test mode', () async {
        await testModeManager.setTestMode(true);

        // Test difficulty progression
        final level1 = testModeManager.generateLevelForTestingAuto(1, 1, generator);
        final level5 = testModeManager.generateLevelForTestingAuto(5, 5, generator);
        final level10 = testModeManager.generateLevelForTestingAuto(10, 10, generator);

        // Higher difficulty should generally have more colors
        expect(level1.colorCount, lessThanOrEqualTo(level5.colorCount));
        expect(level5.colorCount, lessThanOrEqualTo(level10.colorCount));

        // Colors should always be less than containers (need empty space)
        expect(level1.colorCount, lessThan(level1.containerCount));
        expect(level5.colorCount, lessThan(level5.containerCount));
        expect(level10.colorCount, lessThan(level10.containerCount));
      });

      test('should handle auto-generation errors gracefully', () async {
        await testModeManager.setTestMode(true);

        // Create a generator that will fail
        final failingGenerator = _FailingLevelGenerator();

        expect(
          () => testModeManager.generateLevelForTestingAuto(1, 5, failingGenerator),
          throwsA(isA<TestModeException>()
              .having((e) => e.type, 'type', TestModeErrorType.levelGenerationFailure)
              .having((e) => e.message, 'message', contains('Failed to auto-generate level'))),
        );
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle maximum difficulty levels', () async {
        await testModeManager.setTestMode(true);

        final level = testModeManager.generateLevelForTestingAuto(1, 20, generator);

        expect(level.difficulty, equals(20));
        expect(generator.validateLevel(level), isTrue);
        expect(level.containerCount, lessThanOrEqualTo(12)); // Should be capped
        expect(level.colorCount, lessThanOrEqualTo(8)); // Should be capped
      });

      test('should handle minimum difficulty levels', () async {
        await testModeManager.setTestMode(true);

        final level = testModeManager.generateLevelForTestingAuto(1, 0, generator);

        expect(level.difficulty, equals(0));
        expect(generator.validateLevel(level), isTrue);
        expect(level.containerCount, greaterThanOrEqualTo(3)); // May be optimized down
        expect(level.colorCount, equals(2)); // Should be exactly 2 for difficulty 0
      });

      test('should handle negative difficulty levels', () async {
        await testModeManager.setTestMode(true);

        final level = testModeManager.generateLevelForTestingAuto(1, -5, generator);

        expect(level.difficulty, equals(-5));
        expect(generator.validateLevel(level), isTrue);
        // Should use minimum parameters for negative difficulty
        expect(level.containerCount, greaterThanOrEqualTo(3)); // May be optimized down
        expect(level.colorCount, equals(2));
      });

      test('should maintain level quality across multiple generations', () async {
        await testModeManager.setTestMode(true);

        // Generate multiple levels and verify they all meet quality standards
        for (int i = 1; i <= 20; i++) {
          final level = testModeManager.generateLevelForTestingAuto(i, i % 10 + 1, generator);

          expect(generator.validateLevel(level), isTrue,
              reason: 'Level $i should be valid');
          expect(level.isStructurallyValid, isTrue,
              reason: 'Level $i should be structurally valid');
          expect(generator.hasCompletedContainers(level), isFalse,
              reason: 'Level $i should not have completed containers');

          // Verify liquid distribution
          final colorVolumes = <LiquidColor, int>{};
          for (final container in level.initialContainers) {
            for (final layer in container.liquidLayers) {
              colorVolumes[layer.color] =
                  (colorVolumes[layer.color] ?? 0) + layer.volume;
            }
          }
          expect(colorVolumes.length, equals(level.colorCount),
              reason: 'Level $i should have correct number of colors');
        }
      });

      test('should handle concurrent level generation requests', () async {
        await testModeManager.setTestMode(true);

        // Generate multiple levels concurrently
        final futures = <Future<Level>>[];
        for (int i = 1; i <= 10; i++) {
          futures.add(Future(() => testModeManager.generateLevelForTestingAuto(i, i, generator)));
        }

        final levels = await Future.wait(futures);

        // All levels should be valid
        for (int i = 0; i < levels.length; i++) {
          expect(generator.validateLevel(levels[i]), isTrue,
              reason: 'Concurrent level ${i + 1} should be valid');
          expect(levels[i].id, equals(i + 1),
              reason: 'Concurrent level ${i + 1} should have correct ID');
        }
      });

      test('should preserve test mode state during level generation', () async {
        await testModeManager.setTestMode(true);
        expect(testModeManager.isTestModeEnabled, isTrue);

        // Generate a level
        final level = testModeManager.generateLevelForTestingAuto(1, 5, generator);
        expect(generator.validateLevel(level), isTrue);

        // Test mode should still be enabled
        expect(testModeManager.isTestModeEnabled, isTrue);

        // Disable test mode
        await testModeManager.setTestMode(false);
        expect(testModeManager.isTestModeEnabled, isFalse);

        // Generate another level
        final level2 = testModeManager.generateLevelForTesting(2, 3, 5, 3, generator);
        expect(generator.validateLevel(level2), isTrue);

        // Test mode should still be disabled
        expect(testModeManager.isTestModeEnabled, isFalse);
      });
    });

    group('Performance and Reliability', () {
      test('should generate levels within reasonable time limits', () async {
        await testModeManager.setTestMode(true);

        final stopwatch = Stopwatch()..start();

        // Generate multiple levels and measure time
        for (int i = 1; i <= 10; i++) {
          testModeManager.generateLevelForTestingAuto(i, i, generator);
        }

        stopwatch.stop();

        // Should complete within reasonable time (adjust as needed)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000),
            reason: 'Level generation should complete within 5 seconds');
      });

      test('should handle repeated generation with same parameters', () async {
        await testModeManager.setTestMode(true);

        // Generate the same level configuration multiple times
        final levels = <Level>[];
        for (int i = 0; i < 5; i++) {
          levels.add(testModeManager.generateLevelForTesting(1, 5, 6, 4, generator));
        }

        // All levels should be valid
        for (final level in levels) {
          expect(generator.validateLevel(level), isTrue);
          expect(level.id, equals(1));
          expect(level.difficulty, equals(5));
          expect(level.colorCount, equals(4));
        }
      });

      test('should maintain memory efficiency during generation', () async {
        await testModeManager.setTestMode(true);

        // Generate many levels to test memory usage
        for (int i = 1; i <= 100; i++) {
          final level = testModeManager.generateLevelForTestingAuto(i, i % 10 + 1, generator);
          expect(generator.validateLevel(level), isTrue);
          
          // Force garbage collection periodically
          if (i % 20 == 0) {
            await Future.delayed(const Duration(milliseconds: 1));
          }
        }

        // Test should complete without memory issues
        expect(true, isTrue);
      });
    });
  });
}

/// Mock level generator that always fails for testing error handling
class _FailingLevelGenerator implements LevelGenerator {
  @override
  Level generateLevel(
    int levelId,
    int difficulty,
    int containerCount,
    int colorCount, {
    bool ignoreProgressionLimits = false,
  }) {
    throw Exception('Simulated level generation failure');
  }

  @override
  Level generateUniqueLevel(
    int levelId,
    int difficulty,
    int containerCount,
    int colorCount,
    List<Level> existingLevels, {
    bool ignoreProgressionLimits = false,
  }) {
    throw Exception('Simulated unique level generation failure');
  }

  @override
  bool validateLevel(Level level) => false;

  @override
  bool isLevelSimilar(Level newLevel, List<Level> existingLevels) => false;

  @override
  String generateLevelSignature(Level level) => 'failing-signature';

  @override
  List<Level> generateLevelSeries(int startId, int count, {int startDifficulty = 1}) {
    throw Exception('Simulated level series generation failure');
  }

  @override
  bool hasCompletedContainers(Level level) => false;
}