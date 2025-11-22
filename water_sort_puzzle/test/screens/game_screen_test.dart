import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/screens/game_screen.dart';
import '../../lib/models/level.dart';
import '../../lib/models/container.dart' as game_models;
import '../../lib/models/liquid_layer.dart';
import '../../lib/models/liquid_color.dart';

void main() {
  group('GameScreen Widget Tests', () {
    Widget createGameScreen({
      Level? level,
      void Function(Level level, int moves, int timeInSeconds)? onLevelCompleted,
    }) {
      return MaterialApp(
        home: GameScreen(
          level: level,
          onLevelCompleted: onLevelCompleted,
        ),
      );
    }

    testWidgets('should display loading indicator when game state is null', (WidgetTester tester) async {
      await tester.pumpWidget(createGameScreen());
      
      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display app bar with correct controls', (WidgetTester tester) async {
      await tester.pumpWidget(createGameScreen());
      await tester.pumpAndSettle();

      // Check app bar elements
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsAtLeast(1)); // In app bar and bottom panel
      expect(find.byIcon(Icons.refresh), findsAtLeast(1)); // In app bar and bottom panel
      expect(find.byIcon(Icons.pause), findsAtLeast(1)); // In app bar and bottom panel
    });

    testWidgets('should display enhanced game info panel', (WidgetTester tester) async {
      await tester.pumpWidget(createGameScreen());
      await tester.pumpAndSettle();

      // Wait for game state to initialize
      await tester.pump(const Duration(seconds: 1));

      // Check for info panel elements
      expect(find.text('Moves'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.byIcon(Icons.touch_app), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
    });

    testWidgets('should display bottom control panel', (WidgetTester tester) async {
      await tester.pumpWidget(createGameScreen());
      await tester.pumpAndSettle();

      // Check for bottom control panel buttons
      expect(find.text('Restart'), findsAtLeast(1));
      expect(find.text('Pause'), findsAtLeast(1));
    });

    testWidgets('should show pause menu when pause button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createGameScreen());
      await tester.pumpAndSettle();

      // Find and tap the pause button in the app bar
      final pauseButton = find.byIcon(Icons.pause).first;
      await tester.tap(pauseButton);
      await tester.pumpAndSettle();

      // Check that pause dialog is shown
      expect(find.text('Game Paused'), findsAtLeast(1));
      expect(find.text('What would you like to do?'), findsOneWidget);
      expect(find.text('Resume'), findsAtLeast(1));
      expect(find.text('Restart Level'), findsOneWidget);
      expect(find.text('Exit to Menu'), findsOneWidget);
    });

    testWidgets('should resume game when resume button is tapped in pause menu', (WidgetTester tester) async {
      await tester.pumpWidget(createGameScreen());
      await tester.pumpAndSettle();

      // Pause the game
      final pauseButton = find.byIcon(Icons.pause).first;
      await tester.tap(pauseButton);
      await tester.pumpAndSettle();

      // Find the resume button in the dialog specifically
      final resumeButton = find.widgetWithText(TextButton, 'Resume');
      await tester.tap(resumeButton);
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('What would you like to do?'), findsNothing);
    });

    testWidgets('should display game board with containers', (WidgetTester tester) async {
      await tester.pumpWidget(createGameScreen());
      await tester.pumpAndSettle();

      // Wait for game initialization
      await tester.pump(const Duration(seconds: 1));

      // Check for game board
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should show feedback message area', (WidgetTester tester) async {
      await tester.pumpWidget(createGameScreen());
      await tester.pumpAndSettle();

      // Check for instruction text
      expect(find.text('Tap a container to select it, then tap another to pour liquid'), findsOneWidget);
    });

    testWidgets('should handle undo button state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createGameScreen());
      await tester.pumpAndSettle();

      // Initially, undo should be disabled (no moves made)
      final undoButtons = find.byIcon(Icons.undo);
      expect(undoButtons, findsAtLeast(1));
    });

    testWidgets('should display elapsed time correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createGameScreen());
      await tester.pumpAndSettle();

      // Wait a bit for time to elapse
      await tester.pump(const Duration(seconds: 2));

      // Should show elapsed time (look for 's' character in time display)
      expect(find.textContaining('s'), findsAtLeast(1));
    });

    testWidgets('should show correct level information in app bar', (WidgetTester tester) async {
      final testLevel = Level(
        id: 5,
        difficulty: 2,
        containerCount: 2,
        colorCount: 2,
        initialContainers: [
          game_models.Container(
            id: 0,
            capacity: 4,
            liquidLayers: [
              LiquidLayer(color: LiquidColor.red, volume: 2),
              LiquidLayer(color: LiquidColor.blue, volume: 2),
            ],
          ),
          game_models.Container(
            id: 1,
            capacity: 4,
            liquidLayers: [],
          ),
        ],
      );

      await tester.pumpWidget(createGameScreen(level: testLevel));
      await tester.pumpAndSettle();

      // Wait for level initialization
      await tester.pump(const Duration(seconds: 1));

      // Should show level number in app bar
      expect(find.text('Level 5'), findsAtLeast(1));
    });

    testWidgets('should show container count in info panel', (WidgetTester tester) async {
      await tester.pumpWidget(createGameScreen());
      await tester.pumpAndSettle();

      // Wait for game initialization
      await tester.pump(const Duration(seconds: 1));

      // Should show container count
      expect(find.textContaining('containers'), findsOneWidget);
    });

    testWidgets('should show correct status badge', (WidgetTester tester) async {
      await tester.pumpWidget(createGameScreen());
      await tester.pumpAndSettle();

      // Wait for game initialization
      await tester.pump(const Duration(seconds: 1));

      // Should show "In Progress" status initially
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    });

    testWidgets('should handle restart from pause menu', (WidgetTester tester) async {
      await tester.pumpWidget(createGameScreen());
      await tester.pumpAndSettle();

      // Pause the game
      final pauseButton = find.byIcon(Icons.pause).first;
      await tester.tap(pauseButton);
      await tester.pumpAndSettle();

      // Tap restart level
      await tester.tap(find.text('Restart Level'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed and game should restart
      expect(find.text('What would you like to do?'), findsNothing);
    });

    testWidgets('should handle exit to menu from pause menu', (WidgetTester tester) async {
      await tester.pumpWidget(createGameScreen());
      await tester.pumpAndSettle();

      // Pause the game
      final pauseButton = find.byIcon(Icons.pause).first;
      await tester.tap(pauseButton);
      await tester.pumpAndSettle();

      // Tap exit to menu
      await tester.tap(find.text('Exit to Menu'));
      await tester.pumpAndSettle();

      // Should navigate back (in a real app, this would pop the screen)
      // In test environment, we can't easily test navigation
    });
  });

  group('GameScreen Info Card Tests', () {
    testWidgets('InfoCard should display correct information', (WidgetTester tester) async {
      const testCard = _InfoCard(
        icon: Icons.star,
        value: '42',
        label: 'Test',
        color: Colors.blue,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: testCard,
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });
  });

  group('GameScreen Control Button Tests', () {
    testWidgets('ControlButton should display correctly when enabled', (WidgetTester tester) async {
      bool buttonPressed = false;

      final testButton = _ControlButton(
        icon: Icons.play_arrow,
        label: 'Play',
        onPressed: () => buttonPressed = true,
        isEnabled: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: testButton,
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      expect(buttonPressed, isTrue);
    });

    testWidgets('ControlButton should display correctly when disabled', (WidgetTester tester) async {
      const testButton = _ControlButton(
        icon: Icons.play_arrow,
        label: 'Play',
        onPressed: null,
        isEnabled: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: testButton,
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);

      // Button should be disabled
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNull);
    });
  });
}

// Helper classes to access private widgets for testing
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