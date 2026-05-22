import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ArcMeter extends StatelessWidget {
  final double spent;
  final double budget;
  final double animationValue;
  final double size;
  final ui.FragmentShader? glowShader;
  final double? shaderTime;

  const ArcMeter({
    super.key,
    required this.spent,
    required this.budget,
    required this.animationValue,
    this.size = 220,
    this.glowShader,
    this.shaderTime,
  });

  @override
  Widget build(BuildContext context) {
    // Fallback budget of 1 to avoid division by zero and show progress even if income is 0
    final effectiveBudget = budget > 0 ? budget : 1000.0;
    final ratio = (spent / effectiveBudget).clamp(0.0, 1.5);
    final animatedRatio = ratio * animationValue;
    final isOverspent = spent > effectiveBudget && budget > 0;
    final theme = Theme.of(context);

    return SizedBox(
      width: size,
      height: size * 0.65,
      child: CustomPaint(
        painter: _ArcMeterPainter(
          ratio: animatedRatio,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          startColor: theme.colorScheme.primary,
          endColor: ratio > 0.8 ? theme.colorScheme.error : theme.colorScheme.tertiary,
          glowShader: isOverspent ? glowShader : null,
          shaderTime: shaderTime ?? 0,
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
                  color: isOverspent ? theme.colorScheme.error : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '\$${spent.toStringAsFixed(0)} / \$${effectiveBudget.toStringAsFixed(0)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (isOverspent)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'OVER BUDGET',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
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
  final Color startColor;
  final Color endColor;
  final ui.FragmentShader? glowShader;
  final double shaderTime;

  _ArcMeterPainter({
    required this.ratio,
    required this.backgroundColor,
    required this.startColor,
    required this.endColor,
    this.glowShader,
    required this.shaderTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 20.0;
    const startAngle = 3.14159; 
    const sweepAngle = 3.14159; 

    final center = Offset(size.width / 2, size.height);
    final radius = (size.width / 2) - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Glow Shader
    if (glowShader != null) {
      glowShader!
        ..setFloat(0, size.width)
        ..setFloat(1, size.height)
        ..setFloat(2, shaderTime)
        ..setFloat(3, endColor.red / 255)
        ..setFloat(4, endColor.green / 255)
        ..setFloat(5, endColor.blue / 255)
        ..setFloat(6, 1.0);
      
      canvas.drawCircle(center, radius + 10, Paint()..shader = glowShader);
    }

    // Background
    canvas.drawArc(
      rect, startAngle, sweepAngle, false,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth,
    );

    // Progress
    if (ratio > 0) {
      final clampedSweep = sweepAngle * ratio.clamp(0.0, 1.0);
      canvas.drawArc(
        rect, startAngle, clampedSweep, false,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(rect.left, center.dy),
            Offset(rect.right, center.dy),
            [startColor, endColor],
          )
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcMeterPainter old) => 
      old.ratio != ratio || old.shaderTime != shaderTime || old.glowShader != glowShader;
}
