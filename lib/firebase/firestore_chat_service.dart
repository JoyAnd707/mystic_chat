// lib/firebase/firestore_chat_service.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreChatService {
  FirestoreChatService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _messagesCol(String roomId) {
    return _db.collection('rooms').doc(roomId).collection('messages');
  }

  /// Stream of messages ordered by ts ascending.
  /// Injects:
  /// - id (docId)
  static Stream<List<Map<String, dynamic>>> messagesStreamMaps(String roomId) {
    return _messagesCol(roomId)
        .orderBy('ts', descending: false)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();
    });
  }

  /// docId = ts.toString()
  static Future<void> sendTextMessage({
    required String roomId,
    required String senderId,
    required String text,
    required int ts,
    required String bubbleTemplate,
    required String decor,
    
    String? fontFamily,

    // ✅ must match ChatScreenState named params
    String? replyToMessageId,
    String? replyToSenderId,
    String? replyToText,
  }) async {
    final docId = ts.toString();

    await _messagesCol(roomId).doc(docId).set({
      'type': 'text',
      'senderId': senderId,
      'text': text,
      'ts': ts,
      'bubbleTemplate': bubbleTemplate,
      'decor': decor,
      'fontFamily': fontFamily,
      'heartReactorIds': <String>[],

      // ✅ reply fields
      'replyToMessageId': replyToMessageId,
      'replyToSenderId': replyToSenderId,
      'replyToText': replyToText,
    });
  }

  static Future<void> sendSystemLine({
    required String roomId,
    required String text,
    required int ts,
  }) async {
    final docId = ts.toString();

    await _messagesCol(roomId).doc(docId).set({
      'type': 'system',
      'senderId': '',
      'text': text,
      'ts': ts,
      'bubbleTemplate': 'normal',
      'decor': 'none',
      'fontFamily': null,
      'heartReactorIds': <String>[],
    });
  }

  /// ✅ NEW: voice message (upload to Storage, then write url into Firestore)
  static Future<void> sendVoiceMessage({
    required String roomId,
    required String senderId,
    required String localFilePath,
    required int durationMs,
    required int ts,
    required String bubbleTemplate,
    required String decor,
  }) async {
    final docId = ts.toString();

    // 1) create placeholder doc (shows envelope until url is ready)
    await _messagesCol(roomId).doc(docId).set({
      'type': 'voice',
      'senderId': senderId,
      'text': '',
      'ts': ts,
      'bubbleTemplate': bubbleTemplate,
      'decor': decor,
      'fontFamily': null,
      'heartReactorIds': <String>[],

      // we reuse "voicePath" for the downloadable URL (backward compatible)
      'voicePath': '',
      'voiceDurationMs': durationMs,
    });

    // 2) upload file to Storage
    final String ext = (localFilePath.contains('.'))
        ? localFilePath.split('.').last.toLowerCase()
        : 'm4a';

    final storagePath = 'rooms/$roomId/voices/$docId.$ext';
    final ref = FirebaseStorage.instance.ref(storagePath);

    await ref.putFile(
      File(localFilePath),
      SettableMetadata(
        contentType: (ext == 'm4a' || ext == 'mp4') ? 'audio/mp4' : 'audio/aac',
      ),
    );

    final url = await ref.getDownloadURL();

    // 3) update doc with final url
    await _messagesCol(roomId).doc(docId).update({
      'voicePath': url,
    });
  }

  static Future<void> toggleHeart({
    required String roomId,
    required String messageId,
    required String reactorId,
    required bool isAdding,
  }) async {
    final ref = _messagesCol(roomId).doc(messageId);

    await ref.update({
      'heartReactorIds': isAdding
          ? FieldValue.arrayUnion([reactorId])
          : FieldValue.arrayRemove([reactorId]),
    });
  }

  static Future<void> deleteMessage({
    required String roomId,
    required String messageId,
  }) async {
    await _messagesCol(roomId).doc(messageId).delete();
  }

  /// ✅ NEW: delete voice doc + its Storage file (path is deterministic)
  static Future<void> deleteVoiceMessage({
    required String roomId,
    required String messageId, // same as docId
  }) async {
    // Delete Firestore doc first or after - either works.
    // We'll try Storage delete, then doc delete.
    try {
      final ref = FirebaseStorage.instance.ref('rooms/$roomId/voices/$messageId.m4a');
      await ref.delete();
    } catch (_) {
      // ignore: maybe different extension, or already deleted
    }

    try {
      final ref2 = FirebaseStorage.instance.ref('rooms/$roomId/voices/$messageId.aac');
      await ref2.delete();
    } catch (_) {}

    try {
      final ref3 = FirebaseStorage.instance.ref('rooms/$roomId/voices/$messageId.mp4');
      await ref3.delete();
    } catch (_) {}

    await _messagesCol(roomId).doc(messageId).delete();
  }
}
