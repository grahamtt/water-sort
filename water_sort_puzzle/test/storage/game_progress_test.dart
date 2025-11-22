import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/game_state.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/storage/game_progress.dart';

void main() {
  group('GameProgress', () {
    late GameProgress gameProgress;
    late GameState testGameState;
    
    setUp(() {
      gameProgress = GameProgress.fromSets();
      
      // Create a test game state
      final containers = [
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: LiquidColor.red, volume: 2),
            LiquidLayer(color: LiquidColor.blue, volume: 2),
          ],
        ),
        Container(id: 2, capacity: 4, liquidLayers: []),
      ];
      
      testGameState = GameState.initial(
        levelId: 1,
        containers: containers,
      );
    });
    
    group('initialization', () {
      test('should have default values', () {
        expect(gameProgress.unlockedLevels, equals({1}));
        expect(gameProgress.completedLevels, isEmpty);
        expect(gameProgress.currentLevel, isNull);
        expect(gameProgress.savedGameState, isNull);
        expect(gameProgress.bestScores, isEmpty);
        expect(gameProgress.completionTimes, isEmpty);
        expect(gameProgress.perfectCompletions, equals(0));
        expect(gameProgress.lastPlayed, isNull);
      });
      
      test('should have level 1 unlocked by default', () {
        expect(gameProgress.isLevelUnlocked(1), isTrue);
        expect(gameProgress.isLevelUnlocked(2), isFalse);
      });
    });
    
    group('level management', () {
      test('should unlock levels correctly', () {
        final updated = gameProgress.unlockLevel(2);
        
        expect(updated.isLevelUnlocked(1), isTrue);
        expect(updated.isLevelUnlocked(2), isTrue);
        expect(updated.isLevelUnlocked(3), isFalse);
        expect(updated.lastPlayed, isNotNull);
      });
      
      test('should complete levels correctly', () {
        final updated = gameProgress.completeLevel(
          levelId: 1,
          moves: 5,
          timeInSeconds: 120,
          minimumPossibleMoves: 4,
        );
        
        expect(updated.isLevelCompleted(1), isTrue);
        expect(updated.isLevelUnlocked(2), isTrue);
        expect(updated.getBestScore(1), equals(5));
        expect(updated.getCompletionTime(1), equals(120));
        expect(updated.perfectCompletions, equals(0)); // Not perfect
        expect(updated.savedGameState, isNull); // Cleared on completion
        expect(updated.currentLevel, isNull); // Cleared on completion
      });
      
      test('should track perfect completions', () {
        final updated = gameProgress.completeLevel(
          levelId: 1,
          moves: 4,
          timeInSeconds: 120,
          minimumPossibleMoves: 4,
        );
        
        expect(updated.perfectCompletions, equals(1));
      });
      
      test('should update best scores', () {
        // First completion
        var updated = gameProgress.completeLevel(
          levelId: 1,
          moves: 10,
          timeInSeconds: 200,
        );
        expect(updated.getBestScore(1), equals(10));
        expect(updated.getCompletionTime(1), equals(200));
        
        // Better score
        updated = updated.completeLevel(
          levelId: 1,
          moves: 8,
          timeInSeconds: 150,
        );
        expect(updated.getBestScore(1), equals(8));
        expect(updated.getCompletionTime(1), equals(150));
        
        // Worse score (should not update)
        updated = updated.completeLevel(
          levelId: 1,
          moves: 12,
          timeInSeconds: 250,
        );
        expect(updated.getBestScore(1), equals(8));
        expect(updated.getCompletionTime(1), equals(150));
      });
    });
    
    group('game state management', () {
      test('should save game state correctly', () {
        final updated = gameProgress.saveGameState(testGameState);
        
        expect(updated.currentLevel, equals(1));
        expect(updated.savedGameState, equals(testGameState));
        expect(updated.hasSavedGame, isTrue);
        expect(updated.lastPlayed, isNotNull);
      });
      
      test('should clear saved game state', () {
        final withSaved = gameProgress.saveGameState(testGameState);
        expect(withSaved.hasSavedGame, isTrue);
        
        final cleared = withSaved.clearSavedGameState();
        expect(cleared.hasSavedGame, isFalse);
        expect(cleared.savedGameState, isNull);
        expect(cleared.currentLevel, isNull);
      });
    });
    
    group('progress tracking', () {
      test('should calculate highest unlocked level', () {
        var progress = GameProgress.fromSets(unlockedLevels: {1, 3, 5, 2});
        expect(progress.highestUnlockedLevel, equals(5));
        
        progress = GameProgress.fromSets(unlockedLevels: {});
        expect(progress.highestUnlockedLevel, equals(1));
      });
      
      test('should calculate total completed levels', () {
        final progress = GameProgress.fromSets(completedLevels: {1, 2, 3, 5});
        expect(progress.totalCompletedLevels, equals(4));
      });
      
      test('should calculate completion percentage', () {
        final progress = GameProgress.fromSets(completedLevels: {1, 2, 3});
        
        expect(progress.getCompletionPercentage(10), equals(30.0));
        expect(progress.getCompletionPercentage(0), equals(0.0));
      });
    });
    
    group('copyWith', () {
      test('should create copy with updated values', () {
        final original = GameProgress.fromSets(
          unlockedLevels: {1, 2},
          completedLevels: {1},
          currentLevel: 2,
          perfectCompletions: 1,
        );
        
        final updated = original.copyWith(
          unlockedLevels: {1, 2, 3},
          perfectCompletions: 2,
        );
        
        expect(updated.unlockedLevels, equals({1, 2, 3}));
        expect(updated.completedLevels, equals({1})); // Unchanged
        expect(updated.currentLevel, equals(2)); // Unchanged
        expect(updated.perfectCompletions, equals(2)); // Updated
      });
      
      test('should clear values when specified', () {
        final original = GameProgress.fromSets(
          currentLevel: 2,
          savedGameState: testGameState,
        );
        
        final updated = original.copyWith(
          clearCurrentLevel: true,
          clearSavedGameState: true,
        );
        
        expect(updated.currentLevel, isNull);
        expect(updated.savedGameState, isNull);
      });
    });
    
    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        final progress = GameProgress.fromSets(
          unlockedLevels: {1, 2, 3},
          completedLevels: {1, 2},
          currentLevel: 3,
          bestScores: {1: 5, 2: 8},
          completionTimes: {1: 120, 2: 180},
          perfectCompletions: 1,
          lastPlayed: DateTime(2023, 12, 25, 10, 30),
        );
        
        final json = progress.toJson();
        
        expect(json['unlockedLevelsList'], isA<List>());
        expect(json['completedLevelsList'], isA<List>());
        expect(json['currentLevel'], equals(3));
        expect(json['bestScores'], isA<Map>());
        expect(json['completionTimes'], isA<Map>());
        expect(json['perfectCompletions'], equals(1));
        expect(json['lastPlayed'], isA<String>());
      });
      
      test('should deserialize from JSON correctly', () {
        final originalProgress = GameProgress.fromSets(
          unlockedLevels: {1, 2, 3},
          completedLevels: {1, 2},
          currentLevel: 3,
          bestScores: {1: 5, 2: 8},
          completionTimes: {1: 120, 2: 180},
          perfectCompletions: 1,
          lastPlayed: DateTime(2023, 12, 25, 10, 30),
        );
        
        final json = originalProgress.toJson();
        final deserializedProgress = GameProgress.fromJson(json);
        
        expect(deserializedProgress.unlockedLevels, equals(originalProgress.unlockedLevels));
        expect(deserializedProgress.completedLevels, equals(originalProgress.completedLevels));
        expect(deserializedProgress.currentLevel, equals(originalProgress.currentLevel));
        expect(deserializedProgress.bestScores, equals(originalProgress.bestScores));
        expect(deserializedProgress.completionTimes, equals(originalProgress.completionTimes));
        expect(deserializedProgress.perfectCompletions, equals(originalProgress.perfectCompletions));
        expect(deserializedProgress.lastPlayed, equals(originalProgress.lastPlayed));
      });
    });
    
    group('equality and hashCode', () {
      test('should be equal when all properties match', () {
        final progress1 = GameProgress.fromSets(
          unlockedLevels: {1, 2},
          completedLevels: {1},
          currentLevel: 2,
          perfectCompletions: 1,
        );
        
        final progress2 = GameProgress.fromSets(
          unlockedLevels: {1, 2},
          completedLevels: {1},
          currentLevel: 2,
          perfectCompletions: 1,
        );
        
        expect(progress1, equals(progress2));
        expect(progress1.hashCode, equals(progress2.hashCode));
      });
      
      test('should not be equal when properties differ', () {
        final progress1 = GameProgress.fromSets(unlockedLevels: {1, 2});
        final progress2 = GameProgress.fromSets(unlockedLevels: {1, 3});
        
        expect(progress1, isNot(equals(progress2)));
      });
    });
    
    group('toString', () {
      test('should provide meaningful string representation', () {
        final progress = GameProgress.fromSets(
          unlockedLevels: {1, 2, 3},
          completedLevels: {1, 2},
          currentLevel: 3,
          perfectCompletions: 1,
        );
        
        final string = progress.toString();
        
        expect(string, contains('unlocked: 3'));
        expect(string, contains('completed: 2'));
        expect(string, contains('current: 3'));
        expect(string, contains('perfect: 1'));
      });
    });
  });
}