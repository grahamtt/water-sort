import '../models/game_state.dart';
import '../models/pour_result.dart';
import '../models/container.dart';
import '../models/move.dart';
import 'audio_manager.dart';

/// Abstract base class for the water sort puzzle game engine
abstract class GameEngine {
  /// Initialize a new level with the given containers
  GameState initializeLevel(int levelId, List<Container> containers);
  
  /// Attempt to pour liquid from one container to another
  PourResult attemptPour(GameState currentState, int fromContainerId, int toContainerId);
  
  /// Undo the last move if possible
  GameState? undoLastMove(GameState currentState);
  
  /// Redo the next move if possible
  GameState? redoNextMove(GameState currentState);
  
  /// Check if the current game state represents a win condition
  bool checkWinCondition(GameState gameState);
  
  /// Validate if a pour operation is allowed
  PourResult validatePour(GameState gameState, int fromContainerId, int toContainerId);
  
  /// Execute a validated pour operation and return the new game state
  GameState executePour(GameState currentState, int fromContainerId, int toContainerId);
  
  /// Check if any legal moves exist in the current game state
  bool hasLegalMoves(GameState gameState);
  
  /// Check if the current game state represents a loss condition (no legal moves)
  bool checkLossCondition(GameState gameState);
}

/// Concrete implementation of the game engine
class WaterSortGameEngine implements GameEngine {
  final AudioManager _audioManager = AudioManager();
  @override
  GameState initializeLevel(int levelId, List<Container> containers) {
    // Create deep copies of containers to avoid reference issues
    final containerCopies = containers.map((c) => c.copyWith()).toList();
    
    return GameState.initial(
      levelId: levelId,
      containers: containerCopies,
    );
  }
  
  @override
  PourResult attemptPour(GameState currentState, int fromContainerId, int toContainerId) {
    // First validate the pour
    final validationResult = validatePour(currentState, fromContainerId, toContainerId);
    
    if (validationResult.isFailure) {
      // Play error sound and haptic feedback for invalid moves
      _audioManager.playErrorSound();
      _audioManager.lightHaptic();
      return validationResult;
    }
    
    // If validation passed, execute the pour
    final sourceContainer = currentState.getContainer(fromContainerId)!;
    final liquidToPour = sourceContainer.getTopContinuousLayer()!;
    
    // Play pour sound and haptic feedback for successful moves
    _audioManager.playPourSound();
    _audioManager.mediumHaptic();
    
    final move = Move(
      fromContainerId: fromContainerId,
      toContainerId: toContainerId,
      liquidMoved: liquidToPour,
      timestamp: DateTime.now(),
    );
    
    return PourSuccess(move);
  }
  
  @override
  GameState? undoLastMove(GameState currentState) {
    return currentState.undoMove();
  }
  
  @override
  GameState? redoNextMove(GameState currentState) {
    return currentState.redoMove();
  }
  
  @override
  bool checkWinCondition(GameState gameState) {
    return gameState.isSolved;
  }
  
  @override
  PourResult validatePour(GameState gameState, int fromContainerId, int toContainerId) {
    // Check if source and target are the same
    if (fromContainerId == toContainerId) {
      return PourFailureSameContainer(fromContainerId);
    }
    
    // Get source container
    final sourceContainer = gameState.getContainer(fromContainerId);
    if (sourceContainer == null) {
      return PourFailureInvalidContainer(fromContainerId);
    }
    
    // Get target container
    final targetContainer = gameState.getContainer(toContainerId);
    if (targetContainer == null) {
      return PourFailureInvalidContainer(toContainerId);
    }
    
    // Check if source container is empty
    if (sourceContainer.isEmpty) {
      return PourFailureEmptySource(fromContainerId);
    }
    
    // Check if target container is full
    if (targetContainer.isFull) {
      return PourFailureContainerFull(toContainerId);
    }
    
    // Get the liquid that would be poured
    final liquidToPour = sourceContainer.getTopContinuousLayer()!;
    
    // Check if target container can accept this liquid
    if (!targetContainer.canAcceptPour(liquidToPour.color, liquidToPour.volume)) {
      // Check if it's a color mismatch or capacity issue
      if (!targetContainer.isEmpty && targetContainer.topColor != liquidToPour.color) {
        return PourFailureColorMismatch(liquidToPour.color, targetContainer.topColor!);
      } else {
        return PourFailureInsufficientCapacity(
          toContainerId,
          liquidToPour.volume,
          targetContainer.remainingCapacity,
        );
      }
    }
    
    // If we get here, the pour is valid
    // Return a success result with a placeholder move (the actual move will be created in attemptPour)
    final move = Move(
      fromContainerId: fromContainerId,
      toContainerId: toContainerId,
      liquidMoved: liquidToPour,
      timestamp: DateTime.now(),
    );
    
    return PourSuccess(move);
  }
  
  @override
  GameState executePour(GameState currentState, int fromContainerId, int toContainerId) {
    // Validate the pour first
    final validationResult = validatePour(currentState, fromContainerId, toContainerId);
    if (validationResult.isFailure) {
      throw ArgumentError('Cannot execute invalid pour: ${validationResult.toString()}');
    }
    
    // Create copies of all containers
    final newContainers = currentState.containers.map((c) => c.copyWith()).toList();
    
    // Find the source and target containers in the new list
    final sourceContainer = newContainers.firstWhere((c) => c.id == fromContainerId);
    final targetContainer = newContainers.firstWhere((c) => c.id == toContainerId);
    
    // Get the liquid to pour before removing it
    final liquidToPour = sourceContainer.getTopContinuousLayer()!;
    
    // Execute the pour
    sourceContainer.removeTopLayer();
    targetContainer.addLiquid(liquidToPour);
    
    // Create the move record
    final move = Move(
      fromContainerId: fromContainerId,
      toContainerId: toContainerId,
      liquidMoved: liquidToPour,
      timestamp: DateTime.now(),
    );
    
    // Create the new game state with the move added
    final newState = currentState.addMove(move, newContainers);
    
    // Check if the game is now in a lost state (no legal moves remaining)
    final isLost = checkLossCondition(newState);
    
    // Return the new game state with loss condition updated
    return newState.copyWith(isLost: isLost);
  }
  
  @override
  bool hasLegalMoves(GameState gameState) {
    // If the game is already solved, no need to check for moves
    if (gameState.isSolved) return false;
    
    // Try all possible combinations of source and target containers
    for (final sourceContainer in gameState.containers) {
      // Skip empty containers as they can't be poured from
      if (sourceContainer.isEmpty) continue;
      
      // Skip containers that are already sorted and full
      // (no point in pouring from a solved container)
      if (sourceContainer.isSorted && sourceContainer.isFull) continue;
      
      for (final targetContainer in gameState.containers) {
        // Skip if source and target are the same
        if (sourceContainer.id == targetContainer.id) continue;
        
        // Check if this pour would be valid
        final result = validatePour(
          gameState,
          sourceContainer.id,
          targetContainer.id,
        );
        
        if (result.isSuccess) {
          // Found at least one legal move
          return true;
        }
      }
    }
    
    // No legal moves found
    return false;
  }
  
  @override
  bool checkLossCondition(GameState gameState) {
    // Game is not lost if it's already solved
    if (gameState.isSolved) return false;
    
    // Game is lost if there are no legal moves remaining
    return !hasLegalMoves(gameState);
  }
}