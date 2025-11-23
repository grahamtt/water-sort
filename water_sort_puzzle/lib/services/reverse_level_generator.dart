import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/level.dart';
import '../models/container.dart';
import '../models/liquid_layer.dart';
import '../models/liquid_color.dart';
import 'level_generator.dart';
import 'level_validator.dart';
import 'level_parameters.dart';

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
    int colorCount,
    int containerCapacity,
    int emptySlots,
  ) {
    // Calculate containerCount for solved state:
    // - Each color gets one container
    // - Plus empty containers if emptySlots >= containerCapacity
    final emptyContainerCount = emptySlots >= containerCapacity 
        ? emptySlots ~/ containerCapacity 
        : 0;
    final containerCount = colorCount + emptyContainerCount;

    // Validate input parameters
    if (colorCount > LiquidColor.values.length) {
      throw ArgumentError(
        'Color count ($colorCount) cannot exceed available colors (${LiquidColor.values.length})',
      );
    }

    // Validate emptySlots
    if (emptySlots < 1) {
      throw ArgumentError(
        'Empty slots ($emptySlots) must be at least 1',
      );
    }

    // Try generating a valid level with retries
    Level? validLevel;
    Level? bestCandidate;
    int bestCandidateFailureCount = 999;
    const maxAttempts = 10;
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      // Select colors for this level
      final selectedColors = _selectColors(colorCount);

      // Create the solved state
      final solvedContainers = createSolvedState(
        containerCount,
        selectedColors,
        containerCapacity,
        emptySlots,
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

      // Validate the level meets all requirements
      final validationFailures = _validateWithDetails(level);
      
      if (validationFailures.isEmpty) {
        // Skip optimization for small capacities to avoid BFS solver issues
        // Optimize by removing unnecessary empty containers only for larger capacities
        if (containerCapacity >= 4) {
          final optimizedLevel = LevelValidator.optimizeEmptyContainers(level);
          validLevel = optimizedLevel;
        } else {
          validLevel = level;
        }
        break;
      } else if (config.returnBest) {
        // Track the best candidate (fewest failures)
        if (validationFailures.length < bestCandidateFailureCount) {
          bestCandidate = level;
          bestCandidateFailureCount = validationFailures.length;
        }
      }
    }

    // If we found a valid level, return it
    if (validLevel != null) {
      return validLevel;
    }

    // If returnBest is enabled and we have a candidate, return it with failure metadata
    if (config.returnBest && bestCandidate != null) {
      final failureTags = _getValidationFailureTags(bestCandidate);
      return bestCandidate.copyWith(
        tags: [...bestCandidate.tags, ...failureTags, 'best_invalid_candidate'],
      );
    }

    // If we couldn't generate a valid level after max attempts, throw an error
    throw StateError(
      'Failed to generate valid level after $maxAttempts attempts. '
      'Level $levelId with difficulty $difficulty, $containerCount containers, $colorCount colors.',
    );
  }

  @override
  Level generateUniqueLevel(
    int levelId,
    int difficulty,
    int colorCount,
    int containerCapacity,
    int emptySlots,
    List<Level> existingLevels,
  ) {
    // For now, just generate a level
    // TODO: Add uniqueness checking
    return generateLevel(levelId, difficulty, colorCount, containerCapacity, emptySlots);
  }

  @override
  bool validateLevel(Level level) {
    // Use the full validation which checks for completed containers
    // and other requirements, not just structural validity
    return LevelValidator.validateGeneratedLevel(level);
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
      final difficulty = LevelParameters.calculateProgressiveDifficulty(i, startDifficulty);
      final containerCapacity = LevelParameters.calculateContainerCapacity(levelId);
      final emptySlots = LevelParameters.calculateEmptySlots(difficulty, containerCapacity);
      
      // Calculate colorCount based on difficulty
      // Ensure colorCount * containerCapacity > emptySlots for valid liquid volume
      final minColorCount = (emptySlots / containerCapacity).ceil() + 1;
      final targetColorCount = LevelParameters.calculateColorCount(difficulty, minColorCount + 2);
      final colorCount = targetColorCount.clamp(minColorCount, LiquidColor.values.length);

      final level = generateLevel(
        levelId,
        difficulty,
        colorCount,
        containerCapacity,
        emptySlots,
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
  /// Each color is placed in containers with emptySlots distributed optimally
  /// The solved state should have exactly emptySlots total empty space
  /// 
  /// Strategy:
  /// - If emptySlots < containerCapacity: distribute empty slots across colors (no empty containers)
  /// - If emptySlots >= containerCapacity: each color gets full capacity, plus empty containers
  @visibleForTesting
  List<Container> createSolvedState(
    int containerCount,
    List<LiquidColor> colors,
    int containerCapacity,
    int emptySlots,
  ) {
    final containers = <Container>[];

    if (emptySlots < containerCapacity) {
      // Distribute emptySlots across colors (no completely empty containers)
      // Total liquid = colors.length * containerCapacity - emptySlots
      final totalLiquid = colors.length * containerCapacity - emptySlots;
      
      if (totalLiquid <= 0) {
        throw ArgumentError(
          'Invalid parameters: colorCount=${colors.length}, containerCapacity=$containerCapacity, '
          'emptySlots=$emptySlots results in totalLiquid=$totalLiquid.'
        );
      }

      // Distribute liquid evenly across colors
      final baseVolumePerColor = totalLiquid ~/ colors.length;
      final colorsWithExtra = totalLiquid % colors.length;

      for (int i = 0; i < colors.length; i++) {
        final volume = i < colorsWithExtra 
            ? baseVolumePerColor + 1 
            : baseVolumePerColor;
        
        containers.add(
          Container(
            id: i,
            capacity: containerCapacity,
            liquidLayers: [
              LiquidLayer(
                color: colors[i],
                volume: volume,
              ),
            ],
          ),
        );
      }
    } else {
      // emptySlots >= containerCapacity
      // Each color gets full capacity, then add empty containers
      final emptyContainerCount = emptySlots ~/ containerCapacity;
      final remainingEmptySlots = emptySlots % containerCapacity;
      
      // Create one full container per color
      for (int i = 0; i < colors.length; i++) {
        containers.add(
          Container(
            id: i,
            capacity: containerCapacity,
            liquidLayers: [
              LiquidLayer(
                color: colors[i],
                volume: containerCapacity,
              ),
            ],
          ),
        );
      }
      
      // Add completely empty containers
      for (int i = 0; i < emptyContainerCount; i++) {
        containers.add(
          Container(
            id: colors.length + i,
            capacity: containerCapacity,
            liquidLayers: [],
          ),
        );
      }
      
      // If there are remaining empty slots, reduce the last color's volume
      if (remainingEmptySlots > 0 && containers.isNotEmpty) {
        final lastColorContainer = containers[colors.length - 1];
        containers[colors.length - 1] = Container(
          id: lastColorContainer.id,
          capacity: containerCapacity,
          liquidLayers: [
            LiquidLayer(
              color: lastColorContainer.liquidLayers.first.color,
              volume: containerCapacity - remainingEmptySlots,
            ),
          ],
        );
      }
    }

    return containers;
  }

  /// Scramble a solved puzzle using inverse operations
  /// Continues scrambling until the puzzle is sufficiently mixed,
  /// as determined by the percentage of contiguous colors falling below a threshold
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

    // Calculate the target scrambling threshold based on difficulty
    // Higher difficulty = lower threshold = more scrambled
    final targetThreshold = _calculateScrambleThreshold(difficulty);

    // Track state to avoid getting stuck
    final stateHistory = <String>{};
    int attempts = 0;
    final maxAttempts = 1000; // Safety limit to prevent infinite loops
    int consecutiveFailures = 0;
    const maxConsecutiveFailures = 10; // Exit if we can't make progress
    int successfulMoves = 0;
    
    // Minimum moves based on difficulty to ensure puzzle is actually scrambled
    final minMoves = (difficulty * 2).clamp(2, 20);

    // Continue scrambling until sufficiently mixed
    while (attempts < maxAttempts) {
      attempts++;

      // Check if we've reached the target scrambling level
      // But ensure we've made at least the minimum number of moves
      final contiguousPercentage = _calculateContiguousPercentage(containers);
      if (successfulMoves >= minMoves && contiguousPercentage <= targetThreshold) {
        break;
      }

      // Try to perform a scrambling move
      final moveSuccessful = _performRandomScrambleMove(containers, colors, stateHistory);
      
      if (!moveSuccessful) {
        consecutiveFailures++;
        if (consecutiveFailures >= maxConsecutiveFailures) {
          // Can't make more progress, accept current state
          break;
        }
      } else {
        consecutiveFailures = 0;
        successfulMoves++;
      }
    }

    // Note: We don't force an empty container here anymore.
    // The solved state already has the correct number of empty slots as specified.
    // If emptySlots < containerCapacity, we intentionally have no empty containers.

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

  /// Calculate the target scrambling threshold based on difficulty
  /// Returns the maximum percentage of contiguous colors allowed
  /// Lower values = more scrambled = harder
  double _calculateScrambleThreshold(int difficulty) {
    // Difficulty 1-2: 40% contiguous (easier, less scrambled)
    // Difficulty 3-4: 30% contiguous
    // Difficulty 5-6: 20% contiguous
    // Difficulty 7-8: 15% contiguous
    // Difficulty 9-10: 10% contiguous (harder, more scrambled)
    
    if (difficulty <= 2) return 0.40;
    if (difficulty <= 4) return 0.30;
    if (difficulty <= 6) return 0.20;
    if (difficulty <= 8) return 0.15;
    return 0.10;
  }

  /// Calculate the percentage of liquid that is in contiguous (sorted) positions
  /// Returns a value between 0.0 (completely scrambled) and 1.0 (completely sorted)
  double _calculateContiguousPercentage(List<Container> containers) {
    int totalVolume = 0;
    int contiguousVolume = 0;

    for (final container in containers) {
      if (container.isEmpty) continue;

      // Count total volume
      final containerVolume = container.currentVolume;
      totalVolume += containerVolume;

      // Count contiguous sequences within this container
      // Group consecutive layers of the same color together
      LiquidColor? currentColor;
      int currentSequenceVolume = 0;

      for (final layer in container.liquidLayers) {
        if (layer.color == currentColor) {
          // Same color continues - add to current sequence
          currentSequenceVolume += layer.volume;
        } else {
          // New color - count the previous sequence if it existed
          if (currentSequenceVolume > 1) {
            contiguousVolume += currentSequenceVolume - 1;
          }
          // Start new sequence
          currentColor = layer.color;
          currentSequenceVolume = layer.volume;
        }
      }

      // Don't forget to count the final sequence
      if (currentSequenceVolume > 1) {
        contiguousVolume += currentSequenceVolume - 1;
      }
    }

    if (totalVolume == 0) return 0.0;
    return contiguousVolume / totalVolume;
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

  /// Validate a level and return list of validation failure reasons
  List<String> _validateWithDetails(Level level) {
    final failures = <String>[];

    // Check if level is already solved
    if (!LevelValidator.validateGeneratedLevel(level)) {
      // Get specific failure reasons
      bool hasAnyLiquid = false;
      bool allSortedAndFull = true;
      
      for (final container in level.initialContainers) {
        if (container.isEmpty) continue;
        hasAnyLiquid = true;
        if (!container.isSorted || !container.isFull) {
          allSortedAndFull = false;
          break;
        }
      }
      
      if (hasAnyLiquid && allSortedAndFull) {
        failures.add('already_solved');
      }

      // Check for completed containers
      for (final container in level.initialContainers) {
        if (!container.isEmpty && container.isSorted && container.isFull) {
          failures.add('has_completed_container');
          break;
        }
      }

      // Check structural validity
      if (!level.isStructurallyValid) {
        failures.add('not_structurally_valid');
      }
    }

    return failures;
  }

  /// Get validation failure tags for a level
  List<String> _getValidationFailureTags(Level level) {
    final failures = _validateWithDetails(level);
    return failures.map((f) => 'validation_failed:$f').toList();
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
