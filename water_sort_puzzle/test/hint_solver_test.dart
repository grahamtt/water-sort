import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/game_state.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/services/game_engine.dart';
import 'package:water_sort_puzzle/services/hint_solver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('HintSolver', () {
    late WaterSortGameEngine gameEngine;
    late HintSolver hintSolver;

    setUp(() {
      gameEngine = WaterSortGameEngine();
      hintSolver = HintSolver(gameEngine);
    });

    test('should return null for already solved puzzle', () {
      // Create a solved state
      final containers = [
        Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 4),
          ],
        ),
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 4),
          ],
        ),
        Container(id: 2, capacity: 4, liquidLayers: []),
      ];

      final gameState = GameState.initial(
        levelId: 1,
        containers: containers,
      );

      final hint = hintSolver.findBestMove(gameState);
      expect(hint, isNull);
    });

    test('should find a hint for simple puzzle', () {
      // Create a simple unsolved state
      final containers = [
        Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ],
        ),
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        ),
        Container(id: 2, capacity: 4, liquidLayers: []),
      ];

      final gameState = GameState.initial(
        levelId: 1,
        containers: containers,
      );

      final hint = hintSolver.findBestMove(gameState);
      expect(hint, isNotNull);
      expect(hint!.fromContainerId, isA<int>());
      expect(hint.toContainerId, isA<int>());
      expect(hint.fromContainerId, isNot(equals(hint.toContainerId)));
    });

    test('should find valid move that can be executed', () {
      // Create a simple unsolved state
      final containers = [
        Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ],
        ),
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ],
        ),
        Container(id: 2, capacity: 4, liquidLayers: []),
      ];

      final gameState = GameState.initial(
        levelId: 1,
        containers: containers,
      );

      final hint = hintSolver.findBestMove(gameState);
      expect(hint, isNotNull);

      // Verify the hint is a valid move
      final pourResult = gameEngine.validatePour(
        gameState,
        hint!.fromContainerId,
        hint.toContainerId,
      );
      expect(pourResult.isSuccess, isTrue);
    });

    test('should return null when no moves are possible', () {
      // Create a state with no valid moves (all containers full with different colors)
      final containers = [
        Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 4),
          ],
        ),
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 4),
          ],
        ),
      ];

      final gameState = GameState.initial(
        levelId: 1,
        containers: containers,
      );

      final hint = hintSolver.findBestMove(gameState);
      // This should return null since puzzle is already solved
      expect(hint, isNull);
    });
  });
}
