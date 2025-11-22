import 'dart:math';
import '../models/level.dart';
import '../models/container.dart';
import '../models/liquid_layer.dart';
import '../models/liquid_color.dart';

/// Configuration for level generation
class LevelGenerationConfig {
  /// Standard container capacity
  final int containerCapacity;
  
  /// Minimum number of empty containers required
  final int minEmptyContainers;
  
  /// Maximum number of empty containers allowed
  final int maxEmptyContainers;
  
  /// Minimum liquid layers per container
  final int minLayersPerContainer;
  
  /// Maximum liquid layers per container
  final int maxLayersPerContainer;
  
  /// Random seed for reproducible generation (null for random)
  final int? seed;
  
  const LevelGenerationConfig({
    this.containerCapacity = 4,
    this.minEmptyContainers = 1,
    this.maxEmptyContainers = 3,
    this.minLayersPerContainer = 1,
    this.maxLayersPerContainer = 4,
    this.seed,
  });
}

/// Abstract base class for level generation
abstract class LevelGenerator {
  /// Generate a level with the specified parameters
  Level generateLevel(int levelId, int difficulty, int containerCount, int colorCount);
  
  /// Validate that a level is solvable
  bool validateLevel(Level level);
  
  /// Generate a series of levels with progressive difficulty
  List<Level> generateLevelSeries(int startId, int count, {int startDifficulty = 1});
}

/// Concrete implementation of the level generator
class WaterSortLevelGenerator implements LevelGenerator {
  final LevelGenerationConfig config;
  final Random _random;
  
  WaterSortLevelGenerator({
    this.config = const LevelGenerationConfig(),
  }) : _random = Random(config.seed);
  
  @override
  Level generateLevel(int levelId, int difficulty, int containerCount, int colorCount) {
    // Validate input parameters
    if (containerCount < colorCount + config.minEmptyContainers) {
      throw ArgumentError(
        'Container count ($containerCount) must be at least colorCount ($colorCount) + minEmptyContainers (${config.minEmptyContainers})'
      );
    }
    
    if (colorCount > LiquidColor.values.length) {
      throw ArgumentError(
        'Color count ($colorCount) cannot exceed available colors (${LiquidColor.values.length})'
      );
    }
    
    // Select colors for this level
    final selectedColors = _selectColors(colorCount);
    
    // Determine number of empty containers based on difficulty
    final emptyContainerCount = _calculateEmptyContainers(difficulty, containerCount, colorCount);
    
    // Generate containers
    final containers = _generateContainers(
      containerCount,
      emptyContainerCount,
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
    
    return level;
  }
  
  @override
  bool validateLevel(Level level) {
    // First check structural validity
    if (!level.isStructurallyValid) {
      return false;
    }
    
    // Use a simple heuristic to check solvability
    // A level is likely solvable if:
    // 1. Each color has exactly one container's worth of liquid
    // 2. There are enough empty containers to facilitate moves
    // 3. The liquid is sufficiently mixed (not already sorted)
    
    return _checkSolvabilityHeuristic(level);
  }
  
  @override
  List<Level> generateLevelSeries(int startId, int count, {int startDifficulty = 1}) {
    final levels = <Level>[];
    
    for (int i = 0; i < count; i++) {
      final levelId = startId + i;
      final difficulty = _calculateProgressiveDifficulty(i, startDifficulty);
      final containerCount = _calculateContainerCount(difficulty);
      final colorCount = _calculateColorCount(difficulty, containerCount);
      
      final level = generateLevel(levelId, difficulty, containerCount, colorCount);
      levels.add(level);
    }
    
    return levels;
  }
  
  /// Select colors for the level
  List<LiquidColor> _selectColors(int colorCount) {
    final availableColors = List<LiquidColor>.from(LiquidColor.values);
    availableColors.shuffle(_random);
    return availableColors.take(colorCount).toList();
  }
  
  /// Calculate the number of empty containers based on difficulty
  int _calculateEmptyContainers(int difficulty, int containerCount, int colorCount) {
    // Easier levels have more empty containers
    // Harder levels have fewer empty containers (but at least the minimum)
    
    final maxPossibleEmpty = containerCount - colorCount;
    final adjustedMax = min(maxPossibleEmpty, config.maxEmptyContainers);
    
    if (difficulty <= 3) {
      // Easy levels: use maximum empty containers
      return adjustedMax;
    } else if (difficulty <= 6) {
      // Medium levels: use middle range
      return max(config.minEmptyContainers, adjustedMax - 1);
    } else {
      // Hard levels: use minimum empty containers
      return config.minEmptyContainers;
    }
  }
  
  /// Generate containers for the level
  List<Container> _generateContainers(
    int containerCount,
    int emptyContainerCount,
    List<LiquidColor> colors,
    int difficulty,
  ) {
    final containers = <Container>[];
    
    // Create empty containers first
    for (int i = 0; i < emptyContainerCount; i++) {
      containers.add(Container(
        id: i,
        capacity: config.containerCapacity,
        liquidLayers: [],
      ));
    }
    
    // Create filled containers
    final filledContainerCount = containerCount - emptyContainerCount;
    
    // Generate liquid for each color (one container's worth per color)
    final colorLiquids = <LiquidColor, List<LiquidLayer>>{};
    for (final color in colors) {
      colorLiquids[color] = _generateLiquidForColor(color, difficulty);
    }
    
    // Distribute liquids among filled containers
    final filledContainers = _distributeLiquids(
      filledContainerCount,
      colorLiquids,
      emptyContainerCount,
    );
    
    containers.addAll(filledContainers);
    
    // Shuffle containers to randomize positions
    containers.shuffle(_random);
    
    // Reassign IDs to maintain order
    for (int i = 0; i < containers.length; i++) {
      containers[i] = containers[i].copyWith(id: i);
    }
    
    return containers;
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
  
  /// Distribute liquid layers among containers
  List<Container> _distributeLiquids(
    int containerCount,
    Map<LiquidColor, List<LiquidLayer>> colorLiquids,
    int startingId,
  ) {
    final containers = <Container>[];
    
    // Create empty containers
    for (int i = 0; i < containerCount; i++) {
      containers.add(Container(
        id: startingId + i,
        capacity: config.containerCapacity,
        liquidLayers: [],
      ));
    }
    
    // Collect all liquid layers and shuffle them
    final layersToPlace = <LiquidLayer>[];
    for (final layers in colorLiquids.values) {
      layersToPlace.addAll(layers);
    }
    layersToPlace.shuffle(_random);
    
    // Process layers until all are placed
    while (layersToPlace.isNotEmpty) {
      final layer = layersToPlace.removeAt(0);
      bool placed = false;
      
      // Try to find a container that can fit this layer completely
      for (final container in containers) {
        if (container.remainingCapacity >= layer.volume) {
          container.liquidLayers.add(layer);
          placed = true;
          break;
        }
      }
      
      // If no container can fit the layer completely, split it
      if (!placed) {
        for (final container in containers) {
          if (container.remainingCapacity > 0) {
            final availableSpace = container.remainingCapacity;
            final splitLayers = layer.split(availableSpace);
            
            // Add the part that fits
            container.liquidLayers.add(splitLayers[0]);
            
            // Add the remaining part back to the queue
            final remainingLayer = splitLayers[1];
            if (remainingLayer.volume > 0) {
              layersToPlace.add(remainingLayer);
            }
            
            placed = true;
            break;
          }
        }
      }
      
      if (!placed) {
        throw StateError('Could not place liquid layer: insufficient total container capacity');
      }
    }
    
    return containers;
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
    
    // Check that we have at least one empty container
    if (level.emptyContainerCount == 0) {
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
    final maxColors = containerCount - config.minEmptyContainers;
    
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