import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/services/level_generator.dart';

void main() {
  group('Container Capacity Ramping', () {
    late WaterSortLevelGenerator generator;

    setUp(() {
      generator = WaterSortLevelGenerator(
        config: const LevelGenerationConfig(seed: 42),
      );
    });

    test('should increase capacity by 1 every 10 levels', () {
      final testCases = {
        1: 4,   // Levels 1-10: capacity 4
        5: 4,
        10: 4,
        11: 5,  // Levels 11-20: capacity 5
        15: 5,
        20: 5,
        21: 6,  // Levels 21-30: capacity 6
        25: 6,
        30: 6,
        31: 7,  // Levels 31-40: capacity 7
        40: 7,
        41: 8,  // Levels 41-50: capacity 8
        50: 8,
      };

      testCases.forEach((levelId, expectedCapacity) {
        final level = generator.generateLevel(levelId, 3, 5, 3, expectedCapacity);
        
        // Verify all containers have the correct capacity
        for (final container in level.initialContainers) {
          expect(container.capacity, equals(expectedCapacity),
              reason: 'Level $levelId should have capacity $expectedCapacity');
        }
      });
    });

    test('should maintain correct liquid volume per color with varying capacity', () {
      // Test that each color still has exactly one container's worth of liquid
      final level10 = generator.generateLevel(10, 3, 5, 3, 4);  // capacity 4
      final level20 = generator.generateLevel(20, 3, 5, 3, 5);  // capacity 5
      final level30 = generator.generateLevel(30, 3, 5, 3, 6);  // capacity 6

      for (final (level, expectedVolume) in [(level10, 4), (level20, 5), (level30, 6)]) {
        final colorVolumes = <String, int>{};
        for (final container in level.initialContainers) {
          for (final layer in container.liquidLayers) {
            final colorName = layer.color.name;
            colorVolumes[colorName] = (colorVolumes[colorName] ?? 0) + layer.volume;
          }
        }

        // Each color should have exactly one container's worth
        for (final volume in colorVolumes.values) {
          expect(volume, equals(expectedVolume),
              reason: 'Each color should have $expectedVolume units for level ${level.id}');
        }
      }
    });

    test('should generate valid levels with different capacities', () {
      // Test levels across different capacity tiers
      for (final levelId in [1, 11, 21, 31, 41]) {
        final capacity = 4 + ((levelId - 1) ~/ 10);
        final level = generator.generateLevel(levelId, 3, 5, 3, capacity);
        
        expect(level.isStructurallyValid, isTrue,
            reason: 'Level $levelId with capacity $capacity should be structurally valid');
        expect(generator.validateLevel(level), isTrue,
            reason: 'Level $levelId with capacity $capacity should be solvable');
      }
    });
  });
}
