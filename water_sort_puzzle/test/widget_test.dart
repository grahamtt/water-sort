// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/main.dart';
import 'package:water_sort_puzzle/widgets/game_board_widget.dart';
import 'package:water_sort_puzzle/widgets/container_widget.dart';

void main() {
  testWidgets('Water Sort Puzzle app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WaterSortPuzzleApp());

    // Verify that the app loads with the game screen
    expect(find.text('Water Sort Puzzle'), findsOneWidget);
    expect(find.byType(GameBoardWidget), findsOneWidget);
    
    // Verify that containers are displayed
    expect(find.byType(ContainerWidget), findsWidgets);
    
    // Verify that game info is displayed
    expect(find.text('Moves'), findsOneWidget);
    expect(find.text('Current Level'), findsOneWidget);
    expect(find.text('Solved'), findsOneWidget);
    
    // Verify that instructions are shown
    expect(find.textContaining('Tap a container'), findsOneWidget);
  });
}
