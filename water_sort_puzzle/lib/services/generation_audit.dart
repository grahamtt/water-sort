import '../models/container.dart';
import '../models/liquid_color.dart';

/// Records detailed audit information about level generation process
class GenerationAudit {
  final int levelId;
  final int difficulty;
  final int colorCount;
  final int containerCapacity;
  final int emptySlots;
  final List<LiquidColor> selectedColors;
  final List<Container> solvedState;
  final List<ScrambleStep> scrambleSteps;
  final List<Container> finalState;
  final List<String> validationFailures;
  final bool isSolvable;
  final String? solvabilityError;
  final int? firstUnsolvableStep;

  GenerationAudit({
    required this.levelId,
    required this.difficulty,
    required this.colorCount,
    required this.containerCapacity,
    required this.emptySlots,
    required this.selectedColors,
    required this.solvedState,
    required this.scrambleSteps,
    required this.finalState,
    required this.validationFailures,
    required this.isSolvable,
    this.solvabilityError,
    this.firstUnsolvableStep,
  });

  /// Convert to a detailed string representation for debugging
  String toDetailedString() {
    final buffer = StringBuffer();
    buffer.writeln('=' * 80);
    buffer.writeln('GENERATION AUDIT FOR LEVEL $levelId');
    buffer.writeln('=' * 80);
    buffer.writeln();
    
    buffer.writeln('Parameters:');
    buffer.writeln('  Level ID: $levelId');
    buffer.writeln('  Difficulty: $difficulty');
    buffer.writeln('  Color Count: $colorCount');
    buffer.writeln('  Container Capacity: $containerCapacity');
    buffer.writeln('  Empty Slots: $emptySlots');
    buffer.writeln('  Selected Colors: ${selectedColors.map((c) => c.name).join(", ")}');
    buffer.writeln();
    
    buffer.writeln('Solved State:');
    for (int i = 0; i < solvedState.length; i++) {
      final container = solvedState[i];
      buffer.writeln('  Container $i: ${_containerToString(container)}');
    }
    buffer.writeln();
    
    buffer.writeln('Scrambling Steps (${scrambleSteps.length} total):');
    for (int i = 0; i < scrambleSteps.length; i++) {
      final step = scrambleSteps[i];
      final marker = firstUnsolvableStep != null && step.stepNumber == firstUnsolvableStep
          ? ' <-- FIRST UNSOLVABLE STEP'
          : '';
      buffer.writeln('  Step ${i + 1}: ${step.toString()}$marker');
    }
    buffer.writeln();
    
    buffer.writeln('Final State:');
    for (int i = 0; i < finalState.length; i++) {
      final container = finalState[i];
      buffer.writeln('  Container $i: ${_containerToString(container)}');
    }
    buffer.writeln();
    
    buffer.writeln('Validation:');
    if (validationFailures.isEmpty) {
      buffer.writeln('  ✓ PASSED');
    } else {
      buffer.writeln('  ✗ FAILED');
      for (final failure in validationFailures) {
        buffer.writeln('    - $failure');
      }
    }
    buffer.writeln();
    
    buffer.writeln('Solvability:');
    if (isSolvable) {
      buffer.writeln('  ✓ SOLVABLE');
    } else {
      buffer.writeln('  ✗ UNSOLVABLE');
      if (firstUnsolvableStep != null) {
        buffer.writeln('    First became unsolvable at step: $firstUnsolvableStep');
      }
      if (solvabilityError != null) {
        buffer.writeln('    Error: $solvabilityError');
      }
    }
    buffer.writeln();
    
    buffer.writeln('=' * 80);
    return buffer.toString();
  }

  String _containerToString(Container container) {
    if (container.isEmpty) {
      return 'EMPTY';
    }
    final layers = container.liquidLayers
        .map((l) => '${l.color.name}:${l.volume}')
        .join(' | ');
    return '[$layers] (${container.currentVolume}/${container.capacity})';
  }
}

/// Records a single scrambling step
class ScrambleStep {
  final int stepNumber;
  final int sourceContainerId;
  final int targetContainerId;
  final int volume;
  final ScrambleMoveType type;
  final List<Container> stateBefore;
  final List<Container> stateAfter;
  final double contiguousPercentage;
  final bool? isSolvableAfterStep;
  final String? solvabilityError;

  ScrambleStep({
    required this.stepNumber,
    required this.sourceContainerId,
    required this.targetContainerId,
    required this.volume,
    required this.type,
    required this.stateBefore,
    required this.stateAfter,
    required this.contiguousPercentage,
    this.isSolvableAfterStep,
    this.solvabilityError,
  });

  /// Format state in compact form like |ABAAB|BCBA| |
  String formatStateCompact(List<Container> containers) {
    final parts = <String>[];
    for (final container in containers) {
      if (container.isEmpty) {
        parts.add('| |');
      } else {
        final layers = <String>[];
        for (final layer in container.liquidLayers) {
          // Use first letter of color name, repeated for volume
          final colorLetter = layer.color.name[0].toUpperCase();
          layers.add(colorLetter * layer.volume);
        }
        parts.add('|${layers.join('')}|');
      }
    }
    return parts.join('');
  }

  @override
  String toString() {
    final typeStr = type == ScrambleMoveType.splitLayer ? 'SPLIT' : 'MOVE_ENTIRE';
    final solvabilityStr = isSolvableAfterStep == null 
        ? '' 
        : (isSolvableAfterStep! ? ' [SOLVABLE]' : ' [UNSOLVABLE]');
    final stateAfterStr = formatStateCompact(stateAfter);
    return '$typeStr: Container $sourceContainerId -> Container $targetContainerId (volume: $volume, contiguous: ${(contiguousPercentage * 100).toStringAsFixed(1)}%)$solvabilityStr\n    State: $stateAfterStr';
  }
}

/// Type of scrambling move
enum ScrambleMoveType {
  splitLayer,
  moveEntireLayer,
}

