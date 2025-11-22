import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/container.dart' as models;
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/game_state.dart';
import 'package:water_sort_puzzle/services/game_engine.dart';

void main() {
  group('Actual Colors Investigation', () {
    test('should show exact colors being created in GameScreen setup', () {
      // Replicate EXACT GameScreen setup
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
      final initialGameState = gameEngine.initializeLevel(1, containers);
      
      print('=== INITIAL GAME STATE COLORS ===');
      
      // Check each container's actual colors
      for (int i = 1; i <= 6; i++) {
        final container = initialGameState.getContainer(i)!;
        print('\nContainer $i:');
        if (container.isEmpty) {
          print('  Empty');
        } else {
          for (int j = 0; j < container.liquidLayers.length; j++) {
            final layer = container.liquidLayers[j];
            print('  Layer $j: ${layer.color.name} (${layer.color.displayName}) = 0x${layer.color.value.toRadixString(16).toUpperCase()}');
            
            // Check if this is actually the color we expect
            if (i == 2 && j == 1) {
              print('    ^^^ This should be RED, is it? ${layer.color == LiquidColor.red}');
              if (layer.color != LiquidColor.red) {
                print('    🚨 PROBLEM: Expected RED but got ${layer.color.name}!');
              }
            }
          }
        }
      }
      
      // Specifically check container 2
      final container2 = initialGameState.getContainer(2)!;
      print('\n=== CONTAINER 2 DETAILED CHECK ===');
      print('Layers count: ${container2.liquidLayers.length}');
      
      if (container2.liquidLayers.length >= 2) {
        final bottomLayer = container2.liquidLayers[0];
        final topLayer = container2.liquidLayers[1];
        
        print('Bottom layer: ${bottomLayer.color.name} (${bottomLayer.color.displayName})');
        print('Top layer: ${topLayer.color.name} (${topLayer.color.displayName})');
        
        // Verify these are the expected colors
        expect(bottomLayer.color, equals(LiquidColor.green), reason: 'Bottom should be green');
        expect(topLayer.color, equals(LiquidColor.red), reason: 'Top should be red');
        
        print('✓ Colors are correct in the model');
      }
      
      // Check all available colors to see if there's confusion
      print('\n=== ALL AVAILABLE COLORS ===');
      for (final color in LiquidColor.values) {
        print('${color.name}: ${color.displayName} = 0x${color.value.toRadixString(16).toUpperCase()}');
      }
    });
    
    test('should check if game engine initialization changes colors', () {
      print('\n=== GAME ENGINE INITIALIZATION TEST ===');
      
      // Create containers directly
      final directContainers = [
        models.Container(
          id: 2,
          capacity: 4,
          liquidLayers: [
            const LiquidLayer(color: LiquidColor.green, volume: 1),
            const LiquidLayer(color: LiquidColor.red, volume: 2),
          ],
        ),
      ];
      
      print('Direct container creation:');
      final directContainer = directContainers[0];
      print('  Top layer: ${directContainer.liquidLayers[1].color.name} = 0x${directContainer.liquidLayers[1].color.value.toRadixString(16).toUpperCase()}');
      
      // Now initialize through game engine
      final gameEngine = WaterSortGameEngine();
      final gameState = gameEngine.initializeLevel(1, directContainers);
      
      print('After game engine initialization:');
      final engineContainer = gameState.getContainer(2)!;
      print('  Top layer: ${engineContainer.liquidLayers[1].color.name} = 0x${engineContainer.liquidLayers[1].color.value.toRadixString(16).toUpperCase()}');
      
      // Check if they're the same
      final directColor = directContainer.liquidLayers[1].color;
      final engineColor = engineContainer.liquidLayers[1].color;
      
      print('Colors match: ${directColor == engineColor}');
      
      if (directColor != engineColor) {
        print('🚨 GAME ENGINE IS CHANGING COLORS!');
      } else {
        print('✓ Game engine preserves colors correctly');
      }
    });
  });
}