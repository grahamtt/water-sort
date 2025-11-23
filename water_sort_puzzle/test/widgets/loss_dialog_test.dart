import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/widgets/loss_dialog.dart';

void main() {
  group('LossDialog', () {
    testWidgets('displays correct title and message', (WidgetTester tester) async {
      const testMessage = 'Test loss message';
      bool restartCalled = false;
      bool levelSelectCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LossDialog(
              message: testMessage,
              onRestart: () => restartCalled = true,
              onLevelSelect: () => levelSelectCalled = true,
            ),
          ),
        ),
      );

      // Check that the title is displayed
      expect(find.text('Game Over'), findsOneWidget);
      
      // Check that the message is displayed
      expect(find.text(testMessage), findsOneWidget);
      
      // Check that the sad face icon is displayed
      expect(find.byIcon(Icons.sentiment_dissatisfied), findsOneWidget);
    });

    testWidgets('displays action buttons', (WidgetTester tester) async {
      bool restartCalled = false;
      bool levelSelectCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LossDialog(
              message: 'Test message',
              onRestart: () => restartCalled = true,
              onLevelSelect: () => levelSelectCalled = true,
            ),
          ),
        ),
      );

      // Check that both buttons are displayed
      expect(find.text('Level Select'), findsOneWidget);
      expect(find.text('Restart Level'), findsOneWidget);
    });

    testWidgets('calls onRestart when restart button is tapped', (WidgetTester tester) async {
      bool restartCalled = false;
      bool levelSelectCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LossDialog(
              message: 'Test message',
              onRestart: () => restartCalled = true,
              onLevelSelect: () => levelSelectCalled = true,
            ),
          ),
        ),
      );

      // Tap the restart button
      await tester.tap(find.text('Restart Level'));
      await tester.pump();

      // Verify the callback was called
      expect(restartCalled, true);
      expect(levelSelectCalled, false);
    });

    testWidgets('calls onLevelSelect when level select button is tapped', (WidgetTester tester) async {
      bool restartCalled = false;
      bool levelSelectCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LossDialog(
              message: 'Test message',
              onRestart: () => restartCalled = true,
              onLevelSelect: () => levelSelectCalled = true,
            ),
          ),
        ),
      );

      // Tap the level select button
      await tester.tap(find.text('Level Select'));
      await tester.pump();

      // Verify the callback was called
      expect(levelSelectCalled, true);
      expect(restartCalled, false);
    });

    testWidgets('has proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LossDialog(
              message: 'Test message',
              onRestart: () {},
              onLevelSelect: () {},
            ),
          ),
        ),
      );

      // Check that the dialog is an AlertDialog
      expect(find.byType(AlertDialog), findsOneWidget);
      
      // Check that the icon has the correct color
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.sentiment_dissatisfied));
      expect(iconWidget.color, Colors.orange);
      expect(iconWidget.size, 48);
    });

    testWidgets('handles long messages properly', (WidgetTester tester) async {
      const longMessage = 'This is a very long message that should wrap properly '
          'and not cause any layout issues in the dialog. It should be displayed '
          'in a readable format with proper text alignment.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LossDialog(
              message: longMessage,
              onRestart: () {},
              onLevelSelect: () {},
            ),
          ),
        ),
      );

      // Check that the long message is displayed
      expect(find.text(longMessage), findsOneWidget);
      
      // Verify no overflow occurs
      expect(tester.takeException(), isNull);
    });
  });
}