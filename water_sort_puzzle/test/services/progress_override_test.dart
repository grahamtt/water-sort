import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_sort_puzzle/services/progress_override.dart';
import 'package:water_sort_puzzle/services/test_mode_manager.dart';
import 'package:water_sort_puzzle/services/test_mode_error_handler.dart';
import 'package:water_sort_puzzle/storage/game_progress.dart';
import 'package:water_sort_puzzle/models/game_state.dart';

void main() {
  group('ProgressOverride', () {
    late GameProgress actualProgress;
    late TestModeManager testModeManager;
    late ProgressOverride progressOverride;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      actualProgress = GameProgress.fromSets(
        unlockedLevels: {1, 2, 3},
        completedLevels: {1, 2},
      );
      testModeManager = TestModeManager(prefs);
      progressOverride = ProgressOverride(actualProgress, testModeManager);
    });

    group('getEffectiveUnlockedLevels', () {
      test('should return all levels (1-1000) when test mode enabled', () async {
        await testModeManager.setTestMode(true);

        final effectiveLevels = progressOverride.getEffectiveUnlockedLevels();

        expect(effectiveLevels.length, equals(1000));
        expect(effectiveLevels.contains(1), isTrue);
        expect(effectiveLevels.contains(500), isTrue);
        expect(effectiveLevels.contains(1000), isTrue);
      });

      test('should return actual unlocked levels when test mode disabled', () async {
        await testModeManager.setTestMode(false);

        final effectiveLevels = progressOverride.getEffectiveUnlockedLevels();

        expect(effectiveLevels, equals({1, 2, 3}));
      });
    });

    group('isLevelUnlocked', () {
      test('should return true for any level when test mode enabled', () async {
        await testModeManager.setTestMode(true);

        expect(progressOverride.isLevelUnlocked(999), isTrue);
        expect(progressOverride.isLevelUnlocked(1), isTrue);
        expect(progressOverride.isLevelUnlocked(100), isTrue);
      });

      test('should respect actual progress when test mode disabled', () async {
        await testModeManager.setTestMode(false);

        expect(progressOverride.isLevelUnlocked(4), isFalse);
        expect(progressOverride.isLevelUnlocked(2), isTrue);
        expect(progressOverride.isLevelUnlocked(1), isTrue);
      });
    });

    group('shouldRecordCompletion', () {
      test('should return true only for legitimately unlocked levels', () {
        expect(progressOverride.shouldRecordCompletion(1), isTrue);
        expect(progressOverride.shouldRecordCompletion(2), isTrue);
        expect(progressOverride.shouldRecordCompletion(3), isTrue);
        expect(progressOverride.shouldRecordCompletion(4), isFalse);
        expect(progressOverride.shouldRecordCompletion(100), isFalse);
      });
    });

    group('completeLevel', () {
      test('should record completion for legitimately unlocked levels', () async {
        final result = await progressOverride.completeLevel(
          levelId: 3,
          moves: 10,
          timeInSeconds: 60,
        );

        expect(result.completedLevels.contains(3), isTrue);
        expect(result.unlockedLevels.contains(4), isTrue); // Next level unlocked
        expect(result.getBestScore(3), equals(10));
      });

      test('should not record completion for illegitimate levels in test mode', () async {
        final result = await progressOverride.completeLevel(
          levelId: 100, // Not legitimately unlocked
          moves: 10,
          timeInSeconds: 60,
        );

        expect(result.completedLevels.contains(100), isFalse);
        expect(result.unlockedLevels.contains(101), isFalse);
        expect(result.getBestScore(100), isNull);
        expect(result, equals(actualProgress)); // Unchanged
      });

      test('should handle perfect completions correctly for legitimate levels', () async {
        final result = await progressOverride.completeLevel(
          levelId: 3,
          moves: 5,
          timeInSeconds: 30,
          minimumPossibleMoves: 5,
        );

        expect(result.perfectCompletions, equals(1));
        expect(result.getBestScore(3), equals(5));
      });

      test('should not increment perfect completions for illegitimate levels', () async {
        final result = await progressOverride.completeLevel(
          levelId: 100,
          moves: 5,
          timeInSeconds: 30,
          minimumPossibleMoves: 5,
        );

        expect(result.perfectCompletions, equals(0)); // Unchanged
      });
    });

    group('actualProgress delegation', () {
      test('should delegate completedLevels to actual progress', () {
        expect(progressOverride.completedLevels, equals({1, 2}));
      });

      test('should delegate isLevelCompleted to actual progress', () {
        expect(progressOverride.isLevelCompleted(1), isTrue);
        expect(progressOverride.isLevelCompleted(2), isTrue);
        expect(progressOverride.isLevelCompleted(3), isFalse);
      });

      test('should delegate getBestScore to actual progress', () {
        final progressWithScores = GameProgress.fromSets(
          unlockedLevels: {1, 2, 3},
          completedLevels: {1, 2},
          bestScores: {1: 8, 2: 12},
        );
        final override = ProgressOverride(progressWithScores, testModeManager);

        expect(override.getBestScore(1), equals(8));
        expect(override.getBestScore(2), equals(12));
        expect(override.getBestScore(3), isNull);
      });

      test('should delegate getCompletionTime to actual progress', () {
        final progressWithTimes = GameProgress.fromSets(
          unlockedLevels: {1, 2, 3},
          completedLevels: {1, 2},
          completionTimes: {1: 45, 2: 67},
        );
        final override = ProgressOverride(progressWithTimes, testModeManager);

        expect(override.getCompletionTime(1), equals(45));
        expect(override.getCompletionTime(2), equals(67));
        expect(override.getCompletionTime(3), isNull);
      });

      test('should delegate totalCompletedLevels to actual progress', () {
        expect(progressOverride.totalCompletedLevels, equals(2));
      });

      test('should delegate getCompletionPercentage to actual progress', () {
        expect(progressOverride.getCompletionPercentage(10), equals(20.0));
      });

      test('should delegate perfectCompletions to actual progress', () {
        final progressWithPerfect = GameProgress.fromSets(
          unlockedLevels: {1, 2, 3},
          completedLevels: {1, 2},
          perfectCompletions: 1,
        );
        final override = ProgressOverride(progressWithPerfect, testModeManager);

        expect(override.perfectCompletions, equals(1));
      });
    });

    group('highestUnlockedLevel', () {
      test('should return 1000 when test mode enabled', () async {
        await testModeManager.setTestMode(true);

        expect(progressOverride.highestUnlockedLevel, equals(1000));
      });

      test('should return actual highest when test mode disabled', () async {
        await testModeManager.setTestMode(false);

        expect(progressOverride.highestUnlockedLevel, equals(3));
      });
    });

    group('unlockLevel', () {
      test('should unlock level normally when test mode disabled', () async {
        await testModeManager.setTestMode(false);

        final result = progressOverride.unlockLevel(4);

        expect(result.unlockedLevels.contains(4), isTrue);
      });

      test('should allow legitimate unlocks in test mode', () async {
        await testModeManager.setTestMode(true);

        // Level 4 would be legitimate (next after highest unlocked level 3)
        final result = progressOverride.unlockLevel(4);

        expect(result.unlockedLevels.contains(4), isTrue);
      });

      test('should not modify actual progress for illegitimate unlocks in test mode', () async {
        await testModeManager.setTestMode(true);

        // Level 100 would not be legitimate
        final result = progressOverride.unlockLevel(100);

        expect(result.unlockedLevels.contains(100), isFalse);
        expect(result, equals(actualProgress)); // Unchanged
      });
    });

    group('saved game state operations', () {
      test('should delegate hasSavedGame to actual progress', () async {
        expect(progressOverride.hasSavedGame, isFalse);

        final progressWithSave = GameProgress.fromSets(
          unlockedLevels: {1, 2, 3},
          currentLevel: 2,
          savedGameState: GameState.initial(
            levelId: 2,
            containers: [],
          ),
        );
        final overrideWithSave = ProgressOverride(progressWithSave, testModeManager);

        expect(overrideWithSave.hasSavedGame, isTrue);
      });

      test('should delegate currentLevel to actual progress', () {
        expect(progressOverride.currentLevel, isNull);
      });

      test('should delegate savedGameState to actual progress', () {
        expect(progressOverride.savedGameState, isNull);
      });

      test('should delegate saveGameState to actual progress', () {
        final gameState = GameState.initial(
          levelId: 3,
          containers: [],
        );

        final result = progressOverride.saveGameState(gameState);

        expect(result.currentLevel, equals(3));
        expect(result.savedGameState, equals(gameState));
      });

      test('should delegate clearSavedGameState to actual progress', () async {
        final progressWithSave = GameProgress.fromSets(
          unlockedLevels: {1, 2, 3},
          currentLevel: 2,
          savedGameState: GameState.initial(
            levelId: 2,
            containers: [],
          ),
        );
        final overrideWithSave = ProgressOverride(progressWithSave, testModeManager);

        final result = overrideWithSave.clearSavedGameState();

        expect(result.currentLevel, isNull);
        expect(result.savedGameState, isNull);
      });
    });

    group('toString', () {
      test('should include test mode status and actual progress', () async {
        await testModeManager.setTestMode(true);

        final result = progressOverride.toString();

        expect(result, contains('testMode: true'));
        expect(result, contains('actualProgress:'));
      });
    });

    group('Progress Corruption Protection', () {
      setUp(() {
        // Clear any existing fallback state before each test
        TestModeErrorHandler.clearFallbackState();
      });

      tearDown(() {
        // Clean up after each test
        TestModeErrorHandler.clearFallbackState();
      });

      test('should handle progress corruption during level completion', () async {
        // Create corrupted progress (completed level not in unlocked set)
        final corruptedProgress = _CorruptedGameProgress();
        final override = ProgressOverride(corruptedProgress, testModeManager);

        // Should handle corruption gracefully
        final result = await override.completeLevel(
          levelId: 1,
          moves: 10,
          timeInSeconds: 60,
        );

        // Should return unchanged progress due to corruption protection
        expect(result, equals(corruptedProgress));
      });

      test('should validate progress integrity before modifications', () async {
        // Create progress with integrity issues
        final problematicProgress = GameProgress.fromSets(
          unlockedLevels: {1, 2, 3, 15}, // Gap in progression
          completedLevels: {1, 2},
        );
        final override = ProgressOverride(problematicProgress, testModeManager);

        // Should detect integrity issues and handle gracefully
        final result = await override.completeLevel(
          levelId: 3,
          moves: 10,
          timeInSeconds: 60,
        );

        // Should return unchanged progress due to integrity protection
        expect(result, equals(problematicProgress));
      });

      test('should protect against completed levels not in unlocked set', () async {
        final invalidProgress = GameProgress.fromSets(
          unlockedLevels: {1, 2, 3},
          completedLevels: {1, 2, 5}, // Level 5 completed but not unlocked
        );
        final override = ProgressOverride(invalidProgress, testModeManager);

        // Should detect this corruption
        final result = await override.completeLevel(
          levelId: 3,
          moves: 10,
          timeInSeconds: 60,
        );

        // Should return unchanged progress due to corruption protection
        expect(result, equals(invalidProgress));
      });

      test('should validate level progression gaps', () async {
        final gappedProgress = GameProgress.fromSets(
          unlockedLevels: {1, 2, 3, 25}, // Large gap from 3 to 25
          completedLevels: {1, 2},
        );
        final override = ProgressOverride(gappedProgress, testModeManager);

        // Should detect suspicious progression gap
        final result = await override.completeLevel(
          levelId: 3,
          moves: 10,
          timeInSeconds: 60,
        );

        // Should return unchanged progress due to integrity protection
        expect(result, equals(gappedProgress));
      });

      test('should validate highest unlocked level consistency', () async {
        final inconsistentProgress = _InconsistentGameProgress();
        final override = ProgressOverride(inconsistentProgress, testModeManager);

        // Should detect inconsistency
        final result = await override.completeLevel(
          levelId: 1,
          moves: 10,
          timeInSeconds: 60,
        );

        // Should return unchanged progress due to integrity protection
        expect(result, equals(inconsistentProgress));
      });

      test('should allow valid progress modifications', () async {
        // Create valid progress
        final validProgress = GameProgress.fromSets(
          unlockedLevels: {1, 2, 3},
          completedLevels: {1, 2},
        );
        final override = ProgressOverride(validProgress, testModeManager);

        // Should allow valid completion
        final result = await override.completeLevel(
          levelId: 3,
          moves: 10,
          timeInSeconds: 60,
        );

        // Should successfully complete the level
        expect(result.completedLevels.contains(3), isTrue);
        expect(result.unlockedLevels.contains(4), isTrue);
      });
    });

    group('edge cases', () {
      test('should handle empty actual progress correctly', () {
        final emptyProgress = GameProgress.fromSets();
        final override = ProgressOverride(emptyProgress, testModeManager);

        expect(override.completedLevels, isEmpty);
        expect(override.shouldRecordCompletion(1), isTrue); // Level 1 is unlocked by default
        expect(override.shouldRecordCompletion(2), isFalse);
      });

      test('should handle large level IDs in test mode', () async {
        await testModeManager.setTestMode(true);

        final effectiveLevels = progressOverride.getEffectiveUnlockedLevels();

        expect(effectiveLevels.contains(999), isTrue);
        expect(effectiveLevels.contains(1000), isTrue);
      });

      test('should preserve actual progress data integrity', () async {
        final originalProgress = actualProgress;
        
        // Perform various operations
        await testModeManager.setTestMode(true);
        progressOverride.getEffectiveUnlockedLevels();
        progressOverride.isLevelUnlocked(999);
        
        // Actual progress should remain unchanged
        expect(progressOverride.actualProgress, equals(originalProgress));
      });
    });
  });
}

/// Mock GameProgress that simulates corruption (completed level not in unlocked set)
class _CorruptedGameProgress extends GameProgress {
  _CorruptedGameProgress() : super.fromSets(
    unlockedLevels: {1, 2, 3},
    completedLevels: {1, 2, 5}, // Level 5 completed but not unlocked - corruption!
  );

  @override
  GameProgress completeLevel({
    required int levelId,
    required int moves,
    required int timeInSeconds,
    int? minimumPossibleMoves,
  }) {
    // Simulate that the completion would fail due to corruption
    throw Exception('Progress corruption detected during completion');
  }
}

/// Mock GameProgress that has inconsistent highest unlocked level
class _InconsistentGameProgress extends GameProgress {
  _InconsistentGameProgress() : super.fromSets(
    unlockedLevels: {1, 2, 3, 5},
    completedLevels: {1, 2},
  );

  @override
  int get highestUnlockedLevel => 10; // Inconsistent with unlocked levels set

  @override
  GameProgress completeLevel({
    required int levelId,
    required int moves,
    required int timeInSeconds,
    int? minimumPossibleMoves,
  }) {
    // Simulate that the completion would fail due to inconsistency
    throw Exception('Progress inconsistency detected');
  }
}