import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/services/move_validator.dart';

void main() {
  group('MoveValidator', () {
    group('getAllValidMoves', () {
      test('returns empty list when no moves are possible', () {
        // All containers full with incompatible top colors
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

        final validMoves = MoveValidator.getAllValidMoves(containers);
        expect(validMoves, isEmpty);
      });

      test('returns valid moves when containers can accept pours', () {
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

        final validMoves = MoveValidator.getAllValidMoves(containers);
        
        expect(validMoves, hasLength(1));
        expect(validMoves[0].fromContainer, 0);
        expect(validMoves[0].toContainer, 1);
        expect(validMoves[0].liquidColor, LiquidColor.blue);
        expect(validMoves[0].volume, 2);
      });

      test('finds moves to empty containers', () {
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
            liquidLayers: [], // Empty
          ),
        ];

        final validMoves = MoveValidator.getAllValidMoves(containers);
        
        expect(validMoves, hasLength(1));
        expect(validMoves[0].fromContainer, 0);
        expect(validMoves[0].toContainer, 1);
        expect(validMoves[0].liquidColor, LiquidColor.red);
        expect(validMoves[0].volume, 2);
      });

      test('handles multiple valid moves from same container', () {
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
            liquidLayers: [], // Empty
          ),
          Container(
            id: 2,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.red, volume: 1),
            ],
          ),
        ];

        final validMoves = MoveValidator.getAllValidMoves(containers);
        
        expect(validMoves, hasLength(4)); // All possible moves in both directions
        
        // Should be able to pour from container 0 to both other containers
        final fromContainer0 = validMoves.where((m) => m.fromContainer == 0);
        expect(fromContainer0, hasLength(2));
        
        final toContainers = fromContainer0.map((m) => m.toContainer).toSet();
        expect(toContainers, containsAll([1, 2]));
      });

      test('respects container capacity limits', () {
        final containers = [
          Container(
            id: 0,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.red, volume: 3),
            ],
          ),
          Container(
            id: 1,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.blue, volume: 2),
              LiquidLayer(color: LiquidColor.red, volume: 1), // Only 1 space left
            ],
          ),
        ];

        final validMoves = MoveValidator.getAllValidMoves(containers);
        
        expect(validMoves, hasLength(2)); // Moves in both directions
        
        // Find the move from container 0 to container 1 (capacity limited)
        final move0to1 = validMoves.firstWhere((m) => m.fromContainer == 0 && m.toContainer == 1);
        expect(move0to1.volume, 1); // Limited by target capacity
        
        // Find the move from container 1 to container 0 (not capacity limited)
        final move1to0 = validMoves.firstWhere((m) => m.fromContainer == 1 && m.toContainer == 0);
        expect(move1to0.volume, 1); // Full continuous layer volume
      });

      test('handles continuous layers of same color', () {
        final containers = [
          Container(
            id: 0,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.blue, volume: 1),
              LiquidLayer(color: LiquidColor.red, volume: 2),
              LiquidLayer(color: LiquidColor.red, volume: 1), // Continuous red on top
            ],
          ),
          Container(
            id: 1,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.red, volume: 1),
            ],
          ),
        ];

        final validMoves = MoveValidator.getAllValidMoves(containers);
        
        expect(validMoves, hasLength(1));
        expect(validMoves[0].liquidColor, LiquidColor.red);
        expect(validMoves[0].volume, 3); // Should pour all continuous red layers
      });

      test('ignores empty containers as sources', () {
        final containers = [
          Container(
            id: 0,
            capacity: 4,
            liquidLayers: [], // Empty
          ),
          Container(
            id: 1,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.red, volume: 2),
            ],
          ),
        ];

        final validMoves = MoveValidator.getAllValidMoves(containers);
        
        // Should only find moves from container 1, not from empty container 0
        expect(validMoves, hasLength(1));
        expect(validMoves[0].fromContainer, 1);
        expect(validMoves[0].toContainer, 0);
      });

      test('handles complex multi-container scenario', () {
        final containers = [
          Container(
            id: 0,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.red, volume: 2),
              LiquidLayer(color: LiquidColor.blue, volume: 1),
            ],
          ),
          Container(
            id: 1,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.green, volume: 1),
              LiquidLayer(color: LiquidColor.blue, volume: 2),
            ],
          ),
          Container(
            id: 2,
            capacity: 4,
            liquidLayers: [], // Empty
          ),
          Container(
            id: 3,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.blue, volume: 1),
            ],
          ),
        ];

        final validMoves = MoveValidator.getAllValidMoves(containers);
        
        // Should find multiple valid moves
        expect(validMoves.length, greaterThan(0));
        
        // Check that moves to empty container are found
        final movesToEmpty = validMoves.where((m) => m.toContainer == 2);
        expect(movesToEmpty.length, greaterThan(0));
        
        // Check that color-matching moves are found
        final blueToBlue = validMoves.where((m) => 
          m.liquidColor == LiquidColor.blue && 
          containers[m.toContainer].topColor == LiquidColor.blue
        );
        expect(blueToBlue.length, greaterThan(0));
      });

      test('does not allow pouring to same container', () {
        final containers = [
          Container(
            id: 0,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.red, volume: 2),
            ],
          ),
        ];

        final validMoves = MoveValidator.getAllValidMoves(containers);
        
        // Should not find any moves (can't pour to itself)
        expect(validMoves, isEmpty);
      });

      test('handles full containers correctly', () {
        final containers = [
          Container(
            id: 0,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.red, volume: 4), // Full
            ],
          ),
          Container(
            id: 1,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.blue, volume: 4), // Full
            ],
          ),
        ];

        final validMoves = MoveValidator.getAllValidMoves(containers);
        
        // No moves possible - both containers are full
        expect(validMoves, isEmpty);
      });
    });

    group('ValidMove', () {
      test('equality works correctly', () {
        final move1 = ValidMove(
          fromContainer: 0,
          toContainer: 1,
          liquidColor: LiquidColor.red,
          volume: 2,
        );

        final move2 = ValidMove(
          fromContainer: 0,
          toContainer: 1,
          liquidColor: LiquidColor.red,
          volume: 2,
        );

        final move3 = ValidMove(
          fromContainer: 0,
          toContainer: 1,
          liquidColor: LiquidColor.blue,
          volume: 2,
        );

        expect(move1, equals(move2));
        expect(move1, isNot(equals(move3)));
      });

      test('toString provides useful information', () {
        final move = ValidMove(
          fromContainer: 0,
          toContainer: 1,
          liquidColor: LiquidColor.red,
          volume: 2,
        );

        final string = move.toString();
        expect(string, contains('from: 0'));
        expect(string, contains('to: 1'));
        expect(string, contains('red'));
        expect(string, contains('volume: 2'));
      });
    });
  });
}