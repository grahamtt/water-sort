import '../models/level.dart';
import '../models/container.dart';
import '../models/liquid_color.dart';

/// Service for detecting similarity between levels to ensure unique gameplay experiences
class LevelSimilarityChecker {
  /// Threshold for determining if two levels are too similar (80%)
  static const double similarityThreshold = 0.8;
  
  /// Maximum number of attempts to generate a unique level
  static const int maxGenerationAttempts = 50;

  /// Check if two levels are similar based on structural patterns
  /// Returns true if levels are too similar (above threshold)
  static bool areLevelsSimilar(Level level1, Level level2) {
    // Quick checks for obvious differences
    if (level1.containerCount != level2.containerCount) return false;
    if (level1.colorCount != level2.colorCount) return false;
    
    // Compare structural patterns independent of specific colors and container order
    final similarity = compareStructuralPatterns(level1, level2);
    return similarity >= similarityThreshold;
  }

  /// Generate a normalized signature for a level that is color-agnostic and order-independent
  static String generateNormalizedSignature(Level level) {
    // Create color-agnostic signature representing the level structure
    final containers = level.initialContainers;
    final normalizedContainers = normalizeColors(containers);
    
    // Sort patterns to make container order irrelevant for comparison
    final sortedPatterns = List<String>.from(normalizedContainers)..sort();

    return "containers:${containers.length}|colors:${level.colorCount}|pattern:${sortedPatterns.join(',')}";
  }

  /// Compare structural patterns between two levels
  /// Returns similarity score from 0.0 (completely different) to 1.0 (identical)
  static double compareStructuralPatterns(Level level1, Level level2) {
    // Create canonical patterns for both levels using the same method as signature generation
    final pattern1 = normalizeColors(level1.initialContainers);
    final pattern2 = normalizeColors(level2.initialContainers);

    // Calculate similarity score based on pattern matching
    return calculatePatternSimilarity(pattern1, pattern2);
  }



  /// Convert container patterns to normalized color representations
  /// Returns list of pattern strings where colors are represented as A, B, C, etc.
  static List<String> normalizeColors(List<Container> containers) {
    // First pass: collect all unique colors and sort them for consistent mapping
    final allColors = <LiquidColor>{};
    for (final container in containers) {
      for (final layer in container.liquidLayers) {
        allColors.add(layer.color);
      }
    }
    
    // Sort colors by their enum index to ensure consistent mapping across different levels
    final sortedColors = allColors.toList()..sort((a, b) => a.index.compareTo(b.index));
    
    // Create consistent color mapping
    final colorMap = <LiquidColor, String>{};
    for (int i = 0; i < sortedColors.length; i++) {
      colorMap[sortedColors[i]] = String.fromCharCode('A'.codeUnitAt(0) + i);
    }

    // Convert to normalized patterns
    return containers.map((container) {
      if (container.isEmpty) return 'EMPTY';

      final patternParts = <String>[];
      for (final layer in container.liquidLayers) {
        final colorLabel = colorMap[layer.color]!;
        patternParts.add(colorLabel * layer.volume);
      }
      
      return patternParts.join('');
    }).toList();
  }

  /// Calculate similarity between two normalized patterns
  /// Uses container order independence by sorting patterns before comparison
  static double calculatePatternSimilarity(List<String> pattern1, List<String> pattern2) {
    if (pattern1.length != pattern2.length) return 0.0;

    // Sort both patterns to make container order irrelevant
    final sortedPattern1 = List<String>.from(pattern1)..sort();
    final sortedPattern2 = List<String>.from(pattern2)..sort();

    // Count exact matches
    int exactMatches = 0;
    for (int i = 0; i < sortedPattern1.length; i++) {
      if (sortedPattern1[i] == sortedPattern2[i]) {
        exactMatches++;
      }
    }

    // Calculate similarity as the percentage of exact matches
    return exactMatches / sortedPattern1.length;
  }



  /// Validate that a level is sufficiently different from a list of existing levels
  static bool isLevelUnique(Level newLevel, List<Level> existingLevels) {
    for (final existingLevel in existingLevels) {
      if (areLevelsSimilar(newLevel, existingLevel)) {
        return false;
      }
    }
    return true;
  }

  /// Check if a level is similar to any level in a list of existing levels
  /// Returns true if the level is similar to at least one existing level
  static bool isLevelSimilarToAny(Level newLevel, List<Level> existingLevels) {
    return !isLevelUnique(newLevel, existingLevels);
  }

  /// Get detailed similarity analysis between two levels for debugging
  static Map<String, dynamic> getSimilarityAnalysis(Level level1, Level level2) {
    final pattern1 = normalizeColors(level1.initialContainers);
    final pattern2 = normalizeColors(level2.initialContainers);
    final similarity = calculatePatternSimilarity(pattern1, pattern2);
    
    return {
      'similarity_score': similarity,
      'is_similar': similarity >= similarityThreshold,
      'threshold': similarityThreshold,
      'level1_signature': generateNormalizedSignature(level1),
      'level2_signature': generateNormalizedSignature(level2),
      'level1_pattern': pattern1,
      'level2_pattern': pattern2,
      'sorted_pattern1': List<String>.from(pattern1)..sort(),
      'sorted_pattern2': List<String>.from(pattern2)..sort(),
    };
  }

  /// Check if a pattern represents a valid puzzle (not already solved)
  static bool isPatternValid(List<String> pattern) {
    // A pattern is invalid if it represents an already solved state
    // (all non-empty containers have only one color type)
    
    for (final containerPattern in pattern) {
      if (containerPattern == 'EMPTY') continue;
      
      // Check if container has mixed colors
      final uniqueChars = containerPattern.split('').toSet();
      if (uniqueChars.length > 1) {
        return true; // Found mixed colors, so puzzle is not solved
      }
    }
    
    // All containers are either empty or single-color (solved state)
    return false;
  }

  /// Generate a hash code for a level pattern for efficient comparison
  static int generatePatternHash(Level level) {
    final signature = generateNormalizedSignature(level);
    return signature.hashCode;
  }

  /// Analyze the similarity distribution within a set of levels
  /// Returns analysis data about uniqueness and similarity patterns
  static Map<String, dynamic> analyzeLevelSetSimilarity(List<Level> levels) {
    if (levels.isEmpty) {
      return {
        'total_levels': 0,
        'unique_levels': 0,
        'similarity_pairs': 0,
        'uniqueness_ratio': 1.0,
        'analysis_summary': 'No levels to analyze',
      };
    }

    int similarityPairs = 0;
    final signatures = <String>{};
    
    // Count unique signatures and similarity pairs
    for (int i = 0; i < levels.length; i++) {
      final signature = generateNormalizedSignature(levels[i]);
      signatures.add(signature);
      
      for (int j = i + 1; j < levels.length; j++) {
        if (areLevelsSimilar(levels[i], levels[j])) {
          similarityPairs++;
        }
      }
    }
    
    final uniqueCount = signatures.length;
    final uniquenessRatio = uniqueCount / levels.length;
    
    String summary;
    if (uniquenessRatio >= 0.95) {
      summary = 'Excellent uniqueness - levels are highly diverse';
    } else if (uniquenessRatio >= 0.8) {
      summary = 'Good uniqueness - most levels are unique';
    } else if (uniquenessRatio >= 0.6) {
      summary = 'Moderate uniqueness - some similar levels detected';
    } else {
      summary = 'Poor uniqueness - many similar levels detected';
    }
    
    return {
      'total_levels': levels.length,
      'unique_levels': uniqueCount,
      'similarity_pairs': similarityPairs,
      'uniqueness_ratio': uniquenessRatio,
      'analysis_summary': summary,
    };
  }

  /// Optimize a level by removing unnecessary empty containers
  /// Returns a new level with the minimum number of containers needed to solve the puzzle
  static Level optimizeEmptyContainers(Level level) {
    // Don't optimize if the level has very few containers
    if (level.containerCount <= 3) {
      return level;
    }

    // Count empty containers
    final emptyContainers = level.initialContainers.where((c) => c.isEmpty).length;
    
    // If there's only one empty container, we can't remove it (needed for solving)
    if (emptyContainers <= 1) {
      return level;
    }

    // Try removing empty containers one by one and check if level is still solvable
    Level optimizedLevel = level;
    
    for (int containersToRemove = 1; containersToRemove < emptyContainers; containersToRemove++) {
      final candidateContainers = <Container>[];
      int emptyContainersAdded = 0;
      
      // Add all non-empty containers first
      for (final container in level.initialContainers) {
        if (!container.isEmpty) {
          candidateContainers.add(container.copyWith(id: candidateContainers.length));
        }
      }
      
      // Add remaining empty containers (keeping at least one)
      final emptyContainersToKeep = emptyContainers - containersToRemove;
      for (final container in level.initialContainers) {
        if (container.isEmpty && emptyContainersAdded < emptyContainersToKeep) {
          candidateContainers.add(container.copyWith(id: candidateContainers.length));
          emptyContainersAdded++;
        }
      }
      
      // Create candidate level
      final candidateLevel = level.copyWith(
        containerCount: candidateContainers.length,
        initialContainers: candidateContainers,
      );
      
      // Check if the candidate level is still theoretically solvable
      if (_isLevelTheoreticallySolvable(candidateLevel)) {
        optimizedLevel = candidateLevel;
      } else {
        // If removing this many containers makes it unsolvable, stop trying
        break;
      }
    }
    
    return optimizedLevel;
  }

  /// Check if a level is theoretically solvable using heuristic analysis
  /// This is a fast check that doesn't require actual solving
  static bool _isLevelTheoreticallySolvable(Level level) {
    // Basic structural checks
    if (!level.isStructurallyValid) {
      return false;
    }
    
    // Must have at least one empty slot for moves
    final totalEmptySlots = level.initialContainers.fold(
      0,
      (sum, container) => sum + container.remainingCapacity,
    );
    if (totalEmptySlots == 0) {
      return false;
    }
    
    // Count colors and their volumes
    final colorVolumes = <LiquidColor, int>{};
    for (final container in level.initialContainers) {
      for (final layer in container.liquidLayers) {
        colorVolumes[layer.color] = (colorVolumes[layer.color] ?? 0) + layer.volume;
      }
    }
    
    // Each color should have exactly one container's worth of liquid
    const standardCapacity = 4; // Assuming standard container capacity
    for (final volume in colorVolumes.values) {
      if (volume != standardCapacity) {
        return false;
      }
    }
    
    // Check if we have enough containers to hold all colors when sorted
    final filledContainersNeeded = colorVolumes.length;
    final totalContainers = level.containerCount;
    
    // We need at least one empty slot for moves, so we need more containers than colors
    if (totalContainers <= filledContainersNeeded) {
      return false;
    }
    
    // Heuristic: Check if colors are not too fragmented
    // If a color is split across too many containers, it might be unsolvable
    final colorFragmentation = <LiquidColor, int>{};
    for (final container in level.initialContainers) {
      final colorsInContainer = <LiquidColor>{};
      for (final layer in container.liquidLayers) {
        colorsInContainer.add(layer.color);
      }
      for (final color in colorsInContainer) {
        colorFragmentation[color] = (colorFragmentation[color] ?? 0) + 1;
      }
    }
    
    // If any color is spread across more than half the containers, it's likely unsolvable
    final maxAllowedFragmentation = (level.containerCount / 2).ceil();
    for (final fragmentation in colorFragmentation.values) {
      if (fragmentation > maxAllowedFragmentation) {
        return false;
      }
    }
    
    return true;
  }
}