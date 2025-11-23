import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/services/reverse_level_generator.dart';
import 'package:water_sort_puzzle/services/level_validator.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/models/level.dart';

void main() {
  group('Debug Validation', () {
    test('Check what validation is failing', () {
      print('\n=== Attempting to generate and inspect failed levels ===');
      final generator = ReverseLevelGenerator();
      
      // Try to generate multiple times and inspect what fails
      for (int attempt = 1; attempt <= 5; attempt++) {
        print('\n--- Attempt $attempt ---');
        
        try {
          // We need to access internal generation to see what's being created
          // Let's create a simple test level manually to understand the issue
          
          // Simulate what the generator creates: a solved state
          final solvedContainers = [
            Container(
              id: 0,
              capacity: 2,
              liquidLayers: [LiquidLayer(color: LiquidColor.red, volume: 2)],
            ),
            Container(
              id: 1,
              capacity: 2,
              liquidLayers: [LiquidLayer(color: LiquidColor.blue, volume: 2)],
            ),
            Container(
              id: 2,
              capacity: 2,
              liquidLayers: [],
            ),
            Container(
              id: 3,
              capacity: 2,
              liquidLayers: [],
            ),
          ];
          
          final solvedLevel = Level(
            id: 1,
            difficulty: 1,
            containerCount: 4,
            colorCount: 2,
            initialContainers: solvedContainers,
            tags: ['test'],
          );
          
          print('Testing SOLVED state:');
          _inspectLevel(solvedLevel);
          
          // Now test a partially scrambled state
          final partiallyScrambledContainers = [
            Container(
              id: 0,
              capacity: 2,
              liquidLayers: [LiquidLayer(color: LiquidColor.red, volume: 1)],
            ),
            Container(
              id: 1,
              capacity: 2,
              liquidLayers: [
                LiquidLayer(color: LiquidColor.blue, volume: 1),
                LiquidLayer(color: LiquidColor.red, volume: 1),
              ],
            ),
            Container(
              id: 2,
              capacity: 2,
              liquidLayers: [LiquidLayer(color: LiquidColor.blue, volume: 1)],
            ),
            Container(
              id: 3,
              capacity: 2,
              liquidLayers: [],
            ),
          ];
          
          final partiallyScrambledLevel = Level(
            id: 1,
            difficulty: 1,
            containerCount: 4,
            colorCount: 2,
            initialContainers: partiallyScrambledContainers,
            tags: ['test'],
          );
          
          print('\nTesting PARTIALLY SCRAMBLED state:');
          _inspectLevel(partiallyScrambledLevel);
          
        } catch (e) {
          print('Error: $e');
        }
      }
    });
    
    test('Test actual generator output', () {
      print('\n=== Testing actual generator with custom config ===');
      
      // Create generator with custom config to see more attempts
      final generator = ReverseLevelGenerator();
      
      // Manually call internal methods if possible, or just try generating
      // with different parameters
      print('Trying with capacity 3...');
      try {
        final level = generator.generateLevel(1, 1, 4, 2, 3);
        print('✓ Success with capacity 3');
        _inspectLevel(level);
      } catch (e) {
        print('✗ Failed with capacity 3: $e');
      }
      
      print('\nTrying with capacity 4...');
      try {
        final level = generator.generateLevel(1, 1, 4, 2, 4);
        print('✓ Success with capacity 4');
        _inspectLevel(level);
      } catch (e) {
        print('✗ Failed with capacity 4: $e');
      }
    });
  });
}

void _inspectLevel(Level level) {
  print('  Level ID: ${level.id}');
  print('  Containers: ${level.containerCount}, Colors: ${level.colorCount}');
  
  // Check each container
  int emptyCount = 0;
  int sortedCount = 0;
  int fullCount = 0;
  int completedCount = 0;
  
  for (var i = 0; i < level.initialContainers.length; i++) {
    final container = level.initialContainers[i];
    
    if (container.isEmpty) {
      emptyCount++;
      print('    Container $i: [empty]');
    } else {
      final layers = container.liquidLayers
          .map((l) => '${l.color.name}:${l.volume}')
          .join(', ');
      final sorted = container.isSorted ? 'sorted' : 'mixed';
      final full = container.isFull ? 'full' : 'partial';
      print('    Container $i: [$layers] ($sorted, $full)');
      
      if (container.isSorted) sortedCount++;
      if (container.isFull) fullCount++;
      if (LevelValidator.isContainerCompleted(container)) {
        completedCount++;
        print('      ⚠️  COMPLETED CONTAINER!');
      }
    }
  }
  
  print('  Summary: $emptyCount empty, $sortedCount sorted, $fullCount full, $completedCount completed');
  
  // Run validation checks
  final isValid = LevelValidator.validateGeneratedLevel(level);
  final hasCompleted = LevelValidator.hasCompletedContainers(level);
  
  print('  Validation: ${isValid ? "✓ PASS" : "✗ FAIL"}');
  if (hasCompleted) {
    print('  ⚠️  Has completed containers');
  }
  
  // Check if already solved
  bool allSorted = true;
  for (final container in level.initialContainers) {
    if (!container.isEmpty && !container.isSorted) {
      allSorted = false;
      break;
    }
  }
  if (allSorted) {
    print('  ⚠️  All non-empty containers are sorted (already solved)');
  }
}
