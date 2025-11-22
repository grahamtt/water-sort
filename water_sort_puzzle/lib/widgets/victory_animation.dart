import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget that displays a celebration animation when the player wins
class VictoryAnimation extends StatefulWidget {
  /// Whether the animation should be visible
  final bool isVisible;
  
  /// Callback when the animation completes
  final VoidCallback? onAnimationComplete;
  
  /// Duration of the celebration animation
  final Duration duration;
  
  const VictoryAnimation({
    super.key,
    required this.isVisible,
    this.onAnimationComplete,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<VictoryAnimation> createState() => _VictoryAnimationState();
}

class _VictoryAnimationState extends State<VictoryAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _textController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _textBounceAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Main animation controller for overall timing
    _mainController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    // Particle animation controller for continuous particle effects
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Text animation controller for bouncing text
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Scale animation for the main celebration elements
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));
    
    // Fade animation for the overall visibility
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
    ));
    
    // Particle animation for floating particles
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    ));
    
    // Text bounce animation
    _textBounceAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.elasticInOut,
    ));
    
    // Listen for animation completion
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
    
    // Start particle animation loop
    _particleController.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.isVisible) {
        _particleController.reset();
        _particleController.forward();
      }
    });
    
    // Start text bounce loop
    _textController.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.isVisible) {
        _textController.reverse();
      } else if (status == AnimationStatus.dismissed && widget.isVisible) {
        _textController.forward();
      }
    });
  }
  
  @override
  void didUpdateWidget(VictoryAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible && !oldWidget.isVisible) {
      // Start all animations
      _mainController.forward();
      _particleController.forward();
      _textController.forward();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      // Stop all animations
      _mainController.reset();
      _particleController.reset();
      _textController.reset();
    }
  }
  
  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _textController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _mainController,
        _particleController,
        _textController,
      ]),
      builder: (context, child) {
        return Container(
          color: Colors.black.withValues(alpha: 0.3 * _fadeAnimation.value),
          child: Stack(
            children: [
              // Particle effects
              ..._buildParticles(),
              
              // Main celebration content
              Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Victory icon
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Victory text
                        Transform.scale(
                          scale: _textBounceAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '🎉 Congratulations! 🎉',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber[700],
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Level Complete!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.grey[700],
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  List<Widget> _buildParticles() {
    final particles = <Widget>[];
    const particleCount = 20;
    
    for (int i = 0; i < particleCount; i++) {
      final random = math.Random(i);
      final startX = random.nextDouble();
      final startY = 0.8 + random.nextDouble() * 0.2;
      final endY = -0.2;
      final drift = (random.nextDouble() - 0.5) * 0.3;
      
      final currentY = startY + (endY - startY) * _particleAnimation.value;
      final currentX = startX + drift * _particleAnimation.value;
      
      particles.add(
        Positioned(
          left: MediaQuery.of(context).size.width * currentX,
          top: MediaQuery.of(context).size.height * currentY,
          child: Opacity(
            opacity: (1.0 - _particleAnimation.value) * _fadeAnimation.value,
            child: Transform.rotate(
              angle: _particleAnimation.value * math.pi * 4,
              child: Container(
                width: 8 + random.nextDouble() * 8,
                height: 8 + random.nextDouble() * 8,
                decoration: BoxDecoration(
                  color: _getParticleColor(i),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return particles;
  }
  
  Color _getParticleColor(int index) {
    final colors = [
      Colors.amber,
      Colors.orange,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.yellow,
    ];
    return colors[index % colors.length];
  }
}