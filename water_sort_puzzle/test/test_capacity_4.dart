import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/services/reverse_level_generator.dart';

void main() {
  test('Test capacity 4 generation', () {
    print('Testing with capacity 4...');
    final generator = ReverseLevelGenerator();
    
    final startTime = DateTime.now();
    try {
      final level = generator.generateLevel(
        1,      // levelId
        1,      // difficulty
        4,      // containerCount
        2,      // colorCount
        4,      // containerCapacity
      );
      
      final elapsed = DateTime.now().difference(startTime);
      print('✓ Generated in ${elapsed.inMilliseconds}ms');
      print('  Containers: ${level.containerCount}');
      print('  Colors: ${level.colorCount}');
      
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
      
      expect(level, isNotNull);
    } catch (e, stackTrace) {
      final elapsed = DateTime.now().difference(startTime);
      print('✗ Failed after ${elapsed.inMilliseconds}ms');
      print('Error: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }, timeout: const Timeout(Duration(seconds: 10)));
}
