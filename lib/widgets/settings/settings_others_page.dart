import 'package:flutter/material.dart';
import 'mystic_toggle.dart';
class SettingsOthersPage extends StatelessWidget {
  const SettingsOthersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
   SizedBox(
  width: 330,
  child: Stack(
    children: [
      Image.asset(
        'assets/ui/settings/others/PushNotificationsWindow.png',
        width: 330,
      ),

Positioned(
  left: 28,
  top: 46,
  child: MysticToggle(
          value: true,
          onChanged: (_) {},
        ),
      ),
    ],
  ),
),

        const SizedBox(height: 12),

        Image.asset(
          'assets/ui/settings/others/RingtoneDecoyWindow.png',
          width: 330,
        ),

        const SizedBox(height: 12),

        Image.asset(
          'assets/ui/settings/others/MaxChatBubbleDecoy.png',
          width: 330,
        ),

        const SizedBox(height: 12),

        Image.asset(
          'assets/ui/settings/others/EffectWindow.png',
          width: 330,
        ),
      ],
    );
  }
}