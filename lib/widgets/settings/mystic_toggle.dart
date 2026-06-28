import 'package:flutter/material.dart';

import '../../audio/sfx.dart';

class MysticToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const MysticToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        try {
          Sfx.I.playToggle();
        } catch (_) {}

        onChanged(!value);
      },
      child: SizedBox(
        width: 66,
        height: 24,
        child: Stack(
          children: [
            Positioned(
              left: 5,
              right: 5,
              top: 7,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: value
                        ? const Color(0xFF8FFFEF)
                        : const Color(0xFFD8D8D8),
                    width: 1.2,
                  ),
                ),
              ),
            ),
            Positioned(
              left: value ? 39 : 2,
              top: 3,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value
                      ? const Color(0xFF80EAD8)
                      : const Color(0xFFCFCFCF),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.85),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}