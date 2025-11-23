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

  /// Calculate color count based on difficulty
  /// Color count increases with difficulty
  static int _calculateColorCount(int difficulty) {
    if (difficulty <= 2) return 2;
    if (difficulty <= 4) return 3;
    if (difficulty <= 6) return 4;
    if (difficulty <= 8) return 5;
    return 6;
  }

  /// Calculate color count for a specific level ID
  static int calculateColorCountForLevel(int levelId) {
    if (levelId == 1) return 1;
    if (levelId == 2) return 2;
    final difficulty = calculateDifficultyForLevel(levelId);
    return _calculateColorCount(difficulty);
  }

  /// Calculate container capacity based on level ID
  /// Base capacity is 4, increase by 1 every 10 levels
  /// Increases at levels 13, 23, 33, etc. (offset from color/container increases)
  /// to stagger difficulty jumps
  /// Note: Capacities below 4 cause issues with the reverse level generator
  /// producing valid, solvable puzzles that pass validation
  static int calculateContainerCapacity(int levelId) {
    if (levelId <= 2) return 2;
    if (levelId <= 7) return 3;
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
    if (levelId == 1) return 2;
    if (levelId == 2) return 1;

    final difficulty = calculateDifficultyForLevel(levelId);
    final containerCapacity = calculateContainerCapacity(levelId);
    return calculateEmptySlots(difficulty, containerCapacity);
  }
}
