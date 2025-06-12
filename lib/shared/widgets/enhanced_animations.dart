import 'package:flutter/material.dart';
import 'dart:math' as math;

class FloatingIcon extends StatefulWidget {
  final IconData icon;
  final Duration delay;
  final Color color;
  final double size;

  const FloatingIcon({
    super.key,
    required this.icon,
    this.delay = Duration.zero,
    this.color = Colors.white,
    this.size = 24.0,
  });

  @override
  State<FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<FloatingIcon>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _rotateController;
  late Animation<double> _floatAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    
    _floatController = AnimationController(
      duration: Duration(seconds: 3 + math.Random().nextInt(2)),
      vsync: this,
    );
    
    _rotateController = AnimationController(
      duration: Duration(seconds: 10 + math.Random().nextInt(5)),
      vsync: this,
    );
    
    _floatAnimation = Tween<double>(begin: -20, end: 20).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
    
    Future.delayed(widget.delay, () {
      if (mounted) {
        _floatController.repeat(reverse: true);
        _rotateController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnimation, _rotateAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: Icon(
              widget.icon,
              color: widget.color.withOpacity(0.1),
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}

class PulsingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulsingWidget({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.minScale = 1.0,
    this.maxScale = 1.15,
  });

  @override
  State<PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<PulsingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

class SlideInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset beginOffset;

  const SlideInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 0.3),
  });

  @override
  State<SlideInWidget> createState() => _SlideInWidgetState();
}

class _SlideInWidgetState extends State<SlideInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
} 