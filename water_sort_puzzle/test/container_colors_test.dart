import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/container.dart' as models;
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/game_state.dart';
import 'package:water_sort_puzzle/services/game_engine.dart';

void main() {
  group('Container Colors Debug', () {
    test('should show all container contents from GameScreen setup', () {
      // Create the exact same setup as in GameScreen
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
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.yellow, volume: 3),
          ],
        ),
        models.Container(
          id: 5,
          capacity: 4,
          liquidLayers: [],
        ),
        models.Container(
          id: 6,
          capacity: 4,
          liquidLayers: [],
        ),
      ];
      
      final gameEngine = WaterSortGameEngine();
      final gameState = gameEngine.initializeLevel(1, containers);
      
      print('=== All Container Contents ===');
      for (final container in gameState.containers) {
        print('Container ${container.id}:');
        if (container.isEmpty) {
          print('  (empty)');
        } else {
          for (int i = 0; i < container.liquidLayers.length; i++) {
            final layer = container.liquidLayers[i];
            print('  Layer $i (${i == 0 ? 'bottom' : i == container.liquidLayers.length - 1 ? 'top' : 'middle'}): ${layer.color.displayName} (${layer.volume}) - Color: 0x${layer.color.value.toRadixString(16).toUpperCase()}');
          }
          print('  Top color: ${container.topColor?.displayName}');
          final topLayer = container.getTopContinuousLayer();
          if (topLayer != null) {
            print('  Will pour: ${topLayer.color.displayName} (${topLayer.volume})');
          }
        }
        print('');
      }
      
      // Test specific colors
      print('=== Color Definitions ===');
      print('Red: 0x${LiquidColor.red.value.toRadixString(16).toUpperCase()} - ${LiquidColor.red.displayName}');
      print('Pink: 0x${LiquidColor.pink.value.toRadixString(16).toUpperCase()} - ${LiquidColor.pink.displayName}');
      print('Green: 0x${LiquidColor.green.value.toRadixString(16).toUpperCase()} - ${LiquidColor.green.displayName}');
      print('Blue: 0x${LiquidColor.blue.value.toRadixString(16).toUpperCase()} - ${LiquidColor.blue.displayName}');
      print('Yellow: 0x${LiquidColor.yellow.value.toRadixString(16).toUpperCase()} - ${LiquidColor.yellow.displayName}');
    });
  });
}