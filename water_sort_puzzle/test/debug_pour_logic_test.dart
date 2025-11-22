import 'package:flutter_test/flutter_test.dart';
import 'package:water_sort_puzzle/models/container.dart' as models;
import 'package:water_sort_puzzle/models/liquid_color.dart';
import 'package:water_sort_puzzle/models/liquid_layer.dart';
import 'package:water_sort_puzzle/models/game_state.dart';
import 'package:water_sort_puzzle/services/game_engine.dart';
import 'package:water_sort_puzzle/models/pour_result.dart';

void main() {
  group('Debug Pour Logic - Color Change Bug', () {
    test('should track exact color changes during pour', () {
      // Let's create a test case that specifically shows pink changing to red
      // I'll set up container 2 with pink on top to replicate your issue
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
            const LiquidLayer(color: LiquidColor.pink, volume: 2), // Using pink instead of red
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
      
      print('=== BEFORE POUR ===');
      final container2Before = gameState.getContainer(2)!;
      print('Container 2 layers:');
      for (int i = 0; i < container2Before.liquidLayers.length; i++) {
        final layer = container2Before.liquidLayers[i];
        print('  Layer $i: ${layer.color.displayName} (${layer.volume}) - Color: 0x${layer.color.value.toRadixString(16).toUpperCase()}');
      }
      print('Container 2 top color: ${container2Before.topColor?.displayName}');
      final topLayerBefore = container2Before.getTopContinuousLayer();
      if (topLayerBefore != null) {
        print('Container 2 will pour: ${topLayerBefore.color.displayName} (${topLayerBefore.volume}) - Color: 0x${topLayerBefore.color.value.toRadixString(16).toUpperCase()}');
      }
      
      // Validate the pour
      final pourResult = gameEngine.validatePour(gameState, 2, 5);
      expect(pourResult.isSuccess, isTrue);
      
      if (pourResult.isSuccess) {
        final pourSuccess = pourResult as PourSuccess;
        print('\n=== POUR VALIDATION ===');
        print('Move says it will pour: ${pourSuccess.move.liquidMoved.color.displayName} (${pourSuccess.move.liquidMoved.volume}) - Color: 0x${pourSuccess.move.liquidMoved.color.value.toRadixString(16).toUpperCase()}');
        
        // Execute the pour
        final newGameState = gameEngine.executePour(gameState, 2, 5);
        
        print('\n=== AFTER POUR ===');
        final container2After = newGameState.getContainer(2)!;
        final container5After = newGameState.getContainer(5)!;
        
        print('Container 2 layers:');
        for (int i = 0; i < container2After.liquidLayers.length; i++) {
          final layer = container2After.liquidLayers[i];
          print('  Layer $i: ${layer.color.displayName} (${layer.volume}) - Color: 0x${layer.color.value.toRadixString(16).toUpperCase()}');
        }
        
        print('Container 5 layers:');
        for (int i = 0; i < container5After.liquidLayers.length; i++) {
          final layer = container5After.liquidLayers[i];
          print('  Layer $i: ${layer.color.displayName} (${layer.volume}) - Color: 0x${layer.color.value.toRadixString(16).toUpperCase()}');
        }
        
        // Check if the color changed
        if (topLayerBefore != null && container5After.liquidLayers.isNotEmpty) {
          final pouredColor = container5After.liquidLayers[0].color;
          print('\n=== COLOR CHANGE ANALYSIS ===');
          print('Original top layer color: ${topLayerBefore.color.displayName} (0x${topLayerBefore.color.value.toRadixString(16).toUpperCase()})');
          print('Poured liquid color: ${pouredColor.displayName} (0x${pouredColor.value.toRadixString(16).toUpperCase()})');
          print('Colors match: ${topLayerBefore.color == pouredColor}');
          
          if (topLayerBefore.color != pouredColor) {
            print('🚨 BUG DETECTED: Color changed during pour!');
          }
        }
      }
    });
    
    test('should test with original GameScreen setup to see if red becomes something else', () {
      // Test with the exact original setup from GameScreen
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
      
      print('\n=== ORIGINAL GAMESCREEN SETUP TEST ===');
      final container2Before = gameState.getContainer(2)!;
      print('Container 2 before pour:');
      for (int i = 0; i < container2Before.liquidLayers.length; i++) {
        final layer = container2Before.liquidLayers[i];
        print('  Layer $i: ${layer.color.displayName} (${layer.volume}) - Color: 0x${layer.color.value.toRadixString(16).toUpperCase()}');
      }
      
      // Execute pour from container 2 to 5
      final newGameState = gameEngine.executePour(gameState, 2, 5);
      final container5After = newGameState.getContainer(5)!;
      
      print('Container 5 after pour:');
      for (int i = 0; i < container5After.liquidLayers.length; i++) {
        final layer = container5After.liquidLayers[i];
        print('  Layer $i: ${layer.color.displayName} (${layer.volume}) - Color: 0x${layer.color.value.toRadixString(16).toUpperCase()}');
      }
      
      // The original red should still be red
      expect(container5After.liquidLayers[0].color, equals(LiquidColor.red));
    });
  });
}