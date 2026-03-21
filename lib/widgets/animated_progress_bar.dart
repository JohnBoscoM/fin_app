import 'package:flutter/material.dart';

class AnimatedProgressBar extends StatefulWidget {
  final double progress; // 0.0 to 100.0
  final double height;
  final Color? backgroundColor;
  final Duration duration;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.backgroundColor,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(begin: _animation.value, end: widget.progress)
          .animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color getProgressColor(double progress) {
    if (progress >= 100) {
      return const Color(0xFF4CAF50);
    } else if (progress >= 80) {
      return const Color(0xFF66BB6A);
    } else {
      return const Color(0xFFE85D75);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _animation.value / 100,
            minHeight: widget.height,
            backgroundColor: widget.backgroundColor ??
                (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF424242)
                    : const Color(0xFFEEEEEE)),
            valueColor: AlwaysStoppedAnimation<Color>(
              getProgressColor(_animation.value),
            ),
          ),
        );
      },
    );
  }
}
