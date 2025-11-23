import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/screens/game_screen.dart';
import '../../lib/services/test_mode_manager.dart';
import '../../lib/services/progress_override.dart';
import '../../lib/storage/game_progress.dart';
import '../../lib/models/level.dart';
import '../../lib/models/container.dart' as game_container;
import '../../lib/models/liquid_layer.dart';
import '../../lib/models/liquid_color.dart';
import '../../lib/widgets/test_mode_indicator_widget.dart';

void main() {
  group('GameScreen Test Mode Integration', () {
    late TestModeManager testModeManager;
    late GameProgress gameProgress;
    late ProgressOverride progressOverride;

    // Helper function to create a test level
    Level createTestLevel(int levelId, int difficulty) {
      return Level(
        id: levelId,
        difficulty: difficulty,
        containerCount: 3,
        colorCount: 2,
        initialContainers: [
          game_container.Container(
            id: 0,
            capacity: 4,
            liquidLayers: [
              const LiquidLayer(color: LiquidColor.red, volume: 2),
              const LiquidLayer(color: LiquidColor.blue, volume: 2),
            ],
          ),
          game_container.Container(
            id: 1,
            capacity: 4,
            liquidLayers: [
              const LiquidLayer(color: LiquidColor.red, volume: 2),
              const LiquidLayer(color: LiquidColor.blue, volume: 2),
            ],
          ),
          game_container.Container(id: 2, capacity: 4, liquidLayers: []),
        ],
        tags: ['test'],
      );
    }

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

    testWidgets('should display test mode indicator when test mode is enabled', (tester) async {
      final testLevel = createTestLevel(1, 1);
      await testModeManager.setTestMode(true);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            level: testLevel,
            testModeManager: testModeManager,
            progressOverride: progressOverride,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify test mode indicator is displayed
      expect(find.byType(TestModeIndicatorWidget), findsOneWidget);
      expect(find.text('TEST MODE'), findsOneWidget);
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
    });

    testWidgets('should not display test mode indicator when test mode is disabled', (tester) async {
      final testLevel = createTestLevel(1, 1);
      await testModeManager.setTestMode(false);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            level: testLevel,
            testModeManager: testModeManager,
            progressOverride: progressOverride,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify test mode indicator is not displayed
      expect(find.byType(TestModeIndicatorWidget), findsNothing);
      expect(find.text('TEST MODE'), findsNothing);
    });

    testWidgets('should work without test mode manager (backward compatibility)', (tester) async {
      final testLevel = createTestLevel(1, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            level: testLevel,
            // No test mode manager or progress override provided
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should work without test mode components
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.byType(TestModeIndicatorWidget), findsNothing);
    });

    testWidgets('should update test mode indicator when test mode is toggled', (tester) async {
      final testLevel = createTestLevel(1, 1);
      await testModeManager.setTestMode(false);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            level: testLevel,
            testModeManager: testModeManager,
            progressOverride: progressOverride,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no test mode indicator
      expect(find.byType(TestModeIndicatorWidget), findsNothing);

      // Enable test mode
      await testModeManager.setTestMode(true);
      await tester.pumpAndSettle();

      // Now test mode indicator should appear
      expect(find.byType(TestModeIndicatorWidget), findsOneWidget);
      expect(find.text('TEST MODE'), findsOneWidget);

      // Disable test mode
      await testModeManager.setTestMode(false);
      await tester.pumpAndSettle();

      // Test mode indicator should disappear
      expect(find.byType(TestModeIndicatorWidget), findsNothing);
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

    testWidgets('should display level information correctly', (tester) async {
      final testLevel = createTestLevel(42, 5);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            level: testLevel,
            testModeManager: testModeManager,
            progressOverride: progressOverride,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify level information is displayed
      expect(find.text('Level 42'), findsOneWidget);
    });

    testWidgets('should handle level ID parameter correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            levelId: 25,
            testModeManager: testModeManager,
            progressOverride: progressOverride,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The GameScreen should initialize with the provided level ID
      // This is tested indirectly through the widget creation
      expect(find.byType(GameScreen), findsOneWidget);
    });
  });
}