// lib/firebase/firestore_chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreChatService {
  FirestoreChatService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _messagesCol(String roomId) {
    return _db.collection('rooms').doc(roomId).collection('messages');
  }

  /// Stream of messages ordered by ts ascending.
  /// Each item includes:
  /// - id (docId)
  /// - type: "text" | "system"
  /// - senderId
  /// - text
  /// - ts (int ms)
  /// - bubbleTemplate, decor, fontFamily
  /// - heartReactorIds: List<String>
  static Stream<List<Map<String, dynamic>>> messagesStreamMaps(String roomId) {
    return _messagesCol(roomId)
        .orderBy('ts', descending: false)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id; // inject docId so ChatScreen can use it
        return data;
      }).toList();
    });
  }

  /// We use docId = ts.toString() so we can later update hearts by id easily.
  static Future<void> sendTextMessage({
    required String roomId,
    required String senderId,
    required String text,
    required int ts,
    required String bubbleTemplate,
    required String decor,
    String? fontFamily,
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
    });
  }

  static Future<void> sendSystemLine({
    required String roomId,
    required String line,
    required int ts,
  }) async {
    final docId = ts.toString();

    await _messagesCol(roomId).doc(docId).set({
      'type': 'system',
      'senderId': '',
      'text': line,
      'ts': ts,
      'bubbleTemplate': 'normal',
      'decor': 'none',
      'fontFamily': null,
      'heartReactorIds': <String>[],
    });
  }

  static Future<void> toggleHeart({
    required String roomId,
    required String messageId, // docId
    required String reactorId, // who liked
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
