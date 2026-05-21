import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// A swipe-to-delete widget with spring physics.

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

class _SpringSwipeDeleteState extends State<SpringSwipeDelete>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _dragOffset = 0;
  bool _hasBeenDismissed = false;


  static const double _deleteThreshold = 0.3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: double.infinity,
    );

    _controller.addListener(() {
      setState(() {
        _dragOffset = _controller.value;
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasBeenDismissed) {
        _animateOffScreen();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateOffScreen() {
    _hasBeenDismissed = true;
    _controller
        .animateTo(
      2000, // Effectively infinity for visual purposes
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeIn,
    )
        .then((_) {
      widget.onDeleted();
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_hasBeenDismissed) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * _deleteThreshold;

    if (_dragOffset.abs() > threshold) {
      final simulation = SpringDescription(
        mass: 1.0,
        stiffness: 100.0,
        damping: 15.0,
      );

      _controller.animateWith(
        SpringSimulation(simulation, _dragOffset, screenWidth, 0),
      );
    } else {
      final simulation = SpringDescription(
        mass: 1.0,
        stiffness: 300.0,
        damping: 25.0,
      );

      _controller.animateWith(
        SpringSimulation(simulation, _dragOffset, 0, 0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * _deleteThreshold;
    final deleteProgress = (_dragOffset / threshold).clamp(0.0, 1.0);

    return Stack(
      children: [
        // Delete background
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: widget.deleteColor.withValues(
                alpha: deleteProgress * 0.8,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Icon(
                    widget.deleteIcon,
                    color: Colors.white
                        .withValues(alpha: deleteProgress),
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),

        
        Transform.translate(
          offset: Offset(-_dragOffset, 0),
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              if (_hasBeenDismissed) return;
              setState(() {
                // Only allow left-swipe (negative direction)
                _dragOffset =
                    (_dragOffset - details.delta.dx).clamp(0.0, screenWidth);
              });
            },
            onHorizontalDragEnd: _handleDragEnd,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}