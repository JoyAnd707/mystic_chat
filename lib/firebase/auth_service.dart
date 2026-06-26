// lib/firebase/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'push_service.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String? get uid => _auth.currentUser?.uid;

  /// Ensures we have a signed-in user (anonymous).
  /// Safe to call multiple times.
  static Future<void> ensureSignedIn({
    required String currentUserId, // joy / adi / ...
  }) async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }

    final u = _auth.currentUser;
    if (u == null) return;

    // Keep mapping uid -> appUserId (your existing behavior)
    await _db.collection('users').doc(u.uid).set({
      'uid': u.uid,
      'appUserId': currentUserId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Register push token, but don't block login if APNS isn't ready yet.
    PushService.initAndSaveToken(appUserId: currentUserId).catchError((
      error,
      stackTrace,
    ) {
      print('Push init failed, continuing: $error');
    });
  }
}