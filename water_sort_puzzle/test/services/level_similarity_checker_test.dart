import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/level.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/services/level_similarity_checker.dart';

void main() {
  group('LevelSimilarityChecker', () {
    // Helper function to create a container with liquid layers
    Container createContainer(int id, List<(LiquidColor, int)> layers) {
      final liquidLayers = layers
          .map((layer) => LiquidLayer(color: layer.$1, volume: layer.$2))
          .toList();
      return Container(id: id, capacity: 4, liquidLayers: liquidLayers);
    }

    // Helper function to create a level
    Level createLevel(int id, List<Container> containers, int colorCount) {
      return Level(
        id: id,
        difficulty: 1,
        containerCount: containers.length,
        colorCount: colorCount,
        initialContainers: containers,
      );
    }

    group('generateNormalizedSignature', () {
      test('should generate consistent signatures for identical levels', () {
        final containers1 = [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
          createContainer(1, [(LiquidColor.blue, 2), (LiquidColor.red, 2)]),
          createContainer(2, []),
        ];
        final level1 = createLevel(1, containers1, 2);

        final containers2 = [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
          createContainer(1, [(LiquidColor.blue, 2), (LiquidColor.red, 2)]),
          createContainer(2, []),
        ];
        final level2 = createLevel(2, containers2, 2);

        final signature1 = LevelSimilarityChecker.generateNormalizedSignature(level1);
        final signature2 = LevelSimilarityChecker.generateNormalizedSignature(level2);

        expect(signature1, equals(signature2));
      });

      test('should generate different signatures for different levels', () {
        final containers1 = [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
          createContainer(1, [(LiquidColor.blue, 4)]),
          createContainer(2, []),
        ];
        final level1 = createLevel(1, containers1, 2);

        final containers2 = [
          createContainer(0, [(LiquidColor.red, 4)]),
          createContainer(1, [(LiquidColor.blue, 4)]),
          createContainer(2, []),
        ];
        final level2 = createLevel(2, containers2, 2);

        final signature1 = LevelSimilarityChecker.generateNormalizedSignature(level1);
        final signature2 = LevelSimilarityChecker.generateNormalizedSignature(level2);

        expect(signature1, isNot(equals(signature2)));
      });

      test('should be order-independent for containers', () {
        final containers1 = [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
          createContainer(1, [(LiquidColor.blue, 4)]),
          createContainer(2, []),
        ];
        final level1 = createLevel(1, containers1, 2);

        // Same containers but in different order
        final containers2 = [
          createContainer(0, []),
          createContainer(1, [(LiquidColor.blue, 4)]),
          createContainer(2, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
        ];
        final level2 = createLevel(2, containers2, 2);

        final signature1 = LevelSimilarityChecker.generateNormalizedSignature(level1);
        final signature2 = LevelSimilarityChecker.generateNormalizedSignature(level2);

        expect(signature1, equals(signature2));
      });

      test('should be color-agnostic', () {
        final containers1 = [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
          createContainer(1, [(LiquidColor.blue, 2), (LiquidColor.red, 2)]),
          createContainer(2, []),
        ];
        final level1 = createLevel(1, containers1, 2);

        // Same pattern but with different colors
        final containers2 = [
          createContainer(0, [(LiquidColor.green, 2), (LiquidColor.yellow, 2)]),
          createContainer(1, [(LiquidColor.yellow, 2), (LiquidColor.green, 2)]),
          createContainer(2, []),
        ];
        final level2 = createLevel(2, containers2, 2);

        final signature1 = LevelSimilarityChecker.generateNormalizedSignature(level1);
        final signature2 = LevelSimilarityChecker.generateNormalizedSignature(level2);

        expect(signature1, equals(signature2));
      });
    });

    group('areLevelsSimilar', () {
      test('should return true for identical levels', () {
        final containers = [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
          createContainer(1, [(LiquidColor.blue, 2), (LiquidColor.red, 2)]),
          createContainer(2, []),
        ];
        final level1 = createLevel(1, containers, 2);
        final level2 = createLevel(2, containers, 2);

        expect(LevelSimilarityChecker.areLevelsSimilar(level1, level2), isTrue);
      });

      test('should return false for levels with different container counts', () {
        final containers1 = [
          createContainer(0, [(LiquidColor.red, 4)]),
          createContainer(1, []),
        ];
        final level1 = createLevel(1, containers1, 1);

        final containers2 = [
          createContainer(0, [(LiquidColor.red, 4)]),
          createContainer(1, []),
          createContainer(2, []),
        ];
        final level2 = createLevel(2, containers2, 1);

        expect(LevelSimilarityChecker.areLevelsSimilar(level1, level2), isFalse);
      });

      test('should return false for levels with different color counts', () {
        final containers1 = [
          createContainer(0, [(LiquidColor.red, 4)]),
          createContainer(1, []),
        ];
        final level1 = createLevel(1, containers1, 1);

        final containers2 = [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
          createContainer(1, []),
        ];
        final level2 = createLevel(2, containers2, 2);

        expect(LevelSimilarityChecker.areLevelsSimilar(level1, level2), isFalse);
      });

      test('should return true for similar levels above threshold', () {
        final containers1 = [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
          createContainer(1, [(LiquidColor.blue, 2), (LiquidColor.red, 2)]),
          createContainer(2, []),
          createContainer(3, []),
          createContainer(4, []),
        ];
        final level1 = createLevel(1, containers1, 2);

        // 4 out of 5 containers match exactly (80% similarity)
        final containers2 = [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
          createContainer(1, [(LiquidColor.blue, 2), (LiquidColor.red, 2)]),
          createContainer(2, []),
          createContainer(3, []),
          createContainer(4, []), // Same as level1 - all empty
        ];
        final level2 = createLevel(2, containers2, 2);

        expect(LevelSimilarityChecker.areLevelsSimilar(level1, level2), isTrue);
      });

      test('should return false for significantly different levels', () {
        final containers1 = [
          createContainer(0, [(LiquidColor.red, 4)]),
          createContainer(1, [(LiquidColor.blue, 4)]),
          createContainer(2, []),
        ];
        final level1 = createLevel(1, containers1, 2);

        final containers2 = [
          createContainer(0, [(LiquidColor.red, 1), (LiquidColor.blue, 1), (LiquidColor.red, 1), (LiquidColor.blue, 1)]),
          createContainer(1, [(LiquidColor.blue, 1), (LiquidColor.red, 1), (LiquidColor.blue, 1), (LiquidColor.red, 1)]),
          createContainer(2, []),
        ];
        final level2 = createLevel(2, containers2, 2);

        expect(LevelSimilarityChecker.areLevelsSimilar(level1, level2), isFalse);
      });
    });

    group('normalizeColors', () {
      test('should assign colors consistently', () {
        final containers = [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
          createContainer(1, [(LiquidColor.blue, 2), (LiquidColor.red, 2)]),
          createContainer(2, []),
        ];

        final normalized = LevelSimilarityChecker.normalizeColors(containers);

        expect(normalized, hasLength(3));
        expect(normalized[2], equals('EMPTY'));
        
        // First color encountered should be 'A', second should be 'B'
        expect(normalized[0], equals('AABB'));
        expect(normalized[1], equals('BBAA'));
      });

      test('should handle empty containers', () {
        final containers = [
          createContainer(0, []),
          createContainer(1, [(LiquidColor.red, 4)]),
          createContainer(2, []),
        ];

        final normalized = LevelSimilarityChecker.normalizeColors(containers);

        expect(normalized, equals(['EMPTY', 'AAAA', 'EMPTY']));
      });

      test('should handle complex layer patterns', () {
        final containers = [
          createContainer(0, [(LiquidColor.red, 1), (LiquidColor.blue, 2), (LiquidColor.red, 1)]),
          createContainer(1, [(LiquidColor.blue, 3), (LiquidColor.red, 1)]),
        ];

        final normalized = LevelSimilarityChecker.normalizeColors(containers);

        expect(normalized, equals(['ABBA', 'BBBA']));
      });
    });

    group('calculatePatternSimilarity', () {
      test('should return 1.0 for identical patterns', () {
        final pattern1 = ['AABB', 'BBAA', 'EMPTY'];
        final pattern2 = ['AABB', 'BBAA', 'EMPTY'];

        final similarity = LevelSimilarityChecker.calculatePatternSimilarity(pattern1, pattern2);

        expect(similarity, equals(1.0));
      });

      test('should return 0.0 for completely different patterns', () {
        final pattern1 = ['AAAA', 'BBBB', 'EMPTY'];
        final pattern2 = ['ABAB', 'BABA', 'CCCC'];

        final similarity = LevelSimilarityChecker.calculatePatternSimilarity(pattern1, pattern2);

        expect(similarity, lessThan(0.3)); // Should be very low
      });

      test('should be order-independent', () {
        final pattern1 = ['AABB', 'BBAA', 'EMPTY'];
        final pattern2 = ['EMPTY', 'AABB', 'BBAA']; // Same patterns, different order

        final similarity = LevelSimilarityChecker.calculatePatternSimilarity(pattern1, pattern2);

        expect(similarity, equals(1.0));
      });

      test('should return 0.0 for different length patterns', () {
        final pattern1 = ['AABB', 'BBAA'];
        final pattern2 = ['AABB', 'BBAA', 'EMPTY'];

        final similarity = LevelSimilarityChecker.calculatePatternSimilarity(pattern1, pattern2);

        expect(similarity, equals(0.0));
      });
    });

    group('isLevelUnique', () {
      test('should return true for unique level', () {
        final existingLevels = [
          createLevel(1, [
            createContainer(0, [(LiquidColor.red, 4)]),
            createContainer(1, [(LiquidColor.blue, 4)]),
            createContainer(2, []),
          ], 2),
        ];

        final newLevel = createLevel(2, [
          createContainer(0, [(LiquidColor.red, 1), (LiquidColor.blue, 3)]),
          createContainer(1, [(LiquidColor.blue, 1), (LiquidColor.red, 3)]),
          createContainer(2, []),
        ], 2);

        expect(LevelSimilarityChecker.isLevelUnique(newLevel, existingLevels), isTrue);
      });

      test('should return false for similar level', () {
        final existingLevels = [
          createLevel(1, [
            createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
            createContainer(1, [(LiquidColor.blue, 2), (LiquidColor.red, 2)]),
            createContainer(2, []),
          ], 2),
        ];

        // Same pattern with different colors (should be detected as similar)
        final newLevel = createLevel(2, [
          createContainer(0, [(LiquidColor.green, 2), (LiquidColor.yellow, 2)]),
          createContainer(1, [(LiquidColor.yellow, 2), (LiquidColor.green, 2)]),
          createContainer(2, []),
        ], 2);

        expect(LevelSimilarityChecker.isLevelUnique(newLevel, existingLevels), isFalse);
      });
    });

    group('isLevelSimilarToAny', () {
      test('should return true when level is similar to existing levels', () {
        final existingLevels = [
          createLevel(1, [
            createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
            createContainer(1, [(LiquidColor.blue, 2), (LiquidColor.red, 2)]),
            createContainer(2, []),
          ], 2),
        ];

        // Same pattern with different colors (should be detected as similar)
        final newLevel = createLevel(2, [
          createContainer(0, [(LiquidColor.green, 2), (LiquidColor.yellow, 2)]),
          createContainer(1, [(LiquidColor.yellow, 2), (LiquidColor.green, 2)]),
          createContainer(2, []),
        ], 2);

        expect(LevelSimilarityChecker.isLevelSimilarToAny(newLevel, existingLevels), isTrue);
      });

      test('should return false when level is unique', () {
        final existingLevels = [
          createLevel(1, [
            createContainer(0, [(LiquidColor.red, 4)]),
            createContainer(1, [(LiquidColor.blue, 4)]),
            createContainer(2, []),
          ], 2),
        ];

        final newLevel = createLevel(2, [
          createContainer(0, [(LiquidColor.red, 1), (LiquidColor.blue, 3)]),
          createContainer(1, [(LiquidColor.blue, 1), (LiquidColor.red, 3)]),
          createContainer(2, []),
        ], 2);

        expect(LevelSimilarityChecker.isLevelSimilarToAny(newLevel, existingLevels), isFalse);
      });
    });

    group('isPatternValid', () {
      test('should return true for unsolved patterns', () {
        final pattern = ['AABB', 'BBAA', 'EMPTY'];
        expect(LevelSimilarityChecker.isPatternValid(pattern), isTrue);
      });

      test('should return false for solved patterns', () {
        final pattern = ['AAAA', 'BBBB', 'EMPTY'];
        expect(LevelSimilarityChecker.isPatternValid(pattern), isFalse);
      });

      test('should return false for all empty pattern', () {
        final pattern = ['EMPTY', 'EMPTY', 'EMPTY'];
        expect(LevelSimilarityChecker.isPatternValid(pattern), isFalse);
      });

      test('should return true for mixed pattern with some solved containers', () {
        final pattern = ['AAAA', 'ABBA', 'EMPTY']; // One solved, one mixed
        expect(LevelSimilarityChecker.isPatternValid(pattern), isTrue);
      });
    });

    group('getSimilarityAnalysis', () {
      test('should provide detailed analysis', () {
        final level1 = createLevel(1, [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
          createContainer(1, []),
        ], 2);

        final level2 = createLevel(2, [
          createContainer(0, [(LiquidColor.green, 2), (LiquidColor.yellow, 2)]),
          createContainer(1, []),
        ], 2);

        final analysis = LevelSimilarityChecker.getSimilarityAnalysis(level1, level2);

        expect(analysis, containsPair('similarity_score', isA<double>()));
        expect(analysis, containsPair('is_similar', isA<bool>()));
        expect(analysis, containsPair('threshold', LevelSimilarityChecker.similarityThreshold));
        expect(analysis, containsPair('level1_signature', isA<String>()));
        expect(analysis, containsPair('level2_signature', isA<String>()));
        expect(analysis, containsPair('level1_pattern', isA<List<String>>()));
        expect(analysis, containsPair('level2_pattern', isA<List<String>>()));
      });
    });

    group('generatePatternHash', () {
      test('should generate consistent hashes for identical levels', () {
        final containers = [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
          createContainer(1, []),
        ];
        final level1 = createLevel(1, containers, 2);
        final level2 = createLevel(2, containers, 2);

        final hash1 = LevelSimilarityChecker.generatePatternHash(level1);
        final hash2 = LevelSimilarityChecker.generatePatternHash(level2);

        expect(hash1, equals(hash2));
      });

      test('should generate different hashes for different levels', () {
        final level1 = createLevel(1, [
          createContainer(0, [(LiquidColor.red, 4)]),
          createContainer(1, []),
        ], 1);

        final level2 = createLevel(2, [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
          createContainer(1, []),
        ], 2);

        final hash1 = LevelSimilarityChecker.generatePatternHash(level1);
        final hash2 = LevelSimilarityChecker.generatePatternHash(level2);

        expect(hash1, isNot(equals(hash2)));
      });
    });

    group('analyzeLevelSetSimilarity', () {
      test('should handle empty level set', () {
        final analysis = LevelSimilarityChecker.analyzeLevelSetSimilarity([]);

        expect(analysis['total_levels'], equals(0));
        expect(analysis['unique_levels'], equals(0));
        expect(analysis['similarity_pairs'], equals(0));
        expect(analysis['uniqueness_ratio'], equals(1.0));
        expect(analysis['analysis_summary'], equals('No levels to analyze'));
      });

      test('should analyze unique levels correctly', () {
        final levels = [
          createLevel(1, [
            createContainer(0, [(LiquidColor.red, 4)]),
            createContainer(1, []),
          ], 1),
          createLevel(2, [
            createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
            createContainer(1, []),
          ], 2),
          createLevel(3, [
            createContainer(0, [(LiquidColor.green, 4)]),
            createContainer(1, [(LiquidColor.yellow, 4)]),
            createContainer(2, []),
          ], 2),
        ];

        final analysis = LevelSimilarityChecker.analyzeLevelSetSimilarity(levels);

        expect(analysis['total_levels'], equals(3));
        expect(analysis['unique_levels'], equals(3));
        expect(analysis['similarity_pairs'], equals(0));
        expect(analysis['uniqueness_ratio'], equals(1.0));
        expect(analysis['analysis_summary'], contains('Excellent uniqueness'));
      });

      test('should detect similar levels', () {
        final levels = [
          createLevel(1, [
            createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
            createContainer(1, [(LiquidColor.blue, 2), (LiquidColor.red, 2)]),
            createContainer(2, []),
          ], 2),
          createLevel(2, [
            createContainer(0, [(LiquidColor.green, 2), (LiquidColor.yellow, 2)]),
            createContainer(1, [(LiquidColor.yellow, 2), (LiquidColor.green, 2)]),
            createContainer(2, []),
          ], 2), // Same pattern as level 1, different colors
          createLevel(3, [
            createContainer(0, [(LiquidColor.purple, 4)]),
            createContainer(1, []),
          ], 1), // Different pattern
        ];

        final analysis = LevelSimilarityChecker.analyzeLevelSetSimilarity(levels);

        expect(analysis['total_levels'], equals(3));
        expect(analysis['unique_levels'], equals(2)); // Only 2 unique patterns
        expect(analysis['similarity_pairs'], equals(1)); // One similar pair
        expect(analysis['uniqueness_ratio'], closeTo(0.67, 0.01));
        expect(analysis['analysis_summary'], contains('Moderate uniqueness'));
      });
    });

    group('optimizeEmptyContainers', () {
      test('should not optimize levels with 3 or fewer containers', () {
        final level = createLevel(1, [
          createContainer(0, [(LiquidColor.red, 4)]),
          createContainer(1, [(LiquidColor.blue, 4)]),
          createContainer(2, []),
        ], 2);

        final optimized = LevelSimilarityChecker.optimizeEmptyContainers(level);

        expect(optimized.containerCount, equals(3));
        expect(optimized.initialContainers.length, equals(3));
      });

      test('should not optimize levels with only one empty container', () {
        final level = createLevel(1, [
          createContainer(0, [(LiquidColor.red, 4)]),
          createContainer(1, [(LiquidColor.blue, 4)]),
          createContainer(2, [(LiquidColor.green, 4)]),
          createContainer(3, []),
        ], 3);

        final optimized = LevelSimilarityChecker.optimizeEmptyContainers(level);

        expect(optimized.containerCount, equals(4));
        expect(optimized.initialContainers.length, equals(4));
      });

      test('should remove unnecessary empty containers', () {
        final level = createLevel(1, [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
          createContainer(1, [(LiquidColor.blue, 2), (LiquidColor.red, 2)]),
          createContainer(2, []),
          createContainer(3, []),
          createContainer(4, []),
        ], 2);

        final optimized = LevelSimilarityChecker.optimizeEmptyContainers(level);

        // Should keep only the minimum containers needed (2 filled + 1 empty = 3 total)
        expect(optimized.containerCount, lessThan(level.containerCount));
        expect(optimized.initialContainers.where((c) => c.isEmpty).length, greaterThanOrEqualTo(1));
        expect(optimized.initialContainers.where((c) => !c.isEmpty).length, equals(2));
      });

      test('should maintain level solvability after optimization', () {
        final level = createLevel(1, [
          createContainer(0, [(LiquidColor.red, 4)]),
          createContainer(1, [(LiquidColor.blue, 4)]),
          createContainer(2, []),
          createContainer(3, []),
          createContainer(4, []),
        ], 2);

        final optimized = LevelSimilarityChecker.optimizeEmptyContainers(level);

        // Should still be theoretically solvable
        expect(optimized.isStructurallyValid, isTrue);
        expect(optimized.initialContainers.where((c) => c.isEmpty).length, greaterThanOrEqualTo(1));
      });

      test('should reassign container IDs correctly after optimization', () {
        final level = createLevel(1, [
          createContainer(0, [(LiquidColor.red, 4)]),
          createContainer(1, []),
          createContainer(2, [(LiquidColor.blue, 4)]),
          createContainer(3, []),
          createContainer(4, []),
        ], 2);

        final optimized = LevelSimilarityChecker.optimizeEmptyContainers(level);

        // Container IDs should be sequential starting from 0
        for (int i = 0; i < optimized.initialContainers.length; i++) {
          expect(optimized.initialContainers[i].id, equals(i));
        }
      });

      test('should preserve all liquid content during optimization', () {
        final level = createLevel(1, [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
          createContainer(1, [(LiquidColor.blue, 2), (LiquidColor.red, 2)]),
          createContainer(2, []),
          createContainer(3, []),
          createContainer(4, []),
        ], 2);

        final optimized = LevelSimilarityChecker.optimizeEmptyContainers(level);

        // Count total liquid volume before and after
        int originalVolume = 0;
        for (final container in level.initialContainers) {
          for (final layer in container.liquidLayers) {
            originalVolume += layer.volume;
          }
        }

        int optimizedVolume = 0;
        for (final container in optimized.initialContainers) {
          for (final layer in container.liquidLayers) {
            optimizedVolume += layer.volume;
          }
        }

        expect(optimizedVolume, equals(originalVolume));
      });
    });

    group('_isLevelTheoreticallySolvable', () {
      test('should return true for valid solvable levels', () {
        final level = createLevel(1, [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
          createContainer(1, [(LiquidColor.blue, 2), (LiquidColor.red, 2)]),
          createContainer(2, []),
        ], 2);

        expect(LevelSimilarityChecker._isLevelTheoreticallySolvable(level), isTrue);
      });

      test('should return false for levels with no empty slots', () {
        final level = createLevel(1, [
          createContainer(0, [(LiquidColor.red, 4)]),
          createContainer(1, [(LiquidColor.blue, 4)]),
        ], 2);

        expect(LevelSimilarityChecker._isLevelTheoreticallySolvable(level), isFalse);
      });

      test('should return false for levels with incorrect color volumes', () {
        final level = createLevel(1, [
          createContainer(0, [(LiquidColor.red, 3)]), // Wrong volume
          createContainer(1, [(LiquidColor.blue, 4)]),
          createContainer(2, []),
        ], 2);

        expect(LevelSimilarityChecker._isLevelTheoreticallySolvable(level), isFalse);
      });

      test('should return false for levels with insufficient containers', () {
        final level = createLevel(1, [
          createContainer(0, [(LiquidColor.red, 4)]),
          createContainer(1, [(LiquidColor.blue, 4)]),
        ], 2); // 2 colors but only 2 containers (no room for moves)

        expect(LevelSimilarityChecker._isLevelTheoreticallySolvable(level), isFalse);
      });

      test('should return false for levels with excessive color fragmentation', () {
        final level = createLevel(1, [
          createContainer(0, [(LiquidColor.red, 1)]),
          createContainer(1, [(LiquidColor.red, 1)]),
          createContainer(2, [(LiquidColor.red, 1)]),
          createContainer(3, [(LiquidColor.red, 1)]),
          createContainer(4, [(LiquidColor.blue, 4)]),
          createContainer(5, []),
        ], 2); // Red is spread across too many containers

        expect(LevelSimilarityChecker._isLevelTheoreticallySolvable(level), isFalse);
      });
    });

    group('edge cases', () {
      test('should handle single container levels', () {
        final level1 = createLevel(1, [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
        ], 2);

        final level2 = createLevel(2, [
          createContainer(0, [(LiquidColor.green, 2), (LiquidColor.yellow, 2)]),
        ], 2);

        expect(LevelSimilarityChecker.areLevelsSimilar(level1, level2), isTrue);
      });

      test('should handle levels with many colors', () {
        final level1 = createLevel(1, [
          createContainer(0, [(LiquidColor.red, 1), (LiquidColor.blue, 1), (LiquidColor.green, 1), (LiquidColor.yellow, 1)]),
          createContainer(1, []),
        ], 4);

        final level2 = createLevel(2, [
          createContainer(0, [(LiquidColor.purple, 1), (LiquidColor.orange, 1), (LiquidColor.pink, 1), (LiquidColor.cyan, 1)]),
          createContainer(1, []),
        ], 4);

        expect(LevelSimilarityChecker.areLevelsSimilar(level1, level2), isTrue);
      });

      test('should handle levels with single-volume layers', () {
        final level1 = createLevel(1, [
          createContainer(0, [(LiquidColor.red, 1), (LiquidColor.blue, 1), (LiquidColor.red, 1), (LiquidColor.blue, 1)]),
          createContainer(1, []),
        ], 2);

        final level2 = createLevel(2, [
          createContainer(0, [(LiquidColor.green, 1), (LiquidColor.yellow, 1), (LiquidColor.green, 1), (LiquidColor.yellow, 1)]),
          createContainer(1, []),
        ], 2);

        expect(LevelSimilarityChecker.areLevelsSimilar(level1, level2), isTrue);
      });

      test('should handle empty levels', () {
        final level1 = createLevel(1, [
          createContainer(0, []),
          createContainer(1, []),
        ], 0);

        final level2 = createLevel(2, [
          createContainer(0, []),
          createContainer(1, []),
        ], 0);

        expect(LevelSimilarityChecker.areLevelsSimilar(level1, level2), isTrue);
      });
    });

    group('threshold validation', () {
      test('should use correct similarity threshold', () {
        expect(LevelSimilarityChecker.similarityThreshold, equals(0.8));
      });

      test('should respect threshold in similarity detection', () {
        // Create levels that are exactly at the threshold (4 out of 5 containers match = 80%)
        final level1 = createLevel(1, [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
          createContainer(1, [(LiquidColor.blue, 2), (LiquidColor.red, 2)]),
          createContainer(2, []),
          createContainer(3, [(LiquidColor.red, 4)]),
          createContainer(4, []),
        ], 2);

        // 4 out of 5 containers match exactly (80% similarity)
        final level2 = createLevel(2, [
          createContainer(0, [(LiquidColor.red, 2), (LiquidColor.blue, 2)]),
          createContainer(1, [(LiquidColor.blue, 2), (LiquidColor.red, 2)]),
          createContainer(2, []),
          createContainer(3, [(LiquidColor.red, 4)]),
          createContainer(4, [(LiquidColor.blue, 4)]), // Different - only this one differs
        ], 2);

        final similarity = LevelSimilarityChecker.compareStructuralPatterns(level1, level2);
        final isSimilar = LevelSimilarityChecker.areLevelsSimilar(level1, level2);

        // Should be at or above threshold (4/5 = 0.8)
        expect(similarity, greaterThanOrEqualTo(LevelSimilarityChecker.similarityThreshold));
        expect(isSimilar, isTrue);
      });
    });
  });
}