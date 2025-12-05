import 'package:water_sort_puzzle/services/reverse_level_generator.dart';
import 'package:water_sort_puzzle/services/level_generator.dart';
import 'package:water_sort_puzzle/services/level_validator.dart';
import 'package:water_sort_puzzle/services/level_parameters.dart';
import 'dart:io';

/// Script to find unsolvable levels in the range 35-50
/// Uses audit mode to record detailed generation history
void main() async {
  print('=' * 80);
  print('FINDING UNSOLVABLE LEVELS (35-50)');
  print('=' * 80);
  print('');

  // Create generator with audit mode enabled
  final generator = ReverseLevelGenerator(
    config: const LevelGenerationConfig(
      enableAuditMode: true,
      enableActualSolvabilityTest: false, // We'll check manually
    ),
  );

  int unsolvableCount = 0;
  int totalGenerated = 0;

  for (int levelId = 35; levelId <= 50; levelId++) {
    print('Testing level $levelId...');
    
    final difficulty = LevelParameters.calculateDifficultyForLevel(levelId);
    final containerCapacity = LevelParameters.calculateContainerCapacity(levelId);
    final emptySlots = LevelParameters.calculateEmptySlotsForLevel(levelId);
    final colorCount = LevelParameters.calculateColorCountForLevel(levelId);

    print('  Parameters: difficulty=$difficulty, colors=$colorCount, capacity=$containerCapacity, emptySlots=$emptySlots');

    try {
      // Generate the level
      final level = generator.generateLevel(
        levelId,
        difficulty,
        colorCount,
        containerCapacity,
        emptySlots,
      );
      totalGenerated++;

      // Check solvability
      print('  Checking solvability...');
      final isSolvable = LevelValidator.isLevelSolvable(level);
      
      if (!isSolvable) {
        unsolvableCount++;
        print('  ✗ UNSOLVABLE LEVEL FOUND!');
        print('');
        
        // Get audit information
        final audit = generator.lastAudit;
        if (audit != null) {
          // Write audit to file
          final auditFile = File('unsolvable_level_${levelId}_audit.txt');
          await auditFile.writeAsString(audit.toDetailedString());
          print('  Audit saved to: ${auditFile.path}');
          print('');
          
          // Print full diagnostic information
          print('FULL DIAGNOSTIC INFORMATION:');
          print('');
          print(audit.toDetailedString());
        } else {
          print('  WARNING: No audit information available');
          print('');
        }
        
        // Exit after finding first unsolvable puzzle
        print('=' * 80);
        print('Exiting after finding first unsolvable level: $levelId');
        print('=' * 80);
        return;
      } else {
        print('  ✓ Solvable');
      }
    } catch (e, stackTrace) {
      print('  ✗ ERROR generating level: $e');
      print('  Stack trace: $stackTrace');
      print('');
    }
  }

  print('=' * 80);
  print('SEARCH COMPLETE');
  print('=' * 80);
  print('Total levels generated: $totalGenerated');
  print('No unsolvable levels found in range 35-50');
  print('');
}

