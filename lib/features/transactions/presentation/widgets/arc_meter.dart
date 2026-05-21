import 'package:flutter/material.dart';

class ArcMeter extends StatelessWidget {
  final double spent;
  final double budget;
  final double animationValue; // 0..1 from AnimationController
  final double size;

  const ArcMeter({
    super.key,
    required this.spent,
    required this.budget,
    required this.animationValue,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = budget <= 0 ? 0.0 : (spent / budget).clamp(0.0, 1.5);
    final animatedRatio = ratio * animationValue;

    final theme = Theme.of(context);

    return SizedBox(
      width: size,
      height: size * 0.65, // Arc is top-half only
      child: CustomPaint(
        painter: _ArcMeterPainter(
          ratio: animatedRatio,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          // Gradient from green → orange → red based on ratio
          arcColors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
            theme.colorScheme.error,
          ],
        ),
        child: Align(
          alignment: const Alignment(0, 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(ratio * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcMeterPainter extends CustomPainter {
  final double ratio;
  final Color backgroundColor;
  final List<Color> arcColors;

  _ArcMeterPainter({
    required this.ratio,
    required this.backgroundColor,
    required this.arcColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 18.0;
    const startAngle = 3.14159; // π — left side
    const sweepAngle = 3.14159; // π — semi-circle

    final center = Offset(size.width / 2, size.height);
    final radius = (size.width / 2) - strokeWidth / 2;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Foreground arc — only draw if there's something to show
    if (ratio > 0) {
      final clampedSweep = (sweepAngle * ratio.clamp(0.0, 1.0));


      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + clampedSweep,
        colors: arcColors.length >= 3
            ? [
          arcColors[0],
          if (ratio > 0.5) arcColors[1],
          if (ratio > 0.8) arcColors[2],
        ]
            : arcColors,
        stops: _computeStops(ratio),
      );

      final fgPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        clampedSweep,
        false,
        fgPaint,
      );
    }
  }

  /// Dynamically compute gradient stops so the color transition
  List<double> _computeStops(double ratio) {
    if (ratio <= 0.5) return [0.0, 1.0];
    if (ratio <= 0.8) return [0.0, 0.5, 1.0];
    return [0.0, 0.4, 0.8, 1.0];
  }


  @override
  bool shouldRepaint(_ArcMeterPainter oldDelegate) {
    return oldDelegate.ratio != ratio ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

