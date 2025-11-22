import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:water_sort_puzzle/animations/pour_animation.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';

void main() {
  group('PourAnimation', () {
    test('should create animation with required parameters', () {
      const animation = PourAnimation(
        fromContainer: 0,
        toContainer: 1,
        liquidColor: LiquidColor.red,
        volume: 2,
      );

      expect(animation.fromContainer, equals(0));
      expect(animation.toContainer, equals(1));
      expect(animation.liquidColor, equals(LiquidColor.red));
      expect(animation.volume, equals(2));
      expect(animation.duration, equals(const Duration(milliseconds: 800)));
      expect(animation.curve, equals(Curves.easeInOut));
      expect(animation.showSplash, isTrue);
    });

    test('should create animation with custom parameters', () {
      const animation = PourAnimation(
        fromContainer: 2,
        toContainer: 3,
        liquidColor: LiquidColor.blue,
        volume: 1,
        duration: Duration(milliseconds: 1000),
        curve: Curves.bounceIn,
        showSplash: false,
      );

      expect(animation.fromContainer, equals(2));
      expect(animation.toContainer, equals(3));
      expect(animation.liquidColor, equals(LiquidColor.blue));
      expect(animation.volume, equals(1));
      expect(animation.duration, equals(const Duration(milliseconds: 1000)));
      expect(animation.curve, equals(Curves.bounceIn));
      expect(animation.showSplash, isFalse);
    });

    test('should create copy with modified properties', () {
      const original = PourAnimation(
        fromContainer: 0,
        toContainer: 1,
        liquidColor: LiquidColor.red,
        volume: 2,
      );

      final copy = original.copyWith(
        liquidColor: LiquidColor.green,
        volume: 3,
        showSplash: false,
      );

      expect(copy.fromContainer, equals(0));
      expect(copy.toContainer, equals(1));
      expect(copy.liquidColor, equals(LiquidColor.green));
      expect(copy.volume, equals(3));
      expect(copy.duration, equals(const Duration(milliseconds: 800)));
      expect(copy.curve, equals(Curves.easeInOut));
      expect(copy.showSplash, isFalse);
    });

    test('should implement equality correctly', () {
      const animation1 = PourAnimation(
        fromContainer: 0,
        toContainer: 1,
        liquidColor: LiquidColor.red,
        volume: 2,
      );

      const animation2 = PourAnimation(
        fromContainer: 0,
        toContainer: 1,
        liquidColor: LiquidColor.red,
        volume: 2,
      );

      const animation3 = PourAnimation(
        fromContainer: 0,
        toContainer: 1,
        liquidColor: LiquidColor.blue,
        volume: 2,
      );

      expect(animation1, equals(animation2));
      expect(animation1, isNot(equals(animation3)));
      expect(animation1.hashCode, equals(animation2.hashCode));
      expect(animation1.hashCode, isNot(equals(animation3.hashCode)));
    });

    test('should have meaningful toString', () {
      const animation = PourAnimation(
        fromContainer: 0,
        toContainer: 1,
        liquidColor: LiquidColor.red,
        volume: 2,
      );

      final string = animation.toString();
      expect(string, contains('PourAnimation'));
      expect(string, contains('from: 0'));
      expect(string, contains('to: 1'));
      expect(string, contains('color: LiquidColor.red'));
      expect(string, contains('volume: 2'));
    });
  });

  group('AnimationState', () {
    test('IdleState should implement equality', () {
      const state1 = IdleState();
      const state2 = IdleState();

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('PouringState should implement equality', () {
      const animation1 = PourAnimation(
        fromContainer: 0,
        toContainer: 1,
        liquidColor: LiquidColor.red,
        volume: 2,
      );

      const animation2 = PourAnimation(
        fromContainer: 0,
        toContainer: 1,
        liquidColor: LiquidColor.red,
        volume: 2,
      );

      const animation3 = PourAnimation(
        fromContainer: 1,
        toContainer: 2,
        liquidColor: LiquidColor.blue,
        volume: 1,
      );

      const state1 = PouringState(animation1);
      const state2 = PouringState(animation2);
      const state3 = PouringState(animation3);

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('VictoryState should implement equality', () {
      const state1 = VictoryState(Duration(milliseconds: 2000));
      const state2 = VictoryState(Duration(milliseconds: 2000));
      const state3 = VictoryState(Duration(milliseconds: 1000));

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
      expect(state1.hashCode, equals(state2.hashCode));
    });
  });

  group('PourAnimationProgress', () {
    test('should create progress with all parameters', () {
      const progress = PourAnimationProgress(
        progress: 0.5,
        streamPosition: Offset(10, 20),
        streamWidth: 5.0,
        showSplash: true,
        splashIntensity: 0.8,
      );

      expect(progress.progress, equals(0.5));
      expect(progress.streamPosition, equals(const Offset(10, 20)));
      expect(progress.streamWidth, equals(5.0));
      expect(progress.showSplash, isTrue);
      expect(progress.splashIntensity, equals(0.8));
    });

    test('should create start progress', () {
      final progress = PourAnimationProgress.start();

      expect(progress.progress, equals(0.0));
      expect(progress.streamPosition, equals(Offset.zero));
      expect(progress.streamWidth, equals(0.0));
      expect(progress.showSplash, isFalse);
      expect(progress.splashIntensity, equals(0.0));
    });

    test('should create end progress', () {
      const finalPosition = Offset(50, 100);
      final progress = PourAnimationProgress.end(finalPosition);

      expect(progress.progress, equals(1.0));
      expect(progress.streamPosition, equals(finalPosition));
      expect(progress.streamWidth, equals(0.0));
      expect(progress.showSplash, isFalse);
      expect(progress.splashIntensity, equals(0.0));
    });

    test('should implement equality correctly', () {
      const progress1 = PourAnimationProgress(
        progress: 0.5,
        streamPosition: Offset(10, 20),
        streamWidth: 5.0,
        showSplash: true,
        splashIntensity: 0.8,
      );

      const progress2 = PourAnimationProgress(
        progress: 0.5,
        streamPosition: Offset(10, 20),
        streamWidth: 5.0,
        showSplash: true,
        splashIntensity: 0.8,
      );

      const progress3 = PourAnimationProgress(
        progress: 0.7,
        streamPosition: Offset(10, 20),
        streamWidth: 5.0,
        showSplash: true,
        splashIntensity: 0.8,
      );

      expect(progress1, equals(progress2));
      expect(progress1, isNot(equals(progress3)));
      expect(progress1.hashCode, equals(progress2.hashCode));
    });
  });
}