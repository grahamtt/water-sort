import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/dependency_injection.dart';
import '../../lib/services/test_mode_manager.dart';
import '../../lib/services/progress_override.dart';
import '../../lib/storage/game_progress.dart';
import '../../lib/providers/game_state_provider.dart';

void main() {
  group('DependencyProvider Widget Tests', () {
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

    testWidgets('should provide all dependencies to child widgets', (tester) async {
      // Initialize dependencies
      await DependencyInjection.instance.initialize();

      bool testModeManagerFound = false;
      bool progressOverrideFound = false;
      bool gameProgressFound = false;
      bool gameStateProviderFound = false;

      await tester.pumpWidget(
        DependencyProvider(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                // Try to access all dependencies
                try {
                  context.read<TestModeManager>();
                  testModeManagerFound = true;
                } catch (e) {
                  // Dependency not found
                }

                try {
                  context.read<ProgressOverride>();
                  progressOverrideFound = true;
                } catch (e) {
                  // Dependency not found
                }

                try {
                  context.read<GameProgress>();
                  gameProgressFound = true;
                } catch (e) {
                  // Dependency not found
                }

                try {
                  context.read<GameStateProvider>();
                  gameStateProviderFound = true;
                } catch (e) {
                  // Dependency not found
                }

                return const Scaffold(
                  body: Text('Test Widget'),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all dependencies are available
      expect(testModeManagerFound, isTrue, reason: 'TestModeManager should be available');
      expect(progressOverrideFound, isTrue, reason: 'ProgressOverride should be available');
      expect(gameProgressFound, isTrue, reason: 'GameProgress should be available');
      expect(gameStateProviderFound, isTrue, reason: 'GameStateProvider should be available');
    });

    testWidgets('should provide working TestModeManager', (tester) async {
      await DependencyInjection.instance.initialize();

      TestModeManager? testModeManager;

      await tester.pumpWidget(
        DependencyProvider(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                testModeManager = context.read<TestModeManager>();
                return const Scaffold(
                  body: Text('Test Widget'),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify TestModeManager is functional
      expect(testModeManager, isNotNull);
      expect(testModeManager!.isTestModeEnabled, isFalse);

      // Test setting test mode
      await testModeManager!.setTestMode(true);
      expect(testModeManager!.isTestModeEnabled, isTrue);
    });

    testWidgets('should provide working ProgressOverride', (tester) async {
      await DependencyInjection.instance.initialize();

      ProgressOverride? progressOverride;

      await tester.pumpWidget(
        DependencyProvider(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                progressOverride = context.read<ProgressOverride>();
                return const Scaffold(
                  body: Text('Test Widget'),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify ProgressOverride is functional
      expect(progressOverride, isNotNull);
      expect(progressOverride!.getEffectiveUnlockedLevels(), isNotEmpty);
      expect(progressOverride!.isLevelUnlocked(1), isTrue);
    });

    testWidgets('should provide working GameStateProvider', (tester) async {
      await DependencyInjection.instance.initialize();

      GameStateProvider? gameStateProvider;

      await tester.pumpWidget(
        DependencyProvider(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                gameStateProvider = context.read<GameStateProvider>();
                return const Scaffold(
                  body: Text('Test Widget'),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify GameStateProvider is functional
      expect(gameStateProvider, isNotNull);
      expect(gameStateProvider!.currentGameState, isNull); // No level loaded yet
      expect(gameStateProvider!.loadingState.name, equals('idle'));
    });

    testWidgets('should handle dependency context extensions', (tester) async {
      await DependencyInjection.instance.initialize();

      TestModeManager? testModeManager;
      ProgressOverride? progressOverride;

      await tester.pumpWidget(
        DependencyProvider(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                // Test context extensions
                testModeManager = context.testModeManager;
                progressOverride = context.progressOverride;

                return const Scaffold(
                  body: Text('Test Widget'),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify context extensions work
      expect(testModeManager, isNotNull);
      expect(progressOverride, isNotNull);
    });

    testWidgets('should handle Consumer widgets for reactive updates', (tester) async {
      await DependencyInjection.instance.initialize();

      bool testModeEnabled = false;

      await tester.pumpWidget(
        DependencyProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<TestModeManager>(
                builder: (context, testModeManager, child) {
                  testModeEnabled = testModeManager.isTestModeEnabled;
                  return Column(
                    children: [
                      Text('Test Mode: $testModeEnabled'),
                      ElevatedButton(
                        onPressed: () => testModeManager.setTestMode(!testModeEnabled),
                        child: const Text('Toggle Test Mode'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially test mode should be disabled
      expect(find.text('Test Mode: false'), findsOneWidget);
      expect(testModeEnabled, isFalse);

      // Toggle test mode
      await tester.tap(find.text('Toggle Test Mode'));
      await tester.pumpAndSettle();

      // Test mode should now be enabled
      expect(find.text('Test Mode: true'), findsOneWidget);
    });

    testWidgets('should handle multiple consumers', (tester) async {
      await DependencyInjection.instance.initialize();

      await tester.pumpWidget(
        DependencyProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Consumer<TestModeManager>(
                    builder: (context, testModeManager, child) {
                      return Text('Test Mode: ${testModeManager.isTestModeEnabled}');
                    },
                  ),
                  Consumer<ProgressOverride>(
                    builder: (context, progressOverride, child) {
                      return Text('Unlocked Levels: ${progressOverride.getEffectiveUnlockedLevels().length}');
                    },
                  ),
                  Consumer<GameStateProvider>(
                    builder: (context, gameStateProvider, child) {
                      return Text('Loading: ${gameStateProvider.isLoading}');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all consumers are working
      expect(find.text('Test Mode: false'), findsOneWidget);
      expect(find.textContaining('Unlocked Levels:'), findsOneWidget);
      expect(find.text('Loading: false'), findsOneWidget);
    });

    testWidgets('should handle nested providers correctly', (tester) async {
      await DependencyInjection.instance.initialize();

      await tester.pumpWidget(
        DependencyProvider(
          child: MaterialApp(
            home: ChangeNotifierProvider<ValueNotifier<int>>(
              create: (_) => ValueNotifier<int>(0),
              child: Scaffold(
                body: Builder(
                  builder: (context) {
                    // Should be able to access both DI dependencies and nested provider
                    final testModeManager = context.read<TestModeManager>();
                    final valueNotifier = context.read<ValueNotifier<int>>();

                    return Column(
                      children: [
                        Text('Test Mode: ${testModeManager.isTestModeEnabled}'),
                        Text('Value: ${valueNotifier.value}'),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Both providers should work
      expect(find.text('Test Mode: false'), findsOneWidget);
      expect(find.text('Value: 0'), findsOneWidget);
    });

    group('Error Handling', () {
      testWidgets('should handle uninitialized dependencies gracefully', (tester) async {
        // Don't initialize dependencies

        bool errorCaught = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                try {
                  DependencyProvider(
                    child: const Text('Test'),
                  );
                } catch (e) {
                  errorCaught = true;
                }
                return const Scaffold(
                  body: Text('Error Test'),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should handle the error gracefully
        expect(find.text('Error Test'), findsOneWidget);
      });
    });
  });
}