import 'dart:math';
import 'package:flutter/material.dart';
import '../audio/sfx.dart';
class SpaceSnackProgressBar extends StatefulWidget {
  const SpaceSnackProgressBar({
    super.key,
    this.width,
  });

  final double? width;

  @override
  State<SpaceSnackProgressBar> createState() => _SpaceSnackProgressBarState();
}

class _SpaceSnackProgressBarState extends State<SpaceSnackProgressBar>
    with TickerProviderStateMixin {
  late final AnimationController _shipController;
  late final AnimationController _readyController;

  static const String _barAssetPath =
      'assets/ui/main_menu/VideoProgressionBar.png';
  static const String _shipAssetPath = 'assets/ui/main_menu/Spaceship.png';
  static const String _doritosAssetPath = 'assets/ui/main_menu/Doritos.png';
  static const String _tapAssetPath = 'assets/ui/main_menu/Tap.png';
  static const String _rewardMenuAssetPath =
      'assets/ui/main_menu/RewardsMenu.png';

  bool _rewardReady = false;
  bool _claimingReward = false;

  @override
  void initState() {
    super.initState();

    _shipController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _readyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _shipController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _rewardReady = true;
        });
      }
    });

    _shipController.forward();
  }

  @override
  void dispose() {
    _shipController.dispose();
    _readyController.dispose();
    super.dispose();
  }

  double _wave(double t, double speed, double phase) {
    return sin((t * speed * pi * 2) + phase);
  }

  Future<void> _claimReward() async {
    if (!_rewardReady || _claimingReward) return;

    setState(() {
      _claimingReward = true;
    });

    final Random random = Random();
    final int hearts = 3 + random.nextInt(18);
    final int hourglasses = random.nextInt(4);

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Doritos reward',
      barrierColor: Colors.black.withOpacity(0.72),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _DoritosRewardOverlay(
          doritosAssetPath: _doritosAssetPath,
          rewardMenuAssetPath: _rewardMenuAssetPath,
          hearts: hearts,
          hourglasses: hourglasses,
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _rewardReady = false;
      _claimingReward = false;
    });

    _shipController.reset();
    _shipController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final double fullWidth = widget.width ?? MediaQuery.of(context).size.width;

    return SizedBox(
      width: fullWidth,
      height: 82,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 18,
            right: 55,
            top: 18,
            child: AspectRatio(
              aspectRatio: 2048 / 224,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double w = constraints.maxWidth;
                  final double h = constraints.maxHeight;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          _barAssetPath,
                          fit: BoxFit.fitWidth,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _shipController,
                        builder: (context, _) {
                          final double t = _shipController.value;

                          final double forwardProgress = t;

                          final double backAndForth = _rewardReady
                              ? 0.0
                              : (_wave(t, 3.0, 0.7) * 0.035) +
                                  (_wave(t, 7.0, 2.1) * 0.014);

                          final double visualProgress = _rewardReady
    ? 1.11
    : (forwardProgress + backAndForth).clamp(0.0, 1.0);

                          final double x = visualProgress * (w - 46);

                          final double pathY =
                              (h * 0.48) + (h * 0.12 * (0.5 - visualProgress));

                          final double bobY = _rewardReady
                              ? 0.0
                              : (_wave(t, 11.0, 0.2) * 4.5) +
                                  (_wave(t, 17.0, 1.4) * 2.0);

                          final double driftX = _rewardReady
                              ? 0.0
                              : _wave(t, 13.0, 0.9) * 3.0;

                          final double tilt = _rewardReady
                              ? 0.0
                              : (_wave(t, 5.0, 0.4) * 0.13) +
                                  (_wave(t, 9.0, 2.0) * 0.06);

                          return Positioned(
                            left: x + driftX,
                            top: _rewardReady
    ? pathY - 34
    : pathY + bobY - 20,
                            child: Transform.rotate(
                              angle: tilt,
                              child: Image.asset(
                                _shipAssetPath,
                                width: 46,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          Positioned(
            right: 10,
            top: 14,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
             onTap: () async {
  Sfx.I.playBack();
  _claimReward();
},
      child: AnimatedBuilder(
  animation: _readyController,
  builder: (context, _) {
    final double t = _readyController.value;
                  final double snackShiftX =
    (_rewardReady && !_claimingReward) ? sin(t * pi * 2) * 2.5 : 0.0;

                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      if (_rewardReady)
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD34D).withOpacity(
                                  0.35 + (0.25 * t),
                                ),
                                blurRadius: 18 + (8 * t),
                                spreadRadius: 2 + (2 * t),
                              ),
                            ],
                          ),
                        ),
                      Transform.translate(
                        offset: Offset(snackShiftX, 0),
                        child: Image.asset(
                          _doritosAssetPath,
                          width: 52,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                      ),
   
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoritosRewardOverlay extends StatefulWidget {
  final String doritosAssetPath;
  final String rewardMenuAssetPath;
  final int hearts;
  final int hourglasses;
  final VoidCallback onClose;

  const _DoritosRewardOverlay({
    required this.doritosAssetPath,
    required this.rewardMenuAssetPath,
    required this.hearts,
    required this.hourglasses,
    required this.onClose,
  });

  @override
  State<_DoritosRewardOverlay> createState() => _DoritosRewardOverlayState();
}

class _DoritosRewardOverlayState extends State<_DoritosRewardOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _startedOpening = false;
bool _showRewardMenu = false;

  final List<String> _sarcasticMessages = const [
    'Congratulations. You touched a bag.',
    'Five hours later, and this is your legacy.',
    'The snack economy has chosen mercy.',
    'Wow. Productivity is trembling.',
    'A suspicious bag has rewarded your patience.',
    'You may now continue pretending this was worth it.',
  ];

  late final String _message;

  @override
  void initState() {
    super.initState();

    _message = _sarcasticMessages[Random().nextInt(_sarcasticMessages.length)];

_controller = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 3000),
);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
void _startOpening() {
  if (_startedOpening) return;

  setState(() {
    _startedOpening = true;
  });

  _controller.forward();

  Future.delayed(const Duration(milliseconds: 3000), () {
    if (!mounted) return;

    setState(() {
      _showRewardMenu = true;
    });
  });
}
  double _wave(double t, double speed, double phase) {
    return sin((t * speed * pi * 2) + phase);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _showRewardMenu ? _rewardMenu() : _openingDoritos(),
        ),
      ),
    );
  }

Widget _openingDoritos() {
  return AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final double t = _controller.value;

      final double doritosX =
          _startedOpening ? 7 * _wave(t, 4.0, 0.0) : 0.0;

      Widget cloud({
        required String asset,
        required double width,
        required double left,
        required double top,
        required double xPower,
        required double yPower,
        required double speed,
        required double phase,
      }) {
        final double x =
            _startedOpening ? _wave(t, speed, phase) * xPower : 0.0;
        final double y =
            _startedOpening ? _wave(t, speed * 0.8, phase + 1.2) * yPower : 0.0;

        return Positioned(
          left: left + x,
          top: top + y,
          child: Image.asset(
            asset,
            width: width,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        );
      }

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () async {
  Sfx.I.playBack();
  _startOpening();
},
        child: SizedBox(
          width: 310,
          height: 300,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
children: [
  Transform.translate(
    offset: Offset(doritosX, 0),
    child: Image.asset(
      widget.doritosAssetPath,
      width: 245,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    ),
  ),
if (!_startedOpening)
  Positioned(
    right: -18,
    top: -38,
    child: Transform.rotate(
      angle: 0.28,
      child: const Image(
        image: AssetImage('assets/ui/main_menu/Tap.png'),
        width: 120,
        filterQuality: FilterQuality.high,
      ),
    ),
  ),
if (_startedOpening)
  cloud(
    asset: 'assets/ui/main_menu/Cloud1.png',
    width: 125,
    left: -18,
    top: 52,
    xPower: 12,
    yPower: 9,
    speed: 3.8,
    phase: 0.3,
  ),

if (_startedOpening)
  cloud(
    asset: 'assets/ui/main_menu/Cloud2.png',
    width: 100,
    left: 185,
    top: 20,
    xPower: 14,
    yPower: 11,
    speed: 4.8,
    phase: 1.4,
  ),

if (_startedOpening)
  cloud(
    asset: 'assets/ui/main_menu/Cloud3.png',
    width: 80,
    left: 18,
    top: 188,
    xPower: 16,
    yPower: 12,
    speed: 5.4,
    phase: 2.2,
  ),

if (_startedOpening)
  cloud(
    asset: 'assets/ui/main_menu/Cloud4.png',
    width: 120,
    left: 170,
    top: 170,
    xPower: 13,
    yPower: 13,
    speed: 4.2,
    phase: 3.1,
  ),

if (_startedOpening)
  cloud(
    asset: 'assets/ui/main_menu/Cloud5.png',
    width: 115,
    left: 82,
    top: -28,
    xPower: 18,
    yPower: 15,
    speed: 5.9,
    phase: 4.0,
  ),
],
          ),
        ),
      );
    },
  );
}

Widget _rewardMenu() {
  return SizedBox(
    width: 350,
    child: Stack(
  clipBehavior: Clip.none,
  children: [
        Image.asset(
          widget.rewardMenuAssetPath,
          width: 350,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),

    Positioned(
  left: 36,
  right: 36,
  top: 26,
          child: Text(
            _message,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
style: const TextStyle(
  fontFamily: 'NanumGothic.ttf',
  color: Colors.white,
  fontSize: 13,
  height: 1.12,
),
          ),
        ),

     Positioned(
  left: 142,
  top: 88,
          child: Text(
            widget.hearts.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ),

      Positioned(
  left: 290,
  top: 88,
          child: Text(
            widget.hourglasses.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ),

        Positioned(
          left: 116,
          right: 116,
          bottom: 38,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () async {
  Sfx.I.playBack();
  widget.onClose();
},
            child: const SizedBox(
              height: 42,
            ),
          ),
        ),
      ],
    ),
  );
}
}