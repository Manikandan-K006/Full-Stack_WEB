import 'package:flutter/material.dart';

/// Card with a subtle hover lift + border glow, used across the platform.
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? accentColor;
  final EdgeInsetsGeometry padding;
  final double hoverElevation;
  final BorderRadius radius;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.accentColor,
    this.padding = const EdgeInsets.all(16),
    this.hoverElevation = 6,
    this.radius = const BorderRadius.all(Radius.circular(14)),
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? Theme.of(context).colorScheme.primary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: widget.radius,
          border: Border.all(
            color: _hovered ? color.withValues(alpha: 0.45) : const Color(0xFFE6E8F0),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.10 : 0.04),
              blurRadius: _hovered ? 18 : 8,
              offset: Offset(0, _hovered ? 8 : 3),
            ),
          ],
        ),
        padding: widget.padding,
        child: widget.onTap != null
            ? InkWell(
                onTap: widget.onTap,
                borderRadius: widget.radius,
                child: widget.child,
              )
            : widget.child,
      ),
    );
  }
}