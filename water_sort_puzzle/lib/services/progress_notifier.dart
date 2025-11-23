import 'package:flutter/foundation.dart';
import '../storage/game_progress.dart';
import 'progress_override.dart';
import 'test_mode_manager.dart';

/// A ChangeNotifier wrapper around ProgressOverride that notifies listeners when progress changes
class ProgressNotifier extends ChangeNotifier {
  ProgressOverride _progressOverride;

  ProgressNotifier(this._progressOverride);

  /// Get the current ProgressOverride instance
  ProgressOverride get progressOverride => _progressOverride;

  /// Update the progress and notify listeners
  void updateProgress(GameProgress newProgress, TestModeManager testModeManager) {
    _progressOverride = ProgressOverride(newProgress, testModeManager);
    notifyListeners();
  }

  /// Delegate methods to ProgressOverride for convenience
  
  Set<int> getEffectiveUnlockedLevels() => _progressOverride.getEffectiveUnlockedLevels();
  
  Set<int> get completedLevels => _progressOverride.completedLevels;
  
  bool isLevelUnlocked(int levelId) => _progressOverride.isLevelUnlocked(levelId);
  
  bool shouldRecordCompletion(int levelId) => _progressOverride.shouldRecordCompletion(levelId);
  
  Future<GameProgress> completeLevel({
    required int levelId,
    required int moves,
    required int timeInSeconds,
    int? minimumPossibleMoves,
  }) => _progressOverride.completeLevel(
    levelId: levelId,
    moves: moves,
    timeInSeconds: timeInSeconds,
    minimumPossibleMoves: minimumPossibleMoves,
  );
  
  GameProgress get actualProgress => _progressOverride.actualProgress;
  
  bool isLevelCompleted(int levelId) => _progressOverride.isLevelCompleted(levelId);
  
  int? getBestScore(int levelId) => _progressOverride.getBestScore(levelId);
  
  int? getCompletionTime(int levelId) => _progressOverride.getCompletionTime(levelId);
  
  int get highestUnlockedLevel => _progressOverride.highestUnlockedLevel;
  
  int get totalCompletedLevels => _progressOverride.totalCompletedLevels;
  
  double getCompletionPercentage(int totalLevels) => _progressOverride.getCompletionPercentage(totalLevels);
  
  bool get hasSavedGame => _progressOverride.hasSavedGame;
  
  int? get currentLevel => _progressOverride.currentLevel;
  
  int get perfectCompletions => _progressOverride.perfectCompletions;
  
  DateTime? get lastPlayed => _progressOverride.lastPlayed;
}
