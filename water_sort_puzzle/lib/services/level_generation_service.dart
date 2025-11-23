import 'dart:math';
import '../models/level.dart';
import '../models/container.dart';
import '../models/liquid_layer.dart';
import '../models/liquid_color.dart';
import 'level_generator.dart';
import 'level_similarity_checker.dart';

/// Service for managing level generation with session-level uniqueness tracking
/// 
/// This service ensures that generated levels within a session are sufficiently
/// different from each other to provide varied gameplay experiences.
class LevelGenerationService {
  final LevelGenerator _generator;
  final List<Level> _sessionLevels = [];
  final Random _random = Random();

  /// Maximum attempts to generate a unique level before falling back
  static const int maxUniqueGenerationAttempts = 50;

  /// Minimum number of levels to keep in session history for comparison
  static const int minSessionHistorySize = 10;

  /// Maximum number of levels to keep in session history to prevent memory bloat
  static const int maxSessionHistorySize = 100;

  LevelGenerationService(this._generator);

  /// Generate the next level ensuring it's unique within the current session
  /// 
  /// This method will attempt to generate a level that is sufficiently different
  /// from all previously generated levels in the current session.
  /// 
  /// Parameters:
  /// - [levelId]: Unique identifier for the level
  /// - [difficulty]: Difficulty rating (1-10)
  /// - [containerCount]: Number of containers in the level
  /// - [colorCount]: Number of different colors to use
  /// 
  /// Returns a [Level] that is guaranteed to be different from session levels
  /// or falls back to a regular generated level if uniqueness cannot be achieved.
  Future<Level> generateNextLevel(
    int levelId,
    int difficulty,
    int containerCount,
    int colorCount,
  ) async {
    Level? uniqueLevel;
    int attempts = 0;
    final containerCapacity = _calculateContainerCapacity(levelId);

    // Try to generate a unique level within the attempt limit
    while (uniqueLevel == null && attempts < maxUniqueGenerationAttempts) {
      attempts++;

      try {
        // Generate a candidate level
        final candidate = _generator.generateLevel(
          levelId,
          difficulty,
          containerCount,
          colorCount,
          containerCapacity,
        );

        // Check if it's sufficiently different from session levels
        if (_isLevelUniqueInSession(candidate)) {
          uniqueLevel = candidate;
        }
      } catch (e) {
        // If generation fails, continue to next attempt
        continue;
      }
    }

    // Fallback mechanism: if we can't generate a unique level
    if (uniqueLevel == null) {
      uniqueLevel = await _handleUniquenessFailure(
        levelId,
        difficulty,
        containerCount,
        colorCount,
        attempts,
      );
    }

    // Add the generated level to session history
    _addToSessionHistory(uniqueLevel);

    return uniqueLevel;
  }

  /// Generate multiple levels in sequence, ensuring each is unique
  /// 
  /// This is useful for pre-generating a series of levels while maintaining
  /// uniqueness across the entire series.
  Future<List<Level>> generateLevelSeries(
    int startLevelId,
    int count, {
    int startDifficulty = 1,
    int startContainerCount = 4,
    int startColorCount = 2,
  }) async {
    final levels = <Level>[];

    for (int i = 0; i < count; i++) {
      final levelId = startLevelId + i;
      
      // Progressive difficulty scaling
      final difficulty = _calculateProgressiveDifficulty(i, startDifficulty);
      final containerCount = _calculateContainerCount(difficulty, startContainerCount);
      final colorCount = _calculateColorCount(difficulty, containerCount, startColorCount);

      final level = await generateNextLevel(
        levelId,
        difficulty,
        containerCount,
        colorCount,
      );
      
      levels.add(level);
    }

    return levels;
  }

  /// Check if a level is unique within the current session
  bool _isLevelUniqueInSession(Level candidate) {
    if (_sessionLevels.isEmpty) return true;

    return !LevelSimilarityChecker.isLevelSimilarToAny(
      candidate,
      _sessionLevels,
    );
  }

  /// Handle the case where we cannot generate a unique level
  Future<Level> _handleUniquenessFailure(
    int levelId,
    int difficulty,
    int containerCount,
    int colorCount,
    int attemptsMade,
  ) async {
    // Strategy 1: Clear part of session history and try again
    if (_sessionLevels.length > minSessionHistorySize) {
      _clearOldSessionHistory();
      
      // Try one more time with reduced history
      try {
        final containerCapacity = _calculateContainerCapacity(levelId);
        final candidate = _generator.generateLevel(
          levelId,
          difficulty,
          containerCount,
          colorCount,
          containerCapacity,
        );
        
        if (_isLevelUniqueInSession(candidate)) {
          return candidate;
        }
      } catch (e) {
        // Continue to next strategy
      }
    }

    // Strategy 2: Slightly modify parameters to increase variation
    final modifiedLevel = await _generateWithModifiedParameters(
      levelId,
      difficulty,
      containerCount,
      colorCount,
    );
    
    if (modifiedLevel != null && _isLevelUniqueInSession(modifiedLevel)) {
      return modifiedLevel;
    }

    // Strategy 3: Clear entire session history and generate fresh
    clearSessionHistory();
    
    // Final fallback: generate a regular level without uniqueness constraints
    try {
      final containerCapacity = _calculateContainerCapacity(levelId);
      final fallbackLevel = _generator.generateLevel(
        levelId,
        difficulty,
        containerCount,
        colorCount,
        containerCapacity,
      );
      return fallbackLevel;
    } catch (e) {
      // If even the fallback fails, create a minimal valid level
      return _createMinimalLevel(levelId, difficulty, containerCount, colorCount);
    }
  }

  /// Try generating with slightly modified parameters to increase variation
  Future<Level?> _generateWithModifiedParameters(
    int levelId,
    int difficulty,
    int containerCount,
    int colorCount,
  ) async {
    final variations = [
      // Try with one more container if possible
      if (containerCount < 8) (containerCount + 1, colorCount),
      // Try with one less container if possible
      if (containerCount > 4) (containerCount - 1, max(2, colorCount - 1)),
      // Try with different color count
      if (colorCount < containerCount - 1) (containerCount, colorCount + 1),
      if (colorCount > 2) (containerCount, colorCount - 1),
    ];

    for (final (newContainerCount, newColorCount) in variations) {
      try {
        final containerCapacity = _calculateContainerCapacity(levelId);
        final candidate = _generator.generateLevel(
          levelId,
          difficulty,
          newContainerCount,
          newColorCount,
          containerCapacity,
        );
        
        if (_isLevelUniqueInSession(candidate)) {
          return candidate;
        }
      } catch (e) {
        // Continue to next variation
        continue;
      }
    }

    return null;
  }

  /// Add a level to the session history with size management
  void _addToSessionHistory(Level level) {
    _sessionLevels.add(level);

    // Manage session history size to prevent memory bloat
    if (_sessionLevels.length > maxSessionHistorySize) {
      // Remove oldest levels, keeping the most recent ones
      final removeCount = _sessionLevels.length - maxSessionHistorySize;
      _sessionLevels.removeRange(0, removeCount);
    }
  }

  /// Clear old session history while keeping recent levels
  void _clearOldSessionHistory() {
    if (_sessionLevels.length > minSessionHistorySize) {
      final keepCount = minSessionHistorySize;
      final removeCount = _sessionLevels.length - keepCount;
      _sessionLevels.removeRange(0, removeCount);
    }
  }

  /// Clear the entire session history
  void clearSessionHistory() {
    _sessionLevels.clear();
  }

  /// Get the current session history (read-only)
  List<Level> get sessionHistory => List.unmodifiable(_sessionLevels);

  /// Get the number of levels in current session
  int get sessionLevelCount => _sessionLevels.length;

  /// Check if the session history is at capacity
  bool get isSessionHistoryFull => _sessionLevels.length >= maxSessionHistorySize;

  /// Get statistics about the current session
  Map<String, dynamic> getSessionStatistics() {
    if (_sessionLevels.isEmpty) {
      return {
        'total_levels': 0,
        'avg_difficulty': 0.0,
        'avg_containers': 0.0,
        'avg_colors': 0.0,
        'difficulty_range': [0, 0],
        'container_range': [0, 0],
        'color_range': [0, 0],
        'uniqueness_analysis': {},
      };
    }

    final difficulties = _sessionLevels.map((l) => l.difficulty).toList();
    final containers = _sessionLevels.map((l) => l.containerCount).toList();
    final colors = _sessionLevels.map((l) => l.colorCount).toList();

    return {
      'total_levels': _sessionLevels.length,
      'avg_difficulty': difficulties.reduce((a, b) => a + b) / difficulties.length,
      'avg_containers': containers.reduce((a, b) => a + b) / containers.length,
      'avg_colors': colors.reduce((a, b) => a + b) / colors.length,
      'difficulty_range': [difficulties.reduce(min), difficulties.reduce(max)],
      'container_range': [containers.reduce(min), containers.reduce(max)],
      'color_range': [colors.reduce(min), colors.reduce(max)],
      'uniqueness_analysis': LevelSimilarityChecker.analyzeLevelSetSimilarity(_sessionLevels),
    };
  }

  /// Calculate progressive difficulty for level series
  int _calculateProgressiveDifficulty(int levelIndex, int startDifficulty) {
    // Gradually increase difficulty every few levels
    final difficultyIncrease = levelIndex ~/ 5; // Increase every 5 levels
    return min(10, startDifficulty + difficultyIncrease);
  }

  /// Calculate container count based on difficulty
  int _calculateContainerCount(int difficulty, int baseContainerCount) {
    // Increase containers as difficulty increases, but cap at reasonable limits
    if (difficulty <= 2) return max(4, baseContainerCount);
    if (difficulty <= 4) return max(5, baseContainerCount);
    if (difficulty <= 6) return max(6, baseContainerCount);
    if (difficulty <= 8) return max(7, baseContainerCount);
    return max(8, baseContainerCount);
  }

  /// Calculate color count based on difficulty and container count
  int _calculateColorCount(int difficulty, int containerCount, int baseColorCount) {
    // Ensure we have at least one empty container for solving
    final maxColors = containerCount - 1;
    
    if (difficulty <= 2) return min(max(2, baseColorCount), maxColors);
    if (difficulty <= 4) return min(max(3, baseColorCount), maxColors);
    if (difficulty <= 6) return min(max(4, baseColorCount), maxColors);
    if (difficulty <= 8) return min(max(5, baseColorCount), maxColors);
    return min(max(6, baseColorCount), maxColors);
  }

  /// Calculate container capacity based on level ID
  int _calculateContainerCapacity(int levelId) {
    // Base capacity is 4, increase by 1 every 10 levels
    return 4 + ((levelId - 1) ~/ 10);
  }

  /// Validate that the service is working correctly
  bool validateService() {
    try {
      // Test basic generation
      final testLevel = _generator.generateLevel(999, 1, 4, 2, 4);
      if (testLevel.id != 999) return false;

      // Test uniqueness checking
      final isUnique = _isLevelUniqueInSession(testLevel);
      if (!isUnique && _sessionLevels.isEmpty) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reset the service to initial state
  void reset() {
    clearSessionHistory();
  }

  /// Create a minimal valid level as absolute fallback
  Level _createMinimalLevel(int levelId, int difficulty, int containerCount, int colorCount) {
    // Import required models
    final containers = <Container>[];
    final containerCapacity = _calculateContainerCapacity(levelId);
    
    // Create containers - first few with simple liquid patterns, rest empty
    for (int i = 0; i < containerCount; i++) {
      final layers = <LiquidLayer>[];
      
      if (i < colorCount) {
        // Create a simple single-color container
        final color = LiquidColor.values[i % LiquidColor.values.length];
        layers.add(LiquidLayer(color: color, volume: containerCapacity));
      }
      // Remaining containers are empty
      
      containers.add(Container(
        id: i,
        capacity: containerCapacity,
        liquidLayers: layers,
      ));
    }
    
    return Level(
      id: levelId,
      difficulty: difficulty,
      containerCount: containerCount,
      colorCount: colorCount,
      initialContainers: containers,
      tags: ['fallback'],
    );
  }

  /// Get a summary of generation attempts and success rates
  Map<String, dynamic> getGenerationMetrics() {
    // This could be enhanced to track actual metrics over time
    // For now, return basic information about current state
    return {
      'session_levels': _sessionLevels.length,
      'max_session_size': maxSessionHistorySize,
      'min_session_size': minSessionHistorySize,
      'max_attempts': maxUniqueGenerationAttempts,
      'service_status': validateService() ? 'healthy' : 'error',
    };
  }
}