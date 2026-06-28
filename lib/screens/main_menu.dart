import 'dart:async';

import 'package:flutter/material.dart';

import '../audio/bgm.dart';
import '../audio/sfx.dart';
import '../bots/daily_fact_bot.dart';
import '../dms/dms_screens.dart';
import '../firebase/push_service.dart';
import '../widgets/mystic_top_status_bar.dart';
import 'chat_screen.dart';
import 'settings_menu.dart';
import '../widgets/settings/settings_tabs.dart';


class MainMenuScreen extends StatefulWidget {
  final String currentUserId;

  const MainMenuScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _botStarted = false;

  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();

    _now = DateTime.now();

    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        setState(() {
          _now = DateTime.now();
        });
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_botStarted) return;
      _botStarted = true;

      await DailyFactBotScheduler.I.start();

      await Bgm.I.playHomeDm();

      await PushService.initAndSaveToken(appUserId: widget.currentUserId);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
Positioned(
  top: 30,
  right: 15,
  child: GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SettingsMenuScreen(
            currentUserId: widget.currentUserId,
          ),
        ),
      );
    },
    child: const SizedBox(
      width: 80,
      height: 80,
    ),
  ),
),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MysticTopStatusBar(now: _now),

                  const SizedBox(height: 10),

                  const Text(
                    'Mystic Chat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'בחרי מצב:',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 26),

       ElevatedButton(
  onPressed: () {
    try {
      Sfx.I.playEnterGroupChat();
    } catch (_) {}

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          currentUserId: widget.currentUserId,
          roomId: 'group_main',
          title: 'Group Chat',
          enableBgm: true,
        ),
      ),
    )
        .then((_) async {
      await Bgm.I.leaveGroupAndResumeHomeDm();
    });
  },
  child: const Text('Group Chat'),
),

                  const SizedBox(height: 12),

ElevatedButton(
  onPressed: () {
    try {
      Sfx.I.playEnterDmsMenu();
    } catch (_) {}

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DmsListScreen(
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  },
  child: const Text('DMs'),
),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}