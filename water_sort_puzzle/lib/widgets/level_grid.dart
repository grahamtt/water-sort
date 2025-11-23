import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/level.dart';
import '../services/level_generator.dart';
import '../services/progress_override.dart';
import '../services/test_mode_manager.dart';
import '../screens/game_screen.dart';

/// Widget that displays a grid of levels with test mode support
class LevelGrid extends StatelessWidget {
  final ProgressOverride progressOverride;
  final TestModeManager testModeManager;
  final LevelGenerator? levelGenerator;
  final int crossAxisCount;
  final double spacing;

  const LevelGrid({
    super.key,
    required this.progressOverride,
    required this.testModeManager,
    this.levelGenerator,
    this.crossAxisCount = 4,
    this.spacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.0,
      ),
      itemCount: _getMaxLevelCount(),
      itemBuilder: (context, index) {
        final levelId = index + 1;
        final isUnlocked = progressOverride.isLevelUnlocked(levelId);
        final isCompleted = progressOverride.isLevelCompleted(levelId);
        final isTestModeUnlock = testModeManager.isTestModeEnabled && 
                                !progressOverride.actualProgress.unlockedLevels.contains(levelId);

        return LevelTile(
          levelId: levelId,
          isUnlocked: isUnlocked,
          isCompleted: isCompleted,
          isTestModeUnlock: isTestModeUnlock,
          onTap: isUnlocked ? () => _navigateToLevel(context, levelId) : null,
        );
      },
    );
  }

  /// Get maximum level count based on test mode state
  int _getMaxLevelCount() {
    if (testModeManager.isTestModeEnabled) {
      return 100; // Show 100 levels in test mode
    }
    // In normal mode, show actual unlocked levels plus a few locked ones
    final actualUnlocked = progressOverride.actualProgress.unlockedLevels.length;
    return actualUnlocked + 5; // Show 5 additional locked levels
  }

  /// Navigate to game screen with proper test mode context
  void _navigateToLevel(BuildContext context, int levelId) {
    // Generate level for the selected ID
    final generator = levelGenerator ?? WaterSortLevelGenerator();
    
    // Calculate appropriate difficulty and parameters based on level ID
    final difficulty = ((levelId - 1) ~/ 10) + 1; // Increase difficulty every 10 levels
    final containerCount = 4 + (difficulty ~/ 3); // More containers for higher difficulty
    final colorCount = 3 + (difficulty ~/ 2); // More colors for higher difficulty
    
    final level = generator.generateLevel(levelId, difficulty, containerCount, colorCount);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(
          level: level,
          onLevelCompleted: (level, moves, timeInSeconds) {
            // Handle level completion through progress override
            _handleLevelCompletion(level, moves, timeInSeconds);
          },
        ),
      ),
    );
  }

  /// Handle level completion with test mode considerations
  void _handleLevelCompletion(Level level, int moves, int timeInSeconds) {
    // The ProgressOverride will handle whether to record this completion
    // based on whether it was legitimately unlocked
    progressOverride.completeLevel(
      levelId: level.id,
      moves: moves,
      timeInSeconds: timeInSeconds,
      minimumPossibleMoves: level.minimumMoves,
    );
  }
}

/// Individual tile representing a single level with test mode visual indicators
class LevelTile extends StatelessWidget {
  final int levelId;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isTestModeUnlock;
  final VoidCallback? onTap;

  const LevelTile({
    super.key,
    required this.levelId,
    required this.isUnlocked,
    required this.isCompleted,
    required this.isTestModeUnlock,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: getAccessibilityLabel(),
      hint: getAccessibilityHint(),
      button: isUnlocked,
      enabled: isUnlocked,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            border: Border.all(
              color: _getBorderColor(),
              width: isTestModeUnlock ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
                      '$levelId',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(),
                      ),
                      semanticsLabel: 'Level $levelId',
                    ),
                    // Completion indicator
                    if (isCompleted)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                        semanticLabel: 'Completed',
                      ),
                  ],
                ),
              ),
              // Test mode indicator (bug icon)
              if (isTestModeUnlock)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Semantics(
                    label: 'Test mode unlock',
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bug_report,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // Lock overlay for locked levels
              if (!isUnlocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 24,
                        semanticLabel: 'Locked',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get background color based on tile state
  Color _getBackgroundColor() {
    if (!isUnlocked) return Colors.grey.shade300;
    if (isTestModeUnlock) return Colors.orange.shade50;
    if (isCompleted) return Colors.green.shade50;
    return Colors.blue.shade50;
  }

  /// Get border color based on tile state
  Color _getBorderColor() {
    if (!isUnlocked) return Colors.grey;
    if (isTestModeUnlock) return Colors.orange;
    if (isCompleted) return Colors.green;
    return Colors.blue;
  }

  /// Get text color based on tile state
  Color _getTextColor() {
    if (!isUnlocked) return Colors.grey.shade600;
    return Colors.black87;
  }

  /// Get accessibility label for screen readers
  @visibleForTesting
  String getAccessibilityLabel() {
    final buffer = StringBuffer('Level $levelId');
    
    if (isCompleted) {
      buffer.write(', completed');
    } else if (!isUnlocked) {
      buffer.write(', locked');
    } else {
      buffer.write(', unlocked');
    }
    
    if (isTestModeUnlock) {
      buffer.write(', test mode unlock');
    }
    
    return buffer.toString();
  }

  /// Get accessibility hint for screen readers
  @visibleForTesting
  String getAccessibilityHint() {
    if (!isUnlocked) {
      return 'This level is locked and cannot be played';
    } else if (isTestModeUnlock) {
      return 'This level is unlocked in test mode. Tap to play. Progress will not be saved.';
    } else if (isCompleted) {
      return 'This level is completed. Tap to play again.';
    } else {
      return 'This level is unlocked. Tap to play.';
    }
  }
}