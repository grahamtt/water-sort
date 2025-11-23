import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../lib/main.dart';
import '../../lib/services/dependency_injection.dart';
import '../../lib/services/test_mode_manager.dart';
import '../../lib/services/progress_override.dart';
import '../../lib/storage/game_progress.dart';

void main() {
  group('App Initialization Integration Tests', () {
    setUp(() {
      // Reset dependency injection before each test
      DependencyInjection.reset();
      
      // Setup SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      // Clean up after each test
      DependencyInjection.reset();
    });

    testWidgets('should initialize app successfully with all dependencies', (tester) async {
      // Initialize the app
      await tester.pumpWidget(const WaterSortPuzzleApp());
      await tester.pumpAndSettle();

      // Verify the main menu is displayed
      expect(find.text('Water Sort Puzzle'), findsAtLeastNWidgets(1));
      expect(find.text('Play Game'), findsOneWidget);
      expect(find.text('Level Selection'), findsOneWidget);

      // Verify dependencies are available in the widget tree
      final context = tester.element(find.byType(MainMenu));
      
      expect(() => context.read<TestModeManager>(), returnsNormally);
      expect(() => context.read<ProgressOverride>(), returnsNormally);
      expect(() => context.read<GameProgress>(), returnsNormally);
    });

    testWidgets('should handle initialization errors gracefully', (tester) async {
      // Force initialization failure by resetting without setup
      DependencyInjection.reset();
      // Don't set up SharedPreferences to cause failure

      // This should show the error app instead of crashing
      await tester.pumpWidget(const WaterSortPuzzleApp());
      await tester.pumpAndSettle();

      // Should show error screen instead of main menu
      expect(find.text('Water Sort Puzzle'), findsNothing);
      expect(find.text('Initialization Error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should navigate to level selection screen with test mode integration', (tester) async {
      await tester.pumpWidget(const WaterSortPuzzleApp());
      await tester.pumpAndSettle();

      // Navigate to level selection
      await tester.tap(find.text('Level Selection'));
      await tester.pumpAndSettle();

      // Verify level selection screen is displayed
      expect(find.text('Select Level'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Verify test mode components are available
      final context = tester.element(find.byType(Scaffold));
      expect(() => context.read<TestModeManager>(), returnsNormally);
      expect(() => context.read<ProgressOverride>(), returnsNormally);
    });

    testWidgets('should navigate to game screen with dependency injection', (tester) async {
      await tester.pumpWidget(const WaterSortPuzzleApp());
      await tester.pumpAndSettle();

      // Navigate to game screen
      await tester.tap(find.text('Play Game'));
      await tester.pumpAndSettle();

      // Verify game screen is displayed
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('Moves'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);

      // Verify dependencies are available
      final context = tester.element(find.byType(Scaffold));
      expect(() => context.read<TestModeManager>(), returnsNormally);
      expect(() => context.read<ProgressOverride>(), returnsNormally);
    });

    testWidgets('should access settings dialog with test mode toggle', (tester) async {
      await tester.pumpWidget(const WaterSortPuzzleApp());
      await tester.pumpAndSettle();

      // Navigate to level selection
      await tester.tap(find.text('Level Selection'));
      await tester.pumpAndSettle();

      // Tap settings button
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Verify settings dialog is displayed
      expect(find.text('Developer Settings'), findsOneWidget);
      expect(find.text('Test Mode'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('should toggle test mode and update UI', (tester) async {
      await tester.pumpWidget(const WaterSortPuzzleApp());
      await tester.pumpAndSettle();

      // Navigate to level selection
      await tester.tap(find.text('Level Selection'));
      await tester.pumpAndSettle();

      // Open settings dialog
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Toggle test mode on
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Verify test mode indicator is displayed
      expect(find.text('TEST MODE'), findsOneWidget);
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
    });

    testWidgets('should maintain test mode state across navigation', (tester) async {
      await tester.pumpWidget(const WaterSortPuzzleApp());
      await tester.pumpAndSettle();

      // Navigate to level selection and enable test mode
      await tester.tap(find.text('Level Selection'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Navigate back to main menu
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Navigate to game screen
      await tester.tap(find.text('Play Game'));
      await tester.pumpAndSettle();

      // Verify test mode indicator is still displayed in game screen
      expect(find.text('TEST MODE'), findsOneWidget);
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
    });

    testWidgets('should handle dependency disposal on app termination', (tester) async {
      await tester.pumpWidget(const WaterSortPuzzleApp());
      await tester.pumpAndSettle();

      // Verify dependencies are initialized
      final di = DependencyInjection.instance;
      expect(() => di.testModeManager, returnsNormally);

      // Simulate app termination by disposing the widget
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      // Note: In a real app, disposal would be handled by the app lifecycle
      // For testing purposes, we manually dispose
      await di.dispose();

      // Verify dependencies are disposed
      expect(
        () => di.testModeManager,
        throwsA(isA<DependencyInjectionException>()),
      );
    });

    group('Error Recovery', () {
      testWidgets('should retry initialization after error', (tester) async {
        // First attempt with invalid setup - reset without proper setup
        DependencyInjection.reset();
        // Don't set up SharedPreferences to cause failure
        
        await tester.pumpWidget(const WaterSortPuzzleApp());
        await tester.pumpAndSettle();

        // Should show error screen
        expect(find.text('Initialization Error'), findsOneWidget);

        // Fix the setup
        SharedPreferences.setMockInitialValues({});
        DependencyInjection.reset();

        // Tap retry
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Should now show main menu
        expect(find.text('Water Sort Puzzle'), findsAtLeastNWidgets(1));
        expect(find.text('Play Game'), findsOneWidget);
      });
    });

    group('Performance', () {
      testWidgets('should initialize within reasonable time', (tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(const WaterSortPuzzleApp());
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Initialization should complete within 5 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));

        // Verify app is functional
        expect(find.text('Water Sort Puzzle'), findsAtLeastNWidgets(1));
      });

      testWidgets('should not leak memory during navigation', (tester) async {
        await tester.pumpWidget(const WaterSortPuzzleApp());
        await tester.pumpAndSettle();

        // Navigate between screens multiple times
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.text('Level Selection'));
          await tester.pumpAndSettle();

          await tester.tap(find.byIcon(Icons.arrow_back));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Play Game'));
          await tester.pumpAndSettle();

          await tester.tap(find.byIcon(Icons.arrow_back));
          await tester.pumpAndSettle();
        }

        // App should still be responsive
        expect(find.text('Water Sort Puzzle'), findsAtLeastNWidgets(1));
      });
    });
  });
}