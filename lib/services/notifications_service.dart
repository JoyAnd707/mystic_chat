import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

// Channel ids (v2 so Android actually applies new sound settings)
static const String channelDm = 'dm_messages_v2';
static const String channelGroup = 'group_messages_v2';
static const String channelHigh = 'chat_high_v2';


  Future<void> init() async {
    await _initLocalPlugin();
    await _createAndroidChannels();
    await _requestPermissionsIfNeeded();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint(
        'FG FCM | hasNotification=${message.notification != null} | data=${message.data}',
      );
      await showFromRemoteMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened: ${message.messageId}');
    });
  }

  /// Call this inside background handler isolate
  Future<void> initForBackground() async {
    await _initLocalPlugin();
    await _createAndroidChannels();
  }

  Future<void> _initLocalPlugin() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);

    await _local.initialize(initSettings);
  }

Future<void> _createAndroidChannels() async {
  final androidPlugin = _local.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin == null) return;

  // file: android/app/src/main/res/raw/notification_sfx.ogg
  const sound = RawResourceAndroidNotificationSound('notification_sfx');

  const AndroidNotificationChannel dm = AndroidNotificationChannel(
    channelDm,
    'DM messages',
    description: 'Direct messages notifications',
    importance: Importance.high,
    playSound: true,
    sound: sound,
    enableVibration: true,
  );

  const AndroidNotificationChannel group = AndroidNotificationChannel(
    channelGroup,
    'Chatroom messages',
    description: 'Group chat notifications',
    importance: Importance.high,
    playSound: true,
    sound: sound,
    enableVibration: true,
  );

  const AndroidNotificationChannel high = AndroidNotificationChannel(
    channelHigh,
    'High priority chat',
    description: 'High priority notifications',
    importance: Importance.high,
    playSound: true,
    sound: sound,
    enableVibration: true,
  );

  await androidPlugin.createNotificationChannel(dm);
  await androidPlugin.createNotificationChannel(group);
  await androidPlugin.createNotificationChannel(high);
}

  Future<void> _requestPermissionsIfNeeded() async {
    if (kIsWeb) return;

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Notification permission: ${settings.authorizationStatus}');

    if (Platform.isAndroid) {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

Future<void> showFromRemoteMessage(RemoteMessage message) async {
  // We prefer data fields for chat formatting
  final String sender =
      message.data['sender']?.toString() ??
      message.notification?.title ??
      'New message';

  final String msgText =
      message.data['body']?.toString() ??
      message.notification?.body ??
      '';

  // If truly empty, don’t show (prevents "NEW MESSAGE" / empty notifications)
  if (sender.trim().isEmpty && msgText.trim().isEmpty) return;

  // kind: "dm" | "group"
  final String kind = (message.data['kind']?.toString() ?? 'group').toLowerCase();
  final bool isGroup = kind == 'group';

  // Title rules you asked:
  // DM: "ZEN"
  // Group: "ZEN (CHATROOM)"
  final String title = isGroup ? '$sender (CHATROOM)' : sender;

  // Body like the screenshot: "ZEN: message..."
  final String body = msgText.trim().isEmpty ? '' : '$sender: $msgText';

  // Channel selection
  final String channelId = isGroup ? channelGroup : channelDm;

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    channelId,
    isGroup ? 'Chatroom messages' : 'DM messages',
    channelDescription:
        isGroup ? 'Group chat notifications' : 'Direct messages notifications',
    importance: Importance.high,
    priority: Priority.high,
  );

  final NotificationDetails details = NotificationDetails(android: androidDetails);

  // Stable-ish id to reduce accidental duplicates
  final int notificationId =
      (message.messageId ?? DateTime.now().microsecondsSinceEpoch.toString()).hashCode;

  await _local.show(
    notificationId,
    title,
    body,
    details,
  );
}
Future<void> showTest({required bool isGroup}) async {
  final String sender = isGroup ? 'Yoosung★' : 'ZEN';
  final String msgText = isGroup ? 'group sound test' : 'sound test';

  final String title = isGroup ? '$sender (CHATROOM)' : sender;
  final String body = '$sender: $msgText';
  final String channelId = isGroup ? channelGroup : channelDm;

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    channelId,
    isGroup ? 'Chatroom messages' : 'DM messages',
    channelDescription:
        isGroup ? 'Group chat notifications' : 'Direct messages notifications',
    importance: Importance.high,
    priority: Priority.high,
  );

  final NotificationDetails details = NotificationDetails(android: androidDetails);

  await _local.show(
    DateTime.now().microsecondsSinceEpoch.hashCode,
    title,
    body,
    details,
  );
}


}
