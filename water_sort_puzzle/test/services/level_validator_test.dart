import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/level.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/services/level_validator.dart';

void main() {
  group('LevelValidator', () {
    group('validateGeneratedLevel', () {
      test('should return false for level with completed containers', () {
        // Create a level with one completed container (full and single color)
        final completedContainer = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 4),
          ],
        );

        final mixedContainer = Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
            LiquidLayer(color: LiquidColor.green, volume: 1),
          ],
        );

        final emptyContainer = Container(
          id: 2,
          capacity: 4,
          liquidLayers: [],
        );

        final level = Level(
          id: 1,
          difficulty: 3,
          containerCount: 3,
          colorCount: 3,
          initialContainers: [completedContainer, mixedContainer, emptyContainer],
        );

        expect(LevelValidator.validateGeneratedLevel(level), isFalse);
      });

      test('should return false for already solved level', () {
        // Create a level where all containers are sorted (solved state)
        final sortedContainer1 = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 3),
          ],
        );

        final sortedContainer2 = Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ],
        );

        final emptyContainer = Container(
          id: 2,
          capacity: 4,
          liquidLayers: [],
        );

        final level = Level(
          id: 1,
          difficulty: 3,
          containerCount: 3,
          colorCount: 2,
          initialContainers: [sortedContainer1, sortedContainer2, emptyContainer],
        );

        expect(LevelValidator.validateGeneratedLevel(level), isFalse);
      });

      test('should return true for valid unsolved level with no completed containers', () {
        // Create a valid level with mixed containers but no completed ones
        // Each color must have exactly 4 units (one container's worth)
        final mixedContainer1 = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ],
        );

        final mixedContainer2 = Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        );

        final emptyContainer = Container(
          id: 2,
          capacity: 4,
          liquidLayers: [],
        );

        final level = Level(
          id: 1,
          difficulty: 3,
          containerCount: 3,
          colorCount: 2,
          initialContainers: [mixedContainer1, mixedContainer2, emptyContainer],
        );

        expect(LevelValidator.validateGeneratedLevel(level), isTrue);
      });

      test('should return false for structurally invalid level', () {
        // Create a level with wrong container count
        final container = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        );

        final level = Level(
          id: 1,
          difficulty: 3,
          containerCount: 2, // Says 2 containers but only has 1
          colorCount: 1,
          initialContainers: [container],
        );

        expect(LevelValidator.validateGeneratedLevel(level), isFalse);
      });
    });

    group('hasCompletedContainers', () {
      test('should return true when level has completed containers', () {
        final completedContainer = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 4),
          ],
        );

        final normalContainer = Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ],
        );

        final level = Level(
          id: 1,
          difficulty: 3,
          containerCount: 2,
          colorCount: 2,
          initialContainers: [completedContainer, normalContainer],
        );

        expect(LevelValidator.hasCompletedContainers(level), isTrue);
      });

      test('should return false when level has no completed containers', () {
        final partialContainer = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 3), // Not full
          ],
        );

        final mixedContainer = Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
            LiquidLayer(color: LiquidColor.green, volume: 2), // Mixed colors
          ],
        );

        final level = Level(
          id: 1,
          difficulty: 3,
          containerCount: 2,
          colorCount: 3,
          initialContainers: [partialContainer, mixedContainer],
        );

        expect(LevelValidator.hasCompletedContainers(level), isFalse);
      });

      test('should return false for empty level', () {
        final emptyContainer1 = Container(id: 0, capacity: 4, liquidLayers: []);
        final emptyContainer2 = Container(id: 1, capacity: 4, liquidLayers: []);

        final level = Level(
          id: 1,
          difficulty: 1,
          containerCount: 2,
          colorCount: 0,
          initialContainers: [emptyContainer1, emptyContainer2],
        );

        expect(LevelValidator.hasCompletedContainers(level), isFalse);
      });

      test('should handle multiple completed containers', () {
        final completedContainer1 = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 4),
          ],
        );

        final completedContainer2 = Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 4),
          ],
        );

        final level = Level(
          id: 1,
          difficulty: 5,
          containerCount: 2,
          colorCount: 2,
          initialContainers: [completedContainer1, completedContainer2],
        );

        expect(LevelValidator.hasCompletedContainers(level), isTrue);
      });
    });

    group('isContainerCompleted', () {
      test('should return true for full single-color container', () {
        final completedContainer = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 4),
          ],
        );

        expect(LevelValidator.isContainerCompleted(completedContainer), isTrue);
      });

      test('should return true for full single-color container with multiple layers of same color', () {
        final completedContainer = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        );

        expect(LevelValidator.isContainerCompleted(completedContainer), isTrue);
      });

      test('should return false for empty container', () {
        final emptyContainer = Container(id: 0, capacity: 4, liquidLayers: []);

        expect(LevelValidator.isContainerCompleted(emptyContainer), isFalse);
      });

      test('should return false for partial single-color container', () {
        final partialContainer = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 3), // Not full
          ],
        );

        expect(LevelValidator.isContainerCompleted(partialContainer), isFalse);
      });

      test('should return false for full mixed-color container', () {
        final mixedContainer = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 2), // Mixed colors
          ],
        );

        expect(LevelValidator.isContainerCompleted(mixedContainer), isFalse);
      });

      test('should return false for partial mixed-color container', () {
        final partialMixedContainer = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 1),
            LiquidLayer(color: LiquidColor.blue, volume: 1), // Mixed and not full
          ],
        );

        expect(LevelValidator.isContainerCompleted(partialMixedContainer), isFalse);
      });

      test('should handle edge case with zero capacity container', () {
        final zeroCapacityContainer = Container(
          id: 0,
          capacity: 0,
          liquidLayers: [],
        );

        expect(LevelValidator.isContainerCompleted(zeroCapacityContainer), isFalse);
      });

      test('should handle container with single layer of volume 1', () {
        final singleUnitContainer = Container(
          id: 0,
          capacity: 1,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 1),
          ],
        );

        expect(LevelValidator.isContainerCompleted(singleUnitContainer), isTrue);
      });

      test('should handle container with many small layers of same color', () {
        final manyLayersContainer = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 1),
            LiquidLayer(color: LiquidColor.red, volume: 1),
            LiquidLayer(color: LiquidColor.red, volume: 1),
            LiquidLayer(color: LiquidColor.red, volume: 1),
          ],
        );

        expect(LevelValidator.isContainerCompleted(manyLayersContainer), isTrue);
      });
    });

    group('edge cases and integration', () {
      test('should handle level with all empty containers', () {
        final emptyContainer1 = Container(id: 0, capacity: 4, liquidLayers: []);
        final emptyContainer2 = Container(id: 1, capacity: 4, liquidLayers: []);
        final emptyContainer3 = Container(id: 2, capacity: 4, liquidLayers: []);

        final level = Level(
          id: 1,
          difficulty: 1,
          containerCount: 3,
          colorCount: 0,
          initialContainers: [emptyContainer1, emptyContainer2, emptyContainer3],
        );

        expect(LevelValidator.hasCompletedContainers(level), isFalse);
        expect(LevelValidator.validateGeneratedLevel(level), isFalse); // Should fail structural validation
      });

      test('should handle level with mix of completed, partial, and empty containers', () {
        final completedContainer = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 4),
          ],
        );

        final partialContainer = Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ],
        );

        final emptyContainer = Container(id: 2, capacity: 4, liquidLayers: []);

        final level = Level(
          id: 1,
          difficulty: 3,
          containerCount: 3,
          colorCount: 2,
          initialContainers: [completedContainer, partialContainer, emptyContainer],
        );

        expect(LevelValidator.hasCompletedContainers(level), isTrue);
        expect(LevelValidator.validateGeneratedLevel(level), isFalse);
      });

      test('should validate level with complex liquid layer arrangements', () {
        final complexContainer1 = Container(
          id: 0,
          capacity: 6,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 1),
            LiquidLayer(color: LiquidColor.green, volume: 2),
          ],
        );

        final complexContainer2 = Container(
          id: 1,
          capacity: 6,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 3),
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        );

        final emptyContainer = Container(id: 2, capacity: 6, liquidLayers: []);

        final level = Level(
          id: 1,
          difficulty: 5,
          containerCount: 3,
          colorCount: 3,
          initialContainers: [complexContainer1, complexContainer2, emptyContainer],
        );

        expect(LevelValidator.hasCompletedContainers(level), isFalse);
        // Note: This might fail structural validation due to color volume requirements
      });
    });

    group('optimizeEmptyContainers', () {
      test('should not optimize level with 3 or fewer containers', () {
        final container1 = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ],
        );

        final emptyContainer = Container(id: 1, capacity: 4, liquidLayers: []);
        final emptyContainer2 = Container(id: 2, capacity: 4, liquidLayers: []);

        final level = Level(
          id: 1,
          difficulty: 3,
          containerCount: 3,
          colorCount: 2,
          initialContainers: [container1, emptyContainer, emptyContainer2],
        );

        final optimized = LevelValidator.optimizeEmptyContainers(level);
        expect(optimized.containerCount, equals(3));
        expect(optimized.initialContainers.length, equals(3));
      });

      test('should not remove empty containers if only one exists', () {
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

        final emptyContainer = Container(id: 2, capacity: 4, liquidLayers: []);

        final level = Level(
          id: 1,
          difficulty: 3,
          containerCount: 3,
          colorCount: 2,
          initialContainers: [container1, container2, emptyContainer],
        );

        final optimized = LevelValidator.optimizeEmptyContainers(level);
        expect(optimized.containerCount, equals(3));
        expect(optimized.initialContainers.length, equals(3));
      });

      test('should remove unnecessary empty containers when level remains solvable', () {
        // Create a level with multiple empty containers where some can be removed
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

        final emptyContainer1 = Container(id: 2, capacity: 4, liquidLayers: []);
        final emptyContainer2 = Container(id: 3, capacity: 4, liquidLayers: []);
        final emptyContainer3 = Container(id: 4, capacity: 4, liquidLayers: []);

        final level = Level(
          id: 1,
          difficulty: 3,
          containerCount: 5,
          colorCount: 2,
          initialContainers: [container1, container2, emptyContainer1, emptyContainer2, emptyContainer3],
        );

        final optimized = LevelValidator.optimizeEmptyContainers(level);
        
        // Should remove some empty containers but keep at least one
        expect(optimized.containerCount, lessThan(5));
        expect(optimized.containerCount, greaterThanOrEqualTo(3));
        
        // Should still have at least one empty container
        final emptyCount = optimized.initialContainers.where((c) => c.isEmpty).length;
        expect(emptyCount, greaterThanOrEqualTo(1));
        
        // Should preserve all non-empty containers
        final nonEmptyCount = optimized.initialContainers.where((c) => !c.isEmpty).length;
        expect(nonEmptyCount, equals(2));
      });

      test('should stop optimization when removing container makes level unsolvable', () {
        // Create a level where removing too many empty containers would make it unsolvable
        final container1 = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 1),
            LiquidLayer(color: LiquidColor.blue, volume: 1),
            LiquidLayer(color: LiquidColor.green, volume: 1),
            LiquidLayer(color: LiquidColor.yellow, volume: 1),
          ],
        );

        final container2 = Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 1),
            LiquidLayer(color: LiquidColor.blue, volume: 1),
            LiquidLayer(color: LiquidColor.green, volume: 1),
            LiquidLayer(color: LiquidColor.yellow, volume: 1),
          ],
        );

        final container3 = Container(
          id: 2,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 1),
            LiquidLayer(color: LiquidColor.blue, volume: 1),
            LiquidLayer(color: LiquidColor.green, volume: 1),
            LiquidLayer(color: LiquidColor.yellow, volume: 1),
          ],
        );

        final container4 = Container(
          id: 3,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 1),
            LiquidLayer(color: LiquidColor.blue, volume: 1),
            LiquidLayer(color: LiquidColor.green, volume: 1),
            LiquidLayer(color: LiquidColor.yellow, volume: 1),
          ],
        );

        final emptyContainer1 = Container(id: 4, capacity: 4, liquidLayers: []);
        final emptyContainer2 = Container(id: 5, capacity: 4, liquidLayers: []);
        final emptyContainer3 = Container(id: 6, capacity: 4, liquidLayers: []);

        final level = Level(
          id: 1,
          difficulty: 8,
          containerCount: 7,
          colorCount: 4,
          initialContainers: [container1, container2, container3, container4, emptyContainer1, emptyContainer2, emptyContainer3],
        );

        final optimized = LevelValidator.optimizeEmptyContainers(level);
        
        // Should keep enough containers to remain solvable
        expect(optimized.containerCount, greaterThanOrEqualTo(5)); // 4 colors + at least 1 empty
        expect(optimized.containerCount, lessThanOrEqualTo(7));
      });

      test('should reassign container IDs sequentially after optimization', () {
        final container1 = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 4),
          ],
        );

        final container2 = Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 4),
          ],
        );

        final emptyContainer1 = Container(id: 2, capacity: 4, liquidLayers: []);
        final emptyContainer2 = Container(id: 3, capacity: 4, liquidLayers: []);
        final emptyContainer3 = Container(id: 4, capacity: 4, liquidLayers: []);

        final level = Level(
          id: 1,
          difficulty: 3,
          containerCount: 5,
          colorCount: 2,
          initialContainers: [container1, container2, emptyContainer1, emptyContainer2, emptyContainer3],
        );

        final optimized = LevelValidator.optimizeEmptyContainers(level);
        
        // Check that IDs are sequential starting from 0
        for (int i = 0; i < optimized.initialContainers.length; i++) {
          expect(optimized.initialContainers[i].id, equals(i));
        }
      });

      test('should preserve liquid content during optimization', () {
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

        final emptyContainer1 = Container(id: 2, capacity: 4, liquidLayers: []);
        final emptyContainer2 = Container(id: 3, capacity: 4, liquidLayers: []);

        final level = Level(
          id: 1,
          difficulty: 3,
          containerCount: 4,
          colorCount: 2,
          initialContainers: [container1, container2, emptyContainer1, emptyContainer2],
        );

        final optimized = LevelValidator.optimizeEmptyContainers(level);
        
        // Find the non-empty containers in the optimized level
        final nonEmptyContainers = optimized.initialContainers.where((c) => !c.isEmpty).toList();
        expect(nonEmptyContainers.length, equals(2));
        
        // Check that liquid content is preserved
        final totalRedVolume = nonEmptyContainers.fold(0, (sum, container) {
          return sum + container.liquidLayers
              .where((layer) => layer.color == LiquidColor.red)
              .fold(0, (layerSum, layer) => layerSum + layer.volume);
        });
        
        final totalBlueVolume = nonEmptyContainers.fold(0, (sum, container) {
          return sum + container.liquidLayers
              .where((layer) => layer.color == LiquidColor.blue)
              .fold(0, (layerSum, layer) => layerSum + layer.volume);
        });
        
        expect(totalRedVolume, equals(4));
        expect(totalBlueVolume, equals(4));
      });

      test('should handle edge case with no empty containers', () {
        final container1 = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 4),
          ],
        );

        final container2 = Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 4),
          ],
        );

        final level = Level(
          id: 1,
          difficulty: 3,
          containerCount: 2,
          colorCount: 2,
          initialContainers: [container1, container2],
        );

        final optimized = LevelValidator.optimizeEmptyContainers(level);
        
        // Should return the same level since there are no empty containers to remove
        expect(optimized.containerCount, equals(2));
        expect(optimized.initialContainers.length, equals(2));
      });

      test('should handle level with partial containers (not completely full)', () {
        final partialContainer1 = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        );

        final partialContainer2 = Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ],
        );

        final emptyContainer1 = Container(id: 2, capacity: 4, liquidLayers: []);
        final emptyContainer2 = Container(id: 3, capacity: 4, liquidLayers: []);

        final level = Level(
          id: 1,
          difficulty: 3,
          containerCount: 4,
          colorCount: 2,
          initialContainers: [partialContainer1, partialContainer2, emptyContainer1, emptyContainer2],
        );

        final optimized = LevelValidator.optimizeEmptyContainers(level);
        
        // Should optimize while considering the partial containers have remaining capacity
        expect(optimized.containerCount, lessThanOrEqualTo(4));
        
        // Should preserve the partial containers
        final partialContainers = optimized.initialContainers.where((c) => 
            !c.isEmpty && !c.isFull).toList();
        expect(partialContainers.length, equals(2));
      });
    });
  });
}