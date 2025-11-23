import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/models/level.dart';
import 'package:water_sort_puzzle/services/level_generator.dart';

void main() {
  group('Level Solvability Tests', () {
    late WaterSortLevelGenerator generator;

    setUp(() {
      generator = WaterSortLevelGenerator(
        config: const LevelGenerationConfig(
          containerCapacity: 4,
          enableActualSolvabilityTest: true,
          maxSolvabilityStates: 10000,
          maxSolvabilityAttempts: 1000,
          maxGenerationAttempts: 100, // Increase attempts since we're validating solvability
        ),
      );
    });

    test('should validate a simple solvable level', () {
      // Create a simple solvable puzzle:
      // Container 0: [Red:2, Blue:2]
      // Container 1: [Red:2, Blue:2]
      // Container 2: [Empty]
      final containers = [
        Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        ),
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        ),
        Container(
          id: 2,
          capacity: 4,
          liquidLayers: [],
        ),
      ];

      final level = Level(
        id: 1,
        difficulty: 1,
        containerCount: 3,
        colorCount: 2,
        initialContainers: containers,
        tags: ['test'],
      );

      expect(generator.validateLevel(level), isTrue);
    });

    test('should reject an unsolvable level (no empty space)', () {
      // Create an unsolvable puzzle - all containers full with mixed colors
      // and no empty space to work with
      final containers = [
        Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ],
        ),
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        ),
      ];

      final level = Level(
        id: 2,
        difficulty: 1,
        containerCount: 2,
        colorCount: 2,
        initialContainers: containers,
        tags: ['test'],
      );

      // This should fail the heuristic check (no empty slots)
      expect(generator.validateLevel(level), isFalse);
    });

    test('should reject an already solved level', () {
      // Create a level that's already solved
      final containers = [
        Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 4),
          ],
        ),
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 4),
          ],
        ),
        Container(
          id: 2,
          capacity: 4,
          liquidLayers: [],
        ),
      ];

      final level = Level(
        id: 3,
        difficulty: 1,
        containerCount: 3,
        colorCount: 2,
        initialContainers: containers,
        tags: ['test'],
      );

      // Should fail because level is already solved
      expect(generator.validateLevel(level), isFalse);
    });

    test('should validate generated levels are solvable', () {
      // Generate several levels and verify they're all solvable
      for (int i = 0; i < 3; i++) {
        final level = generator.generateLevel(
          i,
          1 + i, // difficulty 1-3
          4, // 4 containers (keep it simple)
          2, // 2 colors (keep it simple)
        );

        expect(generator.validateLevel(level), isTrue,
            reason: 'Generated level $i should be solvable');
      }
    });

    test('should validate a moderately complex solvable level', () {
      // Create a more complex solvable puzzle:
      // Container 0: [Green:1, Red:2, Blue:1]
      // Container 1: [Blue:2, Green:2]
      // Container 2: [Red:2, Green:1, Blue:1]
      // Container 3: [Empty]
      final containers = [
        Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 1),
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.green, volume: 1),
          ],
        ),
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.green, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ],
        ),
        Container(
          id: 2,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 1),
            LiquidLayer(color: LiquidColor.green, volume: 1),
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        ),
        Container(
          id: 3,
          capacity: 4,
          liquidLayers: [],
        ),
      ];

      final level = Level(
        id: 4,
        difficulty: 2,
        containerCount: 4,
        colorCount: 3,
        initialContainers: containers,
        tags: ['test'],
      );

      expect(generator.validateLevel(level), isTrue);
    });

    test('should handle performance limits gracefully', () {
      // Create a complex level that might hit state limits
      final containers = [
        Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.purple, volume: 1),
            LiquidLayer(color: LiquidColor.orange, volume: 1),
            LiquidLayer(color: LiquidColor.green, volume: 1),
            LiquidLayer(color: LiquidColor.red, volume: 1),
          ],
        ),
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 1),
            LiquidLayer(color: LiquidColor.purple, volume: 1),
            LiquidLayer(color: LiquidColor.orange, volume: 1),
            LiquidLayer(color: LiquidColor.green, volume: 1),
          ],
        ),
        Container(
          id: 2,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 1),
            LiquidLayer(color: LiquidColor.blue, volume: 1),
            LiquidLayer(color: LiquidColor.purple, volume: 1),
            LiquidLayer(color: LiquidColor.orange, volume: 1),
          ],
        ),
        Container(
          id: 3,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.green, volume: 1),
            LiquidLayer(color: LiquidColor.red, volume: 1),
            LiquidLayer(color: LiquidColor.blue, volume: 1),
            LiquidLayer(color: LiquidColor.purple, volume: 1),
          ],
        ),
        Container(
          id: 4,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.orange, volume: 1),
            LiquidLayer(color: LiquidColor.green, volume: 1),
            LiquidLayer(color: LiquidColor.red, volume: 1),
            LiquidLayer(color: LiquidColor.blue, volume: 1),
          ],
        ),
        Container(
          id: 5,
          capacity: 4,
          liquidLayers: [],
        ),
      ];

      final level = Level(
        id: 5,
        difficulty: 5,
        containerCount: 6,
        colorCount: 5,
        initialContainers: containers,
        tags: ['test'],
      );

      // Should complete without hanging, even if it can't find a solution
      // within the state limit
      final result = generator.validateLevel(level);
      expect(result, isA<bool>());
    });
  });

  group('Solvability Configuration Tests', () {
    test('should respect enableActualSolvabilityTest flag', () {
      final generatorWithoutTest = WaterSortLevelGenerator(
        config: const LevelGenerationConfig(
          enableActualSolvabilityTest: false,
        ),
      );

      // Create a simple level
      final containers = [
        Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        ),
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        ),
        Container(
          id: 2,
          capacity: 4,
          liquidLayers: [],
        ),
      ];

      final level = Level(
        id: 1,
        difficulty: 1,
        containerCount: 3,
        colorCount: 2,
        initialContainers: containers,
        tags: ['test'],
      );

      // Should pass heuristic checks only
      expect(generatorWithoutTest.validateLevel(level), isTrue);
    });
  });
}
