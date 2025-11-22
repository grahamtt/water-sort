import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/game_state.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/move.dart';
import 'package:water_sort_puzzle/models/pour_result.dart';
import 'package:water_sort_puzzle/services/game_engine.dart';

void main() {
  group('WaterSortGameEngine', () {
    late WaterSortGameEngine gameEngine;
    
    setUp(() {
      gameEngine = WaterSortGameEngine();
    });
    
    group('initializeLevel', () {
      test('should create initial game state with given containers', () {
        // Arrange
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ]),
          Container(id: 2, capacity: 4),
        ];
        
        // Act
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Assert
        expect(gameState.levelId, equals(1));
        expect(gameState.containers.length, equals(2));
        expect(gameState.moveHistory, isEmpty);
        expect(gameState.isCompleted, isFalse);
        expect(gameState.moveCount, equals(0));
        expect(gameState.currentMoveIndex, equals(-1));
      });
      
      test('should create deep copies of containers', () {
        // Arrange
        final originalContainer = Container(id: 1, capacity: 4, liquidLayers: [
          LiquidLayer(color: LiquidColor.red, volume: 2),
        ]);
        final containers = [originalContainer];
        
        // Act
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Assert
        expect(gameState.containers[0], isNot(same(originalContainer)));
        expect(gameState.containers[0], equals(originalContainer));
      });
    });
    
    group('validatePour', () {
      late GameState gameState;
      
      setUp(() {
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ]),
          Container(id: 2, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ]),
          Container(id: 3, capacity: 4), // Empty container
          Container(id: 4, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 4),
          ]), // Full container
        ];
        gameState = gameEngine.initializeLevel(1, containers);
      });
      
      test('should reject pour from container to itself', () {
        // Act
        final result = gameEngine.validatePour(gameState, 1, 1);
        
        // Assert
        expect(result, isA<PourFailureSameContainer>());
        expect((result as PourFailureSameContainer).containerId, equals(1));
      });
      
      test('should reject pour from invalid source container', () {
        // Act
        final result = gameEngine.validatePour(gameState, 99, 2);
        
        // Assert
        expect(result, isA<PourFailureInvalidContainer>());
        expect((result as PourFailureInvalidContainer).containerId, equals(99));
      });
      
      test('should reject pour to invalid target container', () {
        // Act
        final result = gameEngine.validatePour(gameState, 1, 99);
        
        // Assert
        expect(result, isA<PourFailureInvalidContainer>());
        expect((result as PourFailureInvalidContainer).containerId, equals(99));
      });
      
      test('should reject pour from empty container', () {
        // Act
        final result = gameEngine.validatePour(gameState, 3, 1);
        
        // Assert
        expect(result, isA<PourFailureEmptySource>());
        expect((result as PourFailureEmptySource).containerId, equals(3));
      });
      
      test('should reject pour to full container', () {
        // Act
        final result = gameEngine.validatePour(gameState, 1, 4);
        
        // Assert
        expect(result, isA<PourFailureContainerFull>());
        expect((result as PourFailureContainerFull).containerId, equals(4));
      });
      
      test('should reject pour when colors do not match', () {
        // Arrange - Create a state where container 1 has blue on top and container 2 has red on top
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 1),
          ]),
          Container(id: 2, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ]),
        ];
        final testState = gameEngine.initializeLevel(1, containers);
        
        // Act - trying to pour blue onto red
        final result = gameEngine.validatePour(testState, 1, 2);
        
        // Assert
        expect(result, isA<PourFailureColorMismatch>());
        final failure = result as PourFailureColorMismatch;
        expect(failure.sourceColor, equals(LiquidColor.blue));
        expect(failure.targetColor, equals(LiquidColor.red));
      });
      
      test('should allow pour when colors match', () {
        // Arrange - Create a state where container 1 has blue on top and container 2 has blue on top
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 1),
          ]),
          Container(id: 2, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ]),
        ];
        final testState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final result = gameEngine.validatePour(testState, 1, 2);
        
        // Assert
        expect(result, isA<PourSuccess>());
      });
      
      test('should allow pour to empty container', () {
        // Act
        final result = gameEngine.validatePour(gameState, 1, 3);
        
        // Assert
        expect(result, isA<PourSuccess>());
      });
      
      test('should reject pour when insufficient capacity', () {
        // Arrange - Create containers where pour would exceed capacity
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 3),
          ]),
          Container(id: 2, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 1),
          ]),
        ];
        final testState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final result = gameEngine.validatePour(testState, 1, 2);
        
        // Assert
        expect(result, isA<PourFailureInsufficientCapacity>());
        final failure = result as PourFailureInsufficientCapacity;
        expect(failure.containerId, equals(2));
        expect(failure.attemptedVolume, equals(3));
        expect(failure.availableCapacity, equals(1));
      });
    });
    
    group('executePour', () {
      test('should execute valid pour and update game state', () {
        // Arrange
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 1),
          ]),
          Container(id: 2, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ]),
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final newState = gameEngine.executePour(gameState, 1, 2);
        
        // Assert
        expect(newState.moveCount, equals(1));
        expect(newState.currentMoveIndex, equals(0));
        expect(newState.moveHistory.length, equals(1));
        
        // Check that liquid was moved correctly
        final sourceContainer = newState.getContainer(1)!;
        final targetContainer = newState.getContainer(2)!;
        
        expect(sourceContainer.currentVolume, equals(2)); // Lost 1 blue
        expect(targetContainer.currentVolume, equals(3)); // Gained 1 blue
        expect(targetContainer.topColor, equals(LiquidColor.blue));
      });
      
      test('should throw error when trying to execute invalid pour', () {
        // Arrange
        final containers = [
          Container(id: 1, capacity: 4),
          Container(id: 2, capacity: 4),
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act & Assert
        expect(
          () => gameEngine.executePour(gameState, 1, 2),
          throwsArgumentError,
        );
      });
      
      test('should preserve original game state when executing pour', () {
        // Arrange
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ]),
          Container(id: 2, capacity: 4),
        ];
        final originalState = gameEngine.initializeLevel(1, containers);
        final originalVolume = originalState.getContainer(1)!.currentVolume;
        
        // Act
        final newState = gameEngine.executePour(originalState, 1, 2);
        
        // Assert
        expect(originalState.getContainer(1)!.currentVolume, equals(originalVolume));
        expect(newState.getContainer(1)!.currentVolume, equals(0));
      });
    });
    
    group('attemptPour', () {
      test('should return success result for valid pour', () {
        // Arrange
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ]),
          Container(id: 2, capacity: 4),
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final result = gameEngine.attemptPour(gameState, 1, 2);
        
        // Assert
        expect(result, isA<PourSuccess>());
        final success = result as PourSuccess;
        expect(success.move.fromContainerId, equals(1));
        expect(success.move.toContainerId, equals(2));
        expect(success.move.liquidMoved.color, equals(LiquidColor.blue));
        expect(success.move.liquidMoved.volume, equals(2));
      });
      
      test('should return failure result for invalid pour', () {
        // Arrange
        final containers = [
          Container(id: 1, capacity: 4),
          Container(id: 2, capacity: 4),
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final result = gameEngine.attemptPour(gameState, 1, 2);
        
        // Assert
        expect(result, isA<PourFailureEmptySource>());
      });
    });
    
    group('checkWinCondition', () {
      test('should return true when all containers are sorted', () {
        // Arrange - All containers have single colors or are empty
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 4),
          ]),
          Container(id: 2, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 4),
          ]),
          Container(id: 3, capacity: 4), // Empty is OK
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final isWin = gameEngine.checkWinCondition(gameState);
        
        // Assert
        expect(isWin, isTrue);
      });
      
      test('should return false when containers have mixed colors', () {
        // Arrange
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ]),
          Container(id: 2, capacity: 4),
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final isWin = gameEngine.checkWinCondition(gameState);
        
        // Assert
        expect(isWin, isFalse);
      });
      
      test('should return true for all empty containers', () {
        // Arrange
        final containers = [
          Container(id: 1, capacity: 4),
          Container(id: 2, capacity: 4),
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final isWin = gameEngine.checkWinCondition(gameState);
        
        // Assert
        expect(isWin, isTrue);
      });
    });
    
    group('undoLastMove', () {
      test('should undo last move and restore previous state', () {
        // Arrange
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ]),
          Container(id: 2, capacity: 4),
        ];
        final initialState = gameEngine.initializeLevel(1, containers);
        final afterPourState = gameEngine.executePour(initialState, 1, 2);
        
        // Act
        final undoneState = gameEngine.undoLastMove(afterPourState);
        
        // Assert
        expect(undoneState, isNotNull);
        expect(undoneState!.currentMoveIndex, equals(-1));
        expect(undoneState.getContainer(1)!.currentVolume, equals(2));
        expect(undoneState.getContainer(2)!.currentVolume, equals(0));
      });
      
      test('should return null when no moves to undo', () {
        // Arrange
        final containers = [
          Container(id: 1, capacity: 4),
          Container(id: 2, capacity: 4),
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final result = gameEngine.undoLastMove(gameState);
        
        // Assert
        expect(result, isNull);
      });
    });
    
    group('redoNextMove', () {
      test('should redo next move after undo', () {
        // Arrange
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ]),
          Container(id: 2, capacity: 4),
        ];
        final initialState = gameEngine.initializeLevel(1, containers);
        final afterPourState = gameEngine.executePour(initialState, 1, 2);
        final undoneState = gameEngine.undoLastMove(afterPourState)!;
        
        // Act
        final redoneState = gameEngine.redoNextMove(undoneState);
        
        // Assert
        expect(redoneState, isNotNull);
        expect(redoneState!.currentMoveIndex, equals(0));
        expect(redoneState.getContainer(1)!.currentVolume, equals(0));
        expect(redoneState.getContainer(2)!.currentVolume, equals(2));
      });
      
      test('should return null when no moves to redo', () {
        // Arrange
        final containers = [
          Container(id: 1, capacity: 4),
          Container(id: 2, capacity: 4),
        ];
        final gameState = gameEngine.initializeLevel(1, containers);
        
        // Act
        final result = gameEngine.redoNextMove(gameState);
        
        // Assert
        expect(result, isNull);
      });
    });
    
    group('undo/redo edge cases', () {
      test('should handle multiple consecutive undos correctly', () {
        // Arrange - Create a state with multiple moves to empty containers
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 1),
            LiquidLayer(color: LiquidColor.blue, volume: 1),
            LiquidLayer(color: LiquidColor.green, volume: 1),
          ]),
          Container(id: 2, capacity: 4),
          Container(id: 3, capacity: 4),
          Container(id: 4, capacity: 4),
        ];
        var gameState = gameEngine.initializeLevel(1, containers);
        
        // Make three moves to different empty containers
        gameState = gameEngine.executePour(gameState, 1, 2); // Move green to empty container 2
        gameState = gameEngine.executePour(gameState, 1, 3); // Move blue to empty container 3
        gameState = gameEngine.executePour(gameState, 1, 4); // Move red to empty container 4
        
        expect(gameState.moveCount, equals(3));
        expect(gameState.currentMoveIndex, equals(2));
        expect(gameState.getContainer(1)!.isEmpty, isTrue);
        
        // Undo all moves one by one
        gameState = gameEngine.undoLastMove(gameState)!; // Undo red move
        expect(gameState.currentMoveIndex, equals(1));
        expect(gameState.getContainer(1)!.topColor, equals(LiquidColor.red));
        expect(gameState.getContainer(4)!.isEmpty, isTrue);
        
        gameState = gameEngine.undoLastMove(gameState)!; // Undo blue move
        expect(gameState.currentMoveIndex, equals(0));
        expect(gameState.getContainer(1)!.topColor, equals(LiquidColor.blue));
        expect(gameState.getContainer(3)!.isEmpty, isTrue);
        
        gameState = gameEngine.undoLastMove(gameState)!; // Undo green move
        expect(gameState.currentMoveIndex, equals(-1));
        expect(gameState.getContainer(1)!.topColor, equals(LiquidColor.green));
        expect(gameState.getContainer(2)!.isEmpty, isTrue);
        
        // Should not be able to undo further
        final result = gameEngine.undoLastMove(gameState);
        expect(result, isNull);
      });
      
      test('should handle multiple consecutive redos correctly', () {
        // Arrange - Create state with moves to empty containers, then undo them all
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ]),
          Container(id: 2, capacity: 4),
          Container(id: 3, capacity: 4),
        ];
        var gameState = gameEngine.initializeLevel(1, containers);
        
        // Make two moves to different empty containers then undo them
        gameState = gameEngine.executePour(gameState, 1, 2); // Move blue to empty container 2
        gameState = gameEngine.executePour(gameState, 1, 3); // Move red to empty container 3
        gameState = gameEngine.undoLastMove(gameState)!; // Undo red
        gameState = gameEngine.undoLastMove(gameState)!; // Undo blue
        
        expect(gameState.currentMoveIndex, equals(-1));
        expect(gameState.canRedo, isTrue);
        expect(gameState.redoableMovesCount, equals(2));
        
        // Redo both moves
        gameState = gameEngine.redoNextMove(gameState)!; // Redo blue
        expect(gameState.currentMoveIndex, equals(0));
        expect(gameState.getContainer(2)!.topColor, equals(LiquidColor.blue));
        
        gameState = gameEngine.redoNextMove(gameState)!; // Redo red
        expect(gameState.currentMoveIndex, equals(1));
        expect(gameState.getContainer(3)!.topColor, equals(LiquidColor.red));
        expect(gameState.getContainer(1)!.isEmpty, isTrue);
        
        // Should not be able to redo further
        final result = gameEngine.redoNextMove(gameState);
        expect(result, isNull);
      });
      
      test('should handle undo after partial redo correctly', () {
        // Arrange - Use containers where we can pour matching colors
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 1),
            LiquidLayer(color: LiquidColor.blue, volume: 1),
            LiquidLayer(color: LiquidColor.green, volume: 1),
          ]),
          Container(id: 2, capacity: 4),
          Container(id: 3, capacity: 4),
          Container(id: 4, capacity: 4),
        ];
        var gameState = gameEngine.initializeLevel(1, containers);
        
        // Make three moves to different empty containers
        gameState = gameEngine.executePour(gameState, 1, 2); // Move green to empty container 2
        gameState = gameEngine.executePour(gameState, 1, 3); // Move blue to empty container 3
        gameState = gameEngine.executePour(gameState, 1, 4); // Move red to empty container 4
        
        // Undo all moves
        gameState = gameEngine.undoLastMove(gameState)!;
        gameState = gameEngine.undoLastMove(gameState)!;
        gameState = gameEngine.undoLastMove(gameState)!;
        
        // Redo only first two moves
        gameState = gameEngine.redoNextMove(gameState)!; // Redo green
        gameState = gameEngine.redoNextMove(gameState)!; // Redo blue
        
        expect(gameState.currentMoveIndex, equals(1));
        expect(gameState.canRedo, isTrue); // Can still redo red move
        expect(gameState.canUndo, isTrue); // Can undo blue move
        
        // Now undo one move
        gameState = gameEngine.undoLastMove(gameState)!; // Undo blue
        expect(gameState.currentMoveIndex, equals(0));
        expect(gameState.getContainer(1)!.topColor, equals(LiquidColor.blue));
        expect(gameState.getContainer(2)!.topColor, equals(LiquidColor.green));
        expect(gameState.getContainer(3)!.isEmpty, isTrue); // Blue was undone
        expect(gameState.canRedo, isTrue); // Can redo blue and red
        expect(gameState.redoableMovesCount, equals(2));
      });
      
      test('should handle new move after undo truncating redo history', () {
        // Arrange
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ]),
          Container(id: 2, capacity: 4),
          Container(id: 3, capacity: 4),
        ];
        var gameState = gameEngine.initializeLevel(1, containers);
        
        // Make two moves
        gameState = gameEngine.executePour(gameState, 1, 2); // Move red to 2
        gameState = gameEngine.executePour(gameState, 2, 3); // Move red to 3
        
        expect(gameState.moveHistory.length, equals(2));
        
        // Undo one move
        gameState = gameEngine.undoLastMove(gameState)!;
        expect(gameState.currentMoveIndex, equals(0));
        expect(gameState.canRedo, isTrue);
        
        // Make a different move - should truncate redo history
        gameState = gameEngine.executePour(gameState, 2, 1); // Move red back to 1
        
        expect(gameState.moveHistory.length, equals(2)); // Original move + new move
        expect(gameState.currentMoveIndex, equals(1));
        expect(gameState.canRedo, isFalse); // No more redo possible
        expect(gameState.redoableMovesCount, equals(0));
        
        // Verify the state is correct
        expect(gameState.getContainer(1)!.topColor, equals(LiquidColor.red));
        expect(gameState.getContainer(2)!.isEmpty, isTrue);
        expect(gameState.getContainer(3)!.isEmpty, isTrue);
      });
      
      test('should preserve move timestamps during undo/redo', () {
        // Arrange
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ]),
          Container(id: 2, capacity: 4),
        ];
        var gameState = gameEngine.initializeLevel(1, containers);
        
        // Make a move and capture timestamp
        gameState = gameEngine.executePour(gameState, 1, 2);
        final originalTimestamp = gameState.moveHistory.first.timestamp;
        
        // Undo and redo
        gameState = gameEngine.undoLastMove(gameState)!;
        gameState = gameEngine.redoNextMove(gameState)!;
        
        // Timestamp should be preserved
        expect(gameState.moveHistory.first.timestamp, equals(originalTimestamp));
      });
      
      test('should handle complex liquid layer reconstruction correctly', () {
        // Arrange - Complex scenario with multiple liquid layers
        final containers = [
          Container(id: 1, capacity: 6, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 2),
            LiquidLayer(color: LiquidColor.red, volume: 1),
          ]),
          Container(id: 2, capacity: 6, liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 1),
          ]),
          Container(id: 3, capacity: 6),
        ];
        var gameState = gameEngine.initializeLevel(1, containers);
        
        // Make moves that involve partial layer transfers
        gameState = gameEngine.executePour(gameState, 1, 3); // Move top red (1 unit) to empty container
        expect(gameState.getContainer(1)!.topColor, equals(LiquidColor.blue));
        expect(gameState.getContainer(3)!.topColor, equals(LiquidColor.red));
        
        gameState = gameEngine.executePour(gameState, 1, 2); // Move blue (2 units) to container with blue
        expect(gameState.getContainer(1)!.topColor, equals(LiquidColor.red));
        expect(gameState.getContainer(2)!.currentVolume, equals(3)); // 1 + 2 blue
        
        // Undo both moves
        gameState = gameEngine.undoLastMove(gameState)!; // Undo blue transfer
        expect(gameState.getContainer(1)!.topColor, equals(LiquidColor.blue));
        expect(gameState.getContainer(1)!.currentVolume, equals(4)); // Back to 2 red + 2 blue (red was already moved)
        expect(gameState.getContainer(2)!.currentVolume, equals(1)); // Back to 1 blue
        
        gameState = gameEngine.undoLastMove(gameState)!; // Undo red transfer
        expect(gameState.getContainer(1)!.topColor, equals(LiquidColor.red));
        expect(gameState.getContainer(1)!.currentVolume, equals(5)); // Back to original
        expect(gameState.getContainer(3)!.isEmpty, isTrue); // Back to empty
        
        // Verify exact layer structure is restored
        final container1 = gameState.getContainer(1)!;
        expect(container1.liquidLayers.length, equals(3));
        expect(container1.liquidLayers[0].color, equals(LiquidColor.red));
        expect(container1.liquidLayers[0].volume, equals(2));
        expect(container1.liquidLayers[1].color, equals(LiquidColor.blue));
        expect(container1.liquidLayers[1].volume, equals(2));
        expect(container1.liquidLayers[2].color, equals(LiquidColor.red));
        expect(container1.liquidLayers[2].volume, equals(1));
      });
      
      test('should validate undo/redo state consistency', () {
        // Arrange
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ]),
          Container(id: 2, capacity: 4),
        ];
        var gameState = gameEngine.initializeLevel(1, containers);
        
        // Test state consistency flags
        expect(gameState.canUndo, isFalse);
        expect(gameState.canRedo, isFalse);
        expect(gameState.undoableMovesCount, equals(0));
        expect(gameState.redoableMovesCount, equals(0));
        
        // Make a move
        gameState = gameEngine.executePour(gameState, 1, 2);
        expect(gameState.canUndo, isTrue);
        expect(gameState.canRedo, isFalse);
        expect(gameState.undoableMovesCount, equals(1));
        expect(gameState.redoableMovesCount, equals(0));
        
        // Undo the move
        gameState = gameEngine.undoLastMove(gameState)!;
        expect(gameState.canUndo, isFalse);
        expect(gameState.canRedo, isTrue);
        expect(gameState.undoableMovesCount, equals(0));
        expect(gameState.redoableMovesCount, equals(1));
        
        // Redo the move
        gameState = gameEngine.redoNextMove(gameState)!;
        expect(gameState.canUndo, isTrue);
        expect(gameState.canRedo, isFalse);
        expect(gameState.undoableMovesCount, equals(1));
        expect(gameState.redoableMovesCount, equals(0));
      });
    });
    
    group('complex game scenarios', () {
      test('should handle multiple moves with undo/redo correctly', () {
        // Arrange - simpler scenario
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ]),
          Container(id: 2, capacity: 4),
          Container(id: 3, capacity: 4),
        ];
        var gameState = gameEngine.initializeLevel(1, containers);
        
        // Act - Make moves
        gameState = gameEngine.executePour(gameState, 1, 2); // Move blue from 1 to 2
        expect(gameState.moveCount, equals(1));
        expect(gameState.getContainer(1)!.currentVolume, equals(0));
        expect(gameState.getContainer(2)!.currentVolume, equals(2));
        
        gameState = gameEngine.executePour(gameState, 2, 3); // Move blue from 2 to 3
        expect(gameState.moveCount, equals(2));
        expect(gameState.getContainer(2)!.currentVolume, equals(0));
        expect(gameState.getContainer(3)!.currentVolume, equals(2));
        
        // Undo the last move (2->3)
        gameState = gameEngine.undoLastMove(gameState)!;
        expect(gameState.currentMoveIndex, equals(0)); // Back to after first move
        expect(gameState.moveCount, equals(2)); // Move count doesn't change on undo
        expect(gameState.getContainer(1)!.currentVolume, equals(0)); // Still empty
        expect(gameState.getContainer(2)!.currentVolume, equals(2)); // Blue back in 2
        expect(gameState.getContainer(3)!.currentVolume, equals(0)); // 3 is empty again
        
        // Make a different move
        gameState = gameEngine.executePour(gameState, 2, 1); // Move blue back to 1
        
        // Assert final state
        expect(gameState.moveCount, equals(3)); // New move added
        expect(gameState.currentMoveIndex, equals(1)); // Now at index 1 (truncated history)
        expect(gameState.moveHistory.length, equals(2)); // History truncated after undo+new move
        expect(gameState.getContainer(1)!.currentVolume, equals(2)); // Blue back in 1
        expect(gameState.getContainer(2)!.currentVolume, equals(0)); // 2 is empty
        expect(gameState.getContainer(3)!.currentVolume, equals(0)); // 3 is still empty
      });
      
      test('should detect win condition after series of moves', () {
        // Arrange - Simple puzzle that can be solved
        final containers = [
          Container(id: 1, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ]),
          Container(id: 2, capacity: 4, liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ]),
          Container(id: 3, capacity: 4),
          Container(id: 4, capacity: 4),
        ];
        var gameState = gameEngine.initializeLevel(1, containers);
        
        // Act - Solve the puzzle step by step
        gameState = gameEngine.executePour(gameState, 1, 3); // Move blue from 1 to empty 3
        gameState = gameEngine.executePour(gameState, 2, 3); // Move blue from 2 to 3 (matching colors)
        gameState = gameEngine.executePour(gameState, 1, 4); // Move red from 1 to empty 4
        gameState = gameEngine.executePour(gameState, 2, 4); // Move red from 2 to 4 (matching colors)
        
        // Assert - Now all containers should be sorted
        expect(gameEngine.checkWinCondition(gameState), isTrue);
        
        // Verify the final state
        final container1 = gameState.getContainer(1)!;
        final container2 = gameState.getContainer(2)!;
        final container3 = gameState.getContainer(3)!;
        final container4 = gameState.getContainer(4)!;
        
        expect(container1.isEmpty, isTrue);
        expect(container2.isEmpty, isTrue);
        expect(container3.isSorted, isTrue);
        expect(container4.isSorted, isTrue);
        expect(container3.topColor, equals(LiquidColor.blue));
        expect(container4.topColor, equals(LiquidColor.red));
      });
    });
  });
}