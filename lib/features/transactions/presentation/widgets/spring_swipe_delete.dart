import 'dart:math' as math;
import 'package:flutter/material.dart';

class SpringSwipeDelete extends StatefulWidget {
  final Widget child;
  final VoidCallback onDeleted;
  final Color deleteColor;
  final IconData deleteIcon;

  const SpringSwipeDelete({
    super.key,
    required this.child,
    required this.onDeleted,
    this.deleteColor = Colors.red,
    this.deleteIcon = Icons.delete_outline,
  });

  @override
  State<SpringSwipeDelete> createState() => _SpringSwipeDeleteState();
}

class _SpringSwipeDeleteState extends State<SpringSwipeDelete> {
  double _dragOffset = 0;
  bool _isDeleting = false;

  static const double _deleteThreshold = 0.35;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * _deleteThreshold;
    final deleteProgress = (_dragOffset / threshold).clamp(0.0, 1.0);

    return Stack(
      children: [
        // 1. Delete Background (Red bar with icon)
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            decoration: BoxDecoration(
              color: widget.deleteColor.withOpacity(deleteProgress * 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: Opacity(
              opacity: deleteProgress,
              child: Transform.scale(
                scale: 0.5 + (0.5 * deleteProgress),
                child: Icon(widget.deleteIcon, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),

        // 2. Foreground Item (The Tile)
        if (!_isDeleting)
          Transform.translate(
            offset: Offset(-_dragOffset, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragOffset = (_dragOffset - details.delta.dx).clamp(0.0, screenWidth);
                });
              },
              onHorizontalDragEnd: (details) {
                if (_dragOffset > threshold) {
                  _onSwipeComplete();
                } else {
                  setState(() => _dragOffset = 0);
                }
              },
              child: widget.child,
            ),
          ),
      ],
    );
  }

  void _onSwipeComplete() {
    // 1. Get position for the burst effect before the widget is removed
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final size = renderBox.size;
      final offset = renderBox.localToGlobal(Offset.zero);
      _spawnOverlayBurst(offset + Offset(size.width / 2, size.height / 2));
    }

    // 2. Set deleting state to hide the child locally
    setState(() {
      _isDeleting = true;
    });

    // 3. Trigger actual deletion in the Bloc (Instant state update)
    widget.onDeleted();
  }

  void _spawnOverlayBurst(Offset center) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ParticleBurstOverlay(
        center: center,
        color: widget.deleteColor,
        onComplete: () {
          entry.remove();
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }
}

/// A standalone widget that handles the particle animation in the Overlay.
class _ParticleBurstOverlay extends StatefulWidget {
  final Offset center;
  final Color color;
  final VoidCallback onComplete;

  const _ParticleBurstOverlay({
    required this.center,
    required this.color,
    required this.onComplete,
  });

  @override
  State<_ParticleBurstOverlay> createState() => _ParticleBurstOverlayState();
}

class _ParticleBurstOverlayState extends State<_ParticleBurstOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_BurstParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final random = math.Random();
    for (int i = 0; i < 35; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 2.0 + random.nextDouble() * 7.0;
      _particles.add(_BurstParticle(
        position: widget.center,
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        size: 2.0 + random.nextDouble() * 5.0,
      ));
    }

    _controller.addListener(() {
      for (var p in _particles) {
        p.update();
      }
      if (mounted) setState(() {});
    });

    _controller.forward().then((_) {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrapping in Positioned.fill and SizedBox.expand ensures the widget
    // has valid constraints and size immediately upon being added to the Overlay.
    return Positioned.fill(
      child: IgnorePointer(
        child: SizedBox.expand(
          child: CustomPaint(
            painter: _BurstPainter(_particles, widget.color),
          ),
        ),
      ),
    );
  }
}

class _BurstParticle {
  Offset position;
  Offset velocity;
  double size;
  double opacity = 1.0;

  _BurstParticle({required this.position, required this.velocity, required this.size});

  void update() {
    position += velocity;
    opacity -= 0.025;
    if (opacity < 0) opacity = 0;
  }
}

class _BurstPainter extends CustomPainter {
  final List<_BurstParticle> particles;
  final Color color;
  _BurstPainter(this.particles, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var p in particles) {
      if (p.opacity > 0) {
        paint.color = color.withOpacity(p.opacity);
        canvas.drawCircle(p.position, p.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
