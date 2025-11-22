import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/providers/game_state_provider.dart';
import 'package:water_sort_puzzle/services/game_engine.dart';
import 'package:water_sort_puzzle/services/level_generator.dart';
import 'package:water_sort_puzzle/models/game_state.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/models/level.dart';

void main() {
  group('GameStateProvider Integration Tests', () {
    late GameStateProvider provider;
    late WaterSortGameEngine gameEngine;
    late WaterSortLevelGenerator levelGenerator;

    setUp(() {
      gameEngine = WaterSortGameEngine();
      levelGenerator = WaterSortLevelGenerator();
      provider = GameStateProvider(
        gameEngine: gameEngine,
        levelGenerator: levelGenerator,
      );
    });

    tearDown(() {
      provider.dispose();
    });

    group('Initialization', () {
      test('should initialize with correct default state', () {
        expect(provider.currentGameState, isNull);
        expect(provider.loadingState, GameLoadingState.idle);
        expect(provider.uiState, GameUIState.idle);
        expect(provider.selectedContainerId, isNull);
        expect(provider.errorMessage, isNull);
        expect(provider.feedbackMessage, isNull);
        expect(provider.isAnimating, false);
        expect(provider.isLoading, false);
        expect(provider.hasError, false);
        expect(provider.isGameActive, false);
        expect(provider.canUndo, false);
        expect(provider.canRedo, false);
        expect(provider.isVictory, false);
      });

      test('should initialize level successfully', () async {
        // Act
        await provider.initializeLevel(1);

        // Assert
        expect(provider.currentGameState, isNotNull);
        expect(provider.currentGameState!.levelId, 1);
        expect(provider.loadingState, GameLoadingState.idle);
        expect(provider.uiState, GameUIState.idle);
        expect(provider.selectedContainerId, isNull);
        expect(provider.isGameActive, true);
      });

      test('should handle level initialization error gracefully', () async {
        // Create a provider with an error-throwing level generator
        final errorLevelGenerator = _ErrorLevelGenerator();
        final errorProvider = GameStateProvider(
          gameEngine: gameEngine,
          levelGenerator: errorLevelGenerator,
        );

        // Act
        await errorProvider.initializeLevel(1);

        // Assert
        expect(errorProvider.hasError, true);
        expect(errorProvider.errorMessage, contains('Failed to initialize level'));
        expect(errorProvider.loadingState, GameLoadingState.error);
        expect(errorProvider.uiState, GameUIState.error);

        errorProvider.dispose();
      });
    });

    group('Container Selection and Pour Operations', () {
      setUp(() async {
        await provider.initializeLevel(1);
      });

      test('should select non-empty container', () async {
        // Find a non-empty container
        final nonEmptyContainer = provider.currentGameState!.containers
            .firstWhere((c) => !c.isEmpty);

        // Act
        await provider.selectContainer(nonEmptyContainer.id);

        // Assert
        expect(provider.selectedContainerId, nonEmptyContainer.id);
        expect(provider.uiState, GameUIState.containerSelected);
      });

      test('should deselect container when same container is selected twice', () async {
        // Find a non-empty container
        final nonEmptyContainer = provider.currentGameState!.containers
            .firstWhere((c) => !c.isEmpty);

        // Select container first
        await provider.selectContainer(nonEmptyContainer.id);
        expect(provider.selectedContainerId, nonEmptyContainer.id);

        // Act - select same container again
        await provider.selectContainer(nonEmptyContainer.id);

        // Assert
        expect(provider.selectedContainerId, isNull);
        expect(provider.uiState, GameUIState.idle);
      });

      test('should provide feedback when trying to select empty container', () async {
        // Find an empty container
        final emptyContainer = provider.currentGameState!.containers
            .firstWhere((c) => c.isEmpty);

        // Act
        await provider.selectContainer(emptyContainer.id);

        // Assert
        expect(provider.selectedContainerId, isNull);
        expect(provider.feedbackMessage, 'Cannot select empty container');
        
        // Wait for the feedback to clear to avoid disposal issues
        await Future.delayed(const Duration(milliseconds: 2100));
      });

      test('should attempt pour when selecting different containers', () async {
        // Find containers for testing
        final containers = provider.currentGameState!.containers;
        final sourceContainer = containers.firstWhere((c) => !c.isEmpty);
        final targetContainer = containers.firstWhere((c) => c.isEmpty);

        // Select source container first
        await provider.selectContainer(sourceContainer.id);
        expect(provider.selectedContainerId, sourceContainer.id);

        // Act - select target container to trigger pour
        await provider.selectContainer(targetContainer.id);

        // Assert - container should be deselected after pour attempt
        expect(provider.selectedContainerId, isNull);
      });
    });

    group('Undo/Redo Operations', () {
      setUp(() async {
        await provider.initializeLevel(1);
      });

      test('should not undo when no moves available', () async {
        expect(provider.canUndo, false);

        // Act
        await provider.undoMove();

        // Assert - should not change state
        expect(provider.feedbackMessage, isNull);
      });

      test('should not redo when no moves available', () async {
        expect(provider.canRedo, false);

        // Act
        await provider.redoMove();

        // Assert - should not change state
        expect(provider.feedbackMessage, isNull);
      });
    });

    group('Level Reset', () {
      setUp(() async {
        await provider.initializeLevel(1);
      });

      test('should reset level to initial state', () async {
        // Act
        await provider.resetLevel();

        // Assert
        expect(provider.currentGameState!.moveCount, 0);
        expect(provider.selectedContainerId, isNull);
        expect(provider.uiState, GameUIState.idle);
        expect(provider.errorMessage, isNull);
        expect(provider.feedbackMessage, isNull);
      });
    });

    group('Save/Load Operations', () {
      setUp(() async {
        await provider.initializeLevel(1);
      });

      test('should handle save operation', () async {
        // Act
        await provider.saveGameState();

        // Assert
        expect(provider.feedbackMessage, 'Game saved');
        expect(provider.loadingState, GameLoadingState.idle);
      });

      test('should handle load operation', () async {
        // Act
        await provider.loadGameState();

        // Assert
        expect(provider.feedbackMessage, 'Game loaded');
        expect(provider.loadingState, GameLoadingState.idle);
      });
    });

    group('Error Handling', () {
      test('should clear error messages', () async {
        // First create an error condition
        final errorProvider = GameStateProvider(
          gameEngine: gameEngine,
          levelGenerator: _ErrorLevelGenerator(),
        );

        // Initialize to create error
        await errorProvider.initializeLevel(1);
        expect(errorProvider.hasError, true);

        // Act
        errorProvider.clearError();

        // Assert
        expect(errorProvider.hasError, false);
        expect(errorProvider.errorMessage, isNull);

        errorProvider.dispose();
      });

      test('should clear feedback messages', () async {
        await provider.initializeLevel(1);
        
        // Create feedback by trying to select empty container
        final emptyContainer = provider.currentGameState!.containers
            .firstWhere((c) => c.isEmpty);
        await provider.selectContainer(emptyContainer.id);
        
        expect(provider.feedbackMessage, isNotNull);

        // Act
        provider.clearFeedback();

        // Assert
        expect(provider.feedbackMessage, isNull);
      });
    });

    group('Victory State Management', () {
      test('should dismiss victory state', () async {
        await provider.initializeLevel(1);
        
        // We can't easily create a victory state without complex setup,
        // so we'll just test the dismiss functionality
        provider.dismissVictory();

        // Assert - should not crash and should maintain idle state
        expect(provider.uiState, GameUIState.idle);
        expect(provider.feedbackMessage, isNull);
      });
      
      test('should progress to next level', () async {
        await provider.initializeLevel(1);
        expect(provider.currentGameState?.levelId, equals(1));
        
        // Act
        await provider.progressToNextLevel();
        
        // Assert
        expect(provider.currentGameState?.levelId, equals(2));
      });
      
      test('should restart current level', () async {
        await provider.initializeLevel(1);
        final originalLevelId = provider.currentGameState?.levelId;
        
        // Act
        await provider.restartCurrentLevel();
        
        // Assert
        expect(provider.currentGameState?.levelId, equals(originalLevelId));
        expect(provider.currentGameState?.moveCount, equals(0));
        expect(provider.currentGameState?.moveHistory, isEmpty);
      });
    });

    group('State Management Integration', () {
      test('should maintain consistent state during operations', () async {
        // Initialize level
        await provider.initializeLevel(1);
        expect(provider.isGameActive, true);

        // Select container
        final nonEmptyContainer = provider.currentGameState!.containers
            .firstWhere((c) => !c.isEmpty);
        await provider.selectContainer(nonEmptyContainer.id);
        expect(provider.selectedContainerId, nonEmptyContainer.id);

        // Reset level
        await provider.resetLevel();
        expect(provider.selectedContainerId, isNull);
        expect(provider.uiState, GameUIState.idle);
        expect(provider.isGameActive, true);
      });

      test('should handle multiple rapid operations gracefully', () async {
        await provider.initializeLevel(1);

        // Perform multiple operations rapidly
        final containers = provider.currentGameState!.containers;
        final nonEmptyContainer = containers.firstWhere((c) => !c.isEmpty);
        final emptyContainer = containers.firstWhere((c) => c.isEmpty);

        // These operations should not interfere with each other
        await Future.wait([
          provider.selectContainer(nonEmptyContainer.id),
          provider.selectContainer(emptyContainer.id),
          provider.saveGameState(),
        ]);

        // Should maintain consistent state
        expect(provider.loadingState, GameLoadingState.idle);
        expect(provider.hasError, false);
      });
    });

    group('Reactive UI Updates', () {
      test('should notify listeners on state changes', () async {
        bool notified = false;
        provider.addListener(() {
          notified = true;
        });

        // Act
        await provider.initializeLevel(1);

        // Assert
        expect(notified, true);
      });

      test('should notify listeners on container selection', () async {
        await provider.initializeLevel(1);
        
        bool notified = false;
        provider.addListener(() {
          notified = true;
        });

        final nonEmptyContainer = provider.currentGameState!.containers
            .firstWhere((c) => !c.isEmpty);

        // Act
        await provider.selectContainer(nonEmptyContainer.id);

        // Assert
        expect(notified, true);
      });
    });
  });
}

/// Mock level generator that throws errors for testing
class _ErrorLevelGenerator implements LevelGenerator {
  @override
  Level generateLevel(int levelId, int difficulty, int containerCount, int colorCount) {
    throw Exception('Test error in level generation');
  }

  @override
  Level generateUniqueLevel(int levelId, int difficulty, int containerCount, int colorCount, List<Level> existingLevels) {
    throw Exception('Test error in unique level generation');
  }

  @override
  bool validateLevel(Level level) {
    return false;
  }

  @override
  bool isLevelSimilar(Level newLevel, List<Level> existingLevels) {
    return false;
  }

  @override
  String generateLevelSignature(Level level) {
    return 'error-signature';
  }

  @override
  List<Level> generateLevelSeries(int startId, int count, {int startDifficulty = 1}) {
    throw Exception('Test error in level series generation');
  }
}