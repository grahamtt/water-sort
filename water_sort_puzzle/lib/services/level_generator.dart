import 'dart:math';
import '../models/level.dart';
import '../models/container.dart';
import '../models/liquid_layer.dart';
import '../models/liquid_color.dart';
import '../models/game_state.dart';
import 'game_engine.dart';
import 'level_similarity_checker.dart';
import 'level_validator.dart';
import 'audio_manager.dart';
import 'level_parameters.dart';

/// Result of level validation with detailed failure information
class ValidationResult {
  final bool isValid;
  final List<String> failures;

  const ValidationResult({required this.isValid, required this.failures});

  factory ValidationResult.valid() => const ValidationResult(isValid: true, failures: []);
  factory ValidationResult.invalid(List<String> failures) => ValidationResult(isValid: false, failures: failures);
}

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

  /// Maximum states to explore during solvability check (prevents infinite loops)
  final int maxSolvabilityStates;

  /// Whether to enable actual solvability testing (vs heuristic only)
  final bool enableActualSolvabilityTest;

  /// Whether to return the best candidate even if validation fails
  /// When true, returns the best level found with validation failure metadata in tags
  final bool returnBest;

  const LevelGenerationConfig({
    this.containerCapacity = 4,
    this.minEmptySlots = 1,
    this.maxEmptyContainers = 3,
    this.minLayersPerContainer = 1,
    this.maxLayersPerContainer = 4,
    this.seed,
    this.maxGenerationAttempts = 50,
    this.maxSolvabilityAttempts = 1000,
    this.maxSolvabilityStates = 10000,
    this.enableActualSolvabilityTest = true,
    this.returnBest = false,
  });
}

/// Abstract base class for level generation
abstract class LevelGenerator {
  /// Generate a level with the specified parameters
  /// Container count is calculated as: colorCount + ceil(emptySlots / containerCapacity)
  Level generateLevel(
    int levelId,
    int difficulty,
    int colorCount,
    int containerCapacity,
    int emptySlots,
  );

  /// Generate a unique level that is not similar to existing levels
  /// Container count is calculated as: colorCount + ceil(emptySlots / containerCapacity)
  Level generateUniqueLevel(
    int levelId,
    int difficulty,
    int colorCount,
    int containerCapacity,
    int emptySlots,
    List<Level> existingLevels,
  );

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
    int colorCount,
    int containerCapacity,
    int emptySlots,
  ) {
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

    // Calculate container count: colorCount + ceil(emptySlots / containerCapacity)
    final containerCount = colorCount + (emptySlots ~/ containerCapacity);

    // Check if we have enough total capacity
    final totalCapacity = containerCount * containerCapacity;
    final totalLiquidVolume = totalCapacity - emptySlots;
    
    // Ensure we have enough capacity for at least some liquid per color
    if (totalLiquidVolume < colorCount) {
      throw ArgumentError(
        'Container count ($containerCount) with capacity $containerCapacity '
        'and $emptySlots empty slots is insufficient for $colorCount colors. '
        'Need more containers or fewer empty slots.',
      );
    }

    Level? validLevel;
    Level? bestCandidate;
    List<String> bestCandidateFailures = [];
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
          containerCapacity,
          emptySlots,
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
        final validationResult = _validateGeneratedLevelWithDetails(level);
        if (validationResult.isValid) {
          // Apply optimizations after validation
          // First merge adjacent layers of the same color
          var optimizedLevel = LevelValidator.mergeAdjacentLayers(level);
          // Then optimize empty containers
          validLevel = LevelValidator.optimizeEmptyContainers(optimizedLevel);
        } else if (config.returnBest) {
          // Track the best candidate (fewest failures)
          if (bestCandidate == null || validationResult.failures.length < bestCandidateFailures.length) {
            bestCandidate = level;
            bestCandidateFailures = validationResult.failures;
          }
        }
      } catch (e) {
        // Continue to next attempt if generation fails
        continue;
      }
    }

    if (validLevel == null) {
      // If returnBest is enabled and we have a candidate, return it with failure metadata
      if (config.returnBest && bestCandidate != null) {
        final failureTags = bestCandidateFailures.map((f) => 'validation_failed:$f').toList();
        return bestCandidate.copyWith(
          tags: [...bestCandidate.tags, ...failureTags, 'best_invalid_candidate'],
        );
      }
      
      throw StateError(
        'Failed to generate valid level after ${config.maxGenerationAttempts} attempts. '
        'Try adjusting parameters: levelId=$levelId, difficulty=$difficulty, '
        'containerCount=$containerCount, colorCount=$colorCount, containerCapacity=$containerCapacity',
      );
    }

    return validLevel;
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
    Level? uniqueLevel;
    int attempts = 0;

    while (uniqueLevel == null &&
        attempts < LevelSimilarityChecker.maxGenerationAttempts) {
      attempts++;

      // Generate a candidate level
      final candidate = generateLevel(
        levelId,
        difficulty,
        colorCount,
        containerCapacity,
        emptySlots,
      );

      // Check if it's unique compared to existing levels
      if (!isLevelSimilar(candidate, existingLevels)) {
        uniqueLevel = candidate;
      }
    }

    // Fallback: return a regular generated level if we can't find a unique one
    // This ensures the game can continue even if similarity detection is too strict
    uniqueLevel ??= generateLevel(
        levelId,
        difficulty,
        colorCount,
        containerCapacity,
        emptySlots,
      );

    return uniqueLevel;
  }

  @override
  bool validateLevel(Level level) {
    // First check structural validity
    if (!level.isStructurallyValid) {
      return false;
    }

    // Check basic heuristics first (faster, catches obvious issues)
    if (!_checkSolvabilityHeuristic(level)) {
      return false;
    }

    // If enabled, perform actual solvability test
    if (config.enableActualSolvabilityTest) {
      return _testActualSolvability(level);
    }

    // Fallback to heuristic only if actual test is disabled
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
      final difficulty = LevelParameters.calculateProgressiveDifficulty(i, startDifficulty);
      final containerCapacity = LevelParameters.calculateContainerCapacity(levelId);
      final emptySlots = LevelParameters.calculateEmptySlots(difficulty, containerCapacity);
      
      // Calculate containerCount from emptySlots to determine colorCount
      final containerCount = (emptySlots / containerCapacity).ceil() + 2; // Minimum 2 colors
      final colorCount = LevelParameters.calculateColorCount(difficulty, containerCount);

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
    int containerCapacity,
    int emptySlots,
  ) {
    final containers = <Container>[];

    // Create all containers initially empty
    for (int i = 0; i < containerCount; i++) {
      containers.add(
        Container(id: i, capacity: containerCapacity, liquidLayers: []),
      );
    }

    // Calculate how much liquid to generate per color
    // If emptySlots < containerCapacity, reduce the last S colors by 1 slot each
    final colorVolumes = <LiquidColor, int>{};
    
    if (emptySlots < containerCapacity) {
      // We need to reduce some colors by 1 slot
      final colorsToReduce = emptySlots;
      
      for (int i = 0; i < colors.length; i++) {
        if (i >= colors.length - colorsToReduce) {
          // This is one of the last S colors, reduce by 1
          colorVolumes[colors[i]] = containerCapacity - 1;
        } else {
          // Full container capacity for this color
          colorVolumes[colors[i]] = containerCapacity;
        }
      }
    } else {
      // All colors get full container capacity
      for (final color in colors) {
        colorVolumes[color] = containerCapacity;
      }
    }

    // Generate liquid for each color with the calculated volume
    final colorLiquids = <LiquidColor, List<LiquidLayer>>{};
    for (final color in colors) {
      final volume = colorVolumes[color]!;
      colorLiquids[color] = _generateLiquidForColor(color, difficulty, volume);
    }

    // Distribute liquids ensuring we maintain empty slots
    _distributeLiquidsWithEmptySlots(containers, colorLiquids, emptySlots, containerCapacity);

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
    int emptySlots,
    int containerCapacity,
  ) {
    // Calculate total liquid volume
    int totalLiquidVolume = 0;
    for (final layers in colorLiquids.values) {
      for (final layer in layers) {
        totalLiquidVolume += layer.volume;
      }
    }

    // Calculate total container capacity
    final totalCapacity = containers.length * containerCapacity;

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

    // Use the specified empty slots
    final maxFillCapacity = totalCapacity - emptySlots;

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

  /// Validate a generated level and return detailed failure information
  ValidationResult _validateGeneratedLevelWithDetails(Level level) {
    final failures = <String>[];

    // Check if level is already solved
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

    // Check that we have minimum empty slots
    final totalEmptySlots = level.initialContainers.fold(
      0,
      (sum, container) => sum + container.remainingCapacity,
    );
    if (totalEmptySlots < config.minEmptySlots) {
      failures.add('insufficient_empty_slots:$totalEmptySlots<${config.minEmptySlots}');
    }

    // Test solvability (simplified check for now)
    if (!_checkSolvabilityHeuristic(level)) {
      failures.add('failed_solvability_heuristic');
    }

    return failures.isEmpty 
      ? ValidationResult.valid() 
      : ValidationResult.invalid(failures);
  }

  /// Test if a level is actually solvable by attempting to solve it
  /// Uses an optimized BFS approach with pruning and move ordering
  bool _testActualSolvability(Level level) {
    try {
      // Use a game engine without audio for testing (avoids Flutter binding issues)
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
      return _attemptSolveWithOptimizedBFS(gameEngine, initialState);
    } catch (e) {
      // If any error occurs during solving attempt, consider it unsolvable
      return false;
    }
  }

  /// Attempt to solve the level using optimized breadth-first search
  /// Includes pruning, move ordering, and state limits to ensure performance
  bool _attemptSolveWithOptimizedBFS(
    WaterSortGameEngine gameEngine,
    GameState initialState,
  ) {
    final visited = <String>{};
    final queue = <_SearchNode>[_SearchNode(initialState, 0)];
    int statesExplored = 0;

    while (queue.isNotEmpty && statesExplored < config.maxSolvabilityStates) {
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

      // Prune if depth is too large (prevents exploring inefficient solutions)
      if (node.depth > config.maxSolvabilityAttempts) {
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
  /// Prioritizes moves that are more likely to lead to a solution
  List<_PrioritizedMove> _generatePrioritizedMoves(
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
  /// Prioritizes moves that:
  /// 1. Complete a container (pour into same color to fill it)
  /// 2. Empty a container completely
  /// 3. Consolidate colors
  int _calculateMovePriority(
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
  /// Uses a normalized representation that is order-independent
  String _generateStateSignature(GameState gameState) {
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
    // This is crucial for detecting equivalent states with containers in different positions
    containerSignatures.sort();
    return containerSignatures.join('|');
  }

  /// Generate liquid layers for a specific color
  List<LiquidLayer> _generateLiquidForColor(LiquidColor color, int difficulty, int totalVolume) {
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
    // Note: This check is now approximate since containerCapacity varies by level
    // We'll allow some flexibility here
    final expectedVolume = level.initialContainers.isNotEmpty 
        ? level.initialContainers.first.capacity 
        : 4;
    for (final volume in colorVolumes.values) {
      if (volume != expectedVolume) {
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
