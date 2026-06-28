import 'package:shared_preferences/shared_preferences.dart';
import '../../services/app_settings.dart';
class AppSettings {
  static bool textPushEnabled = true;
  static bool chatroomPushEnabled = true;
  static bool touchEffectEnabled = true;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    textPushEnabled = prefs.getBool('text_push') ?? true;
    chatroomPushEnabled = prefs.getBool('chatroom_push') ?? true;
    touchEffectEnabled = prefs.getBool('touch_effect') ?? true;
  }
}