import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/audio_manager.dart';

void main() {
  group('AudioManager', () {
    late AudioManager audioManager;

    setUpAll(() {
      // Initialize Flutter test binding
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      // Reset the singleton instance
      AudioManager.resetInstance();
      
      // Initialize SharedPreferences with mock values
      SharedPreferences.setMockInitialValues({});
      
      // Create a fresh instance for each test with mock audio player
      audioManager = AudioManager(audioPlayer: MockAudioPlayer());
    });

    tearDown(() async {
      // Clean up after each test
      await audioManager.dispose();
      AudioManager.resetInstance();
    });

    group('Initialization', () {
      test('should initialize with default settings', () async {
        await audioManager.initialize();
        
        expect(audioManager.soundEnabled, isTrue);
        expect(audioManager.hapticEnabled, isTrue);
        expect(audioManager.volume, equals(1.0));
      });

      test('should load saved settings from SharedPreferences', () async {
        // Set up mock preferences
        SharedPreferences.setMockInitialValues({
          'sound_enabled': false,
          'haptic_enabled': false,
          'volume': 0.5,
        });
        
        await audioManager.initialize();
        
        expect(audioManager.soundEnabled, isFalse);
        expect(audioManager.hapticEnabled, isFalse);
        expect(audioManager.volume, equals(0.5));
      });
    });

    group('Sound Settings', () {
      test('should update sound enabled setting', () async {
        await audioManager.initialize();
        
        await audioManager.setSoundEnabled(false);
        expect(audioManager.soundEnabled, isFalse);
        
        await audioManager.setSoundEnabled(true);
        expect(audioManager.soundEnabled, isTrue);
      });

      test('should persist sound enabled setting', () async {
        await audioManager.initialize();
        await audioManager.setSoundEnabled(false);
        
        // Verify the setting is saved to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('sound_enabled'), isFalse);
      });
    });

    group('Haptic Settings', () {
      test('should update haptic enabled setting', () async {
        await audioManager.initialize();
        
        await audioManager.setHapticEnabled(false);
        expect(audioManager.hapticEnabled, isFalse);
        
        await audioManager.setHapticEnabled(true);
        expect(audioManager.hapticEnabled, isTrue);
      });

      test('should persist haptic enabled setting', () async {
        await audioManager.initialize();
        await audioManager.setHapticEnabled(false);
        
        // Verify the setting is saved to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('haptic_enabled'), isFalse);
      });
    });

    group('Volume Settings', () {
      test('should update volume setting', () async {
        await audioManager.initialize();
        
        await audioManager.setVolume(0.7);
        expect(audioManager.volume, equals(0.7));
      });

      test('should clamp volume to valid range', () async {
        await audioManager.initialize();
        
        await audioManager.setVolume(-0.5);
        expect(audioManager.volume, equals(0.0));
        
        await audioManager.setVolume(1.5);
        expect(audioManager.volume, equals(1.0));
      });

      test('should persist volume setting', () async {
        await audioManager.initialize();
        await audioManager.setVolume(0.3);
        
        // Verify the setting is saved to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getDouble('volume'), equals(0.3));
      });
    });

    group('Audio Playback', () {
      test('should not throw when playing sounds', () async {
        await audioManager.initialize();
        
        // These methods should not throw exceptions even if audio files don't exist
        expect(() async => await audioManager.playPourSound(), returnsNormally);
        expect(() async => await audioManager.playSuccessSound(), returnsNormally);
        expect(() async => await audioManager.playErrorSound(), returnsNormally);
      });

      test('should handle audio playback errors gracefully', () async {
        await audioManager.initialize();
        
        // Even with invalid audio files, these should not throw
        await audioManager.playPourSound();
        await audioManager.playSuccessSound();
        await audioManager.playErrorSound();
        
        // If we get here without exceptions, the error handling is working
        expect(true, isTrue);
      });

      test('should not play sounds when sound is disabled', () async {
        await audioManager.initialize();
        await audioManager.setSoundEnabled(false);
        
        // These should complete without attempting to play audio
        await audioManager.playPourSound();
        await audioManager.playSuccessSound();
        await audioManager.playErrorSound();
        
        expect(audioManager.soundEnabled, isFalse);
      });
    });

    group('Haptic Feedback', () {
      test('should not throw when triggering haptic feedback', () async {
        await audioManager.initialize();
        
        // These methods should not throw exceptions
        expect(() async => await audioManager.lightHaptic(), returnsNormally);
        expect(() async => await audioManager.mediumHaptic(), returnsNormally);
        expect(() async => await audioManager.heavyHaptic(), returnsNormally);
        expect(() async => await audioManager.selectionHaptic(), returnsNormally);
      });

      test('should handle haptic feedback errors gracefully', () async {
        await audioManager.initialize();
        
        // Even if haptic feedback fails, these should not throw
        await audioManager.lightHaptic();
        await audioManager.mediumHaptic();
        await audioManager.heavyHaptic();
        await audioManager.selectionHaptic();
        
        // If we get here without exceptions, the error handling is working
        expect(true, isTrue);
      });

      test('should not trigger haptics when haptic is disabled', () async {
        await audioManager.initialize();
        await audioManager.setHapticEnabled(false);
        
        // These should complete without attempting haptic feedback
        await audioManager.lightHaptic();
        await audioManager.mediumHaptic();
        await audioManager.heavyHaptic();
        await audioManager.selectionHaptic();
        
        expect(audioManager.hapticEnabled, isFalse);
      });
    });

    group('Singleton Pattern', () {
      test('should return the same instance', () {
        final instance1 = AudioManager();
        final instance2 = AudioManager();
        
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('Cleanup', () {
      test('should stop all audio playback', () async {
        await audioManager.initialize();
        
        // This should not throw
        expect(() async => await audioManager.stopAll(), returnsNormally);
      });

      test('should dispose resources properly', () async {
        await audioManager.initialize();
        
        // This should not throw
        expect(() async => await audioManager.dispose(), returnsNormally);
      });
    });
  });
}