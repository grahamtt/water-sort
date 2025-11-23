import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/level.dart';
import 'package:water_sort_puzzle/models/container.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/services/game_engine.dart';
import 'package:water_sort_puzzle/services/audio_manager.dart';

void main() {
  test('Debug: Can BFS solver solve puzzle without empty container?', () {
    // Test the puzzle WITHOUT the empty container
    final purpleContainer = Container(
      id: 0,
      capacity: 4,
      liquidLayers: [
        LiquidLayer(color: LiquidColor.purple, volume: 4),
      ],
    );

    final mixedContainer = Container(
      id: 1,
      capacity: 4,
      liquidLayers: [
        LiquidLayer(color: LiquidColor.green, volume: 2),
        LiquidLayer(color: LiquidColor.purple, volume: 2),
      ],
    );

    final greenContainer = Container(
      id: 2,
      capacity: 4,
      liquidLayers: [
        LiquidLayer(color: LiquidColor.green, volume: 4),
      ],
    );

    final level = Level(
      id: 1,
      difficulty: 1,
      containerCount: 3,
      colorCount: 2,
      initialContainers: [purpleContainer, mixedContainer, greenContainer],
    );

    print('Level has ${level.containerCount} containers');
    print('Is structurally valid: ${level.isStructurallyValid}');

    // Try to solve it manually with the game engine
    final gameEngine = WaterSortGameEngine(
      audioManager: AudioManager(audioPlayer: MockAudioPlayer()),
    );
    
    final initialState = gameEngine.initializeLevel(
      level.id,
      level.initialContainers,
    );

    print('Initial state created');
    print('Is already solved: ${gameEngine.checkWinCondition(initialState)}');

    // Try move 1: Pour purple from mixed (id=1) to purple container (id=0)
    print('\n--- Attempting move 1: Pour purple from mixed to purple ---');
    try {
      final validateResult = gameEngine.validatePour(initialState, 1, 0);
      print('Move 1 validation: ${validateResult.isSuccess}');
      if (validateResult.isSuccess) {
        final state1 = gameEngine.executePour(initialState, 1, 0);
        print('After move 1:');
        for (int i = 0; i < state1.containers.length; i++) {
          final c = state1.containers[i];
          print('  Container $i: ${c.isEmpty ? "empty" : c.liquidLayers.map((l) => "${l.color.name}:${l.volume}").join(", ")}');
        }
        print('Is solved after move 1: ${gameEngine.checkWinCondition(state1)}');

        // Try move 2: Pour green from mixed (id=1) to green container (id=2)
        print('\n--- Attempting move 2: Pour green from mixed to green ---');
        final validateResult2 = gameEngine.validatePour(state1, 1, 2);
        print('Move 2 validation: ${validateResult2.isSuccess}');
        if (validateResult2.isSuccess) {
          final state2 = gameEngine.executePour(state1, 1, 2);
          print('After move 2:');
          for (int i = 0; i < state2.containers.length; i++) {
            final c = state2.containers[i];
            print('  Container $i: ${c.isEmpty ? "empty" : c.liquidLayers.map((l) => "${l.color.name}:${l.volume}").join(", ")}');
          }
          print('Is solved after move 2: ${gameEngine.checkWinCondition(state2)}');
          
          expect(gameEngine.checkWinCondition(state2), isTrue,
              reason: 'Puzzle should be solved after 2 moves');
        }
      }
    } catch (e) {
      print('Error: $e');
      fail('Should be able to solve the puzzle');
    }
  });
}
