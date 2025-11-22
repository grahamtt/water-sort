import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';

void main() {
  group('LiquidColor', () {
    test('should have correct color values', () {
      expect(LiquidColor.red.value, equals(0xFFE53E3E));
      expect(LiquidColor.blue.value, equals(0xFF3182CE));
      expect(LiquidColor.green.value, equals(0xFF38A169));
      expect(LiquidColor.yellow.value, equals(0xFFD69E2E));
      expect(LiquidColor.purple.value, equals(0xFF805AD5));
      expect(LiquidColor.orange.value, equals(0xFFDD6B20));
      expect(LiquidColor.pink.value, equals(0xFFED64A6));
      expect(LiquidColor.cyan.value, equals(0xFF0BC5EA));
      expect(LiquidColor.brown.value, equals(0xFF8B4513));
      expect(LiquidColor.lime.value, equals(0xFF68D391));
    });

    test('should have correct display names', () {
      expect(LiquidColor.red.displayName, equals('Red'));
      expect(LiquidColor.blue.displayName, equals('Blue'));
      expect(LiquidColor.green.displayName, equals('Green'));
      expect(LiquidColor.yellow.displayName, equals('Yellow'));
      expect(LiquidColor.purple.displayName, equals('Purple'));
      expect(LiquidColor.orange.displayName, equals('Orange'));
      expect(LiquidColor.pink.displayName, equals('Pink'));
      expect(LiquidColor.cyan.displayName, equals('Cyan'));
      expect(LiquidColor.brown.displayName, equals('Brown'));
      expect(LiquidColor.lime.displayName, equals('Lime'));
    });

    test('should convert to Flutter Color correctly', () {
      final redColor = LiquidColor.red.color;
      expect(redColor, isA<Color>());
      expect(redColor, equals(const Color(0xFFE53E3E)));
      
      final blueColor = LiquidColor.blue.color;
      expect(blueColor, equals(const Color(0xFF3182CE)));
    });

    test('should provide dark color variant', () {
      final redDark = LiquidColor.red.darkColor;
      expect(redDark, isA<Color>());
      // Dark color should be different from original
      expect(redDark, isNot(equals(LiquidColor.red.color)));
    });

    test('should provide light color variant', () {
      final redLight = LiquidColor.red.lightColor;
      expect(redLight, isA<Color>());
      // Light color should be different from original
      expect(redLight, isNot(equals(LiquidColor.red.color)));
    });

    test('should have all expected colors', () {
      final allColors = LiquidColor.values;
      expect(allColors.length, equals(10));
      expect(allColors, contains(LiquidColor.red));
      expect(allColors, contains(LiquidColor.blue));
      expect(allColors, contains(LiquidColor.green));
      expect(allColors, contains(LiquidColor.yellow));
      expect(allColors, contains(LiquidColor.purple));
      expect(allColors, contains(LiquidColor.orange));
      expect(allColors, contains(LiquidColor.pink));
      expect(allColors, contains(LiquidColor.cyan));
      expect(allColors, contains(LiquidColor.brown));
      expect(allColors, contains(LiquidColor.lime));
    });
  });
}