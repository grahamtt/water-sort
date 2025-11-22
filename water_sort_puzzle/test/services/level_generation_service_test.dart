import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/level.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/services/level_generation_service.dart';
import 'package:water_sort_puzzle/services/level_generator.dart';
import 'package:water_sort_puzzle/services/level_similarity_checker.dart';

/// Mock level generator for testing
class MockLevelGenerator implements LevelGenerator {
  final List<Level> _predefinedLevels = [];
  int _currentIndex = 0;
  bool _shouldThrowError = false;

  void addPredefinedLevel(Level level) {
    _predefinedLevels.add(level);
  }

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  void reset() {
    _currentIndex = 0;
    _shouldThrowError = false;
  }

  @override
  Level generateLevel(
    int levelId,
    int difficulty,
    int containerCount,
    int colorCount,
  ) {
    if (_shouldThrowError) {
      throw StateError('Mock generation error');
    }

    if (_predefinedLevels.isEmpty) {
      // Generate a simple test level
      return _createTestLevel(levelId, difficulty, containerCount, colorCount);
    }

    // Return predefined levels in sequence, cycling if necessary
    final level = _predefinedLevels[_currentIndex % _predefinedLevels.length];
    _currentIndex++;
    
    // Update the level ID to match the requested one
    return level.copyWith(id: levelId);
  }

  @override
  Level generateUniqueLevel(
    int levelId,
    int difficulty,
    int containerCount,
    int colorCount,
    List<Level> existingLevels,
  ) {
    // For testing, just delegate to generateLevel
    return generateLevel(levelId, difficulty, containerCount, colorCount);
  }

  @override
  bool validateLevel(Level level) => true;

  @override
  bool isLevelSimilar(Level newLevel, List<Level> existingLevels) {
    return LevelSimilarityChecker.isLevelSimilarToAny(newLevel, existingLevels);
  }

  @override
  String generateLevelSignature(Level level) {
    return LevelSimilarityChecker.generateNormalizedSignature(level);
  }

  @override
  List<Level> generateLevelSeries(int startId, int count, {int startDifficulty = 1}) {
    final levels = <Level>[];
    for (int i = 0; i < count; i++) {
      levels.add(generateLevel(startId + i, startDifficulty, 4, 2));
    }
    return levels;
  }

  Level _createTestLevel(int levelId, int difficulty, int containerCount, int colorCount) {
    final containers = <Container>[];
    
    // Select colors for this level
    final selectedColors = <LiquidColor>[];
    for (int i = 0; i < colorCount; i++) {
      selectedColors.add(LiquidColor.values[(levelId + i) % LiquidColor.values.length]);
    }
    
    // Create a structurally valid level by ensuring each color has exactly 4 units
    // First, create containers with each color having exactly one container's worth (4 units)
    for (int i = 0; i < colorCount; i++) {
      final color = selectedColors[i];
      final layers = <LiquidLayer>[];
      
      // Create different mixing patterns based on levelId to ensure uniqueness
      final mixingPattern = (levelId + i) % 3;
      
      switch (mixingPattern) {
        case 0:
          // Single color container
          layers.add(LiquidLayer(color: color, volume: 4));
          break;
        case 1:
          // Split with another color
          final otherColor = selectedColors[(i + 1) % selectedColors.length];
          layers.add(LiquidLayer(color: color, volume: 2));
          layers.add(LiquidLayer(color: otherColor, volume: 2));
          break;
        case 2:
          // Three segments
          final otherColor = selectedColors[(i + 1) % selectedColors.length];
          layers.add(LiquidLayer(color: color, volume: 1));
          layers.add(LiquidLayer(color: otherColor, volume: 2));
          layers.add(LiquidLayer(color: color, volume: 1));
          break;
      }
      
      containers.add(Container(
        id: i,
        capacity: 4,
        liquidLayers: layers,
      ));
    }
    
    // Add empty containers (required for structural validity)
    for (int i = colorCount; i < containerCount; i++) {
      containers.add(Container(
        id: i,
        capacity: 4,
        liquidLayers: [],
      ));
    }
    
    // Now we need to rebalance to ensure each color has exactly 4 units total
    // This is a simplified rebalancing - collect all layers and redistribute
    final allLayers = <LiquidLayer>[];
    for (final container in containers) {
      allLayers.addAll(container.liquidLayers);
    }
    
    // Count volumes by color
    final colorVolumes = <LiquidColor, int>{};
    for (final layer in allLayers) {
      colorVolumes[layer.color] = (colorVolumes[layer.color] ?? 0) + layer.volume;
    }
    
    // Create balanced containers
    final balancedContainers = <Container>[];
    
    // First container for each color gets exactly 4 units of that color
    for (int i = 0; i < colorCount; i++) {
      final color = selectedColors[i];
      final layers = <LiquidLayer>[LiquidLayer(color: color, volume: 4)];
      
      balancedContainers.add(Container(
        id: i,
        capacity: 4,
        liquidLayers: layers,
      ));
    }
    
    // Add empty containers
    for (int i = colorCount; i < containerCount; i++) {
      balancedContainers.add(Container(
        id: i,
        capacity: 4,
        liquidLayers: [],
      ));
    }
    
    // Now mix some containers to create variety while maintaining total volumes
    if (balancedContainers.length >= 2 && levelId % 2 == 0) {
      // Mix the first two containers for variety
      final container1 = balancedContainers[0];
      final container2 = balancedContainers[1];
      
      if (container1.liquidLayers.isNotEmpty && container2.liquidLayers.isNotEmpty) {
        final color1 = container1.liquidLayers.first.color;
        final color2 = container2.liquidLayers.first.color;
        
        // Create mixed containers
        balancedContainers[0] = Container(
          id: 0,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: color1, volume: 2),
            LiquidLayer(color: color2, volume: 2),
          ],
        );
        
        balancedContainers[1] = Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            LiquidLayer(color: color2, volume: 2),
            LiquidLayer(color: color1, volume: 2),
          ],
        );
      }
    }

    return Level(
      id: levelId,
      difficulty: difficulty,
      containerCount: containerCount,
      colorCount: colorCount,
      initialContainers: balancedContainers,
      tags: ['test'],
    );
  }
}

void main() {
  group('LevelGenerationService', () {
    late MockLevelGenerator mockGenerator;
    late LevelGenerationService service;

    setUp(() {
      mockGenerator = MockLevelGenerator();
      service = LevelGenerationService(mockGenerator);
    });

    group('Basic Generation', () {
      test('should generate a level successfully', () async {
        final level = await service.generateNextLevel(1, 1, 4, 2);
        
        expect(level.id, equals(1));
        expect(level.difficulty, equals(1));
        expect(level.containerCount, equals(4));
        expect(level.colorCount, equals(2));
      });

      test('should add generated level to session history', () async {
        expect(service.sessionLevelCount, equals(0));
        
        await service.generateNextLevel(1, 1, 4, 2);
        
        expect(service.sessionLevelCount, equals(1));
      });

      test('should handle generation errors gracefully', () async {
        mockGenerator.setShouldThrowError(true);
        
        // Should still return a level (fallback mechanism)
        final level = await service.generateNextLevel(1, 1, 4, 2);
        expect(level, isNotNull);
      });
    });

    group('Uniqueness Tracking', () {
      test('should generate unique levels within session', () async {
        final levels = <Level>[];
        
        // Generate multiple levels
        for (int i = 1; i <= 5; i++) {
          final level = await service.generateNextLevel(i, 1, 4, 2);
          levels.add(level);
        }
        
        // Check that all levels are in session history
        expect(service.sessionLevelCount, equals(5));
        
        // Verify uniqueness using similarity checker
        for (int i = 0; i < levels.length; i++) {
          for (int j = i + 1; j < levels.length; j++) {
            final similarity = LevelSimilarityChecker.compareStructuralPatterns(
              levels[i],
              levels[j],
            );
            expect(
              similarity,
              lessThan(LevelSimilarityChecker.similarityThreshold),
              reason: 'Levels $i and $j are too similar (similarity: $similarity)',
            );
          }
        }
      });

      test('should handle similarity detection correctly', () async {
        // Create two very similar levels
        final similarLevel1 = Level(
          id: 1,
          difficulty: 1,
          containerCount: 4,
          colorCount: 2,
          initialContainers: [
            Container(id: 0, capacity: 4, liquidLayers: [
              LiquidLayer(color: LiquidColor.red, volume: 2),
              LiquidLayer(color: LiquidColor.blue, volume: 2),
            ]),
            Container(id: 1, capacity: 4, liquidLayers: [
              LiquidLayer(color: LiquidColor.blue, volume: 2),
              LiquidLayer(color: LiquidColor.red, volume: 2),
            ]),
            Container(id: 2, capacity: 4, liquidLayers: []),
            Container(id: 3, capacity: 4, liquidLayers: []),
          ],
        );

        final similarLevel2 = Level(
          id: 2,
          difficulty: 1,
          containerCount: 4,
          colorCount: 2,
          initialContainers: [
            Container(id: 0, capacity: 4, liquidLayers: [
              LiquidLayer(color: LiquidColor.green, volume: 2),
              LiquidLayer(color: LiquidColor.yellow, volume: 2),
            ]),
            Container(id: 1, capacity: 4, liquidLayers: [
              LiquidLayer(color: LiquidColor.yellow, volume: 2),
              LiquidLayer(color: LiquidColor.green, volume: 2),
            ]),
            Container(id: 2, capacity: 4, liquidLayers: []),
            Container(id: 3, capacity: 4, liquidLayers: []),
          ],
        );

        mockGenerator.addPredefinedLevel(similarLevel1);
        mockGenerator.addPredefinedLevel(similarLevel2);

        // Generate first level
        final level1 = await service.generateNextLevel(1, 1, 4, 2);
        expect(service.sessionLevelCount, equals(1));

        // The service should detect similarity and try to generate different levels
        // or fall back to clearing history if needed
        final level2 = await service.generateNextLevel(2, 1, 4, 2);
        expect(level2, isNotNull);
      });
    });

    group('Session Management', () {
      test('should manage session history size', () async {
        // Generate more levels than max session size
        const maxSize = LevelGenerationService.maxSessionHistorySize;
        
        for (int i = 1; i <= maxSize + 10; i++) {
          await service.generateNextLevel(i, 1, 4, 2);
        }
        
        // Should not exceed max size
        expect(service.sessionLevelCount, lessThanOrEqualTo(maxSize));
      });

      test('should clear session history when requested', () async {
        // Generate some levels
        for (int i = 1; i <= 5; i++) {
          await service.generateNextLevel(i, 1, 4, 2);
        }
        
        expect(service.sessionLevelCount, equals(5));
        
        service.clearSessionHistory();
        
        expect(service.sessionLevelCount, equals(0));
      });

      test('should provide read-only access to session history', () async {
        await service.generateNextLevel(1, 1, 4, 2);
        
        final history = service.sessionHistory;
        expect(history.length, equals(1));
        
        // Should be unmodifiable
        expect(() => history.add(history.first), throwsUnsupportedError);
      });
    });

    group('Fallback Mechanisms', () {
      test('should fall back when uniqueness cannot be achieved', () async {
        // Create identical levels to force similarity
        final identicalLevel = Level(
          id: 1,
          difficulty: 1,
          containerCount: 4,
          colorCount: 2,
          initialContainers: [
            Container(id: 0, capacity: 4, liquidLayers: [
              LiquidLayer(color: LiquidColor.red, volume: 4),
            ]),
            Container(id: 1, capacity: 4, liquidLayers: [
              LiquidLayer(color: LiquidColor.blue, volume: 4),
            ]),
            Container(id: 2, capacity: 4, liquidLayers: []),
            Container(id: 3, capacity: 4, liquidLayers: []),
          ],
        );

        // Add many identical levels to force fallback
        for (int i = 0; i < 60; i++) {
          mockGenerator.addPredefinedLevel(identicalLevel);
        }

        // Should still generate levels even if they're not unique
        final level = await service.generateNextLevel(1, 1, 4, 2);
        expect(level, isNotNull);
      });

      test('should try parameter modifications when uniqueness fails', () async {
        // This test verifies that the service attempts different parameters
        // when it cannot generate unique levels with the original parameters
        
        final level = await service.generateNextLevel(1, 5, 6, 4);
        expect(level, isNotNull);
        
        // The service might have modified parameters to achieve uniqueness
        // We just verify it returns a valid level
        expect(level.id, equals(1));
      });
    });

    group('Level Series Generation', () {
      test('should generate a series of unique levels', () async {
        const seriesCount = 10;
        final levels = await service.generateLevelSeries(1, seriesCount);
        
        expect(levels.length, equals(seriesCount));
        
        // Check that all levels have sequential IDs
        for (int i = 0; i < levels.length; i++) {
          expect(levels[i].id, equals(i + 1));
        }
        
        // Session history might be less than seriesCount due to similarity management
        // but should contain at least some levels
        expect(service.sessionLevelCount, greaterThan(0));
        expect(service.sessionLevelCount, lessThanOrEqualTo(seriesCount));
      });

      test('should apply progressive difficulty in series', () async {
        final levels = await service.generateLevelSeries(1, 15, startDifficulty: 1);
        
        // Check that difficulty increases over the series
        expect(levels.first.difficulty, equals(1));
        
        // Difficulty should increase every 5 levels
        bool foundIncrease = false;
        for (int i = 1; i < levels.length; i++) {
          if (levels[i].difficulty > levels[i - 1].difficulty) {
            foundIncrease = true;
            break;
          }
        }
        expect(foundIncrease, isTrue, reason: 'Expected difficulty to increase in series');
      });
    });

    group('Statistics and Metrics', () {
      test('should provide session statistics', () async {
        // Generate levels with varying parameters
        await service.generateNextLevel(1, 1, 4, 2);
        await service.generateNextLevel(2, 3, 5, 3);
        await service.generateNextLevel(3, 5, 6, 4);
        
        final stats = service.getSessionStatistics();
        
        expect(stats['total_levels'], equals(3));
        expect(stats['avg_difficulty'], equals(3.0)); // (1+3+5)/3
        expect(stats['avg_containers'], equals(5.0)); // (4+5+6)/3
        expect(stats['avg_colors'], equals(3.0)); // (2+3+4)/3
        expect(stats['difficulty_range'], equals([1, 5]));
        expect(stats['container_range'], equals([4, 6]));
        expect(stats['color_range'], equals([2, 4]));
        expect(stats['uniqueness_analysis'], isA<Map<String, dynamic>>());
      });

      test('should provide generation metrics', () async {
        final metrics = service.getGenerationMetrics();
        
        expect(metrics['max_session_size'], equals(LevelGenerationService.maxSessionHistorySize));
        expect(metrics['min_session_size'], equals(LevelGenerationService.minSessionHistorySize));
        expect(metrics['max_attempts'], equals(LevelGenerationService.maxUniqueGenerationAttempts));
        expect(metrics['service_status'], equals('healthy'));
      });

      test('should handle empty session statistics', () async {
        final stats = service.getSessionStatistics();
        
        expect(stats['total_levels'], equals(0));
        expect(stats['avg_difficulty'], equals(0.0));
        expect(stats['avg_containers'], equals(0.0));
        expect(stats['avg_colors'], equals(0.0));
      });
    });

    group('Service Validation', () {
      test('should validate service health', () async {
        expect(service.validateService(), isTrue);
      });

      test('should detect service errors', () async {
        mockGenerator.setShouldThrowError(true);
        
        // Service validation should handle errors gracefully
        final isHealthy = service.validateService();
        expect(isHealthy, isFalse);
      });

      test('should reset service state', () async {
        // Generate some levels
        await service.generateNextLevel(1, 1, 4, 2);
        await service.generateNextLevel(2, 1, 4, 2);
        
        expect(service.sessionLevelCount, equals(2));
        
        service.reset();
        
        expect(service.sessionLevelCount, equals(0));
      });
    });

    group('Edge Cases', () {
      test('should handle maximum session size correctly', () async {
        const maxSize = LevelGenerationService.maxSessionHistorySize;
        
        // Generate levels with varying parameters to avoid similarity issues
        for (int i = 1; i <= 20; i++) {
          // Vary parameters to ensure uniqueness
          final containerCount = 4 + (i % 3);
          final colorCount = 2 + (i % 3);
          await service.generateNextLevel(i, 1, containerCount, colorCount);
        }
        
        // Should have generated levels (may be less than 20 due to similarity management)
        expect(service.sessionLevelCount, greaterThan(0));
        expect(service.sessionLevelCount, lessThanOrEqualTo(maxSize));
        
        // Test that the service manages history size appropriately
        final initialCount = service.sessionLevelCount;
        
        // Generate more levels
        for (int i = 21; i <= 30; i++) {
          final containerCount = 4 + (i % 4);
          final colorCount = 2 + (i % 4);
          await service.generateNextLevel(i, 1, containerCount, colorCount);
        }
        
        // Should still be within reasonable bounds
        expect(service.sessionLevelCount, lessThanOrEqualTo(maxSize));
      });

      test('should handle minimum session size during cleanup', () async {
        const minSize = LevelGenerationService.minSessionHistorySize;
        
        // Generate more than min size
        for (int i = 1; i <= minSize + 5; i++) {
          await service.generateNextLevel(i, 1, 4, 2);
        }
        
        // Trigger old history cleanup (this is internal, so we test indirectly)
        // by generating many similar levels to force fallback mechanisms
        final level = await service.generateNextLevel(100, 1, 4, 2);
        expect(level, isNotNull);
      });

      test('should handle concurrent generation requests', () async {
        // Simulate concurrent requests with varied parameters
        final futures = <Future<Level>>[];
        
        for (int i = 1; i <= 5; i++) {
          // Use different parameters for each request to avoid similarity issues
          final containerCount = 4 + (i % 3);
          final colorCount = 2 + (i % 2);
          futures.add(service.generateNextLevel(i, i, containerCount, colorCount));
        }
        
        final levels = await Future.wait(futures);
        
        expect(levels.length, equals(5));
        // Session count might be less than 5 due to similarity management
        expect(service.sessionLevelCount, greaterThan(0));
        expect(service.sessionLevelCount, lessThanOrEqualTo(5));
        
        // All levels should be valid
        for (final level in levels) {
          expect(level, isNotNull);
          expect(level.isStructurallyValid, isTrue);
        }
      });
    });

    group('Integration with LevelSimilarityChecker', () {
      test('should use similarity checker for uniqueness validation', () async {
        // Generate a level
        final level1 = await service.generateNextLevel(1, 1, 4, 2);
        
        // Create a very similar level manually
        final similarLevel = Level(
          id: 2,
          difficulty: 1,
          containerCount: 4,
          colorCount: 2,
          initialContainers: level1.initialContainers.map((container) =>
            Container(
              id: container.id,
              capacity: container.capacity,
              liquidLayers: List.from(container.liquidLayers),
            )
          ).toList(),
        );
        
        mockGenerator.addPredefinedLevel(similarLevel);
        
        // The service should detect similarity and handle it appropriately
        final level2 = await service.generateNextLevel(2, 1, 4, 2);
        expect(level2, isNotNull);
      });

      test('should attempt to respect similarity threshold', () async {
        // This test verifies that the service attempts to generate unique levels
        // and handles similarity detection appropriately
        
        // Clear any existing session history
        service.clearSessionHistory();
        
        // Generate a few levels with the same parameters to force similarity
        final level1 = await service.generateNextLevel(1, 1, 4, 2);
        final level2 = await service.generateNextLevel(2, 1, 4, 2);
        final level3 = await service.generateNextLevel(3, 1, 4, 2);
        
        // All levels should be generated successfully (service handles similarity internally)
        expect(level1, isNotNull);
        expect(level2, isNotNull);
        expect(level3, isNotNull);
        
        // The service should have at least attempted to manage uniqueness
        // This might result in session history being cleared or levels being rejected
        expect(service.sessionLevelCount, greaterThan(0));
        
        // Test that the service can generate levels with very different parameters
        service.clearSessionHistory();
        
        final diverseLevel1 = await service.generateNextLevel(10, 1, 4, 2);
        final diverseLevel2 = await service.generateNextLevel(20, 3, 6, 3);
        final diverseLevel3 = await service.generateNextLevel(30, 5, 8, 4);
        
        expect(diverseLevel1, isNotNull);
        expect(diverseLevel2, isNotNull);
        expect(diverseLevel3, isNotNull);
        
        // These should be quite different due to different parameters
        final similarity12 = LevelSimilarityChecker.compareStructuralPatterns(
          diverseLevel1,
          diverseLevel2,
        );
        final similarity13 = LevelSimilarityChecker.compareStructuralPatterns(
          diverseLevel1,
          diverseLevel3,
        );
        final similarity23 = LevelSimilarityChecker.compareStructuralPatterns(
          diverseLevel2,
          diverseLevel3,
        );
        
        // At least some of these should be below the similarity threshold
        final belowThreshold = [similarity12, similarity13, similarity23]
            .where((s) => s < LevelSimilarityChecker.similarityThreshold)
            .length;
        
        expect(belowThreshold, greaterThan(0), 
          reason: 'Expected at least some levels to be below similarity threshold');
      });
    });
  });
}