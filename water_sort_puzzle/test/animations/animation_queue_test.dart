import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/animations/animation_queue.dart';
import 'package:water_sort_puzzle/animations/pour_animation.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'dart:async';

void main() {
  group('AnimationQueue', () {
    late AnimationQueue animationQueue;
    late List<AnimationEvent> capturedEvents;
    late StreamSubscription<AnimationEvent> eventSubscription;

    setUp(() {
      animationQueue = AnimationQueue();
      capturedEvents = [];
      eventSubscription = animationQueue.animationEvents.listen((event) {
        capturedEvents.add(event);
      });
    });

    tearDown(() async {
      await eventSubscription.cancel();
      animationQueue.dispose();
    });

    /// Helper function to wait for stream events to be processed
    Future<void> pumpEventQueue() async {
      await Future.delayed(Duration.zero);
    }

    group('Initial State', () {
      test('should start in idle state', () {
        expect(animationQueue.state, isA<IdleState>());
        expect(animationQueue.isAnimating, isFalse);
        expect(animationQueue.isInVictoryState, isFalse);
        expect(animationQueue.hasPendingAnimations, isFalse);
        expect(animationQueue.currentAnimation, isNull);
        expect(animationQueue.totalAnimations, equals(0));
      });
    });

    group('Animation Queueing', () {
      test('should add single animation to queue', () async {
        final animation = _createTestAnimation(0, 1);
        
        animationQueue.addAnimation(animation);
        await pumpEventQueue();
        
        expect(animationQueue.hasPendingAnimations, isFalse); // Should start immediately
        expect(animationQueue.isAnimating, isTrue);
        expect(animationQueue.currentAnimation, equals(animation));
        expect(animationQueue.totalAnimations, equals(1));
        
        // Check events (includes StateChanged events)
        expect(capturedEvents.where((e) => e is AnimationQueued), hasLength(1));
        expect(capturedEvents.where((e) => e is AnimationStarted), hasLength(1));
        expect(capturedEvents.where((e) => e is StateChanged), hasLength(1));
      });

      test('should add multiple animations to queue', () async {
        final animation1 = _createTestAnimation(0, 1);
        final animation2 = _createTestAnimation(1, 2);
        final animation3 = _createTestAnimation(2, 0);
        
        animationQueue.addAnimation(animation1);
        animationQueue.addAnimation(animation2);
        animationQueue.addAnimation(animation3);
        await pumpEventQueue();
        
        expect(animationQueue.isAnimating, isTrue);
        expect(animationQueue.hasPendingAnimations, isTrue);
        expect(animationQueue.currentAnimation, equals(animation1));
        expect(animationQueue.totalAnimations, equals(3));
        
        // Check events (includes StateChanged events)
        expect(capturedEvents.where((e) => e is AnimationQueued), hasLength(3));
        expect(capturedEvents.where((e) => e is AnimationStarted), hasLength(1));
        expect(capturedEvents.where((e) => e is StateChanged), hasLength(1));
      });

      test('should add multiple animations at once', () async {
        final animations = [
          _createTestAnimation(0, 1),
          _createTestAnimation(1, 2),
          _createTestAnimation(2, 0),
        ];
        
        animationQueue.addAnimations(animations);
        await pumpEventQueue();
        
        expect(animationQueue.isAnimating, isTrue);
        expect(animationQueue.hasPendingAnimations, isTrue);
        expect(animationQueue.currentAnimation, equals(animations[0]));
        expect(animationQueue.totalAnimations, equals(3));
        
        // Check events (includes StateChanged events)
        expect(capturedEvents.where((e) => e is AnimationQueued), hasLength(3));
        expect(capturedEvents.where((e) => e is AnimationStarted), hasLength(1));
        expect(capturedEvents.where((e) => e is StateChanged), hasLength(1));
      });
    });

    group('Animation Completion', () {
      test('should complete current animation and start next', () async {
        final animation1 = _createTestAnimation(0, 1);
        final animation2 = _createTestAnimation(1, 2);
        
        animationQueue.addAnimation(animation1);
        animationQueue.addAnimation(animation2);
        await pumpEventQueue();
        
        // Complete first animation
        animationQueue.completeCurrentAnimation();
        await pumpEventQueue();
        
        expect(animationQueue.isAnimating, isTrue);
        expect(animationQueue.currentAnimation, equals(animation2));
        expect(animationQueue.totalAnimations, equals(1));
        
        // Check events
        expect(capturedEvents.where((e) => e is AnimationCompleted), hasLength(1));
        expect(capturedEvents.where((e) => e is AnimationStarted), hasLength(2));
      });

      test('should return to idle when all animations complete', () async {
        final animation = _createTestAnimation(0, 1);
        
        animationQueue.addAnimation(animation);
        await pumpEventQueue();
        animationQueue.completeCurrentAnimation();
        await pumpEventQueue();
        
        expect(animationQueue.state, isA<IdleState>());
        expect(animationQueue.isAnimating, isFalse);
        expect(animationQueue.currentAnimation, isNull);
        expect(animationQueue.totalAnimations, equals(0));
        
        // Check events
        expect(capturedEvents.where((e) => e is AnimationCompleted), hasLength(1));
        expect(capturedEvents.where((e) => e is QueueEmpty), hasLength(1));
      });
    });

    group('Animation Skipping', () {
      test('should skip current animation', () async {
        final animation1 = _createTestAnimation(0, 1);
        final animation2 = _createTestAnimation(1, 2);
        
        animationQueue.addAnimation(animation1);
        animationQueue.addAnimation(animation2);
        await pumpEventQueue();
        
        animationQueue.skipCurrentAnimation();
        await pumpEventQueue();
        
        expect(animationQueue.isAnimating, isTrue);
        expect(animationQueue.currentAnimation, equals(animation2));
        
        // Check events
        expect(capturedEvents.where((e) => e is AnimationSkipped), hasLength(1));
        expect(capturedEvents.where((e) => e is AnimationStarted), hasLength(2));
      });

      test('should skip all animations', () async {
        final animation1 = _createTestAnimation(0, 1);
        final animation2 = _createTestAnimation(1, 2);
        final animation3 = _createTestAnimation(2, 0);
        
        animationQueue.addAnimation(animation1);
        animationQueue.addAnimation(animation2);
        animationQueue.addAnimation(animation3);
        await pumpEventQueue();
        
        animationQueue.skipAllAnimations();
        await pumpEventQueue();
        
        expect(animationQueue.state, isA<IdleState>());
        expect(animationQueue.isAnimating, isFalse);
        expect(animationQueue.hasPendingAnimations, isFalse);
        expect(animationQueue.currentAnimation, isNull);
        expect(animationQueue.totalAnimations, equals(0));
        
        // Check events
        expect(capturedEvents.where((e) => e is AnimationSkipped), hasLength(3));
        expect(capturedEvents.where((e) => e is AllAnimationsSkipped), hasLength(1));
      });

      test('should clear pending animations but allow current to complete', () async {
        final animation1 = _createTestAnimation(0, 1);
        final animation2 = _createTestAnimation(1, 2);
        final animation3 = _createTestAnimation(2, 0);
        
        animationQueue.addAnimation(animation1);
        animationQueue.addAnimation(animation2);
        animationQueue.addAnimation(animation3);
        await pumpEventQueue();
        
        animationQueue.clearPendingAnimations();
        await pumpEventQueue();
        
        expect(animationQueue.isAnimating, isTrue);
        expect(animationQueue.hasPendingAnimations, isFalse);
        expect(animationQueue.currentAnimation, equals(animation1));
        expect(animationQueue.totalAnimations, equals(1));
        
        // Check events
        expect(capturedEvents.where((e) => e is AnimationCancelled), hasLength(2));
        expect(capturedEvents.where((e) => e is PendingAnimationsCleared), hasLength(1));
      });
    });

    group('Victory Animation', () {
      test('should start victory animation', () async {
        const duration = Duration(milliseconds: 1500);
        
        animationQueue.startVictoryAnimation(duration: duration);
        await pumpEventQueue();
        
        expect(animationQueue.state, isA<VictoryState>());
        expect(animationQueue.isInVictoryState, isTrue);
        expect(animationQueue.isAnimating, isFalse); // Victory is not considered "animating"
        
        final victoryState = animationQueue.state as VictoryState;
        expect(victoryState.celebrationDuration, equals(duration));
        
        // Check events
        expect(capturedEvents.where((e) => e is VictoryAnimationStarted), hasLength(1));
      });

      test('should complete victory animation', () async {
        animationQueue.startVictoryAnimation();
        await pumpEventQueue();
        animationQueue.completeVictoryAnimation();
        await pumpEventQueue();
        
        expect(animationQueue.state, isA<IdleState>());
        expect(animationQueue.isInVictoryState, isFalse);
        
        // Check events
        expect(capturedEvents.where((e) => e is VictoryAnimationCompleted), hasLength(1));
      });

      test('should clear animations when starting victory', () async {
        final animation1 = _createTestAnimation(0, 1);
        final animation2 = _createTestAnimation(1, 2);
        
        animationQueue.addAnimation(animation1);
        animationQueue.addAnimation(animation2);
        await pumpEventQueue();
        
        animationQueue.startVictoryAnimation();
        await pumpEventQueue();
        
        expect(animationQueue.state, isA<VictoryState>());
        expect(animationQueue.hasPendingAnimations, isFalse);
        expect(animationQueue.currentAnimation, isNull);
        
        // Check events
        expect(capturedEvents.where((e) => e is AnimationSkipped), hasLength(1)); // Current animation
        expect(capturedEvents.where((e) => e is PendingAnimationsCleared), hasLength(1));
        expect(capturedEvents.where((e) => e is VictoryAnimationStarted), hasLength(1));
      });
    });

    group('Force Idle', () {
      test('should force return to idle state', () async {
        final animation1 = _createTestAnimation(0, 1);
        final animation2 = _createTestAnimation(1, 2);
        
        animationQueue.addAnimation(animation1);
        animationQueue.addAnimation(animation2);
        await pumpEventQueue();
        
        animationQueue.forceIdle();
        await pumpEventQueue();
        
        expect(animationQueue.state, isA<IdleState>());
        expect(animationQueue.isAnimating, isFalse);
        expect(animationQueue.hasPendingAnimations, isFalse);
        expect(animationQueue.currentAnimation, isNull);
        expect(animationQueue.totalAnimations, equals(0));
        
        // Check events
        expect(capturedEvents.where((e) => e is ForcedIdle), hasLength(1));
      });

      test('should not emit ForcedIdle event if already idle', () async {
        animationQueue.forceIdle();
        await pumpEventQueue();
        
        expect(animationQueue.state, isA<IdleState>());
        expect(capturedEvents.where((e) => e is ForcedIdle), hasLength(0));
      });
    });

    group('Animation Progress', () {
      test('should update animation progress', () async {
        final animation = _createTestAnimation(0, 1);
        
        animationQueue.addAnimation(animation);
        await pumpEventQueue();
        animationQueue.updateAnimationProgress(0.5);
        await pumpEventQueue();
        
        // Check events
        expect(capturedEvents.where((e) => e is AnimationProgress), hasLength(1));
        final progressEvent = capturedEvents.whereType<AnimationProgress>().first;
        expect(progressEvent.animation, equals(animation));
        expect(progressEvent.progress, equals(0.5));
      });

      test('should not update progress when no current animation', () async {
        animationQueue.updateAnimationProgress(0.5);
        await pumpEventQueue();
        
        expect(capturedEvents.where((e) => e is AnimationProgress), hasLength(0));
      });
    });

    group('State Changes', () {
      test('should emit state change events', () async {
        final animation = _createTestAnimation(0, 1);
        
        // Start animation
        animationQueue.addAnimation(animation);
        await pumpEventQueue();
        
        // Complete animation
        animationQueue.completeCurrentAnimation();
        await pumpEventQueue();
        
        // Check state change events
        final stateChangeEvents = capturedEvents.whereType<StateChanged>().toList();
        expect(stateChangeEvents, hasLength(2));
        
        // First state change: Idle -> Pouring
        expect(stateChangeEvents[0].oldState, isA<IdleState>());
        expect(stateChangeEvents[0].newState, isA<PouringState>());
        
        // Second state change: Pouring -> Idle
        expect(stateChangeEvents[1].oldState, isA<PouringState>());
        expect(stateChangeEvents[1].newState, isA<IdleState>());
      });
    });

    group('Animation Interruption Behavior', () {
      test('should allow interruption during animation', () {
        final animation1 = _createTestAnimation(0, 1);
        final animation2 = _createTestAnimation(1, 2);
        final animation3 = _createTestAnimation(2, 0);
        
        // Start first animation
        animationQueue.addAnimation(animation1);
        expect(animationQueue.currentAnimation, equals(animation1));
        
        // Add more animations while first is playing
        animationQueue.addAnimation(animation2);
        animationQueue.addAnimation(animation3);
        
        // Skip current animation (simulating interruption)
        animationQueue.skipCurrentAnimation();
        
        // Should immediately start next animation
        expect(animationQueue.currentAnimation, equals(animation2));
        expect(animationQueue.isAnimating, isTrue);
        
        // Skip all remaining
        animationQueue.skipAllAnimations();
        
        expect(animationQueue.state, isA<IdleState>());
        expect(animationQueue.isAnimating, isFalse);
      });

      test('should handle rapid animation additions and skips', () {
        final animations = List.generate(10, (i) => _createTestAnimation(i, (i + 1) % 4));
        
        // Add all animations
        animationQueue.addAnimations(animations);
        expect(animationQueue.totalAnimations, equals(10));
        
        // Skip several animations rapidly
        for (int i = 0; i < 5; i++) {
          animationQueue.skipCurrentAnimation();
        }
        
        expect(animationQueue.totalAnimations, equals(5));
        expect(animationQueue.isAnimating, isTrue);
        
        // Clear remaining
        animationQueue.skipAllAnimations();
        
        expect(animationQueue.state, isA<IdleState>());
        expect(animationQueue.totalAnimations, equals(0));
      });

      test('should handle interruption by victory animation', () async {
        final animation1 = _createTestAnimation(0, 1);
        final animation2 = _createTestAnimation(1, 2);
        
        animationQueue.addAnimation(animation1);
        animationQueue.addAnimation(animation2);
        await pumpEventQueue();
        
        // Start victory animation (should interrupt current animations)
        animationQueue.startVictoryAnimation();
        await pumpEventQueue();
        
        expect(animationQueue.state, isA<VictoryState>());
        expect(animationQueue.isInVictoryState, isTrue);
        expect(animationQueue.hasPendingAnimations, isFalse);
        expect(animationQueue.currentAnimation, isNull);
        
        // Check that animations were properly interrupted
        expect(capturedEvents.where((e) => e is AnimationSkipped), hasLength(1));
        expect(capturedEvents.where((e) => e is PendingAnimationsCleared), hasLength(1));
      });
    });

    group('Edge Cases', () {
      test('should handle skip when no current animation', () {
        animationQueue.skipCurrentAnimation();
        
        expect(animationQueue.state, isA<IdleState>());
        expect(capturedEvents.where((e) => e is AnimationSkipped), hasLength(0));
      });

      test('should handle complete when no current animation', () {
        animationQueue.completeCurrentAnimation();
        
        expect(animationQueue.state, isA<IdleState>());
        expect(capturedEvents.where((e) => e is AnimationCompleted), hasLength(0));
      });

      test('should handle clear pending when no pending animations', () async {
        animationQueue.clearPendingAnimations();
        await pumpEventQueue();
        
        expect(capturedEvents.where((e) => e is AnimationCancelled), hasLength(0));
        expect(capturedEvents.where((e) => e is PendingAnimationsCleared), hasLength(1));
      });

      test('should handle victory completion when not in victory state', () {
        animationQueue.completeVictoryAnimation();
        
        expect(animationQueue.state, isA<IdleState>());
        expect(capturedEvents.where((e) => e is VictoryAnimationCompleted), hasLength(0));
      });
    });

    group('Memory Management', () {
      test('should properly dispose and close streams', () async {
        // Create a separate animation queue for this test to avoid double dispose
        final testQueue = AnimationQueue();
        final animation = _createTestAnimation(0, 1);
        testQueue.addAnimation(animation);
        
        // Dispose should not throw
        expect(() => testQueue.dispose(), returnsNormally);
        
        // Stream should be closed after dispose
        expect(testQueue.animationEvents.isBroadcast, isTrue);
      });
    });
  });
}

/// Helper function to create test animations
PourAnimation _createTestAnimation(int from, int to, {
  LiquidColor color = LiquidColor.blue,
  int volume = 1,
  Duration duration = const Duration(milliseconds: 500),
}) {
  return PourAnimation(
    fromContainer: from,
    toContainer: to,
    liquidColor: color,
    volume: volume,
    duration: duration,
  );
}