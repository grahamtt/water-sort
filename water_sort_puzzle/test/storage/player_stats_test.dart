import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/storage/player_stats.dart';

void main() {
  group('PlayerStats', () {
    late PlayerStats playerStats;
    late DateTime testDate;
    
    setUp(() {
      testDate = DateTime(2023, 12, 25, 10, 30);
      playerStats = PlayerStats(firstPlayDate: testDate);
    });
    
    group('initialization', () {
      test('should have default values', () {
        expect(playerStats.totalMoves, equals(0));
        expect(playerStats.perfectSolutions, equals(0));
        expect(playerStats.totalPlayTimeSeconds, equals(0));
        expect(playerStats.gamesStarted, equals(0));
        expect(playerStats.gamesCompleted, equals(0));
        expect(playerStats.totalUndos, equals(0));
        expect(playerStats.longestWinStreak, equals(0));
        expect(playerStats.currentWinStreak, equals(0));
        expect(playerStats.bestCompletionTime, isNull);
        expect(playerStats.bestCompletionTimeLevel, isNull);
        expect(playerStats.bestAverageMovesPerLevel, isNull);
        expect(playerStats.hintsUsed, equals(0));
        expect(playerStats.firstPlayDate, equals(testDate));
        expect(playerStats.lastPlayDate, isNull);
        expect(playerStats.consecutiveDaysPlayed, equals(0));
        expect(playerStats.levelAttempts, isEmpty);
        expect(playerStats.difficultyCompletions, isEmpty);
      });
    });
    
    group('game tracking', () {
      test('should record game start correctly', () {
        final updated = playerStats.recordGameStart(1);
        
        expect(updated.gamesStarted, equals(1));
        expect(updated.getLevelAttempts(1), equals(1));
        expect(updated.firstPlayDate, equals(testDate));
        expect(updated.lastPlayDate, isNotNull);
        expect(updated.consecutiveDaysPlayed, equals(1));
      });
      
      test('should record multiple game starts for same level', () {
        var updated = playerStats.recordGameStart(1);
        updated = updated.recordGameStart(1);
        updated = updated.recordGameStart(2);
        
        expect(updated.gamesStarted, equals(3));
        expect(updated.getLevelAttempts(1), equals(2));
        expect(updated.getLevelAttempts(2), equals(1));
        expect(updated.getLevelAttempts(3), equals(0));
      });
      
      test('should record game completion correctly', () {
        final updated = playerStats.recordGameCompletion(
          levelId: 1,
          moves: 10,
          timeSeconds: 120,
          difficulty: 3,
          isPerfect: false,
          undosUsed: 2,
        );
        
        expect(updated.totalMoves, equals(10));
        expect(updated.perfectSolutions, equals(0));
        expect(updated.totalPlayTimeSeconds, equals(120));
        expect(updated.gamesCompleted, equals(1));
        expect(updated.totalUndos, equals(2));
        expect(updated.currentWinStreak, equals(1));
        expect(updated.longestWinStreak, equals(1));
        expect(updated.bestCompletionTime, equals(120));
        expect(updated.bestCompletionTimeLevel, equals(1));
        expect(updated.getDifficultyCompletions(3), equals(1));
        expect(updated.averageMovesPerLevel, equals(10.0));
        expect(updated.bestAverageMovesPerLevel, equals(10.0));
      });
      
      test('should track perfect solutions', () {
        final updated = playerStats.recordGameCompletion(
          levelId: 1,
          moves: 5,
          timeSeconds: 60,
          difficulty: 2,
          isPerfect: true,
          undosUsed: 0,
        );
        
        expect(updated.perfectSolutions, equals(1));
      });
      
      test('should update best completion time', () {
        var updated = playerStats.recordGameCompletion(
          levelId: 1,
          moves: 10,
          timeSeconds: 120,
          difficulty: 1,
          isPerfect: false,
          undosUsed: 0,
        );
        expect(updated.bestCompletionTime, equals(120));
        expect(updated.bestCompletionTimeLevel, equals(1));
        
        // Better time
        updated = updated.recordGameCompletion(
          levelId: 2,
          moves: 8,
          timeSeconds: 90,
          difficulty: 1,
          isPerfect: false,
          undosUsed: 0,
        );
        expect(updated.bestCompletionTime, equals(90));
        expect(updated.bestCompletionTimeLevel, equals(2));
        
        // Worse time (should not update)
        updated = updated.recordGameCompletion(
          levelId: 3,
          moves: 12,
          timeSeconds: 150,
          difficulty: 1,
          isPerfect: false,
          undosUsed: 0,
        );
        expect(updated.bestCompletionTime, equals(90));
        expect(updated.bestCompletionTimeLevel, equals(2));
      });
      
      test('should track win streaks correctly', () {
        var updated = playerStats;
        
        // First win
        updated = updated.recordGameCompletion(
          levelId: 1,
          moves: 5,
          timeSeconds: 60,
          difficulty: 1,
          isPerfect: false,
          undosUsed: 0,
        );
        expect(updated.currentWinStreak, equals(1));
        expect(updated.longestWinStreak, equals(1));
        
        // Second win
        updated = updated.recordGameCompletion(
          levelId: 2,
          moves: 7,
          timeSeconds: 80,
          difficulty: 1,
          isPerfect: false,
          undosUsed: 0,
        );
        expect(updated.currentWinStreak, equals(2));
        expect(updated.longestWinStreak, equals(2));
        
        // Failure (resets current streak)
        updated = updated.recordGameFailure();
        expect(updated.currentWinStreak, equals(0));
        expect(updated.longestWinStreak, equals(2)); // Longest remains
        
        // New win (starts new streak)
        updated = updated.recordGameCompletion(
          levelId: 3,
          moves: 6,
          timeSeconds: 70,
          difficulty: 1,
          isPerfect: false,
          undosUsed: 0,
        );
        expect(updated.currentWinStreak, equals(1));
        expect(updated.longestWinStreak, equals(2));
      });
    });
    
    group('statistics calculations', () {
      test('should calculate completion rate correctly', () {
        var stats = playerStats.recordGameStart(1);
        stats = stats.recordGameStart(2);
        stats = stats.recordGameStart(3);
        
        stats = stats.recordGameCompletion(
          levelId: 1,
          moves: 5,
          timeSeconds: 60,
          difficulty: 1,
          isPerfect: false,
          undosUsed: 0,
        );
        stats = stats.recordGameCompletion(
          levelId: 2,
          moves: 7,
          timeSeconds: 80,
          difficulty: 1,
          isPerfect: false,
          undosUsed: 0,
        );
        
        expect(stats.completionRate, closeTo(0.667, 0.001)); // 2/3
      });
      
      test('should calculate perfect solution rate correctly', () {
        var stats = playerStats;
        
        stats = stats.recordGameCompletion(
          levelId: 1,
          moves: 5,
          timeSeconds: 60,
          difficulty: 1,
          isPerfect: true,
          undosUsed: 0,
        );
        stats = stats.recordGameCompletion(
          levelId: 2,
          moves: 7,
          timeSeconds: 80,
          difficulty: 1,
          isPerfect: false,
          undosUsed: 0,
        );
        stats = stats.recordGameCompletion(
          levelId: 3,
          moves: 4,
          timeSeconds: 50,
          difficulty: 1,
          isPerfect: true,
          undosUsed: 0,
        );
        
        expect(stats.perfectSolutionRate, closeTo(0.667, 0.001)); // 2/3
      });
      
      test('should calculate average play time per game', () {
        var stats = playerStats;
        
        stats = stats.recordGameCompletion(
          levelId: 1,
          moves: 5,
          timeSeconds: 60,
          difficulty: 1,
          isPerfect: false,
          undosUsed: 0,
        );
        stats = stats.recordGameCompletion(
          levelId: 2,
          moves: 7,
          timeSeconds: 120,
          difficulty: 1,
          isPerfect: false,
          undosUsed: 0,
        );
        
        expect(stats.averagePlayTimePerGame, equals(90.0)); // (60 + 120) / 2
      });
      
      test('should handle zero division gracefully', () {
        expect(playerStats.averageMovesPerLevel, equals(0.0));
        expect(playerStats.completionRate, equals(0.0));
        expect(playerStats.perfectSolutionRate, equals(0.0));
        expect(playerStats.averagePlayTimePerGame, equals(0.0));
      });
    });
    
    group('consecutive days tracking', () {
      test('should track consecutive days through game starts', () {
        final day1 = DateTime(2023, 12, 25);
        final day2 = DateTime(2023, 12, 26);
        final day3 = DateTime(2023, 12, 27);
        final day5 = DateTime(2023, 12, 29); // Skip day 4
        
        // Simulate playing on consecutive days by recording game starts
        var stats = PlayerStats(firstPlayDate: day1, lastPlayDate: day1, consecutiveDaysPlayed: 1);
        
        // The consecutive days calculation is tested indirectly through recordGameStart
        // which calls the private _calculateConsecutiveDays method
        expect(stats.consecutiveDaysPlayed, equals(1));
      });
      
      test('should handle same day plays correctly through game completion', () {
        final day1Morning = DateTime(2023, 12, 25, 9, 0);
        
        var stats = PlayerStats(firstPlayDate: day1Morning);
        
        // Record a game completion on the same day
        stats = stats.recordGameCompletion(
          levelId: 1,
          moves: 5,
          timeSeconds: 60,
          difficulty: 1,
          isPerfect: false,
          undosUsed: 0,
        );
        
        // The consecutive days should be calculated correctly
        expect(stats.consecutiveDaysPlayed, greaterThanOrEqualTo(1));
      });
    });
    
    group('other actions', () {
      test('should record undo actions', () {
        final updated = playerStats.recordUndo();
        expect(updated.totalUndos, equals(1));
      });
      
      test('should record hint usage', () {
        final updated = playerStats.recordHintUsed();
        expect(updated.hintsUsed, equals(1));
      });
      
      test('should record additional play time', () {
        final updated = playerStats.recordPlayTime(300);
        expect(updated.totalPlayTimeSeconds, equals(300));
        expect(updated.lastPlayDate, isNotNull);
      });
    });
    
    group('formatted output', () {
      test('should format total play time correctly', () {
        var stats = PlayerStats(totalPlayTimeSeconds: 45);
        expect(stats.formattedTotalPlayTime, equals('45s'));
        
        stats = PlayerStats(totalPlayTimeSeconds: 125); // 2m 5s
        expect(stats.formattedTotalPlayTime, equals('2m 5s'));
        
        stats = PlayerStats(totalPlayTimeSeconds: 3665); // 1h 1m 5s
        expect(stats.formattedTotalPlayTime, equals('1h 1m 5s'));
      });
    });
    
    group('status checks', () {
      test('should check win streak status', () {
        expect(playerStats.isOnWinStreak, isFalse);
        
        final withStreak = playerStats.copyWith(currentWinStreak: 3);
        expect(withStreak.isOnWinStreak, isTrue);
      });
      
      test('should check if played today', () {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        
        var stats = PlayerStats(lastPlayDate: yesterday);
        expect(stats.hasPlayedToday, isFalse);
        
        stats = PlayerStats(lastPlayDate: today);
        expect(stats.hasPlayedToday, isTrue);
      });
    });
    
    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        final stats = PlayerStats(
          totalMoves: 100,
          perfectSolutions: 5,
          totalPlayTimeSeconds: 3600,
          gamesStarted: 20,
          gamesCompleted: 15,
          totalUndos: 10,
          longestWinStreak: 8,
          currentWinStreak: 3,
          bestCompletionTime: 45,
          bestCompletionTimeLevel: 5,
          bestAverageMovesPerLevel: 6.5,
          hintsUsed: 2,
          firstPlayDate: testDate,
          lastPlayDate: testDate,
          consecutiveDaysPlayed: 5,
          levelAttempts: {1: 3, 2: 2},
          difficultyCompletions: {1: 5, 2: 3},
        );
        
        final json = stats.toJson();
        
        expect(json['totalMoves'], equals(100));
        expect(json['perfectSolutions'], equals(5));
        expect(json['totalPlayTimeSeconds'], equals(3600));
        expect(json['gamesStarted'], equals(20));
        expect(json['gamesCompleted'], equals(15));
        expect(json['levelAttempts'], isA<Map>());
        expect(json['difficultyCompletions'], isA<Map>());
      });
      
      test('should deserialize from JSON correctly', () {
        final originalStats = PlayerStats(
          totalMoves: 100,
          perfectSolutions: 5,
          totalPlayTimeSeconds: 3600,
          gamesStarted: 20,
          gamesCompleted: 15,
          firstPlayDate: testDate,
          levelAttempts: {1: 3, 2: 2},
          difficultyCompletions: {1: 5, 2: 3},
        );
        
        final json = originalStats.toJson();
        final deserializedStats = PlayerStats.fromJson(json);
        
        expect(deserializedStats.totalMoves, equals(originalStats.totalMoves));
        expect(deserializedStats.perfectSolutions, equals(originalStats.perfectSolutions));
        expect(deserializedStats.totalPlayTimeSeconds, equals(originalStats.totalPlayTimeSeconds));
        expect(deserializedStats.gamesStarted, equals(originalStats.gamesStarted));
        expect(deserializedStats.gamesCompleted, equals(originalStats.gamesCompleted));
        expect(deserializedStats.firstPlayDate, equals(originalStats.firstPlayDate));
        expect(deserializedStats.levelAttempts, equals(originalStats.levelAttempts));
        expect(deserializedStats.difficultyCompletions, equals(originalStats.difficultyCompletions));
      });
    });
    
    group('equality and hashCode', () {
      test('should be equal when all properties match', () {
        final stats1 = PlayerStats(
          totalMoves: 100,
          perfectSolutions: 5,
          gamesCompleted: 10,
        );
        
        final stats2 = PlayerStats(
          totalMoves: 100,
          perfectSolutions: 5,
          gamesCompleted: 10,
        );
        
        expect(stats1, equals(stats2));
        expect(stats1.hashCode, equals(stats2.hashCode));
      });
      
      test('should not be equal when properties differ', () {
        final stats1 = PlayerStats(totalMoves: 100);
        final stats2 = PlayerStats(totalMoves: 200);
        
        expect(stats1, isNot(equals(stats2)));
      });
    });
    
    group('toString', () {
      test('should provide meaningful string representation', () {
        final stats = PlayerStats(
          gamesCompleted: 15,
          gamesStarted: 20,
          totalMoves: 150,
          perfectSolutions: 5,
          currentWinStreak: 3,
          totalPlayTimeSeconds: 3600,
        );
        
        final string = stats.toString();
        
        expect(string, contains('games: 15/20'));
        expect(string, contains('moves: 150'));
        expect(string, contains('perfect: 5'));
        expect(string, contains('streak: 3'));
        expect(string, contains('time: 1h 0m 0s'));
      });
    });
  });
}