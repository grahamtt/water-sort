import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

/// Enum representing different liquid colors in the water sort puzzle
@JsonEnum()
enum LiquidColor {
  @JsonValue('red')
  red(0xFFE53E3E, 'Red'),
  
  @JsonValue('blue')
  blue(0xFF3182CE, 'Blue'),
  
  @JsonValue('green')
  green(0xFF38A169, 'Green'),
  
  @JsonValue('yellow')
  yellow(0xFFD69E2E, 'Yellow'),
  
  @JsonValue('purple')
  purple(0xFF805AD5, 'Purple'),
  
  @JsonValue('orange')
  orange(0xFFDD6B20, 'Orange'),
  
  @JsonValue('pink')
  pink(0xFFED64A6, 'Pink'),
  
  @JsonValue('cyan')
  cyan(0xFF0BC5EA, 'Cyan'),
  
  @JsonValue('brown')
  brown(0xFF8B4513, 'Brown'),
  
  @JsonValue('lime')
  lime(0xFF68D391, 'Lime');

  const LiquidColor(this.value, this.displayName);
  
  /// The color value as an integer
  final int value;
  
  /// Human-readable name for the color
  final String displayName;
  
  /// Convert to Flutter Color object
  Color get color => Color(value);
  
  /// Get a darker shade of the color for visual effects
  Color get darkColor => Color.lerp(color, Colors.black, 0.2) ?? color;
  
  /// Get a lighter shade of the color for visual effects
  Color get lightColor => Color.lerp(color, Colors.white, 0.2) ?? color;
}