import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/game_state.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/services/game_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Victory Detection Tests', () {
    late WaterSortGameEngine gameEngine;
    
    setUp(() {
      gameEngine = WaterSortGameEngine();
    });
    
    group('Basic Victory Conditions', () {
      test('should detect victory when all containers have single colors', () {
        // Arrange - All containers sorted with single colors
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 4),
          ]),
          Container(id: 2, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.blue, volume: 4),
          ]),
          Container(id: 3, capacity: 4), // Empty container
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final isVictory = gameEngine.checkWinCondition(gameState);
        
        // Assert
        expect(isVictory, isTrue);
        expect(gameState.isSolved, isTrue);
      });
      
      test('should detect victory when all containers are empty', () {
        // Arrange - All containers empty
        final containers = [
          Container(id: 1, capacity: 4),
          Container(id: 2, capacity: 4),
          Container(id: 3, capacity: 4),
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final isVictory = gameEngine.checkWinCondition(gameState);
        
        // Assert
        expect(isVictory, isTrue);
        expect(gameState.isSolved, isTrue);
      });
      
      test('should detect victory with partially filled containers', () {
        // Arrange - Some containers partially filled but sorted
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 2),
          ]),
          Container(id: 2, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.blue, volume: 3),
          ]),
          Container(id: 3, capacity: 4), // Empty
          Container(id: 4, capacity: 4), // Empty
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final isVictory = gameEngine.checkWinCondition(gameState);
        
        // Assert
        expect(isVictory, isTrue);
        expect(gameState.isSolved, isTrue);
      });
    });
    
    group('Non-Victory Conditions', () {
      test('should not detect victory when containers have mixed colors', () {
        // Arrange - Containers with mixed colors
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 2),
            const LiquidLayer(color: LiquidColor.blue, volume: 2),
          ]),
          Container(id: 2, capacity: 4),
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final isVictory = gameEngine.checkWinCondition(gameState);
        
        // Assert
        expect(isVictory, isFalse);
        expect(gameState.isSolved, isFalse);
      });
      
      test('should not detect victory when colors are not optimally consolidated', () {
        // Arrange - Same color spread across multiple containers when it could fit in fewer
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 2),
          ]),
          Container(id: 2, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 2),
          ]),
          Container(id: 3, capacity: 4), // Empty - red could be consolidated here
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final isVictory = gameEngine.checkWinCondition(gameState);
        
        // Assert
        expect(isVictory, isFalse);
        expect(gameState.isSolved, isFalse);
      });
      
      test('should not detect victory when containers are not optimally filled', () {
        // Arrange - Colors not filled optimally (should fill containers completely first)
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 3),
          ]),
          Container(id: 2, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 1),
          ]),
          Container(id: 3, capacity: 4),
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final isVictory = gameEngine.checkWinCondition(gameState);
        
        // Assert
        expect(isVictory, isFalse);
        expect(gameState.isSolved, isFalse);
      });
    });
    
    group('Complex Victory Scenarios', () {
      test('should detect victory with multiple colors optimally distributed', () {
        // Arrange - Multiple colors, each optimally consolidated
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 4),
          ]),
          Container(id: 2, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 4),
          ]),
          Container(id: 3, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.blue, volume: 4),
          ]),
          Container(id: 4, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.green, volume: 2),
          ]),
          Container(id: 5, capacity: 4), // Empty
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final isVictory = gameEngine.checkWinCondition(gameState);
        
        // Assert
        expect(isVictory, isTrue);
        expect(gameState.isSolved, isTrue);
      });
      
      test('should detect victory when colors exactly fill minimum required containers', () {
        // Arrange - Colors that exactly fill the minimum number of containers needed
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 4),
          ]),
          Container(id: 2, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 4),
          ]),
          Container(id: 3, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 4),
          ]), // Total: 12 units of red = 3 full containers (optimal)
          Container(id: 4, capacity: 4),
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final isVictory = gameEngine.checkWinCondition(gameState);
        
        // Assert
        expect(isVictory, isTrue);
        expect(gameState.isSolved, isTrue);
      });
      
      test('should handle edge case with single unit volumes', () {
        // Arrange - Very small volumes that still need to be sorted
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 1),
          ]),
          Container(id: 2, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.blue, volume: 1),
          ]),
          Container(id: 3, capacity: 4),
          Container(id: 4, capacity: 4),
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final isVictory = gameEngine.checkWinCondition(gameState);
        
        // Assert
        expect(isVictory, isTrue);
        expect(gameState.isSolved, isTrue);
      });
    });
    
    group('Victory Detection During Gameplay', () {
      test('should detect victory after successful moves lead to solution', () {
        // Arrange - Start with mixed containers that require multiple moves to solve
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 1),
            const LiquidLayer(color: LiquidColor.blue, volume: 2),
            const LiquidLayer(color: LiquidColor.red, volume: 1),
          ]),
          Container(id: 2, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.blue, volume: 1),
          ]),
          Container(id: 3, capacity: 4),
          Container(id: 4, capacity: 4),
        ];
        var gameState = gameEngine.initializeLevel(1, containers);
        
        // Verify initial state is not solved
        expect(gameEngine.checkWinCondition(gameState), isFalse);
        
        // Act - Make moves to solve the puzzle step by step
        // Move top red from container 1 to container 3
        gameState = gameEngine.executePour(gameState, 1, 3);
        expect(gameEngine.checkWinCondition(gameState), isFalse); // Not solved yet
        
        // Move blue from container 1 to container 2
        gameState = gameEngine.executePour(gameState, 1, 2);
        expect(gameEngine.checkWinCondition(gameState), isFalse); // Not solved yet
        
        // Move remaining red from container 1 to container 3
        gameState = gameEngine.executePour(gameState, 1, 3);
        
        // Assert - Should now be solved
        expect(gameEngine.checkWinCondition(gameState), isTrue);
        expect(gameState.isSolved, isTrue);
        
        // Verify final state
        final container1 = gameState.getContainer(1)!;
        final container2 = gameState.getContainer(2)!;
        final container3 = gameState.getContainer(3)!;
        final container4 = gameState.getContainer(4)!;
        
        expect(container1.isEmpty, isTrue);
        expect(container2.isSorted, isTrue);
        expect(container2.topColor, equals(LiquidColor.blue));
        expect(container3.isSorted, isTrue);
        expect(container3.topColor, equals(LiquidColor.red));
        expect(container4.isEmpty, isTrue);
      });
      
      test('should not detect victory after partial solution', () {
        // Arrange
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 1),
            const LiquidLayer(color: LiquidColor.blue, volume: 1),
            const LiquidLayer(color: LiquidColor.red, volume: 1),
          ]),
          Container(id: 2, capacity: 4),
          Container(id: 3, capacity: 4),
        ];
        var gameState = gameEngine.initializeLevel(1, containers);
        
        // Act - Make partial moves
        gameState = gameEngine.executePour(gameState, 1, 2); // Move top red
        
        // Assert - Should not be solved yet (still has mixed colors in container 1)
        expect(gameEngine.checkWinCondition(gameState), isFalse);
        expect(gameState.isSolved, isFalse);
      });
      
      test('should maintain victory state after undo/redo operations', () {
        // Arrange - Start with a nearly solved state
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.blue, volume: 1),
          ]),
          Container(id: 2, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.blue, volume: 3),
          ]),
          Container(id: 3, capacity: 4),
        ];
        var gameState = gameEngine.initializeLevel(1, containers);
        
        // Act - Make winning move
        gameState = gameEngine.executePour(gameState, 1, 2);
        expect(gameEngine.checkWinCondition(gameState), isTrue);
        
        // Undo the winning move
        gameState = gameEngine.undoLastMove(gameState)!;
        expect(gameEngine.checkWinCondition(gameState), isFalse);
        
        // Redo the winning move
        gameState = gameEngine.redoNextMove(gameState)!;
        
        // Assert - Should be victory again
        expect(gameEngine.checkWinCondition(gameState), isTrue);
        expect(gameState.isSolved, isTrue);
      });
    });
    
    group('Edge Cases and Error Conditions', () {
      test('should handle empty game state gracefully', () {
        // Arrange - Empty containers list
        final containers = <Container>[];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final isVictory = gameEngine.checkWinCondition(gameState);
        
        // Assert
        expect(isVictory, isTrue); // Empty game is technically "solved"
        expect(gameState.isSolved, isTrue);
      });
      
      test('should handle single container scenarios', () {
        // Arrange - Single container with single color
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 3),
          ]),
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final isVictory = gameEngine.checkWinCondition(gameState);
        
        // Assert
        expect(isVictory, isTrue);
        expect(gameState.isSolved, isTrue);
      });
      
      test('should handle single container with mixed colors', () {
        // Arrange - Single container with mixed colors (unsolvable)
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 2),
            const LiquidLayer(color: LiquidColor.blue, volume: 2),
          ]),
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final isVictory = gameEngine.checkWinCondition(gameState);
        
        // Assert
        expect(isVictory, isFalse);
        expect(gameState.isSolved, isFalse);
      });
      
      test('should handle containers with different capacities', () {
        // Arrange - Mixed capacity containers (though our current implementation assumes uniform capacity)
        final containers = [
          Container(id: 1, capacity: 6, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 6),
          ]),
          Container(id: 2, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.blue, volume: 4),
          ]),
          Container(id: 3, capacity: 4),
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final isVictory = gameEngine.checkWinCondition(gameState);
        
        // Assert
        expect(isVictory, isTrue);
        expect(gameState.isSolved, isTrue);
      });
    });
    
    group('Performance and Consistency', () {
      test('victory detection should be consistent across multiple calls', () {
        // Arrange
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 4),
          ]),
          Container(id: 2, capacity: 4),
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act - Call victory detection multiple times
        final results = List.generate(10, (_) => gameEngine.checkWinCondition(gameState));
        
        // Assert - All results should be the same
        expect(results.every((result) => result == true), isTrue);
      });
      
      test('victory detection should handle large numbers of containers', () {
        // Arrange - Many containers, all sorted
        final containers = List.generate(20, (index) {
          if (index < 10) {
            return Container(id: index + 1, capacity: 4, liquidLayers: [
              LiquidLayer(color: LiquidColor.values[index % LiquidColor.values.length], volume: 4),
            ]);
          } else {
            return Container(id: index + 1, capacity: 4); // Empty containers
          }
        });
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final isVictory = gameEngine.checkWinCondition(gameState);
        
        // Assert
        expect(isVictory, isTrue);
        expect(gameState.isSolved, isTrue);
      });
    });
  });
}