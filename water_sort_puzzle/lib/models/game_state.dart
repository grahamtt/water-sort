import 'package:json_annotation/json_annotation.dart';
import 'container.dart';
import 'move.dart';
import 'liquid_color.dart';

part 'game_state.g.dart';

/// Represents the complete state of a water sort puzzle game
@JsonSerializable(explicitToJson: true)
class GameState {
  /// The current level ID
  final int levelId;

  /// List of all containers in the current game
  final List<Container> containers;

  /// The initial state of containers (for proper undo/redo)
  final List<Container> initialContainers;

  /// History of all moves made in this game session
  final List<Move> moveHistory;

  /// Whether the current puzzle is completed
  final bool isCompleted;

  /// Whether the game is lost (no legal moves remaining)
  final bool isLost;

  /// Total number of moves made
  final int moveCount;

  /// Index of the current move in the history (for undo/redo functionality)
  /// This allows us to undo moves and then make new moves from that point
  final int currentMoveIndex;

  const GameState({
    required this.levelId,
    required this.containers,
    required this.initialContainers,
    required this.moveHistory,
    required this.isCompleted,
    required this.isLost,
    required this.moveCount,
    required this.currentMoveIndex,
  });

  /// Create an initial game state for a new level
  factory GameState.initial({
    required int levelId,
    required List<Container> containers,
  }) {
    return GameState(
      levelId: levelId,
      containers: containers,
      initialContainers: containers.map((c) => c.copyWith()).toList(),
      moveHistory: [],
      isCompleted: false,
      isLost: false,
      moveCount: 0,
      currentMoveIndex: -1,
    );
  }

  /// Create a copy of this game state with optional parameter overrides
  GameState copyWith({
    int? levelId,
    List<Container>? containers,
    List<Container>? initialContainers,
    List<Move>? moveHistory,
    bool? isCompleted,
    bool? isLost,
    int? moveCount,
    int? currentMoveIndex,
  }) {
    return GameState(
      levelId: levelId ?? this.levelId,
      containers: containers ?? List.from(this.containers),
      initialContainers: initialContainers ?? List.from(this.initialContainers),
      moveHistory: moveHistory ?? List.from(this.moveHistory),
      isCompleted: isCompleted ?? this.isCompleted,
      isLost: isLost ?? this.isLost,
      moveCount: moveCount ?? this.moveCount,
      currentMoveIndex: currentMoveIndex ?? this.currentMoveIndex,
    );
  }

  /// Get a container by its ID
  Container? getContainer(int id) {
    try {
      return containers.firstWhere((container) => container.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Check if all containers are in a solved state
  bool get isSolved {
    // A puzzle is solved when:
    // 1. All non-empty containers contain only one color (isSorted)
    // 2. Each color is consolidated into the minimum number of containers

    // First check: all non-empty containers must be sorted
    for (final container in containers) {
      if (!container.isEmpty && !container.isSorted) {
        return false;
      }
    }

    // Second check: each color should be consolidated optimally
    // Group containers by their color
    final Map<LiquidColor, List<Container>> colorGroups = {};

    for (final container in containers) {
      if (!container.isEmpty) {
        final color = container.liquidLayers.first.color;
        colorGroups.putIfAbsent(color, () => []).add(container);
      }
    }

    // For each color, check if it's properly consolidated
    for (final entry in colorGroups.entries) {
      final color = entry.key;
      final containersWithColor = entry.value;

      // Calculate total volume of this color
      final totalVolume = containersWithColor.fold<int>(
        0,
        (sum, container) => sum + container.currentVolume,
      );

      // Calculate minimum containers needed (assuming capacity of 4)
      final containerCapacity = containersWithColor.first.capacity;
      final minContainersNeeded = (totalVolume / containerCapacity).ceil();

      // If we have more containers than needed, it's not optimally solved
      if (containersWithColor.length > minContainersNeeded) {
        return false;
      }

      // Check that containers are filled optimally (full containers first)
      containersWithColor.sort(
        (a, b) => b.currentVolume.compareTo(a.currentVolume),
      );

      for (int i = 0; i < containersWithColor.length - 1; i++) {
        // All containers except the last should be full
        if (containersWithColor[i].currentVolume != containerCapacity) {
          return false;
        }
      }
    }

    return true;
  }

  /// Check if undo is possible
  bool get canUndo {
    return currentMoveIndex >= 0;
  }

  /// Check if redo is possible
  bool get canRedo {
    return currentMoveIndex < moveHistory.length - 1;
  }

  /// Get the number of moves that can be undone
  int get undoableMovesCount {
    return currentMoveIndex + 1;
  }

  /// Get the number of moves that can be redone
  int get redoableMovesCount {
    return moveHistory.length - currentMoveIndex - 1;
  }

  /// Add a new move to the history and update the game state
  GameState addMove(Move move, List<Container> newContainers) {
    // When adding a new move, we truncate any moves after the current index
    // This handles the case where we undid some moves and then made a new move
    final newMoveHistory = moveHistory.take(currentMoveIndex + 1).toList();
    newMoveHistory.add(move);

    return copyWith(
      containers: newContainers,
      moveHistory: newMoveHistory,
      moveCount: moveCount + 1,
      currentMoveIndex: newMoveHistory.length - 1,
      isCompleted: _checkIfCompleted(newContainers),
    );
  }

  /// Undo the last move and return the previous game state
  GameState? undoMove() {
    if (!canUndo) return null;

    // To properly undo, we need to reconstruct the state from the beginning
    // up to the move before the current one
    final targetMoveIndex = currentMoveIndex - 1;

    // Start with the initial containers (we need to store these separately)
    // For now, we'll reconstruct by applying moves up to the target index
    final newContainers = _reconstructContainersUpToMove(targetMoveIndex);

    return copyWith(
      containers: newContainers,
      currentMoveIndex: targetMoveIndex,
      isCompleted: _checkIfCompleted(newContainers),
      // Reset loss condition when undoing - it will be recalculated if needed
      isLost: false,
    );
  }

  /// Redo the next move and return the updated game state
  GameState? redoMove() {
    if (!canRedo) return null;

    // To properly redo, we reconstruct the state up to the next move
    final targetMoveIndex = currentMoveIndex + 1;
    final newContainers = _reconstructContainersUpToMove(targetMoveIndex);

    return copyWith(
      containers: newContainers,
      currentMoveIndex: targetMoveIndex,
      isCompleted: _checkIfCompleted(newContainers),
      // Reset loss condition when redoing - it will be recalculated if needed
      isLost: false,
    );
  }

  /// Reset the game state to the initial state (no moves)
  GameState reset(List<Container> initialContainers) {
    return GameState.initial(levelId: levelId, containers: initialContainers);
  }

  /// Get the effective move count (only counting moves up to current index)
  int get effectiveMoveCount {
    return currentMoveIndex + 1;
  }

  /// Check if the game is completed based on container states
  bool _checkIfCompleted(List<Container> containers) {
    // Create a temporary GameState to use the isSolved logic
    final tempState = GameState(
      levelId: levelId,
      containers: containers,
      initialContainers: initialContainers,
      moveHistory: moveHistory,
      isCompleted: false,
      isLost: false,
      moveCount: moveCount,
      currentMoveIndex: currentMoveIndex,
    );
    return tempState.isSolved;
  }

  /// Reconstruct container states by applying moves up to a specific index
  List<Container> _reconstructContainersUpToMove(int targetMoveIndex) {
    // Start with a copy of the initial containers
    final reconstructedContainers = initialContainers
        .map((c) => c.copyWith())
        .toList();

    // Apply moves from 0 to targetMoveIndex (inclusive)
    for (int i = 0; i <= targetMoveIndex && i < moveHistory.length; i++) {
      final move = moveHistory[i];

      // Find source and target containers
      final sourceContainer = reconstructedContainers.firstWhere(
        (c) => c.id == move.fromContainerId,
      );
      final targetContainer = reconstructedContainers.firstWhere(
        (c) => c.id == move.toContainerId,
      );

      // Apply the move - remove the specific volume that was moved
      sourceContainer.removeSpecificVolume(
        move.liquidMoved.color,
        move.liquidMoved.volume,
      );
      targetContainer.addLiquid(move.liquidMoved);
    }

    return reconstructedContainers;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameState &&
        other.levelId == levelId &&
        _listEquals(other.containers, containers) &&
        _listEquals(other.initialContainers, initialContainers) &&
        _listEquals(other.moveHistory, moveHistory) &&
        other.isCompleted == isCompleted &&
        other.isLost == isLost &&
        other.moveCount == moveCount &&
        other.currentMoveIndex == currentMoveIndex;
  }

  @override
  int get hashCode => Object.hash(
    levelId,
    Object.hashAll(containers),
    Object.hashAll(initialContainers),
    Object.hashAll(moveHistory),
    isCompleted,
    isLost,
    moveCount,
    currentMoveIndex,
  );

  @override
  String toString() {
    return 'GameState(level: $levelId, containers: ${containers.length}, '
        'moves: $effectiveMoveCount/$moveCount, completed: $isCompleted, lost: $isLost)';
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
  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);

  /// JSON deserialization
  Map<String, dynamic> toJson() => _$GameStateToJson(this);
}
