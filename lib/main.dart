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
  } catch (e) {
    debugPrint('Bgm.init failed: $e');
  }

  try {
    await Sfx.I.init();
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

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  String? _resolveUserId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Case-insensitive match against allowed names
    for (final entry in allowedNameToId.entries) {
      if (entry.key.toLowerCase() == trimmed.toLowerCase()) {
        return entry.value;
      }
    }
    return null;
  }

Future<void> _submit() async {
  final userId = _resolveUserId(_controller.text);
  if (userId == null) {
    setState(() => _error = 'שם לא נמצא ברשימה. נסי שוב בדיוק כמו שמופיע.');
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(kPrefsCurrentUserId, userId);

  // 1) ✅ Sign in anonymously + save mapping users/<uid>
  await AuthService.ensureSignedIn(currentUserId: userId);

  // 2) ✅ Ask permission + get FCM token + save it into users/<uid>.fcmTokens
  await PushService.initAndSaveToken(appUserId: userId);

  if (!mounted) return;

  // 3) ✅ Now navigate
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => MainMenuScreen(currentUserId: userId),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final allowedNames = allowedNameToId.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 18),
              const Text(
                'כתבי את השם שלך (חד-פעמי)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 22),

              TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  hintText: 'לדוגמה: Joy',
                  hintStyle: const TextStyle(color: Colors.white38),
                  errorText: _error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('המשך'),
              ),

              const SizedBox(height: 18),
              const Text(
                'שמות אפשריים:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final name in allowedNames)
                        Chip(
                          label: Text(name),
                          labelStyle: const TextStyle(color: Colors.white),
                          backgroundColor: const Color(0xFF2A2A2A),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



