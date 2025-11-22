import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/container.dart' as models;
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/widgets/container_widget.dart';
import 'package:water_sort_puzzle/animations/pour_animation.dart';
import 'package:water_sort_puzzle/animations/pour_animation_controller.dart';

void main() {
  group('ContainerWidget', () {
    late models.Container testContainer;
    
    setUp(() {
      testContainer = models.Container(
        id: 1,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 2),
          const LiquidLayer(color: LiquidColor.blue, volume: 1),
        ],
      );
    });
    
    testWidgets('renders container with liquid layers', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: testContainer,
            ),
          ),
        ),
      );
      
      // Verify the widget is rendered
      expect(find.byType(ContainerWidget), findsOneWidget);
      
      // Find CustomPaint within the ContainerWidget
      final containerWidget = find.byType(ContainerWidget);
      expect(find.descendant(
        of: containerWidget,
        matching: find.byType(CustomPaint),
      ), findsOneWidget);
    });
    
    testWidgets('handles tap events', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: testContainer,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );
      
      // Tap the container
      await tester.tap(find.byType(ContainerWidget));
      await tester.pump();
      
      expect(tapped, isTrue);
    });
    
    testWidgets('shows selection animation when selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: testContainer,
              isSelected: false,
            ),
          ),
        ),
      );
      
      // Initially not selected
      expect(find.byType(ContainerWidget), findsOneWidget);
      
      // Update to selected state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: testContainer,
              isSelected: true,
            ),
          ),
        ),
      );
      
      // Allow animation to start
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      
      expect(find.byType(ContainerWidget), findsOneWidget);
    });
    
    testWidgets('handles empty container', (WidgetTester tester) async {
      final emptyContainer = models.Container(
        id: 2,
        capacity: 4,
        liquidLayers: [],
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: emptyContainer,
            ),
          ),
        ),
      );
      
      expect(find.byType(ContainerWidget), findsOneWidget);
      
      // Find CustomPaint within the ContainerWidget
      final containerWidget = find.byType(ContainerWidget);
      expect(find.descendant(
        of: containerWidget,
        matching: find.byType(CustomPaint),
      ), findsOneWidget);
    });
    
    testWidgets('handles full container', (WidgetTester tester) async {
      final fullContainer = models.Container(
        id: 3,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 2),
          const LiquidLayer(color: LiquidColor.blue, volume: 2),
        ],
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: fullContainer,
            ),
          ),
        ),
      );
      
      expect(find.byType(ContainerWidget), findsOneWidget);
    });
    
    testWidgets('uses custom size when provided', (WidgetTester tester) async {
      const customSize = Size(100, 150);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: testContainer,
              size: customSize,
            ),
          ),
        ),
      );
      
      final containerWidget = tester.widget<ContainerWidget>(
        find.byType(ContainerWidget),
      );
      
      expect(containerWidget.size, equals(customSize));
    });
    
    testWidgets('calculates responsive size based on screen dimensions', (WidgetTester tester) async {
      // Test with different screen sizes
      await tester.binding.setSurfaceSize(const Size(400, 800)); // Small screen
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: testContainer,
            ),
          ),
        ),
      );
      
      expect(find.byType(ContainerWidget), findsOneWidget);
      
      // Test with larger screen
      await tester.binding.setSurfaceSize(const Size(800, 1200)); // Large screen
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: testContainer,
            ),
          ),
        ),
      );
      
      expect(find.byType(ContainerWidget), findsOneWidget);
    });
    
    testWidgets('disables selection animation when showSelectionAnimation is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: testContainer,
              isSelected: true,
              showSelectionAnimation: false,
            ),
          ),
        ),
      );
      
      expect(find.byType(ContainerWidget), findsOneWidget);
    });
    
    testWidgets('handles tap animation', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: testContainer,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );
      
      // Tap and verify animation
      await tester.tap(find.byType(ContainerWidget));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 75)); // Mid animation
      await tester.pump(const Duration(milliseconds: 150)); // End animation
      
      expect(tapped, isTrue);
    });
    
    testWidgets('handles container with single color (sorted)', (WidgetTester tester) async {
      final sortedContainer = models.Container(
        id: 4,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 4),
        ],
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: sortedContainer,
            ),
          ),
        ),
      );
      
      expect(find.byType(ContainerWidget), findsOneWidget);
      expect(sortedContainer.isSorted, isTrue);
    });
    
    testWidgets('handles container with multiple layers of same color', (WidgetTester tester) async {
      final multiLayerContainer = models.Container(
        id: 5,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 1),
          const LiquidLayer(color: LiquidColor.blue, volume: 1),
          const LiquidLayer(color: LiquidColor.red, volume: 1),
        ],
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: multiLayerContainer,
            ),
          ),
        ),
      );
      
      expect(find.byType(ContainerWidget), findsOneWidget);
    });

    testWidgets('integrates with pour animation controller', (WidgetTester tester) async {
      final animationController = PourAnimationController();
      animationController.initialize(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: testContainer,
              pourAnimationController: animationController,
            ),
          ),
        ),
      );

      expect(find.byType(ContainerWidget), findsOneWidget);

      // Verify animation controller is integrated
      final containerWidget = tester.widget<ContainerWidget>(
        find.byType(ContainerWidget),
      );
      expect(containerWidget.pourAnimationController, equals(animationController));

      animationController.dispose();
    });

    testWidgets('updates when pour animation progresses', (WidgetTester tester) async {
      final animationController = PourAnimationController();
      animationController.initialize(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: testContainer,
              pourAnimationController: animationController,
            ),
          ),
        ),
      );

      // Start pour animation
      const animation = PourAnimation(
        fromContainer: 1,
        toContainer: 2,
        liquidColor: LiquidColor.red,
        volume: 1,
        duration: Duration(milliseconds: 200),
      );

      animationController.startPourAnimation(animation);
      await tester.pump();

      // Verify animation is active
      expect(animationController.isAnimating, isTrue);

      // Advance animation
      await tester.pump(const Duration(milliseconds: 100));

      // Verify progress updated
      expect(animationController.progress.progress, greaterThan(0.0));

      // Complete animation
      await tester.pump(const Duration(milliseconds: 200));

      animationController.dispose();
    });

    testWidgets('renders pour animation effects for source container', (WidgetTester tester) async {
      final sourceContainer = models.Container(
        id: 0, // Source container ID
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 2),
        ],
      );

      final animationController = PourAnimationController();
      animationController.initialize(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: sourceContainer,
              pourAnimationController: animationController,
            ),
          ),
        ),
      );

      // Start pour animation from this container
      const animation = PourAnimation(
        fromContainer: 0,
        toContainer: 1,
        liquidColor: LiquidColor.red,
        volume: 1,
        duration: Duration(milliseconds: 100),
      );

      animationController.startPourAnimation(animation);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify container renders with pour effects
      expect(find.byType(ContainerWidget), findsOneWidget);

      animationController.dispose();
    });

    testWidgets('renders splash effects for target container', (WidgetTester tester) async {
      final targetContainer = models.Container(
        id: 1, // Target container ID
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.blue, volume: 1),
        ],
      );

      final animationController = PourAnimationController();
      animationController.initialize(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: targetContainer,
              pourAnimationController: animationController,
            ),
          ),
        ),
      );

      // Start pour animation to this container
      const animation = PourAnimation(
        fromContainer: 0,
        toContainer: 1,
        liquidColor: LiquidColor.red,
        volume: 1,
        duration: Duration(milliseconds: 100),
        showSplash: true,
      );

      animationController.startPourAnimation(animation);
      await tester.pump();
      
      // Advance to splash phase (60% through animation)
      await tester.pump(const Duration(milliseconds: 60));

      // Verify container renders with splash effects
      expect(find.byType(ContainerWidget), findsOneWidget);

      animationController.dispose();
    });

    testWidgets('handles animation without controller gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: testContainer,
              pourAnimationController: null, // No animation controller
            ),
          ),
        ),
      );

      expect(find.byType(ContainerWidget), findsOneWidget);
    });

    testWidgets('responds to victory animation', (WidgetTester tester) async {
      final animationController = PourAnimationController();
      animationController.initialize(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContainerWidget(
              container: testContainer,
              pourAnimationController: animationController,
            ),
          ),
        ),
      );

      // Start victory animation
      animationController.startVictoryAnimation(
        duration: const Duration(milliseconds: 100),
      );
      await tester.pump();

      // Verify victory state
      expect(animationController.state, isA<VictoryState>());

      // Complete animation
      await tester.pump(const Duration(milliseconds: 100));

      animationController.dispose();
    });
  });
  
  group('ContainerPainter', () {
    late models.Container testContainer;
    
    setUp(() {
      testContainer = models.Container(
        id: 1,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 2),
          const LiquidLayer(color: LiquidColor.blue, volume: 1),
        ],
      );
    });
    
    testWidgets('shouldRepaint returns true when container changes', (WidgetTester tester) async {
      final painter1 = ContainerPainter(
        container: testContainer,
        isSelected: false,
        selectionProgress: 0.0,
      );
      
      final differentContainer = models.Container(
        id: 2,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.green, volume: 1),
        ],
      );
      
      final painter2 = ContainerPainter(
        container: differentContainer,
        isSelected: false,
        selectionProgress: 0.0,
      );
      
      expect(painter1.shouldRepaint(painter2), isTrue);
    });
    
    testWidgets('shouldRepaint returns true when selection state changes', (WidgetTester tester) async {
      final painter1 = ContainerPainter(
        container: testContainer,
        isSelected: false,
        selectionProgress: 0.0,
      );
      
      final painter2 = ContainerPainter(
        container: testContainer,
        isSelected: true,
        selectionProgress: 1.0,
      );
      
      expect(painter1.shouldRepaint(painter2), isTrue);
    });
    
    testWidgets('shouldRepaint returns false when nothing changes', (WidgetTester tester) async {
      final painter1 = ContainerPainter(
        container: testContainer,
        isSelected: false,
        selectionProgress: 0.0,
      );
      
      final painter2 = ContainerPainter(
        container: testContainer,
        isSelected: false,
        selectionProgress: 0.0,
      );
      
      expect(painter1.shouldRepaint(painter2), isFalse);
    });
    
    testWidgets('painter handles empty container', (WidgetTester tester) async {
      final emptyContainer = models.Container(
        id: 2,
        capacity: 4,
        liquidLayers: [],
      );
      
      final painter = ContainerPainter(
        container: emptyContainer,
        isSelected: false,
        selectionProgress: 0.0,
      );
      
      // Test that painter can be created with empty container
      expect(painter.container.isEmpty, isTrue);
    });
    
    testWidgets('painter handles selection progress changes', (WidgetTester tester) async {
      final painter1 = ContainerPainter(
        container: testContainer,
        isSelected: true,
        selectionProgress: 0.0,
      );
      
      final painter2 = ContainerPainter(
        container: testContainer,
        isSelected: true,
        selectionProgress: 0.5,
      );
      
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    testWidgets('shouldRepaint returns true when pour animation changes', (WidgetTester tester) async {
      const animation1 = PourAnimation(
        fromContainer: 0,
        toContainer: 1,
        liquidColor: LiquidColor.red,
        volume: 1,
      );

      const animation2 = PourAnimation(
        fromContainer: 1,
        toContainer: 2,
        liquidColor: LiquidColor.blue,
        volume: 2,
      );

      const progress1 = PourAnimationProgress(
        progress: 0.5,
        streamPosition: Offset(10, 20),
        streamWidth: 5.0,
      );

      const progress2 = PourAnimationProgress(
        progress: 0.8,
        streamPosition: Offset(15, 25),
        streamWidth: 8.0,
      );

      final painter1 = ContainerPainter(
        container: testContainer,
        isSelected: false,
        selectionProgress: 0.0,
        pourProgress: progress1,
        pourAnimation: animation1,
      );

      final painter2 = ContainerPainter(
        container: testContainer,
        isSelected: false,
        selectionProgress: 0.0,
        pourProgress: progress2,
        pourAnimation: animation2,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    testWidgets('shouldRepaint returns true when pour progress changes', (WidgetTester tester) async {
      const animation = PourAnimation(
        fromContainer: 0,
        toContainer: 1,
        liquidColor: LiquidColor.red,
        volume: 1,
      );

      const progress1 = PourAnimationProgress(
        progress: 0.3,
        streamPosition: Offset(10, 20),
        streamWidth: 5.0,
      );

      const progress2 = PourAnimationProgress(
        progress: 0.7,
        streamPosition: Offset(10, 20),
        streamWidth: 5.0,
      );

      final painter1 = ContainerPainter(
        container: testContainer,
        isSelected: false,
        selectionProgress: 0.0,
        pourProgress: progress1,
        pourAnimation: animation,
      );

      final painter2 = ContainerPainter(
        container: testContainer,
        isSelected: false,
        selectionProgress: 0.0,
        pourProgress: progress2,
        pourAnimation: animation,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    testWidgets('shouldRepaint returns false when animation parameters are same', (WidgetTester tester) async {
      const animation = PourAnimation(
        fromContainer: 0,
        toContainer: 1,
        liquidColor: LiquidColor.red,
        volume: 1,
      );

      const progress = PourAnimationProgress(
        progress: 0.5,
        streamPosition: Offset(10, 20),
        streamWidth: 5.0,
      );

      final painter1 = ContainerPainter(
        container: testContainer,
        isSelected: false,
        selectionProgress: 0.0,
        pourProgress: progress,
        pourAnimation: animation,
      );

      final painter2 = ContainerPainter(
        container: testContainer,
        isSelected: false,
        selectionProgress: 0.0,
        pourProgress: progress,
        pourAnimation: animation,
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    testWidgets('painter handles null animation parameters', (WidgetTester tester) async {
      final painter = ContainerPainter(
        container: testContainer,
        isSelected: false,
        selectionProgress: 0.0,
        pourProgress: null,
        pourAnimation: null,
      );

      // Test that painter can be created with null animation parameters
      expect(painter.pourProgress, isNull);
      expect(painter.pourAnimation, isNull);
    });

    testWidgets('painter handles animation for source container', (WidgetTester tester) async {
      final sourceContainer = models.Container(
        id: 0,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.red, volume: 2),
        ],
      );

      const animation = PourAnimation(
        fromContainer: 0, // This container is the source
        toContainer: 1,
        liquidColor: LiquidColor.red,
        volume: 1,
      );

      const progress = PourAnimationProgress(
        progress: 0.5,
        streamPosition: Offset(10, 20),
        streamWidth: 5.0,
      );

      final painter = ContainerPainter(
        container: sourceContainer,
        isSelected: false,
        selectionProgress: 0.0,
        pourProgress: progress,
        pourAnimation: animation,
      );

      // Test that painter can handle source container animation
      expect(painter.container.id, equals(animation.fromContainer));
    });

    testWidgets('painter handles animation for target container', (WidgetTester tester) async {
      final targetContainer = models.Container(
        id: 1,
        capacity: 4,
        liquidLayers: [
          const LiquidLayer(color: LiquidColor.blue, volume: 1),
        ],
      );

      const animation = PourAnimation(
        fromContainer: 0,
        toContainer: 1, // This container is the target
        liquidColor: LiquidColor.red,
        volume: 1,
        showSplash: true,
      );

      const progress = PourAnimationProgress(
        progress: 0.8,
        streamPosition: Offset(15, 25),
        streamWidth: 3.0,
        showSplash: true,
        splashIntensity: 0.6,
      );

      final painter = ContainerPainter(
        container: targetContainer,
        isSelected: false,
        selectionProgress: 0.0,
        pourProgress: progress,
        pourAnimation: animation,
      );

      // Test that painter can handle target container animation
      expect(painter.container.id, equals(animation.toContainer));
      expect(painter.pourProgress!.showSplash, isTrue);
    });
  });
}