import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../models/container.dart' as models;
import '../models/pour_result.dart';
import '../services/game_engine.dart';
import '../animations/pour_animation_controller.dart';
import '../animations/pour_animation.dart';
import 'container_widget.dart';

/// Callback type for when a pour operation is attempted
typedef PourCallback = void Function(int fromContainerId, int toContainerId);

/// Callback type for when the game state changes
typedef GameStateCallback = void Function(GameState newState);

/// A widget that displays the game board with multiple containers
/// and handles user interactions for the water sort puzzle game
class GameBoardWidget extends StatefulWidget {
  /// The current game state
  final GameState gameState;
  
  /// The game engine for handling game logic
  final GameEngine gameEngine;
  
  /// Callback when a pour operation is attempted
  final PourCallback? onPourAttempted;
  
  /// Callback when the game state changes
  final GameStateCallback? onGameStateChanged;
  
  /// Whether the game board is interactive
  final bool isInteractive;
  
  /// Custom container size (optional, will use responsive sizing if null)
  final Size? containerSize;
  
  /// Spacing between containers
  final double containerSpacing;
  
  /// Whether to show container selection animations
  final bool showSelectionAnimations;
  
  /// Whether to show pour animations
  final bool showPourAnimations;
  
  const GameBoardWidget({
    super.key,
    required this.gameState,
    required this.gameEngine,
    this.onPourAttempted,
    this.onGameStateChanged,
    this.isInteractive = true,
    this.containerSize,
    this.containerSpacing = 12.0,
    this.showSelectionAnimations = true,
    this.showPourAnimations = true,
  });
  
  @override
  State<GameBoardWidget> createState() => _GameBoardWidgetState();
}

class _GameBoardWidgetState extends State<GameBoardWidget>
    with TickerProviderStateMixin {
  /// Currently selected container ID
  int? _selectedContainerId;
  
  /// Pour animation controller for liquid transfer effects
  late PourAnimationController _pourAnimationController;
  
  /// Current game state (local copy that can be updated)
  late GameState _currentGameState;
  
  @override
  void initState() {
    super.initState();
    _currentGameState = widget.gameState;
    
    // Initialize pour animation controller
    _pourAnimationController = PourAnimationController();
    _pourAnimationController.initialize(this);
    _pourAnimationController.addListener(_onPourAnimationUpdate);
  }
  
  @override
  void didUpdateWidget(GameBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update local game state if it changed
    if (widget.gameState != oldWidget.gameState) {
      setState(() {
        _currentGameState = widget.gameState;
        // Clear selection if the game state changed externally
        _selectedContainerId = null;
      });
    }
  }
  
  @override
  void dispose() {
    _pourAnimationController.removeListener(_onPourAnimationUpdate);
    _pourAnimationController.dispose();
    super.dispose();
  }
  
  void _onPourAnimationUpdate() {
    // Trigger rebuild when pour animation updates
    if (mounted) {
      setState(() {});
    }
  }
  
  /// Handle container tap for selection and pour operations
  void _handleContainerTap(int containerId) {
    if (!widget.isInteractive) return;
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    setState(() {
      if (_selectedContainerId == null) {
        // First tap - select the container
        _selectedContainerId = containerId;
      } else if (_selectedContainerId == containerId) {
        // Tapping the same container - deselect
        _selectedContainerId = null;
      } else {
        // Second tap on different container - attempt pour
        _attemptPour(_selectedContainerId!, containerId);
        _selectedContainerId = null;
      }
    });
  }
  
  /// Attempt to pour liquid from source to target container
  void _attemptPour(int fromContainerId, int toContainerId) {
    // Validate the pour using the game engine
    final pourResult = widget.gameEngine.validatePour(
      _currentGameState,
      fromContainerId,
      toContainerId,
    );
    
    if (pourResult.isSuccess) {
      // Execute the pour and update game state
      final newGameState = widget.gameEngine.executePour(
        _currentGameState,
        fromContainerId,
        toContainerId,
      );
      
      // Start pour animation if enabled
      if (widget.showPourAnimations) {
        final pourSuccess = pourResult as PourSuccess;
        final animation = PourAnimation(
          fromContainer: fromContainerId,
          toContainer: toContainerId,
          liquidColor: pourSuccess.move.liquidMoved.color,
          volume: pourSuccess.move.liquidMoved.volume,
        );
        _pourAnimationController.startPourAnimation(animation);
      }
      
      // Update local state
      setState(() {
        _currentGameState = newGameState;
      });
      
      // Notify parent of state change
      widget.onGameStateChanged?.call(newGameState);
      
      // Provide success haptic feedback
      HapticFeedback.mediumImpact();
    } else {
      // Pour failed - provide error haptic feedback
      HapticFeedback.heavyImpact();
      
      // Show error feedback (could be enhanced with snackbar or animation)
      _showPourError(pourResult);
    }
    
    // Notify parent of pour attempt
    widget.onPourAttempted?.call(fromContainerId, toContainerId);
  }
  
  /// Show visual feedback for pour errors
  void _showPourError(PourResult pourResult) {
    // For now, just print the error. In a full implementation,
    // this could show a snackbar, play an error animation, etc.
    debugPrint('Pour failed: ${pourResult.toString()}');
    
    // Could add visual error feedback here, such as:
    // - Red flash animation on containers
    // - Error message overlay
    // - Shake animation
  }
  
  /// Calculate responsive grid layout based on screen size and container count
  _GridLayout _calculateGridLayout(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final containerCount = _currentGameState.containers.length;
    
    // Calculate optimal grid dimensions
    int columns;
    int rows;
    
    if (containerCount <= 4) {
      // Small puzzles: prefer horizontal layout on larger screens
      if (screenSize.width > screenSize.height) {
        columns = containerCount;
        rows = 1;
      } else {
        columns = 2;
        rows = (containerCount / 2).ceil();
      }
    } else if (containerCount <= 6) {
      // Medium puzzles
      if (screenSize.width > screenSize.height) {
        columns = 3;
        rows = 2;
      } else {
        columns = 2;
        rows = 3;
      }
    } else if (containerCount <= 9) {
      // Larger puzzles
      columns = 3;
      rows = (containerCount / 3).ceil();
    } else {
      // Very large puzzles
      if (screenSize.width > screenSize.height) {
        columns = 5;
        rows = (containerCount / 5).ceil();
      } else {
        columns = 4;
        rows = (containerCount / 4).ceil();
      }
    }
    
    return _GridLayout(columns: columns, rows: rows);
  }
  
  /// Calculate responsive container size based on screen dimensions and grid layout
  Size _calculateContainerSize(BuildContext context, _GridLayout gridLayout) {
    if (widget.containerSize != null) {
      return widget.containerSize!;
    }
    
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    
    // Available space for containers (accounting for padding and spacing)
    final availableWidth = screenSize.width - padding.horizontal - 32; // 16px margin on each side
    final availableHeight = screenSize.height - padding.vertical - 200; // Space for UI elements
    
    // Calculate container dimensions based on grid layout
    final containerWidth = (availableWidth - (widget.containerSpacing * (gridLayout.columns - 1))) / gridLayout.columns;
    final containerHeight = (availableHeight - (widget.containerSpacing * (gridLayout.rows - 1))) / gridLayout.rows;
    
    // Maintain aspect ratio (containers should be taller than wide)
    final aspectRatio = 1.5; // height = 1.5 * width
    
    double finalWidth, finalHeight;
    
    if (containerHeight / containerWidth > aspectRatio) {
      // Height constraint is not limiting
      finalWidth = containerWidth;
      finalHeight = containerWidth * aspectRatio;
    } else {
      // Height constraint is limiting
      finalHeight = containerHeight;
      finalWidth = containerHeight / aspectRatio;
    }
    
    // Apply size constraints
    finalWidth = finalWidth.clamp(60.0, 120.0);
    finalHeight = finalHeight.clamp(90.0, 180.0);
    
    return Size(finalWidth, finalHeight);
  }
  
  @override
  Widget build(BuildContext context) {
    final gridLayout = _calculateGridLayout(context);
    final containerSize = _calculateContainerSize(context, gridLayout);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: _buildContainerGrid(gridLayout, containerSize),
      ),
    );
  }
  
  /// Build the grid of containers
  Widget _buildContainerGrid(_GridLayout gridLayout, Size containerSize) {
    final containers = _currentGameState.containers;
    
    return Wrap(
      spacing: widget.containerSpacing,
      runSpacing: widget.containerSpacing,
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      children: containers.map((container) {
        return _buildContainerWithWrapper(container, containerSize);
      }).toList(),
    );
  }
  
  /// Build a single container with its wrapper for layout and interaction
  Widget _buildContainerWithWrapper(models.Container container, Size containerSize) {
    final isSelected = _selectedContainerId == container.id;
    
    return SizedBox(
      width: containerSize.width,
      height: containerSize.height,
      child: ContainerWidget(
        container: container,
        isSelected: isSelected,
        onTap: widget.isInteractive ? () => _handleContainerTap(container.id) : null,
        size: containerSize,
        showSelectionAnimation: widget.showSelectionAnimations,
        pourAnimationController: widget.showPourAnimations ? _pourAnimationController : null,
      ),
    );
  }
}

/// Helper class to represent grid layout dimensions
class _GridLayout {
  final int columns;
  final int rows;
  
  const _GridLayout({
    required this.columns,
    required this.rows,
  });
  
  @override
  String toString() => 'GridLayout(columns: $columns, rows: $rows)';
}