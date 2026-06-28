import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static bool textPushEnabled = true;
  static bool chatroomPushEnabled = true;
  static bool touchEffectEnabled = true;

  static double bgmVolume = 0.7;
  static double sfxVolume = 0.7;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    textPushEnabled = prefs.getBool('text_push') ?? true;
    chatroomPushEnabled = prefs.getBool('chatroom_push') ?? true;
    touchEffectEnabled = prefs.getBool('touch_effect') ?? true;

    bgmVolume = prefs.getDouble('bgm_volume') ?? 0.7;
    sfxVolume = prefs.getDouble('sfx_volume') ?? 0.7;
  }
}