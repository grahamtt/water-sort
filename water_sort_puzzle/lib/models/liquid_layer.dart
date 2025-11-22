import 'package:json_annotation/json_annotation.dart';
import 'liquid_color.dart';

part 'liquid_layer.g.dart';

/// Represents a layer of liquid in a container
@JsonSerializable()
class LiquidLayer {
  /// The color of this liquid layer
  final LiquidColor color;
  
  /// The volume/amount of liquid in this layer (typically 1 unit)
  final int volume;
  
  const LiquidLayer({
    required this.color,
    required this.volume,
  });
  
  /// Create a copy of this layer with optional parameter overrides
  LiquidLayer copyWith({
    LiquidColor? color,
    int? volume,
  }) {
    return LiquidLayer(
      color: color ?? this.color,
      volume: volume ?? this.volume,
    );
  }
  
  /// Check if this layer can be combined with another layer
  bool canCombineWith(LiquidLayer other) {
    return color == other.color;
  }
  
  /// Combine this layer with another layer of the same color
  LiquidLayer combineWith(LiquidLayer other) {
    if (!canCombineWith(other)) {
      throw ArgumentError('Cannot combine layers of different colors');
    }
    return LiquidLayer(
      color: color,
      volume: volume + other.volume,
    );
  }
  
  /// Split this layer into two layers with the specified volumes
  /// Returns a list with [remaining layer, split layer]
  List<LiquidLayer> split(int splitVolume) {
    if (splitVolume <= 0 || splitVolume >= volume) {
      throw ArgumentError('Split volume must be between 0 and $volume');
    }
    
    return [
      LiquidLayer(color: color, volume: volume - splitVolume),
      LiquidLayer(color: color, volume: splitVolume),
    ];
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiquidLayer &&
        other.color == color &&
        other.volume == volume;
  }
  
  @override
  int get hashCode => Object.hash(color, volume);
  
  @override
  String toString() {
    return 'LiquidLayer(color: ${color.displayName}, volume: $volume)';
  }
  
  /// JSON serialization
  factory LiquidLayer.fromJson(Map<String, dynamic> json) =>
      _$LiquidLayerFromJson(json);
  
  /// JSON deserialization
  Map<String, dynamic> toJson() => _$LiquidLayerToJson(this);
}