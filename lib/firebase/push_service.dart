// lib/firebase/push_service.dart
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushService {
  PushService._();

  static final FirebaseMessaging _msg = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> initAndSaveToken({
    required String appUserId,
  }) async {
    try {
      // 1) Ask permission (iOS + Android 13+)
      final settings = await _msg.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('Push permission denied.');
        return;
      }

      // 2) On iOS, APNS token may not be ready immediately.
      if (Platform.isIOS) {
        String? apnsToken;

        for (int i = 0; i < 10; i++) {
          try {
            apnsToken = await _msg.getAPNSToken();
          } catch (_) {
            apnsToken = null;
          }

          if (apnsToken != null && apnsToken.isNotEmpty) {
            break;
          }

          await Future.delayed(const Duration(seconds: 1));
        }

        if (apnsToken == null || apnsToken.isEmpty) {
          print('APNS token not available yet. Skipping push token save for now.');
          return;
        }
      }

      // 3) Get FCM token
      final token = await _msg.getToken();

      if (token == null || token.isEmpty) {
        print('FCM token is empty.');
        return;
      }

      await _saveToken(
        token: token,
        appUserId: appUserId,
      );

      // 4) Token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (newToken.isEmpty) return;

        await _saveToken(
          token: newToken,
          appUserId: appUserId,
        );
      });
    } catch (e) {
      // Push notifications should never block login / app entry.
      print('PushService.initAndSaveToken skipped due to error: $e');
    }
  }

  static Future<void> _saveToken({
    required String token,
    required String appUserId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

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