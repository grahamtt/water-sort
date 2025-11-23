import '../models/game_state.dart';
import 'move_validator.dart';

/// Detects when the game is in a loss state (no valid moves and not solved)
class LossDetector {
  /// Check if the game is in a loss state
  /// A game is lost when:
  /// 1. The puzzle is not solved
  /// 2. No valid moves are available
  static bool hasLost(GameState gameState) {
    // If already won, not lost
    if (gameState.isCompleted || gameState.isSolved) {
      return false;
    }

    // Check if any valid moves exist
    final validMoves = MoveValidator.getAllValidMoves(gameState.containers);
    return validMoves.isEmpty;
  }

  /// Get a descriptive message for the loss condition
  static String getLossMessage(GameState gameState) {
    if (!hasLost(gameState)) {
      return "Game is not in a loss state";
    }

    return "No more valid moves available! The puzzle cannot be solved from this state.";
  }

  /// Get detailed information about why the game is lost (for debugging)
  static String getDetailedLossReason(GameState gameState) {
    if (!hasLost(gameState)) {
      return "Game is not in a loss state";
    }

    final containers = gameState.containers;
    final validMoves = MoveValidator.getAllValidMoves(containers);
    
    final buffer = StringBuffer();
    buffer.writeln("Loss detected:");
    buffer.writeln("- Puzzle is not solved: ${!gameState.isSolved}");
    buffer.writeln("- Valid moves available: ${validMoves.length}");
    buffer.writeln("- Total containers: ${containers.length}");
    
    int emptyContainers = 0;
    int fullContainers = 0;
    int sortedContainers = 0;
    
    for (int i = 0; i < containers.length; i++) {
      final container = containers[i];
      if (container.isEmpty) emptyContainers++;
      if (container.isFull) fullContainers++;
      if (container.isSorted) sortedContainers++;
    }
    
    buffer.writeln("- Empty containers: $emptyContainers");
    buffer.writeln("- Full containers: $fullContainers");
    buffer.writeln("- Sorted containers: $sortedContainers");
    
    return buffer.toString();
  }
}