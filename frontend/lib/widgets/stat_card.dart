import 'package:flutter/material.dart';

/// Statistic card with an animated counting number.
class StatCard extends StatefulWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final String? suffix;
  final bool isCurrency;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix,
    this.isCurrency = false,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void didUpdateWidget(covariant StatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(double v) {
    if (widget.isCurrency) return '₹${v.round().toString()}';
    return v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.icon, color: widget.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                const SizedBox(height: 2),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final v = _format(widget.value * Curves.easeOutCubic.transform(_controller.value));
                    return Text(
                      '$v${widget.suffix ?? ''}',
                      style: const TextStyle(
                          fontSize: 21, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}