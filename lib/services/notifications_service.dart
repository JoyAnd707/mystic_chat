import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  // Channel ids
  static const String channelMessages = 'chat_messages';
  static const String channelHigh = 'chat_high';

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

    const AndroidNotificationChannel ch1 = AndroidNotificationChannel(
      channelMessages,
      'Chat messages',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
    );

    const AndroidNotificationChannel ch2 = AndroidNotificationChannel(
      channelHigh,
      'High priority chat',
      description: 'High priority notifications',
      importance: Importance.high,
    );

    await androidPlugin.createNotificationChannel(ch1);
    await androidPlugin.createNotificationChannel(ch2);
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
  final String? title = message.notification?.title ?? message.data['title']?.toString();
  final String? body = message.notification?.body ?? message.data['body']?.toString();

  // ✅ אם אין שום תוכן אמיתי — לא מציגים בכלל.
  // זה מונע "NEW MESSAGE" / התראות ריקות.
  final bool hasTitle = title != null && title.trim().isNotEmpty;
  final bool hasBody = body != null && body.trim().isNotEmpty;
  if (!hasTitle && !hasBody) return;

  // ✅ תני title נורמלי אם יש רק body
  final String safeTitle = hasTitle ? title!.trim() : 'New message';
  final String safeBody = hasBody ? body!.trim() : '';

  // ✅ משתמשים רק בערוצים שאת יצרת, לא בערוצים אקראיים שמגיעים מ-FCM.
  final String rawRequestedChannel =
      message.notification?.android?.channelId ??
      message.data['android_channel_id']?.toString() ??
      channelMessages;

  final String channelId =
      (rawRequestedChannel == channelHigh || rawRequestedChannel == channelMessages)
          ? rawRequestedChannel
          : channelMessages;

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    channelId,
    channelId == channelHigh ? 'High priority chat' : 'Chat messages',
    channelDescription: channelId == channelHigh
        ? 'High priority notifications'
        : 'Notifications for new chat messages',
    importance: Importance.high,
    priority: Priority.high,
  );

  final NotificationDetails details = NotificationDetails(android: androidDetails);

  // ✅ ID יציב יותר (עדיף על זמן בשניות) כדי להקטין כפילויות
  final int notificationId =
      (message.messageId ?? DateTime.now().microsecondsSinceEpoch.toString()).hashCode;

  await _local.show(
    notificationId,
    safeTitle,
    safeBody,
    details,
  );
}

}
