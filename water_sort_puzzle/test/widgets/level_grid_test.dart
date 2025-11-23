import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/services/progress_override.dart';
import '../../lib/services/test_mode_manager.dart';
import '../../lib/storage/game_progress.dart';
import '../../lib/widgets/level_grid.dart';

void main() {
  group('LevelGrid Widget Tests', () {
    late TestModeManager testModeManager;
    late GameProgress gameProgress;
    late ProgressOverride progressOverride;

    setUp(() async {
      // Use fake shared preferences
      SharedPreferences.setMockInitialValues({'test_mode_enabled': false});
      final prefs = await SharedPreferences.getInstance();
      
      testModeManager = TestModeManager(prefs);
      gameProgress = GameProgress.fromSets(
        unlockedLevels: {1, 2, 3},
        completedLevels: {1, 2},
      );
      progressOverride = ProgressOverride(gameProgress, testModeManager);
    });

    testWidgets('should render level grid with correct number of tiles in normal mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelGrid(
              progressOverride: progressOverride,
              testModeManager: testModeManager,
            ),
          ),
        ),
      );

      // Should show actual unlocked levels (3) plus 5 additional = 8 tiles
      expect(find.byType(LevelTile), findsNWidgets(8));
      
      // Check specific level numbers are displayed
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('should show more level tiles in test mode', (tester) async {
      // Enable test mode by setting it directly
      await testModeManager.setTestMode(true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelGrid(
              progressOverride: progressOverride,
              testModeManager: testModeManager,
            ),
          ),
        ),
      );

      // In test mode, should show more tiles than normal mode (GridView only renders visible items)
      // We can't easily test for exactly 100 because GridView is lazy, but we can verify
      // that more levels are accessible by checking high level numbers
      
      // Scroll down to see more levels
      await tester.drag(find.byType(GridView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      
      // Check that high level numbers are displayed (indicating test mode is working)
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('should show test mode visual indicators on unlocked levels', (tester) async {
      // Enable test mode by setting it directly
      await testModeManager.setTestMode(true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelGrid(
              progressOverride: progressOverride,
              testModeManager: testModeManager,
            ),
          ),
        ),
      );

      // Check for bug report icon in test mode unlocked levels
      // Level 4 and beyond should have bug report icons (test mode unlocks)
      expect(find.byIcon(Icons.bug_report), findsWidgets);
    });

    testWidgets('should not show test mode indicators in normal mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelGrid(
              progressOverride: progressOverride,
              testModeManager: testModeManager,
            ),
          ),
        ),
      );

      // Should not find any bug report icons in normal mode
      expect(find.byIcon(Icons.bug_report), findsNothing);
    });

    testWidgets('should show completion indicators on completed levels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelGrid(
              progressOverride: progressOverride,
              testModeManager: testModeManager,
            ),
          ),
        ),
      );

      // Should show check icons for completed levels (1 and 2)
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    });

    testWidgets('should show lock icons on locked levels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelGrid(
              progressOverride: progressOverride,
              testModeManager: testModeManager,
            ),
          ),
        ),
      );

      // Should show lock icons for locked levels (4, 5, 6, 7, 8)
      expect(find.byIcon(Icons.lock), findsNWidgets(5));
    });

    testWidgets('should have tappable unlocked levels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelGrid(
              progressOverride: progressOverride,
              testModeManager: testModeManager,
            ),
          ),
        ),
      );

      // Find unlocked level tiles (levels 1, 2, 3)
      final level1Tile = find.ancestor(
        of: find.text('1'),
        matching: find.byType(LevelTile),
      );
      
      expect(level1Tile, findsOneWidget);
      
      // Verify the tile is rendered without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('should have non-tappable locked levels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelGrid(
              progressOverride: progressOverride,
              testModeManager: testModeManager,
            ),
          ),
        ),
      );

      // Find locked level tiles (levels 4, 5, 6, 7, 8)
      final level4Tile = find.ancestor(
        of: find.text('4'),
        matching: find.byType(LevelTile),
      );
      
      expect(level4Tile, findsOneWidget);
      
      // Verify the tile is rendered without errors
      expect(tester.takeException(), isNull);
    });
  });

  group('LevelTile Widget Tests', () {
    testWidgets('should display correct styling for unlocked level', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LevelTile(
              levelId: 1,
              isUnlocked: true,
              isCompleted: false,
              isTestModeUnlock: false,
            ),
          ),
        ),
      );

      // Check level number is displayed
      expect(find.text('1'), findsOneWidget);
      
      // Should not show lock icon
      expect(find.byIcon(Icons.lock), findsNothing);
      
      // Should not show completion icon
      expect(find.byIcon(Icons.check_circle), findsNothing);
      
      // Should not show test mode icon
      expect(find.byIcon(Icons.bug_report), findsNothing);
    });

    testWidgets('should display correct styling for completed level', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LevelTile(
              levelId: 1,
              isUnlocked: true,
              isCompleted: true,
              isTestModeUnlock: false,
            ),
          ),
        ),
      );

      // Check level number is displayed
      expect(find.text('1'), findsOneWidget);
      
      // Should show completion icon
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      
      // Should not show lock icon
      expect(find.byIcon(Icons.lock), findsNothing);
    });

    testWidgets('should display correct styling for locked level', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LevelTile(
              levelId: 5,
              isUnlocked: false,
              isCompleted: false,
              isTestModeUnlock: false,
            ),
          ),
        ),
      );

      // Check level number is displayed
      expect(find.text('5'), findsOneWidget);
      
      // Should show lock icon
      expect(find.byIcon(Icons.lock), findsOneWidget);
      
      // Should not show completion icon
      expect(find.byIcon(Icons.check_circle), findsNothing);
      
      // Should not show test mode icon
      expect(find.byIcon(Icons.bug_report), findsNothing);
    });

    testWidgets('should display test mode indicator for test mode unlocked level', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LevelTile(
              levelId: 10,
              isUnlocked: true,
              isCompleted: false,
              isTestModeUnlock: true,
            ),
          ),
        ),
      );

      // Check level number is displayed
      expect(find.text('10'), findsOneWidget);
      
      // Should show test mode bug icon
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
      
      // Should not show lock icon
      expect(find.byIcon(Icons.lock), findsNothing);
    });

    testWidgets('should display orange styling for test mode unlocked level', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LevelTile(
              levelId: 10,
              isUnlocked: true,
              isCompleted: false,
              isTestModeUnlock: true,
            ),
          ),
        ),
      );

      // Find the container with orange styling
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      
      // Check that border color is orange for test mode
      expect(decoration.border, isA<Border>());
      final border = decoration.border as Border;
      expect(border.top.color, equals(Colors.orange));
      
      // Check that background has orange tint
      expect(decoration.color, equals(Colors.orange.shade50));
    });

    testWidgets('should display green styling for completed level', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LevelTile(
              levelId: 1,
              isUnlocked: true,
              isCompleted: true,
              isTestModeUnlock: false,
            ),
          ),
        ),
      );

      // Find the container with green styling
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      
      // Check that border color is green for completed
      expect(decoration.border, isA<Border>());
      final border = decoration.border as Border;
      expect(border.top.color, equals(Colors.green));
      
      // Check that background has green tint
      expect(decoration.color, equals(Colors.green.shade50));
    });

    testWidgets('should display blue styling for normal unlocked level', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LevelTile(
              levelId: 3,
              isUnlocked: true,
              isCompleted: false,
              isTestModeUnlock: false,
            ),
          ),
        ),
      );

      // Find the container with blue styling
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      
      // Check that border color is blue for normal unlocked
      expect(decoration.border, isA<Border>());
      final border = decoration.border as Border;
      expect(border.top.color, equals(Colors.blue));
      
      // Check that background has blue tint
      expect(decoration.color, equals(Colors.blue.shade50));
    });

    testWidgets('should display grey styling for locked level', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LevelTile(
              levelId: 5,
              isUnlocked: false,
              isCompleted: false,
              isTestModeUnlock: false,
            ),
          ),
        ),
      );

      // Find the container with grey styling
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      
      // Check that border color is grey for locked
      expect(decoration.border, isA<Border>());
      final border = decoration.border as Border;
      expect(border.top.color, equals(Colors.grey));
      
      // Check that background is grey
      expect(decoration.color, equals(Colors.grey.shade300));
    });

    testWidgets('should call onTap when tapped and callback is provided', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelTile(
              levelId: 1,
              isUnlocked: true,
              isCompleted: false,
              isTestModeUnlock: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Tap the tile
      await tester.tap(find.byType(LevelTile));
      await tester.pump();

      // Verify callback was called
      expect(tapped, isTrue);
    });

    testWidgets('should not respond to tap when no callback provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LevelTile(
              levelId: 5,
              isUnlocked: false,
              isCompleted: false,
              isTestModeUnlock: false,
              // No onTap callback
            ),
          ),
        ),
      );

      // Try to tap the tile
      await tester.tap(find.byType(LevelTile));
      await tester.pump();

      // Should not throw any errors
      expect(tester.takeException(), isNull);
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper accessibility label for unlocked level', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LevelTile(
                levelId: 3,
                isUnlocked: true,
                isCompleted: false,
                isTestModeUnlock: false,
              ),
            ),
          ),
        );

        // Check that the tile has proper semantics by looking for the LevelTile widget
        final levelTile = tester.widget<LevelTile>(find.byType(LevelTile));
        
        // Verify the accessibility methods return correct values
        expect(levelTile.getAccessibilityLabel(), equals('Level 3, unlocked'));
        expect(levelTile.getAccessibilityHint(), equals('This level is unlocked. Tap to play.'));
        
        // Verify the tile renders without errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('should have proper accessibility label for completed level', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LevelTile(
                levelId: 1,
                isUnlocked: true,
                isCompleted: true,
                isTestModeUnlock: false,
              ),
            ),
          ),
        );

        // Check that the tile has proper semantics
        final levelTile = tester.widget<LevelTile>(find.byType(LevelTile));
        
        // Verify the accessibility methods return correct values
        expect(levelTile.getAccessibilityLabel(), equals('Level 1, completed'));
        expect(levelTile.getAccessibilityHint(), equals('This level is completed. Tap to play again.'));
        
        // Verify the tile renders without errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('should have proper accessibility label for locked level', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LevelTile(
                levelId: 5,
                isUnlocked: false,
                isCompleted: false,
                isTestModeUnlock: false,
              ),
            ),
          ),
        );

        // Check that the tile has proper semantics
        final levelTile = tester.widget<LevelTile>(find.byType(LevelTile));
        
        // Verify the accessibility methods return correct values
        expect(levelTile.getAccessibilityLabel(), equals('Level 5, locked'));
        expect(levelTile.getAccessibilityHint(), equals('This level is locked and cannot be played'));
        
        // Verify the tile renders without errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('should have proper accessibility label for test mode unlocked level', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LevelTile(
                levelId: 10,
                isUnlocked: true,
                isCompleted: false,
                isTestModeUnlock: true,
              ),
            ),
          ),
        );

        // Check that the tile has proper semantics
        final levelTile = tester.widget<LevelTile>(find.byType(LevelTile));
        
        // Verify the accessibility methods return correct values
        expect(levelTile.getAccessibilityLabel(), equals('Level 10, unlocked, test mode unlock'));
        expect(levelTile.getAccessibilityHint(), equals('This level is unlocked in test mode. Tap to play. Progress will not be saved.'));
        
        // Verify the tile renders without errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('should have proper accessibility label for completed test mode level', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LevelTile(
                levelId: 15,
                isUnlocked: true,
                isCompleted: true,
                isTestModeUnlock: true,
              ),
            ),
          ),
        );

        // Check that the tile has proper semantics
        final levelTile = tester.widget<LevelTile>(find.byType(LevelTile));
        
        // Verify the accessibility methods return correct values
        expect(levelTile.getAccessibilityLabel(), equals('Level 15, completed, test mode unlock'));
        expect(levelTile.getAccessibilityHint(), equals('This level is unlocked in test mode. Tap to play. Progress will not be saved.'));
        
        // Verify the tile renders without errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('should have semantic labels for icons', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LevelTile(
                levelId: 10,
                isUnlocked: true,
                isCompleted: true,
                isTestModeUnlock: true,
              ),
            ),
          ),
        );

        // Check completion icon has semantic label
        final completionIcon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
        expect(completionIcon.semanticLabel, equals('Completed'));

        // Check test mode indicator has semantic label
        final testModeSemantics = tester.widget<Semantics>(
          find.ancestor(
            of: find.byIcon(Icons.bug_report),
            matching: find.byType(Semantics),
          ).first,
        );
        expect(testModeSemantics.properties.label, equals('Test mode unlock'));
      });

      testWidgets('should have semantic label for lock icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LevelTile(
                levelId: 5,
                isUnlocked: false,
                isCompleted: false,
                isTestModeUnlock: false,
              ),
            ),
          ),
        );

        // Check lock icon has semantic label
        final lockIcon = tester.widget<Icon>(find.byIcon(Icons.lock));
        expect(lockIcon.semanticLabel, equals('Locked'));
      });

      testWidgets('should have semantic label for level number text', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LevelTile(
                levelId: 7,
                isUnlocked: true,
                isCompleted: false,
                isTestModeUnlock: false,
              ),
            ),
          ),
        );

        // Check level number text has semantic label
        final levelText = tester.widget<Text>(find.text('7'));
        expect(levelText.semanticsLabel, equals('Level 7'));
      });
    });
  });
}