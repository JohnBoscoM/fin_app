import 'package:flutter/material.dart';
import '../themes/app_themes.dart';

class AnimatedProgressBar extends StatefulWidget {
  final double progress; // 0.0 to 100.0
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Duration duration;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.backgroundColor,
    this.foregroundColor,
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
    if (widget.foregroundColor != null) return widget.foregroundColor!;
    if (progress >= 100) {
      return AppColors.positive;
    } else if (progress >= 90) {
      return AppColors.negative;
    } else if (progress >= 70) {
      return AppColors.warning;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.height / 2),
          child: LinearProgressIndicator(
            value: (_animation.value / 100).clamp(0.0, 1.0),
            minHeight: widget.height,
            backgroundColor: widget.backgroundColor ??
                Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              getProgressColor(_animation.value),
            ),
          ),
        );
      },
    );
  }
}
