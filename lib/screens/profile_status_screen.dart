import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/mystic_top_status_bar.dart';
import '../widgets/mystic_star_twinkle.dart';
import '../widgets/mystic_screen_top_bar.dart';

class ProfileStatusScreen extends StatefulWidget {
  final String currentUserId;
  final String profileUserId;

  const ProfileStatusScreen({
    super.key,
    required this.currentUserId,
    required this.profileUserId,
  });

  @override
  State<ProfileStatusScreen> createState() => _ProfileStatusScreenState();
}

class _ProfileStatusScreenState extends State<ProfileStatusScreen>
    with TickerProviderStateMixin {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  late final AnimationController _twinkleController;

  @override
  void initState() {
    super.initState();

    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;
        setState(() {
          _now = DateTime.now();
        });
      },
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _twinkleController.dispose();
    super.dispose();
  }

  String get _displayName {
    switch (widget.profileUserId) {
      case 'joy':
        return 'Joy';
      case 'adi':
        return 'Adi★';
      case 'danielle':
        return 'Danielle';
      case 'lera':
        return 'Lera';
      case 'lihi':
        return 'Lihi';
      case 'lian':
        return 'Lian';
      case 'tal':
        return 'Tal';
      case 'nella':
        return 'Nella';
      default:
        return widget.profileUserId;
    }
  }

  Color get _userColor {
    switch (widget.profileUserId) {
      case 'joy':
        return const Color(0xFF8E63FF);
      case 'adi':
        return const Color(0xFFFF7EBB);
      case 'danielle':
        return const Color(0xFF62C7FF);
      case 'lera':
        return const Color(0xFFFFA24A);
      case 'lihi':
        return const Color(0xFFFFE066);
      case 'lian':
        return const Color(0xFFFF5C5C);
      case 'tal':
        return const Color(0xFF74D66B);
      case 'nella':
        return const Color(0xFF36D8C8);
      default:
        return const Color(0xFF9A9A9A);
    }
  }

  String get _profileAssetPath {
    switch (widget.profileUserId) {
      case 'joy':
        return 'assets/ui/status/JoyNoStatus.png';
      case 'adi':
        return 'assets/ui/status/AdiNoStatus.png';
      case 'danielle':
        return 'assets/ui/status/DanielleNoStatus.png';
      case 'lera':
        return 'assets/ui/status/LeraNoStatus.png';
      case 'lihi':
        return 'assets/ui/status/LihiNoStatus.png';
      case 'lian':
        return 'assets/ui/status/LianNoStatus.png';
      case 'tal':
        return 'assets/ui/status/TalNoStatus.png';
      case 'nella':
        return 'assets/ui/status/NellaNoStatus.png';
      default:
        return 'assets/ui/status/JoyNoStatus.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color userColor = _userColor;

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
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: MysticTopStatusBar(now: _now),
                ),
                const SizedBox(height: 6),
          MysticScreenTopBar(
  title: 'Profile',
  onBack: () {
    Navigator.of(context).pop();
  },
),
                Expanded(
                  child: Stack(
                    children: [
Positioned(
  left: 0,
  right: 0,
  top: 0,
  height: 385,
  child: Container(
    color: Colors.white,
    child: const Center(
      child: Text(
        'Banner',
        style: TextStyle(
          fontFamily: 'Roboto',
          color: Colors.black54,
          fontSize: 34,
          fontWeight: FontWeight.w300,
        ),
      ),
    ),
  ),
),
Positioned(
  left: 0,
  right: 0,
  top: 382,
  bottom: 0,
  child: Container(
    color: userColor.withOpacity(0.38),
  ),
),
Positioned(
  left: 26,
  top: 300,
  child: Container(
    width: 145,
    height: 145,
    decoration: BoxDecoration(
      border: Border.all(
        color: userColor,
        width: 3,
      ),
    ),
    child: Image.asset(
      _profileAssetPath,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
    ),
  ),
),
Positioned(
  left: 195,
  right: 20,
  top: 385,
  child: Text(
    _displayName,
    style: const TextStyle(
      fontFamily: 'Roboto',
      color: Colors.white,
      fontSize: 31,
      fontWeight: FontWeight.w300,
      height: 1.0,
    ),
  ),
),
const Positioned(
  left: 38,
  right: 38,
  top: 560,
  child: Text(
    'Status text will appear here.',
    textAlign: TextAlign.center,
    style: TextStyle(
      fontFamily: 'Roboto',
      color: Colors.white,
      fontSize: 24,
      height: 1.25,
      fontWeight: FontWeight.w300,
    ),
  ),
),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
