import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/level.dart';
import '../services/dependency_injection.dart';
import '../services/test_mode_manager.dart';
import '../services/progress_override.dart';
import '../providers/game_state_provider.dart';
import '../widgets/container_widget.dart';
import '../widgets/victory_animation.dart';
import '../widgets/test_mode_indicator_widget.dart';

/// Main game screen that uses the GameStateProvider for state management
class GameScreen extends StatefulWidget {
  /// Optional specific level to play
  final Level? level;
  
  /// Level ID to generate if no level is provided
  final int? levelId;
  
  /// Callback when level is completed
  final void Function(Level level, int moves, int timeInSeconds)? onLevelCompleted;
  
  const GameScreen({
    super.key,
    this.level,
    this.levelId,
    this.onLevelCompleted,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late DateTime _levelStartTime;
  bool _isPaused = false;
  DateTime? _pauseStartTime;
  Duration _totalPausedTime = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    
    // Record start time
    _levelStartTime = DateTime.now();
    
    // Start the timer that updates every second
    _startTimer();
    
    // Initialize the level
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameStateProvider = context.read<GameStateProvider>();
      
      if (widget.level != null) {
        gameStateProvider.initializeLevelFromData(widget.level!);
      } else {
        final levelIdToUse = widget.levelId ?? 1;
        gameStateProvider.initializeLevel(levelIdToUse);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Only update the UI if the widget is still mounted, not paused, and game is not completed
      if (mounted && !_isPaused) {
        final gameStateProvider = context.read<GameStateProvider>();
        if (!(gameStateProvider.isVictory || gameStateProvider.currentGameState?.isCompleted == true)) {
          setState(() {
            // This will trigger a rebuild and update the timer display
          });
        }
      }
    });
  }

  void _showVictoryDialog(GameState gameState) {
    // Calculate completion time excluding paused time
    final totalElapsed = DateTime.now().difference(_levelStartTime);
    final activeElapsed = totalElapsed - _totalPausedTime;
    final timeInSeconds = activeElapsed.inSeconds;
    
    // Handle level completion with test mode awareness
    _handleLevelCompletion(gameState, timeInSeconds);
    
    // Call completion callback if provided
    if (widget.onLevelCompleted != null && widget.level != null) {
      widget.onLevelCompleted!(
        widget.level!,
        gameState.effectiveMoveCount,
        timeInSeconds,
      );
      
      // If we have a completion callback (from level selection), 
      // navigate back immediately and let the level selection handle the dialog
      Navigator.of(context).pop();
      return;
    }
    
    // Get dependencies from context
    final progressOverride = context.read<ProgressOverride>();
    final testModeManager = context.read<TestModeManager>();
    
    // Determine if this completion will be recorded in actual progress
    final isLegitimateCompletion = progressOverride.shouldRecordCompletion(gameState.levelId);
    final isTestMode = testModeManager.isTestModeEnabled;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final minutes = timeInSeconds ~/ 60;
        final seconds = timeInSeconds % 60;
        final timeString = '${minutes}m ${seconds}s';
        
        return AlertDialog(
          title: const Text('🎉 Level Complete! 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Congratulations! You solved Level ${gameState.levelId}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Moves: ${gameState.effectiveMoveCount}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Time: $timeString',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              // Show test mode warning if completion won't be recorded
              if (isTestMode && !isLegitimateCompletion) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(color: Colors.orange, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Test mode: This completion won\'t affect your actual progress.',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final gameStateProvider = context.read<GameStateProvider>();
                gameStateProvider.restartCurrentLevel();
                gameStateProvider.dismissVictory();
                _levelStartTime = DateTime.now(); // Reset timer
              },
              child: const Text('Restart Level'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                final gameStateProvider = context.read<GameStateProvider>();
                gameStateProvider.progressToNextLevel();
                gameStateProvider.dismissVictory();
                _levelStartTime = DateTime.now(); // Reset timer
              },
              child: const Text('Next Level'),
            ),
          ],
        );
      },
    );
  }

  /// Handle level completion with test mode awareness
  Future<void> _handleLevelCompletion(GameState gameState, int timeInSeconds) async {
    try {
      // Get ProgressOverride from context and use it to handle completion (respects test mode)
      final progressOverride = context.read<ProgressOverride>();
      final updatedProgress = await progressOverride.completeLevel(
        levelId: gameState.levelId,
        moves: gameState.effectiveMoveCount,
        timeInSeconds: timeInSeconds,
      );
      
      // Save the updated progress and refresh the ProgressOverride instance
      await DependencyInjection.instance.updateGameProgress(updatedProgress);
    } catch (e) {
      // Handle completion error gracefully
      debugPrint('Error completing level: $e');
    }
  }

  void _pauseGame() {
    setState(() {
      _isPaused = true;
      _pauseStartTime = DateTime.now();
    });
  }

  void _resumeGame() {
    if (_pauseStartTime != null) {
      final pauseDuration = DateTime.now().difference(_pauseStartTime!);
      _totalPausedTime += pauseDuration;
      _pauseStartTime = null;
    }
    setState(() {
      _isPaused = false;
    });
  }

  void _resetTimer() {
    _levelStartTime = DateTime.now();
    _totalPausedTime = Duration.zero;
    _pauseStartTime = null;
    setState(() {
      _isPaused = false;
    });
  }

  void _showPauseMenu() {
    _pauseGame();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Paused'),
          content: const Text('What would you like to do?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resumeGame();
              },
              child: const Text('Resume'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final gameStateProvider = context.read<GameStateProvider>();
                gameStateProvider.restartCurrentLevel();
                gameStateProvider.dismissVictory();
                _resetTimer();
              },
              child: const Text('Restart Level'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Exit to previous screen
              },
              child: const Text('Exit to Menu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameStateProvider>(
      builder: (context, provider, child) {
        final gameState = provider.currentGameState;
        
        // Show victory dialog when victory state is reached
        if (provider.isVictory && gameState != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showVictoryDialog(gameState);
          });
        }
        
        return Scaffold(
          appBar: AppBar(
            title: gameState != null 
                ? Text('Level ${gameState.levelId}')
                : const Text('Water Sort Puzzle'),
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            centerTitle: true,
            actions: [
              // Test mode indicator in AppBar
              Consumer<TestModeManager>(
                builder: (context, testModeManager, child) {
                  return StreamBuilder<bool>(
                    stream: testModeManager.testModeStream,
                    initialData: testModeManager.isTestModeEnabled,
                    builder: (context, snapshot) {
                      final indicator = testModeManager.getTestModeIndicator();
                      if (indicator == null) return const SizedBox.shrink();
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Center(
                          child: TestModeIndicatorWidget(indicator: indicator),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
            body: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.blue[50]!, Colors.blue[100]!],
                    ),
                  ),
                  child: SafeArea(
                    child: gameState == null
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: [
                              // Enhanced game info panel
                              Container(
                                margin: const EdgeInsets.all(16.0),
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Top row with level and status
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Level ${gameState.levelId}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue[800],
                                                  ),
                                            ),
                                            Text(
                                              '${gameState.containers.length} containers',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: gameState.isSolved
                                                ? Colors.green[100]
                                                : Colors.orange[100],
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: gameState.isSolved
                                                  ? Colors.green[300]!
                                                  : Colors.orange[300]!,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                gameState.isSolved
                                                    ? Icons.check_circle
                                                    : Icons.play_circle_outline,
                                                color: gameState.isSolved
                                                    ? Colors.green[700]
                                                    : Colors.orange[700],
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                gameState.isSolved ? 'Solved' : 'In Progress',
                                                style: TextStyle(
                                                  color: gameState.isSolved
                                                      ? Colors.green[700]
                                                      : Colors.orange[700],
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Bottom row with moves and undo info
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _InfoCard(
                                          icon: Icons.touch_app,
                                          value: '${gameState.effectiveMoveCount}',
                                          label: 'Moves',
                                          color: Colors.blue[700]!,
                                        ),
                                        _InfoCard(
                                          icon: Icons.undo,
                                          value: provider.canUndo ? 'Available' : 'None',
                                          label: 'Undo',
                                          color: provider.canUndo 
                                              ? Colors.green[700]! 
                                              : Colors.grey[500]!,
                                        ),
                                        _InfoCard(
                                          icon: Icons.timer,
                                          value: _getElapsedTime(),
                                          label: 'Time',
                                          color: Colors.purple[700]!,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Instructions or feedback message
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  provider.feedbackMessage ?? 
                                      'Tap a container to select it, then tap another to pour liquid',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: provider.feedbackMessage != null
                                            ? Colors.red[700]
                                            : Colors.grey[700],
                                        fontWeight: provider.feedbackMessage != null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Game board
                              Expanded(
                                child: _GameBoardSection(
                                  gameState: gameState,
                                  isPaused: _isPaused,
                                ),
                              ),

                              // Bottom control panel
                              Container(
                                margin: const EdgeInsets.all(16.0),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Undo button (duplicate for easy access)
                                    _ControlButton(
                                      icon: Icons.undo,
                                      label: 'Undo',
                                      onPressed: provider.canUndo && !provider.isAnimating && !_isPaused
                                          ? provider.undoMove
                                          : null,
                                      isEnabled: provider.canUndo && !provider.isAnimating && !_isPaused,
                                    ),
                                    // Restart button (duplicate for easy access)
                                    _ControlButton(
                                      icon: Icons.refresh,
                                      label: 'Restart',
                                      onPressed: !provider.isAnimating && !_isPaused
                                          ? () => provider.restartCurrentLevel()
                                          : null,
                                      isEnabled: !provider.isAnimating && !_isPaused,
                                    ),
                                    // Pause button (duplicate for easy access)
                                    _ControlButton(
                                      icon: _isPaused ? Icons.play_arrow : Icons.pause,
                                      label: _isPaused ? 'Resume' : 'Pause',
                                      onPressed: !provider.isAnimating
                                          ? _isPaused 
                                              ? _resumeGame
                                              : _showPauseMenu
                                          : null,
                                      isEnabled: !provider.isAnimating,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                // Victory animation overlay
                VictoryAnimation(
                  isVisible: provider.isVictory,
                  onAnimationComplete: () {
                    // Animation completes, but dialog is shown separately
                  },
                ),
                
                // Loading overlay
                if (provider.isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          );
        },
      );
  }

  /// Get elapsed time since level start in a formatted string
  String _getElapsedTime() {
    if (_isPaused) return 'Paused';
    
    // Calculate total elapsed time minus paused time
    final totalElapsed = DateTime.now().difference(_levelStartTime);
    final activeElapsed = totalElapsed - _totalPausedTime;
    
    final minutes = activeElapsed.inMinutes;
    final seconds = activeElapsed.inSeconds % 60;
    
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

/// Info card widget for displaying game statistics
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

/// Control button widget for the bottom control panel
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isEnabled;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isEnabled ? Colors.blue[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled ? Colors.blue[200]! : Colors.grey[300]!,
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: isEnabled ? Colors.blue[700] : Colors.grey[400],
              size: 24,
            ),
            tooltip: label,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isEnabled ? Colors.blue[700] : Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Separate widget for the game board section to handle container interactions
class _GameBoardSection extends StatelessWidget {
  final GameState gameState;
  final bool isPaused;
  
  const _GameBoardSection({
    required this.gameState,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameStateProvider>(
      builder: (context, provider, child) {
        return Stack(
          children: [
            GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.6,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: gameState.containers.length,
              itemBuilder: (context, index) {
                final container = gameState.containers[index];
                final isSelected = provider.selectedContainerId == container.id;
                
                return ContainerWidget(
                  container: container,
                  isSelected: isSelected,
                  showSelectionAnimation: true,
                  onTap: provider.isAnimating || isPaused
                      ? null 
                      : () => provider.selectContainer(container.id),
                );
              },
            ),
            // Pause overlay
            if (isPaused)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pause_circle_filled,
                        size: 64,
                        color: Colors.white,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Game Paused',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the pause button to resume',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
