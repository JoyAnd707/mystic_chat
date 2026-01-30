// lib/firebase/firestore_chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreChatService {
  FirestoreChatService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ FIX: define rooms ref
  static CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _db.collection('rooms');

  static CollectionReference<Map<String, dynamic>> _messagesCol(String roomId) {
    return _roomsRef.doc(roomId).collection('messages');
  }

  /// Stream of messages ordered by ts ascending.
  static Stream<List<Map<String, dynamic>>> messagesStreamMaps(String roomId) {
    return _messagesCol(roomId)
        .orderBy('ts', descending: false)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id; // inject docId
        return data;
      }).toList();
    });
  }

  /// ✅ TEXT message (docId = ts.toString())
  static Future<void> sendTextMessage({
    required String roomId,
    required String senderId,
    required String text,
    required int ts,
    required String bubbleTemplate,
    required String decor,
    String? fontFamily,

    // ✅ reply payload
    String? replyToMessageId,
    String? replyToSenderId,
    String? replyToText,
  }) async {
    final docId = ts.toString();

    await _messagesCol(roomId).doc(docId).set(<String, dynamic>{
      'id': docId,
      'type': 'text',
      'senderId': senderId,
      'text': text,
      'ts': ts,
      'bubbleTemplate': bubbleTemplate,
      'decor': decor,
      'fontFamily': fontFamily,
      'heartReactorIds': <String>[],

      // ✅ reply fields (optional)
      'replyToMessageId': replyToMessageId,
      'replyToSenderId': replyToSenderId,
      'replyToText': replyToText,
    });
  }

  /// ✅ NEW: SYSTEM message (entered/left)
  static Future<void> sendSystemLine({
    required String roomId,
    required String text,
    required int ts,
  }) async {
    final docId = ts.toString();

    await _messagesCol(roomId).doc(docId).set(<String, dynamic>{
      'id': docId,
      'type': 'system',
      'senderId': 'system',
      'text': text,
      'ts': ts,

      // keep schema stable
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
}
