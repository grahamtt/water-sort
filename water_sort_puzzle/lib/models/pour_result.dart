import 'liquid_color.dart';
import 'move.dart';

/// Base class for all pour operation results
abstract class PourResult {
  const PourResult();

  /// Whether the pour operation was successful
  bool get isSuccess => this is PourSuccess;

  /// Whether the pour operation failed
  bool get isFailure => !isSuccess;
}

/// Represents a successful pour operation
class PourSuccess extends PourResult {
  /// The move that was successfully executed
  final Move move;

  const PourSuccess(this.move);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PourSuccess && other.move == move;
  }

  @override
  int get hashCode => move.hashCode;

  @override
  String toString() => 'PourSuccess(move: $move)';
}

/// Base class for pour operation failures
abstract class PourFailure extends PourResult {
  /// Human-readable error message
  final String message;

  const PourFailure(this.message);

  @override
  String toString() => 'PourFailure: $message';
}

/// Pour failed because the target container is full
class PourFailureContainerFull extends PourFailure {
  /// The ID of the full container
  final int containerId;

  const PourFailureContainerFull(this.containerId)
    : super('Container $containerId is full');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PourFailureContainerFull &&
        other.containerId == containerId;
  }

  @override
  int get hashCode => containerId.hashCode;
}

/// Pour failed because colors don't match
class PourFailureColorMismatch extends PourFailure {
  /// The color being poured
  final LiquidColor sourceColor;

  /// The color at the top of the target container
  final LiquidColor targetColor;

  PourFailureColorMismatch(this.sourceColor, this.targetColor)
    : super(
        'Cannot pour ${sourceColor.displayName} onto ${targetColor.displayName}',
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PourFailureColorMismatch &&
        other.sourceColor == sourceColor &&
        other.targetColor == targetColor;
  }

  @override
  int get hashCode => Object.hash(sourceColor, targetColor);
}

/// Pour failed because the source container is empty
class PourFailureEmptySource extends PourFailure {
  /// The ID of the empty source container
  final int containerId;

  const PourFailureEmptySource(this.containerId)
    : super('Container $containerId is empty');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PourFailureEmptySource && other.containerId == containerId;
  }

  @override
  int get hashCode => containerId.hashCode;
}

/// Pour failed because source and target are the same container
class PourFailureSameContainer extends PourFailure {
  /// The ID of the container
  final int containerId;

  const PourFailureSameContainer(this.containerId)
    : super('Cannot pour from container $containerId to itself');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PourFailureSameContainer &&
        other.containerId == containerId;
  }

  @override
  int get hashCode => containerId.hashCode;
}

/// Pour failed because container ID is invalid
class PourFailureInvalidContainer extends PourFailure {
  /// The invalid container ID
  final int containerId;

  const PourFailureInvalidContainer(this.containerId)
    : super('Container $containerId does not exist');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PourFailureInvalidContainer &&
        other.containerId == containerId;
  }

  @override
  int get hashCode => containerId.hashCode;
}

/// Pour failed because there's insufficient capacity in the target container
class PourFailureInsufficientCapacity extends PourFailure {
  /// The ID of the target container
  final int containerId;

  /// The volume that was attempted to be poured
  final int attemptedVolume;

  /// The available capacity in the target container
  final int availableCapacity;

  const PourFailureInsufficientCapacity(
    this.containerId,
    this.attemptedVolume,
    this.availableCapacity,
  ) : super(
        'Container $containerId has only $availableCapacity capacity, '
        'but attempted to pour $attemptedVolume',
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PourFailureInsufficientCapacity &&
        other.containerId == containerId &&
        other.attemptedVolume == attemptedVolume &&
        other.availableCapacity == availableCapacity;
  }

  @override
  int get hashCode =>
      Object.hash(containerId, attemptedVolume, availableCapacity);
}
