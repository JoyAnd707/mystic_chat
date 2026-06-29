import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/bgm.dart';
import '../audio/sfx.dart';
import '../bots/daily_fact_bot.dart';
import '../dms/dms_screens.dart';
import '../firebase/push_service.dart';
import '../widgets/mystic_top_status_bar.dart';
import '../widgets/mystic_starfield.dart';
import 'chat_screen.dart';
import 'settings_menu.dart';
import 'gallery_screen.dart';



class MainMenuScreen extends StatefulWidget {
  final String currentUserId;

  const MainMenuScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  bool _botStarted = false;

  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  late final AnimationController _twinkleController;
  late final AnimationController _chatroomRingController;
  late final AnimationController _messagePulseController;
late final Animation<double> _messagePulse;
late final AnimationController _messageRingController;

  @override
  void initState() {
    super.initState();
    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _chatroomRingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
        _messagePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
    _messageRingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _messagePulse = Tween<double>(
      begin: 1.0,
      end: 1.045,
    ).animate(
      CurvedAnimation(
        parent: _messagePulseController,
        curve: Curves.easeInOut,
      ),
    );
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
    _twinkleController.dispose();
    _chatroomRingController.dispose();
    _messagePulseController.dispose();
    super.dispose();
  }


    String _dmRoomId(String a, String b) {
    final pair = [a, b]..sort();
    return 'dm_${pair[0]}_${pair[1]}';
  }

  String _lastReadKeyFor(String roomId) {
    return 'lastReadMs__${widget.currentUserId}__$roomId';
  }

  Stream<int> _unreadDmMessageCountStream() async* {
    final prefs = await SharedPreferences.getInstance();

    final others = dmUsers.values
        .where((u) => u.id != widget.currentUserId)
        .toList();

    await for (final snap in FirebaseFirestore.instance
        .collection('dm_rooms')
        .where('participants', arrayContains: widget.currentUserId)
        .snapshots()) {
      int totalUnreadMessages = 0;

      for (final u in others) {
        final roomId = _dmRoomId(widget.currentUserId, u.id);

        final matchingDocs = snap.docs.where((d) => d.id == roomId).toList();
        if (matchingDocs.isEmpty) continue;

        final data = matchingDocs.first.data();

        final int lastUpdatedMs =
            (data['lastUpdatedMs'] is int) ? data['lastUpdatedMs'] as int : 0;

        final String lastSenderId = (data['lastSenderId'] ?? '').toString();

        final int lastReadMs = prefs.getInt(_lastReadKeyFor(roomId)) ?? 0;

        final bool roomHasUnread =
            lastUpdatedMs > lastReadMs &&
            lastSenderId != widget.currentUserId;

        if (!roomHasUnread) continue;

        final messagesSnap = await FirebaseFirestore.instance
            .collection('dm_rooms')
            .doc(roomId)
            .collection('messages')
            .where('tsMs', isGreaterThan: lastReadMs)
            .get();

        for (final messageDoc in messagesSnap.docs) {
          final messageData = messageDoc.data();

          final String senderId = (messageData['senderId'] ?? '').toString();
          final String type = (messageData['type'] ?? 'text').toString();

          if (senderId == widget.currentUserId) continue;
          if (type == 'system') continue;

          totalUnreadMessages++;
        }
      }

      yield totalUnreadMessages;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
child: Stack(
  children: [
    Positioned.fill(
      child: Image.asset(
        'assets/backgrounds/StarsBG.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    ),

Positioned.fill(
  child: MysticStarTwinkleOverlay(
    animation: _twinkleController,
    starCount: 58,
    sizeMultiplier: 1.25,
  ),
),
Transform.scale(
  scale: 0.88,
  alignment: Alignment.topLeft,
  child: Stack(
    children: [
      Positioned(
        left: 185,
        top: 125,
        child: StreamBuilder<int>(
          stream: _unreadDmMessageCountStream(),
          builder: (context, snapshot) {
            final int unreadCount = snapshot.data ?? 0;

            return AnimatedMessageButton(
              unreadCount: unreadCount,
              pulseAnimation: _messagePulse,
              ringAnimation: _messageRingController,
              onTap: () {
                try {
                  Sfx.I.playEnterDmsMenu();
                } catch (_) {}

                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (_) => DmsListScreen(
                      currentUserId: widget.currentUserId,
                    ),
                  ),
                )
                    .then((_) {
                  if (mounted) setState(() {});
                });
              },
            );
          },
        ),
      ),
      Positioned(
        left: 8,
        top: 170,
        child: Stack(
          children: [
            Image.asset(
              'assets/ui/main_menu/MainMenuButtonRow.png',
              width: 72,
              fit: BoxFit.contain,
            ),
            Positioned(
              left: 0,
              top: 6,
              child: GestureDetector(
                onTap: () {
                  try {
                    Sfx.I.playMainMenuButtonRow();
                  } catch (_) {}

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GalleryScreen(
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 72,
                  height: 50,
                  color: Colors.white.withOpacity(0.45),
                ),
              ),
            ),
          ],
        ),
      ),
      Positioned(
        left: 100,
        top: 235,
        child: DecoyCircleMenuButton(
          ringAnimation: _messageRingController,
          imagePath: 'assets/ui/main_menu/EmailDecoyButton.png',
        ),
      ),
      Positioned(
        left: 270,
        top: 255,
        child: DecoyCircleMenuButton(
          ringAnimation: _messageRingController,
          imagePath: 'assets/ui/main_menu/CallDecoyButton.png',
        ),
      ),
Positioned(
  left: 120,
  top: 500,
  child: AnimatedChatroomButton(
    ringAnimation: _chatroomRingController,
    onTap: () {
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
  ),
),
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
    ],
  ),
),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MysticTopStatusBar(now: _now),

const SizedBox(height: 10),

                  const SizedBox(height: 215),

                  const SizedBox(height: 12),

const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class AnimatedChatroomButton extends StatelessWidget {
  final Animation<double> ringAnimation;
  final VoidCallback onTap;

  const AnimatedChatroomButton({
    super.key,
    required this.ringAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 265,
      height: 265,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 232,
              height: 232,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00EEDB).withOpacity(0.10),
                    blurRadius: 14,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/ui/main_menu/chatroom/GreenBlueCircle.png',
              width: 228,
              height: 228,
              fit: BoxFit.contain,
            ),
            RotationTransition(
              turns: ringAnimation,
              child: Image.asset(
                "assets/ui/main_menu/chatroom/Atsushi'sFundraisingAssociation.png",
                width: 220,
                height: 220,
                fit: BoxFit.contain,
              ),
            ),
            Image.asset(
              'assets/ui/main_menu/chatroom/ChatroomButton.png',
              width: 170,
              height: 170,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedMessageButton extends StatelessWidget {
  final int unreadCount;
  final Animation<double> pulseAnimation;
  final Animation<double> ringAnimation;
  final VoidCallback onTap;

  const AnimatedMessageButton({
    super.key,
    required this.unreadCount,
    required this.pulseAnimation,
    required this.ringAnimation,
    required this.onTap,
  });

  bool get hasUnread => unreadCount > 0;

  @override
  Widget build(BuildContext context) {
    final Widget button = SizedBox(
      width: 112,
      height: 112,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (hasUnread)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00EEDB).withOpacity(0.18),
                      blurRadius: 14,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            RotationTransition(
              turns: ringAnimation,
              child: Image.asset(
                hasUnread
                    ? 'assets/ui/main_menu/DMS/NewMessgaeOuterRing.png'
                    : 'assets/ui/main_menu/DMS/MessgaeOuterRing.png',
                width: 104,
                height: 104,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            Image.asset(
              hasUnread
                  ? 'assets/ui/main_menu/DMS/MessageNew.png'
                  : 'assets/ui/main_menu/DMS/Message.png',
              width: 92,
              height: 92,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            if (hasUnread)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF5F73),
                    border: Border.all(
                      color: const Color(0xFFFFA6B2),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5F73).withOpacity(0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (!hasUnread) return button;

    return button;
  }
}

class DecoyCircleMenuButton extends StatelessWidget {
  final Animation<double> ringAnimation;
  final String imagePath;

  const DecoyCircleMenuButton({
    super.key,
    required this.ringAnimation,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: ringAnimation,
            child: Image.asset(
              'assets/ui/main_menu/DMS/MessgaeOuterRing.png',
              width: 108,
              height: 108,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          Image.asset(
            imagePath,
            width: 96,
            height: 96,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ],
      ),
    );
  }
}