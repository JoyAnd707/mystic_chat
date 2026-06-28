import 'package:flutter/material.dart';

class MysticSettingsTopStatusBar extends StatelessWidget {
  final DateTime now;

  const MysticSettingsTopStatusBar({
    super.key,
    required this.now,
  });
@override
Widget build(BuildContext context) {
  return Stack(
    children: [
      Image.asset(
        'assets/ui/TopBarSettings.png',
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
      ),

      Positioned(
        left: 22,
        top: 8,
        child: Text(
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    ],
  );
}
}