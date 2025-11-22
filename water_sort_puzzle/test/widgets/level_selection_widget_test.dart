import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/level.dart';
import 'package:water_sort_puzzle/models/container.dart' as game_models;
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/services/level_progression.dart';
import 'package:water_sort_puzzle/widgets/level_selection_widget.dart';

void main() {
  group('LevelSelectionWidget', () {
    late List<Level> testLevels;
    late LevelProgress testProgress;

    setUp(() {
      // Create test levels
      testLevels = [
        Level(
          id: 1,
          difficulty: 1,
          containerCount: 4,
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
              liquidLayers: [
                LiquidLayer(color: LiquidColor.blue, volume: 2),
                LiquidLayer(color: LiquidColor.red, volume: 2),
              ],
            ),
            game_models.Container(id: 2, capacity: 4, liquidLayers: []),
            game_models.Container(id: 3, capacity: 4, liquidLayers: []),
          ],
          tags: ['tutorial'],
        ),
        Level(
          id: 2,
          difficulty: 2,
          containerCount: 5,
          colorCount: 3,
          initialContainers: [
            game_models.Container(
              id: 0,
              capacity: 4,
              liquidLayers: [
                LiquidLayer(color: LiquidColor.red, volume: 4),
              ],
            ),
            game_models.Container(
              id: 1,
              capacity: 4,
              liquidLayers: [
                LiquidLayer(color: LiquidColor.blue, volume: 4),
              ],
            ),
            game_models.Container(
              id: 2,
              capacity: 4,
              liquidLayers: [
                LiquidLayer(color: LiquidColor.green, volume: 4),
              ],
            ),
            game_models.Container(id: 3, capacity: 4, liquidLayers: []),
            game_models.Container(id: 4, capacity: 4, liquidLayers: []),
          ],
        ),
        Level(
          id: 3,
          difficulty: 5,
          containerCount: 6,
          colorCount: 4,
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
              liquidLayers: [
                LiquidLayer(color: LiquidColor.green, volume: 2),
                LiquidLayer(color: LiquidColor.yellow, volume: 2),
              ],
            ),
            game_models.Container(
              id: 2,
              capacity: 4,
              liquidLayers: [
                LiquidLayer(color: LiquidColor.blue, volume: 2),
                LiquidLayer(color: LiquidColor.red, volume: 2),
              ],
            ),
            game_models.Container(
              id: 3,
              capacity: 4,
              liquidLayers: [
                LiquidLayer(color: LiquidColor.yellow, volume: 2),
                LiquidLayer(color: LiquidColor.green, volume: 2),
              ],
            ),
            game_models.Container(id: 4, capacity: 4, liquidLayers: []),
            game_models.Container(id: 5, capacity: 4, liquidLayers: []),
          ],
          tags: ['challenge'],
        ),
      ];

      // Create test progress
      testProgress = LevelProgress(
        unlockedLevels: {1, 2},
        completedLevels: {1},
        bestScores: {1: 5},
        completionTimes: {1: 120},
      );
    });

    testWidgets('displays levels in a grid layout', (WidgetTester tester) async {
      bool levelSelected = false;
      Level? selectedLevel;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelSelectionWidget(
              levels: testLevels,
              progress: testProgress,
              onLevelSelected: (level) {
                levelSelected = true;
                selectedLevel = level;
              },
            ),
          ),
        ),
      );

      // Verify grid layout is present
      expect(find.byType(GridView), findsOneWidget);
      
      // Verify all levels are displayed
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows correct level status indicators', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelSelectionWidget(
              levels: testLevels,
              progress: testProgress,
              onLevelSelected: (level) {},
            ),
          ),
        ),
      );

      // Level 1 should show completion checkmark
      expect(find.byIcon(Icons.check), findsOneWidget);
      
      // Level 3 should show lock icon (not unlocked)
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('calls onLevelSelected when level is tapped', (WidgetTester tester) async {
      bool levelSelected = false;
      Level? selectedLevel;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelSelectionWidget(
              levels: testLevels,
              progress: testProgress,
              onLevelSelected: (level) {
                levelSelected = true;
                selectedLevel = level;
              },
            ),
          ),
        ),
      );

      // Tap on level 1
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      expect(levelSelected, isTrue);
      expect(selectedLevel?.id, equals(1));
    });

    testWidgets('shows tutorial indicator for tutorial levels', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelSelectionWidget(
              levels: testLevels,
              progress: testProgress,
              onLevelSelected: (level) {},
            ),
          ),
        ),
      );

      // Level 1 is a tutorial level, should show 'T' indicator
      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('shows challenge indicator for challenge levels', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelSelectionWidget(
              levels: testLevels,
              progress: testProgress,
              onLevelSelected: (level) {},
            ),
          ),
        ),
      );

      // Level 3 is a challenge level, should show 'C' indicator
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('shows difficulty stars for unlocked levels', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelSelectionWidget(
              levels: testLevels,
              progress: testProgress,
              onLevelSelected: (level) {},
            ),
          ),
        ),
      );

      // Should show star icons for difficulty indication
      expect(find.byIcon(Icons.star), findsWidgets);
    });

    testWidgets('shows best score for completed levels', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelSelectionWidget(
              levels: testLevels,
              progress: testProgress,
              onLevelSelected: (level) {},
            ),
          ),
        ),
      );

      // Level 1 is completed with 5 moves, should show best score
      expect(find.text('5 moves'), findsOneWidget);
    });

    testWidgets('uses custom grid configuration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelSelectionWidget(
              levels: testLevels,
              progress: testProgress,
              onLevelSelected: (level) {},
              crossAxisCount: 3,
              spacing: 12.0,
            ),
          ),
        ),
      );

      // Verify the widget builds without error with custom configuration
      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('LevelTile', () {
    late Level testLevel;
    late LevelProgress testProgress;

    setUp(() {
      testLevel = Level(
        id: 1,
        difficulty: 3,
        containerCount: 4,
        colorCount: 2,
        initialContainers: [
          game_models.Container(id: 0, capacity: 4, liquidLayers: []),
          game_models.Container(id: 1, capacity: 4, liquidLayers: []),
          game_models.Container(id: 2, capacity: 4, liquidLayers: []),
          game_models.Container(id: 3, capacity: 4, liquidLayers: []),
        ],
      );

      testProgress = LevelProgress(
        unlockedLevels: {1},
        completedLevels: {},
        bestScores: {},
        completionTimes: {},
      );
    });

    testWidgets('displays level number', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelTile(
              level: testLevel,
              progress: testProgress,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('shows lock overlay for locked levels', (WidgetTester tester) async {
      final lockedProgress = LevelProgress(
        unlockedLevels: {},
        completedLevels: {},
        bestScores: {},
        completionTimes: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelTile(
              level: testLevel,
              progress: lockedProgress,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelTile(
              level: testLevel,
              progress: testProgress,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(LevelTile));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('shows completion indicator for completed levels', (WidgetTester tester) async {
      final completedProgress = LevelProgress(
        unlockedLevels: {1},
        completedLevels: {1},
        bestScores: {1: 3},
        completionTimes: {1: 90},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelTile(
              level: testLevel,
              progress: completedProgress,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('3 moves'), findsOneWidget);
    });
  });

  group('LevelSelectionHeader', () {
    late LevelProgress testProgress;

    setUp(() {
      testProgress = LevelProgress(
        unlockedLevels: {1, 2, 3},
        completedLevels: {1, 2},
        bestScores: {1: 5, 2: 7},
        completionTimes: {1: 120, 2: 180},
      );
    });

    testWidgets('displays progress information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelSelectionHeader(
              progress: testProgress,
              totalLevels: 10,
            ),
          ),
        ),
      );

      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('2 / 10 completed'), findsOneWidget);
      expect(find.text('3 unlocked'), findsOneWidget);
    });

    testWidgets('shows progress indicators', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelSelectionHeader(
              progress: testProgress,
              totalLevels: 10,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows filter chips when callback provided', (WidgetTester tester) async {
      String? selectedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelSelectionHeader(
              progress: testProgress,
              totalLevels: 10,
              onFilterChanged: (filter) {
                selectedFilter = filter;
              },
            ),
          ),
        ),
      );

      expect(find.byType(FilterChip), findsWidgets);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unlocked'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Tutorial'), findsOneWidget);
      expect(find.text('Challenge'), findsOneWidget);
    });

    testWidgets('calls filter callback when filter chip is tapped', (WidgetTester tester) async {
      String? selectedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelSelectionHeader(
              progress: testProgress,
              totalLevels: 10,
              currentFilter: null,
              onFilterChanged: (filter) {
                selectedFilter = filter;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(selectedFilter, equals('completed'));
    });

    testWidgets('does not show filter chips when callback not provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelSelectionHeader(
              progress: testProgress,
              totalLevels: 10,
            ),
          ),
        ),
      );

      expect(find.byType(FilterChip), findsNothing);
    });
  });
}