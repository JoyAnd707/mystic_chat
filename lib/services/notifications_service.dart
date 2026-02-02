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
    final String title =
        message.notification?.title ?? message.data['title']?.toString() ?? 'New message';
    final String body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';

    // If server/FCM requested a channel, respect it. Otherwise use default.
    final String requestedChannel =
        message.notification?.android?.channelId ??
        message.data['android_channel_id']?.toString() ??
        channelMessages;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      requestedChannel,
      requestedChannel == channelHigh ? 'High priority chat' : 'Chat messages',
      importance: Importance.high,
      priority: Priority.high,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
