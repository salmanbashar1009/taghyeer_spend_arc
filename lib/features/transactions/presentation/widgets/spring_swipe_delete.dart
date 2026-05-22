import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

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
  double _dragOffset = 0;
  bool _hasBeenDismissed = false;

  static const double _deleteThreshold = 0.3;

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
              color: widget.deleteColor.withOpacity(deleteProgress * 0.8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Icon(
                    widget.deleteIcon,
                    color: Colors.white.withOpacity(deleteProgress),
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Content — offset by drag
        Transform.translate(
          offset: Offset(-_dragOffset, 0),
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              if (_hasBeenDismissed) return;
              setState(() {
                _dragOffset =
                    (_dragOffset - details.delta.dx).clamp(0.0, screenWidth);
              });
            },
            onHorizontalDragEnd: (details) {
              if (_hasBeenDismissed) return;
              final threshold = screenWidth * _deleteThreshold;

              if (_dragOffset > threshold) {
                // Past threshold — animate off screen
                _hasBeenDismissed = true;

                // Use spring to animate the rest
                final simulation = SpringDescription(
                  mass: 1.0,
                  stiffness: 80.0,
                  damping: 12.0,
                );

                // Simple approach: just animate off and call onDeleted
                setState(() {
                  _dragOffset = screenWidth; // Slide fully off
                });

                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) {
                    widget.onDeleted();
                  }
                });
              } else {
                // Not past threshold — spring back
                setState(() {
                  _dragOffset = 0;
                });
              }
            },
            child: widget.child,
          ),
        ),
      ],
    );
  }
}