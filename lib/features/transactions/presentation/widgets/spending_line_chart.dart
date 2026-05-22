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
    if (dataPoints.isEmpty || labels.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Gathering spending data...')),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite 
            ? constraints.maxWidth 
            : MediaQuery.of(context).size.width;
        
        return RepaintBoundary(
          child: SizedBox(
            height: height,
            width: width,
            child: CustomPaint(
              size: Size(width, height),
              painter: _LineChartPainter(
                dataPoints: dataPoints,
                labels: labels,
                animationProgress: animationValue,
                lineColor: Theme.of(context).colorScheme.primary,
                gridColor: Theme.of(context).colorScheme.outlineVariant,
                labelStyle: Theme.of(context).textTheme.labelSmall ?? 
                    const TextStyle(fontSize: 10, color: Colors.grey),
                gradientTop: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                gradientBottom: Theme.of(context).colorScheme.primary.withOpacity(0.0),
              ),
            ),
          ),
        );
      },
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

  static const double leftPadding = 45;
  static const double bottomPadding = 30;
  static const double topPadding = 20;
  static const double rightPadding = 20;

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
    if (size.width <= leftPadding + rightPadding || size.height <= topPadding + bottomPadding) return;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    // Scale calculation - ensure a minimum maxVal of 100 for a clean baseline
    final rawMax = dataPoints.isEmpty ? 0.0 : dataPoints.reduce(math.max);
    final maxVal = rawMax <= 0 ? 100.0 : rawMax * 1.25;

    // ── 1. Draw Grid Lines and Y-Axis Labels (Always Visible) ──
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    
    for (var i = 0; i <= 4; i++) {
      final y = topPadding + (chartHeight / 4) * (4 - i);
      canvas.drawLine(Offset(leftPadding, y), Offset(size.width - rightPadding, y), gridPaint);
      
      final val = (maxVal / 4) * i;
      final textSpan = TextSpan(
        text: val >= 1000 ? '${(val / 1000).toStringAsFixed(1)}k' : val.toStringAsFixed(0),
        style: labelStyle.copyWith(color: labelStyle.color?.withOpacity(0.5)),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(leftPadding - tp.width - 8, y - tp.height / 2));
    }

    // ── 2. Calculate All Points ──
    final xStep = chartWidth / (math.max(1, dataPoints.length - 1));
    final points = <Offset>[];
    for (var i = 0; i < dataPoints.length; i++) {
      final x = leftPadding + xStep * i;
      final normalizedVal = dataPoints[i] / maxVal;
      final y = topPadding + chartHeight - (chartHeight * normalizedVal);
      points.add(Offset(x, y));
    }

    // ── 3. Draw X-Axis Labels (Always Visible) ──
    for (var i = 0; i < labels.length; i++) {
      if (i >= points.length) break;
      final textSpan = TextSpan(
        text: labels[i],
        style: labelStyle.copyWith(color: labelStyle.color?.withOpacity(0.7)),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(points[i].dx - tp.width / 2, topPadding + chartHeight + 10));
    }

    // ── 4. Drawing the animated line/area ──
    // We show the line progressively based on animationProgress.
    final visibleCount = (points.length * animationProgress).ceil().clamp(1, points.length);
    final visiblePoints = points.sublist(0, visibleCount);

    if (visiblePoints.length >= 2) {
      // Area path
      final areaPath = Path()
        ..moveTo(visiblePoints.first.dx, topPadding + chartHeight)
        ..addPolygon(visiblePoints, false)
        ..lineTo(visiblePoints.last.dx, topPadding + chartHeight)
        ..close();
      
      canvas.drawPath(areaPath, Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [gradientTop, gradientBottom],
        ).createShader(Rect.fromLTWH(leftPadding, topPadding, chartWidth, chartHeight)));

      // Line path with subtle curves
      final linePath = Path()..moveTo(visiblePoints.first.dx, visiblePoints.first.dy);
      for (var i = 1; i < visiblePoints.length; i++) {
        final prev = visiblePoints[i-1];
        final curr = visiblePoints[i];
        linePath.cubicTo(
          prev.dx + (curr.dx - prev.dx) / 2, prev.dy,
          prev.dx + (curr.dx - prev.dx) / 2, curr.dy,
          curr.dx, curr.dy,
        );
      }
      canvas.drawPath(linePath, Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round);

      // Data point dots
      final dotPaint = Paint()..color = lineColor;
      final dotOutline = Paint()..color = Colors.white..strokeWidth = 2..style = PaintingStyle.stroke;
      for (final p in visiblePoints) {
        canvas.drawCircle(p, 4, dotPaint);
        canvas.drawCircle(p, 4, dotOutline);
      }
    } else if (visiblePoints.isNotEmpty) {
      // Just a single dot if only one point is "visible"
      canvas.drawCircle(visiblePoints.first, 4, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => 
      old.dataPoints != dataPoints || old.animationProgress != animationProgress;
}
