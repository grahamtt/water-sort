import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/game_state.dart';
import '../models/level.dart';
import '../models/pour_result.dart';
import '../models/liquid_color.dart';
import '../animations/animation_queue.dart';
import '../animations/pour_animation.dart';

import '../services/game_engine.dart';
import '../services/level_generator.dart';
import '../services/audio_manager.dart';
import '../services/level_parameters.dart';

/// Enum representing different loading states for async operations
enum GameLoadingState {
  idle,
  loading,
  saving,
  loadingLevel,
  error,
}

/// Enum representing different UI states for user feedback
enum GameUIState {
  idle,
  containerSelected,
  pouring,
  victory,
  error,
}

/// Provider class that manages the game state and handles all game operations
class GameStateProvider extends ChangeNotifier {
  final WaterSortGameEngine _gameEngine;
  final LevelGenerator _levelGenerator;
  final AudioManager _audioManager = AudioManager();
  final AnimationQueue _animationQueue = AnimationQueue();

  // Core game state
  GameState? _currentGameState;
  GameLoadingState _loadingState = GameLoadingState.idle;
  GameUIState _uiState = GameUIState.idle;
  
  // UI state management
  int? _selectedContainerId;
  String? _errorMessage;
  String? _feedbackMessage;
  
  // Animation event subscription
  StreamSubscription<AnimationEvent>? _animationEventSubscription;
  
  GameStateProvider({
    required WaterSortGameEngine gameEngine,
    required LevelGenerator levelGenerator,
  }) : _gameEngine = gameEngine,
       _levelGenerator = levelGenerator {
    // Listen to animation events
    _animationEventSubscription = _animationQueue.animationEvents.listen(_handleAnimationEvent);
  }

  // Getters for current state
  GameState? get currentGameState => _currentGameState;
  GameLoadingState get loadingState => _loadingState;
  GameUIState get uiState => _uiState;
  int? get selectedContainerId => _selectedContainerId;
  String? get errorMessage => _errorMessage;
  String? get feedbackMessage => _feedbackMessage;
  bool get isAnimating => _animationQueue.isAnimating;
  
  // Convenience getters
  bool get isLoading => _loadingState != GameLoadingState.idle;
  bool get hasError => _loadingState == GameLoadingState.error || _uiState == GameUIState.error;
  bool get isGameActive => _currentGameState != null && !_currentGameState!.isCompleted;
  bool get canUndo => _currentGameState?.canUndo ?? false;
  bool get canRedo => _currentGameState?.canRedo ?? false;
  bool get isVictory => _uiState == GameUIState.victory;
  
  /// Initialize a new level
  Future<void> initializeLevel(int levelId) async {
    try {
      _setLoadingState(GameLoadingState.loadingLevel);
      _clearError();
      
      // Generate level containers
      // Calculate difficulty and parameters based on level ID
      final difficulty = LevelParameters.calculateDifficultyForLevel(levelId);
      final colorCount = LevelParameters.calculateColorCountForLevel(levelId);
      final containerCapacity = LevelParameters.calculateContainerCapacity(levelId);
      final emptySlots = LevelParameters.calculateEmptySlotsForLevel(levelId);
      
      final level = _levelGenerator.generateLevel(levelId, difficulty, colorCount, containerCapacity, emptySlots);
      
      // Initialize game state
      _currentGameState = _gameEngine.initializeLevel(levelId, level.initialContainers);
      _setUIState(GameUIState.idle);
      _selectedContainerId = null;
      
      _setLoadingState(GameLoadingState.idle);
      notifyListeners();
    } catch (e) {
      _handleError('Failed to initialize level $levelId: ${e.toString()}');
    }
  }
  
  /// Initialize a level from existing level data
  Future<void> initializeLevelFromData(Level level) async {
    try {
      _setLoadingState(GameLoadingState.loadingLevel);
      _clearError();
      
      // Initialize game state with the provided level data
      _currentGameState = _gameEngine.initializeLevel(level.id, level.initialContainers);
      _setUIState(GameUIState.idle);
      _selectedContainerId = null;
      
      _setLoadingState(GameLoadingState.idle);
      notifyListeners();
    } catch (e) {
      _handleError('Failed to initialize level ${level.id}: ${e.toString()}');
    }
  }
  
  /// Handle container selection and pouring logic
  Future<void> selectContainer(int containerId) async {
    if (isAnimating || _currentGameState == null) return;
    
    try {
      // If no container is selected, select this one
      if (_selectedContainerId == null) {
        _selectContainer(containerId);
        return;
      }
      
      // If the same container is selected, deselect it
      if (_selectedContainerId == containerId) {
        _deselectContainer();
        return;
      }
      
      // Attempt to pour from selected container to this container
      await _attemptPour(_selectedContainerId!, containerId);
      
    } catch (e) {
      _handleError('Error selecting container: ${e.toString()}');
    }
  }
  
  /// Attempt to pour liquid from one container to another
  Future<void> _attemptPour(int fromContainerId, int toContainerId) async {
    if (_currentGameState == null) return;
    
    try {
      // Validate and attempt the pour
      final pourResult = _gameEngine.attemptPour(
        _currentGameState!,
        fromContainerId,
        toContainerId,
      );
      
      if (pourResult.isSuccess) {
        // Execute the pour and update game state IMMEDIATELY
        final newGameState = _gameEngine.executePour(
          _currentGameState!,
          fromContainerId,
          toContainerId,
        );
        
        _currentGameState = newGameState;
        _deselectContainer();
        
        // Create and queue the animation (non-blocking)
        // Note: We need to get the liquid info from the old state before the pour
        final oldGameState = _gameEngine.attemptPour(_currentGameState!, fromContainerId, toContainerId);
        if (oldGameState.isSuccess) {
          // Get the source container from the previous state to determine what was poured
          final previousState = _currentGameState!; // This is actually the new state now
          // We'll create a simple animation based on the move
          final animation = PourAnimation(
            fromContainer: fromContainerId,
            toContainer: toContainerId,
            liquidColor: LiquidColor.blue, // Default color - this should be improved
            volume: 1, // Default volume - this should be improved
          );
          _animationQueue.addAnimation(animation);
        }
        
        // Check for victory immediately (don't wait for animation)
        if (_gameEngine.checkWinCondition(newGameState)) {
          await _handleVictory(newGameState);
        } else {
          _setUIState(GameUIState.idle);
        }
        
      } else {
        // Handle pour failure
        _handlePourFailure(pourResult as PourFailure);
        _deselectContainer();
        _setUIState(GameUIState.idle);
      }
      
    } catch (e) {
      _handleError('Error during pour operation: ${e.toString()}');
      _deselectContainer();
      _setUIState(GameUIState.idle);
    }
  }
  
  /// Undo the last move
  Future<void> undoMove() async {
    if (_currentGameState == null || !canUndo || isAnimating) return;
    
    try {
      final newGameState = _gameEngine.undoLastMove(_currentGameState!);
      if (newGameState != null) {
        _currentGameState = newGameState;
        _deselectContainer();
        _setUIState(GameUIState.idle);
        _setFeedbackMessage('Move undone');
        
        // Play light haptic feedback for undo
        _audioManager.lightHaptic();
        
        // Clear feedback after a delay (non-blocking)
        Future.delayed(const Duration(seconds: 2), _clearFeedback);
      }
      
    } catch (e) {
      _handleError('Error undoing move: ${e.toString()}');
    }
  }
  
  /// Redo the next move
  Future<void> redoMove() async {
    if (_currentGameState == null || !canRedo || isAnimating) return;
    
    try {
      final newGameState = _gameEngine.redoNextMove(_currentGameState!);
      if (newGameState != null) {
        _currentGameState = newGameState;
        _deselectContainer();
        _setUIState(GameUIState.idle);
        _setFeedbackMessage('Move redone');
        
        // Play light haptic feedback for redo
        _audioManager.lightHaptic();
        
        // Check for victory after redo
        if (_gameEngine.checkWinCondition(newGameState)) {
          _setUIState(GameUIState.victory);
          _setFeedbackMessage('Congratulations! Level completed!');
          // Victory audio feedback will be handled by _handleVictory
          await _handleVictory(newGameState);
        }
        
        // Clear feedback after a delay (non-blocking)
        Future.delayed(const Duration(seconds: 2), () {
          if (_uiState != GameUIState.victory) {
            _clearFeedback();
          }
        });
      }
      
    } catch (e) {
      _handleError('Error redoing move: ${e.toString()}');
    }
  }
  
  /// Reset the current level to its initial state
  Future<void> resetLevel() async {
    if (_currentGameState == null || isAnimating) return;
    
    try {
      _setLoadingState(GameLoadingState.loading);
      
      // Reset to initial state
      _currentGameState = _currentGameState!.reset(_currentGameState!.initialContainers);
      _deselectContainer();
      _setUIState(GameUIState.idle);
      _clearError();
      _clearFeedback();
      
      _setLoadingState(GameLoadingState.idle);
      notifyListeners();
    } catch (e) {
      _handleError('Error resetting level: ${e.toString()}');
    }
  }
  
  /// Save the current game state
  Future<void> saveGameState() async {
    if (_currentGameState == null) return;
    
    try {
      _setLoadingState(GameLoadingState.saving);
      
      // Here you would integrate with your storage service
      // For now, we'll just simulate the save operation
      await Future.delayed(const Duration(milliseconds: 500));
      
      _setLoadingState(GameLoadingState.idle);
      _setFeedbackMessage('Game saved');
      
      // Clear feedback after a delay
      Future.delayed(const Duration(seconds: 2), _clearFeedback);
      
    } catch (e) {
      _handleError('Error saving game: ${e.toString()}');
    }
  }
  
  /// Load a saved game state
  Future<void> loadGameState() async {
    try {
      _setLoadingState(GameLoadingState.loading);
      _clearError();
      
      // Here you would integrate with your storage service
      // For now, we'll just simulate the load operation
      await Future.delayed(const Duration(milliseconds: 500));
      
      _setLoadingState(GameLoadingState.idle);
      _setFeedbackMessage('Game loaded');
      
      // Clear feedback after a delay
      Future.delayed(const Duration(seconds: 2), _clearFeedback);
      
    } catch (e) {
      _handleError('Error loading game: ${e.toString()}');
    }
  }
  
  /// Clear any error messages
  void clearError() {
    _clearError();
  }
  
  /// Clear any feedback messages
  void clearFeedback() {
    _clearFeedback();
  }
  
  /// Dismiss victory state and prepare for next level
  void dismissVictory() {
    if (_uiState == GameUIState.victory) {
      _setUIState(GameUIState.idle);
      _clearFeedback();
    }
  }
  
  /// Progress to the next level
  Future<void> progressToNextLevel() async {
    if (_currentGameState == null) return;
    
    final nextLevelId = _currentGameState!.levelId + 1;
    await initializeLevel(nextLevelId);
  }
  
  /// Restart the current level
  Future<void> restartCurrentLevel() async {
    if (_currentGameState == null) return;
    
    final currentLevelId = _currentGameState!.levelId;
    await initializeLevel(currentLevelId);
  }
  
  // Private helper methods
  
  void _selectContainer(int containerId) {
    if (_currentGameState?.getContainer(containerId)?.isEmpty ?? true) {
      _setFeedbackMessage('Cannot select empty container');
      _audioManager.playErrorSound();
      _audioManager.lightHaptic();
      Future.delayed(const Duration(seconds: 2), _clearFeedback);
      return;
    }
    
    _selectedContainerId = containerId;
    _setUIState(GameUIState.containerSelected);
    _audioManager.selectionHaptic();
    notifyListeners();
  }
  
  void _deselectContainer() {
    _selectedContainerId = null;
    if (_uiState == GameUIState.containerSelected) {
      _setUIState(GameUIState.idle);
    }
    notifyListeners();
  }
  
  void _setLoadingState(GameLoadingState state) {
    if (_loadingState != state) {
      _loadingState = state;
      notifyListeners();
    }
  }
  
  void _setUIState(GameUIState state) {
    if (_uiState != state) {
      _uiState = state;
      notifyListeners();
    }
  }
  
  /// Handle animation events from the animation queue
  void _handleAnimationEvent(AnimationEvent event) {
    switch (event) {
      case AnimationStarted(:final animation):
        // Animation started - could trigger UI updates if needed
        break;
      case AnimationCompleted(:final animation):
        // Animation completed - could trigger UI updates if needed
        break;
      case VictoryAnimationStarted(:final duration):
        // Victory animation started
        break;
      case VictoryAnimationCompleted(:final duration):
        // Victory animation completed
        break;
      default:
        // Handle other events if needed
        break;
    }
    // Notify listeners that animation state may have changed
    notifyListeners();
  }
  
  void _handleError(String message) {
    _errorMessage = message;
    _setLoadingState(GameLoadingState.error);
    _setUIState(GameUIState.error);
    notifyListeners();
  }
  
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      if (_loadingState == GameLoadingState.error) {
        _setLoadingState(GameLoadingState.idle);
      }
      if (_uiState == GameUIState.error) {
        _setUIState(GameUIState.idle);
      }
      notifyListeners();
    }
  }
  
  void _setFeedbackMessage(String message) {
    _feedbackMessage = message;
    notifyListeners();
  }
  
  void _clearFeedback() {
    if (_feedbackMessage != null) {
      _feedbackMessage = null;
      notifyListeners();
    }
  }
  
  /// Handle victory condition when level is completed
  Future<void> _handleVictory(GameState gameState) async {
    _setUIState(GameUIState.victory);
    
    // Play success sound and haptic feedback for victory
    _audioManager.playSuccessSound();
    _audioManager.heavyHaptic();
    
    // Calculate performance metrics
    final moveCount = gameState.effectiveMoveCount;
    final levelId = gameState.levelId;
    
    // Set victory message with performance info
    _setFeedbackMessage('Level $levelId completed in $moveCount moves!');
    
    // Mark the level as completed in the game state
    _currentGameState = gameState.copyWith(isCompleted: true);
    
    notifyListeners();
  }
  
  void _handlePourFailure(PourFailure failure) {
    String message;
    
    switch (failure) {
      case PourFailureContainerFull _:
        message = 'Container is full!';
        break;
      case PourFailureColorMismatch colorFailure:
        message = 'Cannot pour ${colorFailure.sourceColor.displayName} onto ${colorFailure.targetColor.displayName}';
        break;
      case PourFailureEmptySource _:
        message = 'Source container is empty!';
        break;
      case PourFailureSameContainer _:
        message = 'Cannot pour into the same container!';
        break;
      case PourFailureInvalidContainer _:
        message = 'Invalid container selected!';
        break;
      case PourFailureInsufficientCapacity _:
        message = 'Not enough space in target container!';
        break;
      default:
        message = 'Invalid move: ${failure.message}';
    }
    
    _setFeedbackMessage(message);
    
    // Clear feedback after a delay
    Future.delayed(const Duration(seconds: 2), _clearFeedback);
  }
  
  
  @override
  void dispose() {
    _animationEventSubscription?.cancel();
    _animationQueue.dispose();
    super.dispose();
  }
}