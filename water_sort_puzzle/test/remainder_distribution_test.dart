import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/services/reverse_level_generator.dart';
import 'package:water_sort_puzzle/services/level_generator.dart';

void main() {
  test('remainder slots are distributed evenly across colors', () {
    final generator = ReverseLevelGenerator(
      config: const LevelGenerationConfig(seed: 12345),
    );
    
    // Test case: 3 colors, capacity 5, 8 empty slots
    // 8 empty slots = 1 empty container (5 slots) + 3 remaining slots
    // The 3 remaining slots should be distributed evenly: each color loses 1
    // Expected: |AAAA|BBBB|CCCC| | (not |AAAAA|BBBBB|CC| |)
    final colors = [LiquidColor.red, LiquidColor.blue, LiquidColor.green];
    final containerCapacity = 5;
    final emptySlots = 8;
    final containerCount = 4; // 3 colors + 1 empty
    
    final containers = generator.createSolvedState(
      containerCount,
      colors,
      containerCapacity,
      emptySlots,
    );
    
    // Count volumes per color
    final colorVolumes = <LiquidColor, int>{};
    for (final container in containers) {
      for (final layer in container.liquidLayers) {
        colorVolumes[layer.color] = (colorVolumes[layer.color] ?? 0) + layer.volume;
      }
    }
    
    // Verify even distribution: each color should have 4 units (capacity 5 - 1)
    expect(colorVolumes[LiquidColor.red], 4);
    expect(colorVolumes[LiquidColor.blue], 4);
    expect(colorVolumes[LiquidColor.green], 4);
    
    // Verify total empty slots
    int totalEmpty = 0;
    for (final container in containers) {
      totalEmpty += container.remainingCapacity;
    }
    expect(totalEmpty, emptySlots);
  });
  
  test('remainder distribution with 2 colors and 3 remainder slots', () {
    final generator = ReverseLevelGenerator(
      config: const LevelGenerationConfig(seed: 12345),
    );
    
    // Test case: 2 colors, capacity 5, 8 empty slots
    // 8 empty slots = 1 empty container (5 slots) + 3 remaining slots
    // 3 remaining slots distributed across 2 colors: 1 slot each + 1 extra
    // Expected: |AAAA|BBB| | (red loses 1, blue loses 2)
    final colors = [LiquidColor.red, LiquidColor.blue];
    final containerCapacity = 5;
    final emptySlots = 8;
    final containerCount = 3; // 2 colors + 1 empty
    
    final containers = generator.createSolvedState(
      containerCount,
      colors,
      containerCapacity,
      emptySlots,
    );
    
    // Count volumes per color
    final colorVolumes = <LiquidColor, int>{};
    for (final container in containers) {
      for (final layer in container.liquidLayers) {
        colorVolumes[layer.color] = (colorVolumes[layer.color] ?? 0) + layer.volume;
      }
    }
    
    // Red loses 1 slot, blue loses 2 slots (as even as possible)
    expect(colorVolumes[LiquidColor.red], 4);
    expect(colorVolumes[LiquidColor.blue], 3);
    
    // Verify total empty slots
    int totalEmpty = 0;
    for (final container in containers) {
      totalEmpty += container.remainingCapacity;
    }
    expect(totalEmpty, emptySlots);
  });
}
