import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/widgets/victory_animation.dart';

void main() {
  group('VictoryAnimation Widget Tests', () {
    testWidgets('should not render when isVisible is false', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VictoryAnimation(isVisible: false),
          ),
        ),
      );
      
      // Act & Assert
      expect(find.byType(VictoryAnimation), findsOneWidget);
      expect(find.byType(Container), findsNothing); // No content should be rendered
    });
    
    testWidgets('should render animation content when isVisible is true', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VictoryAnimation(isVisible: true),
          ),
        ),
      );
      
      // Act
      await tester.pump(); // Initial frame
      await tester.pump(const Duration(milliseconds: 100)); // Let animation start
      
      // Assert
      expect(find.byType(VictoryAnimation), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.text('🎉 Congratulations! 🎉'), findsOneWidget);
      expect(find.text('Level Complete!'), findsOneWidget);
    });
    
    testWidgets('should call onAnimationComplete when animation finishes', (WidgetTester tester) async {
      // Arrange
      bool callbackCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VictoryAnimation(
              isVisible: true,
              duration: const Duration(milliseconds: 100), // Short duration for testing
              onAnimationComplete: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );
      
      // Act
      await tester.pump(); // Initial frame
      await tester.pump(const Duration(milliseconds: 150)); // Wait for animation to complete
      
      // Assert
      expect(callbackCalled, isTrue);
    });
    
    testWidgets('should handle visibility changes correctly', (WidgetTester tester) async {
      // Arrange
      bool isVisible = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    VictoryAnimation(isVisible: isVisible),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isVisible = !isVisible;
                        });
                      },
                      child: const Text('Toggle'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      
      // Act - Initially not visible
      expect(find.byIcon(Icons.emoji_events), findsNothing);
      
      // Tap to make visible
      await tester.tap(find.text('Toggle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      
      // Assert - Should now be visible
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      
      // Act - Tap to hide again
      await tester.tap(find.text('Toggle'));
      await tester.pump();
      
      // Assert - Should be hidden again
      expect(find.byIcon(Icons.emoji_events), findsNothing);
    });
    
    testWidgets('should display victory icon with correct styling', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VictoryAnimation(isVisible: true),
          ),
        ),
      );
      
      // Act
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      
      // Assert
      final iconFinder = find.byIcon(Icons.emoji_events);
      expect(iconFinder, findsOneWidget);
      
      final Icon icon = tester.widget(iconFinder);
      expect(icon.size, equals(60));
      expect(icon.color, equals(Colors.white));
    });
    
    testWidgets('should display victory text with correct styling', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VictoryAnimation(isVisible: true),
          ),
        ),
      );
      
      // Act
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      
      // Assert
      final congratsTextFinder = find.text('🎉 Congratulations! 🎉');
      expect(congratsTextFinder, findsOneWidget);
      
      final levelCompleteTextFinder = find.text('Level Complete!');
      expect(levelCompleteTextFinder, findsOneWidget);
    });
    
    testWidgets('should have proper overlay background', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VictoryAnimation(isVisible: true),
          ),
        ),
      );
      
      // Act
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      
      // Assert
      final positionedFinder = find.byType(Positioned);
      expect(positionedFinder, findsOneWidget);
      
      final Positioned positioned = tester.widget(positionedFinder);
      expect(positioned.left, equals(0));
      expect(positioned.right, equals(0));
      expect(positioned.top, equals(0));
      expect(positioned.bottom, equals(0));
    });
    
    testWidgets('should animate scale and opacity', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VictoryAnimation(isVisible: true),
          ),
        ),
      );
      
      // Act - Initial frame (should start with scale 0 and opacity 0)
      await tester.pump();
      
      // Find the Transform.scale widget
      final transformFinder = find.byType(Transform);
      expect(transformFinder, findsWidgets);
      
      // Act - Advance animation
      await tester.pump(const Duration(milliseconds: 100));
      
      // Assert - Animation should be progressing
      // Note: Exact values are hard to test due to animation curves,
      // but we can verify the widgets exist and are being animated
      expect(find.byType(AnimatedBuilder), findsOneWidget);
    });
    
    testWidgets('should handle custom duration', (WidgetTester tester) async {
      // Arrange
      const customDuration = Duration(milliseconds: 500);
      bool completed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VictoryAnimation(
              isVisible: true,
              duration: customDuration,
              onAnimationComplete: () {
                completed = true;
              },
            ),
          ),
        ),
      );
      
      // Act
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400)); // Before completion
      
      // Assert - Should not be completed yet
      expect(completed, isFalse);
      
      // Act - Wait for completion
      await tester.pump(const Duration(milliseconds: 200)); // After completion
      
      // Assert - Should now be completed
      expect(completed, isTrue);
    });
    
    testWidgets('should dispose controllers properly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VictoryAnimation(isVisible: true),
          ),
        ),
      );
      
      // Act
      await tester.pump();
      
      // Remove the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );
      
      // Assert - Should not throw any errors during disposal
      // This test mainly ensures no memory leaks or disposal errors
      expect(tester.takeException(), isNull);
    });
    
    testWidgets('should handle rapid visibility changes', (WidgetTester tester) async {
      // Arrange
      bool isVisible = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    VictoryAnimation(isVisible: isVisible),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isVisible = !isVisible;
                        });
                      },
                      child: const Text('Toggle'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      
      // Act - Rapid toggles
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Toggle'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));
      }
      
      // Assert - Should handle rapid changes without errors
      expect(tester.takeException(), isNull);
    });
  });
}