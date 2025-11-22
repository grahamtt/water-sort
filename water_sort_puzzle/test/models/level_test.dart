import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/models.dart';

void main() {
  group('Level', () {
    late List<Container> testContainers;
    
    setUp(() {
      testContainers = [
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
        Container(id: 2, capacity: 4, liquidLayers: []),
      ];
    });
    
    test('should create level with required parameters', () {
      final level = Level(
        id: 1,
        difficulty: 3,
        containerCount: 3,
        colorCount: 2,
        initialContainers: testContainers,
      );
      
      expect(level.id, equals(1));
      expect(level.difficulty, equals(3));
      expect(level.containerCount, equals(3));
      expect(level.colorCount, equals(2));
      expect(level.initialContainers, equals(testContainers));
      expect(level.isValidated, isFalse);
      expect(level.tags, isEmpty);
    });
    
    test('should create level with optional parameters', () {
      final level = Level(
        id: 1,
        difficulty: 5,
        containerCount: 3,
        colorCount: 2,
        initialContainers: testContainers,
        minimumMoves: 4,
        maxMoves: 10,
        isValidated: true,
        hint: 'Start with the red liquid',
        tags: ['tutorial', 'easy'],
      );
      
      expect(level.minimumMoves, equals(4));
      expect(level.maxMoves, equals(10));
      expect(level.isValidated, isTrue);
      expect(level.hint, equals('Start with the red liquid'));
      expect(level.tags, equals(['tutorial', 'easy']));
    });
    
    test('should identify tutorial levels', () {
      final tutorialLevel = Level(
        id: 1,
        difficulty: 1,
        containerCount: 3,
        colorCount: 2,
        initialContainers: testContainers,
        tags: ['tutorial'],
      );
      
      final normalLevel = Level(
        id: 2,
        difficulty: 3,
        containerCount: 3,
        colorCount: 2,
        initialContainers: testContainers,
      );
      
      expect(tutorialLevel.isTutorial, isTrue);
      expect(normalLevel.isTutorial, isFalse);
    });
    
    test('should identify challenge levels', () {
      final challengeLevel = Level(
        id: 1,
        difficulty: 8,
        containerCount: 3,
        colorCount: 2,
        initialContainers: testContainers,
        tags: ['challenge'],
      );
      
      final normalLevel = Level(
        id: 2,
        difficulty: 3,
        containerCount: 3,
        colorCount: 2,
        initialContainers: testContainers,
      );
      
      expect(challengeLevel.isChallenge, isTrue);
      expect(normalLevel.isChallenge, isFalse);
    });
    
    test('should count empty and filled containers correctly', () {
      final level = Level(
        id: 1,
        difficulty: 3,
        containerCount: 3,
        colorCount: 2,
        initialContainers: testContainers,
      );
      
      expect(level.emptyContainerCount, equals(1));
      expect(level.filledContainerCount, equals(2));
    });
    
    test('should calculate complexity score', () {
      final easyLevel = Level(
        id: 1,
        difficulty: 1,
        containerCount: 3,
        colorCount: 2,
        initialContainers: testContainers,
      );
      
      final hardLevel = Level(
        id: 2,
        difficulty: 8,
        containerCount: 6,
        colorCount: 4,
        initialContainers: testContainers,
      );
      
      expect(easyLevel.complexityScore, lessThan(hardLevel.complexityScore));
    });
    
    test('should validate structural correctness', () {
      // Valid level
      final validLevel = Level(
        id: 1,
        difficulty: 3,
        containerCount: 3,
        colorCount: 2,
        initialContainers: testContainers,
      );
      
      expect(validLevel.isStructurallyValid, isTrue);
      
      // Invalid level - wrong container count
      final invalidLevel1 = Level(
        id: 1,
        difficulty: 3,
        containerCount: 4, // Wrong count
        colorCount: 2,
        initialContainers: testContainers,
      );
      
      expect(invalidLevel1.isStructurallyValid, isFalse);
      
      // Invalid level - no empty containers
      final allFilledContainers = [
        Container(
          id: 0,
          capacity: 4,
          liquidLayers: [LiquidLayer(color: LiquidColor.red, volume: 4)],
        ),
        Container(
          id: 1,
          capacity: 4,
          liquidLayers: [LiquidLayer(color: LiquidColor.blue, volume: 4)],
        ),
      ];
      
      final invalidLevel2 = Level(
        id: 1,
        difficulty: 3,
        containerCount: 2,
        colorCount: 2,
        initialContainers: allFilledContainers,
      );
      
      expect(invalidLevel2.isStructurallyValid, isFalse);
    });
    
    test('should support copyWith', () {
      final original = Level(
        id: 1,
        difficulty: 3,
        containerCount: 3,
        colorCount: 2,
        initialContainers: testContainers,
      );
      
      final copy = original.copyWith(
        difficulty: 5,
        hint: 'New hint',
      );
      
      expect(copy.id, equals(original.id));
      expect(copy.difficulty, equals(5));
      expect(copy.hint, equals('New hint'));
      expect(copy.containerCount, equals(original.containerCount));
    });
    
    test('should implement equality correctly', () {
      final level1 = Level(
        id: 1,
        difficulty: 3,
        containerCount: 3,
        colorCount: 2,
        initialContainers: testContainers,
      );
      
      final level2 = Level(
        id: 1,
        difficulty: 3,
        containerCount: 3,
        colorCount: 2,
        initialContainers: testContainers,
      );
      
      final level3 = Level(
        id: 2,
        difficulty: 3,
        containerCount: 3,
        colorCount: 2,
        initialContainers: testContainers,
      );
      
      expect(level1, equals(level2));
      expect(level1, isNot(equals(level3)));
      expect(level1.hashCode, equals(level2.hashCode));
    });
    
    test('should serialize to and from JSON', () {
      final level = Level(
        id: 1,
        difficulty: 3,
        containerCount: 3,
        colorCount: 2,
        initialContainers: testContainers,
        minimumMoves: 4,
        hint: 'Test hint',
        tags: ['tutorial'],
      );
      
      final json = level.toJson();
      final deserializedLevel = Level.fromJson(json);
      
      expect(deserializedLevel, equals(level));
    });
    
    test('should have meaningful toString', () {
      final level = Level(
        id: 1,
        difficulty: 3,
        containerCount: 3,
        colorCount: 2,
        initialContainers: testContainers,
      );
      
      final string = level.toString();
      expect(string, contains('Level'));
      expect(string, contains('id: 1'));
      expect(string, contains('difficulty: 3'));
      expect(string, contains('containers: 3'));
      expect(string, contains('colors: 2'));
    });
  });
}