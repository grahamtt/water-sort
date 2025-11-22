import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import '../models/level.dart';
import 'game_progress.dart';
import 'player_stats.dart';

/// Exception thrown when storage operations fail
class StorageException implements Exception {
  final String message;
  final dynamic cause;
  
  const StorageException(this.message, [this.cause]);
  
  @override
  String toString() => 'StorageException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Service for managing all persistent storage operations
class StorageService {
  static const String _gameProgressBoxName = 'game_progress';
  static const String _playerStatsBoxName = 'player_stats';
  static const String _levelsBoxName = 'levels';
  static const String _gameStatesBoxName = 'game_states';
  
  // SharedPreferences keys
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _musicEnabledKey = 'music_enabled';
  static const String _hapticFeedbackEnabledKey = 'haptic_feedback_enabled';
  static const String _tutorialCompletedKey = 'tutorial_completed';
  static const String _firstLaunchKey = 'first_launch';
  static const String _appVersionKey = 'app_version';
  static const String _languageCodeKey = 'language_code';
  static const String _themePreferenceKey = 'theme_preference';
  
  late Box<GameProgress> _gameProgressBox;
  late Box<PlayerStats> _playerStatsBox;
  late Box<Level> _levelsBox;
  late Box<GameState> _gameStatesBox;
  late SharedPreferences _prefs;
  
  bool _isInitialized = false;
  
  /// Initialize the storage service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize Hive
      await Hive.initFlutter();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(GameProgressAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PlayerStatsAdapter());
      }
      
      // Open boxes
      _gameProgressBox = await Hive.openBox<GameProgress>(_gameProgressBoxName);
      _playerStatsBox = await Hive.openBox<PlayerStats>(_playerStatsBoxName);
      _levelsBox = await Hive.openBox<Level>(_levelsBoxName);
      _gameStatesBox = await Hive.openBox<GameState>(_gameStatesBoxName);
      
      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();
      
      _isInitialized = true;
      
      // Perform initial setup if this is the first launch
      await _performInitialSetup();
      
    } catch (e) {
      throw StorageException('Failed to initialize storage service', e);
    }
  }
  
  /// Ensure the service is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StorageException('StorageService not initialized. Call initialize() first.');
    }
  }
  
  /// Perform initial setup for first-time users
  Future<void> _performInitialSetup() async {
    final isFirstLaunch = _prefs.getBool(_firstLaunchKey) ?? true;
    
    if (isFirstLaunch) {
      // Set default preferences
      await _prefs.setBool(_soundEnabledKey, true);
      await _prefs.setBool(_musicEnabledKey, true);
      await _prefs.setBool(_hapticFeedbackEnabledKey, true);
      await _prefs.setBool(_tutorialCompletedKey, false);
      await _prefs.setString(_themePreferenceKey, 'system');
      
      // Create initial game progress
      if (_gameProgressBox.isEmpty) {
        final initialProgress = GameProgress();
        await _gameProgressBox.put('progress', initialProgress);
      }
      
      // Create initial player stats
      if (_playerStatsBox.isEmpty) {
        final initialStats = PlayerStats(firstPlayDate: DateTime.now());
        await _playerStatsBox.put('stats', initialStats);
      }
      
      await _prefs.setBool(_firstLaunchKey, false);
    }
  }
  
  // ==================== Game Progress Operations ====================
  
  /// Get the current game progress
  Future<GameProgress> getGameProgress() async {
    _ensureInitialized();
    
    try {
      final progress = _gameProgressBox.get('progress');
      return progress ?? GameProgress();
    } catch (e) {
      throw StorageException('Failed to load game progress', e);
    }
  }
  
  /// Save game progress
  Future<void> saveGameProgress(GameProgress progress) async {
    _ensureInitialized();
    
    try {
      await _gameProgressBox.put('progress', progress);
    } catch (e) {
      throw StorageException('Failed to save game progress', e);
    }
  }
  
  /// Update game progress with a function
  Future<GameProgress> updateGameProgress(GameProgress Function(GameProgress) updater) async {
    final currentProgress = await getGameProgress();
    final updatedProgress = updater(currentProgress);
    await saveGameProgress(updatedProgress);
    return updatedProgress;
  }
  
  // ==================== Player Stats Operations ====================
  
  /// Get the current player statistics
  Future<PlayerStats> getPlayerStats() async {
    _ensureInitialized();
    
    try {
      final stats = _playerStatsBox.get('stats');
      return stats ?? PlayerStats(firstPlayDate: DateTime.now());
    } catch (e) {
      throw StorageException('Failed to load player stats', e);
    }
  }
  
  /// Save player statistics
  Future<void> savePlayerStats(PlayerStats stats) async {
    _ensureInitialized();
    
    try {
      await _playerStatsBox.put('stats', stats);
    } catch (e) {
      throw StorageException('Failed to save player stats', e);
    }
  }
  
  /// Update player stats with a function
  Future<PlayerStats> updatePlayerStats(PlayerStats Function(PlayerStats) updater) async {
    final currentStats = await getPlayerStats();
    final updatedStats = updater(currentStats);
    await savePlayerStats(updatedStats);
    return updatedStats;
  }
  
  // ==================== Game State Operations ====================
  
  /// Save a game state
  Future<void> saveGameState(GameState gameState) async {
    _ensureInitialized();
    
    try {
      await _gameStatesBox.put('current_game', gameState);
      
      // Also update the game progress with the saved state
      await updateGameProgress((progress) => progress.saveGameState(gameState));
    } catch (e) {
      throw StorageException('Failed to save game state', e);
    }
  }
  
  /// Load the current game state
  Future<GameState?> loadGameState() async {
    _ensureInitialized();
    
    try {
      return _gameStatesBox.get('current_game');
    } catch (e) {
      throw StorageException('Failed to load game state', e);
    }
  }
  
  /// Clear the saved game state
  Future<void> clearGameState() async {
    _ensureInitialized();
    
    try {
      await _gameStatesBox.delete('current_game');
      
      // Also update the game progress to clear the saved state
      await updateGameProgress((progress) => progress.clearSavedGameState());
    } catch (e) {
      throw StorageException('Failed to clear game state', e);
    }
  }
  
  // ==================== Level Operations ====================
  
  /// Save a level
  Future<void> saveLevel(Level level) async {
    _ensureInitialized();
    
    try {
      await _levelsBox.put(level.id, level);
    } catch (e) {
      throw StorageException('Failed to save level ${level.id}', e);
    }
  }
  
  /// Load a level by ID
  Future<Level?> loadLevel(int levelId) async {
    _ensureInitialized();
    
    try {
      return _levelsBox.get(levelId);
    } catch (e) {
      throw StorageException('Failed to load level $levelId', e);
    }
  }
  
  /// Save multiple levels
  Future<void> saveLevels(List<Level> levels) async {
    _ensureInitialized();
    
    try {
      final levelMap = <int, Level>{};
      for (final level in levels) {
        levelMap[level.id] = level;
      }
      await _levelsBox.putAll(levelMap);
    } catch (e) {
      throw StorageException('Failed to save levels', e);
    }
  }
  
  /// Load all levels
  Future<List<Level>> loadAllLevels() async {
    _ensureInitialized();
    
    try {
      return _levelsBox.values.toList();
    } catch (e) {
      throw StorageException('Failed to load levels', e);
    }
  }
  
  /// Get the number of stored levels
  Future<int> getLevelCount() async {
    _ensureInitialized();
    return _levelsBox.length;
  }
  
  // ==================== Settings Operations (SharedPreferences) ====================
  
  /// Get sound enabled setting
  bool get isSoundEnabled {
    _ensureInitialized();
    return _prefs.getBool(_soundEnabledKey) ?? true;
  }
  
  /// Set sound enabled setting
  Future<void> setSoundEnabled(bool enabled) async {
    _ensureInitialized();
    await _prefs.setBool(_soundEnabledKey, enabled);
  }
  
  /// Get music enabled setting
  bool get isMusicEnabled {
    _ensureInitialized();
    return _prefs.getBool(_musicEnabledKey) ?? true;
  }
  
  /// Set music enabled setting
  Future<void> setMusicEnabled(bool enabled) async {
    _ensureInitialized();
    await _prefs.setBool(_musicEnabledKey, enabled);
  }
  
  /// Get haptic feedback enabled setting
  bool get isHapticFeedbackEnabled {
    _ensureInitialized();
    return _prefs.getBool(_hapticFeedbackEnabledKey) ?? true;
  }
  
  /// Set haptic feedback enabled setting
  Future<void> setHapticFeedbackEnabled(bool enabled) async {
    _ensureInitialized();
    await _prefs.setBool(_hapticFeedbackEnabledKey, enabled);
  }
  
  /// Get tutorial completed status
  bool get isTutorialCompleted {
    _ensureInitialized();
    return _prefs.getBool(_tutorialCompletedKey) ?? false;
  }
  
  /// Set tutorial completed status
  Future<void> setTutorialCompleted(bool completed) async {
    _ensureInitialized();
    await _prefs.setBool(_tutorialCompletedKey, completed);
  }
  
  /// Get app version
  String? get appVersion {
    _ensureInitialized();
    return _prefs.getString(_appVersionKey);
  }
  
  /// Set app version
  Future<void> setAppVersion(String version) async {
    _ensureInitialized();
    await _prefs.setString(_appVersionKey, version);
  }
  
  /// Get language code
  String? get languageCode {
    _ensureInitialized();
    return _prefs.getString(_languageCodeKey);
  }
  
  /// Set language code
  Future<void> setLanguageCode(String code) async {
    _ensureInitialized();
    await _prefs.setString(_languageCodeKey, code);
  }
  
  /// Get theme preference
  String get themePreference {
    _ensureInitialized();
    return _prefs.getString(_themePreferenceKey) ?? 'system';
  }
  
  /// Set theme preference
  Future<void> setThemePreference(String theme) async {
    _ensureInitialized();
    await _prefs.setString(_themePreferenceKey, theme);
  }
  
  // ==================== Backup and Restore Operations ====================
  
  /// Export all data as JSON for backup
  Future<Map<String, dynamic>> exportData() async {
    _ensureInitialized();
    
    try {
      final gameProgress = await getGameProgress();
      final playerStats = await getPlayerStats();
      final levels = await loadAllLevels();
      final gameState = await loadGameState();
      
      return {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'gameProgress': gameProgress.toJson(),
        'playerStats': playerStats.toJson(),
        'levels': levels.map((level) => level.toJson()).toList(),
        'gameState': gameState?.toJson(),
        'settings': {
          'soundEnabled': isSoundEnabled,
          'musicEnabled': isMusicEnabled,
          'hapticFeedbackEnabled': isHapticFeedbackEnabled,
          'tutorialCompleted': isTutorialCompleted,
          'languageCode': languageCode,
          'themePreference': themePreference,
        },
      };
    } catch (e) {
      throw StorageException('Failed to export data', e);
    }
  }
  
  /// Import data from JSON backup
  Future<void> importData(Map<String, dynamic> data) async {
    _ensureInitialized();
    
    try {
      // Validate data format
      if (data['version'] == null) {
        throw StorageException('Invalid backup data: missing version');
      }
      
      // Import game progress
      if (data['gameProgress'] != null) {
        final gameProgress = GameProgress.fromJson(data['gameProgress']);
        await saveGameProgress(gameProgress);
      }
      
      // Import player stats
      if (data['playerStats'] != null) {
        final playerStats = PlayerStats.fromJson(data['playerStats']);
        await savePlayerStats(playerStats);
      }
      
      // Import levels
      if (data['levels'] != null) {
        final levels = (data['levels'] as List)
            .map((levelJson) => Level.fromJson(levelJson))
            .toList();
        await saveLevels(levels);
      }
      
      // Import game state
      if (data['gameState'] != null) {
        final gameState = GameState.fromJson(data['gameState']);
        await saveGameState(gameState);
      }
      
      // Import settings
      if (data['settings'] != null) {
        final settings = data['settings'] as Map<String, dynamic>;
        
        if (settings['soundEnabled'] != null) {
          await setSoundEnabled(settings['soundEnabled']);
        }
        if (settings['musicEnabled'] != null) {
          await setMusicEnabled(settings['musicEnabled']);
        }
        if (settings['hapticFeedbackEnabled'] != null) {
          await setHapticFeedbackEnabled(settings['hapticFeedbackEnabled']);
        }
        if (settings['tutorialCompleted'] != null) {
          await setTutorialCompleted(settings['tutorialCompleted']);
        }
        if (settings['languageCode'] != null) {
          await setLanguageCode(settings['languageCode']);
        }
        if (settings['themePreference'] != null) {
          await setThemePreference(settings['themePreference']);
        }
      }
    } catch (e) {
      throw StorageException('Failed to import data', e);
    }
  }
  
  // ==================== Maintenance Operations ====================
  
  /// Clear all stored data (for reset/debugging)
  Future<void> clearAllData() async {
    _ensureInitialized();
    
    try {
      await _gameProgressBox.clear();
      await _playerStatsBox.clear();
      await _levelsBox.clear();
      await _gameStatesBox.clear();
      await _prefs.clear();
      
      // Reinitialize with defaults
      await _performInitialSetup();
    } catch (e) {
      throw StorageException('Failed to clear all data', e);
    }
  }
  
  /// Get storage usage information
  Future<Map<String, int>> getStorageInfo() async {
    _ensureInitialized();
    
    return {
      'gameProgressEntries': _gameProgressBox.length,
      'playerStatsEntries': _playerStatsBox.length,
      'levelEntries': _levelsBox.length,
      'gameStateEntries': _gameStatesBox.length,
    };
  }
  
  /// Compact the database to reclaim space
  Future<void> compactDatabase() async {
    _ensureInitialized();
    
    try {
      await _gameProgressBox.compact();
      await _playerStatsBox.compact();
      await _levelsBox.compact();
      await _gameStatesBox.compact();
    } catch (e) {
      throw StorageException('Failed to compact database', e);
    }
  }
  
  /// Close all storage connections
  Future<void> close() async {
    if (!_isInitialized) return;
    
    try {
      await _gameProgressBox.close();
      await _playerStatsBox.close();
      await _levelsBox.close();
      await _gameStatesBox.close();
      
      _isInitialized = false;
    } catch (e) {
      throw StorageException('Failed to close storage service', e);
    }
  }
}