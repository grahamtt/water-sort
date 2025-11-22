import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/models.dart';
import 'package:water_sort_puzzle/services/level_progression.dart';

void main() {
  group('LevelProgress', () {
    test('should create initial progress correctly', () {
      final progress = LevelProgress.initial();
      
      expect(progress.unlockedLevels, equals({1}));
      expect(progress.completedLevels, isEmpty);
      expect(progress.bestScores, isEmpty);
      expect(progress.completionTimes, isEmpty);
      expect(progress.currentLevel, equals(1));
    });
    
    test('should check level unlock status', () {
      const progress = LevelProgress(
        unlockedLevels: {1, 2, 3},
        completedLevels: {1, 2},
      );
      
      expect(progress.isLevelUnlocked(1), isTrue);
      expect(progress.isLevelUnlocked(2), isTrue);
      expect(progress.isLevelUnlocked(3), isTrue);
      expect(progress.isLevelUnlocked(4), isFalse);
    });
    
    test('should check level completion status', () {
      const progress = LevelProgress(
        unlockedLevels: {1, 2, 3},
        completedLevels: {1, 2},
      );
      
      expect(progress.isLevelCompleted(1), isTrue);
      expect(progress.isLevelCompleted(2), isTrue);
      expect(progress.isLevelCompleted(3), isFalse);
    });
    
    test('should get best scores and completion times', () {
      const progress = LevelProgress(
        bestScores: {1: 5, 2: 8},
        completionTimes: {1: 30000, 2: 45000},
      );
      
      expect(progress.getBestScore(1), equals(5));
      expect(progress.getBestScore(2), equals(8));
      expect(progress.getBestScore(3), isNull);
      
      expect(progress.getCompletionTime(1), equals(30000));
      expect(progress.getCompletionTime(2), equals(45000));
      expect(progress.getCompletionTime(3), isNull);
    });
    
    test('should calculate highest unlocked level', () {
      const progress = LevelProgress(unlockedLevels: {1, 3, 5, 2});
      
      expect(progress.highestUnlockedLevel, equals(5));
    });
    
    test('should calculate total completed levels', () {
      const progress = LevelProgress(completedLevels: {1, 2, 5, 8});
      
      expect(progress.totalCompletedLevels, equals(4));
    });
    
    test('should calculate completion percentage', () {
      const progress = LevelProgress(completedLevels: {1, 2, 3});
      
      expect(progress.getCompletionPercentage(10), equals(0.3));
      expect(progress.getCompletionPercentage(0), equals(0.0));
    });
    
    test('should support copyWith', () {
      const original = LevelProgress(
        unlockedLevels: {1, 2},
        completedLevels: {1},
        currentLevel: 2,
      );
      
      final copy = original.copyWith(
        unlockedLevels: {1, 2, 3},
        currentLevel: 3,
      );
      
      expect(copy.unlockedLevels, equals({1, 2, 3}));
      expect(copy.completedLevels, equals({1}));
      expect(copy.currentLevel, equals(3));
    });
  });
  
  group('LevelProgressionManager', () {
    late LevelProgressionManager manager;
    late List<Level> testLevels;
    
    setUp(() {
      testLevels = [
        Level(
          id: 1,
          difficulty: 1,
          containerCount: 3,
          colorCount: 2,
          initialContainers: [],
          tags: ['tutorial'],
        ),
        Level(
          id: 2,
          difficulty: 2,
          containerCount: 4,
          colorCount: 2,
          initialContainers: [],
        ),
        Level(
          id: 3,
          difficulty: 3,
          containerCount: 4,
          colorCount: 3,
          initialContainers: [],
        ),
        Level(
          id: 101,
          difficulty: 5,
          containerCount: 5,
          colorCount: 3,
          initialContainers: [],
          tags: ['bonus'],
        ),
      ];
      
      manager = LevelProgressionManager();
      manager.addLevels(testLevels);
    });
    
    test('should initialize with default progress', () {
      final progress = manager.progress;
      
      expect(progress.unlockedLevels, equals({1}));
      expect(progress.currentLevel, equals(1));
    });
    
    test('should add and retrieve levels', () {
      expect(manager.availableLevels.length, equals(4));
      expect(manager.getLevel(1), equals(testLevels[0]));
      expect(manager.getLevel(999), isNull);
    });
    
    test('should get unlocked levels in order', () {
      manager.unlockLevel(2);
      manager.unlockLevel(3);
      
      final unlockedLevels = manager.getUnlockedLevels();
      
      expect(unlockedLevels.length, equals(3));
      expect(unlockedLevels[0].id, equals(1));
      expect(unlockedLevels[1].id, equals(2));
      expect(unlockedLevels[2].id, equals(3));
    });
    
    test('should get completed levels', () {
      manager.completeLevel(1, 5, 30000);
      
      final completedLevels = manager.getCompletedLevels();
      
      expect(completedLevels.length, equals(1));
      expect(completedLevels[0].id, equals(1));
    });
    
    test('should get next level to play', () {
      // Initially, level 1 should be next
      expect(manager.getNextLevel()?.id, equals(1));
      
      // After completing level 1, level 2 should be next
      manager.completeLevel(1, 5, 30000);
      expect(manager.getNextLevel()?.id, equals(2));
      
      // After completing level 2, level 3 should be next
      manager.completeLevel(2, 7, 45000);
      expect(manager.getNextLevel()?.id, equals(3));
      
      // After completing all unlocked levels, should return null
      manager.completeLevel(3, 10, 60000);
      expect(manager.getNextLevel(), isNull);
    });
    
    test('should complete level and unlock next level', () {
      final newProgress = manager.completeLevel(1, 5, 30000);
      
      expect(newProgress.isLevelCompleted(1), isTrue);
      expect(newProgress.isLevelUnlocked(2), isTrue);
      expect(newProgress.getBestScore(1), equals(5));
      expect(newProgress.getCompletionTime(1), equals(30000));
      expect(newProgress.currentLevel, equals(2));
    });
    
    test('should update best score when completing level multiple times', () {
      // Complete level with 10 moves
      manager.completeLevel(1, 10, 60000);
      expect(manager.progress.getBestScore(1), equals(10));
      
      // Complete again with fewer moves
      manager.completeLevel(1, 7, 45000);
      expect(manager.progress.getBestScore(1), equals(7));
      expect(manager.progress.getCompletionTime(1), equals(45000));
      
      // Complete again with more moves (should not update best score)
      manager.completeLevel(1, 12, 30000);
      expect(manager.progress.getBestScore(1), equals(7));
      expect(manager.progress.getCompletionTime(1), equals(30000)); // Should update to better time
    });
    
    test('should unlock bonus levels at milestones', () {
      // Add more levels to test milestone unlocking
      for (int i = 4; i <= 15; i++) {
        manager.addLevel(Level(
          id: i,
          difficulty: i ~/ 3 + 1,
          containerCount: 4,
          colorCount: 2,
          initialContainers: [],
        ));
      }
      
      // Complete levels 1-3 first to unlock more levels
      manager.completeLevel(1, 5, 30000);
      manager.completeLevel(2, 6, 35000);
      manager.completeLevel(3, 7, 40000);
      
      // Complete levels 4-10 to reach the milestone
      for (int i = 4; i <= 10; i++) {
        manager.completeLevel(i, 5, 30000);
      }
      
      // Should unlock bonus level 101
      expect(manager.progress.isLevelUnlocked(101), isTrue);
    });
    
    test('should throw error when completing unlocked level', () {
      expect(
        () => manager.completeLevel(2, 5, 30000),
        throwsArgumentError,
      );
    });
    
    test('should unlock specific level', () {
      manager.unlockLevel(3);
      
      expect(manager.progress.isLevelUnlocked(3), isTrue);
    });
    
    test('should throw error when unlocking non-existent level', () {
      expect(
        () => manager.unlockLevel(999),
        throwsArgumentError,
      );
    });
    
    test('should set current level', () {
      manager.unlockLevel(2);
      manager.setCurrentLevel(2);
      
      expect(manager.progress.currentLevel, equals(2));
    });
    
    test('should throw error when setting current level to unlocked level', () {
      expect(
        () => manager.setCurrentLevel(2),
        throwsArgumentError,
      );
    });
    
    test('should reset progress', () {
      manager.completeLevel(1, 5, 30000);
      manager.resetProgress();
      
      final progress = manager.progress;
      expect(progress.unlockedLevels, equals({1}));
      expect(progress.completedLevels, isEmpty);
      expect(progress.currentLevel, equals(1));
    });
    
    test('should update progress', () {
      const newProgress = LevelProgress(
        unlockedLevels: {1, 2, 3},
        completedLevels: {1, 2},
        currentLevel: 3,
      );
      
      manager.updateProgress(newProgress);
      
      expect(manager.progress, equals(newProgress));
    });
    
    test('should generate progress statistics', () {
      manager.completeLevel(1, 5, 30000);
      manager.completeLevel(2, 8, 45000);
      
      final stats = manager.getProgressStatistics();
      
      expect(stats['totalLevelsAvailable'], equals(4));
      expect(stats['totalLevelsUnlocked'], equals(3)); // 1, 2, 3
      expect(stats['totalLevelsCompleted'], equals(2));
      expect(stats['completionPercentage'], equals(0.5));
      expect(stats['highestUnlockedLevel'], equals(3));
      expect(stats['currentLevel'], equals(3));
      expect(stats['averageMovesPerLevel'], equals(6.5)); // (5 + 8) / 2
      expect(stats['totalPlayTimeMs'], equals(75000)); // 30000 + 45000
    });
    
    test('should handle empty progress in statistics', () {
      final emptyManager = LevelProgressionManager();
      final stats = emptyManager.getProgressStatistics();
      
      expect(stats['totalLevelsCompleted'], equals(0));
      expect(stats['averageMovesPerLevel'], equals(0.0));
      expect(stats['totalPlayTimeMs'], equals(0));
    });
  });
}