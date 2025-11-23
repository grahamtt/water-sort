import 'package:flutter/material.dart';
import '../models/level.dart';
import '../services/level_generator.dart';
import '../services/reverse_level_generator.dart';
import '../services/level_progression.dart';
import '../storage/game_progress.dart';
import '../widgets/level_selection_widget.dart';
import 'game_screen.dart';

/// Screen that displays available levels for selection
class LevelSelectionScreen extends StatefulWidget {
  /// Optional initial progress to display
  final GameProgress? initialProgress;
  
  /// Optional custom level generator
  final LevelGenerator? levelGenerator;
  
  const LevelSelectionScreen({
    super.key,
    this.initialProgress,
    this.levelGenerator,
  });

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  late LevelProgressionManager _progressionManager;
  late GameProgress _gameProgress;
  late List<Level> _availableLevels;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLevels();
  }

  /// Initialize levels and progress
  void _initializeLevels() {
    // Initialize game progress
    _gameProgress = widget.initialProgress ?? GameProgress();
    
    // Initialize level generator
    final levelGenerator = widget.levelGenerator ?? ReverseLevelGenerator();
    
    // Generate initial levels (first 50 levels)
    _availableLevels = levelGenerator.generateLevelSeries(1, 50);
    
    // Create progression manager
    _progressionManager = LevelProgressionManager(
      initialProgress: LevelProgress(
        unlockedLevels: _gameProgress.unlockedLevels,
        completedLevels: _gameProgress.completedLevels,
        bestScores: _gameProgress.bestScores,
        completionTimes: _gameProgress.completionTimes,
        currentLevel: _gameProgress.currentLevel,
      ),
    );
    
    // Add levels to progression manager
    _progressionManager.addLevels(_availableLevels);
    
    setState(() {
      _isLoading = false;
    });
  }

  /// Handle level selection
  void _onLevelSelected(Level level) {
    if (!_progressionManager.progress.isLevelUnlocked(level.id)) {
      _showLevelLockedDialog(level);
      return;
    }

    // Navigate to game screen with selected level
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          level: level,
          onLevelCompleted: _onLevelCompleted,
        ),
      ),
    );
  }

  /// Handle level completion callback
  void _onLevelCompleted(Level level, int moves, int timeInSeconds) {
    setState(() {
      // Update progression
      _progressionManager.completeLevel(level.id, moves, timeInSeconds);
      
      // Update game progress
      _gameProgress = _gameProgress.completeLevel(
        levelId: level.id,
        moves: moves,
        timeInSeconds: timeInSeconds,
        minimumPossibleMoves: level.minimumMoves,
      );
    });

    // Show completion dialog
    _showLevelCompletedDialog(level, moves, timeInSeconds);
  }

  /// Show dialog when trying to access locked level
  void _showLevelLockedDialog(Level level) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Level Locked'),
        content: Text(
          'Complete previous levels to unlock Level ${level.id}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show dialog when level is completed
  void _showLevelCompletedDialog(Level level, int moves, int timeInSeconds) {
    final minutes = timeInSeconds ~/ 60;
    final seconds = timeInSeconds % 60;
    final timeString = '${minutes}m ${seconds}s';
    
    final bestScore = _gameProgress.getBestScore(level.id);
    final isNewBest = bestScore == null || moves < bestScore;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Level Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Level ${level.id} completed!'),
            const SizedBox(height: 8),
            Text('Moves: $moves'),
            Text('Time: $timeString'),
            if (isNewBest) ...[
              const SizedBox(height: 8),
              const Text(
                '🏆 New Best Score!',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
          if (level.id < _availableLevels.length)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                final nextLevel = _availableLevels.firstWhere(
                  (l) => l.id == level.id + 1,
                );
                _onLevelSelected(nextLevel);
              },
              child: const Text('Next Level'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Level'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '${_gameProgress.completedLevels.length}/${_availableLevels.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress bar
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress: ${_gameProgress.completedLevels.length} / ${_availableLevels.length} levels completed',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _gameProgress.completedLevels.length / _availableLevels.length,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Level grid
                Expanded(
                  child: LevelSelectionWidget(
                    levels: _availableLevels,
                    progress: _progressionManager.progress,
                    onLevelSelected: _onLevelSelected,
                  ),
                ),
              ],
            ),
    );
  }
}