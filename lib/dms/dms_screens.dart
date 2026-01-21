import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
double mysticUiScale(BuildContext context) {
  // ✅ never upscale above design (prevents overflow on wide devices)
  const double designWidth = 393.0;       // baseline you already tuned
  const double maxWidthForScale = 430.0;  // cap wide phones

  final double screenWidth = MediaQuery.of(context).size.width;
  final double effectiveWidth = min(screenWidth, maxWidthForScale);

  return (effectiveWidth / designWidth).clamp(0.85, 1.0);
}

/// =======================================
/// DMs module (NO dependency on Group Chat)
/// Owns:
/// - DmsListScreen (rooms list)
/// - DmChatScreen (DM room UI)
/// - Star background overlay for DMs list
/// - Minimal DM bubble + input bar
///
/// Uses SAME storage keys as your current ChatScreen:
/// - room_messages__<roomId> : List<Map>
/// - room_meta__<roomId>     : { lastUpdatedMs, lastSenderId }
/// - lastReadMs__<me>__<roomId> : int
/// =======================================

class DmUser {
  final String id;
  final String name;
  final String? avatarPath;

  const DmUser({
    required this.id,
    required this.name,
    this.avatarPath,
  });
}

// ✅ Keep DM users INSIDE DM module (no import from group files)
const Map<String, DmUser> dmUsers = {
  'joy': DmUser(id: 'joy', name: 'Joy'),
  'adi': DmUser(id: 'adi', name: 'Adi★'),
  'lian': DmUser(id: 'lian', name: 'Lian'),
  'danielle': DmUser(id: 'danielle', name: 'Danielle'),
  'lera': DmUser(id: 'lera', name: 'Lera'),
  'lihi': DmUser(id: 'lihi', name: 'Lihi'),
  'tal': DmUser(id: 'tal', name: 'Tal'),
};

String mysticTimestampFromMs(int ms) {
  if (ms <= 0) return '';

  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  final dd = dt.day.toString().padLeft(2, '0');
  final mm = dt.month.toString().padLeft(2, '0');
  final yy = (dt.year % 100).toString().padLeft(2, '0');

  final isPm = dt.hour >= 12;
  final ampm = isPm ? 'PM' : 'AM';

  int hh = dt.hour % 12;
  if (hh == 0) hh = 12;

  final hhStr = hh.toString().padLeft(2, '0');
  final minStr = dt.minute.toString().padLeft(2, '0');

  return '$dd/$mm/$yy $ampm $hhStr:$minStr';
}
String mysticTimeOnlyFromMs(int ms) {
  if (ms <= 0) return '';

  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  final isPm = dt.hour >= 12;
  final ampm = isPm ? 'PM' : 'AM';

  int hh = dt.hour % 12;
  if (hh == 0) hh = 12;

  final hhStr = hh.toString().padLeft(2, '0');
  final minStr = dt.minute.toString().padLeft(2, '0');

  return '$ampm $hhStr:$minStr';
}


class _DmEntry {
  final DmUser user;
  final String roomId;
  final int lastUpdatedMs;
  final bool unread;
  final String preview;

  const _DmEntry({
    required this.user,
    required this.roomId,
    required this.lastUpdatedMs,
    required this.unread,
    required this.preview,
  });
}

class DmsListScreen extends StatefulWidget {
  final String currentUserId;

  const DmsListScreen({super.key, required this.currentUserId});

  @override
  State<DmsListScreen> createState() => _DmsListScreenState();
}

class _DmsListScreenState extends State<DmsListScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _twinkleController;

  static const String _boxName = 'mystic_chat_storage';
  String _roomKey(String roomId) => 'room_messages__$roomId';
  String _metaKey(String roomId) => 'room_meta__$roomId';
  String _lastReadKeyFor(String roomId) =>
      'lastReadMs__${widget.currentUserId}__$roomId';

  @override
  void initState() {
    super.initState();
_twinkleController = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 6),
)..repeat();

  }

  @override
  void dispose() {
    _twinkleController.dispose();
    super.dispose();
  }

  String _dmRoomId(String a, String b) {
    final pair = [a, b]..sort();
    return 'dm_${pair[0]}_${pair[1]}';
  }

  Future<List<_DmEntry>> _loadDmEntries() async {
    final box = await Hive.openBox(_boxName);
    final prefs = await SharedPreferences.getInstance();

    final others = dmUsers.values
        .where((u) => u.id != widget.currentUserId)
        .toList();

    final entries = <_DmEntry>[];

    for (final u in others) {
      final roomId = _dmRoomId(widget.currentUserId, u.id);

      final meta = box.get(_metaKey(roomId));
      int lastUpdatedMs = 0;
      String lastSenderId = '';

      if (meta is Map) {
        if (meta['lastUpdatedMs'] is int) {
          lastUpdatedMs = meta['lastUpdatedMs'] as int;
        }
        final rawSender = meta['lastSenderId'];
        if (rawSender != null) lastSenderId = rawSender.toString();
      }

      // preview: last text message
      String preview = 'Tap to open chat';
      final raw = box.get(_roomKey(roomId));
      if (raw is List) {
        for (int i = raw.length - 1; i >= 0; i--) {
          final m = raw[i];
          if (m is Map && (m['type'] ?? 'text').toString() == 'text') {
            final t = (m['text'] ?? '').toString().trim();
            if (t.isNotEmpty) {
              preview = t;
              break;
            }
          }
        }
      }

      final lastReadMs = prefs.getInt(_lastReadKeyFor(roomId)) ?? 0;
      final unread =
          (lastUpdatedMs > lastReadMs) && (lastSenderId != widget.currentUserId);

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

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              sizeMultiplier: 1.0,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const _DmTopBar(),

Expanded(
  child: Builder(
    builder: (context) {
      final double uiScale = mysticUiScale(context);
      double s(double v) => v * uiScale;

      return FutureBuilder<List<_DmEntry>>(
        future: _loadDmEntries(),
        builder: (context, snap) {
          final items = snap.data ?? const <_DmEntry>[];

          return ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: s(14),
              vertical: s(12),
            ),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(height: s(12)), // יותר אוויר
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
    );
  }
}

/// =======================================
/// DM TOP BAR (your PNG)
/// =======================================
class _DmTopBar extends StatelessWidget {
  const _DmTopBar();

  static const double _resourceBarHeight = 34;
  static const double _barAspect = 2048 / 212;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // “status bar” spacer like Mystic
          SizedBox(
            height: _resourceBarHeight,
            width: double.infinity,
            child: Container(color: Colors.transparent),
          ),

          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final barH = w / _barAspect;

              return SizedBox(
                width: w,
                height: barH,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/ui/TextMessageBarMenu.png',
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.center,
                      ),
                    ),

                    // ✅ Title: "Text Message"
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Text Message',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w300,
                          height: 1.0,
                        ),
                      ),
                    ),

                    // back tap area (left)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).pop(),
                        child: const SizedBox(
                          width: 72,
                          height: double.infinity,
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
    );
  }
}

class _MysticNewBadge extends StatelessWidget {
  const _MysticNewBadge();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(1.1),
      child: Container(
        color: const Color(0xFFFF6769), // #ff6769

        padding: const EdgeInsets.symmetric(horizontal: 0.7, vertical: 0.15),
        child: const Text(
          'NEW',
          textHeightBehavior: TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          style: TextStyle(
            color: Colors.white,
           fontSize: 6.0,              // ⬅️ קטן יותר
fontWeight: FontWeight.w900, // ⬅️ יותר בולד

            height: 1.0,
            letterSpacing: 0.12,
          ),
        ),
      ),
    );
  }
}



/// =======================================
/// DM ROW TILE (same look you already tuned)
/// =======================================
class _DmRowTile extends StatelessWidget {
  final DmUser user;
  final VoidCallback onTap;

  final bool unread;
  final String previewText;
  final int lastUpdatedMs;

  final double uiScale;

  const _DmRowTile({
    required this.user,
    required this.onTap,
    required this.unread,
    required this.previewText,
    required this.lastUpdatedMs,
    required this.uiScale,
  });

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * uiScale;

    final double tileHeight = s(90);
    final double avatarSize = s(72);

    final double outerFrameThickness = s(3.2);
    final double innerDarkStroke = s(1.1);

    final double gapAfterAvatar = s(10);
    final double innerLeftPadding = s(10);
    final double rightInset = s(8);

    // ✅ envelope a bit bigger
    final double envelopeBoxW = s(46);
    final double envelopeSize = s(42); // ⬅️ קצת יותר גדולה


    // ✅ envelope a bit lower
    final double envelopeBottomPad = s(6.5); // ⬅️ יורדת קצת

    const Color unreadTeal = Color(0xFF46F5D6);

    final Color frameColor =
        unread ? unreadTeal.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.88);

    final String envelopeAsset = unread
        ? 'assets/ui/DMSmessageUnread.png'
        : 'assets/ui/DMSmessageRead.png';

    final String ts = mysticTimestampFromMs(lastUpdatedMs);

    // ✅ compute TOP of envelope inside the Stack so NEW can align to it
    final double envelopeTop =
        tileHeight - envelopeBottomPad - envelopeSize;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: tileHeight,
        child: Container(
          decoration: BoxDecoration(
border: Border.all(color: frameColor, width: outerFrameThickness),
),
child: Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: Colors.black.withValues(alpha: 0.65),
      width: innerDarkStroke,
    ),
    color: const Color(0x80555555),
  ),

  // 👇 עטיפת הפונט – כאן זה נכון
  child: DefaultTextStyle(
    style: const TextStyle(fontFamily: 'NanumGothic'),
    child: Stack(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            innerLeftPadding,
            0,
            rightInset,
            0,
          ),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: avatarSize,
                    height: avatarSize,
                    child: Container(
                      color: Colors.black,
                      alignment: Alignment.center,
                      child: Text(
                        user.name.characters.first.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: s(22),
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: gapAfterAvatar),

                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: unread
                                    ? (envelopeBoxW + s(32) + s(12))
                                    : (envelopeBoxW + s(8)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: s(8)),
                                  Text(
                                    user.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                     fontSize: s(16.0),        // ⬅️ קצת יותר קטן
fontWeight: FontWeight.w600,

                                      height: 1.0,
                                    ),
                                  ),

                                  // ✅ preview a bit higher (less gap)
                                  SizedBox(height: s(14)),

                                  Text(
                                    (previewText.trim().isEmpty)
                                        ? 'Tap to open chat'
                                        : previewText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.70),
                                      fontSize: s(14),
                                      fontWeight: FontWeight.w600,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ✅ envelope
                      Positioned(
                        right: 0,
                        bottom: envelopeBottomPad,
                        child: SizedBox(
                          width: envelopeBoxW,
                          height: envelopeSize,
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: SizedBox(
                              width: envelopeSize,
                              height: envelopeSize,
                              child: Image.asset(
                                envelopeAsset,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.mail_outline,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: s(22),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ✅ NEW: align TOP with envelope TOP
                      if (unread)
                        Positioned(
                          // put it to the left of envelope
                          right: envelopeSize + s(6),
                          // EXACT same top as envelope top
                          top: envelopeTop + s(2), // ⬅️ אותו offset כמו המעטפה, נשאר מיושר

                          child: const _MysticNewBadge(),
                        ),
                    ],
                  ),
                ),

                if (ts.isNotEmpty)
                  Positioned(
                    top: s(6),
                    right: s(6),
                    child: Text(
  ts,
  style: TextStyle(
    color: Colors.white.withValues(alpha: 0.78),
    fontSize: s(11.0),          // ⬅️ קטן יותר
    fontWeight: FontWeight.w700, // ⬅️ יותר בולד


                        height: 1.0,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    )
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
    with SingleTickerProviderStateMixin {

  static const String _boxName = 'mystic_chat_storage';

  final ScrollController _scroll = ScrollController();
  final TextEditingController _c = TextEditingController();
  final FocusNode _focus = FocusNode();
late final AnimationController _twinkleController;

  bool _isTyping = false;

  List<Map<String, dynamic>> _messages = [];

  String _roomKey() => 'room_messages__${widget.roomId}';
  String _metaKey() => 'room_meta__${widget.roomId}';
  String _lastReadKey() =>
      'lastReadMs__${widget.currentUserId}__${widget.roomId}';

  Future<Box> _box() => Hive.openBox(_boxName);

  Future<void> _markReadNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReadKey(), DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _load() async {
    final box = await _box();
    final raw = box.get(_roomKey());

    if (raw is List) {
      _messages = raw.whereType<Map>().map((m) {
        final mm = Map<String, dynamic>.from(m);
        // normalize
        mm['type'] = (mm['type'] ?? 'text').toString();
        mm['senderId'] = (mm['senderId'] ?? '').toString();
        mm['text'] = (mm['text'] ?? '').toString();
        return mm;
      }).toList();
    } else {
      _messages = <Map<String, dynamic>>[];
      await _save(updateMeta: false);
    }

    if (mounted) setState(() {});
  }

  Future<void> _save({required bool updateMeta, String? lastSenderId}) async {
    final box = await _box();
    await box.put(_roomKey(), _messages);

    if (updateMeta) {
      await box.put(_metaKey(), <String, dynamic>{
        'lastUpdatedMs': DateTime.now().millisecondsSinceEpoch,
        'lastSenderId': (lastSenderId ?? '').toString(),
      });
    }
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

  void _send() async {
    final text = _c.text.trim();
    if (text.isEmpty) return;

    setState(() {
_messages.add({
  'type': 'text',
  'senderId': widget.currentUserId,
  'text': text,
  'ts': DateTime.now().millisecondsSinceEpoch, // ⬅️ שעה
});

      _c.clear();
      _isTyping = true;
    });

    await _save(updateMeta: true, lastSenderId: widget.currentUserId);

    _scrollToBottom(keepFocus: true);
  }

  @override
  void initState() {
    super.initState();

    // ✅ Twinkle animation controller (same as DMs list)
    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _c.addListener(() {
      final hasText = _c.text.trim().isNotEmpty;
      final shouldType = _focus.hasFocus && hasText;
      // no spam; we only use it for UI state
      if (_isTyping != shouldType && mounted) {
        setState(() => _isTyping = true);
      }
    });

    _load().then((_) async {
      await _markReadNow();
      if (mounted) _scrollToBottom();
    });

    _box().then((box) {
      box.watch(key: _roomKey()).listen((_) async {
        await _load();
        if (!mounted) return;
        _scrollToBottom();
      });
    });
  }


  @override
  void dispose() {
    _twinkleController.dispose();
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
    textScaler: const TextScaler.linear(1.0), // ✅ נועל טקסט שלא יתפוצץ במכשירים
  ),
  child: Scaffold(
    backgroundColor: Colors.black,
    body: Column(
      children: [

          // ✅ DM room name bar (PNG) + title overlay + back tap area
          // ✅ DM room name bar (PNG) scaled like the DMs list
          SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // same “status bar” spacer height
                const SizedBox(
                  height: 34,
                  width: double.infinity,
                ),

                LayoutBuilder(
                  builder: (context, c) {
                    // IMPORTANT: match the same aspect logic style as the list bar
                    const double barAspect = 2048 / 212; // adjust if your PNG differs
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
                              errorBuilder: (_, __, ___) =>
                                  Container(color: Colors.black),
                            ),
                          ),

// ✅ Center title (character name) + small envelope icon
Align(
  alignment: Alignment.center,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 80),
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


                          // ✅ Back tap area
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Navigator.of(context).pop(),
                              child: const SizedBox(
                                width: 72,
                                height: double.infinity,
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
  child: Stack(
    children: [
      // ✅ Same star background as DMs list
      Positioned.fill(
        child: Image.asset(
          'assets/backgrounds/StarsBG.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),

      // ✅ Same twinkle overlay as DMs list
      Positioned.fill(
        child: MysticStarTwinkleOverlay(
          animation: _twinkleController,
          starCount: 58,
          sizeMultiplier: 1.0,
        ),
      ),

      // ✅ Messages on top
      ListView.builder(
        controller: _scroll,
        padding: EdgeInsets.only(
          left: s(14),
          right: s(14),
          top: s(10),
          bottom: s(90),
        ),
        itemCount: _messages.length,
        itemBuilder: (context, i) {
          final m = _messages[i];
          if ((m['type'] ?? 'text') != 'text') {
            return const SizedBox.shrink();
          }

          final sender = (m['senderId'] ?? '').toString();
          final isMe = sender == widget.currentUserId;
          final text = (m['text'] ?? '').toString();
          final int ts = (m['ts'] is int) ? m['ts'] as int : 0;
final String timeLabel = mysticTimeOnlyFromMs(ts);


          // ✅ spacing logic:
          // - same sender streak: a bit more space than before
          // - switch between ISME <-> OTHERS: noticeably larger gap (Mystic vibe)
          String prevSender = '';
          if (i > 0) {
            final prev = _messages[i - 1];
            if ((prev['type'] ?? 'text') == 'text') {
              prevSender = (prev['senderId'] ?? '').toString();
            }
          }

          final bool switchedSender =
              (prevSender.isNotEmpty && prevSender != sender);

          final double sameSenderGap = s(22);
          final double switchedSenderGap = s(34);

          final double bottomGap =
              switchedSender ? switchedSenderGap : sameSenderGap;

          return Padding(
            padding: EdgeInsets.only(bottom: bottomGap),
child: _DmMessageRow(
  isMe: isMe,
  text: text,
  time: timeLabel,
  uiScale: uiScale,
  meLetter: (dmUsers[widget.currentUserId]?.name.characters.first ?? ' ').toUpperCase(),
  otherLetter: (dmUsers[widget.otherUserId]?.name.characters.first ?? ' ').toUpperCase(),
),



          );
        },
      ),
    ],
  ),
),


          _DmBottomBar(
            height: s(80),
            isTyping: _isTyping,
            onTapTypeMessage: _onTapType,
            controller: _c,
            focusNode: _focus,
            onSend: _send,
            uiScale: uiScale,
        ),
      ],
    ), // Column
  ), // Scaffold
); // MediaQuery

    
  }
}

/// =======================================
/// DM message row (TEMP bubble placeholder)
/// Later we replace with your exact DMSbubble asset logic.
/// =======================================
class _DmMessageRow extends StatelessWidget {
  final bool isMe;
  final String text;
  final String time;
  final double uiScale;

  // ✅ NEW
  final String meLetter;
  final String otherLetter;

  const _DmMessageRow({
    required this.isMe,
    required this.text,
    required this.time,
    required this.uiScale,
    required this.meLetter,
    required this.otherLetter,
  });

  @override
  Widget build(BuildContext context) {

    double s(double v) => v * uiScale;

    return LayoutBuilder(
      builder: (context, constraints) {
        const Color bodyFill = Color(0xFF4A4A4A);
        final Color borderColor = isMe ? Colors.white : const Color(0xFF46F5D6);
        const Color textColor = Colors.white;

        final double strokeW = s(2);

        final String cornerAsset = isMe
            ? 'assets/ui/DMSbubbleCornerISME.png'
            : 'assets/ui/DMSbubbleCornerOTHERS.png';

        // 🎛️ KNOBS
        final double cornerWidth = s(28);
        final double chamfer = s(8.5);
        final double cornerInset = s(0.5);

        // ✅ sizes
        final double avatarSize = s(48);
        final double gap = s(18);

        // ✅ time: fixed box width (Mystic vibe + stable layout)
        final double timeBoxW = s(64);
        final double timeGap = s(8);

        // ✅ desired bubble width like your preview
        final double desiredBubbleMax = s(232);

        // ✅ reserve ONLY what is actually on the row
        // Row also sits inside ListView padding (left/right 14) + your row padding (8),
        // so we add a small safety.
        final double reserved =
            avatarSize +
            gap +
            (time.isNotEmpty ? (timeBoxW + timeGap) : 0.0) +
            s(20); // safety

        final double availableForBubble = (constraints.maxWidth - reserved);

        final double bubbleMaxWidth = min(
          desiredBubbleMax,
          availableForBubble.clamp(s(140), desiredBubbleMax),
        );

        final bubble = ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: bubbleMaxWidth,
            minHeight: avatarSize,
          ),
          child: ClipPath(
            clipper: _ChamferBubbleClipper(isMe: isMe, chamfer: chamfer),
            child: CustomPaint(
              painter: _ChamferBubblePainter(
                isMe: isMe,
                chamfer: chamfer,
                fill: bodyFill,
                stroke: borderColor,
                strokeWidth: strokeW,
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      s(14),
                      s(12),
                      s(14),
                      s(10),
                    ),
child: Builder(
  builder: (context) {
    final bool isRtl = RegExp(r'[\u0590-\u05FF]').hasMatch(text);

    return Text(
      text,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      textAlign: TextAlign.start, // יתיישר נכון לפי הכיוון
      style: TextStyle(
        fontFamily: 'NanumGothic',
        color: textColor,
        fontSize: s(20),
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.3,
      ),
    );
  },
),




                  ),
                  Positioned(
                    top: cornerInset,
                    left: isMe ? cornerInset : null,
                    right: isMe ? null : cornerInset,
                    child: IgnorePointer(
                      child: Image.asset(
                        cornerAsset,
                        width: cornerWidth,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final leftAvatar = _Avatar(letter: 'A', size: avatarSize);
        final rightAvatar = _Avatar(letter: 'J', size: avatarSize);

        final timeWidget = (time.isEmpty)
            ? const SizedBox.shrink()
            : SizedBox(
                width: timeBoxW,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    time,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: s(14),
                      fontWeight: FontWeight.w300,
                      height: 1.0,
                    ),
                  ),
                ),
              );

final row = Padding(
  padding: EdgeInsets.only(
    right: isMe ? s(8) : 0.0,
    left: isMe ? 0.0 : s(8),
  ),
  child: Row(
    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,

    // ✅ זה מה שמחזיר את תמונת הפרופיל למעלה
    crossAxisAlignment: CrossAxisAlignment.start,

    children: [
      if (!isMe) ...[
        Align(
          alignment: Alignment.topCenter,
          child: leftAvatar,
        ),
        SizedBox(width: gap),
      ],

      // ✅ הזמן נשאר מיושר למטה מול הבועה בזכות ה-row הפנימי
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe && time.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(bottom: s(2)),
              child: Text(
                time,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: s(14),
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                ),
              ),
            ),
            SizedBox(width: s(8)),
          ],

          Padding(
            padding: EdgeInsets.only(
              left: isMe ? 0.0 : s(2.5),
              right: isMe ? s(2.5) : 0.0,
            ),
            child: bubble,
          ),

          if (!isMe && time.isNotEmpty) ...[
            SizedBox(width: s(8)),
            Padding(
              padding: EdgeInsets.only(bottom: s(2)),
              child: Text(
                time,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: s(14),
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ],
      ),

      if (isMe) ...[
        SizedBox(width: gap),
        Align(
          alignment: Alignment.topCenter,
          child: rightAvatar,
        ),
      ],
    ],
  ),
);


        // ✅ keep your tail + stem exactly as you had them
        final double tailSize = s(16.0);
        final double tailTop = s(0.0);
        final double tailToBubbleGap = s(5.0);
        final double stemBottomInset = s(0.0);

        final double tailOffset = (avatarSize + gap - tailToBubbleGap) - s(3.0);

        final String tailAsset = isMe
            ? 'assets/ui/DMSbubbleTailISME.png'
            : 'assets/ui/DMSbubbleTailOTHERS.png';

        return Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              foregroundPainter: _MysticStemFromPngTipPainter(
                isRightSide: isMe,
                tailOffset: tailOffset,
                tailSize: tailSize,
                tailTop: tailTop,
                stroke: borderColor,
                strokeWidth: strokeW,
                bottomInset: stemBottomInset,
                tipXFactorRight: 0.78,
                tipXFactorLeft: 0.22,
                tipYFactor: 0.96,
                tipYInset: 0.0,
                tipYOutset: 0.0,
                stemXNudge: isMe ? -s(11) : s(11),
                stemYNudge: -s(10),
              ),
              child: row,
            ),
            Positioned(
              top: tailTop,
              right: isMe ? tailOffset : null,
              left: isMe ? null : tailOffset,
              child: IgnorePointer(
                child: Image.asset(
                  tailAsset,
                  width: tailSize,
                  height: tailSize,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


class _Avatar extends StatelessWidget {
  final String letter;
  final double size;

  const _Avatar({
    required this.letter,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white24, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
  }
}

class _MysticStemOnlyPainter2 extends CustomPainter {
  final bool isRightSide;
  final double avatarSize;
  final double gap;

  final double tailSize;
  final double tailTop;

  final double strokeWidth;
  final Color stroke;
  final double bottomInset;

  _MysticStemOnlyPainter2({
    required this.isRightSide,
    required this.avatarSize,
    required this.gap,
    required this.tailSize,
    required this.tailTop,
    required this.strokeWidth,
    required this.stroke,
    required this.bottomInset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square
      ..isAntiAlias = true;

    final double avatarLeft = isRightSide ? (size.width - avatarSize) : 0.0;
    final double avatarRight = avatarLeft + avatarSize;

    final double tailLeft = isRightSide
        ? (avatarLeft - gap - tailSize)
        : (avatarRight + gap);

    final double stemX = isRightSide
        ? (tailLeft + tailSize * 0.78)
        : (tailLeft + tailSize * 0.22);

    final double yStart = (tailTop + tailSize).clamp(0.0, size.height);
    final double yBottom = (size.height - bottomInset).clamp(0.0, size.height);

    canvas.drawLine(
      Offset(stemX, yStart),
      Offset(stemX, yBottom),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _MysticStemOnlyPainter2 old) {
    return old.isRightSide != isRightSide ||
        old.avatarSize != avatarSize ||
        old.gap != gap ||
        old.tailSize != tailSize ||
        old.tailTop != tailTop ||
        old.strokeWidth != strokeWidth ||
        old.stroke != stroke ||
        old.bottomInset != bottomInset;
  }
}


class _MysticStemConnectorPainter extends CustomPainter {
  final bool isRightSide;
  final double avatarSize;
  final double gap;

  final double strokeWidth;
  final Color stroke;

  // stem controls
  final double stemBottomInset;

  // keep these fields so your existing call sites won't break,
  // but we will NOT draw the geometric tail anymore.
  final double tailW;
  final double tailH;
  final double tailTop;

  _MysticStemConnectorPainter({
    required this.isRightSide,
    required this.avatarSize,
    required this.gap,
    required this.strokeWidth,
    required this.stroke,
    required this.stemBottomInset,
    required this.tailW,
    required this.tailH,
    required this.tailTop,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square
      ..isAntiAlias = true;

    // Avatar location (same assumption as before)
    final double avatarLeft = isRightSide ? (size.width - avatarSize) : 0.0;
    final double avatarRight = avatarLeft + avatarSize;

    // Tail PNG is placed between avatar and bubble.
    // We match the same geometry for where the "tip" X should be.
    final double tailSize = tailW; // use tailW as size
    final double tailLeft = isRightSide ? (avatarLeft - gap - tailSize) : (avatarRight + gap);

    final double stemX = isRightSide
        ? (tailLeft + tailSize * 0.78)
        : (tailLeft + tailSize * 0.22);

    final double yStart = (tailTop + tailH).clamp(0.0, size.height);
    final double yBottom = (size.height - stemBottomInset).clamp(0.0, size.height);

    canvas.drawLine(
      Offset(stemX, yStart),
      Offset(stemX, yBottom),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _MysticStemConnectorPainter old) {
    return old.isRightSide != isRightSide ||
        old.avatarSize != avatarSize ||
        old.gap != gap ||
        old.strokeWidth != strokeWidth ||
        old.stroke != stroke ||
        old.stemBottomInset != stemBottomInset ||
        old.tailW != tailW ||
        old.tailH != tailH ||
        old.tailTop != tailTop;
  }
}

class _BubbleTail extends StatelessWidget {
  final bool isRight;
  final Color fill;
  final Color stroke;
  final double size;
  final double strokeWidth;

  const _BubbleTail({
    required this.isRight,
    required this.fill,
    required this.stroke,
    required this.size,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DetachedTailPainter(
        fill: fill,
        stroke: stroke,
        isRight: isRight,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _BubbleCornerShard extends StatelessWidget {
  final Color fill;
  final Color stroke;
  final double size;
  final double strokeWidth;
  final bool isLeftSide;

  const _BubbleCornerShard({
    required this.fill,
    required this.stroke,
    required this.size,
    required this.strokeWidth,
    required this.isLeftSide,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CornerShardPainter(
        fill: fill,
        stroke: stroke,
        strokeWidth: strokeWidth,
        isLeftSide: isLeftSide,
      ),
    );
  }
}

class _DetachedTailPainter extends CustomPainter {
  final Color fill;
  final Color stroke;
  final bool isRight;
  final double strokeWidth;

  _DetachedTailPainter({
    required this.fill,
    required this.stroke,
    required this.isRight,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final Path p = Path();

    if (isRight) {
      p.moveTo(0, h * 0.18);
      p.lineTo(w * 0.78, 0);
      p.lineTo(w, h * 0.50);
      p.lineTo(w * 0.78, h);
      p.lineTo(0, h * 0.82);
      p.close();
    } else {
      p.moveTo(w, h * 0.18);
      p.lineTo(w * 0.22, 0);
      p.lineTo(0, h * 0.50);
      p.lineTo(w * 0.22, h);
      p.lineTo(w, h * 0.82);
      p.close();
    }

    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;
    canvas.drawPath(p, fillPaint);

    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(p, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _DetachedTailPainter old) {
    return old.fill != fill ||
        old.stroke != stroke ||
        old.isRight != isRight ||
        old.strokeWidth != strokeWidth;
  }
}


class _CornerShardPainter extends CustomPainter {
  final Color fill;
  final Color stroke;
  final double strokeWidth;
  final bool isLeftSide;

  _CornerShardPainter({
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
    required this.isLeftSide,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // משולש קטן שמדמה "פינה חתוכה" בתוך הבועה
    final Path p = Path();

    if (isLeftSide) {
      // top-left
      p.moveTo(0, 0);
      p.lineTo(w, 0);
      p.lineTo(0, h);
      p.close();
    } else {
      // top-right
      p.moveTo(w, 0);
      p.lineTo(0, 0);
      p.lineTo(w, h);
      p.close();
    }

    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;
    canvas.drawPath(p, fillPaint);

    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(p, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _CornerShardPainter old) {
    return old.fill != fill ||
        old.stroke != stroke ||
        old.strokeWidth != strokeWidth ||
        old.isLeftSide != isLeftSide;
  }
}



/// =======================================
/// DM bottom bar (uses your TypeMessageButton/TypeBar/Send button assets)
/// BUT isolated here (no reuse of group BottomBorderBar).
/// =======================================
class _DmBottomBar extends StatelessWidget {
  final double height;
  final bool isTyping;
  final VoidCallback onTapTypeMessage;
  final VoidCallback onSend;
  final TextEditingController controller;
  final FocusNode focusNode;
  final double uiScale;

  const _DmBottomBar({
    required this.height,
    required this.isTyping,
    required this.onTapTypeMessage,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.uiScale,
  });

  static const double _typeButtonWidth = 260;
  static const double _sendBoxSize = 40;
  static const double _sendScale = 0.8;

  static const double _sendInset = 14;
  static const double _sendDown = 3;

  @override
  Widget build(BuildContext context) {
    if (height <= 0) return const SizedBox.shrink();
    double s(double v) => v * uiScale;

    return Container(
      height: height,
      width: double.infinity,
      color: Colors.black,
      padding: EdgeInsets.only(bottom: s(10)),
      child: isTyping ? _typingBar(s) : _typeMessageBar(s),
    );
  }

  Widget _typeMessageBar(double Function(double) s) {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: onTapTypeMessage,
          child: SizedBox(
            width: s(_typeButtonWidth),
            child: Image.asset(
              'assets/ui/TypeMessageButton.png',
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
        _inactiveSendButton(left: true, s: s),
        _inactiveSendButton(left: false, s: s),
      ],
    );
  }

  Widget _inactiveSendButton({required bool left, required double Function(double) s}) {
    return Positioned(
      left: left ? s(_sendInset) : null,
      right: left ? null : s(_sendInset),
      child: Transform.translate(
        offset: Offset(0, s(_sendDown)),
        child: IgnorePointer(
          ignoring: true,
          child: SizedBox(
            width: s(_sendBoxSize),
            height: s(_sendBoxSize),
            child: Transform.scale(
              scale: _sendScale,
              child: left
                  ? Transform.flip(
                      flipX: true,
                      child: Image.asset(
                        'assets/ui/SendMessageButton.png',
                        fit: BoxFit.contain,
                      ),
                    )
                  : Image.asset(
                      'assets/ui/SendMessageButton.png',
                      fit: BoxFit.contain,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typingBar(double Function(double) s) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: s(_typeButtonWidth),
          child: Stack(
            children: [
              Image.asset('assets/ui/TypeBar.png', fit: BoxFit.fitWidth),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: s(18), vertical: s(8)),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    maxLines: 1,
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: s(14),
                      height: 1.2,
                    ),
                    cursorColor: Colors.black,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Type...',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
            ],
          ),
        ),
        _activeSendButton(left: true, s: s),
        _activeSendButton(left: false, s: s),
      ],
    );
  }

  Widget _activeSendButton({required bool left, required double Function(double) s}) {
    return Positioned(
      left: left ? s(_sendInset) : null,
      right: left ? null : s(_sendInset),
      child: Transform.translate(
        offset: Offset(0, s(_sendDown)),
        child: GestureDetector(
          onTap: onSend,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: s(_sendBoxSize),
            height: s(_sendBoxSize),
            child: Transform.scale(
              scale: _sendScale,
              child: left
                  ? Transform.flip(
                      flipX: true,
                      child: Image.asset(
                        'assets/ui/SendMessageButton.png',
                        fit: BoxFit.contain,
                      ),
                    )
                  : Image.asset(
                      'assets/ui/SendMessageButton.png',
                      fit: BoxFit.contain,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// =======================================
/// Star twinkle overlay (DMs list only)
/// =======================================
class MysticStarTwinkleOverlay extends StatelessWidget {
  final Animation<double> animation;
  final int starCount;
  final double sizeMultiplier;

  const MysticStarTwinkleOverlay({
    super.key,
    required this.animation,
    this.starCount = 90,
    this.sizeMultiplier = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          painter: _StarTwinklePainter(
            t: animation.value,
            starCount: starCount,
            sizeMultiplier: sizeMultiplier,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _TwinkleStar {
  final double nx;
  final double ny;
  final double baseR;
  final double speed;
  final double phase;

  _TwinkleStar({
    required this.nx,
    required this.ny,
    required this.baseR,
    required this.speed,
    required this.phase,
  });
}

class _StarTwinklePainter extends CustomPainter {
  final double t;
  final int starCount;
  final double sizeMultiplier;
  late final List<_TwinkleStar> _stars;

  _StarTwinklePainter({
    required this.t,
    required this.starCount,
    required this.sizeMultiplier,
  }) {
    final rng = Random(42);

    _stars = List<_TwinkleStar>.generate(starCount, (i) {
      final tier = rng.nextDouble();
      final double baseR;
      if (tier < 0.78) {
        baseR = 0.9 + rng.nextDouble() * 0.6;
      } else if (tier < 0.96) {
        baseR = 1.6 + rng.nextDouble() * 0.9;
      } else {
        baseR = 2.8 + rng.nextDouble() * 1.2;
      }

      return _TwinkleStar(
        nx: rng.nextDouble(),
        ny: rng.nextDouble(),
        baseR: baseR,
        speed: 0.7 + rng.nextDouble() * 1.6,
        phase: rng.nextDouble() * pi * 2,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final tt = t * pi * 2;

    for (final s in _stars) {
      final x = s.nx * size.width;
      final y = s.ny * size.height;

      final wave = sin(tt * s.speed + s.phase);
      final alpha = (0.35 + 0.65 * (wave * 0.5 + 0.5)).clamp(0.12, 1.0);

      paint.color = Colors.white.withValues(alpha: alpha);


      final r = (s.baseR * sizeMultiplier).clamp(0.8, 12.0);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarTwinklePainter old) {
    return old.t != t ||
        old.starCount != starCount ||
        old.sizeMultiplier != sizeMultiplier;
  }
}



class _ChamferBubbleClipper extends CustomClipper<Path> {
  final bool isMe;
  final double chamfer;

  _ChamferBubbleClipper({required this.isMe, required this.chamfer});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final c = chamfer.clamp(0.0, w * 0.45);

    final p = Path();

    if (isMe) {
      // ✅ chamfer at TOP-LEFT (bubble on right, like Mystic)
      p.moveTo(c, 0);
      p.lineTo(w, 0);
      p.lineTo(w, h);
      p.lineTo(0, h);
      p.lineTo(0, c);
      p.close();
    } else {
      // ✅ chamfer at TOP-RIGHT (bubble on left, like Mystic)
      p.moveTo(0, 0);
      p.lineTo(w - c, 0);
      p.lineTo(w, c);
      p.lineTo(w, h);
      p.lineTo(0, h);
      p.close();
    }

    return p;
  }

  @override
  bool shouldReclip(covariant _ChamferBubbleClipper oldClipper) {
    return oldClipper.isMe != isMe || oldClipper.chamfer != chamfer;
  }
}

class _ChamferBubblePainter extends CustomPainter {
  final bool isMe;
  final double chamfer;
  final Color fill;
  final Color stroke;
  final double strokeWidth;

  _ChamferBubblePainter({
    required this.isMe,
    required this.chamfer,
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
  });

  Path _path(Size size) {
    return _ChamferBubbleClipper(isMe: isMe, chamfer: chamfer).getClip(size);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = _path(size);

    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;

    canvas.drawPath(p, fillPaint);

    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.miter;

    canvas.drawPath(p, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ChamferBubblePainter oldDelegate) {
    return oldDelegate.isMe != isMe ||
        oldDelegate.chamfer != chamfer ||
        oldDelegate.fill != fill ||
        oldDelegate.stroke != stroke ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}




class _MysticStemFromPngTipPainter extends CustomPainter {
  final bool isRightSide;

  // offset from the bubble-row edge (same value you use for Positioned tail)
  final double tailOffset;

  // tail image square size
  final double tailSize;

  // top offset of tail image
  final double tailTop;

  final Color stroke;
  final double strokeWidth;

  // how far above bottom the stem should stop
  final double bottomInset;

  // where inside the tail image the tip is (0..1)
  final double tipXFactorRight;
  final double tipXFactorLeft;

  // where inside the tail image the BOTTOM TIP is (0..1)
  final double tipYFactor;

  // move start point up/down relative to computed tip
  final double tipYInset;  // positive moves start upward
  final double tipYOutset; // positive moves start downward

  // ✅ NEW: pixel nudging for the stem X (negative = left, positive = right)
  final double stemXNudge;


// ✅ NEW: pixel nudging for the stem Y start (negative = up, positive = down)
final double stemYNudge;

  _MysticStemFromPngTipPainter({
    required this.isRightSide,
    required this.tailOffset,
    required this.tailSize,
    required this.tailTop,
    required this.stroke,
    required this.strokeWidth,
    required this.bottomInset,
    required this.tipXFactorRight,
    required this.tipXFactorLeft,
    required this.tipYFactor,
    this.tipYInset = 0.0,
    this.tipYOutset = 0.0,
    this.stemXNudge = 0.0,
    this.stemYNudge = 0.0,

  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square
      ..isAntiAlias = true;

    final double tailLeft = isRightSide
        ? (size.width - tailOffset - tailSize)
        : tailOffset;

    final double stemXBase = isRightSide
        ? (tailLeft + tailSize * tipXFactorRight)
        : (tailLeft + tailSize * tipXFactorLeft);

    // ✅ just shove it left/right
    final double stemX = (stemXBase + stemXNudge).clamp(0.0, size.width);

    final double tailTipY = tailTop + tailSize * tipYFactor;

   final double yStart =
    (tailTipY - tipYInset + tipYOutset + stemYNudge)
        .clamp(0.0, size.height);


    final double yBottom =
        (size.height - bottomInset).clamp(0.0, size.height);

    canvas.drawLine(
      Offset(stemX, yStart),
      Offset(stemX, yBottom),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _MysticStemFromPngTipPainter old) {
    return old.isRightSide != isRightSide ||
        old.tailOffset != tailOffset ||
        old.tailSize != tailSize ||
        old.tailTop != tailTop ||
        old.stroke != stroke ||
        old.strokeWidth != strokeWidth ||
        old.bottomInset != bottomInset ||
        old.tipXFactorRight != tipXFactorRight ||
        old.tipXFactorLeft != tipXFactorLeft ||
        old.tipYFactor != tipYFactor ||
        old.tipYInset != tipYInset ||
        old.tipYOutset != tipYOutset ||
        old.stemXNudge != stemXNudge;
  }
}



