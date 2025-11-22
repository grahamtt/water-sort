import 'package:json_annotation/json_annotation.dart';
import 'liquid_layer.dart';

part 'move.g.dart';

/// Represents a single move in the water sort puzzle game
@JsonSerializable(explicitToJson: true)
class Move {
  /// The ID of the source container
  final int fromContainerId;
  
  /// The ID of the target container
  final int toContainerId;
  
  /// The liquid layer that was moved
  final LiquidLayer liquidMoved;
  
  /// Timestamp when the move was made
  final DateTime timestamp;
  
  const Move({
    required this.fromContainerId,
    required this.toContainerId,
    required this.liquidMoved,
    required this.timestamp,
  });
  
  /// Create a copy of this move with optional parameter overrides
  Move copyWith({
    int? fromContainerId,
    int? toContainerId,
    LiquidLayer? liquidMoved,
    DateTime? timestamp,
  }) {
    return Move(
      fromContainerId: fromContainerId ?? this.fromContainerId,
      toContainerId: toContainerId ?? this.toContainerId,
      liquidMoved: liquidMoved ?? this.liquidMoved,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Move &&
        other.fromContainerId == fromContainerId &&
        other.toContainerId == toContainerId &&
        other.liquidMoved == liquidMoved &&
        other.timestamp == timestamp;
  }
  
  @override
  int get hashCode => Object.hash(
    fromContainerId,
    toContainerId,
    liquidMoved,
    timestamp,
  );
  
  @override
  String toString() {
    return 'Move(from: $fromContainerId, to: $toContainerId, '
           'liquid: $liquidMoved, time: $timestamp)';
  }
  
  /// JSON serialization
  factory Move.fromJson(Map<String, dynamic> json) => _$MoveFromJson(json);
  
  /// JSON deserialization
  Map<String, dynamic> toJson() => _$MoveToJson(this);
}