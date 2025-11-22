import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/models.dart';

void main() {
  group('Move', () {
    late Move testMove;
    late LiquidLayer testLiquid;
    late DateTime testTime;

    setUp(() {
      testTime = DateTime(2023, 1, 1, 12, 0, 0);
      testLiquid = const LiquidLayer(color: LiquidColor.red, volume: 2);
      testMove = Move(
        fromContainerId: 1,
        toContainerId: 2,
        liquidMoved: testLiquid,
        timestamp: testTime,
      );
    });

    test('should create move with correct properties', () {
      expect(testMove.fromContainerId, equals(1));
      expect(testMove.toContainerId, equals(2));
      expect(testMove.liquidMoved, equals(testLiquid));
      expect(testMove.timestamp, equals(testTime));
    });

    test('should create copy with overridden properties', () {
      final newTime = DateTime(2023, 1, 2, 12, 0, 0);
      final copy = testMove.copyWith(
        fromContainerId: 3,
        timestamp: newTime,
      );

      expect(copy.fromContainerId, equals(3));
      expect(copy.toContainerId, equals(2)); // unchanged
      expect(copy.liquidMoved, equals(testLiquid)); // unchanged
      expect(copy.timestamp, equals(newTime));
    });

    test('should support equality comparison', () {
      final identicalMove = Move(
        fromContainerId: 1,
        toContainerId: 2,
        liquidMoved: testLiquid,
        timestamp: testTime,
      );

      final differentMove = Move(
        fromContainerId: 2,
        toContainerId: 1,
        liquidMoved: testLiquid,
        timestamp: testTime,
      );

      expect(testMove, equals(identicalMove));
      expect(testMove, isNot(equals(differentMove)));
    });

    test('should have consistent hashCode', () {
      final identicalMove = Move(
        fromContainerId: 1,
        toContainerId: 2,
        liquidMoved: testLiquid,
        timestamp: testTime,
      );

      expect(testMove.hashCode, equals(identicalMove.hashCode));
    });

    test('should serialize to and from JSON', () {
      final json = testMove.toJson();
      final fromJson = Move.fromJson(json);

      expect(fromJson, equals(testMove));
    });

    test('should have meaningful toString', () {
      final string = testMove.toString();
      expect(string, contains('Move'));
      expect(string, contains('from: 1'));
      expect(string, contains('to: 2'));
    });
  });
}