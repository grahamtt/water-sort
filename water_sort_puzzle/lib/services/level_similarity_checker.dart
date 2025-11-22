import 'dart:math';
import '../models/level.dart';
import '../models/container.dart';
import '../models/liquid_color.dart';
import '../models/liquid_layer.dart';

/// Service for detecting similarity between levels to ensure unique gameplay experiences
class LevelSimilarityChecker {
  /// Threshold for considering two levels as similar (80%)
  static const double similarityThreshold = 0.8;

  /// Maximum attempts to generate a unique level before giving up
  static const int maxGenerationAttempts = 50;

  /// Check if two levels are similar based on structural patterns
  static bool areLevelsSimilar(Level level1, Level level2) {
    // Quick checks first
    if (level1.containerCount != level2.containerCount ||
        level1.colorCount != level2.colorCount) {
      return false;
    }

    // Compare structural patterns independent of specific colors
    final similarity = compareStructuralPatterns(level1, level2);
    return similarity >= similarityThreshold;
  }

  /// Check if a level is similar to any level in a list
  static bool isLevelSimilarToAny(Level newLevel, List<Level> existingLevels) {
    for (final existingLevel in existingLevels) {
      if (areLevelsSimilar(newLevel, existingLevel)) {
        return true;
      }
    }
    return false;
  }

  /// Generate a normalized signature for a level that is color-agnostic
  static String generateNormalizedSignature(Level level) {
    final containers = level.initialContainers;
    final normalizedContainers = normalizeColors(containers);

    // Create signature: "containers:4|pattern:ABAB,BABA,EMPTY,EMPTY"
    return "containers:${containers.length}|pattern:${normalizedContainers.join(',')}";
  }

  /// Compare structural patterns between two levels
  static double compareStructuralPatterns(Level level1, Level level2) {
    // Normalize both levels to color-agnostic patterns
    final pattern1 = _normalizeToPattern(level1);
    final pattern2 = _normalizeToPattern(level2);

    // Calculate similarity score based on multiple factors
    double similarity = 0.0;

    // 1. Container arrangement similarity (40% weight)
    final arrangementSimilarity = _calculateArrangementSimilarity(
      pattern1,
      pattern2,
    );
    similarity += arrangementSimilarity * 0.4;

    // 2. Layer distribution similarity (30% weight)
    final distributionSimilarity = _calculateDistributionSimilarity(
      level1,
      level2,
    );
    similarity += distributionSimilarity * 0.3;

    // 3. Color mixing pattern similarity (30% weight)
    final mixingSimilarity = _calculateMixingPatternSimilarity(
      pattern1,
      pattern2,
    );
    similarity += mixingSimilarity * 0.3;

    return similarity;
  }

  /// Calculate similarity based on container arrangements
  static double _calculateArrangementSimilarity(
    List<String> pattern1,
    List<String> pattern2,
  ) {
    if (pattern1.length != pattern2.length) return 0.0;

    int exactMatches = 0;
    for (int i = 0; i < pattern1.length; i++) {
      if (pattern1[i] == pattern2[i]) {
        exactMatches++;
      }
    }

    return exactMatches / pattern1.length;
  }

  /// Calculate similarity based on layer distribution patterns
  static double _calculateDistributionSimilarity(Level level1, Level level2) {
    // Compare distribution of liquid across containers
    final dist1 = _getLayerDistribution(level1);
    final dist2 = _getLayerDistribution(level2);

    // Calculate similarity using normalized distributions
    return _compareDistributions(dist1, dist2);
  }

  /// Calculate similarity based on color mixing patterns
  static double _calculateMixingPatternSimilarity(
    List<String> pattern1,
    List<String> pattern2,
  ) {
    // Compare complexity patterns (number of segments, mixing levels)
    final complexity1 = _calculateComplexityMetrics(pattern1);
    final complexity2 = _calculateComplexityMetrics(pattern2);

    return _compareComplexityMetrics(complexity1, complexity2);
  }

  /// Get layer distribution statistics for a level
  static Map<String, double> _getLayerDistribution(Level level) {
    final distribution = <String, double>{};
    final totalContainers = level.containerCount;

    // Count empty containers
    int emptyCount = 0;
    int singleColorCount = 0;
    int multiColorCount = 0;

    for (final container in level.initialContainers) {
      if (container.isEmpty) {
        emptyCount++;
      } else if (container.isSorted) {
        singleColorCount++;
      } else {
        multiColorCount++;
      }
    }

    distribution['empty'] = emptyCount / totalContainers;
    distribution['single'] = singleColorCount / totalContainers;
    distribution['mixed'] = multiColorCount / totalContainers;

    return distribution;
  }

  /// Compare two distribution maps
  static double _compareDistributions(
    Map<String, double> dist1,
    Map<String, double> dist2,
  ) {
    final keys = {...dist1.keys, ...dist2.keys};
    double totalDifference = 0.0;

    for (final key in keys) {
      final val1 = dist1[key] ?? 0.0;
      final val2 = dist2[key] ?? 0.0;
      totalDifference += (val1 - val2).abs();
    }

    // Convert difference to similarity (1.0 - normalized difference)
    return max(0.0, 1.0 - (totalDifference / 2.0));
  }

  /// Calculate complexity metrics for a pattern
  static Map<String, double> _calculateComplexityMetrics(List<String> pattern) {
    final metrics = <String, double>{};

    // Count different pattern types
    int emptyContainers = 0;
    int singleColorContainers = 0;
    int multiColorContainers = 0;
    double totalSegments = 0.0;

    for (final containerPattern in pattern) {
      if (containerPattern == 'EMPTY') {
        emptyContainers++;
      } else {
        final segments = countColorSegments(containerPattern);
        totalSegments += segments;

        if (segments == 1) {
          singleColorContainers++;
        } else {
          multiColorContainers++;
        }
      }
    }

    final totalContainers = pattern.length;
    metrics['empty_ratio'] = emptyContainers / totalContainers;
    metrics['single_ratio'] = singleColorContainers / totalContainers;
    metrics['multi_ratio'] = multiColorContainers / totalContainers;
    metrics['avg_segments'] = totalContainers > 0
        ? totalSegments / totalContainers
        : 0.0;

    return metrics;
  }

  /// Count color segments in a container pattern
  static int countColorSegments(String containerPattern) {
    if (containerPattern.isEmpty || containerPattern == 'EMPTY') return 0;

    int segments = 1;
    String? lastChar;

    for (int i = 0; i < containerPattern.length; i++) {
      final char = containerPattern[i];
      if (char.isNotEmpty && char != lastChar && lastChar != null) {
        segments++;
      }
      if (char.isNotEmpty) {
        lastChar = char;
      }
    }

    return segments;
  }

  /// Compare complexity metrics between two patterns
  static double _compareComplexityMetrics(
    Map<String, double> metrics1,
    Map<String, double> metrics2,
  ) {
    final keys = {...metrics1.keys, ...metrics2.keys};
    double totalDifference = 0.0;

    for (final key in keys) {
      final val1 = metrics1[key] ?? 0.0;
      final val2 = metrics2[key] ?? 0.0;
      totalDifference += (val1 - val2).abs();
    }

    // Convert difference to similarity
    return max(0.0, 1.0 - (totalDifference / keys.length));
  }

  /// Convert level to normalized pattern representation
  static List<String> _normalizeToPattern(Level level) {
    return normalizeColors(level.initialContainers);
  }

  /// Convert containers to normalized color patterns
  static List<String> normalizeColors(List<Container> containers) {
    // Map to track color assignments (A, B, C, etc.)
    final colorMap = <LiquidColor, String>{};
    var nextColorLabel = 'A';

    return containers.map((container) {
      if (container.isEmpty) return 'EMPTY';

      final layerPatterns = <String>[];

      for (final layer in container.liquidLayers) {
        // Assign normalized color label if not already assigned
        if (!colorMap.containsKey(layer.color)) {
          colorMap[layer.color] = nextColorLabel;
          nextColorLabel = String.fromCharCode(
            nextColorLabel.codeUnitAt(0) + 1,
          );
        }

        // Add pattern for this layer (repeat label for volume)
        final colorLabel = colorMap[layer.color]!;
        layerPatterns.add(colorLabel * layer.volume);
      }

      return layerPatterns.join('');
    }).toList();
  }

  /// Generate a detailed structural signature for debugging/analysis
  static Map<String, dynamic> generateDetailedSignature(Level level) {
    final normalizedPattern = normalizeColors(level.initialContainers);
    final distribution = _getLayerDistribution(level);
    final complexity = _calculateComplexityMetrics(normalizedPattern);

    return {
      'container_count': level.containerCount,
      'color_count': level.colorCount,
      'normalized_pattern': normalizedPattern,
      'distribution': distribution,
      'complexity': complexity,
      'signature': generateNormalizedSignature(level),
    };
  }

  /// Calculate similarity score between two detailed signatures
  static double calculateDetailedSimilarity(
    Map<String, dynamic> sig1,
    Map<String, dynamic> sig2,
  ) {
    // Quick structural checks
    if (sig1['container_count'] != sig2['container_count'] ||
        sig1['color_count'] != sig2['color_count']) {
      return 0.0;
    }

    final pattern1 = List<String>.from(sig1['normalized_pattern']);
    final pattern2 = List<String>.from(sig2['normalized_pattern']);

    final dist1 = Map<String, double>.from(sig1['distribution']);
    final dist2 = Map<String, double>.from(sig2['distribution']);

    final comp1 = Map<String, double>.from(sig1['complexity']);
    final comp2 = Map<String, double>.from(sig2['complexity']);

    // Calculate weighted similarity
    double similarity = 0.0;
    similarity += _calculateArrangementSimilarity(pattern1, pattern2) * 0.4;
    similarity += _compareDistributions(dist1, dist2) * 0.3;
    similarity += _compareComplexityMetrics(comp1, comp2) * 0.3;

    return similarity;
  }

  /// Validate that a level meets uniqueness requirements against a list
  static bool validateLevelUniqueness(
    Level candidateLevel,
    List<Level> existingLevels, {
    double? customThreshold,
  }) {
    final threshold = customThreshold ?? similarityThreshold;

    for (final existingLevel in existingLevels) {
      final similarity = compareStructuralPatterns(
        candidateLevel,
        existingLevel,
      );
      if (similarity >= threshold) {
        return false; // Too similar to existing level
      }
    }

    return true; // Sufficiently unique
  }

  /// Find the most similar level in a list to a given level
  static ({Level? level, double similarity}) findMostSimilarLevel(
    Level targetLevel,
    List<Level> candidateLevels,
  ) {
    Level? mostSimilar;
    double highestSimilarity = 0.0;

    for (final candidate in candidateLevels) {
      final similarity = compareStructuralPatterns(targetLevel, candidate);
      if (similarity > highestSimilarity) {
        highestSimilarity = similarity;
        mostSimilar = candidate;
      }
    }

    return (level: mostSimilar, similarity: highestSimilarity);
  }

  /// Generate statistics about similarity within a level set
  static Map<String, dynamic> analyzeLevelSetSimilarity(List<Level> levels) {
    if (levels.length < 2) {
      return {
        'total_levels': levels.length,
        'comparisons': 0,
        'avg_similarity': 0.0,
        'max_similarity': 0.0,
        'min_similarity': 0.0,
        'similar_pairs': 0,
      };
    }

    final similarities = <double>[];
    int similarPairs = 0;

    // Compare each pair of levels
    for (int i = 0; i < levels.length; i++) {
      for (int j = i + 1; j < levels.length; j++) {
        final similarity = compareStructuralPatterns(levels[i], levels[j]);
        similarities.add(similarity);

        if (similarity >= similarityThreshold) {
          similarPairs++;
        }
      }
    }

    final avgSimilarity = similarities.isNotEmpty
        ? similarities.reduce((a, b) => a + b) / similarities.length
        : 0.0;

    return {
      'total_levels': levels.length,
      'comparisons': similarities.length,
      'avg_similarity': avgSimilarity,
      'max_similarity': similarities.isNotEmpty
          ? similarities.reduce(max)
          : 0.0,
      'min_similarity': similarities.isNotEmpty
          ? similarities.reduce(min)
          : 0.0,
      'similar_pairs': similarPairs,
      'uniqueness_ratio': similarPairs == 0
          ? 1.0
          : 1.0 - (similarPairs / similarities.length),
    };
  }
}
