import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/services/reverse_level_generator.dart';
import 'package:water_sort_puzzle/services/level_parameters.dart';

void main() {
  test('Test game start with level 1', () {
    print('Simulating game start for level 1...');
    final generator = ReverseLevelGenerator();
    
    // Calculate parameters the same way GameStateProvider does
    final levelId = 1;
    final difficulty = LevelParameters.calculateDifficultyForLevel(levelId);
    final colorCount = LevelParameters.calculateColorCountForLevel(levelId);
    final containerCapacity = LevelParameters.calculateContainerCapacity(levelId);
    final emptySlots = LevelParameters.calculateEmptySlotsForLevel(levelId);
    
    print('Level 1 parameters:');
    print('  Difficulty: $difficulty');
    print('  Color Count: $colorCount');
    print('  Container Capacity: $containerCapacity');
    print('  Empty Slots: $emptySlots');
    
    final startTime = DateTime.now();
    try {
      final level = generator.generateLevel(
        levelId,
        difficulty,
        colorCount,
        containerCapacity,
        emptySlots,
      );
      
      final elapsed = DateTime.now().difference(startTime);
      print('\n✓ Level generated successfully in ${elapsed.inMilliseconds}ms');
      print('  Final container count: ${level.containerCount}');
      print('  Level state:');
      
      for (var i = 0; i < level.initialContainers.length; i++) {
        final container = level.initialContainers[i];
        if (container.isEmpty) {
          print('    Container $i: [empty]');
        } else {
          final layers = container.liquidLayers
              .map((l) => '${l.color.name}:${l.volume}')
              .join(', ');
          final status = container.isSorted ? 'sorted' : 'mixed';
          print('    Container $i: [$layers] ($status)');
        }
      }
      
      expect(level, isNotNull);
      expect(level.id, levelId);
    } catch (e, stackTrace) {
      final elapsed = DateTime.now().difference(startTime);
      print('\n✗ Failed after ${elapsed.inMilliseconds}ms');
      print('Error: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }, timeout: const Timeout(Duration(seconds: 10)));
  
  test('Test multiple level generations', () {
    print('\nTesting multiple level generations...');
    final generator = ReverseLevelGenerator();
    
    for (int levelId = 1; levelId <= 5; levelId++) {
      final difficulty = LevelParameters.calculateDifficultyForLevel(levelId);
      final colorCount = LevelParameters.calculateColorCountForLevel(levelId);
      final containerCapacity = LevelParameters.calculateContainerCapacity(levelId);
      final emptySlots = LevelParameters.calculateEmptySlotsForLevel(levelId);
      
      final startTime = DateTime.now();
      try {
        final level = generator.generateLevel(
          levelId,
          difficulty,
          colorCount,
          containerCapacity,
          emptySlots,
        );
        
        final elapsed = DateTime.now().difference(startTime);
        print('Level $levelId: ✓ Generated in ${elapsed.inMilliseconds}ms (${level.containerCount} containers)');
      } catch (e) {
        final elapsed = DateTime.now().difference(startTime);
        print('Level $levelId: ✗ Failed after ${elapsed.inMilliseconds}ms - $e');
        rethrow;
      }
    }
  }, timeout: const Timeout(Duration(seconds: 30)));
}
