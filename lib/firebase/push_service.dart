// lib/firebase/push_service.dart
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushService {
  PushService._();

  static final FirebaseMessaging _msg = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static bool _tokenRefreshListenerStarted = false;

  static Future<void> initAndSaveToken({
    required String appUserId,
  }) async {
    try {
      final settings = await _msg.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('Push permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('Push permission denied.');
        return;
      }

      await _tryGetAndSaveToken(appUserId: appUserId);

      if (!_tokenRefreshListenerStarted) {
        _tokenRefreshListenerStarted = true;

        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          if (newToken.isEmpty) return;

          await _saveToken(
            token: newToken,
            appUserId: appUserId,
          );
        });
      }
    } catch (e) {
      print('PushService.initAndSaveToken skipped due to error: $e');
    }
  }

  static Future<void> _tryGetAndSaveToken({
    required String appUserId,
  }) async {
    for (int attempt = 1; attempt <= 30; attempt++) {
      try {
        if (Platform.isIOS) {
          final apnsToken = await _msg.getAPNSToken();
          print('APNS TOKEN attempt $attempt = $apnsToken');

          if (apnsToken == null || apnsToken.isEmpty) {
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
        }

        final token = await _msg.getToken();
        print('FCM TOKEN = $token');

        if (token == null || token.isEmpty) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }

        await _saveToken(
          token: token,
          appUserId: appUserId,
        );

        return;
      } catch (e) {
        print('Token attempt $attempt failed: $e');
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    print('Could not get push token after retries.');
  }

  static Future<void> _saveToken({
    required String token,
    required String appUserId,
  }) async {
    print('Saving token...');

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print('No Firebase Auth user. Cannot save FCM token.');
      return;
    }

    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'appUserId': appUserId,
      'platform': Platform.isAndroid ? 'android' : 'ios',
      'updatedAt': FieldValue.serverTimestamp(),
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));

    print('FCM token saved for $appUserId');
  }
}