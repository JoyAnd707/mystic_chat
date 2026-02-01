import 'dart:math' as math;
import 'package:flutter/material.dart';

class RotatingEnvelope extends StatefulWidget {
  final String assetPath;
  final double size;
  final Duration duration;
  final double opacity;

  const RotatingEnvelope({
    super.key,
    required this.assetPath,
    this.size = 26,
    this.duration = const Duration(milliseconds: 1800),
    this.opacity = 1.0,
  });

  @override
  State<RotatingEnvelope> createState() => _RotatingEnvelopeState();
}

class _RotatingEnvelopeState extends State<RotatingEnvelope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.opacity,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final angle = _c.value * 2.0 * math.pi;
          return Transform.rotate(angle: angle, child: child);
        },
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Image.asset(
            widget.assetPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
