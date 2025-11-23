import 'dart:math';

/// Shared utility class for calculating level parameters
/// Used by level generators and game state providers to ensure consistency
class LevelParameters {
  /// Calculate progressive difficulty for level series
  /// Gradually increases difficulty every 5 levels
  static int calculateProgressiveDifficulty(int levelIndex, int startDifficulty) {
    final difficultyIncrease = levelIndex ~/ 5;
    return min(10, startDifficulty + difficultyIncrease);
  }

  /// Calculate difficulty based on level ID
  /// Progressive difficulty: start at 1, increase every 5 levels
  static int calculateDifficultyForLevel(int levelId) {
    return ((levelId - 1) ~/ 5) + 1;
  }

  /// Calculate container count based on difficulty
  /// Increases every 5 levels in lockstep with color count
  static int calculateContainerCount(int difficulty) {
    if (difficulty <= 2) return 4;
    if (difficulty <= 4) return 5;
    if (difficulty <= 6) return 6;
    if (difficulty <= 8) return 7;
    return 8;
  }

  /// Calculate container count for a specific level ID
  static int calculateContainerCountForLevel(int levelId) {
    final difficulty = calculateDifficultyForLevel(levelId);
    return calculateContainerCount(difficulty);
  }

  /// Calculate color count based on difficulty and container count
  /// Ensures at least one empty container for solving
  static int calculateColorCount(int difficulty, int containerCount) {
    final maxColors = containerCount - 1;

    if (difficulty <= 2) return min(2, maxColors);
    if (difficulty <= 4) return min(3, maxColors);
    if (difficulty <= 6) return min(4, maxColors);
    if (difficulty <= 8) return min(5, maxColors);
    return min(6, maxColors);
  }

  /// Calculate color count for a specific level ID
  static int calculateColorCountForLevel(int levelId) {
    final difficulty = calculateDifficultyForLevel(levelId);
    final containerCount = calculateContainerCountForLevel(levelId);
    final maxColors = containerCount - 1;

    if (difficulty <= 2) return 2.clamp(2, maxColors);
    if (difficulty <= 4) return 3.clamp(2, maxColors);
    if (difficulty <= 6) return 4.clamp(2, maxColors);
    if (difficulty <= 8) return 5.clamp(2, maxColors);
    return 6.clamp(2, maxColors);
  }

  /// Calculate container capacity based on level ID
  /// Base capacity is 4, increase by 1 every 10 levels
  /// Increases at levels 13, 23, 33, etc. (offset from color/container increases)
  /// to stagger difficulty jumps
  /// Note: Capacities below 4 cause issues with the reverse level generator
  /// producing valid, solvable puzzles that pass validation
  static int calculateContainerCapacity(int levelId) {
    if (levelId <= 15) return 4;
    if (levelId <= 25) return 5;
    if (levelId <= 35) return 6;
    if (levelId <= 45) return 7;
    return 8;
  }

  /// Calculate container capacity for a level index in a series
  /// Used when generating level series starting from a specific ID
  static int calculateContainerCapacityForSeries(int startId, int levelIndex) {
    final levelId = startId + levelIndex;
    return calculateContainerCapacity(levelId);
  }

  /// Calculate the number of empty slots based on difficulty and container capacity
  /// Returns the total number of empty slots needed for the level
  /// Easy levels have more empty slots, hard levels have fewer
  static int calculateEmptySlots(int difficulty, int containerCapacity) {
    if (difficulty <= 3) {
      // Easy levels: 2 full containers worth of empty slots
      return containerCapacity * 2;
    } else if (difficulty <= 6) {
      // Medium levels: 1.5 containers worth of empty slots
      return (containerCapacity * 1.5).round();
    } else {
      // Hard levels: 1 container worth of empty slots
      return containerCapacity;
    }
  }

  /// Calculate empty slots for a specific level ID
  static int calculateEmptySlotsForLevel(int levelId) {
    final difficulty = calculateDifficultyForLevel(levelId);
    final containerCapacity = calculateContainerCapacity(levelId);
    return calculateEmptySlots(difficulty, containerCapacity);
  }
}
