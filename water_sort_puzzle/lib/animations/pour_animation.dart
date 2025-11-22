import 'package:flutter/material.dart';
import '../models/liquid_color.dart';

/// Represents the data needed for a pour animation between containers
class PourAnimation {
  /// The index of the source container
  final int fromContainer;
  
  /// The index of the target container
  final int toContainer;
  
  /// The color of the liquid being poured
  final LiquidColor liquidColor;
  
  /// The volume of liquid being poured
  final int volume;
  
  /// The duration of the pour animation
  final Duration duration;
  
  /// The curve to use for the animation
  final Curve curve;
  
  /// Whether the animation should include splash effects
  final bool showSplash;
  
  const PourAnimation({
    required this.fromContainer,
    required this.toContainer,
    required this.liquidColor,
    required this.volume,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeInOut,
    this.showSplash = true,
  });
  
  /// Creates a copy of this animation with modified properties
  PourAnimation copyWith({
    int? fromContainer,
    int? toContainer,
    LiquidColor? liquidColor,
    int? volume,
    Duration? duration,
    Curve? curve,
    bool? showSplash,
  }) {
    return PourAnimation(
      fromContainer: fromContainer ?? this.fromContainer,
      toContainer: toContainer ?? this.toContainer,
      liquidColor: liquidColor ?? this.liquidColor,
      volume: volume ?? this.volume,
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
      showSplash: showSplash ?? this.showSplash,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is PourAnimation &&
        other.fromContainer == fromContainer &&
        other.toContainer == toContainer &&
        other.liquidColor == liquidColor &&
        other.volume == volume &&
        other.duration == duration &&
        other.curve == curve &&
        other.showSplash == showSplash;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      fromContainer,
      toContainer,
      liquidColor,
      volume,
      duration,
      curve,
      showSplash,
    );
  }
  
  @override
  String toString() {
    return 'PourAnimation('
        'from: $fromContainer, '
        'to: $toContainer, '
        'color: $liquidColor, '
        'volume: $volume, '
        'duration: $duration'
        ')';
  }
}

/// Represents different states of animation
abstract class AnimationState {
  const AnimationState();
}

/// No animation is currently playing
class IdleState extends AnimationState {
  const IdleState();
  
  @override
  bool operator ==(Object other) => other is IdleState;
  
  @override
  int get hashCode => 0;
}

/// A pour animation is currently playing
class PouringState extends AnimationState {
  final PourAnimation animation;
  
  const PouringState(this.animation);
  
  @override
  bool operator ==(Object other) {
    return other is PouringState && other.animation == animation;
  }
  
  @override
  int get hashCode => animation.hashCode;
}

/// Victory celebration animation is playing
class VictoryState extends AnimationState {
  final Duration celebrationDuration;
  
  const VictoryState(this.celebrationDuration);
  
  @override
  bool operator ==(Object other) {
    return other is VictoryState && 
        other.celebrationDuration == celebrationDuration;
  }
  
  @override
  int get hashCode => celebrationDuration.hashCode;
}

/// Animation progress data for liquid transfer
class PourAnimationProgress {
  /// Progress from 0.0 to 1.0
  final double progress;
  
  /// The current position of the liquid stream
  final Offset streamPosition;
  
  /// The width of the liquid stream
  final double streamWidth;
  
  /// Whether splash effects should be shown
  final bool showSplash;
  
  /// The intensity of the splash (0.0 to 1.0)
  final double splashIntensity;
  
  const PourAnimationProgress({
    required this.progress,
    required this.streamPosition,
    required this.streamWidth,
    this.showSplash = false,
    this.splashIntensity = 0.0,
  });
  
  /// Creates a progress instance for the start of animation
  factory PourAnimationProgress.start() {
    return const PourAnimationProgress(
      progress: 0.0,
      streamPosition: Offset.zero,
      streamWidth: 0.0,
    );
  }
  
  /// Creates a progress instance for the end of animation
  factory PourAnimationProgress.end(Offset finalPosition) {
    return PourAnimationProgress(
      progress: 1.0,
      streamPosition: finalPosition,
      streamWidth: 0.0,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is PourAnimationProgress &&
        other.progress == progress &&
        other.streamPosition == streamPosition &&
        other.streamWidth == streamWidth &&
        other.showSplash == showSplash &&
        other.splashIntensity == splashIntensity;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      progress,
      streamPosition,
      streamWidth,
      showSplash,
      splashIntensity,
    );
  }
}