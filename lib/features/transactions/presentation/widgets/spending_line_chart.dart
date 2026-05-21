import 'dart:math' as math;
import 'package:flutter/material.dart';

class SpendingLineChart extends StatelessWidget {
  final List<double> dataPoints;
  final List<String> labels;
  final double animationValue;
  final double height;

  const SpendingLineChart({
    super.key,
    required this.dataPoints,
    required this.labels,
    required this.animationValue,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('No data yet')),
      );
    }

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _LineChartPainter(
          dataPoints: dataPoints,
          labels: labels,
          animationProgress: animationValue,
          lineColor: Theme.of(context).colorScheme.primary,
          gridColor: Theme.of(context).colorScheme.outlineVariant,
          labelStyle: Theme.of(context).textTheme.labelSmall!,
          gradientTop: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          gradientBottom: Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final List<String> labels;
  final double animationProgress;
  final Color lineColor;
  final Color gridColor;
  final TextStyle labelStyle;
  final Color gradientTop;
  final Color gradientBottom;

  /// Chart area insets
  static const double leftPadding = 40;
  static const double bottomPadding = 24;
  static const double topPadding = 8;
  static const double rightPadding = 8;

  _LineChartPainter({
    required this.dataPoints,
    required this.labels,
    required this.animationProgress,
    required this.lineColor,
    required this.gridColor,
    required this.labelStyle,
    required this.gradientTop,
    required this.gradientBottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    final maxVal = dataPoints.reduce(math.max);
    final minVal = 0.0;

    // grid line
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    const gridLineCount = 4;
    for (var i = 0; i <= gridLineCount; i++) {
      final y = topPadding + (chartHeight / gridLineCount) * i;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      // Y-axis label
      final value = maxVal - (maxVal / gridLineCount) * i;
      final textSpan = TextSpan(
        text: value.toStringAsFixed(0),
        style: labelStyle,
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftPadding - 4);
      tp.paint(
        canvas,
        Offset(leftPadding - tp.width - 4, y - tp.height / 2),
      );
    }

    // Calculate data points
    final points = <Offset>[];
    for (var i = 0; i < dataPoints.length; i++) {
      final x = leftPadding + (chartWidth / (dataPoints.length - 1)) * i;
      final normalizedVal =
      maxVal == 0 ? 0.0 : dataPoints[i] / maxVal;
      final y = topPadding + chartHeight - (chartHeight * normalizedVal);
      points.add(Offset(x, y));
    }


    final visibleCount =
    (points.length * animationProgress).ceil().clamp(1, points.length);
    final visiblePoints = points.sublist(0, visibleCount);

    if (visiblePoints.length < 2) return;

    // Gradient fill under the curve
    final fillPath = Path()
      ..moveTo(visiblePoints.first.dx, topPadding + chartHeight)
      ..addPolygon(visiblePoints, false)
      ..lineTo(visiblePoints.last.dx, topPadding + chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [gradientTop, gradientBottom],
      ).createShader(
        Rect.fromLTWH(leftPadding, topPadding, chartWidth, chartHeight),
      );

    canvas.drawPath(fillPath, fillPaint);


    final linePath = Path();
    linePath.moveTo(visiblePoints.first.dx, visiblePoints.first.dy);


    for (var i = 1; i < visiblePoints.length; i++) {
      final prev = visiblePoints[i - 1];
      final curr = visiblePoints[i];
      final controlOffset = (curr.dx - prev.dx) / 3;

      linePath.cubicTo(
        prev.dx + controlOffset, prev.dy,
        curr.dx - controlOffset, curr.dy,
        curr.dx, curr.dy,
      );
    }

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    // Data point dots
    final dotPaint = Paint()..color = lineColor;
    final dotBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final point in visiblePoints) {
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(point, 4, dotBorder);
    }

    // ── X-axis labels ─────────────────────────────────
    for (var i = 0; i < labels.length && i < points.length; i++) {
      if (i % (labels.length > 7 ? 2 : 1) != 0) continue; // skip every other if crowded
      final textSpan = TextSpan(text: labels[i], style: labelStyle);
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(
        canvas,
        Offset(points[i].dx - tp.width / 2,
            topPadding + chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.animationProgress != animationProgress;
  }
}