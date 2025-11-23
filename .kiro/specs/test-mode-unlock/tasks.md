# Implementation Plan

- [x] 1. Create TestModeManager core class

  - Implement TestModeManager class with SharedPreferences integration
  - Add isTestModeEnabled getter and setTestMode method
  - Create testModeStream for reactive UI updates
  - Implement isLevelAccessible method with test mode logic
  - Add getTestModeIndicator method for UI display
  - Write comprehensive unit tests for all TestModeManager functionality
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.5_

- [x] 2. Implement TestModeIndicator data model and widget

  - Create TestModeIndicator data class with text, color, and icon properties
  - Implement TestModeIndicatorWidget as StatelessWidget
  - Add proper styling with border, background color, and icon display
  - Create responsive design that works across different screen sizes
  - Write widget tests for TestModeIndicatorWidget rendering and styling
  - _Requirements: 3.1, 3.2, 3.4_

- [x] 3. Build ProgressOverride system

  - Create ProgressOverride class that wraps existing GameProgress
  - Implement getEffectiveUnlockedLevels method with test mode logic
  - Add isLevelUnlocked method that considers test mode state
  - Implement shouldRecordCompletion method to preserve actual progress
  - Create completeLevel method that only records legitimate completions
  - Write unit tests for ProgressOverride with various test mode scenarios
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 4. Create TestModeToggle widget component

  - Implement TestModeToggle as StatefulWidget with proper state management
  - Add Switch widget with onChanged callback to toggle test mode
  - Create visual styling that indicates test mode status (colors, icons)
  - Add descriptive text explaining test mode functionality
  - Implement proper error handling for test mode persistence failures
  - Write widget tests for TestModeToggle interaction and state updates
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 6.3, 6.4_

- [x] 5. Enhance LevelSelectionScreen with test mode integration

  - Modify existing LevelSelectionScreen to accept TestModeManager parameter
  - Add StreamBuilder to reactively display test mode indicator
  - Integrate TestModeIndicatorWidget in screen header when test mode active
  - Add settings/debug menu access with IconButton in AppBar
  - Create settings dialog containing TestModeToggle widget
  - Write widget tests for enhanced level selection screen with test mode
  - _Requirements: 3.1, 3.2, 3.3, 6.1, 6.2, 6.5_

- [x] 6. Implement LevelGrid component with test mode support

  - Create LevelGrid widget that uses ProgressOverride for level accessibility
  - Implement dynamic level count based on test mode state (100 levels in test mode)
  - Add LevelTile widget with visual indicators for test mode unlocked levels
  - Create distinctive styling for test mode unlocked levels (orange border, bug icon)
  - Implement proper navigation to GameScreen with test mode context
  - Write widget tests for LevelGrid rendering and test mode visual indicators
  - _Requirements: 1.1, 1.4, 3.1, 3.4, 5.1, 5.2, 5.3_

- [x] 7. Create LevelTile widget with test mode visual indicators

  - Implement LevelTile widget with support for test mode unlock status
  - Add visual styling methods for different tile states (unlocked, completed, test mode)
  - Create bug report icon overlay for test mode unlocked levels
  - Implement proper color coding (orange for test mode, green for completed, blue for normal)
  - Add proper accessibility support for different tile states
  - Write widget tests for LevelTile visual states and styling
  - _Requirements: 3.1, 3.4_

- [x] 8. Integrate test mode with existing GameScreen

  - Modify GameScreen constructor to accept TestModeManager parameter
  - Add test mode indicator display in game screen header when active
  - Ensure game mechanics remain unchanged in test mode
  - Implement proper level completion handling that respects actual progress
  - Add test mode context to level generation for unrestricted difficulty access
  - Write integration tests for GameScreen with test mode enabled
  - _Requirements: 1.3, 3.3, 4.4, 5.4_

- [x] 9. Update LevelGenerator with test mode support

  - Add ignoreProgressionLimits parameter to level generation methods
  - Implement generateLevelForTesting method in TestModeManager
  - Ensure level generation works for any difficulty level in test mode
  - Maintain same quality and solvability standards regardless of test mode
  - Add proper error handling for test mode level generation failures
  - Write unit tests for level generation with test mode parameters
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 10. Implement error handling and recovery for test mode

  - Create TestModeException class with different error types
  - Implement TestModeErrorHandler with recovery strategies
  - Add fallback mechanisms for persistence failures (in-memory state)
  - Create error handling for level generation failures in test mode
  - Implement progress corruption protection to preserve actual game data
  - Write unit tests for error handling scenarios and recovery mechanisms
  - _Requirements: 4.5_

- [ ] 11. Add comprehensive unit tests for test mode system

  - Write unit tests for TestModeManager state management and persistence
  - Create tests for ProgressOverride with various unlock scenarios
  - Add tests for test mode level accessibility logic
  - Implement tests for legitimate vs illegitimate completion tracking
  - Create edge case tests for test mode toggle scenarios
  - Write performance tests to ensure minimal overhead
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 12. Create widget tests for test mode UI components

  - Write widget tests for TestModeToggle interaction and visual feedback
  - Create tests for TestModeIndicatorWidget rendering and styling
  - Add tests for enhanced LevelSelectionScreen with test mode integration
  - Implement tests for LevelGrid and LevelTile test mode visual indicators
  - Create tests for settings dialog and test mode toggle accessibility
  - Write tests for proper test mode indicator display and hiding
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4_

- [ ] 13. Implement integration tests for complete test mode workflow

  - Create end-to-end test for enabling test mode and accessing high levels
  - Write test for completing levels in test mode without affecting actual progress
  - Add test for disabling test mode and verifying normal progression restoration
  - Implement test for test mode persistence across app sessions
  - Create test for test mode visual indicators throughout the app
  - Write test for settings dialog access and test mode toggle functionality
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.2, 5.3, 5.4, 5.5, 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 14. Update dependency injection and app initialization

  - Modify main app initialization to create TestModeManager instance
  - Update dependency injection to provide TestModeManager to required widgets
  - Integrate ProgressOverride creation with existing GameProgress system
  - Ensure proper initialization order for test mode system
  - Add proper disposal of TestModeManager resources
  - Write tests for dependency injection and app initialization with test mode
  - _Requirements: 2.5_

- [ ] 15. Add documentation and help text for test mode

  - Create comprehensive help text explaining test mode purpose and behavior
  - Add tooltips and descriptions for test mode UI elements
  - Implement clear warnings about test mode not affecting actual progress
  - Create developer documentation for test mode usage and integration
  - Add inline comments explaining test mode logic and design decisions
  - Write user-facing documentation for accessing and using test mode
  - _Requirements: 6.3_
