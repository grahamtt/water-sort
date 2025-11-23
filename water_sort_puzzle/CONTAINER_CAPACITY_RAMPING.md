# Container Capacity Ramping Feature

## Overview
Container capacity now increases progressively as players advance through levels, adding an extra dimension of difficulty scaling.

## Implementation

### Formula
```dart
containerCapacity = 4 + ((levelId - 1) ~/ 10)
```

### Progression Schedule
- **Levels 1-10**: Capacity 4
- **Levels 11-20**: Capacity 5
- **Levels 21-30**: Capacity 6
- **Levels 31-40**: Capacity 7
- **Levels 41-50**: Capacity 8
- And so on...

## Changes Made

### Core Files Modified

1. **`lib/providers/game_state_provider.dart`**
   - Added `_calculateContainerCapacityForLevel()` method
   - Updated `initializeLevel()` to calculate and pass containerCapacity to generators

2. **`lib/services/level_generator.dart`**
   - Updated `LevelGenerator` interface to accept `containerCapacity` parameter
   - Modified `WaterSortLevelGenerator.generateLevel()` signature
   - Updated all internal methods to use dynamic containerCapacity
   - Updated `generateLevelSeries()` to calculate capacity per level

3. **`lib/services/reverse_level_generator.dart`**
   - Updated `ReverseLevelGenerator.generateLevel()` signature
   - Modified `_createSolvedState()` to use passed containerCapacity
   - Updated `generateLevelSeries()` with capacity calculation

4. **`lib/services/level_generation_service.dart`**
   - Added `_calculateContainerCapacity()` helper method
   - Updated all `generateLevel()` calls to include containerCapacity
   - Updated `_createMinimalLevel()` to use dynamic capacity

### Test Files Updated
All test files have been updated to pass the containerCapacity parameter:
- `test/services/level_generator_test.dart`
- `test/reverse_level_generator_test.dart`
- `test/reverse_generator_optimization_test.dart`
- `test/services/level_generation_service_test.dart`
- `test/services/level_validator_optimization_integration_test.dart`
- `test/providers/game_state_provider_test.dart`
- `test/level_solvability_test.dart`
- `test_level_requirements.dart`
- `test_requirements_demo.dart`

### New Test File
- `test/container_capacity_ramping_test.dart` - Comprehensive tests for the ramping feature

## Benefits

1. **Progressive Difficulty**: Container capacity increases alongside other difficulty parameters
2. **More Complex Puzzles**: Larger containers allow for more intricate liquid arrangements
3. **Extended Gameplay**: Players experience fresh challenges as they progress
4. **Balanced Scaling**: Capacity increases gradually (every 10 levels) to maintain smooth difficulty curve

## Testing

All tests pass successfully:
```bash
flutter test test/container_capacity_ramping_test.dart
flutter test test/services/level_generator_test.dart
flutter test test/reverse_level_generator_test.dart
# ... and all other test suites
```

## Backward Compatibility

The change is fully backward compatible:
- Existing levels can be regenerated with appropriate capacity
- All validation and optimization logic works with variable capacity
- No breaking changes to the game engine or UI

## Usage Example

```dart
// In GameStateProvider
final containerCapacity = _calculateContainerCapacityForLevel(levelId);
final level = _levelGenerator.generateLevel(
  levelId,
  difficulty,
  containerCount,
  colorCount,
  containerCapacity,
);
```

## Future Enhancements

Potential improvements:
- Make the ramping formula configurable
- Add UI indicators showing current capacity
- Adjust difficulty scaling to account for capacity changes
- Consider non-linear capacity progression for very high levels
