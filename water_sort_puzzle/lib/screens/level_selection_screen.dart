import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/test_mode_manager.dart';
import '../services/progress_notifier.dart';
import '../widgets/test_mode_indicator_widget.dart';
import '../widgets/test_mode_toggle.dart';
import '../widgets/level_grid.dart';

/// Enhanced level selection screen with test mode integration
class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Level'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Progress indicator
          Consumer<ProgressNotifier>(
            builder: (context, progressNotifier, child) {
              final completedCount = progressNotifier.completedLevels.length;
              final totalCount = progressNotifier.getEffectiveUnlockedLevels().length;
              final displayTotal = totalCount > 100 ? 100 : totalCount; // Cap display at 100
              
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    '$completedCount/$displayTotal',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
          // Settings/Debug menu access
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
            tooltip: 'Developer Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Test mode indicator (when active)
          Consumer<TestModeManager>(
            builder: (context, testModeManager, child) {
              return StreamBuilder<bool>(
                stream: testModeManager.testModeStream,
                initialData: testModeManager.isTestModeEnabled,
                builder: (context, snapshot) {
                  final indicator = testModeManager.getTestModeIndicator();
                  if (indicator == null) return const SizedBox.shrink();
                  
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: TestModeIndicatorWidget(indicator: indicator),
                    ),
                  );
                },
              );
            },
          ),
          // Progress bar
          Consumer<ProgressNotifier>(
            builder: (context, progressNotifier, child) {
              final completedCount = progressNotifier.completedLevels.length;
              final unlockedCount = progressNotifier.getEffectiveUnlockedLevels().length;
              final displayTotal = unlockedCount > 100 ? 100 : unlockedCount; // Cap display at 100
              final progress = displayTotal > 0 ? completedCount / displayTotal : 0.0;
              
              return Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress: $completedCount / $displayTotal levels completed',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Level grid
          Expanded(
            child: Consumer2<ProgressNotifier, TestModeManager>(
              builder: (context, progressNotifier, testModeManager, child) {
                return LevelGrid(
                  progressOverride: progressNotifier.progressOverride,
                  testModeManager: testModeManager,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Show settings dialog with test mode toggle
  void _showSettingsDialog(BuildContext context) {
    final testModeManager = context.read<TestModeManager>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Developer Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TestModeToggle(testModeManager: testModeManager),
            const SizedBox(height: 16),
            const Text(
              'Test Mode allows access to all levels for testing purposes. '
              'Progress made in test mode will not affect normal game progression.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}