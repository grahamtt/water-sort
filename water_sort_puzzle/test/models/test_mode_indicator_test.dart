import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/test_mode_indicator.dart';

void main() {
  group('TestModeIndicator', () {
    test('should create instance with required properties', () {
      const indicator = TestModeIndicator(
        text: 'TEST MODE',
        color: Colors.orange,
        icon: Icons.bug_report,
      );

      expect(indicator.text, equals('TEST MODE'));
      expect(indicator.color, equals(Colors.orange));
      expect(indicator.icon, equals(Icons.bug_report));
    });

    test('should support equality comparison', () {
      const indicator1 = TestModeIndicator(
        text: 'TEST MODE',
        color: Colors.orange,
        icon: Icons.bug_report,
      );
      
      const indicator2 = TestModeIndicator(
        text: 'TEST MODE',
        color: Colors.orange,
        icon: Icons.bug_report,
      );
      
      const indicator3 = TestModeIndicator(
        text: 'DEBUG MODE',
        color: Colors.orange,
        icon: Icons.bug_report,
      );

      expect(indicator1, equals(indicator2));
      expect(indicator1, isNot(equals(indicator3)));
    });

    test('should have consistent hashCode for equal objects', () {
      const indicator1 = TestModeIndicator(
        text: 'TEST MODE',
        color: Colors.orange,
        icon: Icons.bug_report,
      );
      
      const indicator2 = TestModeIndicator(
        text: 'TEST MODE',
        color: Colors.orange,
        icon: Icons.bug_report,
      );

      expect(indicator1.hashCode, equals(indicator2.hashCode));
    });

    test('should have different hashCode for different objects', () {
      const indicator1 = TestModeIndicator(
        text: 'TEST MODE',
        color: Colors.orange,
        icon: Icons.bug_report,
      );
      
      const indicator2 = TestModeIndicator(
        text: 'DEBUG MODE',
        color: Colors.red,
        icon: Icons.developer_mode,
      );

      expect(indicator1.hashCode, isNot(equals(indicator2.hashCode)));
    });

    test('should provide meaningful toString representation', () {
      const indicator = TestModeIndicator(
        text: 'TEST MODE',
        color: Colors.orange,
        icon: Icons.bug_report,
      );

      final stringRepresentation = indicator.toString();
      
      expect(stringRepresentation, contains('TestModeIndicator'));
      expect(stringRepresentation, contains('TEST MODE'));
      expect(stringRepresentation, contains('color:'));
      expect(stringRepresentation, contains('icon:'));
    });

    test('should handle different text values', () {
      const indicators = [
        TestModeIndicator(text: 'TEST', color: Colors.red, icon: Icons.science),
        TestModeIndicator(text: 'DEBUG', color: Colors.blue, icon: Icons.bug_report),
        TestModeIndicator(text: 'PREVIEW', color: Colors.green, icon: Icons.preview),
        TestModeIndicator(text: '', color: Colors.grey, icon: Icons.help),
      ];

      for (final indicator in indicators) {
        expect(indicator.text, isA<String>());
        expect(indicator.color, isA<Color>());
        expect(indicator.icon, isA<IconData>());
      }
    });

    test('should handle different color values', () {
      const colors = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.amber,
        Colors.teal,
      ];

      for (final color in colors) {
        final indicator = TestModeIndicator(
          text: 'TEST',
          color: color,
          icon: Icons.star,
        );
        
        expect(indicator.color, equals(color));
      }
    });

    test('should handle different icon values', () {
      const icons = [
        Icons.bug_report,
        Icons.developer_mode,
        Icons.preview,
        Icons.science,
        Icons.settings,
        Icons.help,
        Icons.star,
      ];

      for (final icon in icons) {
        final indicator = TestModeIndicator(
          text: 'TEST',
          color: Colors.blue,
          icon: icon,
        );
        
        expect(indicator.icon, equals(icon));
      }
    });

    test('should be immutable', () {
      const indicator = TestModeIndicator(
        text: 'TEST MODE',
        color: Colors.orange,
        icon: Icons.bug_report,
      );

      // Properties should be final and cannot be changed
      expect(() => indicator.text, returnsNormally);
      expect(() => indicator.color, returnsNormally);
      expect(() => indicator.icon, returnsNormally);
    });

    test('should work with const constructor', () {
      // This test verifies that the constructor can be used in const contexts
      const indicator = TestModeIndicator(
        text: 'CONST TEST',
        color: Colors.indigo,
        icon: Icons.construction,
      );

      expect(indicator.text, equals('CONST TEST'));
      expect(indicator.color, equals(Colors.indigo));
      expect(indicator.icon, equals(Icons.construction));
    });

    test('equality should consider all properties', () {
      const baseIndicator = TestModeIndicator(
        text: 'TEST',
        color: Colors.orange,
        icon: Icons.bug_report,
      );

      // Different text
      const differentText = TestModeIndicator(
        text: 'DEBUG',
        color: Colors.orange,
        icon: Icons.bug_report,
      );

      // Different color
      const differentColor = TestModeIndicator(
        text: 'TEST',
        color: Colors.red,
        icon: Icons.bug_report,
      );

      // Different icon
      const differentIcon = TestModeIndicator(
        text: 'TEST',
        color: Colors.orange,
        icon: Icons.developer_mode,
      );

      expect(baseIndicator, isNot(equals(differentText)));
      expect(baseIndicator, isNot(equals(differentColor)));
      expect(baseIndicator, isNot(equals(differentIcon)));
    });
  });
}