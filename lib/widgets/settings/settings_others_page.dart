import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/app_settings.dart';
import 'mystic_toggle.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';



class SettingsOthersPage extends StatefulWidget {
  const SettingsOthersPage({super.key});

  @override
  State<SettingsOthersPage> createState() => _SettingsOthersPageState();
}

class _SettingsOthersPageState extends State<SettingsOthersPage> {
  bool _textPush = true;
  bool _chatroomPush = true;
  bool _touchEffect = true;
  Future<void> _savePushSettingsToFirestore() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'textPushEnabled': _textPush,
    'chatroomPushEnabled': _chatroomPush,
    'pushSettingsUpdatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
@override
void initState() {
  super.initState();
  _loadSettings();
}

Future<void> _loadSettings() async {
  final prefs = await SharedPreferences.getInstance();

  if (!mounted) return;

  setState(() {
    _textPush = prefs.getBool('text_push') ?? true;
    _chatroomPush = prefs.getBool('chatroom_push') ?? true;
    _touchEffect = prefs.getBool('touch_effect') ?? true;
  });
}
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
                left: 0,
                right: 0,
                top: 46,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
              MysticToggle(
  value: _textPush,
  onChanged: (value) async {
    setState(() {
      _textPush = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('text_push', value);
    AppSettings.textPushEnabled = value;
    await _savePushSettingsToFirestore();
  },
),

                    MysticToggle(
                      value: false,
                      onChanged: (_) {},
                    ),

        MysticToggle(
  value: _chatroomPush,
  onChanged: (value) async {
    setState(() {
      _chatroomPush = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('chatroom_push', value);
    AppSettings.chatroomPushEnabled = value;
    await _savePushSettingsToFirestore();
  },
),

                    MysticToggle(
                      value: false,
                      onChanged: (_) {},
                    ),
                  ],
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

SizedBox(
  width: 330,
  child: Stack(
    children: [
      Image.asset(
        'assets/ui/settings/others/EffectWindow.png',
        width: 330,
      ),

      Positioned(
        left: 132,
        top: 46,
        child: MysticToggle(
  value: _touchEffect,
  onChanged: (value) async {
    setState(() {
      _touchEffect = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('touch_effect', value);
    AppSettings.touchEffectEnabled = value;
  },
),
      ),
    ],
  ),
),
      ],
    );
  }
}