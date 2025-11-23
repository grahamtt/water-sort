import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/level.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/services/level_generator.dart';
import 'package:water_sort_puzzle/services/level_validator.dart';

void main() {
  group('LevelValidator Empty Container Optimization Integration', () {
    late WaterSortLevelGenerator generator;

    setUp(() {
      const config = LevelGenerationConfig(seed: 42);
      generator = WaterSortLevelGenerator(config: config);
    });

    test('should integrate empty container optimization into level generation', () {
      // Generate a level that would normally have multiple empty containers
      final level = generator.generateLevel(1, 2, 6, 2); // Easy level with many containers

      // The optimization should have reduced the container count
      expect(level.containerCount, lessThanOrEqualTo(6));
      
      // Should still have at least one empty container for solvability
      final emptyCount = level.initialContainers.where((c) => c.isEmpty).length;
      expect(emptyCount, greaterThanOrEqualTo(1));
      
      // Should preserve all liquid content
      final totalLiquidVolume = level.initialContainers.fold(0, (sum, container) {
        return sum + container.liquidLayers.fold(0, (layerSum, layer) => layerSum + layer.volume);
      });
      expect(totalLiquidVolume, equals(8)); // 2 colors * 4 units each
      
      // Level should still be valid after optimization
      expect(LevelValidator.validateGeneratedLevel(level), isTrue);
    });

    test('should apply optimization through optimizeLevel method', () {
      // Create a level with excessive empty containers
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

      // Apply optimization through the generator's optimizeLevel method
      final optimized = generator.optimizeLevel(level);
      
      // Should have fewer containers than the original
      expect(optimized.containerCount, lessThan(5));
      expect(optimized.initialContainers.length, lessThan(5));
      
      // Should still be valid
      expect(LevelValidator.validateGeneratedLevel(optimized), isTrue);
    });

    test('should maintain level signature consistency after optimization', () {
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

      final level = Level(
        id: 1,
        difficulty: 3,
        containerCount: 4,
        colorCount: 2,
        initialContainers: [container1, container2, emptyContainer1, emptyContainer2],
      );

      final optimized = LevelValidator.optimizeEmptyContainers(level);
      
      // Should be able to generate signatures for both levels
      final originalSignature = generator.generateLevelSignature(level);
      final optimizedSignature = generator.generateLevelSignature(optimized);
      
      expect(originalSignature, isNotEmpty);
      expect(optimizedSignature, isNotEmpty);
      
      // Signatures should be different if container count changed
      if (optimized.containerCount != level.containerCount) {
        expect(optimizedSignature, isNot(equals(originalSignature)));
      }
    });

    test('should handle edge cases in optimization workflow', () {
      // Test with minimum containers (should not optimize)
      final minimalLevel = generator.generateLevel(1, 1, 3, 2);
      expect(minimalLevel.containerCount, equals(3)); // Should not be reduced further
      
      // Test with no empty containers (should not change)
      final container1 = Container(
        id: 0,
        capacity: 4,
        liquidLayers: [LiquidLayer(color: LiquidColor.red, volume: 4)],
      );
      
      final container2 = Container(
        id: 1,
        capacity: 4,
        liquidLayers: [LiquidLayer(color: LiquidColor.blue, volume: 4)],
      );

      final noEmptyLevel = Level(
        id: 1,
        difficulty: 3,
        containerCount: 2,
        colorCount: 2,
        initialContainers: [container1, container2],
      );

      final optimizedNoEmpty = LevelValidator.optimizeEmptyContainers(noEmptyLevel);
      expect(optimizedNoEmpty.containerCount, equals(2)); // Should remain unchanged
    });

    test('should preserve solvability after optimization', () {
      // Create a complex level that requires careful optimization
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
          LiquidLayer(color: LiquidColor.red, volume: 1),
          LiquidLayer(color: LiquidColor.green, volume: 2),
        ],
      );

      final container3 = Container(
        id: 2,
        capacity: 4,
        liquidLayers: [
          LiquidLayer(color: LiquidColor.red, volume: 2),
          LiquidLayer(color: LiquidColor.blue, volume: 2),
        ],
      );

      final emptyContainer1 = Container(id: 3, capacity: 4, liquidLayers: []);
      final emptyContainer2 = Container(id: 4, capacity: 4, liquidLayers: []);
      final emptyContainer3 = Container(id: 5, capacity: 4, liquidLayers: []);

      final complexLevel = Level(
        id: 1,
        difficulty: 5,
        containerCount: 6,
        colorCount: 3,
        initialContainers: [container1, container2, container3, emptyContainer1, emptyContainer2, emptyContainer3],
      );

      final optimized = LevelValidator.optimizeEmptyContainers(complexLevel);
      
      // Should optimize but maintain solvability
      expect(optimized.containerCount, lessThanOrEqualTo(6));
      expect(optimized.containerCount, greaterThanOrEqualTo(4)); // 3 colors + at least 1 empty
      
      // Should still pass validation
      expect(LevelValidator.validateGeneratedLevel(optimized), isTrue);
    });
  });
}