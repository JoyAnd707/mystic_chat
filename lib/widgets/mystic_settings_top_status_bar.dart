import 'package:flutter/material.dart';

class MysticSettingsTopStatusBar extends StatelessWidget {
  final DateTime now;

  const MysticSettingsTopStatusBar({
    super.key,
    required this.now,
  });

@override
Widget build(BuildContext context) {
  return SizedBox(
    width: double.infinity,
    child: Image.asset(
      'assets/ui/TopBarSettings.png',
      fit: BoxFit.fitWidth,
      alignment: Alignment.topCenter,
    ),
  );
}
}