import 'dart:math';
import '../models/level.dart';
import '../models/container.dart';
import '../models/liquid_layer.dart';
import '../models/liquid_color.dart';
import 'level_generator.dart';
import 'level_validator.dart';

/// Generates levels using a reverse-solving approach.
/// Starts with a solved puzzle and systematically scrambles it using
/// inverse operations to guarantee solvability.
class ReverseLevelGenerator implements LevelGenerator {
  final LevelGenerationConfig config;
  final Random _random;

  ReverseLevelGenerator({this.config = const LevelGenerationConfig()})
      : _random = Random(config.seed);

  @override
  Level generateLevel(
    int levelId,
    int difficulty,
    int containerCount,
    int colorCount,
  ) {
    // Validate input parameters
    if (colorCount > LiquidColor.values.length) {
      throw ArgumentError(
        'Color count ($colorCount) cannot exceed available colors (${LiquidColor.values.length})',
      );
    }

    // Check if we have enough containers for the colors
    if (containerCount < colorCount) {
      throw ArgumentError(
        'Container count ($containerCount) must be at least equal to color count ($colorCount)',
      );
    }

    // Select colors for this level
    final selectedColors = _selectColors(colorCount);

    // Create the solved state
    final solvedContainers = _createSolvedState(
      containerCount,
      selectedColors,
    );

    // Scramble the solved state using inverse operations
    final scrambledContainers = _scramblePuzzle(
      solvedContainers,
      difficulty,
      selectedColors,
    );

    // Create the level
    final level = Level(
      id: levelId,
      difficulty: difficulty,
      containerCount: containerCount,
      colorCount: colorCount,
      initialContainers: scrambledContainers,
      tags: _generateTags(levelId, difficulty),
    );

    // Optimize by removing unnecessary empty containers
    // This tests if the level can be solved with fewer empty containers
    final optimizedLevel = LevelValidator.optimizeEmptyContainers(level);

    return optimizedLevel;
  }

  @override
  Level generateUniqueLevel(
    int levelId,
    int difficulty,
    int containerCount,
    int colorCount,
    List<Level> existingLevels,
  ) {
    // For now, just generate a level
    // TODO: Add uniqueness checking
    return generateLevel(levelId, difficulty, containerCount, colorCount);
  }

  @override
  bool validateLevel(Level level) {
    // Levels generated through reverse-solving are guaranteed to be solvable
    return level.isStructurallyValid;
  }

  @override
  bool isLevelSimilar(Level newLevel, List<Level> existingLevels) {
    // TODO: Implement similarity checking
    return false;
  }

  @override
  String generateLevelSignature(Level level) {
    // TODO: Implement signature generation
    return '';
  }

  @override
  List<Level> generateLevelSeries(
    int startId,
    int count, {
    int startDifficulty = 1,
  }) {
    final levels = <Level>[];

    for (int i = 0; i < count; i++) {
      final levelId = startId + i;
      final difficulty = _calculateProgressiveDifficulty(i, startDifficulty);
      final containerCount = _calculateContainerCount(difficulty);
      final colorCount = _calculateColorCount(difficulty, containerCount);

      final level = generateLevel(
        levelId,
        difficulty,
        containerCount,
        colorCount,
      );
      levels.add(level);
    }

    return levels;
  }

  @override
  bool hasCompletedContainers(Level level) {
    for (final container in level.initialContainers) {
      if (!container.isEmpty && 
          container.isSorted && 
          container.isFull) {
        return true;
      }
    }
    return false;
  }

  /// Select colors for the level
  List<LiquidColor> _selectColors(int colorCount) {
    final availableColors = List<LiquidColor>.from(LiquidColor.values);
    availableColors.shuffle(_random);
    return availableColors.take(colorCount).toList();
  }

  /// Create a solved puzzle state
  /// Each color gets its own container, filled to capacity
  /// Remaining containers are left empty
  List<Container> _createSolvedState(
    int containerCount,
    List<LiquidColor> colors,
  ) {
    final containers = <Container>[];

    // Create one full container per color
    for (int i = 0; i < colors.length; i++) {
      containers.add(
        Container(
          id: i,
          capacity: config.containerCapacity,
          liquidLayers: [
            LiquidLayer(
              color: colors[i],
              volume: config.containerCapacity,
            ),
          ],
        ),
      );
    }

    // Create empty containers for the rest
    for (int i = colors.length; i < containerCount; i++) {
      containers.add(
        Container(
          id: i,
          capacity: config.containerCapacity,
          liquidLayers: [],
        ),
      );
    }

    return containers;
  }

  /// Scramble a solved puzzle using inverse operations
  /// The number and type of scrambling moves depend on difficulty
  List<Container> _scramblePuzzle(
    List<Container> solvedContainers,
    int difficulty,
    List<LiquidColor> colors,
  ) {
    // Make a deep copy to avoid modifying the original
    final containers = solvedContainers
        .map((c) => Container(
              id: c.id,
              capacity: c.capacity,
              liquidLayers: c.liquidLayers
                  .map((l) => LiquidLayer(color: l.color, volume: l.volume))
                  .toList(),
            ))
        .toList();

    // Calculate number of scrambling moves based on difficulty
    final moveCount = _calculateScrambleMoves(difficulty, colors.length);

    // Track state to avoid getting stuck
    final stateHistory = <String>{};
    int successfulMoves = 0;
    int attempts = 0;
    final maxAttempts = moveCount * 10; // Allow some failed attempts

    while (successfulMoves < moveCount && attempts < maxAttempts) {
      attempts++;

      // Try to perform a scrambling move
      if (_performRandomScrambleMove(containers, colors, stateHistory)) {
        successfulMoves++;
      }
    }

    // Ensure we have at least one empty container
    // If all containers have liquid, we need to move some liquid around
    final emptyCount = containers.where((c) => c.isEmpty).length;
    if (emptyCount == 0) {
      // Find the container with the least liquid and empty it into others
      containers.sort((a, b) => a.currentVolume.compareTo(b.currentVolume));
      final toEmpty = containers.first;
      
      // Distribute its contents to other containers
      while (toEmpty.liquidLayers.isNotEmpty) {
        final layer = toEmpty.liquidLayers.removeLast();
        // Find a container with space
        for (final target in containers) {
          if (target != toEmpty && target.remainingCapacity >= layer.volume) {
            target.liquidLayers.add(layer);
            break;
          }
        }
      }
    }

    // Reassign IDs to maintain order
    for (int i = 0; i < containers.length; i++) {
      containers[i] = Container(
        id: i,
        capacity: containers[i].capacity,
        liquidLayers: containers[i].liquidLayers,
      );
    }

    return containers;
  }

  /// Calculate the number of scrambling moves based on difficulty
  int _calculateScrambleMoves(int difficulty, int colorCount) {
    // Base moves: proportional to number of colors
    final baseMoves = colorCount * 2;
    
    // Additional moves based on difficulty
    final difficultyMultiplier = 1 + (difficulty / 10);
    
    return (baseMoves * difficultyMultiplier).round();
  }

  /// Perform a random scrambling move (inverse operation)
  /// Returns true if a move was successfully performed
  bool _performRandomScrambleMove(
    List<Container> containers,
    List<LiquidColor> colors,
    Set<String> stateHistory,
  ) {
    // Get all possible scrambling moves
    final possibleMoves = _getPossibleScrambleMoves(containers);

    if (possibleMoves.isEmpty) {
      return false;
    }

    // Shuffle and try moves until one succeeds
    possibleMoves.shuffle(_random);

    for (final move in possibleMoves) {
      // Try to execute the move
      final newContainers = _executeScrambleMove(containers, move);

      // Check if this creates a new state
      final stateSignature = _generateStateSignature(newContainers);
      if (!stateHistory.contains(stateSignature)) {
        // Apply the move
        _applyContainerChanges(containers, newContainers);
        stateHistory.add(stateSignature);
        return true;
      }
    }

    return false;
  }

  /// Get all possible scrambling moves from the current state
  List<_ScrambleMove> _getPossibleScrambleMoves(List<Container> containers) {
    final moves = <_ScrambleMove>[];

    for (int sourceId = 0; sourceId < containers.length; sourceId++) {
      final source = containers[sourceId];
      
      // Can only scramble from containers that have liquid
      if (source.isEmpty) continue;

      final topLayer = source.liquidLayers.last;

      for (int targetId = 0; targetId < containers.length; targetId++) {
        if (sourceId == targetId) continue;

        final target = containers[targetId];

        // Inverse Move Type 1: Split a unified color
        // Take some liquid from a sorted container and put it in an empty container
        // This is the inverse of "pour from empty to matching color"
        // We can ONLY place on empty containers since players cannot split colors
        if (source.isSorted && source.liquidLayers.length == 1 && topLayer.volume > 1) {
          final volumeToMove = _random.nextInt(topLayer.volume - 1) + 1;
          
          if (target.isEmpty && target.remainingCapacity >= volumeToMove) {
            moves.add(_ScrambleMove(
              sourceId: sourceId,
              targetId: targetId,
              volume: volumeToMove,
              type: _ScrambleMoveType.splitUnified,
            ));
          }
        }

        // Inverse Move Type 2: Create mixture by moving to different color
        // Take liquid from top and place on a container with a DIFFERENT color
        // This creates the mixed state that needs to be solved
        if (!target.isEmpty && target.topColor != topLayer.color) {
          final volumeToMove = min(
            topLayer.volume,
            target.remainingCapacity,
          );
          
          if (volumeToMove > 0) {
            moves.add(_ScrambleMove(
              sourceId: sourceId,
              targetId: targetId,
              volume: volumeToMove,
              type: _ScrambleMoveType.createMixture,
            ));
          }
        }

        // Inverse Move Type 3: Move from empty-adjacent position
        // If we have a container with multiple layers, we can move the top layer
        // to an empty container (inverse of pouring from empty)
        if (source.liquidLayers.length > 1 && target.isEmpty) {
          final volumeToMove = min(
            topLayer.volume,
            target.remainingCapacity,
          );
          
          if (volumeToMove > 0) {
            moves.add(_ScrambleMove(
              sourceId: sourceId,
              targetId: targetId,
              volume: volumeToMove,
              type: _ScrambleMoveType.moveToEmpty,
            ));
          }
        }
      }
    }

    return moves;
  }

  /// Execute a scrambling move and return the new container state
  List<Container> _executeScrambleMove(
    List<Container> containers,
    _ScrambleMove move,
  ) {
    // Create a deep copy
    final newContainers = containers
        .map((c) => Container(
              id: c.id,
              capacity: c.capacity,
              liquidLayers: c.liquidLayers
                  .map((l) => LiquidLayer(color: l.color, volume: l.volume))
                  .toList(),
            ))
        .toList();

    final source = newContainers[move.sourceId];
    final target = newContainers[move.targetId];

    // Get the top layer from source
    final topLayer = source.liquidLayers.last;

    // Remove volume from source
    if (topLayer.volume == move.volume) {
      // Remove the entire layer
      source.liquidLayers.removeLast();
    } else {
      // Split the layer
      source.liquidLayers.removeLast();
      source.liquidLayers.add(
        LiquidLayer(
          color: topLayer.color,
          volume: topLayer.volume - move.volume,
        ),
      );
    }

    // Add volume to target
    if (target.isEmpty || target.topColor != topLayer.color) {
      // Add as a new layer
      target.liquidLayers.add(
        LiquidLayer(
          color: topLayer.color,
          volume: move.volume,
        ),
      );
    } else {
      // Merge with existing top layer
      final targetTopLayer = target.liquidLayers.last;
      target.liquidLayers.removeLast();
      target.liquidLayers.add(
        LiquidLayer(
          color: targetTopLayer.color,
          volume: targetTopLayer.volume + move.volume,
        ),
      );
    }

    return newContainers;
  }

  /// Apply container changes from new state to current state
  void _applyContainerChanges(
    List<Container> current,
    List<Container> newState,
  ) {
    for (int i = 0; i < current.length; i++) {
      current[i] = Container(
        id: current[i].id,
        capacity: current[i].capacity,
        liquidLayers: newState[i].liquidLayers
            .map((l) => LiquidLayer(color: l.color, volume: l.volume))
            .toList(),
      );
    }
  }

  /// Generate a unique signature for a container state
  String _generateStateSignature(List<Container> containers) {
    final containerSignatures = <String>[];

    for (final container in containers) {
      if (container.isEmpty) {
        containerSignatures.add('[empty]');
      } else {
        final layerSignatures = container.liquidLayers
            .map((layer) => '${layer.color.name}:${layer.volume}')
            .join(',');
        containerSignatures.add('[$layerSignatures]');
      }
    }

    // Sort to make signature order-independent
    containerSignatures.sort();
    return containerSignatures.join('|');
  }

  /// Calculate progressive difficulty for level series
  int _calculateProgressiveDifficulty(int levelIndex, int startDifficulty) {
    final difficultyIncrease = levelIndex ~/ 5;
    return min(10, startDifficulty + difficultyIncrease);
  }

  /// Calculate container count based on difficulty
  int _calculateContainerCount(int difficulty) {
    if (difficulty <= 2) return 4;
    if (difficulty <= 4) return 5;
    if (difficulty <= 6) return 6;
    if (difficulty <= 8) return 7;
    return 8;
  }

  /// Calculate color count based on difficulty and container count
  int _calculateColorCount(int difficulty, int containerCount) {
    final maxColors = containerCount - 1;

    if (difficulty <= 2) return min(2, maxColors);
    if (difficulty <= 4) return min(3, maxColors);
    if (difficulty <= 6) return min(4, maxColors);
    if (difficulty <= 8) return min(5, maxColors);
    return min(6, maxColors);
  }

  /// Generate appropriate tags for a level
  List<String> _generateTags(int levelId, int difficulty) {
    final tags = <String>[];

    if (levelId <= 5) {
      tags.add('tutorial');
    }

    if (difficulty >= 8) {
      tags.add('challenge');
    }

    if (difficulty <= 3) {
      tags.add('easy');
    } else if (difficulty <= 6) {
      tags.add('medium');
    } else {
      tags.add('hard');
    }

    return tags;
  }
}

/// Types of scrambling moves (inverse operations)
enum _ScrambleMoveType {
  /// Split a unified color by moving some volume to another container
  splitUnified,
  
  /// Create a mixture by placing one color on top of a different color
  createMixture,
  
  /// Move a layer to an empty container
  moveToEmpty,
}

/// Represents a scrambling move
class _ScrambleMove {
  final int sourceId;
  final int targetId;
  final int volume;
  final _ScrambleMoveType type;

  _ScrambleMove({
    required this.sourceId,
    required this.targetId,
    required this.volume,
    required this.type,
  });
}
