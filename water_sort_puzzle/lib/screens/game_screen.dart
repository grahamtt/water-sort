import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/container.dart' as models;
import '../models/liquid_color.dart';
import '../models/liquid_layer.dart';
import '../services/game_engine.dart';
import '../widgets/game_board_widget.dart';

/// Main game screen that demonstrates the GameBoardWidget functionality
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameEngine _gameEngine;
  late GameState _gameState;

  @override
  void initState() {
    super.initState();
    _gameEngine = WaterSortGameEngine();
    _initializeGame();
  }

  void _initializeGame() {
    // Create a sample level with mixed containers
    final containers = [
      models.Container(
        id: 1,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 2),
          const LiquidLayer(color: LiquidColor.blue, volume: 1),
          const LiquidLayer(color: LiquidColor.yellow, volume: 1),
        ],
      ),
      models.Container(
        id: 2,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.green, volume: 1),
          const LiquidLayer(color: LiquidColor.red, volume: 2),
        ],
      ),
      models.Container(
        id: 3,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.blue, volume: 2),
          const LiquidLayer(color: LiquidColor.green, volume: 1),
        ],
      ),
      models.Container(
        id: 4,
        capacity: 4,
        liquidLayers: [const LiquidLayer(color: LiquidColor.yellow, volume: 3)],
      ),
      models.Container(id: 5, capacity: 4, liquidLayers: []),
      models.Container(id: 6, capacity: 4, liquidLayers: []),
    ];

    _gameState = _gameEngine.initializeLevel(1, containers);
  }

  void _handlePourAttempted(int fromContainerId, int toContainerId) {
    // This callback is called whenever a pour is attempted
    debugPrint('Pour attempted: $fromContainerId -> $toContainerId');
  }

  void _handleGameStateChanged(GameState newGameState) {
    setState(() {
      _gameState = newGameState;
    });

    // Check for win condition
    if (_gameEngine.checkWinCondition(newGameState)) {
      _showVictoryDialog();
    }
  }

  void _showVictoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🎉 Congratulations!'),
          content: Text(
            'You solved the puzzle in ${_gameState.moveCount} moves!',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              child: const Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  void _resetGame() {
    setState(() {
      _initializeGame();
    });
  }

  void _undoMove() {
    final newState = _gameEngine.undoLastMove(_gameState);
    if (newState != null) {
      setState(() {
        _gameState = newState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Sort Puzzle'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _gameState.canUndo ? _undoMove : null,
            icon: const Icon(Icons.undo),
            tooltip: 'Undo last move',
          ),
          IconButton(
            onPressed: _resetGame,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset game',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.blue[100]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Game info panel
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${_gameState.moveCount}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                        ),
                        const Text('Moves'),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Level ${_gameState.levelId}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Text('Current Level'),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(
                          _gameState.isSolved
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: _gameState.isSolved
                              ? Colors.green
                              : Colors.grey,
                          size: 24,
                        ),
                        const Text('Solved'),
                      ],
                    ),
                  ],
                ),
              ),

              // Instructions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Tap a container to select it, then tap another to pour liquid',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Game board
              Expanded(
                child: GameBoardWidget(
                  gameState: _gameState,
                  gameEngine: _gameEngine,
                  onPourAttempted: _handlePourAttempted,
                  onGameStateChanged: _handleGameStateChanged,
                  containerSpacing: 16.0,
                  showSelectionAnimations: true,
                  showPourAnimations: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
