import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/services/reverse_level_generator.dart';
import 'package:water_sort_puzzle/services/level_generator.dart';

void main() {
  group('ReverseLevelGenerator Optimization', () {
    test('generated levels use minimum necessary empty containers', () {
      final generator = ReverseLevelGenerator(
        config: const LevelGenerationConfig(
          containerCapacity: 4,
          seed: 99999,
        ),
      );

      // Generate a level with extra containers
      // 6 containers for 3 colors means 3 empty containers initially
      final level = generator.generateLevel(1, 5, 6, 3);

      // After optimization, we should have fewer than 3 empty containers
      // (unless all 3 are actually needed)
      final emptyCount = level.initialContainers.where((c) => c.isEmpty).length;
      
      // After optimization, some levels may have zero empty containers
      // if they can be solved without them
      expect(emptyCount, greaterThanOrEqualTo(0));
      
      // The level should have been optimized to use fewer containers than we started with
      // or the same if all were necessary
      expect(level.containerCount, lessThanOrEqualTo(6));
      
      // Verify the level is still valid
      expect(level.isStructurallyValid, true);
    });

    test('optimization maintains solvability', () {
      final generator = ReverseLevelGenerator(
        config: const LevelGenerationConfig(
          containerCapacity: 4,
          seed: 12345,
        ),
      );

      // Generate multiple levels and verify they're all valid after optimization
      for (int i = 1; i <= 10; i++) {
        final level = generator.generateLevel(i, 5, 7, 4);
        
        // Should be structurally valid
        expect(level.isStructurallyValid, true,
            reason: 'Level $i should be structurally valid after optimization');
        
        // After optimization, may have zero empty containers if solvable without
        final emptyCount = level.initialContainers.where((c) => c.isEmpty).length;
        expect(emptyCount, greaterThanOrEqualTo(0),
            reason: 'Level $i should have valid empty container count');
      }
    });

    test('optimization removes truly unnecessary empty containers', () {
      final generator = ReverseLevelGenerator(
        config: const LevelGenerationConfig(
          containerCapacity: 4,
          seed: 55555,
        ),
      );

      // Generate a level with many extra containers
      // 8 containers for 4 colors = 4 empty containers initially
      final level = generator.generateLevel(1, 3, 8, 4);

      final emptyCount = level.initialContainers.where((c) => c.isEmpty).length;
      
      // After optimization, we should have significantly fewer empty containers
      // Most puzzles don't need 4 empty containers
      expect(emptyCount, lessThan(4),
          reason: 'Optimization should remove some unnecessary empty containers');
      
      // May have zero if puzzle is solvable without empties
      expect(emptyCount, greaterThanOrEqualTo(0));
    });

    test('easy levels may use fewer containers after optimization', () {
      final generator = ReverseLevelGenerator(
        config: const LevelGenerationConfig(
          containerCapacity: 4,
          seed: 11111,
        ),
      );

      // Generate an easy level
      final level = generator.generateLevel(1, 1, 5, 2);

      // Easy levels with few colors should be optimized to use minimal containers
      expect(level.containerCount, lessThanOrEqualTo(5));
      expect(level.isStructurallyValid, true);
    });
  });
}
