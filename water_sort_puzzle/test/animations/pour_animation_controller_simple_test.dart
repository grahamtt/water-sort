import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/animations/pour_animation.dart';
import 'package:water_sort_puzzle/animations/pour_animation_controller.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';

void main() {
  group('PourAnimationController - Basic Tests', () {
    late PourAnimationController controller;

    setUp(() {
      controller = PourAnimationController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('should initialize with idle state', () {
      expect(controller.state, isA<IdleState>());
      expect(controller.isAnimating, isFalse);
      expect(controller.currentAnimation, isNull);
      expect(controller.progress, equals(PourAnimationProgress.start()));
    });

    test('should calculate container positions correctly', () {
      final containerSizes = [
        const Size(80, 120),
        const Size(80, 120),
        const Size(80, 120),
        const Size(80, 120),
      ];
      const boardSize = Size(400, 600);

      final positions = controller.calculateContainerPositions(containerSizes, boardSize);

      expect(positions.length, equals(4));
      
      // Verify positions are within board bounds
      for (final position in positions) {
        expect(position.dx, greaterThanOrEqualTo(0));
        expect(position.dy, greaterThanOrEqualTo(0));
        expect(position.dx + containerSizes.first.width, lessThanOrEqualTo(boardSize.width));
        expect(position.dy + containerSizes.first.height, lessThanOrEqualTo(boardSize.height));
      }
    });

    test('should handle empty container list', () {
      final positions = controller.calculateContainerPositions([], const Size(400, 600));
      expect(positions, isEmpty);
    });

    test('should return zero offset for invalid container indices', () {
      final containerPositions = [
        const Offset(0, 0),
        const Offset(100, 0),
      ];
      const containerSize = Size(80, 120);

      // Test with no current animation
      final sourcePos = controller.getSourcePosition(containerPositions, containerSize);
      final targetPos = controller.getTargetPosition(containerPositions, containerSize);

      expect(sourcePos, equals(Offset.zero));
      expect(targetPos, equals(Offset.zero));
    });
  });

  group('PourAnimationController - Animation Tests', () {
    testWidgets('should initialize and start basic animation', (WidgetTester tester) async {
      final controller = PourAnimationController();
      
      try {
        controller.initialize(tester);

        const animation = PourAnimation(
          fromContainer: 0,
          toContainer: 1,
          liquidColor: LiquidColor.red,
          volume: 2,
          duration: Duration(milliseconds: 50), // Very short duration
        );

        // Start animation
        controller.addPourAnimation(animation);
        await tester.pump();

        // Verify state changed to pouring
        expect(controller.state, isA<PouringState>());
        expect(controller.isAnimating, isTrue);
        expect(controller.currentAnimation, equals(animation));

        // Complete animation quickly
        await tester.pumpAndSettle();

        // Verify animation completed
        expect(controller.state, isA<IdleState>());
        expect(controller.isAnimating, isFalse);
        expect(controller.currentAnimation, isNull);
      } finally {
        controller.dispose();
      }
    });

    testWidgets('should handle victory animation', (WidgetTester tester) async {
      final controller = PourAnimationController();
      
      try {
        controller.initialize(tester);

        const duration = Duration(milliseconds: 50); // Very short duration

        // Start victory animation
        controller.startVictoryAnimation(duration: duration);
        await tester.pump();

        // Verify state changed to victory
        expect(controller.state, isA<VictoryState>());
        final victoryState = controller.state as VictoryState;
        expect(victoryState.celebrationDuration, equals(duration));

        // Complete victory animation manually
        controller.completeVictoryAnimation();
        await tester.pump();

        // Verify animation completed
        expect(controller.state, isA<IdleState>());
      } finally {
        controller.dispose();
      }
    });

    testWidgets('should stop animation manually', (WidgetTester tester) async {
      final controller = PourAnimationController();
      
      try {
        controller.initialize(tester);

        const animation = PourAnimation(
          fromContainer: 0,
          toContainer: 1,
          liquidColor: LiquidColor.yellow,
          volume: 3,
          duration: Duration(milliseconds: 1000), // Long duration
        );

        // Start animation
        controller.addPourAnimation(animation);
        await tester.pump();

        expect(controller.isAnimating, isTrue);

        // Stop animation
        controller.skipAllAnimations();
        await tester.pump();

        expect(controller.state, isA<IdleState>());
        expect(controller.isAnimating, isFalse);
        expect(controller.currentAnimation, isNull);
      } finally {
        controller.dispose();
      }
    });

    testWidgets('should create curved animations when initialized', (WidgetTester tester) async {
      final controller = PourAnimationController();
      
      try {
        controller.initialize(tester);

        final curvedAnimation = controller.createCurvedAnimation(
          begin: 0.0,
          end: 1.0,
          curve: Curves.bounceIn,
        );

        expect(curvedAnimation, isA<Animation<double>>());
      } finally {
        controller.dispose();
      }
    });

    testWidgets('should create color animations when initialized', (WidgetTester tester) async {
      final controller = PourAnimationController();
      
      try {
        controller.initialize(tester);

        final colorAnimation = controller.createColorAnimation(
          begin: Colors.red,
          end: Colors.blue,
          curve: Curves.linear,
        );

        expect(colorAnimation, isA<Animation<Color?>>());
      } finally {
        controller.dispose();
      }
    });

    test('should throw error when creating animations without initialization', () {
      final controller = PourAnimationController();
      
      try {
        expect(
          () => controller.createCurvedAnimation(
            begin: 0.0,
            end: 1.0,
            curve: Curves.linear,
          ),
          throwsStateError,
        );

        expect(
          () => controller.createColorAnimation(
            begin: Colors.red,
            end: Colors.blue,
            curve: Curves.linear,
          ),
          throwsStateError,
        );
      } finally {
        controller.dispose();
      }
    });
  });
}