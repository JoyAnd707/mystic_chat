import 'dart:math';
import 'package:flutter/material.dart';

class MysticStarfield extends StatefulWidget {
  final int starCount;

  /// speed multiplier (1.0 = normal). smaller = slower
  final double speed;

  /// Optional: add a tiny drift to stars (Mystic is mostly static; keep 0)
  final double driftPx;

  /// ✅ Big visual boost like Mystic (try 6.0, 8.0)
  final double sizeMultiplier;

  /// ✅ Mystic-like glow around stars
  final bool enableGlow;

  const MysticStarfield({
    
    super.key,
    this.starCount = 120,
    this.speed = 1.0,
    this.driftPx = 0.0,
    this.sizeMultiplier = 60.0, // ✅ THIS is the main “make it bigger” knob
    this.enableGlow = true,
  });

  @override
  State<MysticStarfield> createState() => _MysticStarfieldState();
}

class _MysticStarfieldState extends State<MysticStarfield>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  // ✅ Strongly deterministic
  final Random _rng = Random(7);

  bool _generated = false;
  late List<_StarN> _starsN;

  @override
  void initState() {
    super.initState();
    _starsN = <_StarN>[];

    final baseMs = (950 / widget.speed).round();

    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: baseMs.clamp(420, 1800)),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  void _generateOnce() {
    if (_generated) return;
    _generated = true;

    // ✅ More “real” Mystic distribution: few big + many mid + many small
    final int bigCount = max(18, (widget.starCount * 0.18).round());
    final int smallCount = max(0, widget.starCount - bigCount);

    final stars = <_StarN>[];

    // ---------- SMALL/MID STARS ----------
    for (int i = 0; i < smallCount; i++) {
      final tier = _rng.nextDouble();
      double r;

      // Bigger than before (so not dust)
      if (tier < 0.65) {
        r = _lerp(1.6, 3.0, _rng.nextDouble());
      } else if (tier < 0.92) {
        r = _lerp(3.0, 5.2, _rng.nextDouble());
      } else {
        r = _lerp(5.2, 7.2, _rng.nextDouble());
      }

      final bool isSquare = _rng.nextDouble() < 0.06;

      final base = _lerp(0.10, 0.46, _rng.nextDouble());
      final amp = _lerp(0.10, 0.45, _rng.nextDouble());
      final twSpeed = _lerp(0.45, 1.55, _rng.nextDouble());
      final phase = _rng.nextDouble() * pi * 2;

      final bool hasGlint = _rng.nextDouble() < 0.62;
      final glintStrength =
          hasGlint ? _lerp(0.35, 1.05, _rng.nextDouble()) : 0.0;
      final glintSpeed =
          hasGlint ? _lerp(1.4, 3.3, _rng.nextDouble()) : 0.0;
      final glintPhase = _rng.nextDouble() * pi * 2;

      stars.add(
        _StarN(
          nx: _rng.nextDouble(),
          ny: _rng.nextDouble(),
          radius: r,
          isSquare: isSquare,
          baseOpacity: base,
          twinkleAmp: amp,
          twinkleSpeed: twSpeed,
          phase: phase,
          glintStrength: glintStrength,
          glintSpeed: glintSpeed,
          glintPhase: glintPhase,
          driftDir: Offset(_rng.nextDouble() - 0.5, _rng.nextDouble() - 0.5),
        ),
      );
    }

    // ---------- BIG STARS (these must be visible!) ----------
    for (int i = 0; i < bigCount; i++) {
      // ✅ Much bigger base than before
      final double r = _lerp(12.0, 22.0, _rng.nextDouble());

      final base = _lerp(0.18, 0.70, _rng.nextDouble());
      final amp = _lerp(0.14, 0.62, _rng.nextDouble());
      final twSpeed = _lerp(0.35, 1.10, _rng.nextDouble());
      final phase = _rng.nextDouble() * pi * 2;

      final glintStrength = _lerp(0.70, 1.35, _rng.nextDouble());
      final glintSpeed = _lerp(1.2, 2.8, _rng.nextDouble());
      final glintPhase = _rng.nextDouble() * pi * 2;

      stars.add(
        _StarN(
          nx: _rng.nextDouble(),
          ny: _rng.nextDouble(),
          radius: r,
          isSquare: false,
          baseOpacity: base,
          twinkleAmp: amp,
          twinkleSpeed: twSpeed,
          phase: phase,
          glintStrength: glintStrength,
          glintSpeed: glintSpeed,
          glintPhase: glintPhase,
          driftDir: Offset(_rng.nextDouble() - 0.5, _rng.nextDouble() - 0.5),
        ),
      );
    }

    _starsN = stars;
  }

  @override
  Widget build(BuildContext context) {
    _generateOnce();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size.width <= 0 || size.height <= 0) {
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return CustomPaint(
              painter: _MysticStarfieldPainter(
                starsN: _starsN,
                t: _c.value,
                driftPx: widget.driftPx,
                sizeMultiplier: widget.sizeMultiplier,
                enableGlow: widget.enableGlow,
              ),
              child: const SizedBox.expand(),
            );
          },
        );
      },
    );
  }
}

class _StarN {
  final double nx;
  final double ny;

  final double radius;
  final bool isSquare;

  final double baseOpacity;
  final double twinkleAmp;
  final double twinkleSpeed;
  final double phase;

  final double glintStrength;
  final double glintSpeed;
  final double glintPhase;

  final Offset driftDir;

  _StarN({
    required this.nx,
    required this.ny,
    required this.radius,
    required this.isSquare,
    required this.baseOpacity,
    required this.twinkleAmp,
    required this.twinkleSpeed,
    required this.phase,
    required this.glintStrength,
    required this.glintSpeed,
    required this.glintPhase,
    required this.driftDir,
  });
}

class _MysticStarfieldPainter extends CustomPainter {
  final List<_StarN> starsN;
  final double t;
  final double driftPx;

  final double sizeMultiplier;
  final bool enableGlow;

  _MysticStarfieldPainter({
    required this.starsN,
    required this.t,
    required this.driftPx,
    required this.sizeMultiplier,
    required this.enableGlow,
  });

  double _clamp01(double x) => x.clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    final paint = Paint()..isAntiAlias = true;
    final tt = t * pi * 2;

    for (final s in starsN) {
      final cx0 = s.nx * size.width;
      final cy0 = s.ny * size.height;

      final dx = driftPx == 0
          ? 0.0
          : (s.driftDir.dx * driftPx * sin(tt * 0.32 + s.phase));
      final dy = driftPx == 0
          ? 0.0
          : (s.driftDir.dy * driftPx * cos(tt * 0.30 + s.phase));

      final cx = cx0 + dx;
      final cy = cy0 + dy;

      final wave = sin(tt * s.twinkleSpeed + s.phase);
      final tw = _clamp01(wave * 0.5 + 0.5);

      double glint = 0.0;
      if (s.glintStrength > 0.0) {
        final g = sin(tt * s.glintSpeed + s.glintPhase);
        final gp = max(0.0, g);
        glint = pow(gp, 6).toDouble() * s.glintStrength;
      }

      final opacity =
          (s.baseOpacity + s.twinkleAmp * tw + glint * 0.70).clamp(0.05, 1.0);

      final scale = (1.20 + 0.12 * tw + 0.32 * glint).clamp(1.0, 1.90);

      // ✅ THIS is the real final size
      final rr = (s.radius * scale * 60.0).clamp(0.8, 9999.0);


      // ✅ Mystic glow: big soft halo behind the core
      if (enableGlow) {
        final glowOpacity = (opacity * 0.22).clamp(0.03, 0.22);
        paint.color = Colors.white.withOpacity(glowOpacity);
        canvas.drawCircle(Offset(cx, cy), rr * 2.2, paint);
      }

      // ✅ Core star
      paint.color = Colors.white.withOpacity(opacity);

      if (s.isSquare) {
        final rect = Rect.fromCenter(
          center: Offset(cx, cy),
          width: rr * 1.15,
          height: rr * 1.15,
        );
        canvas.drawRect(rect, paint);
      } else {
        canvas.drawCircle(Offset(cx, cy), rr, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MysticStarfieldPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.driftPx != driftPx ||
        oldDelegate.sizeMultiplier != sizeMultiplier ||
        oldDelegate.enableGlow != enableGlow ||
        oldDelegate.starsN != starsN;
  }
}
