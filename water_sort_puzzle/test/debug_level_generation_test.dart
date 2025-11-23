import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/services/reverse_level_generator.dart';
import 'package:water_sort_puzzle/services/level_parameters.dart';

void main() {
  group('Debug Level Generation', () {
    test('Test level parameters calculation for level 1', () {
      final difficulty = LevelParameters.calculateDifficultyForLevel(1);
      final containerCount = LevelParameters.calculateContainerCountForLevel(1);
      final colorCount = LevelParameters.calculateColorCountForLevel(1);
      final containerCapacity = LevelParameters.calculateContainerCapacity(1);
      
      print('Level 1 parameters:');
      print('  Difficulty: $difficulty');
      print('  Container Count: $containerCount');
      print('  Color Count: $colorCount');
      print('  Container Capacity: $containerCapacity');
      
      expect(difficulty, 1);
      expect(containerCount, 4);
      expect(colorCount, 2);
      expect(containerCapacity, 2);
    });

    test('Test ReverseLevelGenerator with minimal parameters', () {
      print('\n=== Testing ReverseLevelGenerator ===');
      final generator = ReverseLevelGenerator();
      
      print('Generating level 1...');
      final startTime = DateTime.now();
      
      try {
        final level = generator.generateLevel(
          1,      // levelId
          1,      // difficulty
          4,      // containerCount
          2,      // colorCount
          2,      // containerCapacity
        );
        
        final elapsed = DateTime.now().difference(startTime);
        print('✓ Level generated successfully in ${elapsed.inMilliseconds}ms');
        print('  Level ID: ${level.id}');
        print('  Containers: ${level.containerCount}');
        print('  Colors: ${level.colorCount}');
        print('  Initial state:');
        for (var i = 0; i < level.initialContainers.length; i++) {
          final container = level.initialContainers[i];
          if (container.isEmpty) {
            print('    Container $i: [empty]');
          } else {
            final layers = container.liquidLayers
                .map((l) => '${l.color.name}:${l.volume}')
                .join(', ');
            print('    Container $i: [$layers]');
          }
        }
        
        expect(level.id, 1);
        expect(level.containerCount, 4);
        expect(level.colorCount, 2);
      } catch (e, stackTrace) {
        final elapsed = DateTime.now().difference(startTime);
        print('✗ Failed after ${elapsed.inMilliseconds}ms');
        print('Error: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('Test ReverseLevelGenerator with timeout monitoring', () {
      print('\n=== Testing with detailed timeout monitoring ===');
      final generator = ReverseLevelGenerator();
      
      final startTime = DateTime.now();
      var lastCheckpoint = startTime;
      
      void checkpoint(String message) {
        final now = DateTime.now();
        final totalElapsed = now.difference(startTime).inMilliseconds;
        final sinceLastCheckpoint = now.difference(lastCheckpoint).inMilliseconds;
        print('[$totalElapsed ms] (+$sinceLastCheckpoint ms) $message');
        lastCheckpoint = now;
      }
      
      checkpoint('Starting generation');
      
      try {
        // This should complete quickly or timeout
        final level = generator.generateLevel(1, 1, 4, 2, 2);
        checkpoint('Generation completed');
        
        expect(level, isNotNull);
      } catch (e) {
        checkpoint('Generation failed: $e');
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('Test with even simpler parameters (3 containers, 2 colors)', () {
      print('\n=== Testing with 3 containers ===');
      final generator = ReverseLevelGenerator();
      
      try {
        final level = generator.generateLevel(
          1,      // levelId
          1,      // difficulty
          3,      // containerCount (minimum: 2 colors + 1 empty)
          2,      // colorCount
          2,      // containerCapacity
        );
        
        print('✓ Generated with 3 containers');
        expect(level.containerCount, 3);
      } catch (e) {
        print('✗ Failed with 3 containers: $e');
        rethrow;
      }
    }, timeout: const Timeout(Duration(seconds: 5)));
  });
}
