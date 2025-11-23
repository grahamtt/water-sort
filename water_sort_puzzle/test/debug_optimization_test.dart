import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/level.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/services/level_validator.dart';

void main() {
  test('Debug: Test exact puzzle from screenshot', () {
    // Recreate the exact puzzle from the screenshot
    // Container 1: Empty
    // Container 2: Full purple (4 units)
    // Container 3: Green (2) + Purple (2) - bottom to top
    // Container 4: Full green (4 units)
    
    final emptyContainer = Container(
      id: 0,
      capacity: 4,
      liquidLayers: [],
    );

    // Looking at the screenshot more carefully:
    // - Purple container has ~2-3 units (not full)
    // - Mixed container has green (2) + purple (2)
    // - Green container has ~2-3 units (not full)
    // Let's assume 2 units each for simplicity
    final purpleContainer = Container(
      id: 1,
      capacity: 4,
      liquidLayers: [
        LiquidLayer(color: LiquidColor.purple, volume: 2),
      ],
    );

    final mixedContainer = Container(
      id: 2,
      capacity: 4,
      liquidLayers: [
        LiquidLayer(color: LiquidColor.green, volume: 2),
        LiquidLayer(color: LiquidColor.purple, volume: 2),
      ],
    );

    final greenContainer = Container(
      id: 3,
      capacity: 4,
      liquidLayers: [
        LiquidLayer(color: LiquidColor.green, volume: 2),
      ],
    );

    final level = Level(
      id: 1,
      difficulty: 1,
      containerCount: 4,
      colorCount: 2,
      initialContainers: [emptyContainer, purpleContainer, mixedContainer, greenContainer],
    );

    print('Original level has ${level.containerCount} containers');
    print('Empty containers: ${level.initialContainers.where((c) => c.isEmpty).length}');
    print('Is structurally valid: ${level.isStructurallyValid}');

    // Optimize the level
    print('\n--- Starting optimization ---');
    final optimized = LevelValidator.optimizeEmptyContainers(level);

    print('Optimized level has ${optimized.containerCount} containers');
    print('Empty containers: ${optimized.initialContainers.where((c) => c.isEmpty).length}');
    print('Is structurally valid: ${optimized.isStructurallyValid}');

    // This puzzle should be solvable with 0 empty containers
    // Solution: Pour purple from mixed -> purple container, then green from mixed -> green container
    expect(optimized.containerCount, lessThan(level.containerCount),
        reason: 'Should remove the unnecessary empty container');
  });

  test('Debug: Test if level is solvable without empty container', () {
    // Test the same puzzle but without the empty container
    final purpleContainer = Container(
      id: 0,
      capacity: 4,
      liquidLayers: [
        LiquidLayer(color: LiquidColor.purple, volume: 4),
      ],
    );

    final mixedContainer = Container(
      id: 1,
      capacity: 4,
      liquidLayers: [
        LiquidLayer(color: LiquidColor.green, volume: 2),
        LiquidLayer(color: LiquidColor.purple, volume: 2),
      ],
    );

    final greenContainer = Container(
      id: 2,
      capacity: 4,
      liquidLayers: [
        LiquidLayer(color: LiquidColor.green, volume: 4),
      ],
    );

    final levelWithoutEmpty = Level(
      id: 1,
      difficulty: 1,
      containerCount: 3,
      colorCount: 2,
      initialContainers: [purpleContainer, mixedContainer, greenContainer],
    );

    print('Level without empty has ${levelWithoutEmpty.containerCount} containers');
    
    // This should be structurally valid
    expect(levelWithoutEmpty.isStructurallyValid, isTrue);
  });
}
