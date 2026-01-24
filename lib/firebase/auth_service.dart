// lib/firebase/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    // Optional but useful: store a "users/<uid>" doc mapping uid -> currentUserId.
    final u = _auth.currentUser;
    if (u == null) return;

    await _db.collection('users').doc(u.uid).set({
      'uid': u.uid,
      'appUserId': currentUserId, // joy/adi...
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
