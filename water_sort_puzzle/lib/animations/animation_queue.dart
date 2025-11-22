import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'pour_animation.dart';

/// Manages a queue of animations and handles animation interruption
class AnimationQueue extends ChangeNotifier {
  final Queue<PourAnimation> _pendingAnimations = Queue<PourAnimation>();
  PourAnimation? _currentAnimation;
  AnimationState _state = const IdleState();
  
  // Stream controller for decoupling game logic from UI animations
  final StreamController<AnimationEvent> _animationEventController = 
      StreamController<AnimationEvent>.broadcast();
  
  /// Stream of animation events for UI components to listen to
  Stream<AnimationEvent> get animationEvents => _animationEventController.stream;
  
  /// Current animation state
  AnimationState get state => _state;
  
  /// Current animation being played (null if idle)
  PourAnimation? get currentAnimation => _currentAnimation;
  
  /// Whether there are pending animations in the queue
  bool get hasPendingAnimations => _pendingAnimations.isNotEmpty;
  
  /// Whether an animation is currently playing
  bool get isAnimating => _state is PouringState;
  
  /// Whether the system is in victory state
  bool get isInVictoryState => _state is VictoryState;
  
  /// Total number of animations in queue (including current)
  int get totalAnimations => _pendingAnimations.length + (_currentAnimation != null ? 1 : 0);
  
  /// Add an animation to the queue
  void addAnimation(PourAnimation animation) {
    _pendingAnimations.add(animation);
    _animationEventController.add(AnimationQueued(animation));
    
    // If not currently animating, start the next animation
    if (_state is IdleState) {
      _processNextAnimation();
    }
    
    notifyListeners();
  }
  
  /// Add multiple animations to the queue
  void addAnimations(List<PourAnimation> animations) {
    for (final animation in animations) {
      _pendingAnimations.add(animation);
      _animationEventController.add(AnimationQueued(animation));
    }
    
    // If not currently animating, start the next animation
    if (_state is IdleState) {
      _processNextAnimation();
    }
    
    notifyListeners();
  }
  
  /// Skip the current animation and move to the next one
  void skipCurrentAnimation() {
    if (_currentAnimation != null) {
      final skippedAnimation = _currentAnimation!;
      _animationEventController.add(AnimationSkipped(skippedAnimation));
      
      _completeCurrentAnimation();
    }
  }
  
  /// Skip all animations and return to idle state
  void skipAllAnimations() {
    final skippedAnimations = <PourAnimation>[];
    
    // Add current animation to skipped list
    if (_currentAnimation != null) {
      skippedAnimations.add(_currentAnimation!);
    }
    
    // Add all pending animations to skipped list
    skippedAnimations.addAll(_pendingAnimations);
    
    // Clear everything
    _pendingAnimations.clear();
    _currentAnimation = null;
    _setState(const IdleState());
    
    // Notify about all skipped animations
    for (final animation in skippedAnimations) {
      _animationEventController.add(AnimationSkipped(animation));
    }
    
    _animationEventController.add(const AllAnimationsSkipped());
    notifyListeners();
  }
  
  /// Clear all pending animations but allow current animation to complete
  void clearPendingAnimations() {
    final clearedAnimations = List<PourAnimation>.from(_pendingAnimations);
    _pendingAnimations.clear();
    
    for (final animation in clearedAnimations) {
      _animationEventController.add(AnimationCancelled(animation));
    }
    
    _animationEventController.add(const PendingAnimationsCleared());
    notifyListeners();
  }
  
  /// Start victory celebration animation
  void startVictoryAnimation({Duration duration = const Duration(milliseconds: 2000)}) {
    // Clear any pending animations
    clearPendingAnimations();
    
    // Skip current animation if any
    if (_currentAnimation != null) {
      skipCurrentAnimation();
    }
    
    _setState(VictoryState(duration));
    _animationEventController.add(VictoryAnimationStarted(duration));
    notifyListeners();
  }
  
  /// Complete victory animation and return to idle
  void completeVictoryAnimation() {
    if (_state is VictoryState) {
      final victoryState = _state as VictoryState;
      _setState(const IdleState());
      _animationEventController.add(VictoryAnimationCompleted(victoryState.celebrationDuration));
      notifyListeners();
    }
  }
  
  /// Force return to idle state (emergency reset)
  void forceIdle() {
    final wasAnimating = isAnimating;
    final hadPending = hasPendingAnimations;
    
    _pendingAnimations.clear();
    _currentAnimation = null;
    _setState(const IdleState());
    
    if (wasAnimating || hadPending) {
      _animationEventController.add(const ForcedIdle());
    }
    
    notifyListeners();
  }
  
  /// Process the next animation in the queue
  void _processNextAnimation() {
    if (_pendingAnimations.isEmpty) {
      _setState(const IdleState());
      _animationEventController.add(const QueueEmpty());
      notifyListeners();
      return;
    }
    
    _currentAnimation = _pendingAnimations.removeFirst();
    _setState(PouringState(_currentAnimation!));
    _animationEventController.add(AnimationStarted(_currentAnimation!));
    notifyListeners();
  }
  
  /// Mark current animation as completed and process next
  void completeCurrentAnimation() {
    _completeCurrentAnimation();
  }
  
  void _completeCurrentAnimation() {
    if (_currentAnimation != null) {
      final completedAnimation = _currentAnimation!;
      _currentAnimation = null;
      _animationEventController.add(AnimationCompleted(completedAnimation));
      
      // Process next animation
      _processNextAnimation();
    }
  }
  
  /// Update animation progress (called by animation controllers)
  void updateAnimationProgress(double progress) {
    if (_currentAnimation != null) {
      _animationEventController.add(AnimationProgress(_currentAnimation!, progress));
    }
  }
  
  /// Set the current state
  void _setState(AnimationState newState) {
    if (_state != newState) {
      final oldState = _state;
      _state = newState;
      _animationEventController.add(StateChanged(oldState, newState));
    }
  }
  
  @override
  void dispose() {
    if (!_animationEventController.isClosed) {
      _animationEventController.close();
    }
    super.dispose();
  }
}

/// Base class for animation events
abstract class AnimationEvent {
  const AnimationEvent();
}

/// Animation was added to the queue
class AnimationQueued extends AnimationEvent {
  final PourAnimation animation;
  const AnimationQueued(this.animation);
}

/// Animation started playing
class AnimationStarted extends AnimationEvent {
  final PourAnimation animation;
  const AnimationStarted(this.animation);
}

/// Animation completed normally
class AnimationCompleted extends AnimationEvent {
  final PourAnimation animation;
  const AnimationCompleted(this.animation);
}

/// Animation was skipped
class AnimationSkipped extends AnimationEvent {
  final PourAnimation animation;
  const AnimationSkipped(this.animation);
}

/// Animation was cancelled (removed from queue)
class AnimationCancelled extends AnimationEvent {
  final PourAnimation animation;
  const AnimationCancelled(this.animation);
}

/// Animation progress update
class AnimationProgress extends AnimationEvent {
  final PourAnimation animation;
  final double progress;
  const AnimationProgress(this.animation, this.progress);
}

/// Victory animation started
class VictoryAnimationStarted extends AnimationEvent {
  final Duration duration;
  const VictoryAnimationStarted(this.duration);
}

/// Victory animation completed
class VictoryAnimationCompleted extends AnimationEvent {
  final Duration duration;
  const VictoryAnimationCompleted(this.duration);
}

/// Animation state changed
class StateChanged extends AnimationEvent {
  final AnimationState oldState;
  final AnimationState newState;
  const StateChanged(this.oldState, this.newState);
}

/// Queue became empty
class QueueEmpty extends AnimationEvent {
  const QueueEmpty();
}

/// All animations were skipped
class AllAnimationsSkipped extends AnimationEvent {
  const AllAnimationsSkipped();
}

/// Pending animations were cleared
class PendingAnimationsCleared extends AnimationEvent {
  const PendingAnimationsCleared();
}

/// System was forced to idle state
class ForcedIdle extends AnimationEvent {
  const ForcedIdle();
}