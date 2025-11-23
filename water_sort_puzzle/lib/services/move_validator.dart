import '../models/container.dart';
import '../models/liquid_color.dart';

/// Represents a valid move that can be made in the game
class ValidMove {
  /// The index of the source container
  final int fromContainer;

  /// The index of the target container
  final int toContainer;

  /// The color of the liquid being moved
  final LiquidColor liquidColor;

  /// The volume of liquid being moved
  final int volume;

  const ValidMove({
    required this.fromContainer,
    required this.toContainer,
    required this.liquidColor,
    required this.volume,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValidMove &&
        other.fromContainer == fromContainer &&
        other.toContainer == toContainer &&
        other.liquidColor == liquidColor &&
        other.volume == volume;
  }

  @override
  int get hashCode => Object.hash(fromContainer, toContainer, liquidColor, volume);

  @override
  String toString() {
    return 'ValidMove(from: $fromContainer, to: $toContainer, '
           'color: $liquidColor, volume: $volume)';
  }
}

/// Validates moves and finds all possible valid moves in the current game state
class MoveValidator {
  /// Get all valid moves that can be made with the current container configuration
  static List<ValidMove> getAllValidMoves(List<Container> containers) {
    final validMoves = <ValidMove>[];

    for (int fromIndex = 0; fromIndex < containers.length; fromIndex++) {
      final fromContainer = containers[fromIndex];
      
      // Skip empty containers - nothing to pour
      if (fromContainer.isEmpty) continue;

      final topLayer = fromContainer.getTopContinuousLayer()!;

      for (int toIndex = 0; toIndex < containers.length; toIndex++) {
        // Can't pour to the same container
        if (fromIndex == toIndex) continue;

        final toContainer = containers[toIndex];

        if (_canPourTo(fromContainer, toContainer, topLayer.color)) {
          final volume = _calculatePourVolume(fromContainer, toContainer, topLayer);
          
          // Only add if there's actually liquid to pour
          if (volume > 0) {
            validMoves.add(ValidMove(
              fromContainer: fromIndex,
              toContainer: toIndex,
              liquidColor: topLayer.color,
              volume: volume,
            ));
          }
        }
      }
    }

    return validMoves;
  }

  /// Check if liquid can be poured from source to target container
  static bool _canPourTo(Container from, Container to, LiquidColor liquidColor) {
    // Target container must have space
    if (to.isFull) return false;

    // If target is empty, can accept any color
    if (to.isEmpty) return true;

    // If target is not empty, colors must match
    return to.topColor == liquidColor;
  }

  /// Calculate how much liquid can be poured from source to target
  static int _calculatePourVolume(Container from, Container to, topLayer) {
    // Get the continuous volume of the same color from the top
    final continuousVolume = topLayer.volume;

    // Limit by target container's available capacity
    final availableSpace = to.remainingCapacity;

    return continuousVolume < availableSpace ? continuousVolume : availableSpace;
  }
}