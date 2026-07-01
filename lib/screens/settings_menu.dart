import 'package:flutter/material.dart';

import '../audio/sfx.dart';
import '../widgets/mystic_settings_top_status_bar.dart';
import '../widgets/mystic_title_bar.dart';
import '../widgets/settings/settings_others_page.dart';
import '../widgets/settings/settings_sound_sliders.dart';
import '../widgets/settings/settings_dm_notification_toggles.dart';
import '../main.dart';


import '../widgets/settings/settings_tabs.dart';
const bool kEnableDevReset = false;

class SettingsMenuScreen extends StatefulWidget {
  final String currentUserId;

  const SettingsMenuScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<SettingsMenuScreen> createState() => _SettingsMenuScreenState();
}

class _SettingsMenuScreenState extends State<SettingsMenuScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
children: [
  MysticSettingsTopStatusBar(
  now: DateTime.now(),
),
Padding(
  padding: const EdgeInsets.only(top: 8),
  child: Padding(
  padding: const EdgeInsets.only(top: 30),
  child: MysticTitleBar(
    title: 'Setting',
onBack: () async {
  try {
    Sfx.I.playBack();
  } catch (_) {}

  if (mounted) {
    Navigator.of(context).pop();
  }
},
  ),
),
),

  const SizedBox(height: 16),

SettingsTabs(
  selectedIndex: _selectedTab,
  onChanged: (index) {
    if (index != _selectedTab) {
      try {
        Sfx.I.playSettingsTabChange();
      } catch (_) {}
    }

    setState(() {
      _selectedTab = index;
    });
  },
),

            const SizedBox(height: 24),

Expanded(
  child: Align(
  alignment: Alignment.topCenter,
    child: switch (_selectedTab) {
0 => SizedBox(
  width: 270,
  child: Stack(
    children: [
      Image.asset(
        'assets/ui/settings/account/AccountSettingsDecoy.png',
        width: 270,
      ),
Positioned(
  right: 0,
  bottom: 0,
  child: GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: kEnableDevReset
        ? () async {
            await devReset(context);
          }
        : null,
    child: const SizedBox(
      width: 120,
      height: 65,
    ),
  ),
),
    ],
  ),
),
1 => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
SizedBox(
  width: 330,
  child: Stack(
    children: [
      Image.asset(
        'assets/ui/settings/sound/SoundAdjustWindow.png',
        width: 330,
      ),

      const Positioned.fill(
        child: SettingsSoundSliders(),
      ),
    ],
  ),
),
const SizedBox(height: 12),
SizedBox(
  width: 330,
  child: Stack(
    children: [
      Image.asset(
        'assets/ui/settings/sound/VoiceDecoy.png',
        width: 330,
      ),
      Positioned.fill(
        child: SettingsDmNotificationToggles(
          currentUserId: widget.currentUserId,
        ),
      ),
    ],
  ),
),
  ],
),
_ => const SettingsOthersPage(),
    },
  ),
),
          ],
        ),
      ),
    );
  }
}