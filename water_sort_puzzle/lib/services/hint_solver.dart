import 'dart:collection';
import '../models/game_state.dart';
import 'game_engine.dart';

/// Represents a move suggestion from the hint system
class HintMove {
  final int fromContainerId;
  final int toContainerId;
  
  const HintMove({
    required this.fromContainerId,
    required this.toContainerId,
  });
  
  @override
  String toString() => 'HintMove(from: $fromContainerId, to: $toContainerId)';
}

/// Service that uses BFS to find the best move from the current state
class HintSolver {
  final WaterSortGameEngine _gameEngine;
  
  HintSolver(this._gameEngine);
  
  /// Find the best move using BFS
  /// Returns null if no solution exists or the puzzle is already solved
  HintMove? findBestMove(GameState currentState) {
    // If already solved, no hint needed
    if (_gameEngine.checkWinCondition(currentState)) {
      return null;
    }
    
    // Use BFS to find the shortest path to solution
    final queue = Queue<_SearchNode>();
    final visited = <String>{};
    
    // Add initial state to queue
    queue.add(_SearchNode(
      state: currentState,
      path: [],
    ));
    visited.add(_stateSignature(currentState));
    
    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      
      // Try all possible moves from this state
      for (int fromId = 0; fromId < node.state.containers.length; fromId++) {
        for (int toId = 0; toId < node.state.containers.length; toId++) {
          if (fromId == toId) continue;
          
          // Check if this move is valid
          final pourResult = _gameEngine.validatePour(node.state, fromId, toId);
          if (!pourResult.isSuccess) continue;
          
          // Execute the move
          final newState = _gameEngine.executePour(node.state, fromId, toId);
          final signature = _stateSignature(newState);
          
          // Skip if we've seen this state before
          if (visited.contains(signature)) continue;
          visited.add(signature);
          
          // Create new path with this move
          final newPath = List<HintMove>.from(node.path)
            ..add(HintMove(fromContainerId: fromId, toContainerId: toId));
          
          // Check if this state is a solution
          if (_gameEngine.checkWinCondition(newState)) {
            // Return the first move in the solution path
            return newPath.first;
          }
          
          // Add to queue for further exploration
          queue.add(_SearchNode(
            state: newState,
            path: newPath,
          ));
        }
      }
      
      // Limit search depth to prevent excessive computation
      // If we've explored too many states, return a heuristic-based move
      if (visited.length > 10000) {
        return null; // _findHeuristicMove(currentState);
      }
    }
    
    // No solution found, try heuristic approach
    return null; // _findHeuristicMove(currentState);
  }
  
  /// Generate a unique signature for a game state to detect duplicates
  String _stateSignature(GameState state) {
    final buffer = StringBuffer();
    for (final container in state.containers) {
      buffer.write('${container.id}:');
      for (final layer in container.liquidLayers) {
        buffer.write('${layer.color.name}${layer.volume},');
      }
      buffer.write('|');
    }
    return buffer.toString();
  }
  
  /// Find a move using heuristics when BFS doesn't find a solution quickly
  /// This provides a "good enough" hint even for complex puzzles
  HintMove? _findHeuristicMove(GameState state) {
    // Heuristic 1: Complete a sorted container (pour matching color onto full/nearly full container)
    for (int fromId = 0; fromId < state.containers.length; fromId++) {
      final fromContainer = state.containers[fromId];
      if (fromContainer.isEmpty) continue;
      
      final topColor = fromContainer.topColor!;
      
      for (int toId = 0; toId < state.containers.length; toId++) {
        if (fromId == toId) continue;
        final toContainer = state.containers[toId];
        
        // Try to complete a container
        if (!toContainer.isEmpty && 
            toContainer.topColor == topColor && 
            toContainer.isSorted &&
            _gameEngine.validatePour(state, fromId, toId).isSuccess) {
          return HintMove(fromContainerId: fromId, toContainerId: toId);
        }
      }
    }
    
    // Heuristic 2: Move to empty container to separate colors
    for (int fromId = 0; fromId < state.containers.length; fromId++) {
      final fromContainer = state.containers[fromId];
      if (fromContainer.isEmpty || fromContainer.isSorted) continue;
      
      for (int toId = 0; toId < state.containers.length; toId++) {
        if (fromId == toId) continue;
        final toContainer = state.containers[toId];
        
        if (toContainer.isEmpty && 
            _gameEngine.validatePour(state, fromId, toId).isSuccess) {
          return HintMove(fromContainerId: fromId, toContainerId: toId);
        }
      }
    }
    
    // Heuristic 3: Any valid move that consolidates colors
    for (int fromId = 0; fromId < state.containers.length; fromId++) {
      final fromContainer = state.containers[fromId];
      if (fromContainer.isEmpty) continue;
      
      final topColor = fromContainer.topColor!;
      
      for (int toId = 0; toId < state.containers.length; toId++) {
        if (fromId == toId) continue;
        final toContainer = state.containers[toId];
        
        if ((toContainer.isEmpty || toContainer.topColor == topColor) &&
            _gameEngine.validatePour(state, fromId, toId).isSuccess) {
          return HintMove(fromContainerId: fromId, toContainerId: toId);
        }
      }
    }
    
    // Last resort: return any valid move
    for (int fromId = 0; fromId < state.containers.length; fromId++) {
      for (int toId = 0; toId < state.containers.length; toId++) {
        if (fromId == toId) continue;
        
        if (_gameEngine.validatePour(state, fromId, toId).isSuccess) {
          return HintMove(fromContainerId: fromId, toContainerId: toId);
        }
      }
    }
    
    return null;
  }
}

/// Internal class to represent a node in the BFS search
class _SearchNode {
  final GameState state;
  final List<HintMove> path;
  
  _SearchNode({
    required this.state,
    required this.path,
  });
}
