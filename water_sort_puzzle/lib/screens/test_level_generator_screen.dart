import 'package:flutter/material.dart';
import '../models/level.dart';
import '../services/reverse_level_generator.dart';
import '../services/level_generator.dart';
import '../services/level_parameters.dart';
import 'game_screen.dart';

/// Screen for generating test levels with custom parameters
/// Allows testing how each parameter affects difficulty
class TestLevelGeneratorScreen extends StatefulWidget {
  const TestLevelGeneratorScreen({super.key});

  @override
  State<TestLevelGeneratorScreen> createState() => _TestLevelGeneratorScreenState();
}

class _TestLevelGeneratorScreenState extends State<TestLevelGeneratorScreen> {
  // Parameter values
  int _difficulty = 1;
  int _colorCount = 2;
  int _containerCapacity = 4;
  int _emptySlots = 8;
  int _seed = 0;
  bool _returnBest = false;
  
  // Container count is calculated as: colorCount + ceil(emptySlots / containerCapacity)
  int get _containerCount => _colorCount + (_emptySlots / _containerCapacity).ceil();
  
  // Generated level
  Level? _generatedLevel;
  bool _isGenerating = false;
  String? _errorMessage;
  
  // Level generator
  late ReverseLevelGenerator _generator;

  @override
  void initState() {
    super.initState();
    _updateGenerator();
  }

  void _updateGenerator() {
    _generator = ReverseLevelGenerator(
      config: LevelGenerationConfig(seed: _seed, returnBest: _returnBest),
    );
  }

  /// Generate a new level with current parameters
  Future<void> _generateLevel() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedLevel = null;
    });

    try {
      // Validate parameters
      if (_colorCount < 1) {
        throw ArgumentError('Color count must be at least 1 (for tutorial levels)');
      }
      
      if (_containerCount < 2) {
        throw ArgumentError('Container count must be at least 2 (calculated from colorCount + ceil(emptySlots/capacity))');
      }
      
      if (_containerCapacity < 2) {
        throw ArgumentError('Container capacity must be at least 2');
      }

      // Create a new generator with the current seed and returnBest flag
      _updateGenerator();

      // Generate the level
      final level = _generator.generateLevel(
        999, // Test level ID
        _difficulty,
        _colorCount,
        _containerCapacity,
        _emptySlots,
      );

      setState(() {
        _generatedLevel = level;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isGenerating = false;
      });
    }
  }

  /// Play the generated level
  void _playLevel() {
    if (_generatedLevel == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          level: _generatedLevel,
          onLevelCompleted: (level, moves, time) {
            // Show completion stats
            _showCompletionDialog(moves, time);
          },
        ),
      ),
    );
  }

  /// Show completion dialog with stats
  void _showCompletionDialog(int moves, int timeInSeconds) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Level Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Moves: $moves'),
            Text('Time: ${timeInSeconds}s'),
            const SizedBox(height: 16),
            const Text(
              'Parameters:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Difficulty: $_difficulty'),
            Text('Colors: $_colorCount'),
            Text('Containers: $_containerCount (auto: colors + ceil(emptySlots/capacity))'),
            Text('Capacity: $_containerCapacity'),
            Text('Empty Slots: $_emptySlots'),
            Text('Return Best: ${_returnBest ? "Yes" : "No"}'),
            if (_generatedLevel != null && _generatedLevel!.tags.contains('best_invalid_candidate')) ...[
              const SizedBox(height: 8),
              const Text(
                '⚠️ VALIDATION FAILURES:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              ..._generatedLevel!.tags
                  .where((tag) => tag.startsWith('validation_failed:'))
                  .map((tag) => Text(
                        '  • ${tag.replaceFirst('validation_failed:', '')}',
                        style: const TextStyle(color: Colors.orange, fontSize: 12),
                      )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Level Generator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level Parameters',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adjust parameters to test how they affect difficulty',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Difficulty slider
            _buildParameterCard(
              title: 'Difficulty',
              value: _difficulty,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) => setState(() => _difficulty = value.toInt()),
              description: 'Controls scrambling intensity (1=easy, 10=hard)',
              recommendedValue: LevelParameters.calculateDifficultyForLevel(1),
            ),

            // Color count slider (container count auto-calculated)
            _buildParameterCard(
              title: 'Color Count',
              value: _colorCount,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) => setState(() => _colorCount = value.toInt()),
              description: 'Number of different colors (1 for tutorial, containers = colors + ceil(emptySlots/capacity))',
              recommendedValue: LevelParameters.calculateColorCount(_difficulty),
            ),

            // Container capacity slider
            _buildParameterCard(
              title: 'Container Capacity',
              value: _containerCapacity,
              min: 2,
              max: 8,
              divisions: 6,
              onChanged: (value) => setState(() => _containerCapacity = value.toInt()),
              description: 'Maximum units of liquid per container',
              recommendedValue: LevelParameters.calculateContainerCapacity(1),
            ),

            // Empty slots slider
            _buildParameterCard(
              title: 'Empty Slots',
              value: _emptySlots,
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: (value) => setState(() => _emptySlots = value.toInt()),
              description: 'Total number of empty slots across all containers',
              recommendedValue: LevelParameters.calculateEmptySlots(_difficulty, _containerCapacity),
            ),

            // Return Best toggle
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                title: const Text('Return Best Invalid Candidate'),
                subtitle: const Text(
                  'If no valid level is found, return the best candidate with validation failure info',
                ),
                value: _returnBest,
                onChanged: (value) {
                  setState(() {
                    _returnBest = value;
                    _updateGenerator();
                  });
                },
              ),
            ),

            // Seed input
            _buildParameterCard(
              title: 'Random Seed',
              value: _seed,
              min: 0,
              max: 1000,
              divisions: 100,
              onChanged: (value) => setState(() => _seed = value.toInt()),
              description: 'Seed for random generation (same seed = same level)',
              showRecommended: false,
            ),

            const SizedBox(height: 24),

            // Generate button
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateLevel,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.casino),
              label: Text(_isGenerating ? 'Generating...' : 'Generate Level'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Generated level info
            if (_generatedLevel != null) ...[
              const SizedBox(height: 16),
              Card(
                color: _generatedLevel!.tags.contains('best_invalid_candidate') 
                    ? Colors.orange[50] 
                    : Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _generatedLevel!.tags.contains('best_invalid_candidate')
                                ? Icons.warning
                                : Icons.check_circle,
                            color: _generatedLevel!.tags.contains('best_invalid_candidate')
                                ? Colors.orange
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _generatedLevel!.tags.contains('best_invalid_candidate')
                                  ? 'Best Invalid Candidate Generated'
                                  : 'Level Generated Successfully',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: _generatedLevel!.tags.contains('best_invalid_candidate')
                                        ? Colors.orange[900]
                                        : Colors.green[900],
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLevelStat('Difficulty', '${_generatedLevel!.difficulty}'),
                      _buildLevelStat('Colors', '${_generatedLevel!.colorCount}'),
                      _buildLevelStat('Containers', '${_generatedLevel!.containerCount}'),
                      _buildLevelStat('Empty Containers', '${_generatedLevel!.emptyContainerCount}'),
                      _buildLevelStat('Filled Containers', '${_generatedLevel!.filledContainerCount}'),
                      _buildLevelStat('Complexity Score', _generatedLevel!.complexityScore.toStringAsFixed(1)),
                      _buildLevelStat('Validated', _generatedLevel!.isValidated ? 'Yes' : 'No'),
                      
                      // Show validation failures if present
                      if (_generatedLevel!.tags.contains('best_invalid_candidate')) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'VALIDATION FAILURES:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._generatedLevel!.tags
                            .where((tag) => tag.startsWith('validation_failed:'))
                            .map((tag) => Padding(
                                  padding: const EdgeInsets.only(left: 28, top: 4),
                                  child: Text(
                                    '• ${tag.replaceFirst('validation_failed:', '').replaceAll('_', ' ')}',
                                    style: TextStyle(
                                      color: Colors.orange[800],
                                      fontSize: 13,
                                    ),
                                  ),
                                )),
                      ],
                      
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _playLevel,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play This Level'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Tips section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips for Testing',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildTip('Start with low difficulty to understand the base puzzle'),
                    _buildTip('Increase difficulty to see more scrambling'),
                    _buildTip('More colors = more complex sorting required'),
                    _buildTip('Fewer empty containers = harder to solve'),
                    _buildTip('Higher capacity = more liquid to manage'),
                    _buildTip('Use the same seed to reproduce a specific level'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a parameter control card
  Widget _buildParameterCard({
    required String title,
    required num value,
    required num min,
    required num max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String description,
    int? recommendedValue,
    bool showRecommended = true,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (showRecommended && recommendedValue != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Recommended for difficulty $_difficulty: $recommendedValue',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange[700],
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ],
            Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: divisions,
              label: value.toString(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  /// Build a level stat row
  Widget _buildLevelStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  /// Build a tip item
  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
