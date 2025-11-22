import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/container.dart' as models;
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/game_state.dart';
import 'package:water_sort_puzzle/services/game_engine.dart';

void main() {
  group('Win Condition Logic', () {
    test('should NOT be solved when colors are split across containers', () {
      // This scenario should NOT be considered solved:
      // Container 1: 2 green
      // Container 2: 2 green  
      // Even though each container has only one color, green is not consolidated
      final containers = [
        models.Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.green, volume: 2),
          ],
        ),
        models.Container(
          id: 2,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.green, volume: 2),
          ],
        ),
        models.Container(id: 3, capacity: 4, liquidLayers: []),
      ];
      
      final gameEngine = WaterSortGameEngine();
      final gameState = gameEngine.initializeLevel(1, containers);
      
      print('=== SPLIT COLORS TEST ===');
      print('Container 1: 2 green');
      print('Container 2: 2 green');
      print('Container 3: empty');
      print('Should be solved: ${gameState.isSolved}');
      
      // This should NOT be solved because green is split across 2 containers
      // when it could be consolidated into 1 container
      expect(gameState.isSolved, isFalse, reason: 'Green should be consolidated into one container');
    });
    
    test('should be solved when colors are properly consolidated', () {
      // This scenario SHOULD be considered solved:
      // Container 1: 4 green (full)
      // Container 2: empty
      final containers = [
        models.Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.green, volume: 4),
          ],
        ),
        models.Container(id: 2, capacity: 4, liquidLayers: []),
      ];
      
      final gameEngine = WaterSortGameEngine();
      final gameState = gameEngine.initializeLevel(1, containers);
      
      print('\n=== PROPERLY CONSOLIDATED TEST ===');
      print('Container 1: 4 green (full)');
      print('Container 2: empty');
      print('Should be solved: ${gameState.isSolved}');
      
      // This should be solved because green is properly consolidated
      expect(gameState.isSolved, isTrue, reason: 'Green is properly consolidated');
    });
    
    test('should be solved when multiple colors are properly consolidated', () {
      // This scenario SHOULD be considered solved:
      // Container 1: 4 red (full)
      // Container 2: 4 blue (full)  
      // Container 3: 2 green (partial, but no other green exists)
      // Container 4: empty
      final containers = [
        models.Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 4),
          ],
        ),
        models.Container(
          id: 2,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.blue, volume: 4),
          ],
        ),
        models.Container(
          id: 3,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.green, volume: 2),
          ],
        ),
        models.Container(id: 4, capacity: 4, liquidLayers: []),
      ];
      
      final gameEngine = WaterSortGameEngine();
      final gameState = gameEngine.initializeLevel(1, containers);
      
      print('\n=== MULTIPLE COLORS CONSOLIDATED TEST ===');
      print('Container 1: 4 red (full)');
      print('Container 2: 4 blue (full)');
      print('Container 3: 2 green (partial, but all green is here)');
      print('Container 4: empty');
      print('Should be solved: ${gameState.isSolved}');
      
      // This should be solved because each color is properly consolidated
      expect(gameState.isSolved, isTrue, reason: 'All colors are properly consolidated');
    });
    
    test('should NOT be solved when containers have mixed colors', () {
      // This scenario should NOT be considered solved:
      // Container 1: red + blue (mixed)
      // Container 2: green
      final containers = [
        models.Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 2),
            const LiquidLayer(color: LiquidColor.blue, volume: 1),
          ],
        ),
        models.Container(
          id: 2,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.green, volume: 2),
          ],
        ),
      ];
      
      final gameEngine = WaterSortGameEngine();
      final gameState = gameEngine.initializeLevel(1, containers);
      
      print('\n=== MIXED COLORS TEST ===');
      print('Container 1: red + blue (mixed)');
      print('Container 2: green');
      print('Should be solved: ${gameState.isSolved}');
      
      // This should NOT be solved because container 1 has mixed colors
      expect(gameState.isSolved, isFalse, reason: 'Container 1 has mixed colors');
    });
    
    test('should handle large volumes requiring multiple containers', () {
      // This scenario SHOULD be considered solved:
      // Container 1: 4 red (full)
      // Container 2: 4 red (full)
      // Container 3: 2 red (partial, but this is optimal for 10 total red)
      // Container 4: empty
      final containers = [
        models.Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 4),
          ],
        ),
        models.Container(
          id: 2,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 4),
          ],
        ),
        models.Container(
          id: 3,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        ),
        models.Container(id: 4, capacity: 4, liquidLayers: []),
      ];
      
      final gameEngine = WaterSortGameEngine();
      final gameState = gameEngine.initializeLevel(1, containers);
      
      print('\n=== LARGE VOLUME TEST ===');
      print('Container 1: 4 red (full)');
      print('Container 2: 4 red (full)');
      print('Container 3: 2 red (partial, but optimal for 10 total)');
      print('Container 4: empty');
      print('Total red: 10 units, needs 3 containers minimum');
      print('Should be solved: ${gameState.isSolved}');
      
      // This should be solved because 10 units of red optimally needs 3 containers
      // (4 + 4 + 2), and the containers are filled optimally (full ones first)
      expect(gameState.isSolved, isTrue, reason: 'Red is optimally consolidated across 3 containers');
    });
    
    test('should NOT be solved when large volumes are not optimally filled', () {
      // This scenario should NOT be considered solved:
      // Container 1: 3 red (not full)
      // Container 2: 4 red (full)
      // Container 3: 3 red (not full)
      // Container 4: empty
      // Total: 10 red, but not optimally arranged
      final containers = [
        models.Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 3),
          ],
        ),
        models.Container(
          id: 2,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 4),
          ],
        ),
        models.Container(
          id: 3,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 3),
          ],
        ),
        models.Container(id: 4, capacity: 4, liquidLayers: []),
      ];
      
      final gameEngine = WaterSortGameEngine();
      final gameState = gameEngine.initializeLevel(1, containers);
      
      print('\n=== NON-OPTIMAL FILLING TEST ===');
      print('Container 1: 3 red (not full)');
      print('Container 2: 4 red (full)');
      print('Container 3: 3 red (not full)');
      print('Container 4: empty');
      print('Total red: 10 units, but not optimally arranged');
      print('Should be solved: ${gameState.isSolved}');
      
      // This should NOT be solved because containers 1 and 3 are not full
      // when they could be consolidated better (4+4+2 arrangement)
      expect(gameState.isSolved, isFalse, reason: 'Red is not optimally arranged - should be 4+4+2, not 3+4+3');
    });
  });
}