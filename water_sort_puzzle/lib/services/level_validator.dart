import '../models/level.dart';
import '../models/container.dart';
import '../models/liquid_layer.dart';
import '../models/game_state.dart';
import '../services/game_engine.dart';
import '../services/audio_manager.dart';

/// Validates generated levels to ensure they meet all requirements
class LevelValidator {
  /// Validates that a generated level meets all requirements
  /// 
  /// This method checks:
  /// - Level is not already in a solved state
  /// - No containers are already completed (single color and full)
  /// - Level has proper structure and constraints
  static bool validateGeneratedLevel(Level level) {
    // Check if level is already solved
    if (_isAlreadySolved(level)) {
      return false;
    }

    // Check if any containers are already completed
    if (_hasCompletedContainers(level)) {
      return false;
    }

    // Check structural validity
    if (!level.isStructurallyValid) {
      return false;
    }

    return true;
  }

  /// Checks if the level is already in a solved state
  /// 
  /// A level is solved if all non-empty containers contain only one color
  static bool _isAlreadySolved(Level level) {
    for (final container in level.initialContainers) {
      if (container.isEmpty) continue;

      // If container has mixed colors, level is not solved
      if (!container.isSorted) {
        return false;
      }
    }

    // All containers are either empty or contain only one color
    return true;
  }

  /// Checks if any containers are already completed
  /// 
  /// A completed container is one that contains only one color AND is full
  /// This violates requirement 9.9 which states no containers should be completed
  /// in the initial state
  static bool _hasCompletedContainers(Level level) {
    for (final container in level.initialContainers) {
      if (_isContainerCompleted(container)) {
        return true;
      }
    }
    return false;
  }

  /// Determines if a container is completed
  /// 
  /// A container is completed if:
  /// 1. It is not empty
  /// 2. It contains only one color (isSorted)
  /// 3. It is completely full (no remaining capacity)
  static bool _isContainerCompleted(Container container) {
    if (container.isEmpty) {
      return false;
    }

    // Must be full capacity
    if (!container.isFull) {
      return false;
    }

    // Must contain only one color
    if (!container.isSorted) {
      return false;
    }

    return true;
  }

  /// Public method to check if a level has completed containers
  /// This is used by the LevelGenerator interface implementation
  static bool hasCompletedContainers(Level level) {
    return _hasCompletedContainers(level);
  }

  /// Public method to check if a specific container is completed
  /// This is useful for testing and validation
  static bool isContainerCompleted(Container container) {
    return _isContainerCompleted(container);
  }

  /// Optimize a level by removing unnecessary empty containers while maintaining solvability
  /// 
  /// This method implements requirement 9.11: "WHEN the system generates a level THEN 
  /// the system SHALL remove any empty container if the level remains solvable without it"
  /// 
  /// Returns a new optimized level with the minimum number of empty containers needed
  static Level optimizeEmptyContainers(Level level) {
    // Don't optimize if the level has very few containers (need minimum for gameplay)
    if (level.containerCount <= 3) {
      return level;
    }

    // Count empty containers
    final emptyContainers = level.initialContainers.where((c) => c.isEmpty).toList();
    
    // If there are no empty containers, nothing to optimize
    if (emptyContainers.isEmpty) {
      return level;
    }

    // Try removing empty containers one by one and check if level is still solvable
    Level optimizedLevel = level;
    
    // Start with removing one empty container and increase until we try removing all
    // Note: We try removing ALL empty containers (<=) because some puzzles can be
    // solved without any empty containers
    for (int containersToRemove = 1; containersToRemove <= emptyContainers.length; containersToRemove++) {
      final candidateContainers = <Container>[];
      int emptyContainersAdded = 0;
      
      // Add all non-empty containers first, reassigning IDs sequentially
      for (final container in level.initialContainers) {
        if (!container.isEmpty) {
          candidateContainers.add(container.copyWith(id: candidateContainers.length));
        }
      }
      
      // Add remaining empty containers (keeping at least one)
      final emptyContainersToKeep = emptyContainers.length - containersToRemove;
      for (final container in level.initialContainers) {
        if (container.isEmpty && emptyContainersAdded < emptyContainersToKeep) {
          candidateContainers.add(container.copyWith(id: candidateContainers.length));
          emptyContainersAdded++;
        }
      }
      
      // Create candidate level with updated container count
      final candidateLevel = level.copyWith(
        containerCount: candidateContainers.length,
        initialContainers: candidateContainers,
      );
      
      // Check if the candidate level is still solvable
      if (_isLevelSolvable(candidateLevel)) {
        optimizedLevel = candidateLevel;
      } else {
        // Short-circuit: If removing this many containers makes it unsolvable,
        // removing more will also make it unsolvable (requirement 9.12)
        break;
      }
    }
    
    // Update level signature after optimization if containers were changed
    if (optimizedLevel.containerCount != level.containerCount) {
      // Import the similarity checker to regenerate the signature
      // Note: We'll need to add this import at the top of the file
      return optimizedLevel;
    }
    
    return optimizedLevel;
  }

  /// Merge adjacent liquid layers of the same color into single layers
  /// 
  /// This method implements requirements 9.13 and 9.14:
  /// - "WHEN the system generates a level THEN the system SHALL merge any adjacent 
  ///   liquid layers of the same color into a single layer"
  /// - "IF two or more consecutive layers in a container have the same color THEN 
  ///   the system SHALL combine them into one layer with the total volume"
  /// 
  /// Returns a new level with optimized containers where adjacent same-color layers
  /// have been merged into single layers with combined volumes.
  static Level mergeAdjacentLayers(Level level) {
    final optimizedContainers = <Container>[];
    
    for (final container in level.initialContainers) {
      if (container.isEmpty) {
        // Empty containers don't need layer merging
        optimizedContainers.add(container);
        continue;
      }
      
      final mergedLayers = <LiquidLayer>[];
      LiquidLayer? currentMergedLayer;
      
      // Process each layer in the container from bottom to top
      for (final layer in container.liquidLayers) {
        if (currentMergedLayer == null) {
          // First layer becomes the current merged layer
          currentMergedLayer = layer;
        } else if (currentMergedLayer.color == layer.color) {
          // Same color as current merged layer - combine volumes
          currentMergedLayer = currentMergedLayer.combineWith(layer);
        } else {
          // Different color - add current merged layer to result and start new one
          mergedLayers.add(currentMergedLayer);
          currentMergedLayer = layer;
        }
      }
      
      // Add the final merged layer if it exists
      if (currentMergedLayer != null) {
        mergedLayers.add(currentMergedLayer);
      }
      
      // Create optimized container with merged layers
      final optimizedContainer = container.copyWith(
        liquidLayers: mergedLayers,
      );
      
      optimizedContainers.add(optimizedContainer);
    }
    
    // Return new level with optimized containers
    return level.copyWith(
      initialContainers: optimizedContainers,
    );
  }

  /// Check if a level is actually solvable using BFS solver
  /// 
  /// This implements an actual solvability test by attempting to solve the level.
  /// Uses breadth-first search with optimizations for performance.
  static bool _isLevelSolvable(Level level) {
    // Basic structural validation first
    if (!level.isStructurallyValid) {
      return false;
    }
    
    // Note: We don't do a quick check for containerCount > colorCount here
    // because some puzzles with containerCount == colorCount can be solved
    // if they have the right configuration (e.g., one mixed container and
    // the rest full of single colors). Let the BFS solver determine actual
    // solvability.
    
    try {
      // Use a game engine without audio for testing
      final gameEngine = WaterSortGameEngine(
        audioManager: AudioManager(audioPlayer: MockAudioPlayer()),
      );
      final initialState = gameEngine.initializeLevel(
        level.id,
        level.initialContainers,
      );

      // Check if already solved (shouldn't happen, but safety check)
      if (gameEngine.checkWinCondition(initialState)) {
        return false; // Level is already solved, not a valid puzzle
      }

      // Use optimized breadth-first search to test solvability
      return _attemptSolveWithBFS(gameEngine, initialState);
    } catch (e) {
      // If any error occurs during solving attempt, consider it unsolvable
      return false;
    }
  }

  /// Attempt to solve the level using breadth-first search
  /// Includes pruning, move ordering, and state limits to ensure performance
  static bool _attemptSolveWithBFS(
    WaterSortGameEngine gameEngine,
    GameState initialState,
  ) {
    const maxStates = 5000; // Limit states to keep optimization fast
    const maxDepth = 500; // Limit depth to prevent excessive search
    
    final visited = <String>{};
    final queue = <_SearchNode>[_SearchNode(initialState, 0)];
    int statesExplored = 0;

    while (queue.isNotEmpty && statesExplored < maxStates) {
      final node = queue.removeAt(0);
      final currentState = node.state;
      statesExplored++;

      // Check if this state is solved
      if (gameEngine.checkWinCondition(currentState)) {
        return true; // Found a solution!
      }

      // Generate a state signature to avoid revisiting the same state
      final stateSignature = _generateStateSignature(currentState);
      if (visited.contains(stateSignature)) {
        continue;
      }
      visited.add(stateSignature);

      // Prune if depth is too large
      if (node.depth > maxDepth) {
        continue;
      }

      // Generate and prioritize moves
      final moves = _generatePrioritizedMoves(gameEngine, currentState);

      // Try all prioritized moves
      for (final move in moves) {
        try {
          final newState = gameEngine.executePour(
            currentState,
            move.fromId,
            move.toId,
          );
          
          // Add to queue with incremented depth
          queue.add(_SearchNode(newState, node.depth + 1));
        } catch (e) {
          // Skip invalid moves
          continue;
        }
      }
    }

    // If we exhausted all possibilities without finding a solution
    return false;
  }

  /// Generate prioritized moves for better search efficiency
  static List<_PrioritizedMove> _generatePrioritizedMoves(
    WaterSortGameEngine gameEngine,
    GameState currentState,
  ) {
    final moves = <_PrioritizedMove>[];

    for (int fromId = 0; fromId < currentState.containers.length; fromId++) {
      final fromContainer = currentState.containers[fromId];
      if (fromContainer.isEmpty) continue;

      for (int toId = 0; toId < currentState.containers.length; toId++) {
        if (fromId == toId) continue;

        final pourResult = gameEngine.validatePour(
          currentState,
          fromId,
          toId,
        );
        
        if (pourResult.isSuccess) {
          final toContainer = currentState.containers[toId];
          final priority = _calculateMovePriority(
            fromContainer,
            toContainer,
            currentState,
          );
          moves.add(_PrioritizedMove(fromId, toId, priority));
        }
      }
    }

    // Sort by priority (higher priority first)
    moves.sort((a, b) => b.priority.compareTo(a.priority));
    return moves;
  }

  /// Calculate priority for a move (higher is better)
  static int _calculateMovePriority(
    Container fromContainer,
    Container toContainer,
    GameState state,
  ) {
    int priority = 0;

    final topLayer = fromContainer.getTopContinuousLayer()!;

    // High priority: Pouring into empty container
    if (toContainer.isEmpty) {
      priority += 100;
      
      // Even higher if this empties the source container
      if (fromContainer.currentVolume == topLayer.volume) {
        priority += 200;
      }
    }
    // High priority: Pouring into same color
    else if (toContainer.topColor == topLayer.color) {
      priority += 150;
      
      // Bonus if this completes the target container
      if (toContainer.remainingCapacity == topLayer.volume) {
        priority += 100;
      }
      
      // Bonus if this empties the source container
      if (fromContainer.currentVolume == topLayer.volume) {
        priority += 100;
      }
    }

    // Bonus for consolidating (moving all of one color)
    if (fromContainer.isSorted && !fromContainer.isFull) {
      priority += 50;
    }

    // Penalty for breaking up sorted containers
    if (fromContainer.isSorted && fromContainer.isFull) {
      priority -= 50;
    }

    return priority;
  }

  /// Generate a unique signature for a game state to detect duplicates
  static String _generateStateSignature(GameState gameState) {
    final containerSignatures = <String>[];

    for (final container in gameState.containers) {
      if (container.isEmpty) {
        containerSignatures.add('[empty]');
      } else {
        final layerSignatures = container.liquidLayers
            .map((layer) => '${layer.color.name}:${layer.volume}')
            .join(',');
        containerSignatures.add('[$layerSignatures]');
      }
    }

    // Sort container signatures to make the state signature order-independent
    containerSignatures.sort();
    return containerSignatures.join('|');
  }
}

/// Helper class to track search state with depth for BFS
class _SearchNode {
  final GameState state;
  final int depth;

  _SearchNode(this.state, this.depth);
}

/// Helper class to represent a prioritized move
class _PrioritizedMove {
  final int fromId;
  final int toId;
  final int priority;

  _PrioritizedMove(this.fromId, this.toId, this.priority);
}