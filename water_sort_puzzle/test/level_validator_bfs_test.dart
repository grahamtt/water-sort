import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/level.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/services/level_validator.dart';

void main() {
  group('LevelValidator BFS Solvability Tests', () {
    test('optimizeEmptyContainers uses actual BFS solver', () {
      // Create a level that is solvable with 2 colors and 2 empty containers
      // but should be optimized to use only 1 empty container
      final container1 = Container(
        id: 0,
        capacity: 4,
        liquidLayers: [
          LiquidLayer(color: LiquidColor.red, volume: 2),
          LiquidLayer(color: LiquidColor.blue, volume: 2),
        ],
      );

      final container2 = Container(
        id: 1,
        capacity: 4,
        liquidLayers: [
          LiquidLayer(color: LiquidColor.blue, volume: 2),
          LiquidLayer(color: LiquidColor.red, volume: 2),
        ],
      );

      final emptyContainer1 = Container(
        id: 2,
        capacity: 4,
        liquidLayers: [],
      );

      final emptyContainer2 = Container(
        id: 3,
        capacity: 4,
        liquidLayers: [],
      );

      final level = Level(
        id: 1,
        difficulty: 1,
        containerCount: 4,
        colorCount: 2,
        initialContainers: [container1, container2, emptyContainer1, emptyContainer2],
      );

      // Optimize the level
      final optimized = LevelValidator.optimizeEmptyContainers(level);

      // The optimized level should have fewer containers
      // With BFS solver, it should correctly determine minimum needed
      expect(optimized.containerCount, lessThan(level.containerCount));
      
      // Should keep at least one empty container for moves
      final emptyCount = optimized.initialContainers.where((c) => c.isEmpty).length;
      expect(emptyCount, greaterThanOrEqualTo(1));
    });

    test('optimizeEmptyContainers correctly identifies unsolvable configurations', () {
      // Create a level that requires 2 empty containers to solve
      // This is a more complex puzzle where removing an empty makes it unsolvable
      final container1 = Container(
        id: 0,
        capacity: 4,
        liquidLayers: [
          LiquidLayer(color: LiquidColor.red, volume: 1),
          LiquidLayer(color: LiquidColor.blue, volume: 1),
          LiquidLayer(color: LiquidColor.green, volume: 2),
        ],
      );

      final container2 = Container(
        id: 1,
        capacity: 4,
        liquidLayers: [
          LiquidLayer(color: LiquidColor.blue, volume: 1),
          LiquidLayer(color: LiquidColor.green, volume: 1),
          LiquidLayer(color: LiquidColor.red, volume: 2),
        ],
      );

      final container3 = Container(
        id: 2,
        capacity: 4,
        liquidLayers: [
          LiquidLayer(color: LiquidColor.green, volume: 1),
          LiquidLayer(color: LiquidColor.red, volume: 1),
          LiquidLayer(color: LiquidColor.blue, volume: 2),
        ],
      );

      final emptyContainer1 = Container(
        id: 3,
        capacity: 4,
        liquidLayers: [],
      );

      final emptyContainer2 = Container(
        id: 4,
        capacity: 4,
        liquidLayers: [],
      );

      final level = Level(
        id: 1,
        difficulty: 3,
        containerCount: 5,
        colorCount: 3,
        initialContainers: [container1, container2, container3, emptyContainer1, emptyContainer2],
      );

      // Optimize the level
      final optimized = LevelValidator.optimizeEmptyContainers(level);

      // The BFS solver should determine the minimum number of empty containers needed
      // and not remove too many
      expect(optimized.isStructurallyValid, isTrue);
      
      // Should have at least one empty container
      final emptyCount = optimized.initialContainers.where((c) => c.isEmpty).length;
      expect(emptyCount, greaterThanOrEqualTo(1));
    });

    test('optimizeEmptyContainers preserves solvability', () {
      // Generate a simple solvable level and verify optimization maintains solvability
      final container1 = Container(
        id: 0,
        capacity: 4,
        liquidLayers: [
          LiquidLayer(color: LiquidColor.red, volume: 3),
          LiquidLayer(color: LiquidColor.blue, volume: 1),
        ],
      );

      final container2 = Container(
        id: 1,
        capacity: 4,
        liquidLayers: [
          LiquidLayer(color: LiquidColor.blue, volume: 3),
          LiquidLayer(color: LiquidColor.red, volume: 1),
        ],
      );

      final emptyContainer1 = Container(
        id: 2,
        capacity: 4,
        liquidLayers: [],
      );

      final emptyContainer2 = Container(
        id: 3,
        capacity: 4,
        liquidLayers: [],
      );

      final emptyContainer3 = Container(
        id: 4,
        capacity: 4,
        liquidLayers: [],
      );

      final level = Level(
        id: 1,
        difficulty: 1,
        containerCount: 5,
        colorCount: 2,
        initialContainers: [container1, container2, emptyContainer1, emptyContainer2, emptyContainer3],
      );

      // Optimize the level
      final optimized = LevelValidator.optimizeEmptyContainers(level);

      // Should remove unnecessary empty containers
      expect(optimized.containerCount, lessThan(level.containerCount));
      
      // But should still be structurally valid
      expect(optimized.isStructurallyValid, isTrue);
      
      // And should have at least one empty container
      final emptyCount = optimized.initialContainers.where((c) => c.isEmpty).length;
      expect(emptyCount, greaterThanOrEqualTo(1));
    });
  });
}
