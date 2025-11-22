import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract interface for audio playback to enable testing
abstract class AudioPlayerInterface {
  Future<void> play(Source source);
  Future<void> setVolume(double volume);
  Future<void> stop();
  Future<void> dispose();
}

/// Concrete implementation of AudioPlayerInterface using audioplayers package
class AudioPlayerImpl implements AudioPlayerInterface {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> play(Source source) async {
    await _player.play(source);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
  }
}

/// Mock implementation for testing
class MockAudioPlayer implements AudioPlayerInterface {
  @override
  Future<void> play(Source source) async {
    // Mock implementation - do nothing
  }

  @override
  Future<void> setVolume(double volume) async {
    // Mock implementation - do nothing
  }

  @override
  Future<void> stop() async {
    // Mock implementation - do nothing
  }

  @override
  Future<void> dispose() async {
    // Mock implementation - do nothing
  }
}

/// Manages audio playback and haptic feedback for the game
class AudioManager {
  static AudioManager? _instance;
  factory AudioManager({AudioPlayerInterface? audioPlayer}) {
    _instance ??= AudioManager._internal(audioPlayer ?? AudioPlayerImpl());
    return _instance!;
  }
  AudioManager._internal(this._audioPlayer);

  final AudioPlayerInterface _audioPlayer;
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  double _volume = 1.0;

  static const String _soundEnabledKey = 'sound_enabled';
  static const String _hapticEnabledKey = 'haptic_enabled';
  static const String _volumeKey = 'volume';

  /// Initialize the audio manager and load settings
  Future<void> initialize() async {
    await _loadSettings();
    await _audioPlayer.setVolume(_volume);
  }

  /// Load audio settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
    _hapticEnabled = prefs.getBool(_hapticEnabledKey) ?? true;
    _volume = prefs.getDouble(_volumeKey) ?? 1.0;
  }

  /// Save audio settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, _soundEnabled);
    await prefs.setBool(_hapticEnabledKey, _hapticEnabled);
    await prefs.setDouble(_volumeKey, _volume);
  }

  /// Play pour sound effect
  Future<void> playPourSound() async {
    if (_soundEnabled) {
      await _playSound('audio/pour.mp3', 'pour');
    }
  }

  /// Play success sound effect
  Future<void> playSuccessSound() async {
    if (_soundEnabled) {
      await _playSound('audio/success.mp3', 'success');
    }
  }

  /// Play error sound effect
  Future<void> playErrorSound() async {
    if (_soundEnabled) {
      await _playSound('audio/error.mp3', 'error');
    }
  }

  /// Internal method to play a sound with better error handling
  Future<void> _playSound(String assetPath, String soundName) async {
    try {
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      // Handle different types of audio errors more gracefully
      if (e.toString().contains('Format error') || 
          e.toString().contains('Failed to set source') ||
          e.toString().contains('MEDIA_ELEMENT_ERROR')) {
        // This is likely a missing or invalid audio file
        print('Audio file not found or invalid format for $soundName sound. '
              'Please add a valid MP3 file at assets/$assetPath');
      } else {
        // Other audio errors (permissions, device issues, etc.)
        print('Error playing $soundName sound: $e');
      }
    }
  }

  /// Trigger light haptic feedback
  Future<void> lightHaptic() async {
    if (_hapticEnabled) {
      try {
        await HapticFeedback.lightImpact();
      } catch (e) {
        // Silently handle haptic feedback errors
        print('Error triggering light haptic: $e');
      }
    }
  }

  /// Trigger medium haptic feedback
  Future<void> mediumHaptic() async {
    if (_hapticEnabled) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (e) {
        // Silently handle haptic feedback errors
        print('Error triggering medium haptic: $e');
      }
    }
  }

  /// Trigger heavy haptic feedback
  Future<void> heavyHaptic() async {
    if (_hapticEnabled) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (e) {
        // Silently handle haptic feedback errors
        print('Error triggering heavy haptic: $e');
      }
    }
  }

  /// Trigger selection haptic feedback
  Future<void> selectionHaptic() async {
    if (_hapticEnabled) {
      try {
        await HapticFeedback.selectionClick();
      } catch (e) {
        // Silently handle haptic feedback errors
        print('Error triggering selection haptic: $e');
      }
    }
  }

  /// Get current sound enabled state
  bool get soundEnabled => _soundEnabled;

  /// Set sound enabled state
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _saveSettings();
  }

  /// Get current haptic enabled state
  bool get hapticEnabled => _hapticEnabled;

  /// Set haptic enabled state
  Future<void> setHapticEnabled(bool enabled) async {
    _hapticEnabled = enabled;
    await _saveSettings();
  }

  /// Get current volume level (0.0 to 1.0)
  double get volume => _volume;

  /// Set volume level (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
    await _saveSettings();
  }

  /// Stop all audio playback
  Future<void> stopAll() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
    } catch (e) {
      print('Error disposing audio player: $e');
    }
  }

  /// Reset the singleton instance (for testing purposes)
  static void resetInstance() {
    _instance = null;
  }
}