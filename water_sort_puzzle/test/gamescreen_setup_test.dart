import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/container.dart' as models;
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/game_state.dart';
import 'package:water_sort_puzzle/services/game_engine.dart';

void main() {
  group('GameScreen Setup Verification', () {
    test('should create exact same containers as GameScreen _initializeGame', () {
      // Replicate the exact _initializeGame method from GameScreen
      final containers = [
        models.Container(
          id: 1,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.red, volume: 2),
            const LiquidLayer(color: LiquidColor.blue, volume: 1),
            const LiquidLayer(color: LiquidColor.yellow, volume: 1),
          ],
        ),
        models.Container(
          id: 2,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.green, volume: 1),
            const LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        ),
        models.Container(
          id: 3,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.blue, volume: 2),
            const LiquidLayer(color: LiquidColor.green, volume: 1),
          ],
        ),
        models.Container(
          id: 4,
          capacity: 4,
          liquidLayers: [const LiquidLayer(color: LiquidColor.yellow, volume: 3)],
        ),
        models.Container(id: 5, capacity: 4, liquidLayers: []),
        models.Container(id: 6, capacity: 4, liquidLayers: []),
      ];

      final gameEngine = WaterSortGameEngine();
      final gameState = gameEngine.initializeLevel(1, containers);
      
      print('=== GAMESCREEN SETUP VERIFICATION ===');
      print('Total containers: ${gameState.containers.length}');
      
      // Verify each container matches exactly what we expect
      final container1 = gameState.getContainer(1)!;
      print('\nContainer 1:');
      expect(container1.liquidLayers.length, equals(3));
      expect(container1.liquidLayers[0].color, equals(LiquidColor.red));
      expect(container1.liquidLayers[0].volume, equals(2));
      expect(container1.liquidLayers[1].color, equals(LiquidColor.blue));
      expect(container1.liquidLayers[1].volume, equals(1));
      expect(container1.liquidLayers[2].color, equals(LiquidColor.yellow));
      expect(container1.liquidLayers[2].volume, equals(1));
      print('  ✓ Red(2), Blue(1), Yellow(1) - Top: ${container1.topColor?.displayName}');
      
      final container2 = gameState.getContainer(2)!;
      print('\nContainer 2:');
      expect(container2.liquidLayers.length, equals(2));
      expect(container2.liquidLayers[0].color, equals(LiquidColor.green));
      expect(container2.liquidLayers[0].volume, equals(1));
      expect(container2.liquidLayers[1].color, equals(LiquidColor.red));
      expect(container2.liquidLayers[1].volume, equals(2));
      print('  ✓ Green(1), Red(2) - Top: ${container2.topColor?.displayName}');
      print('  Color codes: Green=0x${LiquidColor.green.value.toRadixString(16).toUpperCase()}, Red=0x${LiquidColor.red.value.toRadixString(16).toUpperCase()}');
      
      final container3 = gameState.getContainer(3)!;
      print('\nContainer 3:');
      expect(container3.liquidLayers.length, equals(2));
      expect(container3.liquidLayers[0].color, equals(LiquidColor.blue));
      expect(container3.liquidLayers[0].volume, equals(2));
      expect(container3.liquidLayers[1].color, equals(LiquidColor.green));
      expect(container3.liquidLayers[1].volume, equals(1));
      print('  ✓ Blue(2), Green(1) - Top: ${container3.topColor?.displayName}');
      
      final container4 = gameState.getContainer(4)!;
      print('\nContainer 4:');
      expect(container4.liquidLayers.length, equals(1));
      expect(container4.liquidLayers[0].color, equals(LiquidColor.yellow));
      expect(container4.liquidLayers[0].volume, equals(3));
      print('  ✓ Yellow(3) - Top: ${container4.topColor?.displayName}');
      
      final container5 = gameState.getContainer(5)!;
      print('\nContainer 5:');
      expect(container5.isEmpty, isTrue);
      print('  ✓ Empty');
      
      final container6 = gameState.getContainer(6)!;
      print('\nContainer 6:');
      expect(container6.isEmpty, isTrue);
      print('  ✓ Empty');
      
      print('\n=== CONTAINER 2 DETAILED ANALYSIS ===');
      print('Container 2 should show:');
      print('  Bottom layer: Green (0x${LiquidColor.green.value.toRadixString(16).toUpperCase()})');
      print('  Top layer: Red (0x${LiquidColor.red.value.toRadixString(16).toUpperCase()})');
      print('  Top color method returns: ${container2.topColor?.displayName} (0x${container2.topColor?.value.toRadixString(16).toUpperCase()})');
      
      // Verify the top continuous layer (what gets poured)
      final topLayer = container2.getTopContinuousLayer();
      print('  Top continuous layer: ${topLayer?.color.displayName} (${topLayer?.volume}) - 0x${topLayer?.color.value.toRadixString(16).toUpperCase()}');
      
      // This should be RED, not pink!
      expect(container2.topColor, equals(LiquidColor.red));
      expect(topLayer?.color, equals(LiquidColor.red));
    });
    
    test('should verify no color confusion between red and pink', () {
      print('\n=== COLOR VERIFICATION ===');
      print('Red color: ${LiquidColor.red.displayName} = 0x${LiquidColor.red.value.toRadixString(16).toUpperCase()}');
      print('Pink color: ${LiquidColor.pink.displayName} = 0x${LiquidColor.pink.value.toRadixString(16).toUpperCase()}');
      
      // Verify they are different
      expect(LiquidColor.red, isNot(equals(LiquidColor.pink)));
      expect(LiquidColor.red.value, isNot(equals(LiquidColor.pink.value)));
      
      // Create a container with red and verify it stays red
      final redContainer = models.Container(
        id: 99,
        capacity: 4,
        liquidLayers: [const LiquidLayer(color: LiquidColor.red, volume: 2)],
      );
      
      expect(redContainer.topColor, equals(LiquidColor.red));
      expect(redContainer.liquidLayers[0].color, equals(LiquidColor.red));
      print('✓ Red container correctly shows red');
      
      // Create a container with pink and verify it stays pink
      final pinkContainer = models.Container(
        id: 98,
        capacity: 4,
        liquidLayers: [const LiquidLayer(color: LiquidColor.pink, volume: 2)],
      );
      
      expect(pinkContainer.topColor, equals(LiquidColor.pink));
      expect(pinkContainer.liquidLayers[0].color, equals(LiquidColor.pink));
      print('✓ Pink container correctly shows pink');
    });
  });
}