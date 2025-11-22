# Implementation Plan

- [x] 1. Set up Flutter project structure and dependencies

  - Create new Flutter project with proper directory structure
  - Add required dependencies (hive, shared_preferences, audioplayers, json_annotation)
  - Configure build.gradle and pubspec.yaml for cross-platform deployment
  - _Requirements: 7.1, 7.2, 7.5_

- [x] 2. Implement core data models and enums

  - Create LiquidColor enum with color values and Flutter Color integration
  - Implement LiquidLayer class with JSON serialization
  - Create Container class with liquid management methods
  - Write unit tests for all data model operations
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 3. Create game state management system

  - Implement GameState class with move history tracking
  - Create Move class for undo/redo functionality
  - Implement PourResult classes for move validation feedback
  - Write unit tests for state transitions and validation
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 4. Build core game engine with move validation

  - Create GameEngine abstract class and concrete implementation
  - Implement pour validation logic (color matching, container capacity)
  - Add move execution with proper state updates
  - Create win condition detection algorithm
  - Write comprehensive unit tests for all game rules
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 5. Implement undo/redo functionality

  - Add move history management to GameEngine
  - Implement undo operation with state restoration
  - Create redo capability for undone moves
  - Add validation to prevent invalid undo operations
  - Write unit tests for undo/redo edge cases
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 6. Create level management system

  - Implement Level class with difficulty parameters and signature field
  - Create LevelGenerator for procedural level creation
  - Add level validation to ensure solvability
  - Implement level progression and unlocking logic
  - Write unit tests for level generation and validation
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 6.1 Implement level similarity detection system

  - Create LevelSimilarityChecker class with pattern normalization
  - Implement color-agnostic signature generation for levels
  - Add structural pattern comparison algorithm with container order independence
  - Create similarity threshold validation (80% threshold)
  - Implement pattern sorting to make container order irrelevant for comparison
  - Write comprehensive unit tests for similarity detection edge cases
  - _Requirements: 9.6, 9.7, 9.8_

- [x] 6.2 Build level generation service with uniqueness tracking

  - Implement LevelGenerationService to manage session-level uniqueness
  - Add session history tracking for generated levels
  - Create retry logic for generating unique levels (max 50 attempts)
  - Implement fallback mechanism when similarity threshold cannot be met
  - Write integration tests for unique level generation workflow
  - _Requirements: 9.6, 9.7, 9.8_

- [ ] 6.3 Implement completed container validation for level generation

  - Create LevelValidator class with validateGeneratedLevel method
  - Implement \_hasCompletedContainers method to detect full single-color containers
  - Add \_isContainerCompleted method to check if container is both full and single-color
  - Integrate completed container validation into level generation workflow
  - Add hasCompletedContainers method to LevelGenerator abstract interface
  - Write comprehensive unit tests for completed container detection edge cases
  - _Requirements: 9.9, 9.10_

- [x] 7. Build persistence layer with Hive and SharedPreferences

  - Set up Hive database for complex game state storage
  - Implement GameProgress and PlayerStats persistence
  - Create SharedPreferences integration for simple settings
  - Add JSON serialization for all persistent data models
  - Write unit tests for save/load operations
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 8. Create custom container widget with painting

  - Implement ContainerWidget as StatefulWidget
  - Create ContainerPainter for custom liquid layer rendering
  - Add touch detection and selection visual feedback
  - Implement responsive sizing based on screen dimensions
  - Write widget tests for rendering and interaction
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1_

- [x] 9. Implement pour animations with AnimationController

  - Create PourAnimation class for animation data
  - Implement AnimationController for liquid transfer effects
  - Add curved animations for realistic liquid physics
  - Create selection highlight animations
  - Write widget tests for animation behavior
  - _Requirements: 2.3, 2.6_

- [x] 9.1 Implement non-blocking UI animation system

  - Create AnimationQueue class for managing multiple concurrent animations
  - Implement animation interruption and skipping functionality
  - Add StreamController for decoupling game logic from UI animations
  - Ensure game state updates immediately while animations play separately
  - Create animation state management (IdleState, PouringState, VictoryState)
  - Write unit tests for animation queue and interruption behavior
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 10. Build game board widget and layout

  - Create GameBoardWidget to display multiple containers
  - Implement responsive grid layout for different screen sizes
  - Add container selection state management
  - Integrate touch handling for pour operations
  - Write widget tests for layout and interaction
  - _Requirements: 1.5, 2.1, 2.2_

- [x] 11. Create game state provider with Riverpod/Provider

  - Set up state management provider for GameEngine
  - Implement reactive UI updates for game state changes
  - Add error handling and user feedback for invalid moves
  - Create loading states for async operations
  - Write integration tests for state management
  - _Requirements: 2.4, 2.5, 3.5_

- [x] 12. Implement victory detection and celebration

  - Add win condition checking to game loop
  - Create victory animation and visual feedback
  - Implement level completion handling
  - Add progression to next level functionality
  - Write unit tests for victory conditions
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 13. Build level selection screen

  - Create LevelSelectionWidget with grid layout
  - Implement level unlock status visualization
  - Add level completion indicators
  - Create navigation to selected level
  - Write widget tests for level selection UI
  - _Requirements: 5.1, 5.4, 5.5_

- [x] 14. Add audio feedback system

  - Integrate audioplayers package for sound effects
  - Create sound effect assets for pour, success, and error actions
  - Implement audio manager with volume controls
  - Add haptic feedback for touch interactions
  - Write tests for audio system integration
  - _Requirements: 4.5, 2.6_

- [x] 15. Create main game screen with UI controls

  - Build main game screen layout with game board
  - Add undo button with proper state management
  - Implement level info display (moves, level number)
  - Create pause/menu functionality
  - Write widget tests for main game screen
  - _Requirements: 6.4, 6.5_

- [x] 16. Implement error handling and user feedback

  - Add SnackBar notifications for invalid moves
  - Create error recovery for corrupted save data
  - Implement graceful degradation for missing features
  - Add user-friendly error messages
  - Write tests for error handling scenarios
  - _Requirements: 3.5, 2.4, 2.5_

- [ ] 17. Implement loss detection system

  - Create MoveValidator class with getAllValidMoves method
  - Implement move validation logic for all container combinations
  - Add LossDetector class with hasLost and getLossMessage methods
  - Integrate loss detection into GameEngine with checkLossCondition method
  - Write comprehensive unit tests for loss detection edge cases
  - _Requirements: 11.1, 11.4, 11.5_

- [ ] 17.1 Add loss state management and UI components

  - Update GameState model to include isLost boolean field
  - Create LossDialog widget for simple loss notification
  - Implement GameOverOverlay widget with animated presentation
  - Add loss state to animation system (LossState class)
  - Write widget tests for loss UI components
  - _Requirements: 11.2, 11.3, 11.6_

- [ ] 17.2 Integrate loss detection into game flow

  - Add loss condition checking to game state provider
  - Implement loss detection triggers after each move
  - Create restart and level selection handlers for loss state
  - Add loss prevention during animations and transitions
  - Write integration tests for complete loss detection workflow
  - _Requirements: 11.1, 11.2, 11.3, 11.6_

- [ ] 18. Add app lifecycle and state persistence

  - Implement automatic save on app pause/background
  - Create state restoration on app resume
  - Add crash recovery with last known good state
  - Implement progress backup and restore
  - Write integration tests for app lifecycle
  - _Requirements: 8.1, 8.2, 8.3, 8.5_

- [ ] 19. Create app navigation and routing

  - Set up Flutter navigation between screens
  - Implement proper back button handling
  - Add deep linking for level selection
  - Create smooth transitions between screens
  - Write navigation tests
  - _Requirements: 5.1, 4.3_

- [ ] 20. Optimize performance and animations

  - Profile widget rebuilding and optimize unnecessary renders
  - Implement efficient CustomPainter caching
  - Add frame rate monitoring for 60fps target
  - Optimize memory usage for extended gameplay
  - Write performance tests and benchmarks
  - _Requirements: 7.3, 7.4_

- [ ] 21. Add final polish and integration testing
  - Implement app icon and splash screen
  - Add final UI polish and consistent theming
  - Create comprehensive integration tests
  - Test cross-platform compatibility (iOS/Android)
  - Verify all requirements are met through end-to-end testing
  - _Requirements: 7.1, 7.2, 7.5_
