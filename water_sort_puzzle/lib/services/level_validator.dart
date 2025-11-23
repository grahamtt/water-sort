import '../models/level.dart';
import '../models/container.dart';
import '../models/liquid_layer.dart';

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
    
    // If there's only one or no empty containers, we can't remove any
    if (emptyContainers.length <= 1) {
      return level;
    }

    // Try removing empty containers one by one and check if level is still solvable
    Level optimizedLevel = level;
    
    // Start with removing one empty container and increase until we find the limit
    for (int containersToRemove = 1; containersToRemove < emptyContainers.length; containersToRemove++) {
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

  /// Check if a level is solvable using heuristic analysis
  /// 
  /// This implements a fast solvability check without requiring actual solving.
  /// It uses structural analysis to determine if the level can theoretically be solved.
  static bool _isLevelSolvable(Level level) {
    // Basic structural validation first
    if (!level.isStructurallyValid) {
      return false;
    }
    
    // Note: We allow levels with zero empty slots here, as some puzzles can be 
    // solvable through strategic pouring even without empty containers initially.
    // The actual solvability test will validate such cases.
    
    // Analyze color distribution and volumes
    final colorVolumes = <String, int>{};
    final colorFragmentation = <String, int>{};
    
    for (final container in level.initialContainers) {
      final colorsInContainer = <String>{};
      
      for (final layer in container.liquidLayers) {
        final colorName = layer.color.name;
        colorVolumes[colorName] = (colorVolumes[colorName] ?? 0) + layer.volume;
        colorsInContainer.add(colorName);
      }
      
      // Count fragmentation (how many containers each color appears in)
      for (final colorName in colorsInContainer) {
        colorFragmentation[colorName] = (colorFragmentation[colorName] ?? 0) + 1;
      }
    }
    
    // Each color should have exactly one container's worth of liquid
    // (assuming standard container capacity of 4)
    const standardCapacity = 4;
    for (final volume in colorVolumes.values) {
      if (volume != standardCapacity) {
        return false;
      }
    }
    
    // Check if we have enough containers to hold all colors when sorted
    final colorsCount = colorVolumes.length;
    final totalContainers = level.containerCount;
    
    // We need at least one empty slot for moves, so we need more containers than colors
    if (totalContainers <= colorsCount) {
      return false;
    }
    
    // Heuristic: Check if colors are not too fragmented
    // If a color is split across too many containers, it might be unsolvable
    final maxAllowedFragmentation = (level.containerCount / 2).ceil();
    for (final fragmentation in colorFragmentation.values) {
      if (fragmentation > maxAllowedFragmentation) {
        return false;
      }
    }
    
    // Note: We allow levels with no empty space here, as the actual solvability
    // test will determine if such levels are truly solvable through strategic moves.
    // This heuristic check focuses on color distribution and fragmentation rather
    // than requiring empty containers.
    
    return true;
  }
}