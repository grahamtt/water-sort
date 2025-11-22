import 'package:flutter/material.dart';
import '../models/container.dart' as models;
import '../animations/pour_animation.dart';
import '../animations/pour_animation_controller.dart';

/// A custom widget that renders a container with liquid layers
class ContainerWidget extends StatefulWidget {
  /// The container data to display
  final models.Container container;
  
  /// Whether this container is currently selected
  final bool isSelected;
  
  /// Callback when the container is tapped
  final VoidCallback? onTap;
  
  /// The size of the container widget
  final Size? size;
  
  /// Whether to show selection animation
  final bool showSelectionAnimation;
  
  /// Pour animation controller for liquid transfer effects
  final PourAnimationController? pourAnimationController;
  
  const ContainerWidget({
    super.key,
    required this.container,
    this.isSelected = false,
    this.onTap,
    this.size,
    this.showSelectionAnimation = true,
    this.pourAnimationController,
  });
  
  @override
  State<ContainerWidget> createState() => _ContainerWidgetState();
}

class _ContainerWidgetState extends State<ContainerWidget>
    with TickerProviderStateMixin {
  late AnimationController _selectionController;
  late Animation<double> _selectionAnimation;
  late AnimationController _tapController;
  late Animation<double> _tapAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Selection animation controller
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _selectionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _selectionController,
      curve: Curves.easeInOut,
    ));
    
    // Tap animation controller for visual feedback
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _tapAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void didUpdateWidget(ContainerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate selection state changes
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected && widget.showSelectionAnimation) {
        _selectionController.forward();
      } else {
        _selectionController.reverse();
      }
    }
  }
  
  @override
  void dispose() {
    _selectionController.dispose();
    _tapController.dispose();
    super.dispose();
  }
  
  void _handleTap() {
    if (widget.onTap != null) {
      // Play tap animation
      _tapController.forward().then((_) {
        _tapController.reverse();
      });
      
      widget.onTap!();
    }
  }
  
  Size _getResponsiveSize(BuildContext context) {
    if (widget.size != null) {
      return widget.size!;
    }
    
    // Calculate responsive size based on screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Base size calculations
    double containerWidth;
    double containerHeight;
    
    if (screenWidth < 400) {
      // Small screens (phones in portrait)
      containerWidth = screenWidth * 0.15;
      containerHeight = containerWidth * 1.5;
    } else if (screenWidth < 600) {
      // Medium screens (phones in landscape, small tablets)
      containerWidth = screenWidth * 0.12;
      containerHeight = containerWidth * 1.5;
    } else {
      // Large screens (tablets)
      containerWidth = screenWidth * 0.1;
      containerHeight = containerWidth * 1.5;
    }
    
    // Ensure minimum and maximum sizes
    containerWidth = containerWidth.clamp(60.0, 120.0);
    containerHeight = containerHeight.clamp(90.0, 180.0);
    
    // Adjust for screen height constraints
    if (containerHeight > screenHeight * 0.25) {
      containerHeight = screenHeight * 0.25;
      containerWidth = containerHeight / 1.5;
    }
    
    return Size(containerWidth, containerHeight);
  }
  
  @override
  Widget build(BuildContext context) {
    final containerSize = _getResponsiveSize(context);
    
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _selectionAnimation, 
          _tapAnimation,
          if (widget.pourAnimationController != null) widget.pourAnimationController!,
        ]),
        builder: (context, child) {
          // Get current pour animation data if available
          PourAnimationProgress? pourProgress;
          PourAnimation? pourAnimation;
          
          if (widget.pourAnimationController != null) {
            pourProgress = widget.pourAnimationController!.progress;
            pourAnimation = widget.pourAnimationController!.currentAnimation;
          }
          
          return Transform.scale(
            scale: _tapAnimation.value,
            child: Container(
              width: containerSize.width,
              height: containerSize.height,
              margin: const EdgeInsets.all(4.0),
              child: CustomPaint(
                painter: ContainerPainter(
                  container: widget.container,
                  isSelected: widget.isSelected,
                  selectionProgress: _selectionAnimation.value,
                  pourProgress: pourProgress,
                  pourAnimation: pourAnimation,
                ),
                size: containerSize,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for rendering the container and its liquid layers
class ContainerPainter extends CustomPainter {
  final models.Container container;
  final bool isSelected;
  final double selectionProgress;
  final PourAnimationProgress? pourProgress;
  final PourAnimation? pourAnimation;
  
  ContainerPainter({
    required this.container,
    required this.isSelected,
    required this.selectionProgress,
    this.pourProgress,
    this.pourAnimation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Draw container outline
    _drawContainerOutline(canvas, size, paint);
    
    // Draw liquid layers
    _drawLiquidLayers(canvas, size, paint);
    
    // Draw selection highlight
    if (isSelected && selectionProgress > 0) {
      _drawSelectionHighlight(canvas, size, paint);
    }
    
    // Draw capacity indicators (optional visual aid)
    _drawCapacityIndicators(canvas, size, paint);
    
    // Draw pour animation if active
    if (pourProgress != null && pourAnimation != null) {
      _drawPourAnimation(canvas, size, paint);
    }
  }
  
  void _drawContainerOutline(Canvas canvas, Size size, Paint paint) {
    const double wallThickness = 3.0;
    const double bottomThickness = 4.0;
    
    // Container walls and bottom
    paint.color = Colors.grey[800]!;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = wallThickness;
    
    // Draw container shape (rounded rectangle with open top)
    final containerRect = Rect.fromLTWH(
      wallThickness / 2,
      wallThickness / 2,
      size.width - wallThickness,
      size.height - wallThickness,
    );
    
    final path = Path();
    
    // Start from top-left
    path.moveTo(containerRect.left, containerRect.top);
    
    // Left wall
    path.lineTo(containerRect.left, containerRect.bottom - 8);
    
    // Bottom-left corner
    path.quadraticBezierTo(
      containerRect.left,
      containerRect.bottom,
      containerRect.left + 8,
      containerRect.bottom,
    );
    
    // Bottom
    path.lineTo(containerRect.right - 8, containerRect.bottom);
    
    // Bottom-right corner
    path.quadraticBezierTo(
      containerRect.right,
      containerRect.bottom,
      containerRect.right,
      containerRect.bottom - 8,
    );
    
    // Right wall
    path.lineTo(containerRect.right, containerRect.top);
    
    canvas.drawPath(path, paint);
    
    // Draw thicker bottom
    paint.strokeWidth = bottomThickness;
    canvas.drawLine(
      Offset(containerRect.left + 8, containerRect.bottom),
      Offset(containerRect.right - 8, containerRect.bottom),
      paint,
    );
  }
  
  void _drawLiquidLayers(Canvas canvas, Size size, Paint paint) {
    if (container.isEmpty) return;
    
    const double wallThickness = 3.0;
    const double bottomThickness = 4.0;
    
    // Calculate available space for liquid
    final liquidRect = Rect.fromLTWH(
      wallThickness,
      wallThickness,
      size.width - (wallThickness * 2),
      size.height - wallThickness - bottomThickness,
    );
    
    // Calculate total volume and height per unit
    final totalVolume = container.currentVolume;
    if (totalVolume == 0) return;
    
    final heightPerUnit = liquidRect.height / container.capacity;
    
    double currentY = liquidRect.bottom;
    
    // Draw each liquid layer from bottom to top
    for (final layer in container.liquidLayers) {
      final layerHeight = heightPerUnit * layer.volume;
      
      // Create gradient for liquid effect
      final gradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          layer.color.color.withValues(alpha: 0.8),
          layer.color.color,
          layer.color.color.withValues(alpha: 0.9),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
      
      paint.shader = gradient.createShader(Rect.fromLTWH(
        liquidRect.left,
        currentY - layerHeight,
        liquidRect.width,
        layerHeight,
      ));
      
      // Draw liquid layer with rounded bottom if it's the bottom layer
      final isBottomLayer = layer == container.liquidLayers.first;
      
      if (isBottomLayer) {
        final path = Path();
        path.moveTo(liquidRect.left, currentY - layerHeight);
        path.lineTo(liquidRect.right, currentY - layerHeight);
        path.lineTo(liquidRect.right, currentY - 8);
        
        // Bottom-right corner
        path.quadraticBezierTo(
          liquidRect.right,
          currentY,
          liquidRect.right - 8,
          currentY,
        );
        
        // Bottom
        path.lineTo(liquidRect.left + 8, currentY);
        
        // Bottom-left corner
        path.quadraticBezierTo(
          liquidRect.left,
          currentY,
          liquidRect.left,
          currentY - 8,
        );
        
        path.close();
        
        paint.style = PaintingStyle.fill;
        canvas.drawPath(path, paint);
      } else {
        // Regular rectangular layer
        final layerRect = Rect.fromLTWH(
          liquidRect.left,
          currentY - layerHeight,
          liquidRect.width,
          layerHeight,
        );
        
        paint.style = PaintingStyle.fill;
        canvas.drawRect(layerRect, paint);
      }
      
      // Add subtle highlight on top of each layer
      paint.shader = null;
      paint.color = Colors.white.withValues(alpha: 0.2);
      paint.strokeWidth = 1.0;
      paint.style = PaintingStyle.stroke;
      
      canvas.drawLine(
        Offset(liquidRect.left, currentY - layerHeight),
        Offset(liquidRect.right, currentY - layerHeight),
        paint,
      );
      
      currentY -= layerHeight;
    }
  }
  
  void _drawSelectionHighlight(Canvas canvas, Size size, Paint paint) {
    paint.shader = null;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3.0;
    paint.color = Colors.amber.withValues(alpha: selectionProgress * 0.8);
    
    // Draw pulsing selection ring
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) + (10 * selectionProgress);
    
    canvas.drawCircle(center, radius, paint);
    
    // Draw selection glow
    paint.color = Colors.amber.withValues(alpha: selectionProgress * 0.3);
    paint.strokeWidth = 6.0;
    canvas.drawCircle(center, radius, paint);
  }
  
  void _drawCapacityIndicators(Canvas canvas, Size size, Paint paint) {
    const double wallThickness = 3.0;
    const double bottomThickness = 4.0;
    
    // Calculate available space
    final liquidRect = Rect.fromLTWH(
      wallThickness,
      wallThickness,
      size.width - (wallThickness * 2),
      size.height - wallThickness - bottomThickness,
    );
    
    // Draw subtle capacity lines
    paint.shader = null;
    paint.color = Colors.grey.withValues(alpha: 0.2);
    paint.strokeWidth = 0.5;
    paint.style = PaintingStyle.stroke;
    
    final heightPerUnit = liquidRect.height / container.capacity;
    
    for (int i = 1; i < container.capacity; i++) {
      final y = liquidRect.bottom - (heightPerUnit * i);
      canvas.drawLine(
        Offset(liquidRect.left, y),
        Offset(liquidRect.right, y),
        paint,
      );
    }
  }
  
  void _drawPourAnimation(Canvas canvas, Size size, Paint paint) {
    if (pourProgress == null || pourAnimation == null) return;
    
    final progress = pourProgress!;
    final animation = pourAnimation!;
    
    // Only draw if this container is involved in the animation
    final isSource = container.id == animation.fromContainer;
    final isTarget = container.id == animation.toContainer;
    
    if (!isSource && !isTarget) return;
    
    paint.shader = null;
    paint.style = PaintingStyle.fill;
    
    if (isSource && progress.progress > 0.0) {
      _drawSourcePourEffect(canvas, size, paint, progress, animation);
    }
    
    if (isTarget && progress.showSplash) {
      _drawTargetSplashEffect(canvas, size, paint, progress, animation);
    }
    
    // Draw liquid stream if this is the source container
    if (isSource && progress.streamWidth > 0) {
      _drawLiquidStream(canvas, size, paint, progress, animation);
    }
  }
  
  void _drawSourcePourEffect(Canvas canvas, Size size, Paint paint, 
      PourAnimationProgress progress, PourAnimation animation) {
    const double wallThickness = 3.0;
    
    // Calculate pour spout position (top center of container)
    final spoutX = size.width / 2;
    final spoutY = wallThickness / 2;
    
    // Draw liquid flowing out effect
    paint.color = animation.liquidColor.color;
    
    // Create a small flowing liquid effect at the spout
    final flowWidth = progress.streamWidth * 0.8;
    final flowHeight = 8.0 * progress.progress;
    
    final flowRect = Rect.fromCenter(
      center: Offset(spoutX, spoutY + flowHeight / 2),
      width: flowWidth,
      height: flowHeight,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(flowRect, const Radius.circular(2.0)),
      paint,
    );
    
    // Add glow effect
    paint.color = animation.liquidColor.color.withValues(alpha: 0.3);
    paint.strokeWidth = 2.0;
    paint.style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(flowRect.inflate(2.0), const Radius.circular(3.0)),
      paint,
    );
  }
  
  void _drawTargetSplashEffect(Canvas canvas, Size size, Paint paint,
      PourAnimationProgress progress, PourAnimation animation) {
    const double wallThickness = 3.0;
    const double bottomThickness = 4.0;
    
    // Calculate liquid surface position
    final liquidRect = Rect.fromLTWH(
      wallThickness,
      wallThickness,
      size.width - (wallThickness * 2),
      size.height - wallThickness - bottomThickness,
    );
    
    final heightPerUnit = liquidRect.height / container.capacity;
    final currentVolume = container.currentVolume;
    final liquidSurfaceY = liquidRect.bottom - (heightPerUnit * currentVolume);
    
    // Draw splash particles
    paint.style = PaintingStyle.fill;
    paint.color = animation.liquidColor.color.withValues(alpha: progress.splashIntensity * 0.6);
    
    final splashCenter = Offset(size.width / 2, liquidSurfaceY);
    final splashRadius = 8.0 * progress.splashIntensity;
    
    // Draw multiple splash circles for effect
    for (int i = 0; i < 3; i++) {
      final radius = splashRadius * (1.0 - i * 0.3);
      final alpha = progress.splashIntensity * (1.0 - i * 0.4);
      
      paint.color = animation.liquidColor.color.withValues(alpha: alpha);
      canvas.drawCircle(splashCenter, radius, paint);
    }
    
    // Draw splash droplets
    paint.color = animation.liquidColor.color.withValues(alpha: progress.splashIntensity * 0.8);
    
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60.0) * (3.14159 / 180.0); // Convert to radians
      final distance = splashRadius * 1.5;
      final dropletX = splashCenter.dx + (distance * (angle / 6.28318)); // Simplified cos
      final dropletY = splashCenter.dy - (distance * progress.splashIntensity * 0.5);
      
      canvas.drawCircle(Offset(dropletX, dropletY), 2.0 * progress.splashIntensity, paint);
    }
  }
  
  void _drawLiquidStream(Canvas canvas, Size size, Paint paint,
      PourAnimationProgress progress, PourAnimation animation) {
    if (progress.streamWidth <= 0) return;
    
    const double wallThickness = 3.0;
    
    // Calculate stream start position (spout of source container)
    final startX = size.width / 2;
    final startY = wallThickness / 2;
    
    // Calculate stream path using the progress position
    final streamPath = Path();
    final streamWidth = progress.streamWidth;
    
    // Create a curved liquid stream path
    final controlPointX = startX + progress.streamPosition.dx * 0.5;
    final controlPointY = startY + progress.streamPosition.dy * 0.3;
    final endX = startX + progress.streamPosition.dx;
    final endY = startY + progress.streamPosition.dy;
    
    // Left side of stream
    streamPath.moveTo(startX - streamWidth / 2, startY);
    streamPath.quadraticBezierTo(
      controlPointX - streamWidth / 2,
      controlPointY,
      endX - streamWidth / 2,
      endY,
    );
    
    // Right side of stream (reverse direction)
    streamPath.lineTo(endX + streamWidth / 2, endY);
    streamPath.quadraticBezierTo(
      controlPointX + streamWidth / 2,
      controlPointY,
      startX + streamWidth / 2,
      startY,
    );
    
    streamPath.close();
    
    // Draw the liquid stream
    paint.style = PaintingStyle.fill;
    paint.color = animation.liquidColor.color;
    canvas.drawPath(streamPath, paint);
    
    // Add stream highlight
    paint.color = animation.liquidColor.color.withValues(alpha: 0.8);
    paint.strokeWidth = 1.0;
    paint.style = PaintingStyle.stroke;
    canvas.drawPath(streamPath, paint);
  }
  
  @override
  bool shouldRepaint(ContainerPainter oldDelegate) {
    return oldDelegate.container != container ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.selectionProgress != selectionProgress ||
        oldDelegate.pourProgress != pourProgress ||
        oldDelegate.pourAnimation != pourAnimation;
  }
}