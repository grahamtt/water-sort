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
  final AudioManager _audioManager;
  
  WaterSortGameEngine({AudioManager? audioManager})
      : _audioManager = audioManager ?? AudioManager();
  
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
    
    // Return the new game state with the move added
    return currentState.addMove(move, newContainers);
  }
  
  @override
  bool hasLegalMoves(GameState gameState) {
    // Check if any valid pour exists
    for (int fromId = 0; fromId < gameState.containers.length; fromId++) {
      for (int toId = 0; toId < gameState.containers.length; toId++) {
        if (fromId == toId) continue;
        
        final result = validatePour(gameState, fromId, toId);
        if (result.isSuccess) {
          return true;
        }
      }
    }
    return false;
  }
  
  @override
  bool checkLossCondition(GameState gameState) {
    // A loss occurs when the game is not solved and there are no legal moves
    return !checkWinCondition(gameState) && !hasLegalMoves(gameState);
  }
}