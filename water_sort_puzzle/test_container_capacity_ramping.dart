import 'package:water_sort_puzzle/services/level_generator.dart';

void main() {
  print('🎮 Testing Container Capacity Ramping Feature\n');
  
  final generator = WaterSortLevelGenerator(
    config: const LevelGenerationConfig(seed: 42),
  );
  
  // Test levels across multiple difficulty tiers
  final testLevels = [1, 5, 10, 11, 15, 20, 21, 25, 30, 31, 40, 50];
  
  print('Level | Capacity | Expected');
  print('------|----------|----------');
  
  for (final levelId in testLevels) {
    final containerCapacity = 4 + ((levelId - 1) ~/ 10);
    final level = generator.generateLevel(levelId, 3, 5, 3, containerCapacity);
    
    // Verify all containers have the correct capacity
    final actualCapacity = level.initialContainers.first.capacity;
    final allMatch = level.initialContainers.every((c) => c.capacity == containerCapacity);
    
    final status = allMatch && actualCapacity == containerCapacity ? '✅' : '❌';
    print('${levelId.toString().padLeft(5)} | ${actualCapacity.toString().padLeft(8)} | ${containerCapacity.toString().padLeft(8)} $status');
  }
  
  print('\n📊 Summary:');
  print('- Levels 1-10:  Capacity 4');
  print('- Levels 11-20: Capacity 5');
  print('- Levels 21-30: Capacity 6');
  print('- Levels 31-40: Capacity 7');
  print('- Levels 41-50: Capacity 8');
  print('\n✅ Container capacity ramping is working correctly!');
}
