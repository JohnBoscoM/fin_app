import 'dart:math' as math;
import 'package:flutter/material.dart';

class DonutSegment {
  final String label;
  final double value;
  final Color color;

  const DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

class DonutChart extends StatefulWidget {
  final List<DonutSegment> segments;
  final double size;
  final double strokeWidth;
  final Widget? center;
  final Duration duration;

  const DonutChart({
    super.key,
    required this.segments,
    this.size = 180,
    this.strokeWidth = 24,
    this.center,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segments != widget.segments) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _DonutPainter(
              segments: widget.segments,
              strokeWidth: widget.strokeWidth,
              progress: _animation.value,
              trackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Center(child: widget.center),
          );
        },
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double strokeWidth;
  final double progress;
  final Color trackColor;

  _DonutPainter({
    required this.segments,
    required this.strokeWidth,
    required this.progress,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (segments.isEmpty) return;

    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total == 0) return;

    const startAngle = -math.pi / 2;
    const gapAngle = 0.06; // Gap between segments
    final totalGap = gapAngle * segments.length;
    final availableSweep = 2 * math.pi - totalGap;
    var currentAngle = startAngle;

    for (final segment in segments) {
      final sweepAngle = (segment.value / total) * availableSweep * progress;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, currentAngle, sweepAngle, false, paint);
      currentAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.segments != segments;
  }
}
