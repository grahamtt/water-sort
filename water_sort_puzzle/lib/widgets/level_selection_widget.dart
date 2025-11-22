import 'package:flutter/material.dart';
import '../models/level.dart';
import '../services/level_progression.dart';

/// Widget that displays a grid of selectable levels
class LevelSelectionWidget extends StatelessWidget {
  /// List of available levels
  final List<Level> levels;
  
  /// Current player progress
  final LevelProgress progress;
  
  /// Callback when a level is selected
  final void Function(Level level) onLevelSelected;
  
  /// Number of columns in the grid
  final int crossAxisCount;
  
  /// Spacing between grid items
  final double spacing;

  const LevelSelectionWidget({
    super.key,
    required this.levels,
    required this.progress,
    required this.onLevelSelected,
    this.crossAxisCount = 4,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 1.0,
        ),
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final level = levels[index];
          return LevelTile(
            level: level,
            progress: progress,
            onTap: () => onLevelSelected(level),
          );
        },
      ),
    );
  }
}

/// Individual tile representing a single level
class LevelTile extends StatelessWidget {
  /// The level this tile represents
  final Level level;
  
  /// Current player progress
  final LevelProgress progress;
  
  /// Callback when tile is tapped
  final VoidCallback onTap;

  const LevelTile({
    super.key,
    required this.level,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = progress.isLevelUnlocked(level.id);
    final isCompleted = progress.isLevelCompleted(level.id);
    final bestScore = progress.getBestScore(level.id);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _getTileColor(context, isUnlocked, isCompleted),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBorderColor(context, isUnlocked, isCompleted),
            width: 2,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Level number
                  Text(
                    '${level.id}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(context, isUnlocked, isCompleted),
                    ),
                  ),
                  
                  // Difficulty indicator
                  if (isUnlocked) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => Icon(
                          Icons.star,
                          size: 12,
                          color: index < level.difficulty ~/ 2
                              ? Colors.orange
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  ],
                  
                  // Best score
                  if (isCompleted && bestScore != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$bestScore moves',
                      style: TextStyle(
                        fontSize: 10,
                        color: _getTextColor(context, isUnlocked, isCompleted),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Status indicators
            Positioned(
              top: 4,
              right: 4,
              child: _buildStatusIcon(isUnlocked, isCompleted),
            ),
            
            // Lock overlay for locked levels
            if (!isUnlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            
            // Tutorial indicator
            if (level.isTutorial)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'T',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            
            // Challenge indicator
            if (level.isChallenge)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'C',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Get the background color for the tile
  Color _getTileColor(BuildContext context, bool isUnlocked, bool isCompleted) {
    if (!isUnlocked) {
      return Colors.grey[200]!;
    }
    
    if (isCompleted) {
      return Colors.green[100]!;
    }
    
    return Theme.of(context).colorScheme.surface;
  }

  /// Get the border color for the tile
  Color _getBorderColor(BuildContext context, bool isUnlocked, bool isCompleted) {
    if (!isUnlocked) {
      return Colors.grey[400]!;
    }
    
    if (isCompleted) {
      return Colors.green;
    }
    
    return Theme.of(context).colorScheme.primary;
  }

  /// Get the text color for the tile
  Color _getTextColor(BuildContext context, bool isUnlocked, bool isCompleted) {
    if (!isUnlocked) {
      return Colors.grey[600]!;
    }
    
    if (isCompleted) {
      return Colors.green[800]!;
    }
    
    return Theme.of(context).colorScheme.onSurface;
  }

  /// Build the status icon for the tile
  Widget _buildStatusIcon(bool isUnlocked, bool isCompleted) {
    if (!isUnlocked) {
      return const SizedBox.shrink();
    }
    
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 16,
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}

/// Widget that displays level statistics and filters
class LevelSelectionHeader extends StatelessWidget {
  /// Current player progress
  final LevelProgress progress;
  
  /// Total number of available levels
  final int totalLevels;
  
  /// Current filter (optional)
  final String? currentFilter;
  
  /// Callback when filter changes
  final void Function(String? filter)? onFilterChanged;

  const LevelSelectionHeader({
    super.key,
    required this.progress,
    required this.totalLevels,
    this.currentFilter,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = progress.totalCompletedLevels;
    final unlockedCount = progress.unlockedLevels.length;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '$completedCount / $totalLevels completed',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '$unlockedCount unlocked',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              CircularProgressIndicator(
                value: completedCount / totalLevels,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          
          // Progress bar
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: completedCount / totalLevels,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          
          // Filters (if callback provided)
          if (onFilterChanged != null) ...[
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: currentFilter == null,
                    onSelected: () => onFilterChanged!(null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Unlocked',
                    isSelected: currentFilter == 'unlocked',
                    onSelected: () => onFilterChanged!('unlocked'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Completed',
                    isSelected: currentFilter == 'completed',
                    onSelected: () => onFilterChanged!('completed'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Tutorial',
                    isSelected: currentFilter == 'tutorial',
                    onSelected: () => onFilterChanged!('tutorial'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Challenge',
                    isSelected: currentFilter == 'challenge',
                    onSelected: () => onFilterChanged!('challenge'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }
}