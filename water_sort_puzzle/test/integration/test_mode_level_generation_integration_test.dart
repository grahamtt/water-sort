import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_sort_puzzle/services/level_generator.dart';
import 'package:water_sort_puzzle/services/test_mode_manager.dart';

void main() {
  group('Test Mode Level Generation Integration', () {
    late WaterSortLevelGenerator generator;
    late TestModeManager testModeManager;
    late SharedPreferences mockPrefs;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      // Initialize components
      const config = LevelGenerationConfig(seed: 42);
      generator = WaterSortLevelGenerator(config: config);

      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();
      testModeManager = TestModeManager(mockPrefs);
    });

    tearDown(() {
      testModeManager.dispose();
    });

    test('should generate levels with test mode enabled for extreme parameters', () async {
      await testModeManager.setTestMode(true);

      // Generate a level with extreme parameters that would normally fail
      final level = testModeManager.generateLevelForTesting(
        999,
        15, // Very high difficulty
        8,  // Many containers
        6,  // Many colors
        generator,
      );

      expect(level.id, equals(999));
      expect(level.difficulty, equals(15));
      expect(level.colorCount, equals(6));
      expect(generator.validateLevel(level), isTrue);
      expect(level.isStructurallyValid, isTrue);
      expect(generator.hasCompletedContainers(level), isFalse);
    });

    test('should auto-generate levels across full difficulty range', () async {
      await testModeManager.setTestMode(true);

      // Test a range of difficulties
      final difficulties = [1, 5, 10, 15, 20];
      
      for (final difficulty in difficulties) {
        final level = testModeManager.generateLevelForTestingAuto(
          difficulty,
          difficulty,
          generator,
        );

        expect(level.id, equals(difficulty));
        expect(level.difficulty, equals(difficulty));
        expect(generator.validateLevel(level), isTrue,
            reason: 'Level with difficulty $difficulty should be valid');
        expect(level.isStructurallyValid, isTrue,
            reason: 'Level with difficulty $difficulty should be structurally valid');
        expect(generator.hasCompletedContainers(level), isFalse,
            reason: 'Level with difficulty $difficulty should not have completed containers');

        // Verify color distribution
        final colorVolumes = <String, int>{};
        for (final container in level.initialContainers) {
          for (final layer in container.liquidLayers) {
            final colorName = layer.color.name;
            colorVolumes[colorName] = (colorVolumes[colorName] ?? 0) + layer.volume;
          }
        }
        expect(colorVolumes.length, equals(level.colorCount),
            reason: 'Level with difficulty $difficulty should have correct number of colors');
      }
    });

    test('should handle test mode toggle during level generation workflow', () async {
      // Start with test mode disabled
      await testModeManager.setTestMode(false);
      expect(testModeManager.isTestModeEnabled, isFalse);

      // Generate a normal level
      final normalLevel = testModeManager.generateLevelForTesting(
        1, 5, 6, 4, generator,
      );
      expect(generator.validateLevel(normalLevel), isTrue);

      // Enable test mode
      await testModeManager.setTestMode(true);
      expect(testModeManager.isTestModeEnabled, isTrue);

      // Generate a test mode level with extreme parameters
      final testLevel = testModeManager.generateLevelForTesting(
        2, 20, 10, 8, generator,
      );
      expect(generator.validateLevel(testLevel), isTrue);
      expect(testLevel.difficulty, equals(20));
      expect(testLevel.colorCount, equals(8));

      // Disable test mode again
      await testModeManager.setTestMode(false);
      expect(testModeManager.isTestModeEnabled, isFalse);

      // Generate another normal level
      final normalLevel2 = testModeManager.generateLevelForTesting(
        3, 5, 6, 4, generator,
      );
      expect(generator.validateLevel(normalLevel2), isTrue);
    });

    test('should maintain level quality standards in test mode', () async {
      await testModeManager.setTestMode(true);

      // Generate multiple levels and verify they all meet quality standards
      final levels = <int, dynamic>{};
      
      for (int difficulty = 1; difficulty <= 10; difficulty++) {
        final level = testModeManager.generateLevelForTestingAuto(
          difficulty,
          difficulty,
          generator,
        );

        levels[difficulty] = {
          'level': level,
          'valid': generator.validateLevel(level),
          'structural': level.isStructurallyValid,
          'completed': generator.hasCompletedContainers(level),
        };

        // All levels should meet quality standards
        expect(levels[difficulty]['valid'], isTrue,
            reason: 'Level $difficulty should be valid');
        expect(levels[difficulty]['structural'], isTrue,
            reason: 'Level $difficulty should be structurally valid');
        expect(levels[difficulty]['completed'], isFalse,
            reason: 'Level $difficulty should not have completed containers');
      }

      // Verify difficulty progression
      for (int i = 1; i < 10; i++) {
        final currentLevel = levels[i]['level'];
        final nextLevel = levels[i + 1]['level'];
        
        // Higher difficulty should generally have same or more complexity
        expect(currentLevel.colorCount, lessThanOrEqualTo(nextLevel.colorCount),
            reason: 'Difficulty progression should increase color count');
      }
    });

    test('should handle error scenarios gracefully', () async {
      await testModeManager.setTestMode(true);

      // Test impossible configuration
      expect(
        () => testModeManager.generateLevelForTesting(
          1, 10, 2, 5, generator, // 2 containers, 5 colors - impossible
        ),
        throwsA(isA<TestModeException>()
            .having((e) => e.type, 'type', TestModeErrorType.levelGenerationFailure)),
      );

      // Test mode should still be enabled after error
      expect(testModeManager.isTestModeEnabled, isTrue);

      // Should be able to generate valid level after error
      final validLevel = testModeManager.generateLevelForTestingAuto(1, 5, generator);
      expect(generator.validateLevel(validLevel), isTrue);
    });

    test('should work with different generator configurations', () async {
      await testModeManager.setTestMode(true);

      // Test with different generator configurations
      final configs = [
        const LevelGenerationConfig(seed: 123, containerCapacity: 4),
        const LevelGenerationConfig(seed: 456, containerCapacity: 4, minEmptySlots: 2),
        const LevelGenerationConfig(seed: 789, containerCapacity: 4, maxGenerationAttempts: 100),
      ];

      for (int i = 0; i < configs.length; i++) {
        final testGenerator = WaterSortLevelGenerator(config: configs[i]);
        
        final level = testModeManager.generateLevelForTesting(
          i + 1, 5, 6, 4, testGenerator,
        );

        expect(testGenerator.validateLevel(level), isTrue,
            reason: 'Level generated with config $i should be valid');
        expect(level.isStructurallyValid, isTrue,
            reason: 'Level generated with config $i should be structurally valid');
      }
    });

    test('should preserve test mode state across multiple operations', () async {
      // Test state persistence through multiple operations
      await testModeManager.setTestMode(true);
      
      // Perform multiple operations
      for (int i = 1; i <= 5; i++) {
        expect(testModeManager.isTestModeEnabled, isTrue,
            reason: 'Test mode should remain enabled during operation $i');
        
        final level = testModeManager.generateLevelForTestingAuto(i, i * 2, generator);
        expect(generator.validateLevel(level), isTrue,
            reason: 'Level $i should be valid');
        
        expect(testModeManager.isTestModeEnabled, isTrue,
            reason: 'Test mode should remain enabled after operation $i');
      }

      // Disable test mode
      await testModeManager.setTestMode(false);
      
      // Perform operations with test mode disabled
      for (int i = 1; i <= 3; i++) {
        expect(testModeManager.isTestModeEnabled, isFalse,
            reason: 'Test mode should remain disabled during operation $i');
        
        final level = testModeManager.generateLevelForTesting(i, 3, 5, 3, generator);
        expect(generator.validateLevel(level), isTrue,
            reason: 'Normal level $i should be valid');
        
        expect(testModeManager.isTestModeEnabled, isFalse,
            reason: 'Test mode should remain disabled after operation $i');
      }
    });
  });
}