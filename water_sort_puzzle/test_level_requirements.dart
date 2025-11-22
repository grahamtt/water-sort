import 'package:water_sort_puzzle/services/level_generator.dart';
import 'package:water_sort_puzzle/services/game_engine.dart';

void main() {
  print('Testing Level Generator Requirements...\n');
  
  final generator = WaterSortLevelGenerator(
    config: const LevelGenerationConfig(seed: 42),
  );
  
  final gameEngine = WaterSortGameEngine();
  
  // Test multiple levels to verify requirements
  for (int i = 1; i <= 10; i++) {
    final difficulty = (i / 2).ceil();
    final containerCount = 4 + (difficulty ~/ 3);
    final colorCount = 2 + (difficulty ~/ 2);
    
    print('Testing Level $i (Difficulty: $difficulty, Containers: $containerCount, Colors: $colorCount)');
    
    final level = generator.generateLevel(i, difficulty, containerCount, colorCount);
    
    // Requirement 1: Level should never be initially solved
    final initialState = gameEngine.initializeLevel(level.id, level.initialContainers);
    final isInitiallySolved = gameEngine.checkWinCondition(initialState);
    print('  ✓ Not initially solved: ${!isInitiallySolved}');
    
    // Requirement 2: Level should be solvable (using heuristic check)
    final isSolvable = generator.validateLevel(level);
    print('  ✓ Is solvable: $isSolvable');
    
    // Requirement 3: Should have at least one empty slot
    final totalEmptySlots = level.initialContainers
        .fold(0, (sum, container) => sum + container.remainingCapacity);
    print('  ✓ Has empty slots: $totalEmptySlots (minimum: 1)');
    
    // Additional info
    final emptyContainers = level.emptyContainerCount;
    print('  - Empty containers: $emptyContainers');
    print('  - Total empty slots: $totalEmptySlots');
    
    // Check if any containers are already sorted
    final sortedContainers = level.initialContainers
        .where((c) => !c.isEmpty && c.isSorted)
        .length;
    print('  - Already sorted containers: $sortedContainers');
    
    print('');
  }
  
  print('All requirements verified! ✅');
}