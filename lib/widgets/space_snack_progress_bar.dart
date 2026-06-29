import 'package:flutter/material.dart';

class SpaceSnackProgressBar extends StatelessWidget {
  const SpaceSnackProgressBar({
    super.key,
    this.width,
  });

  final double? width;

  static const String _assetPath =
      'assets/ui/main_menu/VideoProgressionBar.png';

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
  width: width ?? MediaQuery.of(context).size.width,
  margin: const EdgeInsets.only(
  left: 30,
  right: 55,
),
        height: 60,
        color: Colors.red.withOpacity(0.35),
        child: Image.asset(
          _assetPath,
          fit: BoxFit.fitWidth,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) {
            return const Center(
              child: Text(
                'VideoProgressionBar asset not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }
}