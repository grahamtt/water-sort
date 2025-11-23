import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../services/game_engine.dart';
import '../services/reverse_level_generator.dart';

/// Example widget demonstrating how to use GameStateProvider
/// This shows reactive UI updates, error handling, and user feedback
class GameStateExample extends StatelessWidget {
  const GameStateExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GameStateProvider(
        gameEngine: WaterSortGameEngine(),
        levelGenerator: ReverseLevelGenerator(),
      ),
      child: const _GameStateExampleContent(),
    );
  }
}

class _GameStateExampleContent extends StatelessWidget {
  const _GameStateExampleContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game State Provider Example')),
      body: Consumer<GameStateProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Loading indicator
              if (provider.isLoading) const LinearProgressIndicator(),

              // Error display
              if (provider.hasError)
                Container(
                  width: double.infinity,
                  color: Colors.red.shade100,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error: ${provider.errorMessage}',
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: provider.clearError,
                        child: const Text('Clear Error'),
                      ),
                    ],
                  ),
                ),

              // Feedback display
              if (provider.feedbackMessage != null)
                Container(
                  width: double.infinity,
                  color: provider.isVictory
                      ? Colors.green.shade100
                      : Colors.blue.shade100,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.feedbackMessage!,
                          style: TextStyle(
                            color: provider.isVictory
                                ? Colors.green.shade800
                                : Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (provider.isVictory)
                        ElevatedButton(
                          onPressed: provider.dismissVictory,
                          child: const Text('Continue'),
                        ),
                    ],
                  ),
                ),

              // Game controls
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: provider.isLoading
                          ? null
                          : () => provider.initializeLevel(1),
                      child: const Text('Initialize Level 1'),
                    ),
                    ElevatedButton(
                      onPressed: provider.isLoading
                          ? null
                          : () => provider.initializeLevel(5),
                      child: const Text('Initialize Level 5'),
                    ),
                    ElevatedButton(
                      onPressed: provider.canUndo && !provider.isAnimating
                          ? provider.undoMove
                          : null,
                      child: const Text('Undo'),
                    ),
                    ElevatedButton(
                      onPressed: provider.canRedo && !provider.isAnimating
                          ? provider.redoMove
                          : null,
                      child: const Text('Redo'),
                    ),
                    ElevatedButton(
                      onPressed: provider.isGameActive && !provider.isAnimating
                          ? provider.resetLevel
                          : null,
                      child: const Text('Reset'),
                    ),
                    ElevatedButton(
                      onPressed: provider.currentGameState != null
                          ? provider.saveGameState
                          : null,
                      child: const Text('Save'),
                    ),
                    ElevatedButton(
                      onPressed: provider.loadGameState,
                      child: const Text('Load'),
                    ),
                  ],
                ),
              ),

              // Game state display
              if (provider.currentGameState != null)
                Expanded(
                  child: _GameStateDisplay(
                    gameState: provider.currentGameState!,
                  ),
                ),

              // Container selection area
              if (provider.currentGameState != null) _ContainerSelectionArea(),
            ],
          );
        },
      ),
    );
  }
}

class _GameStateDisplay extends StatelessWidget {
  final dynamic gameState; // Using dynamic to avoid import issues

  const _GameStateDisplay({required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Game State',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Level: ${gameState.levelId}'),
            Text('Moves: ${gameState.effectiveMoveCount}'),
            Text('Completed: ${gameState.isCompleted}'),
            Text('Can Undo: ${gameState.canUndo}'),
            Text('Can Redo: ${gameState.canRedo}'),
            const SizedBox(height: 16),
            Text(
              'Containers: ${gameState.containers.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: gameState.containers.length,
                itemBuilder: (context, index) {
                  final container = gameState.containers[index];
                  return ListTile(
                    title: Text('Container ${container.id}'),
                    subtitle: Text(
                      'Layers: ${container.liquidLayers.length}, '
                      'Volume: ${container.currentVolume}/${container.capacity}, '
                      'Empty: ${container.isEmpty}, '
                      'Sorted: ${container.isSorted}',
                    ),
                    trailing: container.isEmpty
                        ? const Icon(Icons.circle_outlined)
                        : Icon(
                            Icons.circle,
                            color: _getColorForLiquid(
                              container.liquidLayers.last.color,
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForLiquid(dynamic liquidColor) {
    // Simple color mapping - in real app you'd use the actual LiquidColor
    return Colors.blue; // Placeholder
  }
}

class _ContainerSelectionArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameStateProvider>(
      builder: (context, provider, child) {
        if (provider.currentGameState == null) return const SizedBox.shrink();

        return Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Containers (Selected: ${provider.selectedContainerId ?? "None"})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.currentGameState!.containers.length,
                  itemBuilder: (context, index) {
                    final container =
                        provider.currentGameState!.containers[index];
                    final isSelected =
                        provider.selectedContainerId == container.id;
                    final isAnimating = provider.isAnimating;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: isAnimating
                            ? null
                            : () => provider.selectContainer(container.id),
                        child: Container(
                          width: 60,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey,
                              width: isSelected ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: container.isEmpty
                                ? Colors.grey.shade200
                                : Colors.blue.shade100,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${container.id}',
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              Text(
                                '${container.currentVolume}/${container.capacity}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (container.isEmpty)
                                const Icon(Icons.circle_outlined, size: 16)
                              else
                                const Icon(Icons.circle, size: 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
