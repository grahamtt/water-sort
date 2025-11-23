import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/widgets/game_over_overlay.dart';

void main() {
  group('GameOverOverlay', () {
    testWidgets('displays correct title and message', (WidgetTester tester) async {
      const testMessage = 'Test loss message';
      bool restartCalled = false;
      bool levelSelectCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverOverlay(
              message: testMessage,
              onRestart: () => restartCalled = true,
              onLevelSelect: () => levelSelectCalled = true,
            ),
          ),
        ),
      );

      // Wait for animations to start
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

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
            body: GameOverOverlay(
              message: 'Test message',
              onRestart: () => restartCalled = true,
              onLevelSelect: () => levelSelectCalled = true,
            ),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

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
            body: GameOverOverlay(
              message: 'Test message',
              onRestart: () => restartCalled = true,
              onLevelSelect: () => levelSelectCalled = true,
            ),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

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
            body: GameOverOverlay(
              message: 'Test message',
              onRestart: () => restartCalled = true,
              onLevelSelect: () => levelSelectCalled = true,
            ),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      // Tap the level select button
      await tester.tap(find.text('Level Select'));
      await tester.pump();

      // Verify the callback was called
      expect(levelSelectCalled, true);
      expect(restartCalled, false);
    });

    testWidgets('has proper overlay styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverOverlay(
              message: 'Test message',
              onRestart: () {},
              onLevelSelect: () {},
            ),
          ),
        ),
      );

      // Wait for initial animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check that the overlay container exists
      expect(find.byType(Container), findsWidgets);
      
      // Check that the card exists
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('animates properly on initialization', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverOverlay(
              message: 'Test message',
              onRestart: () {},
              onLevelSelect: () {},
            ),
          ),
        ),
      );

      // Initially, the overlay should be starting to animate
      await tester.pump();
      
      // Check that the GameOverOverlay widget is present
      expect(find.byType(GameOverOverlay), findsOneWidget);
      
      // Check that animation widgets are present (there may be multiple)
      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);

      // Pump through the animation
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      
      // The content should be visible after animation
      expect(find.text('Game Over'), findsOneWidget);
    });

    testWidgets('handles long messages properly', (WidgetTester tester) async {
      const longMessage = 'This is a very long message that should wrap properly '
          'and not cause any layout issues in the overlay. It should be displayed '
          'in a readable format with proper text alignment and should not overflow.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverOverlay(
              message: longMessage,
              onRestart: () {},
              onLevelSelect: () {},
            ),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      // Check that the long message is displayed
      expect(find.text(longMessage), findsOneWidget);
      
      // Verify no overflow occurs
      expect(tester.takeException(), isNull);
    });

    testWidgets('disposes animation controller properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverOverlay(
              message: 'Test message',
              onRestart: () {},
              onLevelSelect: () {},
            ),
          ),
        ),
      );

      // Wait for animations to start
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Remove the widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      // Verify no exceptions are thrown during disposal
      expect(tester.takeException(), isNull);
    });

    testWidgets('icon animation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverOverlay(
              message: 'Test message',
              onRestart: () {},
              onLevelSelect: () {},
            ),
          ),
        ),
      );

      // Wait for initial animation
      await tester.pump();
      
      // Check that the TweenAnimationBuilder is present for icon animation
      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
      
      // Pump through the icon animation
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      
      // The icon should be visible and properly sized
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.sentiment_dissatisfied));
      expect(iconWidget.size, greaterThan(0));
    });
  });
}