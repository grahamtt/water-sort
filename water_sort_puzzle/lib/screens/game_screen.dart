import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/level.dart';
import '../services/game_engine.dart';
import '../services/reverse_level_generator.dart';
import '../providers/game_state_provider.dart';
import '../widgets/container_widget.dart';
import '../widgets/victory_animation.dart';

/// Main game screen that uses the GameStateProvider for state management
class GameScreen extends StatefulWidget {
  /// Optional specific level to play
  final Level? level;
  
  /// Callback when level is completed
  final void Function(Level level, int moves, int timeInSeconds)? onLevelCompleted;
  
  const GameScreen({
    super.key,
    this.level,
    this.onLevelCompleted,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameStateProvider _gameStateProvider;
  late DateTime _levelStartTime;
  bool _isPaused = false;
  DateTime? _pauseStartTime;
  Duration _totalPausedTime = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    
    // Initialize the game state provider
    _gameStateProvider = GameStateProvider(
      gameEngine: WaterSortGameEngine(),
      levelGenerator: ReverseLevelGenerator(),
    );
    
    // Record start time
    _levelStartTime = DateTime.now();
    
    // Start the timer that updates every second
    _startTimer();
    
    // Initialize the level
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.level != null) {
        _gameStateProvider.initializeLevelFromData(widget.level!);
      } else {
        _gameStateProvider.initializeLevel(1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gameStateProvider.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Only update the UI if the widget is still mounted, not paused, and game is not completed
      if (mounted && !_isPaused && !(_gameStateProvider.isVictory || _gameStateProvider.currentGameState?.isCompleted == true)) {
        setState(() {
          // This will trigger a rebuild and update the timer display
        });
      }
    });
  }

  void _showVictoryDialog(GameState gameState) {
    // Calculate completion time excluding paused time
    final totalElapsed = DateTime.now().difference(_levelStartTime);
    final activeElapsed = totalElapsed - _totalPausedTime;
    final timeInSeconds = activeElapsed.inSeconds;
    
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _gameStateProvider.restartCurrentLevel();
                _gameStateProvider.dismissVictory();
                _levelStartTime = DateTime.now(); // Reset timer
              },
              child: const Text('Restart Level'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _gameStateProvider.progressToNextLevel();
                _gameStateProvider.dismissVictory();
                _levelStartTime = DateTime.now(); // Reset timer
              },
              child: const Text('Next Level'),
            ),
          ],
        );
      },
    );
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
                _gameStateProvider.restartCurrentLevel();
                _gameStateProvider.dismissVictory();
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
    return ChangeNotifierProvider.value(
      value: _gameStateProvider,
      child: Consumer<GameStateProvider>(
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
                              // Instructions or feedback message
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
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
        return LayoutBuilder(
          builder: (context, constraints) {
            // Calculate optimal grid layout to fit all containers on screen
            final containerCount = gameState.containers.length;
            final availableWidth = constraints.maxWidth;
            final availableHeight = constraints.maxHeight;
            
            // Try different column counts to find the best fit
            int bestCrossAxisCount = 3;
            double bestContainerHeight = 0;
            
            for (int cols = 2; cols <= 5; cols++) {
              final rows = (containerCount / cols).ceil();
              final spacing = 16.0;
              final padding = 16.0;
              
              // Calculate container dimensions for this layout
              final totalHorizontalSpacing = spacing * (cols - 1) + padding * 2;
              final totalVerticalSpacing = spacing * (rows - 1) + padding * 2;
              
              final containerWidth = (availableWidth - totalHorizontalSpacing) / cols;
              final containerHeight = (availableHeight - totalVerticalSpacing) / rows;
              
              // Container aspect ratio should be around 0.6 (width/height)
              // So height should be width / 0.6 = width * 1.67
              final idealHeight = containerWidth * 1.67;
              
              // Use the smaller of calculated height or ideal height
              final actualHeight = containerHeight < idealHeight ? containerHeight : idealHeight;
              
              // Choose layout that gives largest container height while fitting on screen
              if (actualHeight > bestContainerHeight && containerHeight >= actualHeight) {
                bestContainerHeight = actualHeight;
                bestCrossAxisCount = cols;
              }
            }
            
            // Calculate final aspect ratio
            final spacing = 16.0;
            final padding = 16.0;
            final totalHorizontalSpacing = spacing * (bestCrossAxisCount - 1) + padding * 2;
            final containerWidth = (availableWidth - totalHorizontalSpacing) / bestCrossAxisCount;
            final childAspectRatio = containerWidth / bestContainerHeight;
            
            return Stack(
              children: [
                GridView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: bestCrossAxisCount,
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: containerCount,
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
                    color: Colors.black.withValues(alpha: 0.3),
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
      },
    );
  }
}
