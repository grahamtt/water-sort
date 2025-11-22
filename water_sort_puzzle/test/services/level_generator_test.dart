import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/models.dart';
import 'package:water_sort_puzzle/services/level_generator.dart';

void main() {
  group('LevelGenerationConfig', () {
    test('should have default values', () {
      const config = LevelGenerationConfig();

      expect(config.containerCapacity, equals(4));
      expect(config.minEmptyContainers, equals(1));
      expect(config.maxEmptyContainers, equals(3));
      expect(config.minLayersPerContainer, equals(1));
      expect(config.maxLayersPerContainer, equals(4));
      expect(config.seed, isNull);
    });

    test('should allow custom values', () {
      const config = LevelGenerationConfig(
        containerCapacity: 6,
        minEmptyContainers: 2,
        maxEmptyContainers: 4,
        seed: 12345,
      );

      expect(config.containerCapacity, equals(6));
      expect(config.minEmptyContainers, equals(2));
      expect(config.maxEmptyContainers, equals(4));
      expect(config.seed, equals(12345));
    });
  });

  group('WaterSortLevelGenerator', () {
    late WaterSortLevelGenerator generator;

    setUp(() {
      // Use a fixed seed for reproducible tests
      const config = LevelGenerationConfig(seed: 42);
      generator = WaterSortLevelGenerator(config: config);
    });

    test('should generate valid level with basic parameters', () {
      final level = generator.generateLevel(1, 3, 4, 2);

      expect(level.id, equals(1));
      expect(level.difficulty, equals(3));
      expect(level.containerCount, equals(4));
      expect(level.colorCount, equals(2));
      expect(level.initialContainers.length, equals(4));
    });

    test('should generate level with correct number of empty containers', () {
      final level = generator.generateLevel(1, 1, 5, 2); // Easy level

      // Easy levels should have more empty containers
      final emptyCount = level.emptyContainerCount;
      expect(emptyCount, greaterThanOrEqualTo(1));
      expect(emptyCount, lessThanOrEqualTo(3));
    });

    test('should generate level with appropriate tags', () {
      final tutorialLevel = generator.generateLevel(1, 1, 4, 2);
      final challengeLevel = generator.generateLevel(50, 9, 6, 4);

      expect(tutorialLevel.tags, contains('tutorial'));
      expect(tutorialLevel.tags, contains('easy'));

      expect(challengeLevel.tags, contains('challenge'));
      expect(challengeLevel.tags, contains('hard'));
    });

    test('should throw error for invalid parameters', () {
      // Too few containers for colors + empty containers
      expect(() => generator.generateLevel(1, 3, 3, 3), throwsArgumentError);

      // Too many colors
      expect(() => generator.generateLevel(1, 3, 10, 20), throwsArgumentError);
    });

    test('should generate containers with correct liquid distribution', () {
      final level = generator.generateLevel(1, 3, 5, 3);

      // Count liquid volumes by color
      final colorVolumes = <LiquidColor, int>{};

      for (final container in level.initialContainers) {
        for (final layer in container.liquidLayers) {
          colorVolumes[layer.color] =
              (colorVolumes[layer.color] ?? 0) + layer.volume;
        }
      }

      // Each color should have exactly one container's worth of liquid
      expect(colorVolumes.length, equals(3));
      for (final volume in colorVolumes.values) {
        expect(volume, equals(4)); // Default container capacity
      }
    });

    test('should validate generated levels', () {
      final level = generator.generateLevel(1, 3, 5, 3);

      expect(generator.validateLevel(level), isTrue);
      expect(level.isStructurallyValid, isTrue);
    });

    test('should generate level series with progressive difficulty', () {
      final levels = generator.generateLevelSeries(1, 10);

      expect(levels.length, equals(10));

      // Check that IDs are sequential
      for (int i = 0; i < levels.length; i++) {
        expect(levels[i].id, equals(i + 1));
      }

      // Check that difficulty generally increases
      expect(
        levels.first.difficulty,
        lessThanOrEqualTo(levels.last.difficulty),
      );
    });

    test('should generate different levels with different seeds', () {
      final generator1 = WaterSortLevelGenerator(
        config: const LevelGenerationConfig(seed: 123),
      );
      final generator2 = WaterSortLevelGenerator(
        config: const LevelGenerationConfig(seed: 456),
      );

      final level1 = generator1.generateLevel(1, 3, 4, 2);
      final level2 = generator2.generateLevel(1, 3, 4, 2);

      // Levels should be different (very unlikely to be identical with different seeds)
      expect(level1.initialContainers, isNot(equals(level2.initialContainers)));
    });

    test('should generate reproducible levels with same seed', () {
      final generator1 = WaterSortLevelGenerator(
        config: const LevelGenerationConfig(seed: 789),
      );
      final generator2 = WaterSortLevelGenerator(
        config: const LevelGenerationConfig(seed: 789),
      );

      final level1 = generator1.generateLevel(1, 3, 4, 2);
      final level2 = generator2.generateLevel(1, 3, 4, 2);

      // Levels should be identical with same seed
      expect(level1.initialContainers, equals(level2.initialContainers));
    });

    test('should reject invalid levels in validation', () {
      // Create an invalid level manually
      final invalidLevel = Level(
        id: 1,
        difficulty: 3,
        containerCount: 3,
        colorCount: 2,
        initialContainers: [
          Container(
            id: 0,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.red, volume: 2),
            ], // Insufficient volume
          ),
          Container(
            id: 1,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.blue, volume: 2),
            ], // Insufficient volume
          ),
          Container(id: 2, capacity: 4, liquidLayers: []),
        ],
      );

      expect(generator.validateLevel(invalidLevel), isFalse);
    });

    test('should handle edge cases in level generation', () {
      // Minimum viable level
      final minLevel = generator.generateLevel(1, 1, 3, 1);
      expect(minLevel.containerCount, equals(3));
      expect(minLevel.colorCount, equals(1));
      expect(generator.validateLevel(minLevel), isTrue);

      // Complex level
      final complexLevel = generator.generateLevel(1, 10, 8, 6);
      expect(complexLevel.containerCount, equals(8));
      expect(complexLevel.colorCount, equals(6));
      expect(generator.validateLevel(complexLevel), isTrue);
    });

    test(
      'should generate levels with appropriate complexity for difficulty',
      () {
        final easyLevel = generator.generateLevel(1, 1, 4, 2);
        final hardLevel = generator.generateLevel(1, 10, 8, 6);

        expect(easyLevel.complexityScore, lessThan(hardLevel.complexityScore));
        expect(
          easyLevel.emptyContainerCount,
          greaterThanOrEqualTo(hardLevel.emptyContainerCount),
        );
      },
    );
  });
}
