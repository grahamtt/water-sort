import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/level.dart';
import 'package:water_sort_puzzle/services/reverse_level_generator.dart';
import 'package:water_sort_puzzle/services/level_generator.dart';
import 'package:water_sort_puzzle/services/game_engine.dart';
import 'package:water_sort_puzzle/services/audio_manager.dart';

void main() {
  group('ReverseLevelGenerator', () {
    late ReverseLevelGenerator generator;
    late WaterSortGameEngine gameEngine;

    setUp(() {
      generator = ReverseLevelGenerator(
        config: const LevelGenerationConfig(
          containerCapacity: 4,
          seed: 12345, // Fixed seed for reproducibility
        ),
      );
      gameEngine = WaterSortGameEngine(
        audioManager: AudioManager(audioPlayer: MockAudioPlayer()),
      );
    });

    test('correctly handles emptySlots parameter', () {
      // colorCount=2, capacity=3, emptySlots=1
      // Total liquid = 2*3 - 1 = 5, containers needed = ceil(5/3) = 2
      // Solved state should be: |AAA|BB| (no empty containers)
      final level = generator.generateLevel(1, 3, 2, 3, 1);

      expect(level.id, 1);
      expect(level.difficulty, 3);
      expect(level.colorCount, 2);
      expect(level.containerCount, 2);
      
      // Count total empty slots
      int totalEmptySlots = 0;
      for (final container in level.initialContainers) {
        totalEmptySlots += container.remainingCapacity;
      }
      // Should have at least 1 empty slot (may have more after scrambling)
      expect(totalEmptySlots, greaterThanOrEqualTo(1));
    });

    test('generates single-color tutorial level (1 color, capacity 2, 2 empty slots)', () {
      // Tutorial case: colorCount=1, capacity=2, emptySlots=2
      // Solved state should be: |AA| | (one full container, one empty)
      // Scrambled state should be: |A|A| (split across two containers)
      final level = generator.generateLevel(1, 1, 1, 2, 2);

      expect(level.id, 1);
      expect(level.difficulty, 1);
      expect(level.colorCount, 1);
      expect(level.containerCount, 2); // 1 color + ceil(2/2) = 1 + 1 = 2
      
      // Count colors present in the level
      final colorCounts = <String, int>{};
      for (final container in level.initialContainers) {
        for (final layer in container.liquidLayers) {
          final colorName = layer.color.name;
          colorCounts[colorName] = (colorCounts[colorName] ?? 0) + layer.volume;
        }
      }
      
      // Only one color should be present
      expect(colorCounts.length, 1, reason: 'Only one color should be present in tutorial level');
      
      // Total liquid should be 2 (1*2 capacity, 2 empty slots means full container)
      final totalLiquid = colorCounts.values.fold(0, (sum, vol) => sum + vol);
      expect(totalLiquid, 2);
      
      // Should have exactly 2 empty slots total
      int totalEmptySlots = 0;
      for (final container in level.initialContainers) {
        totalEmptySlots += container.remainingCapacity;
      }
      expect(totalEmptySlots, 2);
    });

    test('preserves all colors with small capacity (2 colors, capacity 2, 1 empty slot)', () {
      // This is the specific case reported by the user
      // colorCount=2, capacity=2, emptySlots=1
      // Solved state should be: |AA|B| (no empty containers)
      final level = generator.generateLevel(1, 3, 2, 2, 1);

      expect(level.id, 1);
      expect(level.difficulty, 3);
      expect(level.colorCount, 2);
      expect(level.containerCount, 2);
      
      // Count colors present in the level
      final colorCounts = <String, int>{};
      for (final container in level.initialContainers) {
        for (final layer in container.liquidLayers) {
          final colorName = layer.color.name;
          colorCounts[colorName] = (colorCounts[colorName] ?? 0) + layer.volume;
        }
      }
      
      // Both colors must be present (not just one!)
      expect(colorCounts.length, 2, reason: 'Both colors should be present in the scrambled level');
      
      // Total liquid should be 3 (2*2 - 1)
      final totalLiquid = colorCounts.values.fold(0, (sum, vol) => sum + vol);
      expect(totalLiquid, 3);
    });

    test('actually scrambles small puzzles (not just returning solved state)', () {
      // For a very small puzzle like |AA|B|, the only valid scramble is |A|BA|
      // This test ensures the puzzle is actually scrambled, not returned as-is
      final level = generator.generateLevel(1, 3, 2, 2, 1);

      // Check that the puzzle is not in solved state
      // In solved state, each container would have only one color
      bool hasMultiColorContainer = false;
      for (final container in level.initialContainers) {
        if (container.liquidLayers.length > 1) {
          // Check if this container has multiple colors
          final colors = container.liquidLayers.map((l) => l.color).toSet();
          if (colors.length > 1) {
            hasMultiColorContainer = true;
            break;
          }
        }
      }

      // The puzzle should be scrambled (have at least one container with mixed colors)
      // OR have a different structure than the solved state
      // For |AA|B| solved, scrambled should be |A|BA| or similar
      expect(hasMultiColorContainer || level.initialContainers.any((c) => c.liquidLayers.length > 1), 
             true, 
             reason: 'Puzzle should be scrambled, not in solved state');
    });

    test('generates a valid level', () {
      // colorCount=4, capacity=4, emptySlots=4
      // emptySlots >= capacity, so we get 4 color containers + 1 empty = 5 total
      final level = generator.generateLevel(1, 3, 4, 4, 4);

      expect(level.id, 1);
      expect(level.difficulty, 3);
      expect(level.colorCount, 4);
      // 4 colors + 1 empty container (may be optimized down)
      expect(level.containerCount, greaterThanOrEqualTo(4));
      expect(level.initialContainers.length, level.containerCount);
    });

    test('generated level is structurally valid', () {
      final level = generator.generateLevel(1, 3, 4, 4, 4);

      expect(level.isStructurallyValid, true);
    });

    test('generated level is not already solved', () {
      final level = generator.generateLevel(1, 5, 4, 4, 4);

      // Initialize game state
      final gameState = gameEngine.initializeLevel(
        level.id,
        level.initialContainers,
      );

      // Level should not be in a winning state
      expect(gameEngine.checkWinCondition(gameState), false);
    });

    test('generated level has correct color distribution', () {
      // colorCount=4, capacity=4, emptySlots=4
      // emptySlots >= capacity, so each color gets full capacity (4 units)
      final level = generator.generateLevel(1, 3, 4, 4, 4);

      // Count total volume of each color
      final colorVolumes = <String, int>{};
      for (final container in level.initialContainers) {
        for (final layer in container.liquidLayers) {
          final colorName = layer.color.name;
          colorVolumes[colorName] = (colorVolumes[colorName] ?? 0) + layer.volume;
        }
      }

      // All 4 colors should be present
      expect(colorVolumes.length, 4);
      // Total liquid should be 16 (4 colors * 4 capacity)
      final totalLiquid = colorVolumes.values.fold(0, (sum, vol) => sum + vol);
      expect(totalLiquid, 16);
      // Each color should have 4 units (full capacity)
      for (final volume in colorVolumes.values) {
        expect(volume, 4);
      }
    });

    test('generated level has empty slots for moves', () {
      final level = generator.generateLevel(1, 3, 4, 4, 4);

      // Count total empty slots
      int totalEmptySlots = 0;
      for (final container in level.initialContainers) {
        totalEmptySlots += container.remainingCapacity;
      }

      // Should have empty slots for making moves (may be distributed or in empty containers)
      expect(totalEmptySlots, greaterThan(0));
    });

    test('generated level has mixed colors (not all sorted)', () {
      final level = generator.generateLevel(1, 5, 4, 4, 4);

      // Most containers should be mixed (not sorted)
      // At least some containers should have multiple layers
      int mixedContainers = 0;
      for (final container in level.initialContainers) {
        if (container.liquidLayers.length > 1) {
          mixedContainers++;
        }
      }

      expect(mixedContainers, greaterThan(0));
    });

    test('higher difficulty generates more complex levels', () {
      final easyLevel = generator.generateLevel(1, 2, 2, 4, 4);
      final hardLevel = generator.generateLevel(2, 8, 5, 4, 4);

      // Hard level should have more colors
      expect(hardLevel.colorCount, greaterThan(easyLevel.colorCount));

      // Hard level should have more mixed containers
      int easyMixed = 0;
      for (final container in easyLevel.initialContainers) {
        if (container.liquidLayers.length > 1) {
          easyMixed++;
        }
      }

      int hardMixed = 0;
      for (final container in hardLevel.initialContainers) {
        if (container.liquidLayers.length > 1) {
          hardMixed++;
        }
      }

      expect(hardMixed, greaterThanOrEqualTo(easyMixed));
    });

    test('generates a series of levels', () {
      final levels = generator.generateLevelSeries(1, 5, startDifficulty: 1);

      expect(levels.length, 5);
      expect(levels[0].id, 1);
      expect(levels[4].id, 5);

      // Each level should be valid
      for (final level in levels) {
        expect(level.isStructurallyValid, true);
      }
    });

    test('generated level does not have completed containers', () {
      final level = generator.generateLevel(1, 5, 4, 4, 4);

      // No container should be both full and sorted (completed)
      for (final container in level.initialContainers) {
        if (container.isFull) {
          expect(container.isSorted, false,
              reason: 'Full containers should not be sorted in initial state');
        }
      }
    });

    test('validates generated levels correctly', () {
      final level = generator.generateLevel(1, 3, 4, 4, 4);
      
      expect(level.isStructurallyValid, true);
      expect(generator.validateLevel(level), true);
      // Validated levels should have isValidated flag set to true
      expect(level.isValidated, true);
    });

    test('different seeds generate different levels', () {
      final gen1 = ReverseLevelGenerator(
        config: const LevelGenerationConfig(seed: 111),
      );
      final gen2 = ReverseLevelGenerator(
        config: const LevelGenerationConfig(seed: 222),
      );

      final level1 = gen1.generateLevel(1, 3, 4, 4, 4);
      final level2 = gen2.generateLevel(1, 3, 4, 4, 4);

      // Generate signatures for comparison
      String sig1 = _generateLevelSignature(level1);
      String sig2 = _generateLevelSignature(level2);

      expect(sig1, isNot(equals(sig2)));
    });

    test('same seed generates same level', () {
      final gen1 = ReverseLevelGenerator(
        config: const LevelGenerationConfig(seed: 12345),
      );
      final gen2 = ReverseLevelGenerator(
        config: const LevelGenerationConfig(seed: 12345),
      );

      final level1 = gen1.generateLevel(1, 3, 4, 4, 4);
      final level2 = gen2.generateLevel(1, 3, 4, 4, 4);

      // Generate signatures for comparison
      String sig1 = _generateLevelSignature(level1);
      String sig2 = _generateLevelSignature(level2);

      expect(sig1, equals(sig2));
    });
  });
}

/// Helper to generate a signature for a level
String _generateLevelSignature(Level level) {
  final containerSignatures = <String>[];

  for (final container in level.initialContainers) {
    if (container.isEmpty) {
      containerSignatures.add('[empty]');
    } else {
      final layerSignatures = container.liquidLayers
          .map((layer) => '${layer.color.name}:${layer.volume}')
          .join(',');
      containerSignatures.add('[$layerSignatures]');
    }
  }

  return containerSignatures.join('|');
}
