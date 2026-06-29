import 'package:flutter/material.dart';

class MysticScreenTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const MysticScreenTopBar({
    super.key,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const double barAspect = 2048 / 212;
        final double w = c.maxWidth;
        final double barH = w / barAspect;

        return SizedBox(
          width: w,
          height: barH,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/ui/DMSroomNameBar.png',
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBack,
                  child: const SizedBox(
                    width: 72,
                    height: double.infinity,
                  ),
                ),
              ),
              Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}