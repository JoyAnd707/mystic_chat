// lib/firebase/firestore_chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// ✅ must match ChatScreenState: sendSystemLine(text: ..., ts: ...)
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

  /// ✅ VER103 — delete doc (no rules changes)
  static Future<void> deleteMessage({
    required String roomId,
    required String messageId,
  }) async {
    await _messagesCol(roomId).doc(messageId).delete();
  }
}
