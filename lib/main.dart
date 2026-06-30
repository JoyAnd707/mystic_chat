import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dms/dms_screens.dart';
import 'screens/chat_screen.dart';
import '../fx/heart_reaction_fly_layer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase/auth_service.dart';
import '../fx/tap_sparkle_layer.dart';
import 'audio/sfx.dart';
import 'audio/bgm.dart';
import 'bots/daily_fact_bot.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase/push_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notifications_service.dart';
import 'firebase_options.dart';
import 'screens/main_menu.dart';
import 'services/app_settings.dart';


class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
  
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child; // no animation, no fade, no white flash
  }
}




/// =======================================
/// Mystic Chat — App Entry
/// =======================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationsService.instance.initForBackground();

  debugPrint(
    'BG FCM | hasNotification=${message.notification != null} | data=${message.data}',
  );

  if (message.notification != null) {
    return;
  }

  await NotificationsService.instance.showFromRemoteMessage(message);
}

Future<void> _enableImmersiveSticky() async {
  // Hide Android navigation bar + status bar until user swipes.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Optional: make bars transparent when they do appear (Android).
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
    await AppSettings.load();

  await NotificationsService.instance.init();


  try {
    await FirebaseFirestore.instance.collection('debug').doc('ping').set({
      'ok': true,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  } catch (e) {
    debugPrint('Firestore ping failed: $e');
  }

  await Hive.initFlutter();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await _enableImmersiveSticky();

  try {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.ambient,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      androidWillPauseWhenDucked: false,
    ));
  } catch (e) {
    debugPrint('AudioSession configure failed: $e');
  }

try {
  await Bgm.I.init();
  await Bgm.I.setVolume(AppSettings.bgmVolume);
} catch (e) {
  debugPrint('Bgm.init failed: $e');
}

try {
  await Sfx.I.init();
  await Sfx.I.setVolume(AppSettings.sfxVolume);
} catch (e) {
  debugPrint('Sfx.init failed: $e');
}

  runApp(const MysticChatApp());
}







/// Key used to store the chosen user id (first launch).
const String kPrefsCurrentUserId = 'currentUserId';

/// Names allowed on first launch.
/// Tip: we accept both "Adi" and "Adi★" etc.
const Map<String, String> allowedNameToId = {
  'Joy': 'joy',
  'Adi': 'adi',
  'Lian': 'lian',
  'Danielle': 'danielle',
  'Lera': 'lera',
  'Lihi': 'lihi',
  'Tal': 'tal',
  'Nella': 'nella',
};



class MysticChatApp extends StatefulWidget {
  const MysticChatApp({super.key});

  @override
  State<MysticChatApp> createState() => _MysticChatAppState();
}

class _MysticChatAppState extends State<MysticChatApp>
    with WidgetsBindingObserver {
  Future<String?> _loadSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(kPrefsCurrentUserId);
    if (id == null || id.trim().isEmpty) return null;
    return id;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // App is no longer in the foreground → stop audio
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      await Bgm.I.pause();
      await Sfx.I.stopAll();
      return;
    }

if (state == AppLifecycleState.resumed) {
  await _enableImmersiveSticky();
  await Bgm.I.resumeIfPossible();
}

  }

  @override
  Widget build(BuildContext context) {
return MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: const {
        TargetPlatform.android: _NoTransitionsBuilder(),
        TargetPlatform.iOS: _NoTransitionsBuilder(),
      },
    ),
  ),
builder: (context, child) {
  return HeartReactionFlyLayer(
    child: TapSparkleLayer(
      debugScale: 0.7,
      child: child ?? const SizedBox.shrink(),
    ),
  );
},

  home: FutureBuilder<String?>(
    future: _loadSavedUserId(),
    builder: (context, snapshot) {
      final savedId = snapshot.data;
      if (savedId == null) {
        return const UsernameScreen();
      }
     return MainMenuScreen(currentUserId: savedId);
    },
  ),
);


  }
}


const bool kEnableDevReset = false;
Future<void> devReset(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();

  // ✅ Remove current user (forces onboarding again)
  await prefs.remove(kPrefsCurrentUserId);

  // OPTIONAL: uncomment only if you want to wipe all chats too
  // await Hive.deleteFromDisk();

  if (!context.mounted) return;

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const MysticChatApp()),
    (route) => false,
  );
}


/// =======================================
/// First-launch: Username → User ID
/// =======================================

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}


class _UsernameScreenState extends State<UsernameScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedUserId;
  bool _isConnecting = false;

  late final AnimationController _glowController;

  static const Color _turquoise = Color(0xFF6FE7F7);
  static const Color _turquoiseLight = Color(0xFFA7F5FF);
  static const Color _turquoiseDark = Color(0xFF2CB9D3);

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _submitSelectedUser() async {
    final userId = _selectedUserId;

    if (userId == null || _isConnecting) {
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kPrefsCurrentUserId, userId);

      await AuthService.ensureSignedIn(currentUserId: userId);
      await PushService.initAndSaveToken(appUserId: userId);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainMenuScreen(currentUserId: userId),
        ),
      );
    } catch (e) {
      debugPrint('UsernameScreen submit failed: $e');

      if (!mounted) return;

      setState(() {
        _isConnecting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection failed. Please try again.'),
          backgroundColor: Color(0xFF063846),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = allowedNameToId.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const _MysticOnboardingBackground(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      final glow = 0.35 + (_glowController.value * 0.35);

                      return Container(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _turquoiseLight.withOpacity(0.35),
                            width: 1,
                          ),
                          color: const Color(0xFF061522).withOpacity(0.78),
                          boxShadow: [
                            BoxShadow(
                              color: _turquoise.withOpacity(glow),
                              blurRadius: 30,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: Column(
                      children: [
                        const Text(
                          'MysticMeowssenger',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 31,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            shadows: [
                              Shadow(
                                color: Color(0xAA6FE7F7),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This device has not been linked yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.74),
                            fontSize: 14,
                            height: 1.25,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose your identity to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _turquoiseLight.withOpacity(0.72),
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: users.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.75,
                      ),
                      itemBuilder: (context, index) {
                        final name = users[index].key;
                        final userId = users[index].value;
                        final selected = _selectedUserId == userId;

                        return _MysticUserCard(
                          name: name,
                          selected: selected,
                          turquoise: _turquoise,
                          turquoiseLight: _turquoiseLight,
                          onTap: () {
                            if (_isConnecting) return;

                            setState(() {
                              _selectedUserId = userId;
                            });
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  _MysticContinueButton(
                    enabled: _selectedUserId != null && !_isConnecting,
                    isLoading: _isConnecting,
                    turquoise: _turquoise,
                    turquoiseLight: _turquoiseLight,
                    turquoiseDark: _turquoiseDark,
                    onTap: _submitSelectedUser,
                  ),
                ],
              ),
            ),
          ),

          if (_isConnecting)
            Container(
              color: Colors.black.withOpacity(0.42),
              child: Center(
                child: Container(
                  width: 230,
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF061522).withOpacity(0.96),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _turquoise.withOpacity(0.55),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _turquoise.withOpacity(0.35),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: _turquoise,
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Connecting...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Preparing your chat.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MysticOnboardingBackground extends StatelessWidget {
  const _MysticOnboardingBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF020811),
                  Color(0xFF062236),
                  Color(0xFF063846),
                  Color(0xFF02050A),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _MysticStarPainter(),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.25),
                radius: 0.88,
                colors: [
                  const Color(0xFF6FE7F7).withOpacity(0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MysticStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final smallStarPaint = Paint()
      ..color = Colors.white.withOpacity(0.42)
      ..style = PaintingStyle.fill;

    final brightStarPaint = Paint()
      ..color = const Color(0xFFA7F5FF).withOpacity(0.78)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0xFF6FE7F7).withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final starPoints = <Offset>[
      Offset(size.width * 0.08, size.height * 0.08),
      Offset(size.width * 0.21, size.height * 0.15),
      Offset(size.width * 0.39, size.height * 0.07),
      Offset(size.width * 0.62, size.height * 0.13),
      Offset(size.width * 0.84, size.height * 0.09),
      Offset(size.width * 0.93, size.height * 0.20),
      Offset(size.width * 0.13, size.height * 0.28),
      Offset(size.width * 0.31, size.height * 0.31),
      Offset(size.width * 0.73, size.height * 0.29),
      Offset(size.width * 0.89, size.height * 0.39),
      Offset(size.width * 0.06, size.height * 0.48),
      Offset(size.width * 0.25, size.height * 0.56),
      Offset(size.width * 0.47, size.height * 0.49),
      Offset(size.width * 0.68, size.height * 0.58),
      Offset(size.width * 0.91, size.height * 0.61),
      Offset(size.width * 0.12, size.height * 0.72),
      Offset(size.width * 0.37, size.height * 0.77),
      Offset(size.width * 0.59, size.height * 0.70),
      Offset(size.width * 0.82, size.height * 0.79),
      Offset(size.width * 0.18, size.height * 0.91),
      Offset(size.width * 0.51, size.height * 0.88),
      Offset(size.width * 0.78, size.height * 0.93),
    ];

    for (var i = 0; i < starPoints.length; i++) {
      final point = starPoints[i];
      final radius = i % 4 == 0 ? 1.8 : 1.1;

      canvas.drawCircle(point, radius, smallStarPaint);

      if (i % 5 == 0) {
        canvas.drawCircle(point, 7, glowPaint);
        canvas.drawCircle(point, 2.3, brightStarPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MysticStarPainter oldDelegate) {
    return false;
  }
}

class _MysticUserCard extends StatelessWidget {
  const _MysticUserCard({
    required this.name,
    required this.selected,
    required this.turquoise,
    required this.turquoiseLight,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final Color turquoise;
  final Color turquoiseLight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      scale: selected ? 1.035 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: selected
                  ? turquoise.withOpacity(0.22)
                  : const Color(0xFF061522).withOpacity(0.78),
              border: Border.all(
                color: selected
                    ? turquoiseLight.withOpacity(0.95)
                    : turquoise.withOpacity(0.18),
                width: selected ? 1.6 : 1,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: turquoise.withOpacity(0.45),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? turquoiseLight.withOpacity(0.95)
                        : turquoise.withOpacity(0.62),
                    boxShadow: [
                      BoxShadow(
                        color: turquoise.withOpacity(0.40),
                        blurRadius: 13,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name.characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(selected ? 1.0 : 0.84),
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: selected ? 1 : 0,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: turquoiseLight,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MysticContinueButton extends StatelessWidget {
  const _MysticContinueButton({
    required this.enabled,
    required this.isLoading,
    required this.turquoise,
    required this.turquoiseLight,
    required this.turquoiseDark,
    required this.onTap,
  });

  final bool enabled;
  final bool isLoading;
  final Color turquoise;
  final Color turquoiseLight;
  final Color turquoiseDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.42,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: enabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      turquoiseLight,
                      turquoise,
                      turquoiseDark,
                    ],
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.10),
                      Colors.white.withOpacity(0.07),
                    ],
                  ),
            boxShadow: [
              if (enabled)
                BoxShadow(
                  color: turquoise.withOpacity(0.38),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Center(
            child: Text(
              isLoading ? 'Connecting' : 'Continue',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}