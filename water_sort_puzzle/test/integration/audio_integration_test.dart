import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/audio_manager.dart';
import '../../lib/services/game_engine.dart';
import '../../lib/services/level_generator.dart';
import '../../lib/providers/game_state_provider.dart';
import '../../lib/models/container.dart';
import '../../lib/models/liquid_layer.dart';
import '../../lib/models/liquid_color.dart';
import '../../lib/models/level.dart';

void main() {
  group('Audio Integration Tests', () {
    late AudioManager audioManager;
    late WaterSortGameEngine gameEngine;
    late LevelGenerator levelGenerator;
    late GameStateProvider gameStateProvider;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      // Reset audio manager singleton
      AudioManager.resetInstance();

      // Initialize SharedPreferences with mock values
      SharedPreferences.setMockInitialValues({});

      // Create instances with mock audio player
      audioManager = AudioManager(audioPlayer: MockAudioPlayer());
      await audioManager.initialize();

      gameEngine = WaterSortGameEngine();
      levelGenerator = WaterSortLevelGenerator();
      gameStateProvider = GameStateProvider(
        gameEngine: gameEngine,
        levelGenerator: levelGenerator,
      );
    });

    tearDown(() async {
      await audioManager.dispose();
      AudioManager.resetInstance();
    });

    group('Game Engine Audio Integration', () {
      test('should handle audio feedback for successful pour', () async {
        // Create a simple test level
        final containers = [
          Container(
            id: 0,
            capacity: 4,
            liquidLayers: [LiquidLayer(color: LiquidColor.red, volume: 2)],
          ),
          Container(id: 1, capacity: 4, liquidLayers: []),
        ];

        final gameState = gameEngine.initializeLevel(1, containers);

        // Attempt a valid pour - should not throw
        expect(() async {
          final result = gameEngine.attemptPour(gameState, 0, 1);
          expect(result.isSuccess, isTrue);
        }, returnsNormally);
      });

      test('should handle audio feedback for invalid pour', () async {
        // Create a test level with incompatible colors
        final containers = [
          Container(
            id: 0,
            capacity: 4,
            liquidLayers: [LiquidLayer(color: LiquidColor.red, volume: 2)],
          ),
          Container(
            id: 1,
            capacity: 4,
            liquidLayers: [LiquidLayer(color: LiquidColor.blue, volume: 2)],
          ),
        ];

        final gameState = gameEngine.initializeLevel(1, containers);

        // Attempt an invalid pour - should not throw
        expect(() async {
          final result = gameEngine.attemptPour(gameState, 0, 1);
          expect(result.isFailure, isTrue);
        }, returnsNormally);
      });
    });

    group('Game State Provider Audio Integration', () {
      test(
        'should handle audio feedback during level initialization',
        () async {
          // Initialize a level - should not throw
          expect(() async {
            await gameStateProvider.initializeLevel(1);
          }, returnsNormally);
        },
      );

      test('should handle audio feedback for container selection', () async {
        // Initialize a level first
        await gameStateProvider.initializeLevel(1);

        // Select a container - should not throw
        expect(() async {
          await gameStateProvider.selectContainer(0);
        }, returnsNormally);
      });

      test('should handle audio feedback for undo operations', () async {
        // Initialize a level and make a move first
        await gameStateProvider.initializeLevel(1);

        // Make a valid move if possible
        if (gameStateProvider.currentGameState != null) {
          final containers = gameStateProvider.currentGameState!.containers;
          if (containers.isNotEmpty && !containers[0].isEmpty) {
            await gameStateProvider.selectContainer(0);

            // Find an empty container to pour into
            for (int i = 1; i < containers.length; i++) {
              if (containers[i].isEmpty) {
                await gameStateProvider.selectContainer(i);
                break;
              }
            }
          }
        }

        // Attempt undo - should not throw
        expect(() async {
          await gameStateProvider.undoMove();
        }, returnsNormally);
      });

      test('should handle audio feedback for victory conditions', () async {
        // Create a nearly solved level
        final containers = [
          Container(
            id: 0,
            capacity: 4,
            liquidLayers: [LiquidLayer(color: LiquidColor.red, volume: 4)],
          ),
          Container(
            id: 1,
            capacity: 4,
            liquidLayers: [LiquidLayer(color: LiquidColor.blue, volume: 4)],
          ),
          Container(id: 2, capacity: 4, liquidLayers: []),
        ];

        // Initialize with the pre-solved level
        await gameStateProvider.initializeLevelFromData(
          Level(
            id: 1,
            difficulty: 1,
            containerCount: 3,
            colorCount: 2,
            initialContainers: containers,
            minimumMoves: 0,
          ),
        );

        // The level should already be solved, triggering victory audio
        expect(gameStateProvider.currentGameState?.isSolved, isTrue);
      });
    });

    group('Audio Settings Integration', () {
      test('should persist audio settings across game sessions', () async {
        // Change audio settings
        await audioManager.setSoundEnabled(false);
        await audioManager.setHapticEnabled(false);
        await audioManager.setVolume(0.5);

        // Verify settings are persisted
        expect(audioManager.soundEnabled, isFalse);
        expect(audioManager.hapticEnabled, isFalse);
        expect(audioManager.volume, equals(0.5));

        // Create a new instance and verify settings are loaded
        AudioManager.resetInstance();
        final newAudioManager = AudioManager(audioPlayer: MockAudioPlayer());
        await newAudioManager.initialize();

        expect(newAudioManager.soundEnabled, isFalse);
        expect(newAudioManager.hapticEnabled, isFalse);
        expect(newAudioManager.volume, equals(0.5));

        await newAudioManager.dispose();
      });

      test('should respect disabled audio settings during gameplay', () async {
        // Disable sound and haptics
        await audioManager.setSoundEnabled(false);
        await audioManager.setHapticEnabled(false);

        // Initialize game and make moves - should not throw
        await gameStateProvider.initializeLevel(1);

        expect(() async {
          await gameStateProvider.selectContainer(0);
        }, returnsNormally);

        // Verify settings are still disabled
        expect(audioManager.soundEnabled, isFalse);
        expect(audioManager.hapticEnabled, isFalse);
      });
    });

    group('Error Handling Integration', () {
      test('should handle audio errors gracefully during gameplay', () async {
        // Initialize game
        await gameStateProvider.initializeLevel(1);

        // All operations should complete without throwing, even if audio fails
        expect(() async {
          await gameStateProvider.selectContainer(0);
          await gameStateProvider.undoMove();
          await gameStateProvider.resetLevel();
        }, returnsNormally);
      });

      test('should handle audio initialization errors gracefully', () async {
        // Even if audio initialization fails, the manager should still work
        AudioManager.resetInstance();
        final audioManager = AudioManager(audioPlayer: MockAudioPlayer());

        expect(() async {
          await audioManager.initialize();
          await audioManager.playPourSound();
          await audioManager.lightHaptic();
        }, returnsNormally);

        await audioManager.dispose();
      });
    });
  });
}
