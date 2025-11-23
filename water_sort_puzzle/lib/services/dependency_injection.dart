import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/storage_service.dart';
import '../storage/game_progress.dart';
import '../services/test_mode_manager.dart';
import '../services/progress_override.dart';
import '../services/level_generator.dart';
import '../services/game_engine.dart';
import '../services/audio_manager.dart';
import '../providers/game_state_provider.dart';

/// Service locator for managing app-wide dependencies
class DependencyInjection {
  static DependencyInjection? _instance;
  static DependencyInjection get instance => _instance ??= DependencyInjection._();
  
  DependencyInjection._();

  // Core services
  SharedPreferences? _sharedPreferences;
  StorageService? _storageService;
  TestModeManager? _testModeManager;
  LevelGenerator? _levelGenerator;
  WaterSortGameEngine? _gameEngine;
  AudioManager? _audioManager;

  // State management
  GameProgress? _gameProgress;
  ProgressOverride? _progressOverride;

  bool _isInitialized = false;

  /// Initialize all dependencies in the correct order
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize SharedPreferences first (required by other services)
      _sharedPreferences = await SharedPreferences.getInstance();

      // Initialize storage service
      _storageService = StorageService();
      await _storageService!.initialize();

      // Initialize audio manager
      _audioManager = AudioManager();
      await _audioManager!.initialize();

      // Initialize test mode manager (depends on SharedPreferences)
      _testModeManager = TestModeManager(_sharedPreferences!);

      // Initialize level generator
      _levelGenerator = WaterSortLevelGenerator();

      // Initialize game engine
      _gameEngine = WaterSortGameEngine();

      // Load game progress from storage
      _gameProgress = await _storageService!.getGameProgress();

      // Create progress override (depends on game progress and test mode manager)
      _progressOverride = ProgressOverride(_gameProgress!, _testModeManager!);

      _isInitialized = true;
    } catch (e) {
      throw DependencyInjectionException('Failed to initialize dependencies: $e');
    }
  }

  /// Get SharedPreferences instance
  SharedPreferences get sharedPreferences {
    _ensureInitialized();
    return _sharedPreferences!;
  }

  /// Get StorageService instance
  StorageService get storageService {
    _ensureInitialized();
    return _storageService!;
  }

  /// Get TestModeManager instance
  TestModeManager get testModeManager {
    _ensureInitialized();
    return _testModeManager!;
  }

  /// Get LevelGenerator instance
  LevelGenerator get levelGenerator {
    _ensureInitialized();
    return _levelGenerator!;
  }

  /// Get WaterSortGameEngine instance
  WaterSortGameEngine get gameEngine {
    _ensureInitialized();
    return _gameEngine!;
  }

  /// Get AudioManager instance
  AudioManager get audioManager {
    _ensureInitialized();
    return _audioManager!;
  }

  /// Get GameProgress instance
  GameProgress get gameProgress {
    _ensureInitialized();
    return _gameProgress!;
  }

  /// Get ProgressOverride instance
  ProgressOverride get progressOverride {
    _ensureInitialized();
    return _progressOverride!;
  }

  /// Update game progress and refresh progress override
  Future<void> updateGameProgress(GameProgress newProgress) async {
    _ensureInitialized();
    
    _gameProgress = newProgress;
    await _storageService!.saveGameProgress(newProgress);
    
    // Recreate progress override with updated progress
    _progressOverride = ProgressOverride(_gameProgress!, _testModeManager!);
  }

  /// Create a GameStateProvider with all required dependencies
  GameStateProvider createGameStateProvider() {
    _ensureInitialized();
    return GameStateProvider(
      gameEngine: _gameEngine!,
      levelGenerator: _levelGenerator!,
    );
  }

  /// Dispose of all resources
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      // Dispose test mode manager
      _testModeManager?.dispose();

      // Close storage service
      await _storageService?.close();

      // Reset all instances
      _sharedPreferences = null;
      _storageService = null;
      _testModeManager = null;
      _levelGenerator = null;
      _gameEngine = null;
      _audioManager = null;
      _gameProgress = null;
      _progressOverride = null;

      _isInitialized = false;
    } catch (e) {
      throw DependencyInjectionException('Failed to dispose dependencies: $e');
    }
  }

  /// Ensure dependencies are initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw DependencyInjectionException(
        'Dependencies not initialized. Call DependencyInjection.instance.initialize() first.',
      );
    }
  }

  /// Reset instance (for testing purposes)
  @visibleForTesting
  static void reset() {
    _instance = null;
  }
}

/// Exception thrown when dependency injection operations fail
class DependencyInjectionException implements Exception {
  final String message;
  final dynamic cause;

  const DependencyInjectionException(this.message, [this.cause]);

  @override
  String toString() {
    return 'DependencyInjectionException: $message${cause != null ? ' (caused by: $cause)' : ''}';
  }
}

/// Provider widget that provides all dependencies to the widget tree
class DependencyProvider extends StatelessWidget {
  final Widget child;

  const DependencyProvider({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final di = DependencyInjection.instance;

    return MultiProvider(
      providers: [
        // Core services
        Provider<SharedPreferences>.value(value: di.sharedPreferences),
        Provider<StorageService>.value(value: di.storageService),
        Provider<TestModeManager>.value(value: di.testModeManager),
        Provider<LevelGenerator>.value(value: di.levelGenerator),
        Provider<WaterSortGameEngine>.value(value: di.gameEngine),
        Provider<AudioManager>.value(value: di.audioManager),

        // Progress management
        Provider<GameProgress>.value(value: di.gameProgress),
        Provider<ProgressOverride>.value(value: di.progressOverride),

        // Game state provider (created fresh for each use)
        ChangeNotifierProvider<GameStateProvider>(
          create: (_) => di.createGameStateProvider(),
        ),
      ],
      child: child,
    );
  }
}

/// Extension methods for easy access to dependencies from BuildContext
extension DependencyContext on BuildContext {
  /// Get TestModeManager from context
  TestModeManager get testModeManager => read<TestModeManager>();

  /// Get ProgressOverride from context
  ProgressOverride get progressOverride => read<ProgressOverride>();

  /// Get StorageService from context
  StorageService get storageService => read<StorageService>();

  /// Get LevelGenerator from context
  LevelGenerator get levelGenerator => read<LevelGenerator>();

  /// Get WaterSortGameEngine from context
  WaterSortGameEngine get gameEngine => read<WaterSortGameEngine>();

  /// Get AudioManager from context
  AudioManager get audioManager => read<AudioManager>();

  /// Get GameProgress from context
  GameProgress get gameProgress => read<GameProgress>();

  /// Get GameStateProvider from context
  GameStateProvider get gameStateProvider => read<GameStateProvider>();

  /// Watch TestModeManager for changes
  TestModeManager watchTestModeManager() => watch<TestModeManager>();

  /// Watch ProgressOverride for changes
  ProgressOverride watchProgressOverride() => watch<ProgressOverride>();

  /// Watch GameStateProvider for changes
  GameStateProvider watchGameStateProvider() => watch<GameStateProvider>();
}