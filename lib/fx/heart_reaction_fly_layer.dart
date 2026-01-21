import 'dart:math';
import 'package:flutter/material.dart';

class HeartReactionFlyLayer extends StatefulWidget {
  final Widget child;

  const HeartReactionFlyLayer({super.key, required this.child});

  static _HeartReactionFlyLayerState of(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_HeartReactionFlyLayerState>();
    assert(state != null, 'HeartReactionFlyLayer not found in tree');
    return state!;
  }

  @override
  State<HeartReactionFlyLayer> createState() =>
      _HeartReactionFlyLayerState();
}

class _HeartReactionFlyLayerState extends State<HeartReactionFlyLayer>
    with TickerProviderStateMixin {
  final List<_FlyingHeart> _hearts = [];

  void spawnHeart({required Color color}) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    final heart = _FlyingHeart(
      controller: controller,
      color: color,
    );

    setState(() => _hearts.add(heart));

    controller.forward().whenComplete(() {
      setState(() => _hearts.remove(heart));
      controller.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          child: Stack(
            children: _hearts.map((h) {
              return AnimatedBuilder(
                animation: h.controller,
                builder: (_, __) {
                  final t = h.controller.value;

                  // 🔵 חצי עיגול
                  final radius = size.width * 0.35;
                  final angle = pi * t;

                  final startX = size.width / 2;
                  final startY = size.height / 2;

                  final dx = cos(angle) * radius;
                  final dy = sin(angle) * radius;

                  final x = startX + dx;
                  final y = startY + dy + (t * size.height * 0.25);

                  final opacity = t < 0.7
                      ? 1.0
                      : (1.0 - ((t - 0.7) / 0.3)).clamp(0.0, 1.0);

                  return Positioned(
                    left: x,
                    top: y,
                    child: Opacity(
                      opacity: opacity,
                      child: ColorFiltered(
                        colorFilter:
                            ColorFilter.mode(h.color, BlendMode.srcIn),
                        child: Image.asset(
                          'assets/reactions/HeartReaction.png',
                          width: 28,
                          height: 28,
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _FlyingHeart {
  final AnimationController controller;
  final Color color;

  _FlyingHeart({required this.controller, required this.color});
}
