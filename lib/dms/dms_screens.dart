import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/sticker_picker_sheet.dart';
import '../firebase/firestore_chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/rotating_envelope.dart';
import '../data/animated_emojis.dart';
import '../audio/bgm.dart';
import '../audio/sfx.dart';
import '../fx/heart_reaction_fly_layer.dart';
import '../services/presence_service.dart';
import '../widgets/fullscreen_video_player.dart';
import '../widgets/video_preview_tile.dart';
import '../widgets/mystic_top_status_bar.dart';
import '../widgets/mystic_profile_avatar.dart';
import '../widgets/chat_widgets.dart';
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
      MysticTopStatusBar(
  now: _now,
  currentUserId: widget.currentUserId,
),

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
  Timer? _clockTimer;
DateTime _now = DateTime.now();
late final AnimationController _enterController;
late final Animation<double> _enterScale;
bool _isTyping = false;
bool _nearBottomCached = true;
// ✅ DM delete mode
String? _armedDeleteMessageId;
String? _heartJumpMessageId;
String? _heartJumpFromUserId;
int _heartJumpShownAtMs = 0;
bool _dmSearchOpen = false;
final TextEditingController _dmSearchController = TextEditingController();
Timer? _dmSearchDebounce;
String _dmSearchQuery = '';
List<String> _dmSearchResultMessageIds = <String>[];
List<QueryDocumentSnapshot<Map<String, dynamic>>> _currentDmDocs =
    <QueryDocumentSnapshot<Map<String, dynamic>>>[];
final Map<String, Set<String>> _lastDmReactorsByMessageId = <String, Set<String>>{};
bool _dmHeartSnapshotInitialized = false;
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
Future<void> _copyDmMessageText(Map<String, dynamic> data) async {
  final String text = (data['text'] ?? '').toString().trim();

  if (text.isEmpty) return;

  await Clipboard.setData(
    ClipboardData(text: text),
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Message copied'),
      duration: Duration(seconds: 1),
    ),
  );
}
Future<bool> _isDmMessageStarredByMe(String messageId) async {
  try {
    final doc = await _msgsRef.doc(messageId).get();
    final data = doc.data();
    final raw = data?['starredBy'];

    if (raw is List) {
      return raw.map((e) => e.toString()).contains(widget.currentUserId);
    }

    return false;
  } catch (_) {
    return false;
  }
}

Future<void> _toggleStarForDmMessage(
  String messageId, {
  required bool isCurrentlyStarred,
}) async {
  try {
    if (isCurrentlyStarred) {
      await _msgsRef.doc(messageId).update({
        'starredBy': FieldValue.arrayRemove([widget.currentUserId]),
      });
    } else {
      await _msgsRef.doc(messageId).update({
        'starredBy': FieldValue.arrayUnion([widget.currentUserId]),
        'starredUpdatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCurrentlyStarred ? 'Message unstarred' : 'Message starred'),
        duration: const Duration(seconds: 1),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not update star: $e'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
void _toggleArmDeleteDmMessage({
  required String messageId,
  required Map<String, dynamic> data,
}) async {
  final bool canDelete = _isMyDeletableDmMessage(data);

  final String type = (data['type'] ?? 'text').toString();
  final String text = (data['text'] ?? '').toString().trim();

  final bool canCopy = type == 'text' && text.isNotEmpty;
  final bool isStarred = await _isDmMessageStarredByMe(messageId);

  if (!mounted) return;

  final String? action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF061522),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF46F5D6).withOpacity(0.45),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Message Options',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _DmMessageOptionTile(
                icon: isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                title: isStarred ? 'Unstar Message' : 'Star Message',
                color: const Color(0xFFFFD95A),
                onTap: () {
                  Navigator.pop(sheetContext, 'star');
                },
              ),
              const SizedBox(height: 8),
              if (canCopy) ...[
                _DmMessageOptionTile(
                  icon: Icons.copy_rounded,
                  title: 'Copy Message',
                  color: const Color(0xFF46F5D6),
                  onTap: () {
                    Navigator.pop(sheetContext, 'copy');
                  },
                ),
                const SizedBox(height: 8),
              ],

              if (canDelete) ...[
                _DmMessageOptionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete Message',
                  color: const Color(0xFFFF6B7A),
                  onTap: () {
                    Navigator.pop(sheetContext, 'delete');
                  },
                ),
                const SizedBox(height: 8),
              ],

              _DmMessageOptionTile(
                icon: Icons.close_rounded,
                title: 'Cancel',
                color: Colors.white70,
                onTap: () {
                  Navigator.pop(sheetContext, 'cancel');
                },
              ),
            ],
          ),
        ),
      );
    },
  );

  if (!mounted) return;
  if (action == null || action == 'cancel') return;

  if (action == 'copy') {
    await _copyDmMessageText(data);
    return;
  }
  if (action == 'star') {
    await _toggleStarForDmMessage(
      messageId,
      isCurrentlyStarred: isStarred,
    );
    return;
  }
  if (action == 'delete') {
    setState(() {
      _armedDeleteMessageId = messageId;
    });

    await _deleteArmedDmMessage(
      messageId: messageId,
      data: data,
    );
  }
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
    await _msgsRef.doc(messageId).delete();

    await Future.delayed(const Duration(milliseconds: 250));

    final latestSnap = await _msgsRef
        .orderBy('tsMs', descending: true)
        .get();

if (latestSnap.docs.isEmpty) {
  await _roomRef.update({
    'lastUpdatedMs': 0,
    'lastSenderId': '',
    'lastText': FieldValue.delete(),
  });
  return;
}

String lastText = '';
String lastSenderId = '';
int lastUpdatedMs = 0;

for (final doc in latestSnap.docs) {
      if (doc.id == messageId) continue;

      final m = doc.data();
      final type = (m['type'] ?? 'text').toString();

      if (type == 'system') continue;

      lastSenderId = (m['senderId'] ?? '').toString();
      lastUpdatedMs = (m['tsMs'] is int) ? m['tsMs'] as int : 0;

      if (type == 'text') {
        lastText = (m['text'] ?? '').toString();
      } else if (type == 'image') {
        lastText = '📷 Photo';
      } else if (type == 'video') {
        lastText = '🎥 Video';
      } else if (type == 'sticker') {
        lastText = '🙂 Sticker';
      } else if (type == 'animatedEmoji') {
        final label = (m['text'] ?? '').toString().trim();
        lastText = label.isEmpty ? '✨ Animated Emoji' : '✨ $label';
      } else if (type == 'voice') {
        lastText = '🎙️ Voice message';
      } else {
        continue;
      }

      break;
    }

if (lastText.trim().isEmpty) {
  await _roomRef.update({
    'lastUpdatedMs': 0,
    'lastSenderId': '',
    'lastText': FieldValue.delete(),
  });
} else {
  await _roomRef.update({
    'lastUpdatedMs': lastUpdatedMs,
    'lastSenderId': lastSenderId,
    'lastText': lastText,
  });
}
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

void _flashMessageHighlight(String messageId) {
  if (!mounted) return;

  setState(() {
    _highlightedMessageIds.add(messageId);
  });

  Future.delayed(const Duration(milliseconds: 1200), () {
    if (!mounted) return;

    setState(() {
      _highlightedMessageIds.remove(messageId);
    });
  });
}

String _dmSearchDateLabel(int ms) {
  if (ms <= 0) return '';

  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  final now = DateTime.now();

  bool sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  final yesterday = DateTime(now.year, now.month, now.day - 1);

  if (sameDay(dt, now)) return 'Today';
  if (sameDay(dt, yesterday)) return 'Yesterday';

  return '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

String _dmSearchPreviewText(String text) {
  final clean = text.replaceAll('\n', ' ').trim();

  if (clean.length <= 90) return clean;

  return '${clean.substring(0, 90)}...';
}


void _runDmMessageSearch(String rawQuery) {
  _dmSearchDebounce?.cancel();

  _dmSearchDebounce = Timer(const Duration(milliseconds: 250), () {
    if (!mounted) return;

    final String q = rawQuery.trim().toLowerCase();

    if (q.isEmpty) {
      setState(() {
        _dmSearchQuery = '';
        _dmSearchResultMessageIds = <String>[];
      });
      return;
    }

    final List<String> results = _currentDmDocs
        .where((d) {
          final data = d.data();
          final String type = (data['type'] ?? 'text').toString();
          final String text = (data['text'] ?? '').toString();

          if (type != 'text') return false;
          return text.toLowerCase().contains(q);
        })
        .map((d) => d.id)
        .toList();

    setState(() {
      _dmSearchQuery = q;
      _dmSearchResultMessageIds = results;
    });
  });
}

void _closeDmMessageSearch() {
  _dmSearchDebounce?.cancel();

  setState(() {
    _dmSearchOpen = false;
    _dmSearchQuery = '';
    _dmSearchResultMessageIds = <String>[];
  });

  _dmSearchController.clear();
}

void _openDmMessageSearch() {
  setState(() {
    _dmSearchOpen = true;
  });
}

void _showDmHeartJumpNotification({
  required String messageId,
  required String fromUserId,
}) {
  if (!mounted) return;

  setState(() {
    _heartJumpMessageId = messageId;
    _heartJumpFromUserId = fromUserId;
    _heartJumpShownAtMs = DateTime.now().millisecondsSinceEpoch;
  });

  Future.delayed(const Duration(seconds: 6), () {
    if (!mounted) return;

    final int nowMs = DateTime.now().millisecondsSinceEpoch;

    if (nowMs - _heartJumpShownAtMs < 5900) return;

    setState(() {
      _heartJumpMessageId = null;
      _heartJumpFromUserId = null;
      _heartJumpShownAtMs = 0;
    });
  });
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
      type == 'sticker' ||
      type == 'animatedEmoji' ||
      type == 'voice';
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
    Icons.search_rounded,
    color: Color(0xFF46F5D6),
  ),
  title: const Text(
    'Search Messages',
    style: TextStyle(color: Colors.white),
  ),
  onTap: () {
    Navigator.pop(sheetContext);
    _openDmMessageSearch();
  },
),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_rounded,
                  color: Color(0xFF46F5D6),
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _pickAndSendDmCameraPhoto();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.sticky_note_2_outlined,
                  color: Color(0xFF46F5D6),
                ),
                title: const Text(
                  'Sticker',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  _openDmStickerPicker();
                },
              ),
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
                  Icons.mic_rounded,
                  color: Color(0xFF46F5D6),
                ),
                title: const Text(
                  'Voice Message',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  _openDmVoiceRecorderSheet();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
  
}
void _openDmVoiceRecorderSheet() {
  final double uiScale = mysticUiScale(context);

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.black.withOpacity(0.94),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16 * uiScale,
            18 * uiScale,
            16 * uiScale,
            24 * uiScale,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tap the mic to record',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * uiScale,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 18 * uiScale),
              TapToRecordMicButton(
                size: 72 * uiScale,
                iconSize: 46 * uiScale,
                uiScale: uiScale,
                onSendVoice: (filePath, durationMs) async {
                  Navigator.pop(sheetContext);
                  await _sendDmVoiceMessage(
                    filePath: filePath,
                    durationMs: durationMs,
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _sendDmVoiceMessage({
  required String filePath,
  required int durationMs,
}) async {
  final int nowMs = DateTime.now().millisecondsSinceEpoch;
  final docRef = _msgsRef.doc();

  final String storagePath =
      'dm_rooms/${widget.roomId}/voice/${docRef.id}.m4a';

  try {
    await docRef.set({
      'type': 'voice',
      'senderId': widget.currentUserId,
      'text': '',
      'tsMs': nowMs,
      'mediaUrl': '',
      'voiceUrl': '',
      'voicePath': filePath,
      'voiceDurationMs': durationMs,
      'storagePath': storagePath,
      'heartReactorIds': <String>[],
      'replyToMessageId': _replyToMessageId,
      'replyToSenderId': _replyToSenderId,
      'replyToSenderName': _replyToSenderName,
      'replyToText': _replyToText,
    });

    final ref = FirebaseStorage.instance.ref(storagePath);

    await ref.putFile(
      File(filePath),
      SettableMetadata(contentType: 'audio/mp4'),
    );

    final String downloadUrl = await ref.getDownloadURL();

    await docRef.update({
      'mediaUrl': downloadUrl,
      'voiceUrl': downloadUrl,
      'voicePath': downloadUrl,
    });

    await _roomRef.set({
      'lastUpdatedMs': nowMs,
      'lastSenderId': widget.currentUserId,
      'lastText': '🎙️ Voice message',
    }, SetOptions(merge: true));

    try {
      Sfx.I.playSend();
    } catch (_) {}

    setState(() {
      _replyToMessageId = null;
      _replyToSenderId = null;
      _replyToSenderName = null;
      _replyToText = null;
    });

    _scrollToBottom(keepFocus: false);
  } catch (e) {
    try {
      await docRef.delete();
    } catch (_) {}

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not send voice message: $e'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
Future<void> _pickAndSendDmCameraPhoto() async {
  final XFile? picked = await _mediaPicker.pickImage(
    source: ImageSource.camera,
    imageQuality: 82,
  );

  if (picked == null) return;

  final String path = picked.path;
  final int nowMs = DateTime.now().millisecondsSinceEpoch;

  final docRef = _msgsRef.doc();

  final String fileExt = path.split('.').last.toLowerCase();
  final String storagePath =
      'dm_rooms/${widget.roomId}/media/${docRef.id}.$fileExt';

  try {
    await docRef.set({
      'type': 'image',
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
      'lastText': '📷 Photo',
    }, SetOptions(merge: true));

    _scrollToBottom(keepFocus: false);
  } catch (e) {
    try {
      await docRef.delete();
    } catch (_) {}

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not send camera photo: $e'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
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
  showMysticStickerPickerSheet(
    context: context,
    currentUserId: widget.currentUserId,
    onCreateSticker: (localFilePath, ts) async {
      await _sendNewDmStickerFromPicker(
        localFilePath: localFilePath,
        nowMs: ts,
      );
    },
    onSendArchivedSticker: (stickerUrl, storagePath, ts) async {
      await _sendArchivedDmStickerFromPicker(
        stickerUrl: stickerUrl,
        storagePath: storagePath,
        nowMs: ts,
      );
    },
    onSendAnimatedEmoji: (emoji, ts) async {
      await _sendAnimatedEmojiDmMessage(
        emoji: emoji,
        nowMs: ts,
      );
    },
  );
}
Future<void> _sendAnimatedEmojiDmMessage({
  required MysticAnimatedEmoji emoji,
  required int nowMs,
}) async {
  await _msgsRef.add({
    'type': 'animatedEmoji',
    'senderId': widget.currentUserId,
    'text': emoji.label,
    'tsMs': nowMs,
    'animatedEmojiId': emoji.id,
    'ownerUserId': emoji.ownerUserId,
    'frame1Asset': emoji.frame1Asset,
    'frame2Asset': emoji.frame2Asset,
    'canBeSaved': false,
    'heartReactorIds': <String>[],
    'replyToMessageId': null,
    'replyToSenderId': null,
    'replyToSenderName': null,
    'replyToText': null,
  });

  await _roomRef.set({
    'lastUpdatedMs': nowMs,
    'lastSenderId': widget.currentUserId,
    'lastText': '✨ ${emoji.label}',
  }, SetOptions(merge: true));

  try {
    Sfx.I.playSend();
  } catch (_) {}

  _scrollToBottom(keepFocus: false);
}
Future<void> _sendNewDmStickerFromPicker({
  required String localFilePath,
  required int nowMs,
}) async {
  final docRef = _msgsRef.doc();

  final String storagePath =
      'users/${widget.currentUserId}/stickers/${docRef.id}.png';

  await docRef.set({
    'type': 'sticker',
    'senderId': widget.currentUserId,
    'text': '',
    'tsMs': nowMs,
    'stickerUrl': '',
    'stickerLocalPath': localFilePath,
    'storagePath': storagePath,
    'heartReactorIds': <String>[],
    'replyToMessageId': null,
    'replyToSenderId': null,
    'replyToSenderName': null,
    'replyToText': null,
  });

  final ref = FirebaseStorage.instance.ref(storagePath);

  final uploadSnap = await ref.putFile(
    File(localFilePath),
    SettableMetadata(contentType: 'image/png'),
  );

  final String stickerUrl = await uploadSnap.ref.getDownloadURL();

  await FirebaseFirestore.instance
      .collection('users')
      .doc(widget.currentUserId)
      .collection('stickers')
      .doc(docRef.id)
      .set({
    'stickerUrl': stickerUrl,
    'storagePath': storagePath,
    'createdBy': widget.currentUserId,
    'createdAt': FieldValue.serverTimestamp(),
  });

  await docRef.update({
    'stickerUrl': stickerUrl,
    'stickerLocalPath': null,
    'storagePath': storagePath,
  });

  await _roomRef.set({
    'lastUpdatedMs': nowMs,
    'lastSenderId': widget.currentUserId,
    'lastText': '🙂 Sticker',
  }, SetOptions(merge: true));

  try {
    Sfx.I.playSend();
  } catch (_) {}

  _scrollToBottom(keepFocus: false);
}

Future<void> _sendArchivedDmStickerFromPicker({
  required String stickerUrl,
  required String storagePath,
  required int nowMs,
}) async {
  await _msgsRef.add({
    'type': 'sticker',
    'senderId': widget.currentUserId,
    'text': '',
    'tsMs': nowMs,
    'stickerUrl': stickerUrl,
    'stickerLocalPath': null,
    'storagePath': storagePath,
    'heartReactorIds': <String>[],
    'replyToMessageId': null,
    'replyToSenderId': null,
    'replyToSenderName': null,
    'replyToText': null,
  });

  await _roomRef.set({
    'lastUpdatedMs': nowMs,
    'lastSenderId': widget.currentUserId,
    'lastText': '🙂 Sticker',
  }, SetOptions(merge: true));

  try {
    Sfx.I.playSend();
  } catch (_) {}

  _scrollToBottom(keepFocus: false);
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
  _clockTimer?.cancel();

  _typingSub?.cancel();
  _typingStopTimer?.cancel();
  _sendTypingState(false);

  _clearActiveDmWith();

  _twinkleController.dispose();
  _enterController.dispose();

  _scroll.removeListener(_onDmScroll);
  _scroll.dispose();
_dmSearchDebounce?.cancel();
_dmSearchController.dispose();
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
  MysticTopStatusBar(
  now: _now,
  currentUserId: widget.currentUserId,
),
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
  onTap: () {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_armedDeleteMessageId != null) {
      setState(() {
        _armedDeleteMessageId = null;
      });
    }
  },
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
_currentDmDocs =
    List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);
_messageIdsInOrder = docs.map((d) => d.id).toList();

if (snap.hasData) {
  final Map<String, Set<String>> currentReactorsByMessageId =
      <String, Set<String>>{};

  for (final d in docs) {
    final data = d.data();

    final String messageId = d.id;
    final String senderId = (data['senderId'] ?? '').toString();
    final String type = (data['type'] ?? 'text').toString();

    if (type == 'system') continue;

    final Set<String> reactors =
        List<String>.from(data['heartReactorIds'] ?? const [])
            .map((e) => e.toString())
            .toSet();

    currentReactorsByMessageId[messageId] = reactors;

    if (_dmHeartSnapshotInitialized &&
        senderId == widget.currentUserId) {
      final Set<String> previous =
          _lastDmReactorsByMessageId[messageId] ?? <String>{};

      final Set<String> added = reactors.difference(previous);

      added.remove(widget.currentUserId);

      if (added.isNotEmpty) {
        final List<String> addedList = added.toList()..sort();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          _showDmHeartJumpNotification(
            messageId: messageId,
            fromUserId: addedList.first,
          );
        });
      }
    }
  }

  _lastDmReactorsByMessageId
    ..clear()
    ..addAll(currentReactorsByMessageId);

  _dmHeartSnapshotInitialized = true;
}
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
    messageType != 'sticker' &&
    messageType != 'animatedEmoji' &&
    messageType != 'voice') {
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
child: (messageType == 'image' ||
        messageType == 'video' ||
        messageType == 'sticker' ||
        messageType == 'animatedEmoji' ||
        messageType == 'voice')
                      ? _DmMediaMessageRow(
  isMe: isMe,
  messageType: messageType,
  mediaUrl: mediaUrl,
storagePath: messageType == 'voice'
    ? ((m['voicePath'] ?? '').toString().trim().isNotEmpty
        ? (m['voicePath'] ?? '').toString()
        : ((m['voiceUrl'] ?? '').toString().trim().isNotEmpty
            ? (m['voiceUrl'] ?? '').toString()
            : (m['mediaUrl'] ?? '').toString()))
    : (m['storagePath'] ?? '').toString(),  animatedEmojiId: (m['animatedEmojiId'] ?? '').toString(),
  frame1Asset: (m['frame1Asset'] ?? '').toString(),
  frame2Asset: (m['frame2Asset'] ?? '').toString(),
  onLongPressSticker: messageType == 'sticker'
      ? () async {
          final bool saved =
              await FirestoreChatService.saveStickerToArchiveFromMessage(
            userId: widget.currentUserId,
            stickerUrl: (m['stickerUrl'] ?? '').toString(),
            storagePath: (m['storagePath'] ?? '').toString(),
          );

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                saved
                    ? 'Sticker saved to your archive'
                    : 'Sticker is already in your archive',
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      : null,
  time: timeLabel,
  uiScale: uiScale,
  meUserId: widget.currentUserId,
  otherUserId: widget.otherUserId,
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
  meUserId: widget.currentUserId,
  otherUserId: widget.otherUserId,
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

if (_heartJumpMessageId != null && _heartJumpFromUserId != null)
  Positioned(
    right: s(18),
    bottom: _nearBottomCached ? s(18) : s(78),
    child: GestureDetector(
      onTap: () {
        final String? id = _heartJumpMessageId;
        if (id == null) return;

        setState(() {
          _heartJumpMessageId = null;
          _heartJumpFromUserId = null;
          _heartJumpShownAtMs = 0;
        });

        _jumpToMessage(id);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: s(12),
          vertical: s(9),
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.78),
          borderRadius: BorderRadius.circular(s(999)),
          border: Border.all(
            color: const Color(0xFFEF797E),
            width: s(1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF797E).withOpacity(0.35),
              blurRadius: s(14),
              spreadRadius: s(1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_rounded,
              color: const Color(0xFFEF797E),
              size: s(18),
            ),
            SizedBox(width: s(7)),
            Text(
              '${dmUsers[_heartJumpFromUserId!]?.name ?? _heartJumpFromUserId!} liked your message',
              style: TextStyle(
                color: Colors.white,
                fontSize: s(12),
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
  if (_dmSearchOpen)
  Positioned(
    left: s(14),
    right: s(14),
    top: s(14),
    child: Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: s(420),
        ),
        padding: EdgeInsets.all(s(12)),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.88),
          borderRadius: BorderRadius.circular(s(16)),
          border: Border.all(
            color: const Color(0xFF46F5D6).withOpacity(0.65),
            width: s(1.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: const Color(0xFF46F5D6),
                  size: s(22),
                ),
                SizedBox(width: s(8)),
                Expanded(
                  child: TextField(
                    controller: _dmSearchController,
                    autofocus: true,
                    onChanged: _runDmMessageSearch,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: s(14),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search messages...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _closeDmMessageSearch,
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: s(22),
                  ),
                ),
              ],
            ),

            if (_dmSearchQuery.isNotEmpty) ...[
              SizedBox(height: s(8)),
              Divider(
                color: Colors.white24,
                height: 1,
              ),
              SizedBox(height: s(8)),

              if (_dmSearchResultMessageIds.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: s(18)),
                  child: Text(
                    'No results',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: s(13),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _dmSearchResultMessageIds.length,
                    itemBuilder: (context, index) {
                      final id = _dmSearchResultMessageIds[index];

                      final data = _currentDmDocs
                          .firstWhere((d) => d.id == id)
                          .data();

                      final String sender =
                          dmUsers[(data['senderId'] ?? '').toString()]?.name ??
                              '';

                      final String text =
                          (data['text'] ?? '').toString();

                      final int ts =
                          (data['tsMs'] ?? 0) as int;

                      return GestureDetector(
                        onTap: () {
                          _closeDmMessageSearch();
                          _jumpToMessage(id);
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: s(8)),
                          padding: EdgeInsets.all(s(10)),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(s(12)),
                            border: Border.all(
                              color: Colors.white10,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      sender,
                                      style: TextStyle(
                                        color: const Color(0xFF46F5D6),
                                        fontWeight: FontWeight.w800,
                                        fontSize: s(12),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _dmSearchDateLabel(ts),
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: s(11),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: s(4)),
                              Text(
                                _dmSearchPreviewText(text),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: s(12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
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
  onOpenSearch: _openDmMessageSearch,
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



class _DmMessageOptionTile extends StatelessWidget {
  const _DmMessageOptionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(0.28),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 23,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}








