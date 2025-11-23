import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/container.dart' as models;
import 'package:water_sort_puzzle/models/game_state.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/pour_result.dart';
import 'package:water_sort_puzzle/models/move.dart';
import 'package:water_sort_puzzle/services/game_engine.dart';
import 'package:water_sort_puzzle/widgets/game_board_widget.dart';
import 'package:water_sort_puzzle/widgets/container_widget.dart';

/// Mock game engine for testing
class MockGameEngine implements GameEngine {
  bool shouldValidatePourSucceed = true;
  PourResult? lastValidationResult;
  GameState? lastExecutedState;
  int? lastFromContainer;
  int? lastToContainer;
  
  @override
  GameState initializeLevel(int levelId, List<models.Container> containers) {
    return GameState.initial(levelId: levelId, containers: containers);
  }
  
  @override
  PourResult attemptPour(GameState currentState, int fromContainerId, int toContainerId) {
    return validatePour(currentState, fromContainerId, toContainerId);
  }
  
  @override
  GameState? undoLastMove(GameState currentState) {
    return currentState.undoMove();
  }
  
  @override
  GameState? redoNextMove(GameState currentState) {
    return currentState.redoMove();
  }
  
  @override
  bool checkWinCondition(GameState gameState) {
    return gameState.isSolved;
  }
  
  @override
  PourResult validatePour(GameState gameState, int fromContainerId, int toContainerId) {
    lastFromContainer = fromContainerId;
    lastToContainer = toContainerId;
    
    if (shouldValidatePourSucceed) {
      final move = Move(
        fromContainerId: fromContainerId,
        toContainerId: toContainerId,
        liquidMoved: const LiquidLayer(color: LiquidColor.red, volume: 1),
        timestamp: DateTime.now(),
      );
      lastValidationResult = PourSuccess(move);
      return lastValidationResult!;
    } else {
      lastValidationResult = PourFailureSameContainer(fromContainerId);
      return lastValidationResult!;
    }
  }
  
  @override
  GameState executePour(GameState currentState, int fromContainerId, int toContainerId) {
    lastExecutedState = currentState;
    
    // Create a simple mock execution - just add a move to history
    final move = Move(
      fromContainerId: fromContainerId,
      toContainerId: toContainerId,
      liquidMoved: const LiquidLayer(color: LiquidColor.red, volume: 1),
      timestamp: DateTime.now(),
    );
    
    return currentState.addMove(move, currentState.containers);
  }
  
  @override
  bool hasLegalMoves(GameState gameState) {
    // Simple mock implementation - assume there are always legal moves
    return true;
  }
  
  @override
  bool checkLossCondition(GameState gameState) {
    // Simple mock implementation - assume game is never lost
    return false;
  }
}

void main() {
  group('GameBoardWidget', () {
    late MockGameEngine mockGameEngine;
    late GameState testGameState;
    late List<models.Container> testContainers;
    
    setUp(() {
      mockGameEngine = MockGameEngine();
      
      // Create test containers
      testContainers = [
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
            const LiquidLayer(color: LiquidColor.green, volume: 1),
          ],
        ),
        models.Container(
          id: 3,
          capacity: 4,
          liquidLayers: [],
        ),
      ];
      
      testGameState = GameState.initial(
        levelId: 1,
        containers: testContainers,
      );
    });
    
    testWidgets('displays all containers from game state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameBoardWidget(
              gameState: testGameState,
              gameEngine: mockGameEngine,
            ),
          ),
        ),
      );
      
      // Should display all 3 containers
      expect(find.byType(ContainerWidget), findsNWidgets(3));
    });
    
    testWidgets('handles container selection on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameBoardWidget(
              gameState: testGameState,
              gameEngine: mockGameEngine,
            ),
          ),
        ),
      );
      
      // Find the first container widget
      final firstContainer = find.byType(ContainerWidget).first;
      
      // Tap to select
      await tester.tap(firstContainer);
      await tester.pump();
      
      // Container should be selected (we can't directly test the selection state,
      // but we can verify the widget rebuilds without errors)
      expect(find.byType(ContainerWidget), findsNWidgets(3));
    });
    
    testWidgets('handles pour operation between containers', (WidgetTester tester) async {
      bool pourAttempted = false;
      GameState? newGameState;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameBoardWidget(
              gameState: testGameState,
              gameEngine: mockGameEngine,
              onPourAttempted: (from, to) {
                pourAttempted = true;
              },
              onGameStateChanged: (state) {
                newGameState = state;
              },
            ),
          ),
        ),
      );
      
      // Get container widgets
      final containerWidgets = find.byType(ContainerWidget);
      
      // Tap first container to select
      await tester.tap(containerWidgets.at(0));
      await tester.pump();
      
      // Tap second container to pour
      await tester.tap(containerWidgets.at(1));
      await tester.pump();
      
      // Verify pour was attempted
      expect(pourAttempted, isTrue);
      expect(mockGameEngine.lastFromContainer, equals(1));
      expect(mockGameEngine.lastToContainer, equals(2));
      
      // Verify game state was updated
      expect(newGameState, isNotNull);
      expect(newGameState!.moveCount, equals(1));
    });
    
    testWidgets('deselects container when tapping same container twice', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameBoardWidget(
              gameState: testGameState,
              gameEngine: mockGameEngine,
            ),
          ),
        ),
      );
      
      final firstContainer = find.byType(ContainerWidget).first;
      
      // Tap to select
      await tester.tap(firstContainer);
      await tester.pump();
      
      // Tap again to deselect
      await tester.tap(firstContainer);
      await tester.pump();
      
      // Should not crash and should handle deselection
      expect(find.byType(ContainerWidget), findsNWidgets(3));
    });
    
    testWidgets('handles failed pour operations', (WidgetTester tester) async {
      mockGameEngine.shouldValidatePourSucceed = false;
      bool pourAttempted = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameBoardWidget(
              gameState: testGameState,
              gameEngine: mockGameEngine,
              onPourAttempted: (from, to) {
                pourAttempted = true;
              },
            ),
          ),
        ),
      );
      
      final containerWidgets = find.byType(ContainerWidget);
      
      // Tap first container to select
      await tester.tap(containerWidgets.at(0));
      await tester.pump();
      
      // Tap second container to attempt pour (should fail)
      await tester.tap(containerWidgets.at(1));
      await tester.pump();
      
      // Verify pour was attempted but failed
      expect(pourAttempted, isTrue);
      expect(mockGameEngine.lastValidationResult, isA<PourFailureSameContainer>());
    });
    
    testWidgets('respects isInteractive property', (WidgetTester tester) async {
      bool pourAttempted = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameBoardWidget(
              gameState: testGameState,
              gameEngine: mockGameEngine,
              isInteractive: false,
              onPourAttempted: (from, to) {
                pourAttempted = true;
              },
            ),
          ),
        ),
      );
      
      final containerWidgets = find.byType(ContainerWidget);
      
      // Try to tap containers
      await tester.tap(containerWidgets.at(0));
      await tester.pump();
      await tester.tap(containerWidgets.at(1));
      await tester.pump();
      
      // Should not attempt pour when not interactive
      expect(pourAttempted, isFalse);
    });
    
    testWidgets('updates when game state changes externally', (WidgetTester tester) async {
      // Create widget with initial state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameBoardWidget(
              gameState: testGameState,
              gameEngine: mockGameEngine,
            ),
          ),
        ),
      );
      
      expect(find.byType(ContainerWidget), findsNWidgets(3));
      
      // Create new game state with different containers
      final newContainers = [
        models.Container(id: 1, capacity: 4, liquidLayers: []),
        models.Container(id: 2, capacity: 4, liquidLayers: []),
      ];
      
      final newGameState = GameState.initial(
        levelId: 2,
        containers: newContainers,
      );
      
      // Update the widget with new game state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameBoardWidget(
              gameState: newGameState,
              gameEngine: mockGameEngine,
            ),
          ),
        ),
      );
      
      // Should now display 2 containers
      expect(find.byType(ContainerWidget), findsNWidgets(2));
    });
    
    group('Responsive Layout', () {
      testWidgets('adapts to small screen size', (WidgetTester tester) async {
        // Set small screen size
        await tester.binding.setSurfaceSize(const Size(400, 600));
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameBoardWidget(
                gameState: testGameState,
                gameEngine: mockGameEngine,
              ),
            ),
          ),
        );
        
        expect(find.byType(ContainerWidget), findsNWidgets(3));
        
        // Reset surface size
        await tester.binding.setSurfaceSize(null);
      });
      
      testWidgets('adapts to large screen size', (WidgetTester tester) async {
        // Set large screen size
        await tester.binding.setSurfaceSize(const Size(800, 600));
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameBoardWidget(
                gameState: testGameState,
                gameEngine: mockGameEngine,
              ),
            ),
          ),
        );
        
        expect(find.byType(ContainerWidget), findsNWidgets(3));
        
        // Reset surface size
        await tester.binding.setSurfaceSize(null);
      });
      
      testWidgets('handles many containers layout', (WidgetTester tester) async {
        // Create game state with many containers
        final manyContainers = List.generate(12, (index) => 
          models.Container(
            id: index + 1,
            capacity: 4,
            liquidLayers: [],
          ),
        );
        
        final manyContainersState = GameState.initial(
          levelId: 1,
          containers: manyContainers,
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameBoardWidget(
                gameState: manyContainersState,
                gameEngine: mockGameEngine,
              ),
            ),
          ),
        );
        
        expect(find.byType(ContainerWidget), findsNWidgets(12));
      });
    });
    
    group('Custom Properties', () {
      testWidgets('respects custom container size', (WidgetTester tester) async {
        const customSize = Size(100, 150);
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameBoardWidget(
                gameState: testGameState,
                gameEngine: mockGameEngine,
                containerSize: customSize,
              ),
            ),
          ),
        );
        
        expect(find.byType(ContainerWidget), findsNWidgets(3));
      });
      
      testWidgets('respects custom container spacing', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameBoardWidget(
                gameState: testGameState,
                gameEngine: mockGameEngine,
                containerSpacing: 20.0,
              ),
            ),
          ),
        );
        
        expect(find.byType(ContainerWidget), findsNWidgets(3));
      });
      
      testWidgets('can disable selection animations', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameBoardWidget(
                gameState: testGameState,
                gameEngine: mockGameEngine,
                showSelectionAnimations: false,
              ),
            ),
          ),
        );
        
        expect(find.byType(ContainerWidget), findsNWidgets(3));
      });
      
      testWidgets('can disable pour animations', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameBoardWidget(
                gameState: testGameState,
                gameEngine: mockGameEngine,
                showPourAnimations: false,
              ),
            ),
          ),
        );
        
        expect(find.byType(ContainerWidget), findsNWidgets(3));
      });
    });
    
    group('Edge Cases', () {
      testWidgets('handles empty game state', (WidgetTester tester) async {
        final emptyGameState = GameState.initial(
          levelId: 1,
          containers: [],
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameBoardWidget(
                gameState: emptyGameState,
                gameEngine: mockGameEngine,
              ),
            ),
          ),
        );
        
        expect(find.byType(ContainerWidget), findsNothing);
      });
      
      testWidgets('handles single container', (WidgetTester tester) async {
        final singleContainerState = GameState.initial(
          levelId: 1,
          containers: [
            models.Container(id: 1, capacity: 4, liquidLayers: []),
          ],
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GameBoardWidget(
                gameState: singleContainerState,
                gameEngine: mockGameEngine,
              ),
            ),
          ),
        );
        
        expect(find.byType(ContainerWidget), findsOneWidget);
      });
    });
  });
}