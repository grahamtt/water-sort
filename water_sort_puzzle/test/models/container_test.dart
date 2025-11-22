import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';

void main() {
  group('Container', () {
    test('should create empty container with correct properties', () {
      final container = Container(id: 1, capacity: 4);

      expect(container.id, equals(1));
      expect(container.capacity, equals(4));
      expect(container.liquidLayers, isEmpty);
      expect(container.isEmpty, isTrue);
      expect(container.isFull, isFalse);
      expect(container.currentVolume, equals(0));
      expect(container.remainingCapacity, equals(4));
    });

    test('should create container with initial liquid layers', () {
      final layers = [
        const LiquidLayer(color: LiquidColor.red, volume: 2),
        const LiquidLayer(color: LiquidColor.blue, volume: 1),
      ];
      final container = Container(id: 1, capacity: 4, liquidLayers: layers);

      expect(container.liquidLayers.length, equals(2));
      expect(container.currentVolume, equals(3));
      expect(container.remainingCapacity, equals(1));
      expect(container.isEmpty, isFalse);
      expect(container.isFull, isFalse);
    });

    test('should create copy with modified properties', () {
      final original = Container(id: 1, capacity: 4);

      final copyWithNewId = original.copyWith(id: 2);
      expect(copyWithNewId.id, equals(2));
      expect(copyWithNewId.capacity, equals(4));

      final copyWithNewCapacity = original.copyWith(capacity: 6);
      expect(copyWithNewCapacity.id, equals(1));
      expect(copyWithNewCapacity.capacity, equals(6));

      final newLayers = [const LiquidLayer(color: LiquidColor.red, volume: 1)];
      final copyWithLayers = original.copyWith(liquidLayers: newLayers);
      expect(copyWithLayers.liquidLayers.length, equals(1));
    });

    test('should detect full container', () {
      final layers = [
        const LiquidLayer(color: LiquidColor.red, volume: 2),
        const LiquidLayer(color: LiquidColor.blue, volume: 2),
      ];
      final container = Container(id: 1, capacity: 4, liquidLayers: layers);

      expect(container.isFull, isTrue);
      expect(container.remainingCapacity, equals(0));
    });

    test('should detect sorted container (single color)', () {
      final sortedLayers = [
        const LiquidLayer(color: LiquidColor.red, volume: 2),
        const LiquidLayer(color: LiquidColor.red, volume: 1),
      ];
      final sortedContainer = Container(
        id: 1,
        capacity: 4,
        liquidLayers: sortedLayers,
      );

      final mixedLayers = [
        const LiquidLayer(color: LiquidColor.red, volume: 2),
        const LiquidLayer(color: LiquidColor.blue, volume: 1),
      ];
      final mixedContainer = Container(
        id: 2,
        capacity: 4,
        liquidLayers: mixedLayers,
      );

      final emptyContainer = Container(id: 3, capacity: 4);

      expect(sortedContainer.isSorted, isTrue);
      expect(mixedContainer.isSorted, isFalse);
      expect(emptyContainer.isSorted, isTrue); // Empty is considered sorted
    });

    test('should get top layer and color correctly', () {
      final layers = [
        const LiquidLayer(color: LiquidColor.red, volume: 2),
        const LiquidLayer(color: LiquidColor.blue, volume: 1),
      ];
      final container = Container(id: 1, capacity: 4, liquidLayers: layers);
      final emptyContainer = Container(id: 2, capacity: 4);

      expect(container.topLayer?.color, equals(LiquidColor.blue));
      expect(container.topLayer?.volume, equals(1));
      expect(container.topColor, equals(LiquidColor.blue));

      expect(emptyContainer.topLayer, isNull);
      expect(emptyContainer.topColor, isNull);
    });

    test('should check if pour can be accepted', () {
      final container = Container(
        id: 1,
        capacity: 4,
        liquidLayers: [const LiquidLayer(color: LiquidColor.red, volume: 2)],
      );
      final emptyContainer = Container(id: 2, capacity: 4);
      final fullContainer = Container(
        id: 3,
        capacity: 2,
        liquidLayers: [const LiquidLayer(color: LiquidColor.blue, volume: 2)],
      );

      // Can accept same color
      expect(container.canAcceptPour(LiquidColor.red, 1), isTrue);
      // Cannot accept different color
      expect(container.canAcceptPour(LiquidColor.blue, 1), isFalse);
      // Cannot accept if exceeds capacity
      expect(container.canAcceptPour(LiquidColor.red, 3), isFalse);

      // Empty container can accept any color
      expect(emptyContainer.canAcceptPour(LiquidColor.red, 1), isTrue);
      expect(emptyContainer.canAcceptPour(LiquidColor.blue, 1), isTrue);

      // Full container cannot accept anything
      expect(fullContainer.canAcceptPour(LiquidColor.blue, 1), isFalse);
    });

    test('should check if can pour from container', () {
      final container = Container(
        id: 1,
        capacity: 4,
        liquidLayers: [const LiquidLayer(color: LiquidColor.red, volume: 2)],
      );
      final emptyContainer = Container(id: 2, capacity: 4);

      expect(container.canPourFrom(), isTrue);
      expect(emptyContainer.canPourFrom(), isFalse);
    });

    test('should get top continuous layer correctly', () {
      final container = Container(
        id: 1,
        capacity: 6,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.blue, volume: 1),
          const LiquidLayer(color: LiquidColor.red, volume: 2),
          const LiquidLayer(color: LiquidColor.red, volume: 1),
        ],
      );
      final emptyContainer = Container(id: 2, capacity: 4);

      final topContinuous = container.getTopContinuousLayer();
      expect(topContinuous?.color, equals(LiquidColor.red));
      expect(topContinuous?.volume, equals(3)); // 2 + 1

      expect(emptyContainer.getTopContinuousLayer(), isNull);
    });

    test('should add liquid correctly', () {
      final container = Container(
        id: 1,
        capacity: 4,
        liquidLayers: [const LiquidLayer(color: LiquidColor.red, volume: 2)],
      );

      // Add same color - should combine
      container.addLiquid(const LiquidLayer(color: LiquidColor.red, volume: 1));
      expect(container.liquidLayers.length, equals(1));
      expect(container.liquidLayers.first.volume, equals(3));

      // Test adding to empty container
      final emptyContainer = Container(id: 2, capacity: 4);
      emptyContainer.addLiquid(
        const LiquidLayer(color: LiquidColor.blue, volume: 1),
      );
      expect(emptyContainer.liquidLayers.length, equals(1));
      expect(emptyContainer.topColor, equals(LiquidColor.blue));

      // Add same color to the empty container that now has liquid
      emptyContainer.addLiquid(
        const LiquidLayer(color: LiquidColor.blue, volume: 1),
      );
      expect(emptyContainer.liquidLayers.length, equals(1));
      expect(emptyContainer.liquidLayers.first.volume, equals(2));
    });

    test('should throw error when adding incompatible liquid', () {
      final container = Container(
        id: 1,
        capacity: 4,
        liquidLayers: [const LiquidLayer(color: LiquidColor.red, volume: 2)],
      );

      // Try to add different color when top is red
      expect(
        () => container.addLiquid(
          const LiquidLayer(color: LiquidColor.blue, volume: 1),
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Try to exceed capacity
      expect(
        () => container.addLiquid(
          const LiquidLayer(color: LiquidColor.red, volume: 3),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should remove top layer correctly', () {
      final container = Container(
        id: 1,
        capacity: 6,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.blue, volume: 1),
          const LiquidLayer(color: LiquidColor.red, volume: 2),
          const LiquidLayer(color: LiquidColor.red, volume: 1),
        ],
      );

      final removed = container.removeTopLayer();

      expect(removed?.color, equals(LiquidColor.red));
      expect(removed?.volume, equals(3)); // Combined top continuous layers
      expect(container.liquidLayers.length, equals(1));
      expect(container.topColor, equals(LiquidColor.blue));
    });

    test('should return null when removing from empty container', () {
      final emptyContainer = Container(id: 1, capacity: 4);

      expect(emptyContainer.removeTopLayer(), isNull);
    });

    test('should get unique colors correctly', () {
      final container = Container(
        id: 1,
        capacity: 6,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 1),
          const LiquidLayer(color: LiquidColor.blue, volume: 1),
          const LiquidLayer(color: LiquidColor.red, volume: 1),
          const LiquidLayer(color: LiquidColor.green, volume: 1),
        ],
      );

      final uniqueColors = container.uniqueColors;
      expect(uniqueColors.length, equals(3));
      expect(uniqueColors, contains(LiquidColor.red));
      expect(uniqueColors, contains(LiquidColor.blue));
      expect(uniqueColors, contains(LiquidColor.green));
    });

    test('should count color segments correctly', () {
      final container = Container(
        id: 1,
        capacity: 6,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 1),
          const LiquidLayer(
            color: LiquidColor.red,
            volume: 1,
          ), // Same color, same segment
          const LiquidLayer(color: LiquidColor.blue, volume: 1), // New segment
          const LiquidLayer(
            color: LiquidColor.red,
            volume: 1,
          ), // New segment (different from previous)
        ],
      );
      final emptyContainer = Container(id: 2, capacity: 4);

      expect(container.colorSegmentCount, equals(3));
      expect(emptyContainer.colorSegmentCount, equals(0));
    });

    test('should implement equality correctly', () {
      final container1 = Container(
        id: 1,
        capacity: 4,
        liquidLayers: [const LiquidLayer(color: LiquidColor.red, volume: 2)],
      );
      final container2 = Container(
        id: 1,
        capacity: 4,
        liquidLayers: [const LiquidLayer(color: LiquidColor.red, volume: 2)],
      );
      final container3 = Container(
        id: 2,
        capacity: 4,
        liquidLayers: [const LiquidLayer(color: LiquidColor.red, volume: 2)],
      );

      expect(container1, equals(container2));
      expect(container1, isNot(equals(container3)));
    });

    test('should have meaningful toString', () {
      final container = Container(
        id: 1,
        capacity: 4,
        liquidLayers: [const LiquidLayer(color: LiquidColor.red, volume: 2)],
      );

      final string = container.toString();
      expect(string, contains('1')); // id
      expect(string, contains('4')); // capacity
      expect(string, contains('2')); // volume
    });

    test('should serialize to and from JSON', () {
      final original = Container(
        id: 1,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 2),
          const LiquidLayer(color: LiquidColor.blue, volume: 1),
        ],
      );

      final json = original.toJson();
      expect(json['id'], equals(1));
      expect(json['capacity'], equals(4));
      expect(json['liquidLayers'], isA<List>());
      expect(json['liquidLayers'].length, equals(2));

      final deserialized = Container.fromJson(json);
      expect(deserialized, equals(original));
    });

    test('should handle complex pour scenarios', () {
      // Test scenario: pour from container with mixed layers
      final sourceContainer = Container(
        id: 1,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.blue, volume: 1),
          const LiquidLayer(color: LiquidColor.red, volume: 1),
          const LiquidLayer(color: LiquidColor.red, volume: 1),
        ],
      );

      final targetContainer = Container(
        id: 2,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.green, volume: 1),
          const LiquidLayer(color: LiquidColor.red, volume: 1),
        ],
      );

      // Should be able to pour red from source to target
      expect(targetContainer.canAcceptPour(LiquidColor.red, 2), isTrue);

      final poured = sourceContainer.removeTopLayer();
      expect(poured?.color, equals(LiquidColor.red));
      expect(poured?.volume, equals(2));

      targetContainer.addLiquid(poured!);
      expect(targetContainer.topColor, equals(LiquidColor.red));
      expect(targetContainer.topLayer?.volume, equals(3)); // 1 + 2 combined
      expect(sourceContainer.topColor, equals(LiquidColor.blue));
    });
  });
}
