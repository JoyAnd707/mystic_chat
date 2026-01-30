import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageMessageService {
  ImageMessageService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    ImagePicker? picker,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  /// Picks an image from gallery, uploads to Firebase Storage,
  /// and writes a Firestore message document:
  /// { type: "image", senderId, imageUrl, createdAt, fileName }
  ///
  /// Returns true if an image was sent, false if user canceled.
Future<bool> pickAndSendImage({
  required String roomId,
  required String senderId,
  required int ts, // ✅ חשוב: ts נשמר במסמך
  int imageQuality = 82,
}) async {
  final XFile? picked = await _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: imageQuality,
  );

  if (picked == null) return false;

  final messagesRef = _firestore
      .collection('rooms')
      .doc(roomId)
      .collection('messages');

  // ✅ משתמשים ב-ts כ-id כדי להתאים לדרך שלך
  final newDoc = messagesRef.doc(ts.toString());

  final String ext = _extFromName(picked.name);

  final storageRef = _storage
      .ref()
      .child('rooms')
      .child(roomId)
      .child('uploads')
      .child('${newDoc.id}.$ext');

  // ignore: avoid_print
  print('UPLOAD PATH: ${storageRef.fullPath}');

  final bytes = await picked.readAsBytes();

  final TaskSnapshot snap = await storageRef.putData(
    bytes,
    SettableMetadata(contentType: _guessContentType(ext)),
  );

  final String downloadUrl = await snap.ref.getDownloadURL();

  await newDoc.set({
    'id': newDoc.id,
    'type': 'image',
    'senderId': senderId,
    'text': '', // ✅ כדי ש-fromMap לא ייפול על null
    'imageUrl': downloadUrl,
    'fileName': picked.name,
    'ts': ts, // ✅ זה מה שה-UI שלך קורא
  });

  return true;
}



  String _extFromName(String name) {
    final parts = name.split('.');
    if (parts.length < 2) return 'jpg';
    final ext = parts.last.toLowerCase().trim();
    if (ext.isEmpty) return 'jpg';
    return ext;
  }

  String _guessContentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
