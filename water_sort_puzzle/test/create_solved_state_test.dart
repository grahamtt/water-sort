import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/services/reverse_level_generator.dart';
import 'package:water_sort_puzzle/services/level_generator.dart';

void main() {
  group('_createSolvedState', () {
    late ReverseLevelGenerator generator;

    setUp(() {
      generator = ReverseLevelGenerator(
        config: const LevelGenerationConfig(
          containerCapacity: 4,
          seed: 12345,
        ),
      );
    });

    test('example case: 2 colors, capacity 3, 1 empty slot', () {
      // Given: 2 colors, capacity 3, 1 empty slot
      // Expected: |AAA|BB| (total liquid = 2*3 - 1 = 5)
      // Color A: 3 units (full)
      // Color B: 2 units (reduced by 1)
      final colors = [LiquidColor.red, LiquidColor.blue];
      final containerCapacity = 3;
      final emptySlots = 1;
      final containerCount = 2; // ceil(5/3) = 2

      final containers = _callCreateSolvedState(
        generator,
        containerCount,
        colors,
        containerCapacity,
        emptySlots,
      );

      // Should have 2 containers
      expect(containers.length, 2);

      // Count total liquid and empty slots
      int totalLiquid = 0;
      int totalEmpty = 0;
      for (final container in containers) {
        totalLiquid += container.currentVolume;
        totalEmpty += container.remainingCapacity;
      }

      // Total liquid should be 5
      expect(totalLiquid, 5);
      // Total empty slots should be 1
      expect(totalEmpty, 1);

      // Each color should appear exactly once
      final colorCounts = <LiquidColor, int>{};
      for (final container in containers) {
        for (final layer in container.liquidLayers) {
          colorCounts[layer.color] = (colorCounts[layer.color] ?? 0) + layer.volume;
        }
      }
      expect(colorCounts.length, 2);
      expect(colorCounts[LiquidColor.red], 3);
      expect(colorCounts[LiquidColor.blue], 2);
    });

    test('small case: 2 colors, capacity 2, 1 empty slot', () {
      // Given: 2 colors, capacity 2, 1 empty slot
      // Expected: |AA|B| (total liquid = 2*2 - 1 = 3)
      // Color A: 2 units (full)
      // Color B: 1 unit
      final colors = [LiquidColor.red, LiquidColor.blue];
      final containerCapacity = 2;
      final emptySlots = 1;
      final containerCount = 2;

      final containers = _callCreateSolvedState(
        generator,
        containerCount,
        colors,
        containerCapacity,
        emptySlots,
      );

      expect(containers.length, 2);

      int totalLiquid = 0;
      int totalEmpty = 0;
      for (final container in containers) {
        totalLiquid += container.currentVolume;
        totalEmpty += container.remainingCapacity;
      }

      expect(totalLiquid, 3);
      expect(totalEmpty, 1);

      // Both colors should be present
      final colorCounts = <LiquidColor, int>{};
      for (final container in containers) {
        for (final layer in container.liquidLayers) {
          colorCounts[layer.color] = (colorCounts[layer.color] ?? 0) + layer.volume;
        }
      }
      expect(colorCounts.length, 2);
      expect(colorCounts[LiquidColor.red], 2);
      expect(colorCounts[LiquidColor.blue], 1);
    });

    test('3 colors, capacity 4, 2 empty slots', () {
      // Total liquid = 3*4 - 2 = 10
      // Expected distribution: |AAAA|BBB|CCC| (containers = ceil(10/4) = 3)
      final colors = [LiquidColor.red, LiquidColor.blue, LiquidColor.green];
      final containerCapacity = 4;
      final emptySlots = 2;
      final containerCount = 3; // ceil(10/4) = 3

      final containers = _callCreateSolvedState(
        generator,
        containerCount,
        colors,
        containerCapacity,
        emptySlots,
      );

      expect(containers.length, 3);

      int totalLiquid = 0;
      int totalEmpty = 0;
      for (final container in containers) {
        totalLiquid += container.currentVolume;
        totalEmpty += container.remainingCapacity;
      }

      expect(totalLiquid, 10);
      expect(totalEmpty, 2);

      // All 3 colors should be present
      final colorCounts = <LiquidColor, int>{};
      for (final container in containers) {
        for (final layer in container.liquidLayers) {
          colorCounts[layer.color] = (colorCounts[layer.color] ?? 0) + layer.volume;
        }
      }
      expect(colorCounts.length, 3);
      // Last 2 colors reduced by 1 each
      expect(colorCounts.values.toList()..sort(), [3, 3, 4]);
    });

    test('4 colors, capacity 4, 4 empty slots', () {
      // emptySlots (4) >= containerCapacity (4)
      // Expected: |AAAA|BBBB|CCCC|DDDD| | (4 full containers + 1 empty)
      final colors = [
        LiquidColor.red,
        LiquidColor.blue,
        LiquidColor.green,
        LiquidColor.yellow
      ];
      final containerCapacity = 4;
      final emptySlots = 4;
      final containerCount = 5; // 4 colors + 1 empty container

      final containers = _callCreateSolvedState(
        generator,
        containerCount,
        colors,
        containerCapacity,
        emptySlots,
      );

      expect(containers.length, 5);

      int totalLiquid = 0;
      int totalEmpty = 0;
      int emptyContainers = 0;
      for (final container in containers) {
        totalLiquid += container.currentVolume;
        totalEmpty += container.remainingCapacity;
        if (container.isEmpty) emptyContainers++;
      }

      expect(totalLiquid, 16); // All colors at full capacity
      expect(totalEmpty, 4); // One empty container
      expect(emptyContainers, 1);

      // All 4 colors should be present at full capacity
      final colorCounts = <LiquidColor, int>{};
      for (final container in containers) {
        for (final layer in container.liquidLayers) {
          colorCounts[layer.color] = (colorCounts[layer.color] ?? 0) + layer.volume;
        }
      }
      expect(colorCounts.length, 4);
      // Each color gets full capacity
      expect(colorCounts.values.toList()..sort(), [4, 4, 4, 4]);
    });

    test('2 colors, capacity 4, 5 empty slots', () {
      // emptySlots (5) >= containerCapacity (4)
      // Expected: |AAAA|BBB| | (2 full + 1 partial + 1 empty)
      // 5 empty slots = 1 empty container (4 slots) + 1 remaining slot
      final colors = [LiquidColor.red, LiquidColor.blue];
      final containerCapacity = 4;
      final emptySlots = 5;
      final containerCount = 3; // 2 colors + 1 empty container

      final containers = _callCreateSolvedState(
        generator,
        containerCount,
        colors,
        containerCapacity,
        emptySlots,
      );

      expect(containers.length, 3);

      int totalLiquid = 0;
      int totalEmpty = 0;
      int emptyContainers = 0;
      for (final container in containers) {
        totalLiquid += container.currentVolume;
        totalEmpty += container.remainingCapacity;
        if (container.isEmpty) emptyContainers++;
      }

      expect(totalLiquid, 7); // Red: 4, Blue: 3
      expect(totalEmpty, 5); // 1 empty container (4) + 1 in Blue container
      expect(emptyContainers, 1);

      // Both colors should be present
      final colorCounts = <LiquidColor, int>{};
      for (final container in containers) {
        for (final layer in container.liquidLayers) {
          colorCounts[layer.color] = (colorCounts[layer.color] ?? 0) + layer.volume;
        }
      }
      expect(colorCounts.length, 2);
      expect(colorCounts[LiquidColor.red], 4);
      expect(colorCounts[LiquidColor.blue], 3);
    });
  });
}

/// Helper to call the createSolvedState method
List<Container> _callCreateSolvedState(
  ReverseLevelGenerator generator,
  int containerCount,
  List<LiquidColor> colors,
  int containerCapacity,
  int emptySlots,
) {
  return generator.createSolvedState(
    containerCount,
    colors,
    containerCapacity,
    emptySlots,
  );
}
