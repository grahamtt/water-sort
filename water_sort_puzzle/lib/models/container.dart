import 'package:json_annotation/json_annotation.dart';
import 'liquid_color.dart';
import 'liquid_layer.dart';

part 'container.g.dart';

/// Represents a container that holds liquid layers in the water sort puzzle
@JsonSerializable(explicitToJson: true)
class Container {
  /// Unique identifier for this container
  final int id;
  
  /// Maximum capacity of the container (number of liquid units it can hold)
  final int capacity;
  
  /// List of liquid layers from bottom to top
  final List<LiquidLayer> liquidLayers;
  
  Container({
    required this.id,
    required this.capacity,
    List<LiquidLayer>? liquidLayers,
  }) : liquidLayers = liquidLayers ?? [];
  
  /// Create a copy of this container with optional parameter overrides
  Container copyWith({
    int? id,
    int? capacity,
    List<LiquidLayer>? liquidLayers,
  }) {
    return Container(
      id: id ?? this.id,
      capacity: capacity ?? this.capacity,
      liquidLayers: liquidLayers ?? List.from(this.liquidLayers),
    );
  }
  
  /// Get the current volume of liquid in the container
  int get currentVolume {
    return liquidLayers.fold(0, (sum, layer) => sum + layer.volume);
  }
  
  /// Get the remaining capacity of the container
  int get remainingCapacity {
    return capacity - currentVolume;
  }
  
  /// Check if the container is empty
  bool get isEmpty {
    return liquidLayers.isEmpty;
  }
  
  /// Check if the container is full
  bool get isFull {
    return currentVolume >= capacity;
  }
  
  /// Check if the container contains only one color (solved state)
  bool get isSorted {
    if (isEmpty) return true;
    
    final firstColor = liquidLayers.first.color;
    return liquidLayers.every((layer) => layer.color == firstColor);
  }
  
  /// Get the top liquid layer (null if empty)
  LiquidLayer? get topLayer {
    return liquidLayers.isEmpty ? null : liquidLayers.last;
  }
  
  /// Get the color of the top layer (null if empty)
  LiquidColor? get topColor {
    return topLayer?.color;
  }
  
  /// Check if a pour of the specified color can be accepted
  bool canAcceptPour(LiquidColor liquidColor, int volume) {
    // Check if there's enough capacity
    if (volume > remainingCapacity) return false;
    
    // If empty, can accept any color
    if (isEmpty) return true;
    
    // If not empty, can only accept matching color
    return topColor == liquidColor;
  }
  
  /// Check if liquid can be poured from this container
  bool canPourFrom() {
    return !isEmpty;
  }
  
  /// Get the top continuous layer of the same color that can be poured
  LiquidLayer? getTopContinuousLayer() {
    if (isEmpty) return null;
    
    final topColor = this.topColor!;
    int continuousVolume = 0;
    
    // Count from top down while colors match
    for (int i = liquidLayers.length - 1; i >= 0; i--) {
      if (liquidLayers[i].color == topColor) {
        continuousVolume += liquidLayers[i].volume;
      } else {
        break;
      }
    }
    
    return LiquidLayer(color: topColor, volume: continuousVolume);
  }
  
  /// Add liquid to the container
  void addLiquid(LiquidLayer layer) {
    if (!canAcceptPour(layer.color, layer.volume)) {
      throw ArgumentError('Cannot add liquid: incompatible color or insufficient capacity');
    }
    
    // If the top layer has the same color, combine them
    if (!isEmpty && topColor == layer.color) {
      final topLayer = liquidLayers.removeLast();
      liquidLayers.add(topLayer.combineWith(layer));
    } else {
      liquidLayers.add(layer);
    }
  }
  
  /// Remove and return the top continuous layer of the same color
  LiquidLayer? removeTopLayer() {
    if (isEmpty) return null;
    
    final topContinuous = getTopContinuousLayer()!;
    final topColor = this.topColor!;
    int volumeToRemove = topContinuous.volume;
    
    // Remove layers from top down until we've removed the required volume
    while (volumeToRemove > 0 && !isEmpty) {
      final currentTop = liquidLayers.last;
      if (currentTop.color != topColor) break;
      
      if (currentTop.volume <= volumeToRemove) {
        // Remove entire layer
        liquidLayers.removeLast();
        volumeToRemove -= currentTop.volume;
      } else {
        // Split the layer
        final split = currentTop.split(volumeToRemove);
        liquidLayers[liquidLayers.length - 1] = split[0]; // Keep remaining part
        volumeToRemove = 0;
      }
    }
    
    return topContinuous;
  }
  
  /// Remove a specific volume of liquid from the top of the container
  /// Returns the liquid layer that was removed, or null if not possible
  LiquidLayer? removeSpecificVolume(LiquidColor color, int volume) {
    if (isEmpty || topColor != color) return null;
    
    int volumeToRemove = volume;
    final removedLayers = <LiquidLayer>[];
    
    // Remove layers from top down until we've removed the required volume
    while (volumeToRemove > 0 && !isEmpty && topColor == color) {
      final currentTop = liquidLayers.last;
      
      if (currentTop.volume <= volumeToRemove) {
        // Remove entire layer
        final removed = liquidLayers.removeLast();
        removedLayers.add(removed);
        volumeToRemove -= removed.volume;
      } else {
        // Split the layer
        final split = currentTop.split(volumeToRemove);
        liquidLayers[liquidLayers.length - 1] = split[0]; // Keep remaining part
        removedLayers.add(split[1]); // Add removed part
        volumeToRemove = 0;
      }
    }
    
    // Combine all removed layers into one
    if (removedLayers.isEmpty) return null;
    
    int totalVolume = removedLayers.fold(0, (sum, layer) => sum + layer.volume);
    return LiquidLayer(color: color, volume: totalVolume);
  }
  
  /// Get a list of all unique colors in the container from bottom to top
  List<LiquidColor> get uniqueColors {
    return liquidLayers.map((layer) => layer.color).toSet().toList();
  }
  
  /// Get the number of different color segments in the container
  int get colorSegmentCount {
    if (isEmpty) return 0;
    
    int segments = 1;
    for (int i = 1; i < liquidLayers.length; i++) {
      if (liquidLayers[i].color != liquidLayers[i - 1].color) {
        segments++;
      }
    }
    return segments;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Container &&
        other.id == id &&
        other.capacity == capacity &&
        _listEquals(other.liquidLayers, liquidLayers);
  }
  
  @override
  int get hashCode => Object.hash(id, capacity, Object.hashAll(liquidLayers));
  
  @override
  String toString() {
    return 'Container(id: $id, capacity: $capacity, layers: ${liquidLayers.length}, volume: $currentVolume)';
  }
  
  /// Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  
  /// JSON serialization
  factory Container.fromJson(Map<String, dynamic> json) =>
      _$ContainerFromJson(json);
  
  /// JSON deserialization
  Map<String, dynamic> toJson() => _$ContainerToJson(this);
}