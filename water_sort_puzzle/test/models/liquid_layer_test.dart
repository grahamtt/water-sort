import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';

void main() {
  group('LiquidLayer', () {
    test('should create liquid layer with correct properties', () {
      const layer = LiquidLayer(color: LiquidColor.red, volume: 3);
      
      expect(layer.color, equals(LiquidColor.red));
      expect(layer.volume, equals(3));
    });

    test('should create copy with modified properties', () {
      const original = LiquidLayer(color: LiquidColor.red, volume: 3);
      
      final copyWithNewColor = original.copyWith(color: LiquidColor.blue);
      expect(copyWithNewColor.color, equals(LiquidColor.blue));
      expect(copyWithNewColor.volume, equals(3));
      
      final copyWithNewVolume = original.copyWith(volume: 5);
      expect(copyWithNewVolume.color, equals(LiquidColor.red));
      expect(copyWithNewVolume.volume, equals(5));
      
      final copyWithBoth = original.copyWith(color: LiquidColor.green, volume: 7);
      expect(copyWithBoth.color, equals(LiquidColor.green));
      expect(copyWithBoth.volume, equals(7));
    });

    test('should check if layers can be combined', () {
      const redLayer1 = LiquidLayer(color: LiquidColor.red, volume: 2);
      const redLayer2 = LiquidLayer(color: LiquidColor.red, volume: 3);
      const blueLayer = LiquidLayer(color: LiquidColor.blue, volume: 2);
      
      expect(redLayer1.canCombineWith(redLayer2), isTrue);
      expect(redLayer1.canCombineWith(blueLayer), isFalse);
      expect(blueLayer.canCombineWith(redLayer1), isFalse);
    });

    test('should combine layers of same color', () {
      const layer1 = LiquidLayer(color: LiquidColor.red, volume: 2);
      const layer2 = LiquidLayer(color: LiquidColor.red, volume: 3);
      
      final combined = layer1.combineWith(layer2);
      
      expect(combined.color, equals(LiquidColor.red));
      expect(combined.volume, equals(5));
    });

    test('should throw error when combining different colors', () {
      const redLayer = LiquidLayer(color: LiquidColor.red, volume: 2);
      const blueLayer = LiquidLayer(color: LiquidColor.blue, volume: 3);
      
      expect(
        () => redLayer.combineWith(blueLayer),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should split layer correctly', () {
      const layer = LiquidLayer(color: LiquidColor.red, volume: 5);
      
      final split = layer.split(2);
      
      expect(split.length, equals(2));
      expect(split[0].color, equals(LiquidColor.red));
      expect(split[0].volume, equals(3)); // remaining
      expect(split[1].color, equals(LiquidColor.red));
      expect(split[1].volume, equals(2)); // split off
    });

    test('should throw error for invalid split volumes', () {
      const layer = LiquidLayer(color: LiquidColor.red, volume: 5);
      
      expect(() => layer.split(0), throwsA(isA<ArgumentError>()));
      expect(() => layer.split(-1), throwsA(isA<ArgumentError>()));
      expect(() => layer.split(5), throwsA(isA<ArgumentError>()));
      expect(() => layer.split(6), throwsA(isA<ArgumentError>()));
    });

    test('should implement equality correctly', () {
      const layer1 = LiquidLayer(color: LiquidColor.red, volume: 3);
      const layer2 = LiquidLayer(color: LiquidColor.red, volume: 3);
      const layer3 = LiquidLayer(color: LiquidColor.blue, volume: 3);
      const layer4 = LiquidLayer(color: LiquidColor.red, volume: 2);
      
      expect(layer1, equals(layer2));
      expect(layer1, isNot(equals(layer3)));
      expect(layer1, isNot(equals(layer4)));
    });

    test('should implement hashCode correctly', () {
      const layer1 = LiquidLayer(color: LiquidColor.red, volume: 3);
      const layer2 = LiquidLayer(color: LiquidColor.red, volume: 3);
      const layer3 = LiquidLayer(color: LiquidColor.blue, volume: 3);
      
      expect(layer1.hashCode, equals(layer2.hashCode));
      expect(layer1.hashCode, isNot(equals(layer3.hashCode)));
    });

    test('should have meaningful toString', () {
      const layer = LiquidLayer(color: LiquidColor.red, volume: 3);
      final string = layer.toString();
      
      expect(string, contains('Red'));
      expect(string, contains('3'));
    });

    test('should serialize to and from JSON', () {
      const original = LiquidLayer(color: LiquidColor.red, volume: 3);
      
      final json = original.toJson();
      expect(json['color'], equals('red'));
      expect(json['volume'], equals(3));
      
      final deserialized = LiquidLayer.fromJson(json);
      expect(deserialized, equals(original));
    });

    test('should handle all color types in JSON serialization', () {
      for (final color in LiquidColor.values) {
        final layer = LiquidLayer(color: color, volume: 1);
        final json = layer.toJson();
        final deserialized = LiquidLayer.fromJson(json);
        
        expect(deserialized.color, equals(color));
        expect(deserialized.volume, equals(1));
      }
    });
  });
}