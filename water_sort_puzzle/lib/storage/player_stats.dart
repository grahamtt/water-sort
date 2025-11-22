import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'player_stats.g.dart';

/// Represents detailed player statistics and achievements
@HiveType(typeId: 1)
@JsonSerializable(explicitToJson: true)
class PlayerStats extends HiveObject {
  /// Total number of moves made across all games
  @HiveField(0)
  final int totalMoves;
  
  /// Total number of perfect solutions (minimum moves)
  @HiveField(1)
  final int perfectSolutions;
  
  /// Total play time in seconds
  @HiveField(2)
  final int totalPlayTimeSeconds;
  
  /// Total number of games started
  @HiveField(3)
  final int gamesStarted;
  
  /// Total number of games completed
  @HiveField(4)
  final int gamesCompleted;
  
  /// Total number of undos used
  @HiveField(5)
  final int totalUndos;
  
  /// Longest winning streak
  @HiveField(6)
  final int longestWinStreak;
  
  /// Current winning streak
  @HiveField(7)
  final int currentWinStreak;
  
  /// Best single-level completion time in seconds
  @HiveField(8)
  final int? bestCompletionTime;
  
  /// Level ID where best completion time was achieved
  @HiveField(9)
  final int? bestCompletionTimeLevel;
  
  /// Fastest average moves per level
  @HiveField(10)
  final double? bestAverageMovesPerLevel;
  
  /// Total number of hints used (if hint system is implemented)
  @HiveField(11)
  final int hintsUsed;
  
  /// Date when the player first started playing
  @HiveField(12)
  final DateTime? firstPlayDate;
  
  /// Date of the last game session
  @HiveField(13)
  final DateTime? lastPlayDate;
  
  /// Number of consecutive days played
  @HiveField(14)
  final int consecutiveDaysPlayed;
  
  /// Map of level ID to number of attempts
  @HiveField(15)
  final Map<int, int> levelAttempts;
  
  /// Map of difficulty level to completion count
  @HiveField(16)
  final Map<int, int> difficultyCompletions;
  
  PlayerStats({
    this.totalMoves = 0,
    this.perfectSolutions = 0,
    this.totalPlayTimeSeconds = 0,
    this.gamesStarted = 0,
    this.gamesCompleted = 0,
    this.totalUndos = 0,
    this.longestWinStreak = 0,
    this.currentWinStreak = 0,
    this.bestCompletionTime,
    this.bestCompletionTimeLevel,
    this.bestAverageMovesPerLevel,
    this.hintsUsed = 0,
    this.firstPlayDate,
    this.lastPlayDate,
    this.consecutiveDaysPlayed = 0,
    this.levelAttempts = const {},
    this.difficultyCompletions = const {},
  });
  
  /// Create a copy of this stats with optional parameter overrides
  PlayerStats copyWith({
    int? totalMoves,
    int? perfectSolutions,
    int? totalPlayTimeSeconds,
    int? gamesStarted,
    int? gamesCompleted,
    int? totalUndos,
    int? longestWinStreak,
    int? currentWinStreak,
    int? bestCompletionTime,
    int? bestCompletionTimeLevel,
    double? bestAverageMovesPerLevel,
    int? hintsUsed,
    DateTime? firstPlayDate,
    DateTime? lastPlayDate,
    int? consecutiveDaysPlayed,
    Map<int, int>? levelAttempts,
    Map<int, int>? difficultyCompletions,
  }) {
    return PlayerStats(
      totalMoves: totalMoves ?? this.totalMoves,
      perfectSolutions: perfectSolutions ?? this.perfectSolutions,
      totalPlayTimeSeconds: totalPlayTimeSeconds ?? this.totalPlayTimeSeconds,
      gamesStarted: gamesStarted ?? this.gamesStarted,
      gamesCompleted: gamesCompleted ?? this.gamesCompleted,
      totalUndos: totalUndos ?? this.totalUndos,
      longestWinStreak: longestWinStreak ?? this.longestWinStreak,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      bestCompletionTime: bestCompletionTime ?? this.bestCompletionTime,
      bestCompletionTimeLevel: bestCompletionTimeLevel ?? this.bestCompletionTimeLevel,
      bestAverageMovesPerLevel: bestAverageMovesPerLevel ?? this.bestAverageMovesPerLevel,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      firstPlayDate: firstPlayDate ?? this.firstPlayDate,
      lastPlayDate: lastPlayDate ?? this.lastPlayDate,
      consecutiveDaysPlayed: consecutiveDaysPlayed ?? this.consecutiveDaysPlayed,
      levelAttempts: levelAttempts ?? Map.from(this.levelAttempts),
      difficultyCompletions: difficultyCompletions ?? Map.from(this.difficultyCompletions),
    );
  }
  
  /// Record a new game start
  PlayerStats recordGameStart(int levelId) {
    final now = DateTime.now();
    final newLevelAttempts = Map<int, int>.from(levelAttempts);
    newLevelAttempts[levelId] = (newLevelAttempts[levelId] ?? 0) + 1;
    
    return copyWith(
      gamesStarted: gamesStarted + 1,
      levelAttempts: newLevelAttempts,
      firstPlayDate: firstPlayDate ?? now,
      lastPlayDate: now,
      consecutiveDaysPlayed: _calculateConsecutiveDays(now),
    );
  }
  
  /// Record a game completion
  PlayerStats recordGameCompletion({
    required int levelId,
    required int moves,
    required int timeSeconds,
    required int difficulty,
    required bool isPerfect,
    required int undosUsed,
  }) {
    final now = DateTime.now();
    
    // Update win streak
    final newCurrentStreak = currentWinStreak + 1;
    final newLongestStreak = longestWinStreak > newCurrentStreak 
        ? longestWinStreak 
        : newCurrentStreak;
    
    // Update best completion time
    int? newBestTime = bestCompletionTime;
    int? newBestTimeLevel = bestCompletionTimeLevel;
    if (bestCompletionTime == null || timeSeconds < bestCompletionTime!) {
      newBestTime = timeSeconds;
      newBestTimeLevel = levelId;
    }
    
    // Update difficulty completions
    final newDifficultyCompletions = Map<int, int>.from(difficultyCompletions);
    newDifficultyCompletions[difficulty] = (newDifficultyCompletions[difficulty] ?? 0) + 1;
    
    // Calculate new average moves per level
    final newTotalMoves = totalMoves + moves;
    final newGamesCompleted = gamesCompleted + 1;
    final newAverageMovesPerLevel = newTotalMoves / newGamesCompleted;
    
    // Update best average if this is better
    double? newBestAverageMovesPerLevel = bestAverageMovesPerLevel;
    if (bestAverageMovesPerLevel == null || newAverageMovesPerLevel < bestAverageMovesPerLevel!) {
      newBestAverageMovesPerLevel = newAverageMovesPerLevel;
    }
    
    return copyWith(
      totalMoves: newTotalMoves,
      perfectSolutions: isPerfect ? perfectSolutions + 1 : perfectSolutions,
      totalPlayTimeSeconds: totalPlayTimeSeconds + timeSeconds,
      gamesCompleted: newGamesCompleted,
      totalUndos: totalUndos + undosUsed,
      longestWinStreak: newLongestStreak,
      currentWinStreak: newCurrentStreak,
      bestCompletionTime: newBestTime,
      bestCompletionTimeLevel: newBestTimeLevel,
      bestAverageMovesPerLevel: newBestAverageMovesPerLevel,
      lastPlayDate: now,
      consecutiveDaysPlayed: _calculateConsecutiveDays(now),
      difficultyCompletions: newDifficultyCompletions,
    );
  }
  
  /// Record a game failure (reset win streak)
  PlayerStats recordGameFailure() {
    return copyWith(
      currentWinStreak: 0,
      lastPlayDate: DateTime.now(),
    );
  }
  
  /// Record an undo action
  PlayerStats recordUndo() {
    return copyWith(
      totalUndos: totalUndos + 1,
    );
  }
  
  /// Record a hint usage
  PlayerStats recordHintUsed() {
    return copyWith(
      hintsUsed: hintsUsed + 1,
    );
  }
  
  /// Record additional play time
  PlayerStats recordPlayTime(int additionalSeconds) {
    return copyWith(
      totalPlayTimeSeconds: totalPlayTimeSeconds + additionalSeconds,
      lastPlayDate: DateTime.now(),
    );
  }
  
  /// Get the average moves per completed level
  double get averageMovesPerLevel {
    if (gamesCompleted == 0) return 0.0;
    return totalMoves / gamesCompleted;
  }
  
  /// Get the completion rate (completed / started)
  double get completionRate {
    if (gamesStarted == 0) return 0.0;
    return gamesCompleted / gamesStarted;
  }
  
  /// Get the perfect solution rate
  double get perfectSolutionRate {
    if (gamesCompleted == 0) return 0.0;
    return perfectSolutions / gamesCompleted;
  }
  
  /// Get the average play time per game in seconds
  double get averagePlayTimePerGame {
    if (gamesCompleted == 0) return 0.0;
    return totalPlayTimeSeconds / gamesCompleted;
  }
  
  /// Get the total play time formatted as a human-readable string
  String get formattedTotalPlayTime {
    final hours = totalPlayTimeSeconds ~/ 3600;
    final minutes = (totalPlayTimeSeconds % 3600) ~/ 60;
    final seconds = totalPlayTimeSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
  
  /// Get the number of attempts for a specific level
  int getLevelAttempts(int levelId) {
    return levelAttempts[levelId] ?? 0;
  }
  
  /// Get the number of completions for a specific difficulty
  int getDifficultyCompletions(int difficulty) {
    return difficultyCompletions[difficulty] ?? 0;
  }
  
  /// Check if the player is on a winning streak
  bool get isOnWinStreak {
    return currentWinStreak > 0;
  }
  
  /// Check if the player has played today
  bool get hasPlayedToday {
    if (lastPlayDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastPlay = DateTime(lastPlayDate!.year, lastPlayDate!.month, lastPlayDate!.day);
    return today == lastPlay;
  }
  
  /// Calculate consecutive days played
  int _calculateConsecutiveDays(DateTime currentDate) {
    if (lastPlayDate == null) return 1;
    
    final today = DateTime(currentDate.year, currentDate.month, currentDate.day);
    final lastPlay = DateTime(lastPlayDate!.year, lastPlayDate!.month, lastPlayDate!.day);
    
    final daysDifference = today.difference(lastPlay).inDays;
    
    if (daysDifference == 0) {
      // Same day, keep current streak
      return consecutiveDaysPlayed;
    } else if (daysDifference == 1) {
      // Next day, increment streak
      return consecutiveDaysPlayed + 1;
    } else {
      // Gap in playing, reset streak
      return 1;
    }
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerStats &&
        other.totalMoves == totalMoves &&
        other.perfectSolutions == perfectSolutions &&
        other.totalPlayTimeSeconds == totalPlayTimeSeconds &&
        other.gamesStarted == gamesStarted &&
        other.gamesCompleted == gamesCompleted &&
        other.totalUndos == totalUndos &&
        other.longestWinStreak == longestWinStreak &&
        other.currentWinStreak == currentWinStreak &&
        other.bestCompletionTime == bestCompletionTime &&
        other.bestCompletionTimeLevel == bestCompletionTimeLevel &&
        other.bestAverageMovesPerLevel == bestAverageMovesPerLevel &&
        other.hintsUsed == hintsUsed &&
        other.firstPlayDate == firstPlayDate &&
        other.lastPlayDate == lastPlayDate &&
        other.consecutiveDaysPlayed == consecutiveDaysPlayed &&
        _mapEquals(other.levelAttempts, levelAttempts) &&
        _mapEquals(other.difficultyCompletions, difficultyCompletions);
  }
  
  @override
  int get hashCode => Object.hash(
    totalMoves,
    perfectSolutions,
    totalPlayTimeSeconds,
    gamesStarted,
    gamesCompleted,
    totalUndos,
    longestWinStreak,
    currentWinStreak,
    bestCompletionTime,
    bestCompletionTimeLevel,
    bestAverageMovesPerLevel,
    hintsUsed,
    firstPlayDate,
    lastPlayDate,
    consecutiveDaysPlayed,
    Object.hashAll(levelAttempts.entries),
    Object.hashAll(difficultyCompletions.entries),
  );
  
  @override
  String toString() {
    return 'PlayerStats(games: $gamesCompleted/$gamesStarted, '
           'moves: $totalMoves, perfect: $perfectSolutions, '
           'streak: $currentWinStreak, time: $formattedTotalPlayTime)';
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
  factory PlayerStats.fromJson(Map<String, dynamic> json) =>
      _$PlayerStatsFromJson(json);
  
  /// JSON deserialization
  Map<String, dynamic> toJson() => _$PlayerStatsToJson(this);
}