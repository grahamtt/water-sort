import '../models/level.dart';

/// Represents the player's progress through levels
class LevelProgress {
  /// Set of level IDs that have been unlocked
  final Set<int> unlockedLevels;
  
  /// Set of level IDs that have been completed
  final Set<int> completedLevels;
  
  /// Map of level ID to best score (fewest moves)
  final Map<int, int> bestScores;
  
  /// Map of level ID to completion time in milliseconds
  final Map<int, int> completionTimes;
  
  /// Current level the player is on (null if no active level)
  final int? currentLevel;
  
  const LevelProgress({
    this.unlockedLevels = const {},
    this.completedLevels = const {},
    this.bestScores = const {},
    this.completionTimes = const {},
    this.currentLevel,
  });
  
  /// Create initial progress with only level 1 unlocked
  factory LevelProgress.initial() {
    return const LevelProgress(
      unlockedLevels: {1},
      currentLevel: 1,
    );
  }
  
  /// Create a copy with optional parameter overrides
  LevelProgress copyWith({
    Set<int>? unlockedLevels,
    Set<int>? completedLevels,
    Map<int, int>? bestScores,
    Map<int, int>? completionTimes,
    int? currentLevel,
  }) {
    return LevelProgress(
      unlockedLevels: unlockedLevels ?? Set.from(this.unlockedLevels),
      completedLevels: completedLevels ?? Set.from(this.completedLevels),
      bestScores: bestScores ?? Map.from(this.bestScores),
      completionTimes: completionTimes ?? Map.from(this.completionTimes),
      currentLevel: currentLevel ?? this.currentLevel,
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
  
  /// Get the best score for a level (null if not completed)
  int? getBestScore(int levelId) {
    return bestScores[levelId];
  }
  
  /// Get the completion time for a level (null if not completed)
  int? getCompletionTime(int levelId) {
    return completionTimes[levelId];
  }
  
  /// Get the highest unlocked level
  int get highestUnlockedLevel {
    return unlockedLevels.isEmpty ? 0 : unlockedLevels.reduce((a, b) => a > b ? a : b);
  }
  
  /// Get the total number of completed levels
  int get totalCompletedLevels {
    return completedLevels.length;
  }
  
  /// Calculate completion percentage for available levels
  double getCompletionPercentage(int totalAvailableLevels) {
    if (totalAvailableLevels == 0) return 0.0;
    return completedLevels.length / totalAvailableLevels;
  }
}

/// Manages level progression and unlocking logic
class LevelProgressionManager {
  /// Current player progress
  LevelProgress _progress;
  
  /// Available levels in the game
  final Map<int, Level> _availableLevels;
  
  LevelProgressionManager({
    LevelProgress? initialProgress,
    Map<int, Level>? availableLevels,
  }) : _progress = initialProgress ?? LevelProgress.initial(),
       _availableLevels = availableLevels ?? {};
  
  /// Get current progress
  LevelProgress get progress => _progress;
  
  /// Get available levels
  Map<int, Level> get availableLevels => Map.unmodifiable(_availableLevels);
  
  /// Add a level to the available levels
  void addLevel(Level level) {
    _availableLevels[level.id] = level;
  }
  
  /// Add multiple levels
  void addLevels(List<Level> levels) {
    for (final level in levels) {
      addLevel(level);
    }
  }
  
  /// Get a specific level by ID
  Level? getLevel(int levelId) {
    return _availableLevels[levelId];
  }
  
  /// Get all unlocked levels
  List<Level> getUnlockedLevels() {
    return _progress.unlockedLevels
        .where((id) => _availableLevels.containsKey(id))
        .map((id) => _availableLevels[id]!)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }
  
  /// Get all completed levels
  List<Level> getCompletedLevels() {
    return _progress.completedLevels
        .where((id) => _availableLevels.containsKey(id))
        .map((id) => _availableLevels[id]!)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }
  
  /// Get the next level to play (first unlocked but not completed)
  Level? getNextLevel() {
    final unlockedLevels = getUnlockedLevels();
    
    for (final level in unlockedLevels) {
      if (!_progress.isLevelCompleted(level.id)) {
        return level;
      }
    }
    
    return null;
  }
  
  /// Complete a level and unlock the next one
  LevelProgress completeLevel(int levelId, int moveCount, int timeInMilliseconds) {
    if (!_progress.isLevelUnlocked(levelId)) {
      throw ArgumentError('Cannot complete level $levelId: level is not unlocked');
    }
    
    final newCompletedLevels = Set<int>.from(_progress.completedLevels);
    final newUnlockedLevels = Set<int>.from(_progress.unlockedLevels);
    final newBestScores = Map<int, int>.from(_progress.bestScores);
    final newCompletionTimes = Map<int, int>.from(_progress.completionTimes);
    
    // Mark level as completed
    newCompletedLevels.add(levelId);
    
    // Update best score if this is better
    final currentBest = newBestScores[levelId];
    if (currentBest == null || moveCount < currentBest) {
      newBestScores[levelId] = moveCount;
    }
    
    // Update completion time if this is better
    final currentTime = newCompletionTimes[levelId];
    if (currentTime == null || timeInMilliseconds < currentTime) {
      newCompletionTimes[levelId] = timeInMilliseconds;
    }
    
    // Unlock next level(s) based on completion rules
    final levelsToUnlock = _calculateLevelsToUnlock(levelId, newCompletedLevels);
    newUnlockedLevels.addAll(levelsToUnlock);
    
    // Update current level to next available level
    final nextLevel = _findNextLevel(newUnlockedLevels, newCompletedLevels);
    
    _progress = _progress.copyWith(
      unlockedLevels: newUnlockedLevels,
      completedLevels: newCompletedLevels,
      bestScores: newBestScores,
      completionTimes: newCompletionTimes,
      currentLevel: nextLevel,
    );
    
    return _progress;
  }
  
  /// Unlock a specific level (for testing or special unlocks)
  LevelProgress unlockLevel(int levelId) {
    if (!_availableLevels.containsKey(levelId)) {
      throw ArgumentError('Cannot unlock level $levelId: level does not exist');
    }
    
    final newUnlockedLevels = Set<int>.from(_progress.unlockedLevels);
    newUnlockedLevels.add(levelId);
    
    _progress = _progress.copyWith(unlockedLevels: newUnlockedLevels);
    return _progress;
  }
  
  /// Set the current level
  LevelProgress setCurrentLevel(int levelId) {
    if (!_progress.isLevelUnlocked(levelId)) {
      throw ArgumentError('Cannot set current level to $levelId: level is not unlocked');
    }
    
    _progress = _progress.copyWith(currentLevel: levelId);
    return _progress;
  }
  
  /// Reset progress to initial state
  LevelProgress resetProgress() {
    _progress = LevelProgress.initial();
    return _progress;
  }
  
  /// Update progress (for loading saved progress)
  void updateProgress(LevelProgress newProgress) {
    _progress = newProgress;
  }
  
  /// Calculate which levels should be unlocked after completing a level
  Set<int> _calculateLevelsToUnlock(int completedLevelId, Set<int> allCompletedLevels) {
    final levelsToUnlock = <int>{};
    
    // Standard progression: unlock next level
    final nextLevelId = completedLevelId + 1;
    if (_availableLevels.containsKey(nextLevelId)) {
      levelsToUnlock.add(nextLevelId);
    }
    
    // Special unlock rules based on milestones
    final completedCount = allCompletedLevels.length;
    
    // Unlock bonus levels at certain milestones
    if (completedCount == 10 && _availableLevels.containsKey(101)) {
      levelsToUnlock.add(101); // First bonus level
    }
    
    if (completedCount == 25 && _availableLevels.containsKey(102)) {
      levelsToUnlock.add(102); // Second bonus level
    }
    
    if (completedCount == 50 && _availableLevels.containsKey(103)) {
      levelsToUnlock.add(103); // Third bonus level
    }
    
    // Unlock challenge levels after completing tutorial
    if (completedLevelId == 5) {
      // Unlock first challenge level after tutorial
      for (int i = 201; i <= 205; i++) {
        if (_availableLevels.containsKey(i)) {
          levelsToUnlock.add(i);
        }
      }
    }
    
    return levelsToUnlock;
  }
  
  /// Find the next level to play
  int? _findNextLevel(Set<int> unlockedLevels, Set<int> completedLevels) {
    // Find the lowest numbered unlocked level that hasn't been completed
    final availableToPlay = unlockedLevels
        .where((id) => !completedLevels.contains(id))
        .toList()
      ..sort();
    
    return availableToPlay.isEmpty ? null : availableToPlay.first;
  }
  
  /// Get statistics about the player's progress
  Map<String, dynamic> getProgressStatistics() {
    final stats = <String, dynamic>{};
    
    stats['totalLevelsAvailable'] = _availableLevels.length;
    stats['totalLevelsUnlocked'] = _progress.unlockedLevels.length;
    stats['totalLevelsCompleted'] = _progress.completedLevels.length;
    stats['completionPercentage'] = _progress.getCompletionPercentage(_availableLevels.length);
    stats['highestUnlockedLevel'] = _progress.highestUnlockedLevel;
    stats['currentLevel'] = _progress.currentLevel;
    
    // Calculate average moves per completed level
    if (_progress.completedLevels.isNotEmpty) {
      final totalMoves = _progress.bestScores.values.fold(0, (sum, moves) => sum + moves);
      stats['averageMovesPerLevel'] = totalMoves / _progress.completedLevels.length;
    } else {
      stats['averageMovesPerLevel'] = 0.0;
    }
    
    // Calculate total play time
    final totalTime = _progress.completionTimes.values.fold(0, (sum, time) => sum + time);
    stats['totalPlayTimeMs'] = totalTime;
    
    return stats;
  }
}