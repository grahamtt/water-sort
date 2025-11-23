import 'package:flutter/material.dart';

/// Data model for test mode visual indicator
class TestModeIndicator {
  final String text;
  final Color color;
  final IconData icon;

  const TestModeIndicator({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestModeIndicator &&
        other.text == text &&
        other.color == color &&
        other.icon == icon;
  }

  @override
  int get hashCode => text.hashCode ^ color.hashCode ^ icon.hashCode;

  @override
  String toString() {
    return 'TestModeIndicator(text: $text, color: $color, icon: $icon)';
  }
}