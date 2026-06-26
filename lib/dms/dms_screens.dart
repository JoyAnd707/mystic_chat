import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../audio/bgm.dart';
import '../audio/sfx.dart';
import 'dart:async';
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
  late final AnimationController _twinkleController;
late final AnimationController _enterController;
late final Animation<double> _enterScale;
  bool _isTyping = false;




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

  Future<void> _markReadNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReadKey(), DateTime.now().millisecondsSinceEpoch);
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

  void _scrollToBottom({bool keepFocus = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      if (keepFocus) _focus.requestFocus();
    });
  }

  void _onTapType() {
    if (_isTyping) {
      _focus.requestFocus();
      return;
    }
    setState(() => _isTyping = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  Future<void> _send() async {
    final text = _c.text.trim();
    if (text.isEmpty) return;

    // 🔊 SFX — do NOT await
    try {
      Sfx.I.playSend();
    } catch (_) {}

    final nowMs = DateTime.now().millisecondsSinceEpoch;

 _c.clear();
setState(() {
  _isTyping = true;
  _replyToMessageId = null;
  _replyToSenderId = null;
  _replyToSenderName = null;
  _replyToText = null;
});

    // ✅ write message
    await _msgsRef.add({
      'type': 'text',
      'senderId': widget.currentUserId,
      'text': text,
      'tsMs': nowMs,
    });

    // ✅ update room meta for list + unread
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
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        if (mounted) {
          setState(() {
            _isTyping = false;
          });
        }
      }
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

    // ✅ ensure room exists + mark read
    _ensureRoomExists().then((_) async {
      await _markReadNow();
    });
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    _enterController.dispose();
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

                        if (snap.hasData) {
                          WidgetsBinding.instance.addPostFrameCallback((_) async {
                            await _markReadNow();
                          });
                        }

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (snap.hasData) _scrollToBottom();
                        });

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

                            if ((m['type'] ?? 'text') != 'text') {
                              return const SizedBox.shrink();
                            }

                            final sender = (m['senderId'] ?? '').toString();
                            final isMe = sender == widget.currentUserId;
                            final text = (m['text'] ?? '').toString();

                            final int ts =
                                (m['tsMs'] is int) ? m['tsMs'] as int : 0;

                            final String timeLabel =
                                mysticTimeOnlyFromMs(ts);

                            int prevTs = 0;
                            if (i > 0) {
                              final prev = docs[i - 1].data();
                              if ((prev['type'] ?? 'text') == 'text') {
                                prevTs = (prev['tsMs'] is int)
                                    ? prev['tsMs'] as int
                                    : 0;
                              }
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

      GestureDetector(
        behavior: HitTestBehavior.translucent,

        onHorizontalDragStart: (_) {
          _dragDx = 0.0;
        },

        onHorizontalDragUpdate: (details) {
          _dragDx += details.delta.dx;

          final bool swipeOk = _dragDx > 28;

          if (swipeOk) {
            _dragDx = 0.0;

            _setReplyTarget(
              messageId: docs[i].id,
              senderId: sender,
              text: text,
            );
          }
        },

        onHorizontalDragEnd: (_) {
          _dragDx = 0.0;
        },

        child: _DmMessageRow(
          isMe: isMe,
          text: text,
          time: timeLabel,
          uiScale: uiScale,
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
        ),
      ),
    ],
  ),
);
},
                        );
                        
                      },
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




