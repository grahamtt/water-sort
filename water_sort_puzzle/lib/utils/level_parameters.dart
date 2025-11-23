/// Utility class for calculating level generation parameters
/// 
/// This class centralizes the logic for determining valid combinations of
/// containers and colors based on game constraints.
class LevelParameters {
  /// Standard container capacity (number of liquid units per container)
  static const int defaultContainerCapacity = 4;
  
  /// Minimum number of empty slots required for a valid level
  static const int defaultMinEmptySlots = 1;

  /// Calculate the maximum number of colors that can fit in the given number
  /// of containers while maintaining the minimum empty slots requirement.
  /// 
  /// The calculation ensures: 
  /// `containerCount * containerCapacity - colorCount * containerCapacity >= minEmptySlots`
  /// 
  /// Which simplifies to:
  /// `colorCount <= (containerCount * containerCapacity - minEmptySlots) / containerCapacity`
  /// 
  /// Example with default values (containerCapacity=4, minEmptySlots=1):
  /// - 4 containers: max 3 colors (16 total capacity - 12 liquid = 4 empty slots)
  /// - 5 containers: max 4 colors (20 total capacity - 16 liquid = 4 empty slots)
  /// - 6 containers: max 5 colors (24 total capacity - 20 liquid = 4 empty slots)
  static int calculateMaxColors({
    required int containerCount,
    int containerCapacity = defaultContainerCapacity,
    int minEmptySlots = defaultMinEmptySlots,
  }) {
    if (containerCount <= 0) {
      throw ArgumentError('Container count must be positive');
    }
    if (containerCapacity <= 0) {
      throw ArgumentError('Container capacity must be positive');
    }
    if (minEmptySlots < 0) {
      throw ArgumentError('Minimum empty slots cannot be negative');
    }

    final totalCapacity = containerCount * containerCapacity;
    final maxLiquidVolume = totalCapacity - minEmptySlots;
    
    // Ensure we have enough capacity for at least one color
    if (maxLiquidVolume < containerCapacity) {
      return 0;
    }

    return maxLiquidVolume ~/ containerCapacity;
  }

  /// Validate that a given combination of containers and colors is valid
  /// according to the minimum empty slots requirement.
  static bool isValidConfiguration({
    required int containerCount,
    required int colorCount,
    int containerCapacity = defaultContainerCapacity,
    int minEmptySlots = defaultMinEmptySlots,
  }) {
    if (containerCount <= 0 || colorCount < 0) {
      return false;
    }

    final totalCapacity = containerCount * containerCapacity;
    final totalLiquidVolume = colorCount * containerCapacity;
    final emptySlots = totalCapacity - totalLiquidVolume;

    return emptySlots >= minEmptySlots;
  }

  /// Calculate the minimum number of containers needed for a given number
  /// of colors while maintaining the minimum empty slots requirement.
  static int calculateMinContainers({
    required int colorCount,
    int containerCapacity = defaultContainerCapacity,
    int minEmptySlots = defaultMinEmptySlots,
  }) {
    if (colorCount < 0) {
      throw ArgumentError('Color count cannot be negative');
    }

    final totalLiquidVolume = colorCount * containerCapacity;
    final minCapacity = totalLiquidVolume + minEmptySlots;
    
    // Round up to get the minimum number of containers
    return (minCapacity + containerCapacity - 1) ~/ containerCapacity;
  }
}
