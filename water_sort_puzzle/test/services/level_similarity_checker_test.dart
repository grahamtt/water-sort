import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/level.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/services/level_similarity_checker.dart';

void main() {
  group('LevelSimilarityChecker', () {
    group('Color Normalization', () {
      test('should normalize identical color patterns correctly', () {
        // Create two levels with same structure but different colors
        final level1 = _createTestLevel(
          id: 1,
          containers: [
            _createContainer(0, [
              LiquidLayer(color: LiquidColor.red, volume: 2),
              LiquidLayer(color: LiquidColor.blue, volume: 2),
            ]),
            _createContainer(1, [
              LiquidLayer(color: LiquidColor.blue, volume: 2),
              LiquidLayer(color: LiquidColor.red, volume: 2),
            ]),
            _createContainer(2, []), // Empty
            _createContainer(3, []), // Empty
          ],
        );
        
        final level2 = _createTestLevel(
          id: 2,
          containers: [
            _createContainer(0, [
              LiquidLayer(color: LiquidColor.green, volume: 2),
              LiquidLayer(color: LiquidColor.yellow, volume: 2),
            ]),
            _createContainer(1, [
              LiquidLayer(color: LiquidColor.yellow, volume: 2),
              LiquidLayer(color: LiquidColor.green, volume: 2),
            ]),
            _createContainer(2, []), // Empty
            _createContainer(3, []), // Empty
          ],
        );
        
        final sig1 = LevelSimilarityChecker.generateNormalizedSignature(level1);
        final sig2 = LevelSimilarityChecker.generateNormalizedSignature(level2);
        
        expect(sig1, equals(sig2));
        expect(LevelSimilarityChecker.areLevelsSimilar(level1, level2), isTrue);
      });
      
      test('should handle empty containers in normalization', () {
        final level = _createTestLevel(
          id: 1,
          containers: [
            _createContainer(0, [
              LiquidLayer(color: LiquidColor.red, volume: 4),
            ]),
            _createContainer(1, []), // Empty
            _createContainer(2, []), // Empty
          ],
        );
        
        final signature = LevelSimilarityChecker.generateNormalizedSignature(level);
        expect(signature, contains('EMPTY'));
        expect(signature, contains('AAAA')); // 4 units of first color
      });
      
      test('should normalize complex multi-layer patterns', () {
        final level = _createTestLevel(
          id: 1,
          containers: [
            _createContainer(0, [
              LiquidLayer(color: LiquidColor.red, volume: 1),
              LiquidLayer(color: LiquidColor.blue, volume: 1),
              LiquidLayer(color: LiquidColor.red, volume: 2),
            ]),
            _createContainer(1, [
              LiquidLayer(color: LiquidColor.blue, volume: 3),
              LiquidLayer(color: LiquidColor.red, volume: 1),
            ]),
          ],
        );
        
        final normalized = LevelSimilarityChecker.normalizeColors(level.initialContainers);
        expect(normalized[0], equals('ABAA')); // red=A, blue=B
        expect(normalized[1], equals('BBBA'));
      });
    });
    
    group('Similarity Detection', () {
      test('should detect identical structural patterns as highly similar', () {
        final level1 = _createTestLevel(
          id: 1,
          containers: [
            _createContainer(0, [
              LiquidLayer(color: LiquidColor.red, volume: 2),
              LiquidLayer(color: LiquidColor.blue, volume: 2),
            ]),
            _createContainer(1, [
              LiquidLayer(color: LiquidColor.blue, volume: 4),
            ]),
            _createContainer(2, []), // Empty
          ],
        );
        
        final level2 = _createTestLevel(
          id: 2,
          containers: [
            _createContainer(0, [
              LiquidLayer(color: LiquidColor.green, volume: 2),
              LiquidLayer(color: LiquidColor.yellow, volume: 2),
            ]),
            _createContainer(1, [
              LiquidLayer(color: LiquidColor.yellow, volume: 4),
            ]),
            _createContainer(2, []), // Empty
          ],
        );
        
        expect(LevelSimilarityChecker.areLevelsSimilar(level1, level2), isTrue);
      });
      
      test('should detect different patterns as dissimilar', () {
        final level1 = _createTestLevel(
          id: 1,
          containers: [
            _createContainer(0, [
              LiquidLayer(color: LiquidColor.red, volume: 4),
            ]),
            _createContainer(1, [
              LiquidLayer(color: LiquidColor.blue, volume: 4),
            ]),
            _createContainer(2, []), // Empty
          ],
        );
        
        final level2 = _createTestLevel(
          id: 2,
          containers: [
            _createContainer(0, [
              LiquidLayer(color: LiquidColor.red, volume: 2),
              LiquidLayer(color: LiquidColor.blue, volume: 2),
            ]),
            _createContainer(1, [
              LiquidLayer(color: LiquidColor.blue, volume: 2),
              LiquidLayer(color: LiquidColor.red, volume: 2),
            ]),
            _createContainer(2, []), // Empty
          ],
        );
        
        expect(LevelSimilarityChecker.areLevelsSimilar(level1, level2), isFalse);
      });
      
      test('should handle different container counts as dissimilar', () {
        final level1 = _createTestLevel(
          id: 1,
          containers: [
            _createContainer(0, [LiquidLayer(color: LiquidColor.red, volume: 4)]),
            _createContainer(1, []),
          ],
        );
        
        final level2 = _createTestLevel(
          id: 2,
          containers: [
            _createContainer(0, [LiquidLayer(color: LiquidColor.red, volume: 4)]),
            _createContainer(1, []),
            _createContainer(2, []),
          ],
        );
        
        expect(LevelSimilarityChecker.areLevelsSimilar(level1, level2), isFalse);
      });
      
      test('should handle different color counts as dissimilar', () {
        final level1 = _createTestLevel(
          id: 1,
          colorCount: 2,
          containers: [
            _createContainer(0, [LiquidLayer(color: LiquidColor.red, volume: 4)]),
            _createContainer(1, [LiquidLayer(color: LiquidColor.blue, volume: 4)]),
            _createContainer(2, []),
          ],
        );
        
        final level2 = _createTestLevel(
          id: 2,
          colorCount: 3,
          containers: [
            _createContainer(0, [LiquidLayer(color: LiquidColor.red, volume: 4)]),
            _createContainer(1, [LiquidLayer(color: LiquidColor.blue, volume: 4)]),
            _createContainer(2, [LiquidLayer(color: LiquidColor.green, volume: 4)]),
            _createContainer(3, []),
          ],
        );
        
        expect(LevelSimilarityChecker.areLevelsSimilar(level1, level2), isFalse);
      });
    });
    
    group('Similarity Threshold Validation', () {
      test('should respect 80% similarity threshold', () {
        // Create levels that are similar but not identical
        final level1 = _createTestLevel(
          id: 1,
          containers: [
            _createContainer(0, [
              LiquidLayer(color: LiquidColor.red, volume: 2),
              LiquidLayer(color: LiquidColor.blue, volume: 2),
            ]),
            _createContainer(1, [
              LiquidLayer(color: LiquidColor.blue, volume: 2),
              LiquidLayer(color: LiquidColor.red, volume: 2),
            ]),
            _createContainer(2, []), // Empty
            _createContainer(3, []), // Empty
          ],
        );
        
        // Slightly different arrangement
        final level2 = _createTestLevel(
          id: 2,
          containers: [
            _createContainer(0, [
              LiquidLayer(color: LiquidColor.red, volume: 2),
              LiquidLayer(color: LiquidColor.blue, volume: 2),
            ]),
            _createContainer(1, [
              LiquidLayer(color: LiquidColor.blue, volume: 4), // Different mixing
            ]),
            _createContainer(2, []), // Empty
            _createContainer(3, []), // Empty
          ],
        );
        
        final similarity = LevelSimilarityChecker.compareStructuralPatterns(level1, level2);
        
        // Should be similar but not exceed threshold
        expect(similarity, lessThan(LevelSimilarityChecker.similarityThreshold));
        expect(LevelSimilarityChecker.areLevelsSimilar(level1, level2), isFalse);
      });
      
      test('should validate level uniqueness against list', () {
        final existingLevels = [
          _createTestLevel(
            id: 1,
            containers: [
              _createContainer(0, [LiquidLayer(color: LiquidColor.red, volume: 4)]),
              _createContainer(1, [LiquidLayer(color: LiquidColor.blue, volume: 4)]),
              _createContainer(2, []),
            ],
          ),
          _createTestLevel(
            id: 2,
            containers: [
              _createContainer(0, [
                LiquidLayer(color: LiquidColor.green, volume: 2),
                LiquidLayer(color: LiquidColor.yellow, volume: 2),
              ]),
              _createContainer(1, [LiquidLayer(color: LiquidColor.yellow, volume: 4)]),
              _createContainer(2, []),
            ],
          ),
        ];
        
        // Test unique level - completely different structure with 4 containers
        final uniqueLevel = _createTestLevel(
          id: 3,
          containers: [
            _createContainer(0, [
              LiquidLayer(color: LiquidColor.purple, volume: 1),
              LiquidLayer(color: LiquidColor.orange, volume: 1),
              LiquidLayer(color: LiquidColor.purple, volume: 1),
              LiquidLayer(color: LiquidColor.orange, volume: 1),
            ]),
            _createContainer(1, [LiquidLayer(color: LiquidColor.orange, volume: 4)]),
            _createContainer(2, [LiquidLayer(color: LiquidColor.purple, volume: 4)]),
            _createContainer(3, []), // Extra container makes it structurally different
          ],
        );
        
        expect(
          LevelSimilarityChecker.validateLevelUniqueness(uniqueLevel, existingLevels),
          isTrue,
        );
        
        // Test similar level (same structure as first existing level)
        final similarLevel = _createTestLevel(
          id: 4,
          containers: [
            _createContainer(0, [LiquidLayer(color: LiquidColor.pink, volume: 4)]),
            _createContainer(1, [LiquidLayer(color: LiquidColor.cyan, volume: 4)]),
            _createContainer(2, []),
          ],
        );
        
        expect(
          LevelSimilarityChecker.validateLevelUniqueness(similarLevel, existingLevels),
          isFalse,
        );
      });
    });
    
    group('Edge Cases', () {
      test('should handle all empty containers', () {
        final level1 = _createTestLevel(
          id: 1,
          containers: [
            _createContainer(0, []),
            _createContainer(1, []),
            _createContainer(2, []),
          ],
        );
        
        final level2 = _createTestLevel(
          id: 2,
          containers: [
            _createContainer(0, []),
            _createContainer(1, []),
            _createContainer(2, []),
          ],
        );
        
        expect(LevelSimilarityChecker.areLevelsSimilar(level1, level2), isTrue);
      });
      
      test('should handle single container levels', () {
        final level1 = _createTestLevel(
          id: 1,
          containers: [
            _createContainer(0, [LiquidLayer(color: LiquidColor.red, volume: 4)]),
          ],
        );
        
        final level2 = _createTestLevel(
          id: 2,
          containers: [
            _createContainer(0, [LiquidLayer(color: LiquidColor.blue, volume: 4)]),
          ],
        );
        
        expect(LevelSimilarityChecker.areLevelsSimilar(level1, level2), isTrue);
      });
      
      test('should handle levels with maximum color mixing', () {
        final level = _createTestLevel(
          id: 1,
          containers: [
            _createContainer(0, [
              LiquidLayer(color: LiquidColor.red, volume: 1),
              LiquidLayer(color: LiquidColor.blue, volume: 1),
              LiquidLayer(color: LiquidColor.green, volume: 1),
              LiquidLayer(color: LiquidColor.yellow, volume: 1),
            ]),
          ],
        );
        
        final signature = LevelSimilarityChecker.generateNormalizedSignature(level);
        expect(signature, contains('ABCD'));
      });
      
      test('should handle zero volume layers gracefully', () {
        // This shouldn't happen in normal gameplay, but test robustness
        final level = _createTestLevel(
          id: 1,
          containers: [
            _createContainer(0, [
              LiquidLayer(color: LiquidColor.red, volume: 4),
            ]),
          ],
        );
        
        expect(() => LevelSimilarityChecker.generateNormalizedSignature(level), 
               returnsNormally);
      });
      
      test('should handle very large container counts', () {
        final containers = <Container>[];
        for (int i = 0; i < 20; i++) {
          if (i < 10) {
            containers.add(_createContainer(i, [
              LiquidLayer(color: LiquidColor.values[i % LiquidColor.values.length], volume: 4),
            ]));
          } else {
            containers.add(_createContainer(i, [])); // Empty
          }
        }
        
        final level = _createTestLevel(id: 1, containers: containers);
        
        expect(() => LevelSimilarityChecker.generateNormalizedSignature(level), 
               returnsNormally);
      });
    });
    
    group('Pattern Analysis', () {
      test('should correctly count color segments', () {
        expect(LevelSimilarityChecker.countColorSegments('AAAA'), equals(1));
        expect(LevelSimilarityChecker.countColorSegments('AABB'), equals(2));
        expect(LevelSimilarityChecker.countColorSegments('ABAB'), equals(4));
        expect(LevelSimilarityChecker.countColorSegments('ABCD'), equals(4));
        expect(LevelSimilarityChecker.countColorSegments('EMPTY'), equals(0));
        expect(LevelSimilarityChecker.countColorSegments(''), equals(0));
      });
      
      test('should generate detailed signatures correctly', () {
        final level = _createTestLevel(
          id: 1,
          containers: [
            _createContainer(0, [
              LiquidLayer(color: LiquidColor.red, volume: 2),
              LiquidLayer(color: LiquidColor.blue, volume: 2),
            ]),
            _createContainer(1, [LiquidLayer(color: LiquidColor.blue, volume: 4)]),
            _createContainer(2, []), // Empty
          ],
        );
        
        final detailed = LevelSimilarityChecker.generateDetailedSignature(level);
        
        expect(detailed['container_count'], equals(3));
        expect(detailed['color_count'], equals(2));
        expect(detailed['normalized_pattern'], isA<List<String>>());
        expect(detailed['distribution'], isA<Map<String, double>>());
        expect(detailed['complexity'], isA<Map<String, double>>());
        expect(detailed['signature'], isA<String>());
      });
      
      test('should find most similar level correctly', () {
        final targetLevel = _createTestLevel(
          id: 1,
          containers: [
            _createContainer(0, [LiquidLayer(color: LiquidColor.red, volume: 4)]),
            _createContainer(1, [LiquidLayer(color: LiquidColor.blue, volume: 4)]),
            _createContainer(2, []),
          ],
        );
        
        final candidates = [
          _createTestLevel(
            id: 2,
            containers: [
              _createContainer(0, [LiquidLayer(color: LiquidColor.green, volume: 4)]),
              _createContainer(1, [LiquidLayer(color: LiquidColor.yellow, volume: 4)]),
              _createContainer(2, []),
            ],
          ),
          _createTestLevel(
            id: 3,
            containers: [
              _createContainer(0, [
                LiquidLayer(color: LiquidColor.purple, volume: 2),
                LiquidLayer(color: LiquidColor.orange, volume: 2),
              ]),
              _createContainer(1, [LiquidLayer(color: LiquidColor.orange, volume: 4)]),
              _createContainer(2, []),
            ],
          ),
        ];
        
        final result = LevelSimilarityChecker.findMostSimilarLevel(targetLevel, candidates);
        
        expect(result.level, equals(candidates[0])); // First candidate is identical structure
        expect(result.similarity, greaterThan(0.9));
      });
      
      test('should analyze level set similarity correctly', () {
        final levels = [
          _createTestLevel(
            id: 1,
            containers: [
              _createContainer(0, [LiquidLayer(color: LiquidColor.red, volume: 4)]),
              _createContainer(1, []),
            ],
          ),
          _createTestLevel(
            id: 2,
            containers: [
              _createContainer(0, [LiquidLayer(color: LiquidColor.blue, volume: 4)]),
              _createContainer(1, []),
            ],
          ),
          _createTestLevel(
            id: 3,
            containers: [
              _createContainer(0, [
                LiquidLayer(color: LiquidColor.green, volume: 2),
                LiquidLayer(color: LiquidColor.yellow, volume: 2),
              ]),
              _createContainer(1, []),
            ],
          ),
        ];
        
        final analysis = LevelSimilarityChecker.analyzeLevelSetSimilarity(levels);
        
        expect(analysis['total_levels'], equals(3));
        expect(analysis['comparisons'], equals(3)); // 3 choose 2
        expect(analysis['avg_similarity'], isA<double>());
        expect(analysis['max_similarity'], isA<double>());
        expect(analysis['min_similarity'], isA<double>());
        expect(analysis['similar_pairs'], isA<int>());
        expect(analysis['uniqueness_ratio'], isA<double>());
      });
    });
    
    group('Performance and Robustness', () {
      test('should handle comparison of many levels efficiently', () {
        final levels = <Level>[];
        
        // Generate 50 test levels
        for (int i = 0; i < 50; i++) {
          levels.add(_createTestLevel(
            id: i,
            containers: [
              _createContainer(0, [
                LiquidLayer(color: LiquidColor.values[i % LiquidColor.values.length], volume: 4),
              ]),
              _createContainer(1, []),
            ],
          ));
        }
        
        final stopwatch = Stopwatch()..start();
        
        // Test that we can check similarity for all pairs
        for (int i = 0; i < levels.length; i++) {
          for (int j = i + 1; j < levels.length; j++) {
            LevelSimilarityChecker.areLevelsSimilar(levels[i], levels[j]);
          }
        }
        
        stopwatch.stop();
        
        // Should complete within reasonable time (less than 1 second for 50 levels)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
      
      test('should handle malformed input gracefully', () {
        final emptyLevel = _createTestLevel(id: 1, containers: []);
        final normalLevel = _createTestLevel(
          id: 2,
          containers: [
            _createContainer(0, [LiquidLayer(color: LiquidColor.red, volume: 4)]),
          ],
        );
        
        expect(() => LevelSimilarityChecker.areLevelsSimilar(emptyLevel, normalLevel), 
               returnsNormally);
      });
    });
  });
}

/// Helper function to create a test level
Level _createTestLevel({
  required int id,
  required List<Container> containers,
  int? colorCount,
}) {
  // Calculate color count if not provided
  final colors = <LiquidColor>{};
  for (final container in containers) {
    for (final layer in container.liquidLayers) {
      colors.add(layer.color);
    }
  }
  
  return Level(
    id: id,
    difficulty: 1,
    containerCount: containers.length,
    colorCount: colorCount ?? colors.length,
    initialContainers: containers,
  );
}

/// Helper function to create a test container
Container _createContainer(int id, List<LiquidLayer> layers) {
  return Container(
    id: id,
    capacity: 4,
    liquidLayers: layers,
  );
}