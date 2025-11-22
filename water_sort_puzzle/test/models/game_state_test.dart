import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/models.dart';

void main() {
  group('GameState', () {
    late List<Container> testContainers;
    late GameState initialState;

    setUp(() {
      testContainers = [
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 2),
            const LiquidLayer(color: LiquidColor.blue, volume: 1),
          ],
        ),
        Container(
          id: 2,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.blue, volume: 2),
          ],
        ),
        Container(id: 3, capacity: 4), // empty container
      ];

      initialState = GameState.initial(
        levelId: 1,
        containers: testContainers,
      );
    });

    group('Initial State', () {
      test('should create initial state correctly', () {
        expect(initialState.levelId, equals(1));
        expect(initialState.containers.length, equals(3));
        expect(initialState.moveHistory, isEmpty);
        expect(initialState.isCompleted, isFalse);
        expect(initialState.moveCount, equals(0));
        expect(initialState.currentMoveIndex, equals(-1));
      });

      test('should not be solved initially', () {
        expect(initialState.isSolved, isFalse);
      });

      test('should not allow undo/redo initially', () {
        expect(initialState.canUndo, isFalse);
        expect(initialState.canRedo, isFalse);
        expect(initialState.undoableMovesCount, equals(0));
        expect(initialState.redoableMovesCount, equals(0));
      });
    });

    group('Container Access', () {
      test('should get container by ID', () {
        final container = initialState.getContainer(2);
        expect(container, isNotNull);
        expect(container!.id, equals(2));
      });

      test('should return null for invalid container ID', () {
        final container = initialState.getContainer(99);
        expect(container, isNull);
      });
    });

    group('Move Management', () {
      test('should add move and update state', () {
        final move = Move(
          fromContainerId: 1,
          toContainerId: 3,
          liquidMoved: const LiquidLayer(color: LiquidColor.blue, volume: 1),
          timestamp: DateTime.now(),
        );

        // Create new containers after the move
        final newContainers = [
          Container(
            id: 1,
            capacity: 4,
            liquidLayers: [
              const LiquidLayer(color: LiquidColor.red, volume: 2),
            ],
          ),
          Container(
            id: 2,
            capacity: 4,
            liquidLayers: [
              const LiquidLayer(color: LiquidColor.blue, volume: 2),
            ],
          ),
          Container(
            id: 3,
            capacity: 4,
            liquidLayers: [
              const LiquidLayer(color: LiquidColor.blue, volume: 1),
            ],
          ),
        ];

        final newState = initialState.addMove(move, newContainers);

        expect(newState.moveHistory.length, equals(1));
        expect(newState.moveHistory.first, equals(move));
        expect(newState.moveCount, equals(1));
        expect(newState.currentMoveIndex, equals(0));
        expect(newState.effectiveMoveCount, equals(1));
        expect(newState.canUndo, isTrue);
        expect(newState.canRedo, isFalse);
      });

      test('should truncate history when adding move after undo', () {
        // Add two moves
        final move1 = Move(
          fromContainerId: 1,
          toContainerId: 3,
          liquidMoved: const LiquidLayer(color: LiquidColor.blue, volume: 1),
          timestamp: DateTime.now(),
        );

        final move2 = Move(
          fromContainerId: 2,
          toContainerId: 3,
          liquidMoved: const LiquidLayer(color: LiquidColor.blue, volume: 1),
          timestamp: DateTime.now(),
        );

        var state = initialState.addMove(move1, testContainers);
        state = state.addMove(move2, testContainers);

        expect(state.moveHistory.length, equals(2));

        // Undo one move
        state = state.undoMove()!;
        expect(state.currentMoveIndex, equals(0));
        expect(state.canRedo, isTrue);

        // Add a new move - should truncate history
        final move3 = Move(
          fromContainerId: 1,
          toContainerId: 2,
          liquidMoved: const LiquidLayer(color: LiquidColor.red, volume: 1),
          timestamp: DateTime.now(),
        );

        state = state.addMove(move3, testContainers);

        expect(state.moveHistory.length, equals(2)); // move1 and move3
        expect(state.moveHistory[1], equals(move3));
        expect(state.canRedo, isFalse);
      });
    });

    group('Undo/Redo Functionality', () {
      late GameState stateWithMoves;

      setUp(() {
        final move1 = Move(
          fromContainerId: 1,
          toContainerId: 3,
          liquidMoved: const LiquidLayer(color: LiquidColor.blue, volume: 1),
          timestamp: DateTime.now(),
        );

        final containersAfterMove1 = [
          Container(
            id: 1,
            capacity: 4,
            liquidLayers: [
              const LiquidLayer(color: LiquidColor.red, volume: 2),
            ],
          ),
          Container(
            id: 2,
            capacity: 4,
            liquidLayers: [
              const LiquidLayer(color: LiquidColor.blue, volume: 2),
            ],
          ),
          Container(
            id: 3,
            capacity: 4,
            liquidLayers: [
              const LiquidLayer(color: LiquidColor.blue, volume: 1),
            ],
          ),
        ];

        stateWithMoves = initialState.addMove(move1, containersAfterMove1);
      });

      test('should undo move correctly', () {
        final undoneState = stateWithMoves.undoMove();

        expect(undoneState, isNotNull);
        expect(undoneState!.currentMoveIndex, equals(-1));
        expect(undoneState.canUndo, isFalse);
        expect(undoneState.canRedo, isTrue);
        expect(undoneState.effectiveMoveCount, equals(0));

        // Check that containers are restored
        final container1 = undoneState.getContainer(1)!;
        final container3 = undoneState.getContainer(3)!;
        expect(container1.liquidLayers.length, equals(2)); // blue layer restored
        expect(container3.isEmpty, isTrue); // liquid removed
      });

      test('should redo move correctly', () {
        final undoneState = stateWithMoves.undoMove()!;
        final redoneState = undoneState.redoMove();

        expect(redoneState, isNotNull);
        expect(redoneState!.currentMoveIndex, equals(0));
        expect(redoneState.canUndo, isTrue);
        expect(redoneState.canRedo, isFalse);
        expect(redoneState.effectiveMoveCount, equals(1));

        // Should be back to the state after the move
        final container1 = redoneState.getContainer(1)!;
        final container3 = redoneState.getContainer(3)!;
        expect(container1.liquidLayers.length, equals(1)); // blue layer removed
        expect(container3.liquidLayers.length, equals(1)); // blue layer added
      });

      test('should return null when undoing with no moves', () {
        final result = initialState.undoMove();
        expect(result, isNull);
      });

      test('should return null when redoing with no moves to redo', () {
        final result = stateWithMoves.redoMove();
        expect(result, isNull);
      });
    });

    group('Win Condition Detection', () {
      test('should detect solved state', () {
        final solvedContainers = [
          Container(
            id: 1,
            capacity: 4,
            liquidLayers: [
              const LiquidLayer(color: LiquidColor.red, volume: 4),
            ],
          ),
          Container(
            id: 2,
            capacity: 4,
            liquidLayers: [
              const LiquidLayer(color: LiquidColor.blue, volume: 4),
            ],
          ),
          Container(id: 3, capacity: 4), // empty is allowed
        ];

        final solvedState = GameState.initial(
          levelId: 1,
          containers: solvedContainers,
        );

        expect(solvedState.isSolved, isTrue);
      });

      test('should not detect solved state with mixed colors', () {
        expect(initialState.isSolved, isFalse);
      });

      test('should update completion status when adding moves', () {
        final solvedContainers = [
          Container(
            id: 1,
            capacity: 4,
            liquidLayers: [
              const LiquidLayer(color: LiquidColor.red, volume: 4),
            ],
          ),
          Container(
            id: 2,
            capacity: 4,
            liquidLayers: [
              const LiquidLayer(color: LiquidColor.blue, volume: 4),
            ],
          ),
          Container(id: 3, capacity: 4),
        ];

        final move = Move(
          fromContainerId: 1,
          toContainerId: 2,
          liquidMoved: const LiquidLayer(color: LiquidColor.red, volume: 1),
          timestamp: DateTime.now(),
        );

        final completedState = initialState.addMove(move, solvedContainers);
        expect(completedState.isCompleted, isTrue);
      });
    });

    group('State Reset', () {
      test('should reset to initial state', () {
        var state = initialState;
        
        // Add some moves
        final move = Move(
          fromContainerId: 1,
          toContainerId: 3,
          liquidMoved: const LiquidLayer(color: LiquidColor.blue, volume: 1),
          timestamp: DateTime.now(),
        );
        
        state = state.addMove(move, testContainers);
        expect(state.moveCount, equals(1));

        // Reset
        final resetState = state.reset(testContainers);
        
        expect(resetState.moveHistory, isEmpty);
        expect(resetState.moveCount, equals(0));
        expect(resetState.currentMoveIndex, equals(-1));
        expect(resetState.isCompleted, isFalse);
        expect(resetState.levelId, equals(state.levelId)); // level ID preserved
      });
    });

    group('Serialization', () {
      test('should serialize to and from JSON', () {
        final json = initialState.toJson();
        final fromJson = GameState.fromJson(json);

        expect(fromJson.levelId, equals(initialState.levelId));
        expect(fromJson.containers.length, equals(initialState.containers.length));
        expect(fromJson.moveHistory.length, equals(initialState.moveHistory.length));
        expect(fromJson.isCompleted, equals(initialState.isCompleted));
        expect(fromJson.moveCount, equals(initialState.moveCount));
        expect(fromJson.currentMoveIndex, equals(initialState.currentMoveIndex));
      });
    });

    group('Equality and HashCode', () {
      test('should support equality comparison', () {
        final state1 = GameState.initial(levelId: 1, containers: testContainers);
        final state2 = GameState.initial(levelId: 1, containers: testContainers);
        final state3 = GameState.initial(levelId: 2, containers: testContainers);

        expect(state1, equals(state2));
        expect(state1, isNot(equals(state3)));
      });

      test('should have consistent hashCode', () {
        final state1 = GameState.initial(levelId: 1, containers: testContainers);
        final state2 = GameState.initial(levelId: 1, containers: testContainers);

        expect(state1.hashCode, equals(state2.hashCode));
      });
    });

    group('Copy With', () {
      test('should create copy with overridden properties', () {
        final copy = initialState.copyWith(
          levelId: 2,
          isCompleted: true,
        );

        expect(copy.levelId, equals(2));
        expect(copy.isCompleted, isTrue);
        expect(copy.containers, equals(initialState.containers));
        expect(copy.moveHistory, equals(initialState.moveHistory));
      });
    });

    group('String Representation', () {
      test('should have meaningful toString', () {
        final string = initialState.toString();
        expect(string, contains('GameState'));
        expect(string, contains('level: 1'));
        expect(string, contains('containers: 3'));
        expect(string, contains('moves: 0'));
      });
    });
  });
}