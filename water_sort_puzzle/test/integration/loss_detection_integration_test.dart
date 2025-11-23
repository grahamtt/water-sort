import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/game_state.dart';
import 'package:water_sort_puzzle/models/level.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/providers/game_state_provider.dart';
import 'package:water_sort_puzzle/services/game_engine.dart';
import 'package:water_sort_puzzle/services/level_generator.dart';

/// Mock level generator for testing
class MockLevelGenerator implements LevelGenerator {
  Level? _mockLevel;

  void setMockLevel(Level level) {
    _mockLevel = level;
  }

  @override
  Level generateLevel(int levelId, int difficulty, int containerCount, int colorCount, {bool ignoreProgressionLimits = false}) {
    return _mockLevel ?? Level(
      id: levelId,
      difficulty: difficulty,
      containerCount: containerCount,
      colorCount: colorCount,
      initialContainers: [],
      minimumMoves: 0,
    );
  }

  @override
  Level generateUniqueLevel(int levelId, int difficulty, int containerCount, int colorCount, List<Level> existingLevels, {bool ignoreProgressionLimits = false}) {
    return generateLevel(levelId, difficulty, containerCount, colorCount, ignoreProgressionLimits: ignoreProgressionLimits);
  }

  @override
  List<Level> generateLevelSeries(int startId, int count, {int startDifficulty = 1}) {
    return [];
  }

  @override
  bool validateLevel(Level level) => true;

  @override
  bool isLevelSimilar(Level newLevel, List<Level> previousLevels) => false;

  @override
  String generateLevelSignature(Level level) => 'test-signature';

  @override
  bool hasCompletedContainers(Level level) => false;
}

void main() {
  group('Loss Detection Integration', () {
    late GameStateProvider provider;
    late MockLevelGenerator mockLevelGenerator;
    late WaterSortGameEngine gameEngine;

    setUp(() {
      mockLevelGenerator = MockLevelGenerator();
      gameEngine = WaterSortGameEngine();
      provider = GameStateProvider(
        gameEngine: gameEngine,
        levelGenerator: mockLevelGenerator,
      );
    });

    tearDown(() {
      provider.dispose();
    });

    testWidgets('detects loss condition in deadlocked state', (WidgetTester tester) async {
      // Create a deadlocked level (no valid moves possible)
      final containers = [
        Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ],
        ),
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        ),
      ];

      final level = Level(
        id: 1,
        difficulty: 1,
        containerCount: 2,
        colorCount: 2,
        initialContainers: containers,
        minimumMoves: 0,
      );

      mockLevelGenerator.setMockLevel(level);

      // Initialize the level (should immediately detect loss)
      await provider.initializeLevel(1);
      
      // Wait for loss detection
      await tester.pump();
      
      // Should be in loss state
      expect(provider.isLoss, true);
      expect(provider.uiState, GameUIState.loss);
      expect(provider.feedbackMessage, contains('No more valid moves'));
    });

    testWidgets('does not detect loss when valid moves are available', (WidgetTester tester) async {
      // Create a level with valid moves available but not solved
      final containers = [
        Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 1),
          ],
        ),
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 1),
          ],
        ),
        Container(
          id: 2,
          capacity: 4,
          liquidLayers: [],
        ),
      ];

      final level = Level(
        id: 1,
        difficulty: 1,
        containerCount: 3,
        colorCount: 2,
        initialContainers: containers,
        minimumMoves: 1,
      );

      mockLevelGenerator.setMockLevel(level);

      // Initialize the level
      await provider.initializeLevel(1);
      
      // Wait for any async operations to complete
      await tester.pump();

      // Should not detect loss since valid moves are available
      expect(provider.currentGameState, isNotNull);
      expect(provider.isLoss, false);
      expect(provider.uiState, GameUIState.idle);
    });

    testWidgets('handles restart from loss state', (WidgetTester tester) async {
      // Create a deadlocked level
      final containers = [
        Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ],
        ),
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        ),
      ];

      final level = Level(
        id: 1,
        difficulty: 1,
        containerCount: 2,
        colorCount: 2,
        initialContainers: containers,
        minimumMoves: 0,
      );

      mockLevelGenerator.setMockLevel(level);

      // Initialize the level (should immediately detect loss)
      await provider.initializeLevel(1);
      await tester.pump();
      
      expect(provider.isLoss, true);

      // Restart the level
      await provider.restartCurrentLevel();
      await tester.pump();

      // Should be back to initial state, still in loss (since it's inherently deadlocked)
      expect(provider.isLoss, true); // Still deadlocked
      expect(provider.currentGameState?.isLost, true);
    });

    testWidgets('dismisses loss state correctly', (WidgetTester tester) async {
      // Create a deadlocked level
      final containers = [
        Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ],
        ),
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        ),
      ];

      final level = Level(
        id: 1,
        difficulty: 1,
        containerCount: 2,
        colorCount: 2,
        initialContainers: containers,
        minimumMoves: 0,
      );

      mockLevelGenerator.setMockLevel(level);

      // Initialize the level (should immediately detect loss)
      await provider.initializeLevel(1);
      await tester.pump();
      
      expect(provider.isLoss, true);
      expect(provider.feedbackMessage, isNotNull);

      // Dismiss the loss state
      provider.dismissLoss();

      // Should clear the loss UI state but keep the game state as lost
      expect(provider.isLoss, false);
      expect(provider.uiState, GameUIState.idle);
      expect(provider.feedbackMessage, isNull);
      expect(provider.currentGameState?.isLost, true); // Game state should still be lost
    });

    testWidgets('loss detection works with game engine integration', (WidgetTester tester) async {
      // Test that the game engine's checkLossCondition method is properly integrated
      final containers = [
        Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 4),
          ],
        ),
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.blue, volume: 2),
            LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        ),
      ];

      final level = Level(
        id: 1,
        difficulty: 1,
        containerCount: 2,
        colorCount: 2,
        initialContainers: containers,
        minimumMoves: 0,
      );

      mockLevelGenerator.setMockLevel(level);

      // Initialize the level
      await provider.initializeLevel(1);
      await tester.pump();

      // This level should be detected as lost because:
      // - Container 0 is full with red (can't pour anything into it)
      // - Container 1 has red on top, but container 0 is full
      // - No valid moves are possible
      expect(provider.isLoss, true);
      expect(provider.currentGameState?.isLost, true);
    });
  });
}