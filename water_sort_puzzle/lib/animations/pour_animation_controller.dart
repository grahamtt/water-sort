import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'pour_animation.dart';

/// Controller for managing pour animations with realistic liquid physics
class PourAnimationController extends ChangeNotifier {
  AnimationController? _animationController;
  PourAnimation? _currentAnimation;
  AnimationState _state = const IdleState();
  PourAnimationProgress _progress = PourAnimationProgress.start();
  
  // Animation curves for different phases
  late Animation<double> _pourCurve;
  late Animation<double> _streamCurve;
  late Animation<double> _splashCurve;
  
  /// Current animation state
  AnimationState get state => _state;
  
  /// Current animation progress
  PourAnimationProgress get progress => _progress;
  
  /// Whether an animation is currently playing
  bool get isAnimating => _state is PouringState;
  
  /// Current animation data (null if not animating)
  PourAnimation? get currentAnimation => _currentAnimation;
  
  /// Initialize the controller with a TickerProvider
  void initialize(TickerProvider tickerProvider) {
    _animationController?.dispose();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: tickerProvider,
    );
    
    _setupAnimationCurves();
    _animationController!.addListener(_onAnimationUpdate);
    _animationController!.addStatusListener(_onAnimationStatusChange);
  }
  
  void _setupAnimationCurves() {
    if (_animationController == null) return;
    
    // Main pour curve with realistic liquid physics
    _pourCurve = CurvedAnimation(
      parent: _animationController!,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    );
    
    // Stream curve for liquid stream width and position
    _streamCurve = CurvedAnimation(
      parent: _animationController!,
      curve: const Interval(0.1, 0.9, curve: Curves.easeInOutQuart),
    );
    
    // Splash curve for impact effects
    _splashCurve = CurvedAnimation(
      parent: _animationController!,
      curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
    );
  }
  
  /// Start a pour animation
  Future<void> startPourAnimation(PourAnimation animation) async {
    if (isAnimating) {
      await stopAnimation();
    }
    
    _currentAnimation = animation;
    _state = PouringState(animation);
    
    if (_animationController != null) {
      _animationController!.duration = animation.duration;
      _setupAnimationCurves();
      await _animationController!.forward(from: 0.0);
    }
    
    notifyListeners();
  }
  
  /// Stop the current animation
  Future<void> stopAnimation() async {
    if (_animationController != null && _animationController!.isAnimating) {
      _animationController!.stop();
    }
    
    _currentAnimation = null;
    _state = const IdleState();
    _progress = PourAnimationProgress.start();
    notifyListeners();
  }
  
  /// Start victory celebration animation
  Future<void> startVictoryAnimation({
    Duration duration = const Duration(milliseconds: 2000),
  }) async {
    if (isAnimating) {
      await stopAnimation();
    }
    
    _state = VictoryState(duration);
    
    if (_animationController != null) {
      _animationController!.duration = duration;
      await _animationController!.forward(from: 0.0);
    }
    
    notifyListeners();
  }
  
  void _onAnimationUpdate() {
    if (_animationController == null || _currentAnimation == null) return;
    
    final progress = _animationController!.value;
    final pourProgress = _pourCurve.value;
    final streamProgress = _streamCurve.value;
    final splashProgress = _splashCurve.value;
    
    // Calculate stream position using parabolic trajectory
    final streamPosition = _calculateStreamPosition(streamProgress);
    
    // Calculate stream width based on liquid physics
    final streamWidth = _calculateStreamWidth(streamProgress);
    
    // Determine splash effects
    final showSplash = progress > 0.6 && _currentAnimation!.showSplash;
    final splashIntensity = showSplash ? splashProgress : 0.0;
    
    _progress = PourAnimationProgress(
      progress: progress,
      streamPosition: streamPosition,
      streamWidth: streamWidth,
      showSplash: showSplash,
      splashIntensity: splashIntensity,
    );
    
    notifyListeners();
  }
  
  void _onAnimationStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _currentAnimation = null;
      _state = const IdleState();
      _progress = PourAnimationProgress.start();
      notifyListeners();
    }
  }
  
  /// Calculate the position of the liquid stream using realistic physics
  Offset _calculateStreamPosition(double progress) {
    if (_currentAnimation == null) return Offset.zero;
    
    // Simulate parabolic trajectory for liquid stream
    // This creates a realistic arc from source to target
    
    // Assume containers are positioned horizontally
    final horizontalDistance = (_currentAnimation!.toContainer - 
        _currentAnimation!.fromContainer).abs() * 100.0;
    
    // Calculate horizontal position
    final x = progress * horizontalDistance;
    
    // Calculate vertical position using parabolic curve
    // y = ax² + bx + c where the liquid follows gravity
    final gravity = 0.5; // Gravity effect factor
    final initialVelocity = 0.8; // Initial upward velocity
    
    final y = gravity * progress * progress - initialVelocity * progress;
    
    return Offset(x, y * 50); // Scale for visual effect
  }
  
  /// Calculate the width of the liquid stream based on physics
  double _calculateStreamWidth(double progress) {
    if (_currentAnimation == null) return 0.0;
    
    // Stream starts narrow, widens in middle, then narrows again
    // This simulates realistic liquid flow
    
    const maxWidth = 8.0;
    const minWidth = 2.0;
    
    // Use sine wave for natural width variation
    final widthFactor = math.sin(progress * math.pi);
    
    return minWidth + (maxWidth - minWidth) * widthFactor;
  }
  
  /// Calculate container positions for animation
  List<Offset> calculateContainerPositions(
    List<Size> containerSizes,
    Size boardSize,
  ) {
    final positions = <Offset>[];
    
    if (containerSizes.isEmpty) return positions;
    
    // Calculate grid layout
    final containerCount = containerSizes.length;
    final columns = math.sqrt(containerCount).ceil();
    final rows = (containerCount / columns).ceil();
    
    final containerSpacing = 16.0;
    final totalWidth = columns * containerSizes.first.width + 
        (columns - 1) * containerSpacing;
    final totalHeight = rows * containerSizes.first.height + 
        (rows - 1) * containerSpacing;
    
    final startX = (boardSize.width - totalWidth) / 2;
    final startY = (boardSize.height - totalHeight) / 2;
    
    for (int i = 0; i < containerCount; i++) {
      final row = i ~/ columns;
      final col = i % columns;
      
      final x = startX + col * (containerSizes[i].width + containerSpacing);
      final y = startY + row * (containerSizes[i].height + containerSpacing);
      
      positions.add(Offset(x, y));
    }
    
    return positions;
  }
  
  /// Get the source position for pour animation
  Offset getSourcePosition(List<Offset> containerPositions, Size containerSize) {
    if (_currentAnimation == null || 
        _currentAnimation!.fromContainer >= containerPositions.length) {
      return Offset.zero;
    }
    
    final containerPos = containerPositions[_currentAnimation!.fromContainer];
    
    // Return position at top center of source container
    return Offset(
      containerPos.dx + containerSize.width / 2,
      containerPos.dy,
    );
  }
  
  /// Get the target position for pour animation
  Offset getTargetPosition(List<Offset> containerPositions, Size containerSize) {
    if (_currentAnimation == null || 
        _currentAnimation!.toContainer >= containerPositions.length) {
      return Offset.zero;
    }
    
    final containerPos = containerPositions[_currentAnimation!.toContainer];
    
    // Return position at top center of target container
    return Offset(
      containerPos.dx + containerSize.width / 2,
      containerPos.dy,
    );
  }
  
  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }
}

/// Extension to add animation capabilities to existing widgets
extension AnimationControllerExtension on PourAnimationController {
  /// Create a curved animation for custom effects
  Animation<double> createCurvedAnimation({
    required double begin,
    required double end,
    required Curve curve,
  }) {
    if (_animationController == null) {
      throw StateError('Animation controller not initialized');
    }
    
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _animationController!, curve: curve),
    );
  }
  
  /// Create a color animation for liquid effects
  Animation<Color?> createColorAnimation({
    required Color begin,
    required Color end,
    required Curve curve,
  }) {
    if (_animationController == null) {
      throw StateError('Animation controller not initialized');
    }
    
    return ColorTween(begin: begin, end: end).animate(
      CurvedAnimation(parent: _animationController!, curve: curve),
    );
  }
}