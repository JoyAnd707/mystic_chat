import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../audio/bgm.dart';
import '../audio/sfx.dart';
import '../bots/daily_fact_bot.dart';
import '../dms/dms_screens.dart';
import '../firebase/push_service.dart';
import '../widgets/mystic_top_status_bar.dart';
import 'chat_screen.dart';
import 'settings_menu.dart';
import '../widgets/mystic_starfield.dart';




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
    super.dispose();
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

                  Center(
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
      width: 250,
      height: 250,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
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
              width: 214,
              height: 214,
              fit: BoxFit.contain,
            ),

            RotationTransition(
              turns: ringAnimation,
              child: Image.asset(
  "assets/ui/main_menu/chatroom/Atsushi'sFundraisingAssociation.png",
                width: 202,
                height: 202,
                fit: BoxFit.contain,
              ),
            ),

            Image.asset(
              'assets/ui/main_menu/chatroom/ChatroomButton.png',
              width: 154,
              height: 154,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

class _RotatingChatroomOuterRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);

    final Paint blackRing = Paint()
      ..color = Colors.black.withOpacity(0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 23;

    final Paint whiteRing = Paint()
      ..color = Colors.white.withOpacity(0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final Paint tealRing = Paint()
      ..color = const Color(0xFF11DAD0).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, 92, blackRing);
    canvas.drawCircle(center, 104, whiteRing);
    canvas.drawCircle(center, 80, whiteRing);
    canvas.drawCircle(center, 107, tealRing);

    final textPainter = TextPainter(
      text: TextSpan(
        text: "Rika's Fundraising Association",
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 2);

    final double radius = 92;
    final String text = "Rika's Fundraising Association";

    double angle = -1.88;

    for (int i = 0; i < text.length; i++) {
      final String char = text[i];

      final charPainter = TextPainter(
        text: TextSpan(
          text: char,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final double charAngle = angle + (i * 0.075);

      canvas.save();
      canvas.rotate(charAngle);
      canvas.translate(0, -radius);
      canvas.rotate(math.pi / 2);
      charPainter.paint(
        canvas,
        Offset(
          -charPainter.width / 2,
          -charPainter.height / 2,
        ),
      );
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _StaticChatroomInnerRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);

    final Paint whiteThin = Paint()
      ..color = Colors.white.withOpacity(0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final Paint grayThin = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, 84, whiteThin);
    canvas.drawCircle(center, 63, grayThin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}