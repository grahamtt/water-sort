import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'pour_animation.dart';
import 'animation_queue.dart';

/// Controller for managing pour animations with realistic liquid physics
/// Integrates with AnimationQueue for non-blocking animation system
class PourAnimationController extends ChangeNotifier {
  AnimationController? _animationController;
  final AnimationQueue _animationQueue = AnimationQueue();
  PourAnimationProgress _progress = PourAnimationProgress.start();
  StreamSubscription<AnimationEvent>? _animationEventSubscription;
  
  // Animation curves for different phases
  late Animation<double> _pourCurve;
  late Animation<double> _streamCurve;
  late Animation<double> _splashCurve;
  
  /// Access to the animation queue
  AnimationQueue get animationQueue => _animationQueue;
  
  /// Current animation state
  AnimationState get state => _animationQueue.state;
  
  /// Current animation progress
  PourAnimationProgress get progress => _progress;
  
  /// Whether an animation is currently playing
  bool get isAnimating => _animationQueue.isAnimating;
  
  /// Current animation data (null if not animating)
  PourAnimation? get currentAnimation => _animationQueue.currentAnimation;
  
  /// Initialize the controller with a TickerProvider
  void initialize(TickerProvider tickerProvider) {
    _animationController?.dispose();
    _animationEventSubscription?.cancel();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: tickerProvider,
    );
    
    _setupAnimationCurves();
    _animationController!.addListener(_onAnimationUpdate);
    _animationController!.addStatusListener(_onAnimationStatusChange);
    
    // Listen to animation queue events
    _animationEventSubscription = _animationQueue.animationEvents.listen(_handleAnimationEvent);
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
  
  /// Add a pour animation to the queue
  void addPourAnimation(PourAnimation animation) {
    _animationQueue.addAnimation(animation);
  }
  
  /// Add multiple pour animations to the queue
  void addPourAnimations(List<PourAnimation> animations) {
    _animationQueue.addAnimations(animations);
  }
  
  /// Skip the current animation
  void skipCurrentAnimation() {
    _animationQueue.skipCurrentAnimation();
  }
  
  /// Skip all animations
  void skipAllAnimations() {
    _animationQueue.skipAllAnimations();
  }
  
  /// Start victory celebration animation
  void startVictoryAnimation({Duration duration = const Duration(milliseconds: 2000)}) {
    _animationQueue.startVictoryAnimation(duration: duration);
  }
  
  /// Complete victory animation
  void completeVictoryAnimation() {
    _animationQueue.completeVictoryAnimation();
  }
  
  /// Handle animation queue events
  void _handleAnimationEvent(AnimationEvent event) {
    switch (event) {
      case AnimationStarted(:final animation):
        _startFlutterAnimation(animation);
        break;
      case AnimationCompleted(:final animation):
        _completeFlutterAnimation();
        break;
      case AnimationSkipped(:final animation):
        _skipFlutterAnimation();
        break;
      case VictoryAnimationStarted(:final duration):
        _startVictoryFlutterAnimation(duration);
        break;
      case VictoryAnimationCompleted(:final duration):
        _completeVictoryFlutterAnimation();
        break;
      case ForcedIdle():
        _forceIdleFlutterAnimation();
        break;
      default:
        // Handle other events if needed
        break;
    }
  }
  
  /// Start the Flutter animation for a pour
  void _startFlutterAnimation(PourAnimation animation) {
    if (_animationController != null) {
      _animationController!.duration = animation.duration;
      _setupAnimationCurves();
      _animationController!.forward(from: 0.0);
    }
  }
  
  /// Complete the current Flutter animation
  void _completeFlutterAnimation() {
    if (_animationController != null) {
      _animationController!.reset();
    }
    _progress = PourAnimationProgress.start();
    notifyListeners();
  }
  
  /// Skip the current Flutter animation
  void _skipFlutterAnimation() {
    if (_animationController != null && _animationController!.isAnimating) {
      _animationController!.stop();
      _animationController!.reset();
    }
    _progress = PourAnimationProgress.start();
    notifyListeners();
  }
  
  /// Start victory Flutter animation
  void _startVictoryFlutterAnimation(Duration duration) {
    if (_animationController != null) {
      _animationController!.duration = duration;
      _animationController!.forward(from: 0.0);
    }
  }
  
  /// Complete victory Flutter animation
  void _completeVictoryFlutterAnimation() {
    if (_animationController != null) {
      _animationController!.reset();
    }
    _progress = PourAnimationProgress.start();
    notifyListeners();
  }
  
  /// Force idle state for Flutter animation
  void _forceIdleFlutterAnimation() {
    if (_animationController != null) {
      _animationController!.stop();
      _animationController!.reset();
    }
    _progress = PourAnimationProgress.start();
    notifyListeners();
  }
  
  void _onAnimationUpdate() {
    if (_animationController == null || currentAnimation == null) return;
    
    final progress = _animationController!.value;
    final pourProgress = _pourCurve.value;
    final streamProgress = _streamCurve.value;
    final splashProgress = _splashCurve.value;
    
    // Calculate stream position using parabolic trajectory
    final streamPosition = _calculateStreamPosition(streamProgress);
    
    // Calculate stream width based on liquid physics
    final streamWidth = _calculateStreamWidth(streamProgress);
    
    // Determine splash effects
    final showSplash = progress > 0.6 && currentAnimation!.showSplash;
    final splashIntensity = showSplash ? splashProgress : 0.0;
    
    _progress = PourAnimationProgress(
      progress: progress,
      streamPosition: streamPosition,
      streamWidth: streamWidth,
      showSplash: showSplash,
      splashIntensity: splashIntensity,
    );
    
    // Update animation queue with progress
    _animationQueue.updateAnimationProgress(progress);
    
    notifyListeners();
  }
  
  void _onAnimationStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Notify the animation queue that the current animation is complete
      _animationQueue.completeCurrentAnimation();
    }
  }
  
  /// Calculate the position of the liquid stream using realistic physics
  Offset _calculateStreamPosition(double progress) {
    if (currentAnimation == null) return Offset.zero;
    
    // Simulate parabolic trajectory for liquid stream
    // This creates a realistic arc from source to target
    
    // Assume containers are positioned horizontally
    final horizontalDistance = (currentAnimation!.toContainer - 
        currentAnimation!.fromContainer).abs() * 100.0;
    
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
    if (currentAnimation == null) return 0.0;
    
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
    if (currentAnimation == null || 
        currentAnimation!.fromContainer >= containerPositions.length) {
      return Offset.zero;
    }
    
    final containerPos = containerPositions[currentAnimation!.fromContainer];
    
    // Return position at top center of source container
    return Offset(
      containerPos.dx + containerSize.width / 2,
      containerPos.dy,
    );
  }
  
  /// Get the target position for pour animation
  Offset getTargetPosition(List<Offset> containerPositions, Size containerSize) {
    if (currentAnimation == null || 
        currentAnimation!.toContainer >= containerPositions.length) {
      return Offset.zero;
    }
    
    final containerPos = containerPositions[currentAnimation!.toContainer];
    
    // Return position at top center of target container
    return Offset(
      containerPos.dx + containerSize.width / 2,
      containerPos.dy,
    );
  }
  
  @override
  void dispose() {
    _animationController?.dispose();
    _animationEventSubscription?.cancel();
    _animationQueue.dispose();
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