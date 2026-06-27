import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../firebase/firestore_chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/rotating_envelope.dart';

import '../audio/bgm.dart';
import '../audio/sfx.dart';
import '../fx/heart_reaction_fly_layer.dart';
import '../services/presence_service.dart';
import '../widgets/fullscreen_video_player.dart';
import '../widgets/video_preview_tile.dart';

part 'dms_core.dart';
part 'dms_widgets.dart';
part 'dms_painters.dart';


class DmsListScreen extends StatefulWidget {
  final String currentUserId;

  const DmsListScreen({super.key, required this.currentUserId});

  @override
  State<DmsListScreen> createState() => _DmsListScreenState();
}

class _DmsListScreenState extends State<DmsListScreen>
    with TickerProviderStateMixin {
  late final AnimationController _twinkleController;
late final AnimationController _enterController;
late final Animation<double> _enterScale;
Timer? _clockTimer;
DateTime _now = DateTime.now();
// ✅ prevents double back sound when we pop manually (top bar back)
bool _suppressNextPopSound = false;


  static const String _boxName = 'mystic_chat_storage';
  String _roomKey(String roomId) => 'room_messages__$roomId';
  String _metaKey(String roomId) => 'room_meta__$roomId';
  String _lastReadKeyFor(String roomId) =>
      'lastReadMs__${widget.currentUserId}__$roomId';

@override
void initState() {
  super.initState();
_now = DateTime.now();

_clockTimer = Timer.periodic(
  const Duration(seconds: 1),
  (_) {
    if (!mounted) return;

    setState(() {
      _now = DateTime.now();
    });
  },
);
  // ✅ DMs use same Home BGM
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Bgm.I.playHomeDm();
  });

  _twinkleController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();
  _enterController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 180),
);

_enterScale = Tween<double>(
  begin: 0.0,
  end: 1.0,
).animate(
  CurvedAnimation(
    parent: _enterController,
    curve: Curves.easeOutCubic,
  ),
);

_enterController.forward();



}


@override
void dispose() {
  _clockTimer?.cancel();
  _twinkleController.dispose();
  _enterController.dispose();
  super.dispose();
}

  String _dmRoomId(String a, String b) {
    final pair = [a, b]..sort();
    return 'dm_${pair[0]}_${pair[1]}';
  }

  static const String _roomsCol = 'dm_rooms';

  Future<void> _ensureDmRoomExists({
    required String roomId,
    required String me,
    required String other,
  }) async {
    final ref = FirebaseFirestore.instance.collection(_roomsCol).doc(roomId);
    final snap = await ref.get();
    if (snap.exists) return;

    await ref.set({
      'participants': [me, other]..sort(),
      'lastUpdatedMs': 0,
      'lastSenderId': '',
      'lastText': '',
      'createdMs': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

Stream<List<_DmEntry>> _dmEntriesStream() async* {
  final prefs = await SharedPreferences.getInstance();

  final others = dmUsers.values
      .where((u) => u.id != widget.currentUserId)
      .toList();

for (final u in others) {
  final roomId = _dmRoomId(widget.currentUserId, u.id);

  _ensureDmRoomExists(
    roomId: roomId,
    me: widget.currentUserId,
    other: u.id,
  );
}

  await for (final snap in FirebaseFirestore.instance
      .collection(_roomsCol)
      .where('participants', arrayContains: widget.currentUserId)
      .snapshots()) {
    final entries = <_DmEntry>[];

    for (final u in others) {
      final roomId = _dmRoomId(widget.currentUserId, u.id);
      final docMatches = snap.docs.where((d) => d.id == roomId).toList();

      final data = docMatches.isEmpty
          ? <String, dynamic>{}
          : docMatches.first.data();

      final int lastUpdatedMs =
          (data['lastUpdatedMs'] is int) ? data['lastUpdatedMs'] as int : 0;

      final String lastSenderId = (data['lastSenderId'] ?? '').toString();
      final String previewRaw = (data['lastText'] ?? '').toString().trim();

      final String preview =
          previewRaw.isEmpty ? 'Tap to open chat' : previewRaw;

      final int lastReadMs = prefs.getInt(_lastReadKeyFor(roomId)) ?? 0;

      final bool unread =
          (lastUpdatedMs > lastReadMs) &&
          (lastSenderId != widget.currentUserId);

      entries.add(
        _DmEntry(
          user: u,
          roomId: roomId,
          lastUpdatedMs: lastUpdatedMs,
          unread: unread,
          preview: preview,
        ),
      );
    }

    entries.sort((a, b) {
      final byTime = b.lastUpdatedMs.compareTo(a.lastUpdatedMs);
      if (byTime != 0) return byTime;
      return a.user.name.toLowerCase().compareTo(b.user.name.toLowerCase());
    });

    yield entries;
  }
}

@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: true,
    onPopInvoked: (didPop) {
      // ✅ if we already played back sound manually (top bar back), skip once
      if (_suppressNextPopSound) {
        _suppressNextPopSound = false;
        return;
      }

      // ✅ system back (Android back / iOS swipe)
      try {
        Sfx.I.playBack();
      } catch (_) {}
    },
    child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ✅ Static background image
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/StarsBG.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          // ✅ Animated glints on top
          Positioned.fill(
            child: MysticStarTwinkleOverlay(
              animation: _twinkleController,
              starCount: 58,
              sizeMultiplier: 1.25,

            ),
          ),

SafeArea(
  child: Column(
    children: [
      MysticTopStatusBar(now: _now),

      _DmTopBar(
  onBack: () async {
    // 🔊 Back SFX (do NOT await — navigate immediately)
    try {
      Sfx.I.playBack();
    } catch (_) {}

    // ✅ tell PopScope to NOT play sound again
    _suppressNextPopSound = true;

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  },
),

                Expanded(
                  child: Builder(
                    builder: (context) {
                      final double uiScale = mysticUiScale(context);
                      double s(double v) => v * uiScale;

                    return StreamBuilder<List<_DmEntry>>(
  stream: _dmEntriesStream(),
                        builder: (context, snap) {
                          final items = snap.data ?? const <_DmEntry>[];

                          return ListView.separated(
                    padding: EdgeInsets.symmetric(
  horizontal: s(10), // ⬅️ פחות שוליים = מלבן רחב יותר
  vertical: s(10),
),

                            itemCount: items.length,
                            separatorBuilder: (_, __) => SizedBox(height: s(9)),

                            itemBuilder: (context, index) {
                              final e = items[index];
                              final double uiScale = mysticUiScale(context);

                              return _DmRowTile(
                                user: e.user,
                                previewText: e.preview,
                                unread: e.unread,
                                lastUpdatedMs: e.lastUpdatedMs,
                                uiScale: uiScale,
          onTap: () async {
  // 🔊 SFX — DM room selected (do NOT await)
  try {
    Sfx.I.playSelectDm();
  } catch (_) {}

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DmChatScreen(
        currentUserId: widget.currentUserId,
        otherUserId: e.user.id,
        otherName: e.user.name,
        roomId: e.roomId,
      ),
    ),
  );

  if (mounted) setState(() {});
},

                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


}










/// =======================================
/// DM CHAT SCREEN (separate from group ChatScreen)
/// =======================================
class DmChatScreen extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;
  final String otherName;
  final String roomId;

  const DmChatScreen({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherName,
    required this.roomId,
  });

  @override
  State<DmChatScreen> createState() => _DmChatScreenState();
}

class _DmChatScreenState extends State<DmChatScreen>
    with TickerProviderStateMixin {

  static const String _roomsCol = 'dm_rooms';
  static const String _msgsSub = 'messages';
final ScrollController _scroll = ScrollController();
final TextEditingController _c = TextEditingController();
final FocusNode _focus = FocusNode();
final ImagePicker _mediaPicker = ImagePicker();
  late final AnimationController _twinkleController;
late final AnimationController _enterController;
late final Animation<double> _enterScale;
bool _isTyping = false;
bool _nearBottomCached = true;
// ✅ DM delete mode
String? _armedDeleteMessageId;
// ✅ DM typing indicator
Timer? _typingStopTimer;
bool _sentTypingState = false;
Set<String> _typingUserIds = <String>{};
StreamSubscription<Set<String>>? _typingSub;
// ✅ NEW: unread messages badge (DM)
int _newBelowCount = 0;

// ✅ DM unread divider
int _lastReadMsCache = 0;
bool _lastReadLoaded = false;
bool _hideUnreadDivider = false;

// How many messages were in the previous snapshot
int _previousMessageCount = 0;

// ✅ Initial open position: jump to UNREAD if exists, otherwise bottom
bool _didInitialDmOpenJump = false;
// ✅ Reply jump + highlight
final Map<String, GlobalKey> _messageKeys = <String, GlobalKey>{};
final Set<String> _highlightedMessageIds = <String>{};
List<String> _messageIdsInOrder = <String>[];

GlobalKey _keyForMessageId(String id) {
  return _messageKeys.putIfAbsent(id, () => GlobalKey());
}
bool _isMyDeletableDmMessage(Map<String, dynamic> m) {
  final String senderId = (m['senderId'] ?? '').toString();
  final String type = (m['type'] ?? 'text').toString();

  if (type == 'system') return false;

  return senderId == widget.currentUserId;
}

bool _isArmedDeleteDmMessage(String messageId) {
  return _armedDeleteMessageId != null &&
      _armedDeleteMessageId == messageId;
}

void _toggleArmDeleteDmMessage({
  required String messageId,
  required Map<String, dynamic> data,
}) {
  if (!_isMyDeletableDmMessage(data)) return;

  setState(() {
    if (_armedDeleteMessageId == messageId) {
      _armedDeleteMessageId = null;
    } else {
      _armedDeleteMessageId = messageId;
    }
  });
}

Future<void> _deleteArmedDmMessage({
  required String messageId,
  required Map<String, dynamic> data,
}) async {
  if (!_isMyDeletableDmMessage(data)) return;
  if (!_isArmedDeleteDmMessage(messageId)) return;

  setState(() {
    _armedDeleteMessageId = null;
  });

  try {
    await FirebaseFirestore.instance
        .collection(_roomsCol)
        .doc(widget.roomId)
        .collection(_msgsSub)
        .doc(messageId)
        .delete();
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not delete message: $e'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
void _flashMessageHighlight(String messageId) {
  if (!mounted) return;

  setState(() {
    _highlightedMessageIds.add(messageId);
  });

  Future.delayed(const Duration(milliseconds: 900), () {
    if (!mounted) return;

    setState(() {
      _highlightedMessageIds.remove(messageId);
    });
  });
}

Future<void> _jumpToMessage(String messageId) async {
  if (messageId.trim().isEmpty) return;

  final int index = _messageIdsInOrder.indexOf(messageId);

  if (index >= 0 && _scroll.hasClients && _messageIdsInOrder.length > 1) {
    final double max = _scroll.position.maxScrollExtent;
    final double target =
        (max * (index / (_messageIdsInOrder.length - 1))).clamp(0.0, max);

    await _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  for (int attempt = 0; attempt < 8; attempt++) {
    await Future.delayed(const Duration(milliseconds: 70));

    final ctx = _messageKeys[messageId]?.currentContext;
    if (ctx == null) continue;

    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      alignment: 0.25,
    );

    _flashMessageHighlight(messageId);
    return;
  }

  _flashMessageHighlight(messageId);
}


Future<void> _toggleHeartForMessage(
  String messageId,
  List<String> currentReactors,
) async {
  final me = widget.currentUserId;

  final bool isAdding = !currentReactors.contains(me);

  await _msgsRef.doc(messageId).update({
    'heartReactorIds': isAdding
        ? FieldValue.arrayUnion([me])
        : FieldValue.arrayRemove([me]),
  });

  if (isAdding && mounted) {
    HeartReactionFlyLayer.of(context).spawnHeart(
      color: _heartColorForUserId(me),
    );
  }
}

double _dragDx = 0.0;

String? _replyToMessageId;
String? _replyToSenderId;
String? _replyToSenderName;
String? _replyToText;

void _setReplyTarget({
  required String messageId,
  required String senderId,
  required String text,
}) {
  setState(() {
    _replyToMessageId = messageId;
    _replyToSenderId = senderId;
    _replyToSenderName =
        dmUsers[senderId]?.name ?? senderId;
    _replyToText = text.trim();
    _isTyping = true;
  });

  _focus.requestFocus();
}

void _clearReplyTarget() {
  setState(() {
    _replyToMessageId = null;
    _replyToSenderId = null;
    _replyToSenderName = null;
    _replyToText = null;
  });
}
  String _lastReadKey() =>
      'lastReadMs__${widget.currentUserId}__${widget.roomId}';

  DocumentReference<Map<String, dynamic>> get _roomRef =>
      FirebaseFirestore.instance.collection(_roomsCol).doc(widget.roomId);

  CollectionReference<Map<String, dynamic>> get _msgsRef =>
      _roomRef.collection(_msgsSub);

  Stream<QuerySnapshot<Map<String, dynamic>>> get _msgsStream =>
      _msgsRef.orderBy('tsMs', descending: false).snapshots();

  Future<void> _loadLastReadOnce() async {
    if (_lastReadLoaded) return;

    final prefs = await SharedPreferences.getInstance();

    _lastReadMsCache = prefs.getInt(_lastReadKey()) ?? 0;
    _lastReadLoaded = true;
  }

bool _isReadableDmMessageType(String type) {
  return type == 'text' ||
      type == 'image' ||
      type == 'video' ||
      type == 'sticker';
}
  int _latestIncomingReadableTs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    int latest = 0;

    for (final d in docs) {
      final data = d.data();

      final String type = (data['type'] ?? 'text').toString();
      final String sender = (data['senderId'] ?? '').toString();
      final int ts = (data['tsMs'] is int) ? data['tsMs'] as int : 0;

      if (!_isReadableDmMessageType(type)) continue;
      if (sender == widget.currentUserId) continue;
      if (ts > latest) latest = ts;
    }

    return latest;
  }

  int _firstUnreadIncomingReadableTs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (!_lastReadLoaded) return 0;

    for (final d in docs) {
      final data = d.data();

      final String type = (data['type'] ?? 'text').toString();
      final String sender = (data['senderId'] ?? '').toString();
      final int ts = (data['tsMs'] is int) ? data['tsMs'] as int : 0;

      if (!_isReadableDmMessageType(type)) continue;
      if (sender == widget.currentUserId) continue;
      if (ts <= _lastReadMsCache) continue;

      return ts;
    }

    return 0;
  }

  Future<void> _markReadNow({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  }) async {
    if (!_lastReadLoaded) return;

   final int latestIncomingTs = _latestIncomingReadableTs(docs);
    if (latestIncomingTs <= 0) return;
    if (latestIncomingTs <= _lastReadMsCache) return;

    _lastReadMsCache = latestIncomingTs;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReadKey(), latestIncomingTs);

    if (!mounted) return;

    setState(() {
      _hideUnreadDivider = true;
      _newBelowCount = 0;
    });
  }

  Future<void> _ensureRoomExists() async {
    final snap = await _roomRef.get();
    if (snap.exists) return;

    final pair = [widget.currentUserId, widget.otherUserId]..sort();

    await _roomRef.set({
      'participants': pair,
      'lastUpdatedMs': 0,
      'lastSenderId': '',
      'lastText': '',
      'createdMs': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }
Future<void> _setActiveDmWith() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'activeDmWith': widget.otherUserId,
    'activeDmRoomId': widget.roomId,
    'activeDmUpdatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

Future<void> _clearActiveDmWith() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'activeDmWith': FieldValue.delete(),
    'activeDmRoomId': FieldValue.delete(),
    'activeDmUpdatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
  void _scrollToBottom({bool keepFocus = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      if (keepFocus) _focus.requestFocus();
    });
  }
bool _isNearBottom() {
  if (!_scroll.hasClients) return true;

  final distanceFromBottom =
      _scroll.position.maxScrollExtent - _scroll.position.pixels;

  return distanceFromBottom <= 80;
}

void _onDmScroll() {
  if (!mounted) return;

  final nearBottom = _isNearBottom();

  if (nearBottom == _nearBottomCached) return;

  setState(() {
    _nearBottomCached = nearBottom;

    if (nearBottom) {
      _hideUnreadDivider = true;
    } else {
      _hideUnreadDivider = false;
    }
  });
}

void _clearNewBelowBadge() {
  if (!mounted) return;

  if (_newBelowCount == 0) return;

  setState(() {
    _newBelowCount = 0;
  });
}

void _onTapScrollToBottomButton() {
  _clearNewBelowBadge();

  setState(() {
    _hideUnreadDivider = true;
  });

  _scrollToBottom(keepFocus: false);
}
String _myDmDisplayName() {
  return dmUsers[widget.currentUserId]?.name ?? widget.currentUserId;
}

Future<void> _sendTypingState(bool isTyping) async {
  if (_sentTypingState == isTyping) return;

  _sentTypingState = isTyping;

  try {
    await PresenceService.I.setTyping(
      roomId: widget.roomId,
      userId: widget.currentUserId,
      displayName: _myDmDisplayName(),
      isTyping: isTyping,
    );
  } catch (_) {
    // Ignore typing failures; chat should keep working.
  }
}

void _notifyDmTypingChanged() {
  final bool shouldType =
      _focus.hasFocus && _c.text.trim().isNotEmpty;

  _sendTypingState(shouldType);

  _typingStopTimer?.cancel();

  if (shouldType) {
    _typingStopTimer = Timer(const Duration(seconds: 3), () {
      _sendTypingState(false);
    });
  }
}
  void _onTapType() {
    if (_isTyping) {
      _focus.requestFocus();
      return;
    }
    setState(() => _isTyping = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }
Future<void> _pickAndSendDmMedia() async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.black.withOpacity(0.92),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFF46F5D6),
                ),
                title: const Text(
                  'Photo / Video',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _pickAndSendDmPhotoOrVideo();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.sticky_note_2_outlined,
                  color: Color(0xFF46F5D6),
                ),
                title: const Text(
                  'Stickers',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  _openDmStickerPicker();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _pickAndSendDmPhotoOrVideo() async {
  final XFile? picked = await _mediaPicker.pickMedia();

  if (picked == null) return;

  final String path = picked.path;
  final String lowerPath = path.toLowerCase();

  final bool isVideo =
      lowerPath.endsWith('.mp4') ||
      lowerPath.endsWith('.mov') ||
      lowerPath.endsWith('.m4v') ||
      lowerPath.endsWith('.avi') ||
      lowerPath.endsWith('.webm');

  final String type = isVideo ? 'video' : 'image';

  final int nowMs = DateTime.now().millisecondsSinceEpoch;

  final docRef = _msgsRef.doc();

  final String fileExt = path.split('.').last.toLowerCase();
  final String storagePath =
      'dm_rooms/${widget.roomId}/media/${docRef.id}.$fileExt';

  try {
    await docRef.set({
      'type': type,
      'senderId': widget.currentUserId,
      'text': '',
      'tsMs': nowMs,
      'mediaUrl': '',
      'storagePath': storagePath,
      'heartReactorIds': <String>[],
      'replyToMessageId': null,
      'replyToSenderId': null,
      'replyToSenderName': null,
      'replyToText': null,
    });

    final ref = FirebaseStorage.instance.ref(storagePath);

    await ref.putFile(File(path));

    final String downloadUrl = await ref.getDownloadURL();

    await docRef.update({
      'mediaUrl': downloadUrl,
    });

    await _roomRef.set({
      'lastUpdatedMs': nowMs,
      'lastSenderId': widget.currentUserId,
      'lastText': isVideo ? '🎥 Video' : '📷 Photo',
    }, SetOptions(merge: true));

    _scrollToBottom(keepFocus: false);
  } catch (e) {
    try {
      await docRef.delete();
    } catch (_) {}

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not send media: $e'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

void _openDmStickerPicker() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black.withOpacity(0.92),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: FirestoreChatService.loadStickerArchive(
            userId: widget.currentUserId,
          ),
          builder: (context, snapshot) {
            final bool isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            final List<Map<String, dynamic>> stickers =
                snapshot.data ?? <Map<String, dynamic>>[];

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Stickers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 330,
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : GridView.builder(
                            itemCount: stickers.length + 1,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1,
                            ),
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return GestureDetector(
                                  onTap: () async {
                                    final XFile? picked =
                                        await _mediaPicker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 70,
                                    );

                                    if (picked == null) return;

                                    final int nowMs =
                                        DateTime.now().millisecondsSinceEpoch;

                                    Navigator.pop(sheetContext);

                                    await FirestoreChatService
                                        .sendStickerMessage(
                                      roomId: widget.roomId,
                                      senderId: widget.currentUserId,
                                      localFilePath: picked.path,
                                      ts: nowMs,
                                    );

                                    await _roomRef.set({
                                      'lastUpdatedMs': nowMs,
                                      'lastSenderId': widget.currentUserId,
                                      'lastText': '🙂 Sticker',
                                    }, SetOptions(merge: true));

                                    try {
                                      Sfx.I.playSend();
                                    } catch (_) {}

                                    _scrollToBottom(keepFocus: false);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.18),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: Colors.white.withOpacity(0.9),
                                          size: 30,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Create',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.75),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final sticker = stickers[index - 1];
                              final String stickerId =
                                  (sticker['id'] ?? '').toString();
                              final String stickerUrl =
                                  (sticker['stickerUrl'] ?? '').toString();
                              final String storagePath =
                                  (sticker['storagePath'] ?? '').toString();

                              if (stickerUrl.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return GestureDetector(
                                onTap: () async {
                                  final int nowMs =
                                      DateTime.now().millisecondsSinceEpoch;

                                  Navigator.pop(sheetContext);

                                  await FirestoreChatService
                                      .sendArchivedStickerMessage(
                                    roomId: widget.roomId,
                                    senderId: widget.currentUserId,
                                    stickerUrl: stickerUrl,
                                    storagePath: storagePath,
                                    ts: nowMs,
                                  );

                                  await _roomRef.set({
                                    'lastUpdatedMs': nowMs,
                                    'lastSenderId': widget.currentUserId,
                                    'lastText': '🙂 Sticker',
                                  }, SetOptions(merge: true));

                                  try {
                                    Sfx.I.playSend();
                                  } catch (_) {}

                                  _scrollToBottom(keepFocus: false);
                                },
                                onLongPress: () async {
                                  if (stickerId.isEmpty) return;

                                  final bool? shouldDelete =
                                      await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) {
                                      return AlertDialog(
                                        backgroundColor: Colors.black,
                                        title: const Text(
                                          'Delete sticker?',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        content: const Text(
                                          'Remove this sticker from your archive?',
                                          style:
                                              TextStyle(color: Colors.white70),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              false,
                                            ),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              true,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (shouldDelete != true) return;

                                  await FirestoreChatService
                                      .deleteArchivedSticker(
                                    userId: widget.currentUserId,
                                    stickerId: stickerId,
                                    storagePath: storagePath,
                                  );

                                  if (!mounted) return;

                                  Navigator.pop(sheetContext);
                                  _openDmStickerPicker();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.12),
                                    ),
                                  ),
                                  child: Image.network(
                                    stickerUrl,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (!isLoading && stickers.isEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      'No saved stickers yet',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
Future<void> _send() async {
  final text = _c.text.trim();
  if (text.isEmpty) return;

  final String? replyMessageId = _replyToMessageId;
  final String? replySenderId = _replyToSenderId;
  final String? replySenderName = _replyToSenderName;
  final String? replyText = _replyToText;

  try {
    Sfx.I.playSend();
  } catch (_) {}

  final nowMs = DateTime.now().millisecondsSinceEpoch;

_c.clear();
await _sendTypingState(false);

setState(() {
  _isTyping = true;
    _replyToMessageId = null;
    _replyToSenderId = null;
    _replyToSenderName = null;
    _replyToText = null;
  });

await _msgsRef.add({
  'type': 'text',
  'senderId': widget.currentUserId,
  'text': text,
  'tsMs': nowMs,

  // ❤️ reactions
  'heartReactorIds': <String>[],

  'replyToMessageId': replyMessageId,
  'replyToSenderId': replySenderId,
  'replyToSenderName': replySenderName,
  'replyToText': replyText,
});

  await _roomRef.set({
    'lastUpdatedMs': nowMs,
    'lastSenderId': widget.currentUserId,
    'lastText': text,
  }, SetOptions(merge: true));

  _scrollToBottom(keepFocus: true);
}

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Bgm.I.playHomeDm();
    });

    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
_enterController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 180),
);

_enterScale = Tween<double>(
  begin: 0.0,
  end: 1.0,
).animate(
  CurvedAnimation(
    parent: _enterController,
    curve: Curves.easeOutCubic,
  ),
);

_enterController.forward();
_scroll.addListener(_onDmScroll);
_focus.addListener(() {
  if (!_focus.hasFocus) {
    if (mounted) {
      setState(() {
        _isTyping = false;
      });
    }
  }

  _notifyDmTypingChanged();
});

_c.addListener(() {
  if (_focus.hasFocus && !_isTyping) {
    if (mounted) {
      setState(() {
        _isTyping = true;
      });
    }
  }

  _notifyDmTypingChanged();
});

    _c.addListener(() {
      if (_focus.hasFocus && !_isTyping) {
        if (mounted) {
          setState(() {
            _isTyping = true;
          });
        }
      }
    });

// ✅ ensure room exists + mark read + mark this DM as currently open
_ensureRoomExists().then((_) async {
  _loadLastReadOnce();
  await _setActiveDmWith();
});
_typingSub = PresenceService.I.streamTypingUserIds(
  roomId: widget.roomId,
).listen((ids) {
  if (!mounted) return;

  final filtered = ids.where((id) {
    return id != widget.currentUserId;
  }).toSet();

  setState(() {
    _typingUserIds = filtered;
  });
});
  }

@override
void dispose() {
  _typingSub?.cancel();
  _typingStopTimer?.cancel();
  _sendTypingState(false);

  _clearActiveDmWith();

  _twinkleController.dispose();
  _enterController.dispose();

  _scroll.removeListener(_onDmScroll);
  _scroll.dispose();

  _c.dispose();
  _focus.dispose();
  super.dispose();
}

  @override
Widget build(BuildContext context) {
  final double uiScale = mysticUiScale(context);
  double s(double v) => v * uiScale;

  final mq = MediaQuery.of(context);

  return MediaQuery(
    data: mq.copyWith(
      textScaler: const TextScaler.linear(1.0),
    ),
    child: Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 34, width: double.infinity),
                LayoutBuilder(
                  builder: (context, c) {
                    const double barAspect = 2048 / 212;
                    final w = c.maxWidth;
                    final barH = w / barAspect;

                    return SizedBox(
                      width: w,
                      height: barH,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/ui/DMSroomNameBar.png',
                              fit: BoxFit.fitWidth,
                              alignment: Alignment.center,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {
                                try {
                                  Sfx.I.playBack();
                                } catch (_) {}
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              child: const SizedBox(
                                width: 72,
                                height: double.infinity,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 80),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Transform.translate(
                                    offset: const Offset(-2, 1),
                                    child: Image.asset(
                                      'assets/ui/DMSlittleLetterIcon.png',
                                      width: 25,
                                      height: 25,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      widget.otherName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w200,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: ScaleTransition(
              scale: _enterScale,
              alignment: Alignment.center,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/backgrounds/StarsBG.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    Positioned.fill(
                      child: MysticStarTwinkleOverlay(
                        animation: _twinkleController,
                        starCount: 58,
                        sizeMultiplier: 1.25,
                      ),
                    ),

                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _msgsStream,
                      builder: (context, snap) {
       final docs = snap.data?.docs ?? const [];
_messageIdsInOrder = docs.map((d) => d.id).toList();
if (snap.hasData && _lastReadLoaded && !_didInitialDmOpenJump) {
  _didInitialDmOpenJump = true;

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!mounted) return;

    final int firstUnreadTs =
        _firstUnreadIncomingReadableTs(docs);

    if (firstUnreadTs > 0) {
      String targetMessageId = '';

      for (final d in docs) {
        final data = d.data();
        final int ts = (data['tsMs'] is int) ? data['tsMs'] as int : 0;

        if (ts == firstUnreadTs) {
          targetMessageId = d.id;
          break;
        }
      }

      if (targetMessageId.isNotEmpty) {
        await _jumpToMessage(targetMessageId);
      }

      return;
    }

    _scrollToBottom(keepFocus: false);
  });
}

if (snap.hasData) {
  final int currentCount = docs.length;

  if (_previousMessageCount == 0) {
    _previousMessageCount = currentCount;
  } else if (currentCount > _previousMessageCount) {
    final addedDocs = docs.sublist(_previousMessageCount);

    int incomingAdded = 0;

    for (final d in addedDocs) {
      final data = d.data();

      final String sender =
          (data['senderId'] ?? '').toString();

      final String type =
          (data['type'] ?? 'text').toString();

      if (sender != widget.currentUserId && type != 'system') {
        incomingAdded++;
      }
    }

    if (incomingAdded > 0 && !_isNearBottom()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        setState(() {
          _newBelowCount += incomingAdded;
        });
      });
    }
  }

  _previousMessageCount = currentCount;

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (_isNearBottom()) {
      _clearNewBelowBadge();
      await _markReadNow(docs: docs);
    }
  });
}

                 // ✅ Auto-scroll only when sending / new message flow asks for it.
// Do not force-scroll on every rebuild, because Reply Jump needs to stay in place.
// WidgetsBinding.instance.addPostFrameCallback((_) {
//   if (snap.hasData) _scrollToBottom();
// });

                         final int firstUnreadTs =
    _firstUnreadIncomingReadableTs(docs);

                        return ListView.builder(
                          controller: _scroll,
                          padding: EdgeInsets.only(
                            left: s(14),
                            right: s(14),
                            top: s(10),
                            bottom: s(90),
                          ),
                          itemCount: docs.length,
                          itemBuilder: (context, i) {
                            final m = docs[i].data();

                            final int currentTs =
                                (m['tsMs'] is int) ? m['tsMs'] as int : 0;

                            final bool showUnreadDivider =
                                !_hideUnreadDivider &&
                                firstUnreadTs > 0 &&
                                currentTs == firstUnreadTs;

           final String messageType = (m['type'] ?? 'text').toString();

if (messageType != 'text' &&
    messageType != 'image' &&
    messageType != 'video' &&
    messageType != 'sticker') {
  return const SizedBox.shrink();
}

final sender = (m['senderId'] ?? '').toString();
final isMe = sender == widget.currentUserId;
final text = (m['text'] ?? '').toString();

final String mediaUrl = messageType == 'sticker'
    ? (m['stickerUrl'] ?? '').toString()
    : (m['mediaUrl'] ?? '').toString();

                            final int ts =
                                (m['tsMs'] is int) ? m['tsMs'] as int : 0;

                            final String timeLabel =
                                mysticTimeOnlyFromMs(ts);

                  int prevTs = 0;
if (i > 0) {
  final prev = docs[i - 1].data();
  prevTs = (prev['tsMs'] is int)
      ? prev['tsMs'] as int
      : 0;
}

                            final bool showDateDivider =
                                (i == 0 && ts > 0) ||
                                    (i > 0 &&
                                        ts > 0 &&
                                        !mysticIsSameDayMs(prevTs, ts));

                            final String dateHeader =
                                mysticDmDateHeaderFromMs(ts);

                            String prevSender = '';
                            if (i > 0) {
                              final prev = docs[i - 1].data();
                              if ((prev['type'] ?? 'text') == 'text') {
                                prevSender =
                                    (prev['senderId'] ?? '').toString();
                              }
                            }

                            final bool switchedSender =
                                prevSender.isNotEmpty && prevSender != sender;

                            final double sameSenderGap = s(22);
                            final double switchedSenderGap = s(34);
                            final double bottomGap = switchedSender
                                ? switchedSenderGap
                                : sameSenderGap;

        return Padding(
  padding: EdgeInsets.only(bottom: bottomGap),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (showDateDivider)
        _DmDateDivider(
          text: dateHeader,
          uiScale: uiScale,
        ),

      if (showUnreadDivider)
        _DmUnreadDivider(
          uiScale: uiScale,
        ),

            Builder(
        builder: (context) {
          final String messageId = docs[i].id;
          final bool isHighlighted =
              _highlightedMessageIds.contains(messageId);

          final bool isArmedDelete =
              _isArmedDeleteDmMessage(messageId);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                key: _keyForMessageId(messageId),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: EdgeInsets.all(
                  (isHighlighted || isArmedDelete) ? s(4) : 0,
                ),
                decoration: BoxDecoration(
                  color: isArmedDelete
                      ? const Color(0xFFFF6769).withOpacity(0.16)
                      : isHighlighted
                          ? const Color(0xFF46F5D6).withOpacity(0.18)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(s(12)),
                  border: isArmedDelete
                      ? Border.all(
                          color: const Color(0xFFFF6769).withOpacity(0.95),
                          width: s(1.4),
                        )
                      : null,
                  boxShadow: isArmedDelete
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF6769).withOpacity(0.45),
                            blurRadius: s(18),
                            spreadRadius: s(1),
                          ),
                        ]
                      : isHighlighted
                          ? [
                              BoxShadow(
                                color: const Color(0xFF46F5D6)
                                    .withOpacity(0.65),
                                blurRadius: 22,
                                spreadRadius: 2,
                              ),
                            ]
                          : const [],
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,

                  onDoubleTap: () {
                    final reactors =
                        List<String>.from(m['heartReactorIds'] ?? const []);

                    _toggleHeartForMessage(
                      messageId,
                      reactors,
                    );
                  },

                  onLongPress: () {
                    _toggleArmDeleteDmMessage(
                      messageId: messageId,
                      data: m,
                    );
                  },

                  onHorizontalDragStart: (_) {
                    _dragDx = 0.0;
                  },

                  onHorizontalDragUpdate: (details) {
                    _dragDx += details.delta.dx;

                    if (_dragDx > 28) {
                      _dragDx = 0.0;

                      _setReplyTarget(
                        messageId: messageId,
                        senderId: sender,
                        text: text,
                      );
                    }
                  },

                  onHorizontalDragEnd: (_) {
                    _dragDx = 0.0;
                  },

                  child: (messageType == 'image' || messageType == 'video')
                      ? _DmMediaMessageRow(
                          isMe: isMe,
                          messageType: messageType,
                          mediaUrl: mediaUrl,
                          time: timeLabel,
                          uiScale: uiScale,
                          heartReactorIds: List<String>.from(
                            m['heartReactorIds'] ?? const [],
                          ),
                          meLetter: (dmUsers[widget.currentUserId]
                                      ?.name
                                      .characters
                                      .first ??
                                  ' ')
                              .toUpperCase(),
                          otherLetter: (dmUsers[widget.otherUserId]
                                      ?.name
                                      .characters
                                      .first ??
                                  ' ')
                              .toUpperCase(),
                          replyToSenderName:
                              m['replyToSenderName']?.toString(),
                          replyToText: m['replyToText']?.toString(),
                          onTapReplyPreview: () {
                            final id = m['replyToMessageId']?.toString();

                            if (id == null || id.isEmpty) return;

                            _jumpToMessage(id);
                          },
                        )
                      : _DmMessageRow(
                          isMe: isMe,
                          text: text,
                          time: timeLabel,
                          uiScale: uiScale,
                          heartReactorIds: List<String>.from(
                            m['heartReactorIds'] ?? const [],
                          ),
                          meLetter: (dmUsers[widget.currentUserId]
                                      ?.name
                                      .characters
                                      .first ??
                                  ' ')
                              .toUpperCase(),
                          otherLetter: (dmUsers[widget.otherUserId]
                                      ?.name
                                      .characters
                                      .first ??
                                  ' ')
                              .toUpperCase(),
                          replyToSenderName:
                              m['replyToSenderName']?.toString(),
                          replyToText: m['replyToText']?.toString(),
                          onTapReplyPreview: () {
                            final id = m['replyToMessageId']?.toString();

                            if (id == null || id.isEmpty) return;

                            _jumpToMessage(id);
                          },
                        ),
                ),
              ),

              if (isArmedDelete)
                Padding(
                  padding: EdgeInsets.only(top: s(8)),
                  child: GestureDetector(
                    onTap: () {
                      _deleteArmedDmMessage(
                        messageId: messageId,
                        data: m,
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: s(14),
                        vertical: s(7),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6769).withOpacity(0.92),
                        borderRadius: BorderRadius.circular(s(999)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6769).withOpacity(0.45),
                            blurRadius: s(12),
                            spreadRadius: s(1),
                          ),
                        ],
                      ),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: s(12),
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  ),
);
},
                        );
                      },
                    ),



if (_typingUserIds.isNotEmpty)
  Positioned(
    left: s(18),
    bottom: s(18),
    child: _DmTypingIndicator(
      name: dmUsers[_typingUserIds.first]?.name ?? 'Someone',
      uiScale: uiScale,
    ),
  ),
  if (!_nearBottomCached)
  Positioned(
    right: s(18),
    bottom: s(18),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_newBelowCount > 0)
          GestureDetector(
            onTap: _onTapScrollToBottomButton,
            child: AnimatedScale(
              scale: _newBelowCount > 0 ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: Container(
                margin: EdgeInsets.only(bottom: s(8)),
                padding: EdgeInsets.symmetric(
                  horizontal: s(12),
                  vertical: s(7),
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(s(999)),
                  border: Border.all(
                    color: const Color(0xFF46F5D6),
                    width: s(1.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF46F5D6).withOpacity(0.35),
                      blurRadius: s(10),
                      spreadRadius: s(1),
                    ),
                  ],
                ),
                child: Text(
                  _newBelowCount == 1
                      ? '1 New Message'
                      : '$_newBelowCount New Messages',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: s(12),
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),

        GestureDetector(
          onTap: _onTapScrollToBottomButton,
          child: AnimatedScale(
            scale: _nearBottomCached ? 0 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: Container(
              width: s(42),
              height: s(42),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.72),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF46F5D6),
                  width: s(1.2),
                ),
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: s(28),
              ),
            ),
          ),
        ),
      ],
    ),
  ),

                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(bottom: s(0)),
            child: _DmBottomCornerLine(uiScale: uiScale),
          ),

_DmBottomBar(
height: (_replyToText != null && _replyToText!.trim().isNotEmpty)
    ? s(126)
    : s(80),
  isTyping: _isTyping,
  onTapTypeMessage: _onTapType,
  controller: _c,
  focusNode: _focus,
  onSend: _send,
  onPickMedia: _pickAndSendDmMedia,
  uiScale: uiScale,

  replyToSenderName: _replyToSenderName,
  replyToText: _replyToText,
  onCancelReply: _clearReplyTarget,
),
        ],
      ),
    ),
  );
}


}


class MysticTopStatusBar extends StatelessWidget {
  final DateTime now;

  const MysticTopStatusBar({
    super.key,
    required this.now,
  });

  String _timeText(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute$ampm';
  }

@override
Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(top: 25),
    child: SizedBox(
      width: double.infinity,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: -25,
            child: Image.asset(
              'assets/ui/TopBar.png',
              fit: BoxFit.fitWidth,
            ),
          ),

          Positioned(
            left: 12,
            top: 67,
            child: Text(
              _timeText(now),
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 17,
                color: Colors.white,
                fontWeight: FontWeight.w400,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}




