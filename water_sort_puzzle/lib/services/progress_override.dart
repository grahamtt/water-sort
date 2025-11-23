import '../storage/game_progress.dart';
import '../models/game_state.dart';
import 'test_mode_manager.dart';
import 'test_mode_error_handler.dart';

/// Wraps GameProgress to provide test mode functionality while preserving actual progress
class ProgressOverride {
  final GameProgress _actualProgress;
  final TestModeManager _testModeManager;

  ProgressOverride(this._actualProgress, this._testModeManager);

  /// Get effective unlocked levels considering test mode
  Set<int> getEffectiveUnlockedLevels() {
    if (_testModeManager.isTestModeEnabled) {
      // Return expanded set for test mode (levels 1-1000)
      return Set<int>.from(List.generate(1000, (index) => index + 1));
    }
    return _actualProgress.unlockedLevels;
  }

  /// Get completed levels (always returns actual progress)
  Set<int> get completedLevels => _actualProgress.completedLevels;

  /// Check if level is unlocked considering test mode state
  bool isLevelUnlocked(int levelId) {
    return _testModeManager.isLevelAccessible(levelId, _actualProgress.unlockedLevels);
  }

  /// Determine if level completion should be recorded in actual progress
  bool shouldRecordCompletion(int levelId) {
    // Only record completion if level was legitimately unlocked
    return _actualProgress.unlockedLevels.contains(levelId);
  }

  /// Complete a level (only affects actual progress if legitimately unlocked)
  Future<GameProgress> completeLevel({
    required int levelId,
    required int moves,
    required int timeInSeconds,
    int? minimumPossibleMoves,
  }) async {
    try {
      // Validate progress integrity before modification
      await _validateProgressIntegrity();

      // Only mark as completed if it was legitimately unlocked
      if (shouldRecordCompletion(levelId)) {
        return _actualProgress.completeLevel(
          levelId: levelId,
          moves: moves,
          timeInSeconds: timeInSeconds,
          minimumPossibleMoves: minimumPossibleMoves,
        );
      }
      
      // In test mode, don't modify actual progress for illegitimate completions
      // Return the unchanged actual progress
      return _actualProgress;
    } catch (e) {
      // Handle potential progress corruption
      final exception = TestModeException(
        TestModeErrorType.progressCorruption,
        'Progress corruption detected during level completion: levelId=$levelId, error=$e',
        e,
      );

      final recoveryResult = await TestModeErrorHandler.handleTestModeError(
        exception,
        context: {
          'levelId': levelId,
          'moves': moves,
          'timeInSeconds': timeInSeconds,
          'operation': 'completeLevel',
        },
      );

      if (recoveryResult.success) {
        // Progress protection activated, return unchanged progress
        return _actualProgress;
      } else {
        // Recovery failed, rethrow
        throw exception;
      }
    }
  }

  /// Get the actual progress (for persistence and other operations)
  GameProgress get actualProgress => _actualProgress;

  /// Check if a level is completed (delegates to actual progress)
  bool isLevelCompleted(int levelId) {
    return _actualProgress.isLevelCompleted(levelId);
  }

  /// Get the best score for a level (delegates to actual progress)
  int? getBestScore(int levelId) {
    return _actualProgress.getBestScore(levelId);
  }

  /// Get the completion time for a level (delegates to actual progress)
  int? getCompletionTime(int levelId) {
    return _actualProgress.getCompletionTime(levelId);
  }

  /// Get the highest unlocked level considering test mode
  int get highestUnlockedLevel {
    if (_testModeManager.isTestModeEnabled) {
      return 1000; // Max level in test mode
    }
    return _actualProgress.highestUnlockedLevel;
  }

  /// Get the total number of completed levels (actual progress only)
  int get totalCompletedLevels => _actualProgress.totalCompletedLevels;

  /// Get completion percentage based on actual progress
  double getCompletionPercentage(int totalLevels) {
    return _actualProgress.getCompletionPercentage(totalLevels);
  }

  /// Check if the player has a saved game in progress
  bool get hasSavedGame => _actualProgress.hasSavedGame;

  /// Get current level from actual progress
  int? get currentLevel => _actualProgress.currentLevel;

  /// Get saved game state from actual progress
  GameState? get savedGameState => _actualProgress.savedGameState;

  /// Save game state (delegates to actual progress)
  GameProgress saveGameState(GameState gameState) {
    return _actualProgress.saveGameState(gameState);
  }

  /// Clear saved game state (delegates to actual progress)
  GameProgress clearSavedGameState() {
    return _actualProgress.clearSavedGameState();
  }

  /// Unlock a level (only affects actual progress if not in test mode or legitimately earned)
  GameProgress unlockLevel(int levelId) {
    // In test mode, don't modify actual progress for test unlocks
    // Only unlock if it would be a legitimate unlock
    if (_testModeManager.isTestModeEnabled) {
      // Check if this would be a legitimate unlock based on actual progress
      final actualHighest = _actualProgress.highestUnlockedLevel;
      if (levelId <= actualHighest + 1) {
        // This is a legitimate unlock, allow it
        return _actualProgress.unlockLevel(levelId);
      }
      // Otherwise, don't modify actual progress
      return _actualProgress;
    }
    
    // Normal mode, allow unlock
    return _actualProgress.unlockLevel(levelId);
  }

  /// Get perfect completions count (from actual progress)
  int get perfectCompletions => _actualProgress.perfectCompletions;

  /// Get last played timestamp (from actual progress)
  DateTime? get lastPlayed => _actualProgress.lastPlayed;

  /// Validate progress integrity to detect potential corruption
  Future<void> _validateProgressIntegrity() async {
    try {
      // Check for basic integrity issues
      final unlockedLevels = _actualProgress.unlockedLevels;
      final completedLevels = _actualProgress.completedLevels;

      // Validate that completed levels are subset of unlocked levels
      if (!completedLevels.every((level) => unlockedLevels.contains(level))) {
        throw Exception('Completed levels contain levels that are not unlocked');
      }

      // Validate level progression (no gaps in unlocked levels starting from 1)
      if (unlockedLevels.isNotEmpty) {
        final sortedLevels = unlockedLevels.toList()..sort();
        if (sortedLevels.first != 1) {
          throw Exception('First unlocked level is not level 1');
        }
        
        // Check for reasonable progression (no huge gaps)
        for (int i = 1; i < sortedLevels.length; i++) {
          final gap = sortedLevels[i] - sortedLevels[i - 1];
          if (gap > 10) {
            throw Exception('Suspicious gap in level progression: ${sortedLevels[i - 1]} to ${sortedLevels[i]}');
          }
        }
      }

      // Validate highest unlocked level consistency
      final highestUnlocked = _actualProgress.highestUnlockedLevel;
      if (unlockedLevels.isNotEmpty && !unlockedLevels.contains(highestUnlocked)) {
        throw Exception('Highest unlocked level ($highestUnlocked) not in unlocked levels set');
      }

    } catch (e) {
      // Progress integrity validation failed
      throw Exception('Progress integrity validation failed: $e');
    }
  }

  @override
  String toString() {
    return 'ProgressOverride(testMode: ${_testModeManager.isTestModeEnabled}, '
        'actualProgress: $_actualProgress)';
  }
}