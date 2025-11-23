import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/level.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/services/level_validator.dart';

void main() {
  group('LevelValidator.mergeAdjacentLayers', () {
    test('should merge adjacent layers of the same color', () {
      // Arrange: Create a container with adjacent same-color layers
      final container = Container(
        id: 0,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 1),
          const LiquidLayer(color: LiquidColor.red, volume: 2), // Adjacent red
          const LiquidLayer(color: LiquidColor.blue, volume: 1),
        ],
      );

      final level = Level(
        id: 1,
        difficulty: 1,
        containerCount: 1,
        colorCount: 2,
        initialContainers: [container],
      );

      // Act
      final mergedLevel = LevelValidator.mergeAdjacentLayers(level);

      // Assert
      expect(mergedLevel.initialContainers.length, equals(1));
      final mergedContainer = mergedLevel.initialContainers[0];
      expect(mergedContainer.liquidLayers.length, equals(2));
      
      // First layer should be merged red with volume 3
      expect(mergedContainer.liquidLayers[0].color, equals(LiquidColor.red));
      expect(mergedContainer.liquidLayers[0].volume, equals(3));
      
      // Second layer should be blue with volume 1
      expect(mergedContainer.liquidLayers[1].color, equals(LiquidColor.blue));
      expect(mergedContainer.liquidLayers[1].volume, equals(1));
    });

    test('should merge multiple adjacent layers of the same color', () {
      // Arrange: Create a container with multiple adjacent same-color layers
      final container = Container(
        id: 0,
        capacity: 6,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 1),
          const LiquidLayer(color: LiquidColor.red, volume: 1), // Adjacent red
          const LiquidLayer(color: LiquidColor.red, volume: 1), // Adjacent red
          const LiquidLayer(color: LiquidColor.blue, volume: 2),
          const LiquidLayer(color: LiquidColor.blue, volume: 1), // Adjacent blue
        ],
      );

      final level = Level(
        id: 1,
        difficulty: 1,
        containerCount: 1,
        colorCount: 2,
        initialContainers: [container],
      );

      // Act
      final mergedLevel = LevelValidator.mergeAdjacentLayers(level);

      // Assert
      final mergedContainer = mergedLevel.initialContainers[0];
      expect(mergedContainer.liquidLayers.length, equals(2));
      
      // First layer should be merged red with volume 3
      expect(mergedContainer.liquidLayers[0].color, equals(LiquidColor.red));
      expect(mergedContainer.liquidLayers[0].volume, equals(3));
      
      // Second layer should be merged blue with volume 3
      expect(mergedContainer.liquidLayers[1].color, equals(LiquidColor.blue));
      expect(mergedContainer.liquidLayers[1].volume, equals(3));
    });

    test('should not merge non-adjacent layers of the same color', () {
      // Arrange: Create a container with non-adjacent same-color layers
      final container = Container(
        id: 0,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 1),
          const LiquidLayer(color: LiquidColor.blue, volume: 1), // Different color in between
          const LiquidLayer(color: LiquidColor.red, volume: 1), // Non-adjacent red
          const LiquidLayer(color: LiquidColor.green, volume: 1),
        ],
      );

      final level = Level(
        id: 1,
        difficulty: 1,
        containerCount: 1,
        colorCount: 3,
        initialContainers: [container],
      );

      // Act
      final mergedLevel = LevelValidator.mergeAdjacentLayers(level);

      // Assert
      final mergedContainer = mergedLevel.initialContainers[0];
      expect(mergedContainer.liquidLayers.length, equals(4));
      
      // Layers should remain separate since they're not adjacent
      expect(mergedContainer.liquidLayers[0].color, equals(LiquidColor.red));
      expect(mergedContainer.liquidLayers[0].volume, equals(1));
      expect(mergedContainer.liquidLayers[1].color, equals(LiquidColor.blue));
      expect(mergedContainer.liquidLayers[1].volume, equals(1));
      expect(mergedContainer.liquidLayers[2].color, equals(LiquidColor.red));
      expect(mergedContainer.liquidLayers[2].volume, equals(1));
      expect(mergedContainer.liquidLayers[3].color, equals(LiquidColor.green));
      expect(mergedContainer.liquidLayers[3].volume, equals(1));
    });

    test('should handle empty containers without changes', () {
      // Arrange: Create an empty container
      final emptyContainer = Container(
        id: 0,
        capacity: 4,
        liquidLayers: [],
      );

      final level = Level(
        id: 1,
        difficulty: 1,
        containerCount: 1,
        colorCount: 0,
        initialContainers: [emptyContainer],
      );

      // Act
      final mergedLevel = LevelValidator.mergeAdjacentLayers(level);

      // Assert
      expect(mergedLevel.initialContainers.length, equals(1));
      final mergedContainer = mergedLevel.initialContainers[0];
      expect(mergedContainer.isEmpty, isTrue);
      expect(mergedContainer.liquidLayers.length, equals(0));
    });

    test('should handle single layer containers without changes', () {
      // Arrange: Create a container with only one layer
      final container = Container(
        id: 0,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 3),
        ],
      );

      final level = Level(
        id: 1,
        difficulty: 1,
        containerCount: 1,
        colorCount: 1,
        initialContainers: [container],
      );

      // Act
      final mergedLevel = LevelValidator.mergeAdjacentLayers(level);

      // Assert
      final mergedContainer = mergedLevel.initialContainers[0];
      expect(mergedContainer.liquidLayers.length, equals(1));
      expect(mergedContainer.liquidLayers[0].color, equals(LiquidColor.red));
      expect(mergedContainer.liquidLayers[0].volume, equals(3));
    });

    test('should handle multiple containers with different merging scenarios', () {
      // Arrange: Create multiple containers with various layer configurations
      final containers = [
        Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 1),
            const LiquidLayer(color: LiquidColor.red, volume: 2), // Adjacent red
            const LiquidLayer(color: LiquidColor.blue, volume: 1),
          ],
        ),
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [], // Empty container
        ),
        Container(
          id: 2,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.green, volume: 1),
            const LiquidLayer(color: LiquidColor.blue, volume: 1),
            const LiquidLayer(color: LiquidColor.green, volume: 1), // Non-adjacent green
          ],
        ),
      ];

      final level = Level(
        id: 1,
        difficulty: 1,
        containerCount: 3,
        colorCount: 3,
        initialContainers: containers,
      );

      // Act
      final mergedLevel = LevelValidator.mergeAdjacentLayers(level);

      // Assert
      expect(mergedLevel.initialContainers.length, equals(3));
      
      // First container: red layers should be merged
      final container0 = mergedLevel.initialContainers[0];
      expect(container0.liquidLayers.length, equals(2));
      expect(container0.liquidLayers[0].color, equals(LiquidColor.red));
      expect(container0.liquidLayers[0].volume, equals(3));
      expect(container0.liquidLayers[1].color, equals(LiquidColor.blue));
      expect(container0.liquidLayers[1].volume, equals(1));
      
      // Second container: should remain empty
      final container1 = mergedLevel.initialContainers[1];
      expect(container1.isEmpty, isTrue);
      
      // Third container: green layers should not be merged (not adjacent)
      final container2 = mergedLevel.initialContainers[2];
      expect(container2.liquidLayers.length, equals(3));
      expect(container2.liquidLayers[0].color, equals(LiquidColor.green));
      expect(container2.liquidLayers[0].volume, equals(1));
      expect(container2.liquidLayers[1].color, equals(LiquidColor.blue));
      expect(container2.liquidLayers[1].volume, equals(1));
      expect(container2.liquidLayers[2].color, equals(LiquidColor.green));
      expect(container2.liquidLayers[2].volume, equals(1));
    });

    test('should merge all layers when entire container has same color', () {
      // Arrange: Create a container where all layers are the same color
      final container = Container(
        id: 0,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 1),
          const LiquidLayer(color: LiquidColor.red, volume: 1),
          const LiquidLayer(color: LiquidColor.red, volume: 1),
          const LiquidLayer(color: LiquidColor.red, volume: 1),
        ],
      );

      final level = Level(
        id: 1,
        difficulty: 1,
        containerCount: 1,
        colorCount: 1,
        initialContainers: [container],
      );

      // Act
      final mergedLevel = LevelValidator.mergeAdjacentLayers(level);

      // Assert
      final mergedContainer = mergedLevel.initialContainers[0];
      expect(mergedContainer.liquidLayers.length, equals(1));
      expect(mergedContainer.liquidLayers[0].color, equals(LiquidColor.red));
      expect(mergedContainer.liquidLayers[0].volume, equals(4));
    });

    test('should preserve container IDs and other properties', () {
      // Arrange: Create containers with specific IDs and capacities
      final containers = [
        Container(
          id: 5,
          capacity: 6,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 2),
            const LiquidLayer(color: LiquidColor.red, volume: 1),
          ],
        ),
        Container(
          id: 10,
          capacity: 8,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.blue, volume: 3),
          ],
        ),
      ];

      final level = Level(
        id: 42,
        difficulty: 5,
        containerCount: 2,
        colorCount: 2,
        initialContainers: containers,
        tags: ['test', 'merge'],
      );

      // Act
      final mergedLevel = LevelValidator.mergeAdjacentLayers(level);

      // Assert
      // Level properties should be preserved
      expect(mergedLevel.id, equals(42));
      expect(mergedLevel.difficulty, equals(5));
      expect(mergedLevel.containerCount, equals(2));
      expect(mergedLevel.colorCount, equals(2));
      expect(mergedLevel.tags, equals(['test', 'merge']));
      
      // Container properties should be preserved
      expect(mergedLevel.initialContainers[0].id, equals(5));
      expect(mergedLevel.initialContainers[0].capacity, equals(6));
      expect(mergedLevel.initialContainers[1].id, equals(10));
      expect(mergedLevel.initialContainers[1].capacity, equals(8));
      
      // Only liquid layers should be merged
      expect(mergedLevel.initialContainers[0].liquidLayers.length, equals(1));
      expect(mergedLevel.initialContainers[0].liquidLayers[0].volume, equals(3));
    });

    test('should handle complex alternating color patterns', () {
      // Arrange: Create a container with alternating colors that have some adjacent pairs
      final container = Container(
        id: 0,
        capacity: 8,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 1),
          const LiquidLayer(color: LiquidColor.blue, volume: 1),
          const LiquidLayer(color: LiquidColor.blue, volume: 1), // Adjacent blue
          const LiquidLayer(color: LiquidColor.red, volume: 1),
          const LiquidLayer(color: LiquidColor.red, volume: 1), // Adjacent red
          const LiquidLayer(color: LiquidColor.red, volume: 1), // Adjacent red
          const LiquidLayer(color: LiquidColor.green, volume: 1),
          const LiquidLayer(color: LiquidColor.green, volume: 1), // Adjacent green
        ],
      );

      final level = Level(
        id: 1,
        difficulty: 1,
        containerCount: 1,
        colorCount: 3,
        initialContainers: [container],
      );

      // Act
      final mergedLevel = LevelValidator.mergeAdjacentLayers(level);

      // Assert
      final mergedContainer = mergedLevel.initialContainers[0];
      expect(mergedContainer.liquidLayers.length, equals(4));
      
      // Expected pattern after merging: red(1), blue(2), red(3), green(2)
      expect(mergedContainer.liquidLayers[0].color, equals(LiquidColor.red));
      expect(mergedContainer.liquidLayers[0].volume, equals(1));
      
      expect(mergedContainer.liquidLayers[1].color, equals(LiquidColor.blue));
      expect(mergedContainer.liquidLayers[1].volume, equals(2));
      
      expect(mergedContainer.liquidLayers[2].color, equals(LiquidColor.red));
      expect(mergedContainer.liquidLayers[2].volume, equals(3));
      
      expect(mergedContainer.liquidLayers[3].color, equals(LiquidColor.green));
      expect(mergedContainer.liquidLayers[3].volume, equals(2));
    });

    test('should return a new level instance, not modify the original', () {
      // Arrange: Create a level with adjacent layers
      final originalContainer = Container(
        id: 0,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 1),
          const LiquidLayer(color: LiquidColor.red, volume: 2),
        ],
      );

      final originalLevel = Level(
        id: 1,
        difficulty: 1,
        containerCount: 1,
        colorCount: 1,
        initialContainers: [originalContainer],
      );

      // Act
      final mergedLevel = LevelValidator.mergeAdjacentLayers(originalLevel);

      // Assert
      // Original level should be unchanged
      expect(originalLevel.initialContainers[0].liquidLayers.length, equals(2));
      expect(originalLevel.initialContainers[0].liquidLayers[0].volume, equals(1));
      expect(originalLevel.initialContainers[0].liquidLayers[1].volume, equals(2));
      
      // Merged level should have merged layers
      expect(mergedLevel.initialContainers[0].liquidLayers.length, equals(1));
      expect(mergedLevel.initialContainers[0].liquidLayers[0].volume, equals(3));
      
      // Should be different instances
      expect(identical(originalLevel, mergedLevel), isFalse);
      expect(identical(originalLevel.initialContainers[0], mergedLevel.initialContainers[0]), isFalse);
    });
  });
}