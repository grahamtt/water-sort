import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/game_state.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/services/loss_detector.dart';

void main() {
  group('LossDetector', () {
    group('hasLost', () {
      test('returns false when game is already won', () {
        // Create a solved game state
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

        expect(LossDetector.hasLost(gameState), false);
      });

      test('returns false when valid moves are available', () {
        // Create a game state with valid moves
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
        ];

        final gameState = GameState.initial(
          levelId: 1,
          containers: containers,
        );

        expect(LossDetector.hasLost(gameState), false);
      });

      test('returns true when no valid moves are available and not solved', () {
        // Create a deadlock situation
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
        ];

        final gameState = GameState.initial(
          levelId: 1,
          containers: containers,
        );

        expect(LossDetector.hasLost(gameState), true);
      });

      test('returns false when empty container allows moves', () {
        // Game state with an empty container that allows moves
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
            liquidLayers: [], // Empty container
          ),
        ];

        final gameState = GameState.initial(
          levelId: 1,
          containers: containers,
        );

        expect(LossDetector.hasLost(gameState), false);
      });

      test('returns true when all containers are full with mixed colors', () {
        // All containers are full but not sorted
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
          Container(
            id: 2,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.green, volume: 2),
              LiquidLayer(color: LiquidColor.yellow, volume: 2),
            ],
          ),
        ];

        final gameState = GameState.initial(
          levelId: 1,
          containers: containers,
        );

        expect(LossDetector.hasLost(gameState), true);
      });

      test('returns false when partial moves are possible', () {
        // Container with matching top colors but limited capacity
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
              LiquidLayer(color: LiquidColor.green, volume: 2),
              LiquidLayer(color: LiquidColor.blue, volume: 1), // Can accept 1 more blue
            ],
          ),
        ];

        final gameState = GameState.initial(
          levelId: 1,
          containers: containers,
        );

        expect(LossDetector.hasLost(gameState), false);
      });

      test('handles single container edge case', () {
        // Single container - should be lost if not solved
        final containers = [
          Container(
            id: 0,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.red, volume: 2),
              LiquidLayer(color: LiquidColor.blue, volume: 2),
            ],
          ),
        ];

        final gameState = GameState.initial(
          levelId: 1,
          containers: containers,
        );

        expect(LossDetector.hasLost(gameState), true);
      });

      test('handles empty containers edge case', () {
        // All containers empty - should not be lost (technically solved)
        final containers = [
          Container(id: 0, capacity: 4, liquidLayers: []),
          Container(id: 1, capacity: 4, liquidLayers: []),
        ];

        final gameState = GameState.initial(
          levelId: 1,
          containers: containers,
        );

        expect(LossDetector.hasLost(gameState), false);
      });

      test('complex deadlock scenario with multiple colors', () {
        // Complex scenario where no moves are possible
        final containers = [
          Container(
            id: 0,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.red, volume: 1),
              LiquidLayer(color: LiquidColor.blue, volume: 1),
              LiquidLayer(color: LiquidColor.green, volume: 1),
              LiquidLayer(color: LiquidColor.yellow, volume: 1),
            ],
          ),
          Container(
            id: 1,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.blue, volume: 1),
              LiquidLayer(color: LiquidColor.red, volume: 1),
              LiquidLayer(color: LiquidColor.yellow, volume: 1),
              LiquidLayer(color: LiquidColor.green, volume: 1),
            ],
          ),
          Container(
            id: 2,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.green, volume: 1),
              LiquidLayer(color: LiquidColor.yellow, volume: 1),
              LiquidLayer(color: LiquidColor.red, volume: 1),
              LiquidLayer(color: LiquidColor.blue, volume: 1),
            ],
          ),
        ];

        final gameState = GameState.initial(
          levelId: 1,
          containers: containers,
        );

        expect(LossDetector.hasLost(gameState), true);
      });
    });

    group('getLossMessage', () {
      test('returns appropriate message when game is lost', () {
        // Create a lost game state
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
        ];

        final gameState = GameState.initial(
          levelId: 1,
          containers: containers,
        );

        final message = LossDetector.getLossMessage(gameState);
        expect(message, contains('No more valid moves available'));
        expect(message, contains('cannot be solved'));
      });

      test('returns different message when game is not lost', () {
        // Create a non-lost game state
        final containers = [
          Container(
            id: 0,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.red, volume: 2),
            ],
          ),
          Container(
            id: 1,
            capacity: 4,
            liquidLayers: [],
          ),
        ];

        final gameState = GameState.initial(
          levelId: 1,
          containers: containers,
        );

        final message = LossDetector.getLossMessage(gameState);
        expect(message, contains('not in a loss state'));
      });
    });

    group('getDetailedLossReason', () {
      test('provides detailed information for lost game', () {
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
              LiquidLayer(color: LiquidColor.blue, volume: 2),
              LiquidLayer(color: LiquidColor.red, volume: 2),
            ],
          ),
        ];

        final gameState = GameState.initial(
          levelId: 1,
          containers: containers,
        );

        final reason = LossDetector.getDetailedLossReason(gameState);
        expect(reason, contains('Loss detected'));
        expect(reason, contains('Valid moves available: 0'));
        expect(reason, contains('Total containers: 2'));
        expect(reason, contains('Empty containers:'));
        expect(reason, contains('Full containers:'));
        expect(reason, contains('Sorted containers:'));
      });

      test('provides different message when game is not lost', () {
        final containers = [
          Container(
            id: 0,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.red, volume: 2),
            ],
          ),
          Container(
            id: 1,
            capacity: 4,
            liquidLayers: [],
          ),
        ];

        final gameState = GameState.initial(
          levelId: 1,
          containers: containers,
        );

        final reason = LossDetector.getDetailedLossReason(gameState);
        expect(reason, contains('not in a loss state'));
      });
    });
  });
}