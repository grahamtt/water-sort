import 'dart:math';
import '../models/level.dart';
import '../models/container.dart';
import '../models/liquid_layer.dart';
import '../models/liquid_color.dart';
import '../models/game_state.dart';
import '../utils/level_parameters.dart';
import 'game_engine.dart';
import 'level_similarity_checker.dart';
import 'level_validator.dart';
import 'test_mode_manager.dart';

/// Configuration for level generation
class LevelGenerationConfig {
  /// Standard container capacity
  final int containerCapacity;

  /// Minimum number of empty slots required (can be distributed across containers)
  final int minEmptySlots;

  /// Maximum number of empty containers allowed
  final int maxEmptyContainers;

  /// Minimum liquid layers per container
  final int minLayersPerContainer;

  /// Maximum liquid layers per container
  final int maxLayersPerContainer;

  /// Random seed for reproducible generation (null for random)
  final int? seed;

  /// Maximum attempts to generate a valid level
  final int maxGenerationAttempts;

  /// Maximum attempts to validate solvability
  final int maxSolvabilityAttempts;

  const LevelGenerationConfig({
    this.containerCapacity = 4,
    this.minEmptySlots = 1,
    this.maxEmptyContainers = 3,
    this.minLayersPerContainer = 1,
    this.maxLayersPerContainer = 4,
    this.seed,
    this.maxGenerationAttempts = 50,
    this.maxSolvabilityAttempts = 100,
  });
}

/// Abstract base class for level generation
abstract class LevelGenerator {
  /// Generate a level with the specified parameters
  Level generateLevel(
    int levelId,
    int difficulty,
    int containerCount,
    int colorCount, {
    bool ignoreProgressionLimits = false,
  });

  /// Generate a unique level that is not similar to existing levels
  Level generateUniqueLevel(
    int levelId,
    int difficulty,
    int containerCount,
    int colorCount,
    List<Level> existingLevels, {
    bool ignoreProgressionLimits = false,
  });

  /// Validate that a level is solvable
  bool validateLevel(Level level);

  /// Check if a level is similar to any level in a list
  bool isLevelSimilar(Level newLevel, List<Level> existingLevels);

  /// Generate a normalized signature for a level
  String generateLevelSignature(Level level);

  /// Generate a series of levels with progressive difficulty
  List<Level> generateLevelSeries(
    int startId,
    int count, {
    int startDifficulty = 1,
  });

  /// Check if a level has any completed containers
  /// A completed container is one that is full and contains only one color
  bool hasCompletedContainers(Level level);
}

/// Concrete implementation of the level generator
class WaterSortLevelGenerator implements LevelGenerator {
  final LevelGenerationConfig config;
  final Random _random;

  WaterSortLevelGenerator({this.config = const LevelGenerationConfig()})
    : _random = Random(config.seed);

  @override
  Level generateLevel(
    int levelId,
    int difficulty,
    int containerCount,
    int colorCount, {
    bool ignoreProgressionLimits = false,
  }) {
    try {
      // Validate input parameters
      if (colorCount > LiquidColor.values.length) {
        throw ArgumentError(
          'Color count ($colorCount) cannot exceed available colors (${LiquidColor.values.length})',
        );
      }

      // In test mode, allow more flexible parameter combinations
      if (!ignoreProgressionLimits) {
        // Check if we have enough containers for the colors and minimum empty slots
        if (!LevelParameters.isValidConfiguration(
          containerCount: containerCount,
          colorCount: colorCount,
          containerCapacity: config.containerCapacity,
          minEmptySlots: config.minEmptySlots,
        )) {
          final minContainers = LevelParameters.calculateMinContainers(
            colorCount: colorCount,
            containerCapacity: config.containerCapacity,
            minEmptySlots: config.minEmptySlots,
          );
          throw ArgumentError(
            'Container count ($containerCount) is insufficient for $colorCount colors '
            'with minimum ${config.minEmptySlots} empty slots. '
            'Need at least $minContainers containers.',
          );
        }
      } else {
        // In test mode, ensure we have at least the minimum viable configuration
        final minContainers = colorCount + 1; // At least one container per color plus one empty
        if (containerCount < minContainers) {
          throw ArgumentError(
            'Even in test mode, need at least $minContainers containers for $colorCount colors',
          );
        }
      }

      Level? validLevel;
      int attempts = 0;

      // Try to generate a valid level within the attempt limit
      while (validLevel == null && attempts < config.maxGenerationAttempts) {
        attempts++;

        try {
          // Select colors for this level
          final selectedColors = _selectColors(colorCount);

          // Generate containers with proper empty slot distribution
          final containers = _generateValidContainers(
            containerCount,
            selectedColors,
            difficulty,
          );

          // Create the level
          final level = Level(
            id: levelId,
            difficulty: difficulty,
            containerCount: containerCount,
            colorCount: colorCount,
            initialContainers: containers,
            tags: _generateTags(levelId, difficulty),
          );

          // Validate the level meets all requirements
          if (_validateGeneratedLevel(level)) {
            // Apply optimizations after validation
            // First merge adjacent layers of the same color
            var optimizedLevel = LevelValidator.mergeAdjacentLayers(level);
            // Then optimize empty containers
            validLevel = LevelValidator.optimizeEmptyContainers(optimizedLevel);
          }
        } catch (e) {
          // Continue to next attempt if generation fails
          continue;
        }
      }

      if (validLevel == null) {
        if (ignoreProgressionLimits) {
          // In test mode, provide more detailed error information
          throw TestModeException(
            TestModeErrorType.levelGenerationFailure,
            'Failed to generate valid level in test mode after ${config.maxGenerationAttempts} attempts. '
            'Parameters: levelId=$levelId, difficulty=$difficulty, '
            'containerCount=$containerCount, colorCount=$colorCount',
          );
        } else {
          throw StateError(
            'Failed to generate valid level after ${config.maxGenerationAttempts} attempts. '
            'Try adjusting parameters: levelId=$levelId, difficulty=$difficulty, '
            'containerCount=$containerCount, colorCount=$colorCount',
          );
        }
      }

      return validLevel;
    } catch (e) {
      // Handle any unexpected errors during level generation
      if (ignoreProgressionLimits) {
        throw TestModeException(
          TestModeErrorType.levelGenerationFailure,
          'Unexpected error during test mode level generation: $e',
          e,
        );
      } else {
        rethrow;
      }
    }
  }

  @override
  Level generateUniqueLevel(
    int levelId,
    int difficulty,
    int containerCount,
    int colorCount,
    List<Level> existingLevels, {
    bool ignoreProgressionLimits = false,
  }) {
    Level? uniqueLevel;
    int attempts = 0;

    while (uniqueLevel == null &&
        attempts < LevelSimilarityChecker.maxGenerationAttempts) {
      attempts++;

      // Generate a candidate level
      final candidate = generateLevel(
        levelId,
        difficulty,
        containerCount,
        colorCount,
        ignoreProgressionLimits: ignoreProgressionLimits,
      );

      // Check if it's unique compared to existing levels
      if (!isLevelSimilar(candidate, existingLevels)) {
        uniqueLevel = candidate;
      }
    }

    if (uniqueLevel == null) {
      // Fallback: return a regular generated level if we can't find a unique one
      // This ensures the game can continue even if similarity detection is too strict
      uniqueLevel = generateLevel(
        levelId,
        difficulty,
        containerCount,
        colorCount,
        ignoreProgressionLimits: ignoreProgressionLimits,
      );
    }

    return uniqueLevel;
  }

  @override
  bool validateLevel(Level level) {
    // First check structural validity
    if (!level.isStructurallyValid) {
      return false;
    }

    // Check basic heuristics first (faster)
    if (!_checkSolvabilityHeuristic(level)) {
      return false;
    }

    // For now, use heuristic check only (actual solvability test can be enabled later)
    // TODO: Enable actual solvability test when performance is optimized
    // return _testActualSolvability(level);
    return true;
  }

  /// Optimize a level by removing unnecessary empty containers
  /// This ensures levels use the minimum number of containers needed
  Level optimizeLevel(Level level) {
    return LevelValidator.optimizeEmptyContainers(level);
  }

  @override
  bool isLevelSimilar(Level newLevel, List<Level> existingLevels) {
    return LevelSimilarityChecker.isLevelSimilarToAny(newLevel, existingLevels);
  }

  @override
  String generateLevelSignature(Level level) {
    return LevelSimilarityChecker.generateNormalizedSignature(level);
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
    // Delegate to LevelValidator for consistency
    return LevelValidator.hasCompletedContainers(level);
  }

  /// Select colors for the level
  List<LiquidColor> _selectColors(int colorCount) {
    final availableColors = List<LiquidColor>.from(LiquidColor.values);
    availableColors.shuffle(_random);
    return availableColors.take(colorCount).toList();
  }

  /// Generate containers that meet all requirements
  List<Container> _generateValidContainers(
    int containerCount,
    List<LiquidColor> colors,
    int difficulty,
  ) {
    final containers = <Container>[];

    // Create all containers initially empty
    for (int i = 0; i < containerCount; i++) {
      containers.add(
        Container(id: i, capacity: config.containerCapacity, liquidLayers: []),
      );
    }

    // Generate liquid for each color (one container's worth per color)
    final colorLiquids = <LiquidColor, List<LiquidLayer>>{};
    for (final color in colors) {
      colorLiquids[color] = _generateLiquidForColor(color, difficulty);
    }

    // Distribute liquids ensuring we maintain empty slots
    _distributeLiquidsWithEmptySlots(containers, colorLiquids, difficulty);

    // Shuffle containers to randomize positions
    containers.shuffle(_random);

    // Reassign IDs to maintain order
    for (int i = 0; i < containers.length; i++) {
      containers[i] = containers[i].copyWith(id: i);
    }

    return containers;
  }

  /// Distribute liquids while ensuring minimum empty slots
  void _distributeLiquidsWithEmptySlots(
    List<Container> containers,
    Map<LiquidColor, List<LiquidLayer>> colorLiquids,
    int difficulty,
  ) {
    // Calculate total liquid volume
    int totalLiquidVolume = 0;
    for (final layers in colorLiquids.values) {
      for (final layer in layers) {
        totalLiquidVolume += layer.volume;
      }
    }

    // Calculate total container capacity
    final totalCapacity = containers.length * config.containerCapacity;

    // Ensure we have enough empty slots
    final availableCapacity = totalCapacity - totalLiquidVolume;
    if (availableCapacity < config.minEmptySlots) {
      throw StateError('Not enough capacity for minimum empty slots');
    }

    // Collect all liquid layers and shuffle them
    final layersToPlace = <LiquidLayer>[];
    for (final layers in colorLiquids.values) {
      layersToPlace.addAll(layers);
    }
    layersToPlace.shuffle(_random);

    // For harder levels, we can fill containers more densely
    // but still maintain at least minEmptySlots
    final targetEmptySlots = _calculateTargetEmptySlots(
      difficulty,
      availableCapacity,
    );
    final maxFillCapacity = totalCapacity - targetEmptySlots;

    int currentFillVolume = 0;

    // Place layers while respecting capacity limits
    while (layersToPlace.isNotEmpty && currentFillVolume < maxFillCapacity) {
      final layer = layersToPlace.removeAt(0);
      bool placed = false;

      // Try to place the layer in a container that can fit it
      for (final container in containers) {
        final wouldExceedLimit =
            currentFillVolume + layer.volume > maxFillCapacity;
        if (!wouldExceedLimit && container.remainingCapacity >= layer.volume) {
          container.liquidLayers.add(layer);
          currentFillVolume += layer.volume;
          placed = true;
          break;
        }
      }

      // If we can't place the full layer, try to split it
      if (!placed) {
        final remainingCapacity = maxFillCapacity - currentFillVolume;
        if (remainingCapacity > 0) {
          // Find a container with space
          for (final container in containers) {
            if (container.remainingCapacity > 0) {
              final spaceAvailable = min(
                container.remainingCapacity,
                remainingCapacity,
              );
              final splitLayers = layer.split(spaceAvailable);

              container.liquidLayers.add(splitLayers[0]);
              currentFillVolume += splitLayers[0].volume;

              // Add remaining part back if it has volume
              if (splitLayers[1].volume > 0) {
                layersToPlace.add(splitLayers[1]);
              }
              placed = true;
              break;
            }
          }
        }
      }

      if (!placed) {
        // If we can't place any more liquid, we're done
        break;
      }
    }

    // If there are still layers to place, we have a problem
    if (layersToPlace.isNotEmpty) {
      throw StateError(
        'Could not place all liquid layers while maintaining empty slots',
      );
    }
  }

  /// Calculate target empty slots based on difficulty
  int _calculateTargetEmptySlots(int difficulty, int availableCapacity) {
    if (difficulty <= 3) {
      // Easy levels: use more empty slots (up to 2 full containers worth)
      return min(availableCapacity, config.containerCapacity * 2);
    } else if (difficulty <= 6) {
      // Medium levels: moderate empty slots (up to 1.5 containers worth)
      return min(availableCapacity, (config.containerCapacity * 1.5).round());
    } else {
      // Hard levels: minimum empty slots (but at least the required minimum)
      return max(
        config.minEmptySlots,
        min(availableCapacity, config.containerCapacity),
      );
    }
  }

  /// Validate that a generated level meets all requirements
  bool _validateGeneratedLevel(Level level) {
    // Use the LevelValidator to check all requirements including completed containers
    if (!LevelValidator.validateGeneratedLevel(level)) {
      return false;
    }

    // Check that we have minimum empty slots
    final totalEmptySlots = level.initialContainers.fold(
      0,
      (sum, container) => sum + container.remainingCapacity,
    );
    if (totalEmptySlots < config.minEmptySlots) {
      return false;
    }

    // Test solvability (simplified check for now)
    return _checkSolvabilityHeuristic(level);
  }

  /// Check if the level is already in a solved state
  bool _isLevelAlreadySolved(Level level) {
    // A level is solved if all non-empty containers contain only one color
    for (final container in level.initialContainers) {
      if (!container.isEmpty && !container.isSorted) {
        return false; // Found a mixed container, so not solved
      }
    }

    // If we get here, all containers are either empty or sorted
    // This means the level is already solved
    return true;
  }

  /// Test if a level is actually solvable by attempting to solve it
  bool _testActualSolvability(Level level) {
    try {
      final gameEngine = WaterSortGameEngine();
      final initialState = gameEngine.initializeLevel(
        level.id,
        level.initialContainers,
      );

      // Use a simple breadth-first search to test solvability
      return _attemptSolveWithBFS(gameEngine, initialState);
    } catch (e) {
      // If any error occurs during solving attempt, consider it unsolvable
      return false;
    }
  }

  /// Attempt to solve the level using breadth-first search
  bool _attemptSolveWithBFS(
    WaterSortGameEngine gameEngine,
    GameState initialState,
  ) {
    final visited = <String>{};
    final queue = <GameState>[initialState];
    int attempts = 0;

    while (queue.isNotEmpty && attempts < config.maxSolvabilityAttempts) {
      attempts++;
      final currentState = queue.removeAt(0);

      // Check if this state is solved
      if (gameEngine.checkWinCondition(currentState)) {
        return true;
      }

      // Generate a state signature to avoid revisiting the same state
      final stateSignature = _generateStateSignature(currentState);
      if (visited.contains(stateSignature)) {
        continue;
      }
      visited.add(stateSignature);

      // Try all possible moves from this state
      for (int fromId = 0; fromId < currentState.containers.length; fromId++) {
        for (int toId = 0; toId < currentState.containers.length; toId++) {
          if (fromId == toId) continue;

          final pourResult = gameEngine.validatePour(
            currentState,
            fromId,
            toId,
          );
          if (pourResult.isSuccess) {
            try {
              final newState = gameEngine.executePour(
                currentState,
                fromId,
                toId,
              );
              queue.add(newState);
            } catch (e) {
              // Skip invalid moves
              continue;
            }
          }
        }
      }
    }

    // If we exhausted all possibilities without finding a solution
    return false;
  }

  /// Generate a unique signature for a game state to detect duplicates
  String _generateStateSignature(GameState gameState) {
    final containerSignatures = <String>[];

    for (final container in gameState.containers) {
      final layerSignatures = container.liquidLayers
          .map((layer) => '${layer.color.name}:${layer.volume}')
          .join(',');
      containerSignatures.add('[$layerSignatures]');
    }

    // Sort container signatures to make the state signature order-independent
    containerSignatures.sort();
    return containerSignatures.join('|');
  }

  /// Generate liquid layers for a specific color
  List<LiquidLayer> _generateLiquidForColor(LiquidColor color, int difficulty) {
    // Determine how many layers to split this color into
    int layerCount;

    if (difficulty <= 2) {
      // Easy: 1-2 layers
      layerCount = _random.nextInt(2) + 1;
    } else if (difficulty <= 5) {
      // Medium: 2-3 layers
      layerCount = _random.nextInt(2) + 2;
    } else {
      // Hard: 2-4 layers
      layerCount = _random.nextInt(3) + 2;
    }

    // Split the total volume into layers
    final totalVolume = config.containerCapacity;
    final layers = <LiquidLayer>[];
    int remainingVolume = totalVolume;

    for (int i = 0; i < layerCount - 1; i++) {
      final maxLayerVolume = remainingVolume - (layerCount - i - 1);
      final layerVolume = _random.nextInt(maxLayerVolume) + 1;
      layers.add(LiquidLayer(color: color, volume: layerVolume));
      remainingVolume -= layerVolume;
    }

    // Add the final layer with remaining volume
    if (remainingVolume > 0) {
      layers.add(LiquidLayer(color: color, volume: remainingVolume));
    }

    return layers;
  }

  /// Check if a level is likely solvable using heuristics
  bool _checkSolvabilityHeuristic(Level level) {
    // Count liquid volumes by color
    final colorVolumes = <LiquidColor, int>{};

    for (final container in level.initialContainers) {
      for (final layer in container.liquidLayers) {
        colorVolumes[layer.color] =
            (colorVolumes[layer.color] ?? 0) + layer.volume;
      }
    }

    // Check that we have the expected number of colors
    if (colorVolumes.length != level.colorCount) {
      return false;
    }

    // Check that each color has exactly one container's worth
    for (final volume in colorVolumes.values) {
      if (volume != config.containerCapacity) {
        return false;
      }
    }

    // Check that we have at least one empty slot (not necessarily a full container)
    final totalEmptySlots = level.initialContainers.fold(
      0,
      (sum, container) => sum + container.remainingCapacity,
    );
    if (totalEmptySlots == 0) {
      return false;
    }

    // Check that liquids are sufficiently mixed (not too many already sorted)
    int sortedContainers = 0;
    for (final container in level.initialContainers) {
      if (!container.isEmpty && container.isSorted) {
        sortedContainers++;
      }
    }

    // Allow at most 1 container to be already sorted (for easier levels)
    if (sortedContainers > 1) {
      return false;
    }

    return true;
  }

  /// Calculate progressive difficulty for level series
  int _calculateProgressiveDifficulty(int levelIndex, int startDifficulty) {
    // Gradually increase difficulty
    final difficultyIncrease = levelIndex ~/ 5; // Increase every 5 levels
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
    final maxColors = LevelParameters.calculateMaxColors(
      containerCount: containerCount,
      containerCapacity: config.containerCapacity,
      minEmptySlots: config.minEmptySlots,
    );

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
