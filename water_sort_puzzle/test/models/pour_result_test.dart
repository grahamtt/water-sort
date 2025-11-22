import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/models.dart';

void main() {
  group('PourResult', () {
    late Move testMove;

    setUp(() {
      testMove = Move(
        fromContainerId: 1,
        toContainerId: 2,
        liquidMoved: const LiquidLayer(color: LiquidColor.red, volume: 1),
        timestamp: DateTime.now(),
      );
    });

    group('PourSuccess', () {
      test('should indicate success', () {
        final result = PourSuccess(testMove);
        
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.move, equals(testMove));
      });

      test('should support equality comparison', () {
        final result1 = PourSuccess(testMove);
        final result2 = PourSuccess(testMove);
        final result3 = PourSuccess(Move(
          fromContainerId: 2,
          toContainerId: 3,
          liquidMoved: const LiquidLayer(color: LiquidColor.blue, volume: 1),
          timestamp: DateTime.now(),
        ));

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });
    });

    group('PourFailureContainerFull', () {
      test('should indicate failure with correct message', () {
        final result = PourFailureContainerFull(5);
        
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.containerId, equals(5));
        expect(result.message, contains('Container 5 is full'));
      });

      test('should support equality comparison', () {
        final result1 = PourFailureContainerFull(5);
        final result2 = PourFailureContainerFull(5);
        final result3 = PourFailureContainerFull(6);

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });
    });

    group('PourFailureColorMismatch', () {
      test('should indicate failure with correct message', () {
        final result = PourFailureColorMismatch(
          LiquidColor.red,
          LiquidColor.blue,
        );
        
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.sourceColor, equals(LiquidColor.red));
        expect(result.targetColor, equals(LiquidColor.blue));
        expect(result.message, contains('Red'));
        expect(result.message, contains('Blue'));
      });

      test('should support equality comparison', () {
        final result1 = PourFailureColorMismatch(
          LiquidColor.red,
          LiquidColor.blue,
        );
        final result2 = PourFailureColorMismatch(
          LiquidColor.red,
          LiquidColor.blue,
        );
        final result3 = PourFailureColorMismatch(
          LiquidColor.green,
          LiquidColor.blue,
        );

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });
    });

    group('PourFailureEmptySource', () {
      test('should indicate failure with correct message', () {
        final result = PourFailureEmptySource(3);
        
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.containerId, equals(3));
        expect(result.message, contains('Container 3 is empty'));
      });
    });

    group('PourFailureSameContainer', () {
      test('should indicate failure with correct message', () {
        final result = PourFailureSameContainer(4);
        
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.containerId, equals(4));
        expect(result.message, contains('Cannot pour from container 4 to itself'));
      });
    });

    group('PourFailureInvalidContainer', () {
      test('should indicate failure with correct message', () {
        final result = PourFailureInvalidContainer(99);
        
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.containerId, equals(99));
        expect(result.message, contains('Container 99 does not exist'));
      });
    });

    group('PourFailureInsufficientCapacity', () {
      test('should indicate failure with correct message', () {
        final result = PourFailureInsufficientCapacity(2, 3, 1);
        
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.containerId, equals(2));
        expect(result.attemptedVolume, equals(3));
        expect(result.availableCapacity, equals(1));
        expect(result.message, contains('Container 2'));
        expect(result.message, contains('1 capacity'));
        expect(result.message, contains('pour 3'));
      });

      test('should support equality comparison', () {
        final result1 = PourFailureInsufficientCapacity(2, 3, 1);
        final result2 = PourFailureInsufficientCapacity(2, 3, 1);
        final result3 = PourFailureInsufficientCapacity(2, 2, 1);

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });
    });
  });
}