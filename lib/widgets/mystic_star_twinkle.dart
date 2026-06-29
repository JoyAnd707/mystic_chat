import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class MysticStarTwinkleOverlay extends StatelessWidget {
  final Animation<double> animation;
  final int starCount;
  final double sizeMultiplier;

  const MysticStarTwinkleOverlay({
    super.key,
    required this.animation,
    this.starCount = 90,
    this.sizeMultiplier = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          painter: _StarTwinklePainter(
            t: animation.value,
            starCount: starCount,
            sizeMultiplier: sizeMultiplier,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _TwinkleStar {
  final double nx;
  final double ny;
  final double baseR;
  final double speed;
  final double phase;

  _TwinkleStar({
    required this.nx,
    required this.ny,
    required this.baseR,
    required this.speed,
    required this.phase,
  });
}

class _StarTwinklePainter extends CustomPainter {
  final double t;
  final int starCount;
  final double sizeMultiplier;
  late final List<_TwinkleStar> _stars;

  _StarTwinklePainter({
    required this.t,
    required this.starCount,
    required this.sizeMultiplier,
  }) {
    final rng = Random(42);

    _stars = List<_TwinkleStar>.generate(starCount, (i) {
      final tier = rng.nextDouble();
      final double baseR;

      if (tier < 0.78) {
        baseR = 0.9 + rng.nextDouble() * 0.6;
      } else if (tier < 0.96) {
        baseR = 1.6 + rng.nextDouble() * 0.9;
      } else {
        baseR = 2.8 + rng.nextDouble() * 1.2;
      }

      return _TwinkleStar(
        nx: rng.nextDouble(),
        ny: rng.nextDouble(),
        baseR: baseR,
        speed: 0.7 + rng.nextDouble() * 1.6,
        phase: rng.nextDouble() * pi * 2,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final core = Paint()..style = PaintingStyle.fill;
    final soft = Paint()..style = PaintingStyle.fill;

    final tt = t * pi * 2;

    for (final s in _stars) {
      final x = s.nx * size.width;
      final y = s.ny * size.height;

      final wave = sin(tt * s.speed + s.phase);
      final alpha = (0.35 + 0.65 * (wave * 0.5 + 0.5)).clamp(0.12, 1.0);

      final r = (s.baseR * sizeMultiplier).clamp(0.9, 14.0);

      final blurSigma = (r * 0.55).clamp(0.9, 3.2);
      soft.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);

      soft.color = Colors.white.withOpacity((alpha * 0.22).clamp(0.04, 0.22));
      canvas.drawCircle(Offset(x, y), r * 1.25, soft);

      core.color = Colors.white.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), r, core);
    }
  }

  @override
  bool shouldRepaint(covariant _StarTwinklePainter old) {
    return old.t != t ||
        old.starCount != starCount ||
        old.sizeMultiplier != sizeMultiplier;
  }
}