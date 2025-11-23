import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/services/test_mode_manager.dart';
import '../../lib/services/progress_override.dart';
import '../../lib/storage/game_progress.dart';
import '../../lib/models/level.dart';
import '../../lib/models/container.dart' as game_container;
import '../../lib/models/liquid_layer.dart';
import '../../lib/models/liquid_color.dart';

void main() {
  group('GameScreen Test Mode Integration', () {
    late TestModeManager testModeManager;
    late GameProgress gameProgress;
    late ProgressOverride progressOverride;

    setUp(() async {
      // Use in-memory SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      testModeManager = TestModeManager(prefs);
      
      // Create a real GameProgress instance for testing
      gameProgress = GameProgress.fromSets(
        unlockedLevels: {1, 2, 3},
        completedLevels: {1, 2},
      );
      
      progressOverride = ProgressOverride(gameProgress, testModeManager);
    });

    test('should correctly identify legitimate vs illegitimate completions', () async {
      // Setup test mode enabled
      await testModeManager.setTestMode(true);

      // Test legitimate completion (level is unlocked)
      expect(progressOverride.shouldRecordCompletion(3), true);
      
      // Test illegitimate completion (level is not unlocked)
      expect(progressOverride.shouldRecordCompletion(100), false);
    });

    test('should provide unrestricted level access in test mode', () async {
      // Enable test mode
      await testModeManager.setTestMode(true);

      // Test that high levels are accessible in test mode
      expect(progressOverride.isLevelUnlocked(100), true);
      expect(progressOverride.isLevelUnlocked(1000), true);
      
      // Test that normal levels are still accessible
      expect(progressOverride.isLevelUnlocked(1), true);
      expect(progressOverride.isLevelUnlocked(3), true);
    });

    test('should respect normal progression when test mode is disabled', () async {
      // Test mode disabled
      await testModeManager.setTestMode(false);

      // Test that only unlocked levels are accessible
      expect(progressOverride.isLevelUnlocked(3), true);
      expect(progressOverride.isLevelUnlocked(4), false);
      expect(progressOverride.isLevelUnlocked(100), false);
    });

    test('should handle level completion correctly in test mode', () async {
      // Enable test mode
      await testModeManager.setTestMode(true);

      // Test completing a legitimate level (level 3 is unlocked)
      final result1 = await progressOverride.completeLevel(
        levelId: 3,
        moves: 10,
        timeInSeconds: 60,
      );
      
      // Should record the completion since level 3 is legitimately unlocked
      expect(result1.completedLevels.contains(3), true);

      // Test completing an illegitimate level (level 100 is not unlocked)
      final result2 = await progressOverride.completeLevel(
        levelId: 100,
        moves: 10,
        timeInSeconds: 60,
      );
      
      // Should NOT record the completion since level 100 is not legitimately unlocked
      expect(result2.completedLevels.contains(100), false);
    });

    test('should generate test mode indicator when enabled', () async {
      // Test mode disabled initially
      await testModeManager.setTestMode(false);
      expect(testModeManager.getTestModeIndicator(), isNull);

      // Enable test mode
      await testModeManager.setTestMode(true);
      final indicator = testModeManager.getTestModeIndicator();
      
      expect(indicator, isNotNull);
      expect(indicator!.text, 'TEST MODE');
      expect(indicator.color.value, 0xFFFF9800); // Orange color
    });

    test('should handle test mode level generation', () async {
      // Enable test mode
      await testModeManager.setTestMode(true);
      
      // Test that test mode manager can generate levels for testing
      expect(testModeManager.isTestModeEnabled, true);
      
      // Test level accessibility
      expect(testModeManager.isLevelAccessible(100, {1, 2, 3}), true);
      expect(testModeManager.isLevelAccessible(1000, {1, 2, 3}), true);
    });

    test('should maintain actual progress integrity', () async {
      // Enable test mode
      await testModeManager.setTestMode(true);
      
      // Get initial state
      final initialUnlocked = progressOverride.actualProgress.unlockedLevels;
      final initialCompleted = progressOverride.actualProgress.completedLevels;
      
      // Complete an illegitimate level
      await progressOverride.completeLevel(
        levelId: 100,
        moves: 10,
        timeInSeconds: 60,
      );
      
      // Verify actual progress is unchanged
      expect(progressOverride.actualProgress.unlockedLevels, equals(initialUnlocked));
      expect(progressOverride.actualProgress.completedLevels, equals(initialCompleted));
    });
  });
}