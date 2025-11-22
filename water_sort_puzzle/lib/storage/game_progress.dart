import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../models/game_state.dart';

part 'game_progress.g.dart';

/// Represents the player's overall progress in the game
@HiveType(typeId: 0)
@JsonSerializable(explicitToJson: true)
class GameProgress extends HiveObject {
  /// List of level IDs that have been unlocked (stored as list for Hive compatibility)
  @HiveField(0)
  final List<int> unlockedLevelsList;

  /// List of level IDs that have been completed (stored as list for Hive compatibility)
  @HiveField(1)
  final List<int> completedLevelsList;

  /// Current level the player is on (null if no active level)
  @HiveField(2)
  final int? currentLevel;

  /// Saved game state for the current level (null if no saved state)
  @HiveField(3)
  final GameState? savedGameState;

  /// Map of level ID to best score (minimum moves to complete)
  @HiveField(4)
  final Map<int, int> bestScores;

  /// Map of level ID to completion time in seconds
  @HiveField(5)
  final Map<int, int> completionTimes;

  /// Total number of levels completed with perfect score
  @HiveField(6)
  final int perfectCompletions;

  /// Last played timestamp
  @HiveField(7)
  final DateTime? lastPlayed;

  GameProgress({
    List<int>? unlockedLevelsList,
    List<int>? completedLevelsList,
    this.currentLevel,
    this.savedGameState,
    this.bestScores = const {},
    this.completionTimes = const {},
    this.perfectCompletions = 0,
    this.lastPlayed,
  }) : unlockedLevelsList =
           unlockedLevelsList ?? [1], // Level 1 is unlocked by default
       completedLevelsList = completedLevelsList ?? [];

  /// Create from Sets (convenience constructor)
  GameProgress.fromSets({
    Set<int> unlockedLevels = const {1},
    Set<int> completedLevels = const {},
    int? currentLevel,
    GameState? savedGameState,
    Map<int, int> bestScores = const {},
    Map<int, int> completionTimes = const {},
    int perfectCompletions = 0,
    DateTime? lastPlayed,
  }) : this(
         unlockedLevelsList: unlockedLevels.toList(),
         completedLevelsList: completedLevels.toList(),
         currentLevel: currentLevel,
         savedGameState: savedGameState,
         bestScores: bestScores,
         completionTimes: completionTimes,
         perfectCompletions: perfectCompletions,
         lastPlayed: lastPlayed,
       );

  /// Get unlocked levels as a Set
  Set<int> get unlockedLevels => unlockedLevelsList.toSet();

  /// Get completed levels as a Set
  Set<int> get completedLevels => completedLevelsList.toSet();

  /// Create a copy of this progress with optional parameter overrides
  GameProgress copyWith({
    Set<int>? unlockedLevels,
    Set<int>? completedLevels,
    int? currentLevel,
    GameState? savedGameState,
    Map<int, int>? bestScores,
    Map<int, int>? completionTimes,
    int? perfectCompletions,
    DateTime? lastPlayed,
    bool clearSavedGameState = false,
    bool clearCurrentLevel = false,
  }) {
    return GameProgress.fromSets(
      unlockedLevels: unlockedLevels ?? Set.from(this.unlockedLevels),
      completedLevels: completedLevels ?? Set.from(this.completedLevels),
      currentLevel: clearCurrentLevel
          ? null
          : (currentLevel ?? this.currentLevel),
      savedGameState: clearSavedGameState
          ? null
          : (savedGameState ?? this.savedGameState),
      bestScores: bestScores ?? Map.from(this.bestScores),
      completionTimes: completionTimes ?? Map.from(this.completionTimes),
      perfectCompletions: perfectCompletions ?? this.perfectCompletions,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }

  /// Check if a level is unlocked
  bool isLevelUnlocked(int levelId) {
    return unlockedLevels.contains(levelId);
  }

  /// Check if a level is completed
  bool isLevelCompleted(int levelId) {
    return completedLevels.contains(levelId);
  }

  /// Get the best score for a level (minimum moves)
  int? getBestScore(int levelId) {
    return bestScores[levelId];
  }

  /// Get the completion time for a level
  int? getCompletionTime(int levelId) {
    return completionTimes[levelId];
  }

  /// Unlock a level
  GameProgress unlockLevel(int levelId) {
    final newUnlockedLevels = Set<int>.from(unlockedLevels);
    newUnlockedLevels.add(levelId);

    return copyWith(
      unlockedLevels: newUnlockedLevels,
      lastPlayed: DateTime.now(),
    );
  }

  /// Complete a level with the given score and time
  GameProgress completeLevel({
    required int levelId,
    required int moves,
    required int timeInSeconds,
    int? minimumPossibleMoves,
  }) {
    final newCompletedLevels = Set<int>.from(completedLevels);
    newCompletedLevels.add(levelId);

    final newBestScores = Map<int, int>.from(bestScores);
    final currentBest = newBestScores[levelId];
    if (currentBest == null || moves < currentBest) {
      newBestScores[levelId] = moves;
    }

    final newCompletionTimes = Map<int, int>.from(completionTimes);
    final currentBestTime = newCompletionTimes[levelId];
    if (currentBestTime == null || timeInSeconds < currentBestTime) {
      newCompletionTimes[levelId] = timeInSeconds;
    }

    // Check if this is a perfect completion
    int newPerfectCompletions = perfectCompletions;
    if (minimumPossibleMoves != null && moves == minimumPossibleMoves) {
      // Only increment if this is the first perfect completion for this level
      if (!isLevelCompleted(levelId) ||
          getBestScore(levelId) != minimumPossibleMoves) {
        newPerfectCompletions++;
      }
    }

    // Unlock the next level
    final newUnlockedLevels = Set<int>.from(unlockedLevels);
    newUnlockedLevels.add(levelId + 1);

    return copyWith(
      unlockedLevels: newUnlockedLevels,
      completedLevels: newCompletedLevels,
      bestScores: newBestScores,
      completionTimes: newCompletionTimes,
      perfectCompletions: newPerfectCompletions,
      lastPlayed: DateTime.now(),
      clearSavedGameState: true, // Clear saved state when level is completed
      clearCurrentLevel: true,
    );
  }

  /// Save the current game state
  GameProgress saveGameState(GameState gameState) {
    return copyWith(
      currentLevel: gameState.levelId,
      savedGameState: gameState,
      lastPlayed: DateTime.now(),
    );
  }

  /// Clear the saved game state
  GameProgress clearSavedGameState() {
    return copyWith(
      clearSavedGameState: true,
      clearCurrentLevel: true,
      lastPlayed: DateTime.now(),
    );
  }

  /// Get the highest unlocked level
  int get highestUnlockedLevel {
    return unlockedLevels.isEmpty
        ? 1
        : unlockedLevels.reduce((a, b) => a > b ? a : b);
  }

  /// Get the total number of completed levels
  int get totalCompletedLevels {
    return completedLevels.length;
  }

  /// Get the completion percentage for a given total number of levels
  double getCompletionPercentage(int totalLevels) {
    if (totalLevels <= 0) return 0.0;
    return (completedLevels.length / totalLevels) * 100.0;
  }

  /// Check if the player has a saved game in progress
  bool get hasSavedGame {
    return savedGameState != null && currentLevel != null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameProgress &&
        _setEquals(other.unlockedLevels, unlockedLevels) &&
        _setEquals(other.completedLevels, completedLevels) &&
        other.currentLevel == currentLevel &&
        other.savedGameState == savedGameState &&
        _mapEquals(other.bestScores, bestScores) &&
        _mapEquals(other.completionTimes, completionTimes) &&
        other.perfectCompletions == perfectCompletions &&
        other.lastPlayed == lastPlayed;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(unlockedLevels),
    Object.hashAll(completedLevels),
    currentLevel,
    savedGameState,
    Object.hashAll(bestScores.entries),
    Object.hashAll(completionTimes.entries),
    perfectCompletions,
    lastPlayed,
  );

  @override
  String toString() {
    return 'GameProgress(unlocked: ${unlockedLevels.length}, '
        'completed: ${completedLevels.length}, '
        'current: $currentLevel, '
        'hasSaved: $hasSavedGame, '
        'perfect: $perfectCompletions)';
  }

  /// Helper method to compare sets
  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b) && b.containsAll(a);
  }

  /// Helper method to compare maps
  bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  /// JSON serialization
  factory GameProgress.fromJson(Map<String, dynamic> json) =>
      _$GameProgressFromJson(json);

  /// JSON deserialization
  Map<String, dynamic> toJson() => _$GameProgressToJson(this);
}
