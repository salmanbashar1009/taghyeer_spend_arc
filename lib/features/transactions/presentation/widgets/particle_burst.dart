import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A particle burst effect that plays when a transaction is deleted.
class ParticleBurst extends StatefulWidget {
  final Offset origin;
  final List<Color> colors;
  final int particleCount;
  final VoidCallback? onComplete;

  const ParticleBurst({
    super.key,
    required this.origin,
    this.colors = const [
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.deepOrange,
      Colors.yellow,
    ],
    this.particleCount = 24,
    this.onComplete,
  });

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _particles = List.generate(widget.particleCount, (index) {
      final random = math.Random(index + DateTime.now().millisecond);
      return _Particle(
        x: widget.origin.dx,
        y: widget.origin.dy,
        vx: (random.nextDouble() - 0.5) * 300, // spread
        vy: (random.nextDouble() - 0.5) * 300 - 50, // slight upward bias
        color: widget.colors[random.nextInt(widget.colors.length)],
        size: random.nextDouble() * 6 + 3,
        rotation: random.nextDouble() * math.pi * 2,
        rotationSpeed: (random.nextDouble() - 0.5) * 10,
      );
    });

    _controller.forward().then((_) {
      widget.onComplete?.call();
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
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  double x, y;
  final double vx, vy;
  final Color color;
  final double size;
  final double rotation;
  final double rotationSpeed;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress; // 0..1

  _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {

    const gravity = 200.0;
    final t = progress;

    for (final p in particles) {
      final currentX = p.x + p.vx * t;
      final currentY = p.y + p.vy * t + 0.5 * gravity * t * t;

      // Fade out exponentially
      final opacity = math.pow(1 - progress, 2).toDouble();
      final scale = 1.0 - (progress * 0.5); // shrink to 50% by end

      final rotatedSize = p.size * scale;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Draw as rotated rounded rectangles
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(currentX, currentY),
          width: rotatedSize,
          height: rotatedSize * 0.6,
        ),
        Radius.circular(rotatedSize * 0.3),
      );

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(p.rotation + p.rotationSpeed * progress);
      canvas.translate(-currentX, -currentY);
      canvas.drawRRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}