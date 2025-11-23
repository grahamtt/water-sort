import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/utils/level_parameters.dart';

void main() {
  group('LevelParameters', () {
    group('calculateMaxColors', () {
      test('should calculate correct max colors with default parameters', () {
        expect(LevelParameters.calculateMaxColors(containerCount: 4), equals(3));
        expect(LevelParameters.calculateMaxColors(containerCount: 5), equals(4));
        expect(LevelParameters.calculateMaxColors(containerCount: 6), equals(5));
        expect(LevelParameters.calculateMaxColors(containerCount: 7), equals(6));
        expect(LevelParameters.calculateMaxColors(containerCount: 8), equals(7));
      });

      test('should handle custom container capacity', () {
        expect(
          LevelParameters.calculateMaxColors(
            containerCount: 4,
            containerCapacity: 5,
            minEmptySlots: 1,
          ),
          equals(3), // (4*5-1)/5 = 19/5 = 3
        );
      });

      test('should handle custom minimum empty slots', () {
        expect(
          LevelParameters.calculateMaxColors(
            containerCount: 4,
            containerCapacity: 4,
            minEmptySlots: 4,
          ),
          equals(3), // (4*4-4)/4 = 12/4 = 3
        );
      });

      test('should return 0 when not enough capacity for one color', () {
        expect(
          LevelParameters.calculateMaxColors(
            containerCount: 1,
            containerCapacity: 4,
            minEmptySlots: 4,
          ),
          equals(0), // (1*4-4)/4 = 0/4 = 0
        );
      });

      test('should throw on invalid parameters', () {
        expect(
          () => LevelParameters.calculateMaxColors(containerCount: 0),
          throwsArgumentError,
        );
        expect(
          () => LevelParameters.calculateMaxColors(
            containerCount: 4,
            containerCapacity: 0,
          ),
          throwsArgumentError,
        );
        expect(
          () => LevelParameters.calculateMaxColors(
            containerCount: 4,
            minEmptySlots: -1,
          ),
          throwsArgumentError,
        );
      });
    });

    group('isValidConfiguration', () {
      test('should validate correct configurations', () {
        expect(
          LevelParameters.isValidConfiguration(
            containerCount: 4,
            colorCount: 3,
          ),
          isTrue,
        );
        expect(
          LevelParameters.isValidConfiguration(
            containerCount: 5,
            colorCount: 4,
          ),
          isTrue,
        );
      });

      test('should reject invalid configurations', () {
        // 4 containers with 4 colors leaves no empty slots
        expect(
          LevelParameters.isValidConfiguration(
            containerCount: 4,
            colorCount: 4,
          ),
          isFalse,
        );
        // 5 colors need at least 6 containers
        expect(
          LevelParameters.isValidConfiguration(
            containerCount: 5,
            colorCount: 5,
          ),
          isFalse,
        );
      });

      test('should handle edge cases', () {
        expect(
          LevelParameters.isValidConfiguration(
            containerCount: 0,
            colorCount: 0,
          ),
          isFalse,
        );
        expect(
          LevelParameters.isValidConfiguration(
            containerCount: 4,
            colorCount: 0,
          ),
          isTrue,
        );
      });
    });

    group('calculateMinContainers', () {
      test('should calculate minimum containers needed', () {
        expect(
          LevelParameters.calculateMinContainers(colorCount: 3),
          equals(4), // 3*4+1 = 13, ceil(13/4) = 4
        );
        expect(
          LevelParameters.calculateMinContainers(colorCount: 4),
          equals(5), // 4*4+1 = 17, ceil(17/4) = 5
        );
        expect(
          LevelParameters.calculateMinContainers(colorCount: 5),
          equals(6), // 5*4+1 = 21, ceil(21/4) = 6
        );
      });

      test('should handle zero colors', () {
        expect(
          LevelParameters.calculateMinContainers(colorCount: 0),
          equals(1), // 0*4+1 = 1, ceil(1/4) = 1
        );
      });

      test('should handle custom parameters', () {
        expect(
          LevelParameters.calculateMinContainers(
            colorCount: 3,
            containerCapacity: 5,
            minEmptySlots: 2,
          ),
          equals(4), // 3*5+2 = 17, ceil(17/5) = 4
        );
      });

      test('should throw on negative color count', () {
        expect(
          () => LevelParameters.calculateMinContainers(colorCount: -1),
          throwsArgumentError,
        );
      });
    });
  });
}
