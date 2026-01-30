import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/chat_widgets.dart';
import '../audio/sfx.dart';
import '../audio/bgm.dart';
import '../bots/daily_fact_bot.dart';
import '../fx/heart_reaction_fly_layer.dart';
import 'dart:ui';
import '../firebase/firestore_chat_service.dart';
import '../firebase/auth_service.dart';
import '../services/presence_service.dart';
import '../widgets/new_messages_badge.dart'; // ✅ ADD THIS
import '../widgets/reply_preview_bar.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';


double mysticUiScale(BuildContext context) {
  // ✅ UI scale tuned for your Mystic layout.
  // This is the "older" behavior (before the wide-phone cap):
  // - can scale DOWN on smaller screens
  // - can scale UP a bit on wider screens (keeps your original look)
  const double designWidth = 393.0; // iPhone 15 Pro baseline
  final double screenWidth = MediaQuery.of(context).size.width;

  // Allow a little upscaling (this is what makes the layout look like your
  // earlier "perfect" version on wider previews/devices).
  return (screenWidth / designWidth).clamp(0.85, 1.15);
}




class _TemplateMenuResult {
  final BubbleTemplate template;
  final BubbleDecor decor;

  const _TemplateMenuResult({
    required this.template,
    required this.decor,
  });
}

String backgroundForHour(int hour) {
  // 00:00–00:59
  if (hour == 0) return 'assets/backgrounds/MidnightBG.png';

  // Night split:
  // 21:00–23:59  AND  01:00–06:59
  if ((hour >= 21 && hour <= 23) || (hour >= 1 && hour <= 6)) {
    return 'assets/backgrounds/NightBG.png';
  }

  // 07:00–11:59
  if (hour >= 7 && hour <= 11) return 'assets/backgrounds/MorningBG.png';

  // 12:00–16:59
  if (hour >= 12 && hour <= 16) return 'assets/backgrounds/NoonBG.png';

  // 17:00–20:59
  return 'assets/backgrounds/EveningBG.png';
}

Color usernameColorForHour(int hour) {
  // Morning + Noon => BLACK
  if (hour >= 7 && hour <= 16) {
    return Colors.black;
  }

  // Evening + Night + Midnight => WHITE
  return Colors.white;
}

Color timeColorForHour(int hour) {
  // Morning + Noon => BLACK
  if (hour >= 7 && hour <= 16) {
    return Colors.black;
  }

  // Evening + Night + Midnight => WHITE (as before)
  return Colors.white;
}


/// =======================
/// USERS
/// =======================
const bool kEnableDebugIncomingPreview = false;

const ChatUser joy =
    ChatUser(id: 'joy', name: 'Joy', bubbleColor: Color(0xFFDACFFF));
const ChatUser adi =
    ChatUser(id: 'adi', name: 'Adi★', bubbleColor: Color(0xFFFFCFF7));
const ChatUser lian =
    ChatUser(id: 'lian', name: 'Lian', bubbleColor: Color(0xFFFAC0C4));
const ChatUser danielle =
    ChatUser(id: 'danielle', name: 'Danielle', bubbleColor: Color(0xFFCFECFF));
const ChatUser lera =
    ChatUser(id: 'lera', name: 'Lera', bubbleColor: Color(0xFFFFFDCF));
const ChatUser lihi =
    ChatUser(id: 'lihi', name: 'Lihi', bubbleColor: Color(0xFFFFDDCF));
const ChatUser tal =
    ChatUser(id: 'tal', name: 'Tal', bubbleColor: Color(0xFFD7FFCF));
const ChatUser gacktoFacto = ChatUser(
  
  id: 'gackto_facto',
  name: 'Gackto Facto of the Day',
  bubbleColor: Color(0xFFCFFFEE),
  avatarPath: 'assets/avatars/gackto_facto.png',
);


const Map<String, ChatUser> users = {
  'joy': joy,
  'adi': adi,
  'lian': lian,
  'danielle': danielle,
  'lera': lera,
  'lihi': lihi,
  'tal': tal,
    'gackto_facto': gacktoFacto,

};



/// =======================
/// MESSAGE MODEL
/// =======================

enum ChatMessageType { text, system }

class ChatMessage {
  /// Firestore doc id (we use ts.toString())
  final String id;

  final ChatMessageType type;
  final String senderId;
  final String text;
  final int ts;

  final BubbleTemplate bubbleTemplate;
  final BubbleDecor decor;
  final String? fontFamily;

  final Set<String> heartReactorIds;

  // ✅ REPLY META (for preview inside the bubble)
  final String? replyToMessageId;
  final String? replyToSenderId;
  final String? replyToText;

  ChatMessage({
    required this.id,
    required this.type,
    required this.senderId,
    required this.text,
    required this.ts,
    this.bubbleTemplate = BubbleTemplate.normal,
    this.decor = BubbleDecor.none,
    this.fontFamily,
    Set<String>? heartReactorIds,

    // ✅ reply
    this.replyToMessageId,
    this.replyToSenderId,
    this.replyToText,
  }) : heartReactorIds = heartReactorIds ?? <String>{};

  ChatMessage copyWith({
    String? id,
    ChatMessageType? type,
    String? senderId,
    String? text,
    int? ts,
    BubbleTemplate? bubbleTemplate,
    BubbleDecor? decor,
    String? fontFamily,
    Set<String>? heartReactorIds,

    String? replyToMessageId,
    String? replyToSenderId,
    String? replyToText,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      ts: ts ?? this.ts,
      bubbleTemplate: bubbleTemplate ?? this.bubbleTemplate,
      decor: decor ?? this.decor,
      fontFamily: fontFamily ?? this.fontFamily,
      heartReactorIds: heartReactorIds ?? this.heartReactorIds,

      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      replyToText: replyToText ?? this.replyToText,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'type': type.name,
        'senderId': senderId,
        'text': text,
        'ts': ts,
        'bubbleTemplate': bubbleTemplate.name,
        'decor': decor.name,
        'fontFamily': fontFamily,
        'heartReactorIds': heartReactorIds.toList(),

        // ✅ reply fields
        'replyToMessageId': replyToMessageId,
        'replyToSenderId': replyToSenderId,
        'replyToText': replyToText,
      };

  static ChatMessage fromMap(Map m) {
    final typeStr = (m['type'] ?? 'text').toString();
    final type = ChatMessageType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => ChatMessageType.text,
    );

    final btStr = (m['bubbleTemplate'] ?? 'normal').toString();
    final bt = BubbleTemplate.values.firstWhere(
      (b) => b.name == btStr,
      orElse: () => BubbleTemplate.normal,
    );

    final decorStr = (m['decor'] ?? 'none').toString();
    final decor = BubbleDecor.values.firstWhere(
      (d) => d.name == decorStr,
      orElse: () => BubbleDecor.none,
    );

    final ff = m['fontFamily'];
    final fontFamily =
        (ff == null || ff.toString().trim().isEmpty) ? null : ff.toString();

    final int ts = (m['ts'] is int) ? (m['ts'] as int) : 0;

    final rawReactors = (m['heartReactorIds'] as List?) ?? const [];
    final reactors = rawReactors.map((e) => e.toString()).toSet();

    final rawId = m['id'];
final id = (rawId != null && rawId.toString().trim().isNotEmpty)
    ? rawId.toString()
    : '${ts}_${m['senderId'] ?? ''}_${(m['text'] ?? '').toString().hashCode}';


    return ChatMessage(
      id: id,
      type: type,
      senderId: (m['senderId'] ?? '').toString(),
      text: (m['text'] ?? '').toString(),
      ts: ts,
      bubbleTemplate: bt,
      decor: decor,
      fontFamily: fontFamily,
      heartReactorIds: reactors,

      // ✅ reply
      replyToMessageId: (m['replyToMessageId'] as String?)?.toString(),
      replyToSenderId: (m['replyToSenderId'] as String?)?.toString(),
      replyToText: (m['replyToText'] as String?)?.toString(),
    );
  }
}



class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String roomId;
  final String? title;

  /// ✅ If false -> NO background music in this room (DMs)
  final bool enableBgm;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.roomId,
    this.title,
    this.enableBgm = true, // default = group behavior
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}


/// ✅ סוג בועה לשליחה (תפריט)
enum BubbleStyle { normal, glow }


class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {

  static const double _topBarHeight = 0;
  static const double _bottomBarHeight = 80;
  static const double _redFrameTopGap = 0;
  StreamSubscription<List<Map<String, dynamic>>>? _roomSub;

VoidCallback? _onlineListener;
// =======================
// Creepy BG Easter Egg
// =======================
String? _bgOverride;
final ItemScrollController _itemScrollController = ItemScrollController();
final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

// ✅ IMPORTANT: cached "near bottom" state so UI rebuilds on scroll
bool _nearBottomCached = true;


late final AnimationController _bgFxCtrl;

// איפה שמכניסים את המילים לטריגר:
static const List<String> _creepyTriggers = <String>[
  'glitch',
  'Bug',
  'Saeran',
  'saeran'
  "סארן",
  "סיירן",
  "גליץ'",
  "'גליץ",
  "מנטה",
  "Mint",
  "Mint eye",
  "מינט איי",
  "גן עדן",
  "paradise",
  "searan",
  "Rika",
  "ריקה",
  "באג",
  "Savior",
  "סארן",
  'struct', // דוגמה – תוסיפי/תמחקי מה שבא לך
];

static const String _heartAsset = 'assets/reactions/HeartReaction.png';

bool _isNearBottom({int thresholdItems = 1}) {
  // thresholdItems = כמה פריטים מהסוף עדיין נחשב “למטה”
  final positions = _itemPositionsListener.itemPositions.value;
  if (positions.isEmpty) return true;

  final maxVisible = positions
      .where((p) => p.itemTrailingEdge > 0) // מופיע במסך
      .map((p) => p.index)
      .fold<int>(-1, (a, b) => a > b ? a : b);

  if (_messages.isEmpty) return true;

  final lastIndex = _messages.length - 1;
  return maxVisible >= (lastIndex - thresholdItems);
}

// =======================
// Reply (WhatsApp-like preview)
// =======================
ChatMessage? _replyTarget;

// highlight flash per message id
final Map<String, bool> _highlightByMsgId = <String, bool>{};

// drag accumulator
double _dragDx = 0.0;

String _replyPreviewText(String raw) {
  final s = raw.replaceAll('\n', ' ').trim();
  if (s.isEmpty) return '';
  if (s.length <= 70) return s;
  return '${s.substring(0, 70)}…';
}

void _setReplyTarget(ChatMessage msg) {
  if (!mounted) return;
  setState(() => _replyTarget = msg);
}

void _clearReplyTarget() {
  if (!mounted) return;
  setState(() => _replyTarget = null);
}

void _flashHighlight(String msgId) {
  if (!mounted) return;
  setState(() => _highlightByMsgId[msgId] = true);

  // ✅ exactly 1 second total, fade-out handled by AnimatedOpacity
  Future.delayed(const Duration(milliseconds: 1000), () {
    if (!mounted) return;
    setState(() => _highlightByMsgId[msgId] = false);
  });
}




Future<void> _jumpToMessageId(String messageId) async {
  final int index = _messages.indexWhere((m) => m.id == messageId);
  if (index < 0) return;

  if (!_itemScrollController.isAttached) return;

  await _itemScrollController.scrollTo(
    index: index,
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOut,
    alignment: 0.15, // קצת מתחת לראש, נראה טוב ל-reply jump
  );

  if (!mounted) return;
  _flashHighlight(messageId);
}


// =======================
// Unread Divider (last read boundary)
// =======================
int _lastReadTsCache = 0;
bool _lastReadLoaded = false;
bool _hideUnreadDivider = false;

// =======================
// NEW "messages below" badge (overlay)
// =======================
int _newBelowCount = 0;

// ✅ NEW: whether there is a mention below (so we can show @)
bool _newBelowHasMention = false;
// ✅ When I send a message, we wait for the Firestore snapshot that includes it.
// When we see that exact ts in the list -> scroll to bottom (even if list length didn't grow).
int _pendingScrollToBottomTs = 0;



/// ✅ counts only "real unread-ish" messages:
// - text only
// - not me
int _countAddedUnreadishMessages(List<ChatMessage> oldList, List<ChatMessage> newList) {
  if (newList.length <= oldList.length) return 0;

  final added = newList.sublist(oldList.length);
  int c = 0;

  for (final m in added) {
    if (m.type == ChatMessageType.text && m.senderId != widget.currentUserId) {
      c++;
    }
  }

  return c;
}

/// ✅ NEW: detect if ANY added message is a "mention" of me
/// In our app: "mention" == someone replied to MY message
bool _hasAddedMentionsOfMe(List<ChatMessage> oldList, List<ChatMessage> newList) {
  if (newList.length <= oldList.length) return false;

  final added = newList.sublist(oldList.length);

  for (final m in added) {
    if (m.type != ChatMessageType.text) continue;
    if (m.senderId == widget.currentUserId) continue;

    // ✅ mention rule
    if (m.replyToSenderId != null && m.replyToSenderId == widget.currentUserId) {
      return true;
    }
  }

  return false;
}



bool _hasUnreadNow() {
  if (!_lastReadLoaded) return false;

  // ✅ UNREAD is only for OTHER people's messages
  return _messages.any((m) =>
      m.type == ChatMessageType.text &&
      m.ts > 0 &&
      m.ts > _lastReadTsCache &&
      m.senderId != widget.currentUserId);
}

int _firstUnreadTsOrNull() {
  if (!_lastReadLoaded) return 0;

  // ✅ First unread from OTHER users only
  for (final m in _messages) {
    if (m.type != ChatMessageType.text) continue;
    if (m.ts <= 0) continue;

    if (m.ts > _lastReadTsCache && m.senderId != widget.currentUserId) {
      return m.ts;
    }
  }
  return 0;
}

Future<void> _loadLastReadTsOnce() async {
  if (_lastReadLoaded) return;
  _lastReadTsCache = await _loadLastReadTs();
  _lastReadLoaded = true;
}

Future<void> _markReadIfAtBottom() async {
  if (!_lastReadLoaded) return;

  // ✅ Don't auto-mark read immediately on entry
  if (_nowMs() < _blockAutoMarkReadUntilMs) return;

  if (!_isNearBottom()) return;

  // ✅ when user reaches bottom: badge disappears
if ((_newBelowCount != 0 || _newBelowHasMention) && mounted) {
  setState(() {
    _newBelowCount = 0;
    _newBelowHasMention = false;
  });
}


  final int lastTs = _latestTextTs();
  if (lastTs <= 0) return;

  // nothing to do
  if (lastTs <= _lastReadTsCache) return;

  _lastReadTsCache = lastTs;
  await _saveLastReadTs(lastTs);

  if (mounted) {
    setState(() {
      _hideUnreadDivider = true;
    });
  }
}


// =======================
// Scroll position restore
// =======================
bool _didRestoreScroll = false;
double _savedScrollOffset = 0.0;
Timer? _scrollSaveDebounce;

// ✅ IMPORTANT: don't save offset until we've restored/jumped once
bool _allowScrollOffsetSaves = false;
int _blockAutoMarkReadUntilMs = 0;


// =======================
// Unread jump helpers (NO GlobalKeys inside a lazy list)
// =======================

// ✅ Stable key per message (safe for ScrollablePositionedList)
Key _keyForMsg(ChatMessage m) => ValueKey<String>('msg_${m.id}');

// ✅ Stable key for UNREAD divider (also NOT GlobalKey)
final Key _unreadDividerKey = ValueKey<String>('unread_divider');



String _scrollOffsetPrefsKey() =>
    'scrollOffset__${widget.currentUserId}__${widget.roomId}';

Future<void> _loadSavedScrollOffset() async {
  final prefs = await SharedPreferences.getInstance();
  _savedScrollOffset = prefs.getDouble(_scrollOffsetPrefsKey()) ?? 0.0;
}

Future<void> _initScrollAndStream() async {
  await _loadSavedScrollOffset();
  if (!mounted) return;

  // attach listener ONLY after we loaded the saved offset
 // ScrollablePositionedList doesn't use _scrollController.
// We listen via _itemPositionsListener instead.


  // start stream AFTER we know what to restore to
  _startFirestoreSubscription();
}


Future<void> _saveScrollOffsetNow() async {
  if (!_scrollController.hasClients) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(_scrollOffsetPrefsKey(), _scrollController.offset);
}

void _onPositionsChanged() {
  if (!mounted) return;

  // ✅ Always compute and cache "near bottom"
  final bool nearBottom = _isNearBottom();

  // ✅ Force rebuild when near-bottom changes (this fixes the button "stuck" issue)
  if (nearBottom != _nearBottomCached) {
    setState(() {
      _nearBottomCached = nearBottom;
    });
  }

  // ✅ Reveal/hide UNREAD divider based on being near bottom
  if (_lastReadLoaded && _hasUnreadNow()) {
    if (nearBottom) {
      if (!_hideUnreadDivider) {
        setState(() => _hideUnreadDivider = true);
      }
    } else {
      if (_hideUnreadDivider) {
        setState(() => _hideUnreadDivider = false);
      }
    }
  } else {
    // no unread at all -> keep hidden
    if (!_hideUnreadDivider) {
      setState(() => _hideUnreadDivider = true);
    }
  }

  // ✅ Don't do side-effects during initial open
  if (!_allowScrollOffsetSaves) return;

  _scrollSaveDebounce?.cancel();
  _scrollSaveDebounce = Timer(const Duration(milliseconds: 250), () async {
    if (!mounted) return;

    // ✅ mark read when user is at bottom
    await _markReadIfAtBottom();

    // ✅ best-effort (note: ScrollablePositionedList doesn't use _scrollController)
    await _saveScrollOffsetNow();
  });
}




void _tryRestoreScrollOnce() {
  if (_didRestoreScroll) return;

  int triesLeft = 14;

  void attempt() {
    if (!mounted) return;

    if (!_scrollController.hasClients) {
      triesLeft--;
      if (triesLeft <= 0) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
      return;
    }

    final max = _scrollController.position.maxScrollExtent;

    // Wait until layout stabilizes (avatars/images can change extents).
    if (max <= 0.0 && _messages.isNotEmpty) {
      triesLeft--;
      if (triesLeft <= 0) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
      return;
    }

    final target = _savedScrollOffset.clamp(0.0, max);
    _scrollController.jumpTo(target);

    _didRestoreScroll = true;

    // ✅ now it's safe to save offsets
    _allowScrollOffsetSaves = true;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
}




// =======================
// Heart animation gating
// =======================
bool _appIsResumed = true;
bool _initialSnapshotDone = false;

// block heart fly animations briefly after opening the chat
int _enableHeartAnimsAtMs = 0;

int _nowMs() => DateTime.now().millisecondsSinceEpoch;

bool _canPlayHeartFlyAnims() {
  return mounted &&
      _appIsResumed &&
      _initialSnapshotDone &&
      _nowMs() >= _enableHeartAnimsAtMs;
}

int _latestTextTs() {
  for (int i = _messages.length - 1; i >= 0; i--) {
    final m = _messages[i];
    if (m.type == ChatMessageType.text && m.ts > 0) return m.ts;
  }
  return 0;
}

/// ❤️ Heart colors per user (FINAL)
static const Map<String, Color> _heartColorByUserId = <String, Color>{
  'lian': Color(0xFFFF2020), // #ff2020
  'lihi': Color(0xFFFF9020), // #ff9020
  'lera': Color(0xFFFFF420), // #fff420
  'tal': Color(0xFF33FF20),  // #33ff20
  'danielle': Color(0xFF20D2FF), // #20d2ff
  'joy': Color(0xFFB120FF),  // #b120ff
  'adi': Color(0xFFFF20AA),  // #ff20aa
};

Color _heartColorForUserId(String userId) {
  return _heartColorByUserId[userId] ?? Colors.white;
}

List<Widget> _buildHeartIcons(Set<String> reactorIds, double uiScale) {
  if (reactorIds.isEmpty) return const <Widget>[];

  const double baseHeartSize = 40; // הגודל הוויזואלי של הלב
  const double baseHeartGap = 2.0;

  // גובה "שורת שם" בלבד (זה מה שמונע מהבועה לרדת)
  final double lineHeight = 16 * uiScale;

  final ids = reactorIds.toList()..sort();

  return ids.map((rid) {
    // ✅ each heart color == the user who reacted (liked)
    final tint = _heartColorForUserId(rid);

    return Padding(
      padding: EdgeInsets.only(left: baseHeartGap * uiScale),
      child: SizedBox(
        height: lineHeight,
        width: baseHeartSize * uiScale,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: baseHeartSize * uiScale,
          minWidth: 0,
          maxWidth: baseHeartSize * uiScale,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
            child: Transform.translate(
              offset: Offset(0, -16 * uiScale),
              child: Image.asset(
                _heartAsset,
                width: baseHeartSize * uiScale,
                height: baseHeartSize * uiScale,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }).toList();
}





bool _shouldTriggerCreepyEgg(String raw) {
  final s = raw.trim().toLowerCase();
  if (s.isEmpty) return false;

  for (final t in _creepyTriggers) {
    final tt = t.trim().toLowerCase();
    if (tt.isEmpty) continue;
    if (s.contains(tt)) return true;
  }
  return false;
}

Future<void> _playCreepyEggFx() async {
  if (!mounted) return;

  // 1) swap bg (AnimatedSwitcher will fade)
  setState(() {
    _bgOverride = 'assets/backgrounds/CreepyBackgroundEasterEgg.png';
  });

  // ✅ let the BG fade start, then start the egg
  await Future.delayed(const Duration(milliseconds: 120));

  // 2) creepy music
  if (widget.enableBgm) {
    await Bgm.I.playEasterEgg('bgm/CreepyMusic.mp3');
  }

  // 3) glitch pulses + SFX
  for (int i = 0; i < 3; i++) {
    Sfx.I.playGlitch();
    await _bgFxCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 120));
  }

  // 4) keep creepy bg a moment
  await Future.delayed(const Duration(milliseconds: 700));
  if (!mounted) return;

  // ✅ IMPORTANT: stop egg audio now (don’t wait for track to end)
  if (widget.enableBgm) {
    await Bgm.I.cancelEasterEggAndRestore(
      fadeOut: const Duration(milliseconds: 650),
    );
  }

  // 5) return background
  setState(() {
    _bgOverride = null;
  });
}


Widget _nameWithHeartsHeader({
  required ChatUser user,
  required ChatMessage msg,
  required bool isMe,
  required Color usernameColor,
  required double uiScale,
}) {
  if (widget.roomId != 'group_main') return const SizedBox.shrink();

  // same offset so header sits above the bubble, not above the avatar
  final double avatarSize = 60 * uiScale;
  final double avatarGap = 10 * uiScale;

  final EdgeInsets sideInset = isMe
      ? EdgeInsets.only(right: avatarSize + avatarGap)
      : EdgeInsets.only(left: avatarSize + avatarGap);

  final hearts = _buildHeartIcons(msg.heartReactorIds, uiScale);

  return Padding(
    // ✅ NO top padding (this is what “lifted” the name)
    padding: EdgeInsets.only(
      top: 0,
      bottom: 2 * uiScale, // tiny gap like the old layout
    ),
    child: Padding(
      padding: sideInset,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✅ isMe: hearts BEFORE name (left of name)
            if (isMe) ...hearts,
            if (isMe && hearts.isNotEmpty) SizedBox(width: 4 * uiScale),

            Text(
              user.name,
              style: TextStyle(
                color: usernameColor,
                fontSize: 15 * uiScale,
                fontWeight: FontWeight.w700,
                height: 1.0, // ✅ keeps baseline tight (closer to old)
              ),
            ),

            // ✅ not isMe: hearts AFTER name (right of name)
            if (!isMe && hearts.isNotEmpty) SizedBox(width: 4 * uiScale),
            if (!isMe) ...hearts,
          ],
        ),
      ),
    ),
  );
}


Future<void> _toggleHeartForMessage(ChatMessage msg) async {
  if (msg.type != ChatMessageType.text) return;

  // ❌ Block hearts on my own messages (no add, no remove)
  if (msg.senderId == widget.currentUserId) return;

  final me = widget.currentUserId;
  final isAdding = !msg.heartReactorIds.contains(me);

  // Update in Firestore (ALL devices will update via stream)
  await FirestoreChatService.toggleHeart(
    roomId: widget.roomId,
    messageId: msg.id, // ✅ docId
    reactorId: me,
    isAdding: isAdding,
  );

  // ✅ No fly anim here (fly anim is for the RECEIVER / author via snapshot logic)
}






final ScrollController _scrollController = ScrollController();
final TextEditingController _controller = TextEditingController();
final FocusNode _focusNode = FocusNode();

// ✅ Random font picker (English only)
final Random _rng = Random();
static const List<String> _englishFonts = <String>[
  'NanumGothic',
  'NanumMyeongjo',
  'BMHanna',
];

bool _containsEnglishLetters(String s) {
  return RegExp(r'[A-Za-z]').hasMatch(s);
}


String _lastReadPrefsKey() =>
    'lastReadMs__${widget.currentUserId}__${widget.roomId}';

Future<void> _markRoomReadNow() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_lastReadPrefsKey(), DateTime.now().millisecondsSinceEpoch);
}
String _lastReadTsPrefsKey() =>
    'lastReadTs__${widget.currentUserId}__${widget.roomId}';

Future<int> _loadLastReadTs() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_lastReadTsPrefsKey()) ?? 0;
}

Future<void> _saveLastReadTs(int ts) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_lastReadTsPrefsKey(), ts);
}


bool _shouldTrigger707Egg(String raw) {
  final s = raw.trim().toLowerCase();
  if (s.isEmpty) return false;

  // ✅ Full trigger list (from roadmap v28)
  const triggers = <String>[
    '7',
    '70',
    '707',
    'שבע',
    'שבעה',
    'שביעי',
    'שבעים',
    'seven',
    'luciel',
    'saeyoung',
    'saven', // (optional typo safety — remove if you hate it)
    'סבן',
    'hacker',
    'האקר',
    'hack',
    'לפרוץ',
    'פרוץ',
    'פריצה',
    'choi',
    'צוי', // NOTE: "צ'וי" becomes "צ וי" after normalization, so we match the normalized form.
    'ג\'ינג\'י',
    'גינגי',
    'שיער אדום',
    'אדום בשיער',
    'אדום',
    'לצבוע לאדום',
    'לתכנת',
    'תכנות',
    'קוד',
    'קודים',
  ];

  // ✅ Normalize the MESSAGE: keep only a-z / 0-9 / Hebrew, everything else → space
  String normalize(String x) {
    final cleaned = x
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u0590-\u05FF]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned;
  }

  final normalizedMsg = normalize(s);
  if (normalizedMsg.isEmpty) return false;

  final paddedMsg = ' $normalizedMsg ';

  for (final t in triggers) {
    final tt = normalize(t);
    if (tt.isEmpty) continue;

    // ✅ Word-ish matching (works for both single-word and multi-word triggers)
    if (paddedMsg.contains(' $tt ')) return true;
  }

  return false;
}


// ✅ Live hour update (changes BG + username color even if nobody sends messages)
Timer? _hourTimer;
late int _uiHour;
double _lastKeyboardInset = 0.0;


void _scheduleNextHourTick() {
  _hourTimer?.cancel();

  final now = DateTime.now();
  final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
  final delay = nextHour.difference(now);

  _hourTimer = Timer(delay, () {
    if (!mounted) return;

    final newHour = DateTime.now().hour;
if (newHour != _uiHour) {
  setState(() {
    _uiHour = newHour;
  });

  // ✅ swap BGM track on hour change (only if allowed)
  if (widget.enableBgm) {
    Bgm.I.playForHour(newHour);
  }
}


    // schedule again for the next hour
    _scheduleNextHourTick();
  });
}



  bool _isTyping = false;
  late List<ChatMessage> _messages;
  // =======================
// NEW badge (live in-room)
// =======================
final Map<int, bool> _newBadgeVisibleByTs = <int, bool>{};
final Set<int> _seenMessageTs = <int>{};
void _triggerNewBadgeForTs(int ts) {
  if (ts <= 0) return;

  // ✅ Show longer (so the user actually notices it)
  setState(() {
    _newBadgeVisibleByTs[ts] = true;
  });

  // stays visible longer
 Future.delayed(const Duration(milliseconds: 600), () {




    if (!mounted) return;

    // ✅ turn OFF (MessageRow will fade it out)
    setState(() {
      _newBadgeVisibleByTs[ts] = false;
    });

    // ✅ keep it in the map a bit longer so fade-out can finish
    Future.delayed(const Duration(milliseconds: 300), () {



      if (!mounted) return;
      _newBadgeVisibleByTs.remove(ts);
    });
  });
}

// =======================
// LIVE Heart reactions (receiver sees fly animation)
// =======================
final Map<int, Set<String>> _lastReactorSnapshotByTs = <int, Set<String>>{};
bool _heartsSnapshotInitialized = false;

Future<void> _spawnHeartsForReactors(List<String> reactorIds) async {
  for (final rid in reactorIds) {
    if (!mounted) return;
    HeartReactionFlyLayer.of(context).spawnHeart(color: _heartColorForUserId(rid));
    // tiny stagger so multiple likes feel nice
    await Future.delayed(const Duration(milliseconds: 120));
  }
}


  // ✅ Currently selected bubble template for the NEXT message
  BubbleTemplate _selectedTemplate = BubbleTemplate.normal;

  // ✅ Selected decor for NEXT message
  BubbleDecor _selectedDecor = BubbleDecor.none;



void _openBubbleTemplateMenu() async {
  final result = await showModalBottomSheet<_TemplateMenuResult>(
    context: context,
    isScrollControlled: true, // ✅ מאפשר גובה גדול + גלילה
    backgroundColor: Colors.black.withOpacity(0.92),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (context) {
      Widget templateTile({
        required BubbleTemplate template,
        required String label,
        required Widget preview,
      }) {
        final isSelected = _selectedTemplate == template;

        return GestureDetector(
          onTap: () => Navigator.pop(
            context,
            _TemplateMenuResult(template: template, decor: _selectedDecor),
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.10)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withOpacity(0.35)
                    : Colors.white.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 44, child: Center(child: preview)),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      Widget decorTile({
        required BubbleDecor decor,
        required String label,
        required Widget preview,
      }) {
        final isSelected = _selectedDecor == decor;

        return GestureDetector(
          onTap: () => Navigator.pop(
            context,
            _TemplateMenuResult(template: _selectedTemplate, decor: decor),
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.10)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withOpacity(0.35)
                    : Colors.white.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 44, child: Center(child: preview)),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      Widget grayBubblePreview() {
        return Container(
          width: 54,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }

      Widget decorPreviewHeartsGray() {
        return SizedBox(
          width: 54,
          height: 28,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              grayBubblePreview(),
              Positioned(
                top: -10,
                left: -6,
                child: ColorFiltered(
                  colorFilter:
                      const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                  child: Image.asset(
                    'assets/decors/TextBubbleLeftHearts.png',
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: -4,
                right: -6,
                child: ColorFiltered(
                  colorFilter:
                      const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                  child: Image.asset(
                    'assets/decors/TextBubbleRightHearts.png',
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      Widget decorPreviewPinkHeartsGray() {
        return SizedBox(
          width: 54,
          height: 28,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              grayBubblePreview(),
              Positioned(
                top: -10,
                left: -6,
                child: ColorFiltered(
                  colorFilter:
                      const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                  child: Image.asset(
                    'assets/decors/TextBubblePinkHeartsLeft.png',
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: -4,
                right: -6,
                child: ColorFiltered(
                  colorFilter:
                      const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                  child: Image.asset(
                    'assets/decors/TextBubblePinkHeartsRight.png',
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      }


            Widget decorPreviewCornerStarsGlowGray() {
        return SizedBox(
          width: 54,
          height: 28,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              grayBubblePreview(),
              Positioned(
                top: -10,
                left: -6,
                child: ColorFiltered(
                  colorFilter:
                      const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                  child: Image.asset(
                    'assets/decors/TextBubble4CornerStarsLeft.png',
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: -4,
                right: -6,
                child: ColorFiltered(
                  colorFilter:
                      const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
     child: Image.asset(
  'assets/decors/TextBubble4CornerStarsRightpng.png',
  width: 26,
  height: 26,
  fit: BoxFit.contain,
),

                ),
              ),
            ],
          ),
        );
      }

      Widget decorPreviewFlowersRibbonGray() {
        return SizedBox(
          width: 54,
          height: 28,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              grayBubblePreview(),
              Positioned(
                bottom: -10,
                left: -10,
                child: ColorFiltered(
                  colorFilter:
                      const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                  child: Image.asset(
                    'assets/decors/TextBubbleFlowersAndRibbon.png',
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      }

Widget decorPreviewStarsGray() {
        return SizedBox(
          width: 54,
          height: 28,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              grayBubblePreview(),
              Positioned(
                bottom: -10,
                left: -10,
                child: ColorFiltered(
                  colorFilter:
                      const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                  child: Image.asset(
                    'assets/decors/TextBubbleStars.png',
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      Widget decorPreviewDripSadGray() {
        return SizedBox(
          width: 54,
          height: 28,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              grayBubblePreview(),

              // drip (gray preview)
              Positioned(
                bottom: -16,
                right: -12,
                child: ColorFiltered(
                  colorFilter:
                      const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                  child: Image.asset(
                    'assets/decors/TextBubbleDrip.png',
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // face (gray preview so it matches the menu style)
              Positioned(
                bottom: -12,
                right: -8,
                child: ColorFiltered(
                  colorFilter:
                      const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                  child: Image.asset(
                    'assets/decors/TextBubbleSadFace.png',
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      }


      Widget decorPreviewMusicNotesGray() {
        return SizedBox(
          width: 54,
          height: 28,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              grayBubblePreview(),
              Positioned(
                top: -10,
                right: -10,
                child: ColorFiltered(
                  colorFilter:
                      const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                  child: Image.asset(
                    'assets/decors/TextBubbleMusicNotes.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      Widget decorPreviewSurpriseGray() {
        return SizedBox(
          width: 54,
          height: 28,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              grayBubblePreview(),
              Positioned(
                top: -10,
                right: -10,
                child: ColorFiltered(
                  colorFilter:
                      const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                  child: Image.asset(
                    'assets/decors/TextBubbleSurprise.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      }

Widget decorPreviewKittyGray() {
  return SizedBox(
    width: 54,
    height: 28,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        grayBubblePreview(),
        Positioned(
          top: -10,
          right: -10,
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
            child: Image.asset(
              'assets/decors/TextBubbleKitty.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    ),
  );
}


      return SafeArea(
        child: SingleChildScrollView(
          // ✅ זה מה שמונע overflow
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
                'Bubble Style',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.25,
                children: [
                  templateTile(
                    template: BubbleTemplate.normal,
                    label: 'Normal',
                    preview: grayBubblePreview(),
                  ),
                  templateTile(
                    template: BubbleTemplate.glow,
                    label: 'Glow',
                    preview: Container(
                      width: 54,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200.withOpacity(0.35),
                            blurRadius: 16,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),

              const Text(
                'Decor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.25,
children: [
  decorTile(
    decor: BubbleDecor.none,
    label: 'None',
    preview: grayBubblePreview(),
  ),
  decorTile(
    decor: BubbleDecor.hearts,
    label: 'Red Hearts',
    preview: decorPreviewHeartsGray(),
  ),
  decorTile(
    decor: BubbleDecor.pinkHearts,
    label: 'Pink Hearts',
    preview: decorPreviewPinkHeartsGray(),
  ),
    decorTile(
    decor: BubbleDecor.cornerStarsGlow,
    label: 'Shiny Stars',
    preview: decorPreviewCornerStarsGlowGray(),
  ),

  decorTile(
    decor: BubbleDecor.flowersRibbon,
    label: 'Flowers',
    preview: decorPreviewFlowersRibbonGray(),
  ),
  decorTile(
    decor: BubbleDecor.stars,
    label: 'Stars',
    preview: decorPreviewStarsGray(),
  ),
  decorTile(
    decor: BubbleDecor.dripSad,
    label: 'Gloomy',
    preview: decorPreviewDripSadGray(),
  ),
  decorTile(
    decor: BubbleDecor.musicNotes,
    label: 'Music Notes',
    preview: decorPreviewMusicNotesGray(),
  ),
  decorTile(
    decor: BubbleDecor.surprise,
    label: 'Surprise',
    preview: decorPreviewSurpriseGray(),
  ),
  decorTile(
  decor: BubbleDecor.kitty,
  label: 'Kitty',
  preview: decorPreviewKittyGray(),
),
],




              ),
            ],
          ),
        ),
      );
    },
  );

  if (!mounted || result == null) return;

  setState(() {
    _selectedTemplate = result.template;
    _selectedDecor = result.decor;
  });
}


  /// ✅ Bubble style selection (saved per user)
  BubbleStyle _myBubbleStyle = BubbleStyle.normal;

  String _bubbleStylePrefsKey() => 'bubbleStyle__${widget.currentUserId}';

  Future<void> _loadBubbleStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bubbleStylePrefsKey());
    if (raw == BubbleStyle.glow.name) {
      if (mounted) setState(() => _myBubbleStyle = BubbleStyle.glow);
      return;
    }
    if (mounted) setState(() => _myBubbleStyle = BubbleStyle.normal);
  }

  Future<void> _saveBubbleStyle(BubbleStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bubbleStylePrefsKey(), style.name);
  }

  void _openBubbleStyleMenu() {
    // ✅ previews stay gray (templates), the real bubble uses user's color
    const Map<BubbleStyle, String> previewAsset = {
      BubbleStyle.normal: 'assets/bubble_templates/preview_normal.png',
      BubbleStyle.glow: 'assets/bubble_templates/preview_glow.png',
    };

    void select(BubbleStyle style) async {
      setState(() => _myBubbleStyle = style);
      await _saveBubbleStyle(style);
      if (mounted) Navigator.of(context).pop();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (context) {
        Widget tile(BubbleStyle style) {
          final bool selected = _myBubbleStyle == style;

          return GestureDetector(
            onTap: () => select(style),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? Colors.white : Colors.white24,
                  width: selected ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Image.asset(
                      previewAsset[style]!,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    style == BubbleStyle.normal ? 'Normal' : 'Glow',
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bubble Templates',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.2,
                    children: [
                      tile(BubbleStyle.normal),
                      tile(BubbleStyle.glow),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ===== Hive =====
  static const String _boxName = 'mystic_chat_storage';
  String _roomKey(String roomId) => 'room_messages__$roomId';
  Future<Box> _box() async => Hive.openBox(_boxName);

  Future<void> _loadMessagesForRoom() async {
    final box = await _box();
    final raw = box.get(_roomKey(widget.roomId));

    if (raw is List) {
      _messages =
          raw.whereType<Map>().map((m) => ChatMessage.fromMap(m)).toList();
    } else {
      _messages = <ChatMessage>[];
        await _saveMessagesForRoom(updateMeta: false);

    }

    if (mounted) setState(() {});
  }
Future<void> _saveMessagesForRoom({
  bool updateMeta = false,
  String? lastSenderId,
}) async {
  final box = await _box();

  await box.put(
    _roomKey(widget.roomId),
    _messages.map((m) => m.toMap()).toList(),
  );

  // ✅ Update DM meta with BOTH timestamp + who sent the last real message
  if (updateMeta) {
    await box.put(
      'room_meta__${widget.roomId}',
      <String, dynamic>{
        'lastUpdatedMs': DateTime.now().millisecondsSinceEpoch,
        'lastSenderId': (lastSenderId ?? '').toString(),
      },
    );
  }
}




  /// =======================
  /// SYSTEM EVENTS (entered/left)
  /// =======================
  String _displayNameForId(String userId) {
    final u = users[userId];
    return u?.name ?? userId;
  }

Future<void> _emitSystemLine(
  String line, {
  bool showInUi = true,
  bool scroll = true,
}) async {
final ts = DateTime.now().millisecondsSinceEpoch;

// ✅ Force scroll when THIS exact system line appears in the Firestore snapshot
_pendingScrollToBottomTs = ts;


  // Send to Firestore so ALL devices see it
await FirestoreChatService.sendSystemLine(
  roomId: widget.roomId,
  text: line,
  ts: ts,
);



  // UI will update via stream; optional scroll
  if (scroll && mounted) {
    _scrollToBottom();
  }
}



Future<void> _emitEntered() async {
  final name = _displayNameForId(widget.currentUserId);
  await _emitSystemLine('$name has entered the chatroom.');
}

Future<void> _emitLeft({bool showInUi = true}) async {
  final name = _displayNameForId(widget.currentUserId);
  await _emitSystemLine(
    '$name has left the chatroom.',
    showInUi: showInUi,
    scroll: false,
  );
}



  /// ===== REAL presence (Firestore) =====
  StreamSubscription<Set<String>>? _presenceSub;

  /// We still store a notifier per-room so the UI can rebuild easily.
  static final Map<String, ValueNotifier<Set<String>>> _roomOnline = {};
  late final ValueNotifier<Set<String>> _onlineNotifier;

/// ===== Typing (Firestore, live) =====
StreamSubscription<Set<String>>? _typingSub;
late final ValueNotifier<Set<String>> _typingNotifier;

// debounce so we don't write to Firestore on every keystroke
Timer? _typingDebounce;

// track my last sent typing state (prevents spam)
bool _meTypingRemote = false;


  void _markMeOnline() {
    // Optional: quick optimistic UI (stream will override)
    _onlineNotifier.value = {..._onlineNotifier.value, widget.currentUserId};
  }

  void _markMeOffline() {
    final next = {..._onlineNotifier.value}..remove(widget.currentUserId);
    _onlineNotifier.value = next;
  }



void _sendTypingToFirestore(bool shouldType) {
  if (shouldType == _meTypingRemote) return; // no change
  _meTypingRemote = shouldType;

  final name = _displayNameForId(widget.currentUserId);

  // Firestore write (debounced)
  PresenceService.I.setTyping(
    roomId: widget.roomId,
    userId: widget.currentUserId,
    displayName: name,
    isTyping: shouldType,
  );
}

void _handleTypingChange() {
  final hasFocus = _focusNode.hasFocus;
  final hasText = _controller.text.trim().isNotEmpty;

  final shouldType = hasFocus && hasText;

  // debounce (prevents heavy write spam)
  _typingDebounce?.cancel();
  _typingDebounce = Timer(const Duration(milliseconds: 250), () {
    if (!mounted) return;
    _sendTypingToFirestore(shouldType);
  });

  // local UX: when typing turns ON, auto-scroll so you see your own typing row
// ✅ Don't auto-scroll when typing starts.
// We only scroll when sending (or when new messages arrive and we're already at bottom).


}


@override
void initState() {
  super.initState();

  // ✅ IMPORTANT: on entry we want the chat to open at the BOTTOM,
  // and show UNREAD only when the user scrolls UP.
  _hideUnreadDivider = true;

  // ✅ IMPORTANT: block saving offsets until we do the initial bottom jump once
  _allowScrollOffsetSaves = false;
  _didRestoreScroll = false;

  // ✅ Load lastRead cache once (so _firstUnreadTsOrNull() can work)
  _loadLastReadTsOnce().then((_) {
    if (!mounted) return;
    setState(() {});
  });

  AuthService.ensureSignedIn(currentUserId: widget.currentUserId);
  WidgetsBinding.instance.addObserver(this);

  // ✅ block fly anims for a moment after opening the chat (prevents “offline” replays)
  _enableHeartAnimsAtMs = _nowMs() + 1600; // tweak: 1200–2000 feels good
  _initialSnapshotDone = false;
  _appIsResumed = true;

  _messages = <ChatMessage>[];

  _bgFxCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // ✅ initialize hour for live UI updates
  _uiHour = DateTime.now().hour;

  // ✅ START BGM when entering (only if allowed in this room)
  if (widget.enableBgm) {
    Bgm.I.playForHour(_uiHour);
  }

  _scheduleNextHourTick();

  _onlineNotifier = _roomOnline.putIfAbsent(
    widget.roomId,
    () => ValueNotifier<Set<String>>(<String>{}),
  );

_typingNotifier = ValueNotifier<Set<String>>(<String>{});

// ✅ Typing stream (Firestore) -> drives TypingBubbleRow on ALL devices
_typingSub?.cancel();
_typingSub = PresenceService.I
    .streamTypingUserIds(roomId: widget.roomId)
    .listen((ids) {
  if (!mounted) return;
  _typingNotifier.value = ids;
});


  // ✅ optimistic: show myself immediately (stream will override)
  _markMeOnline();

  // ✅ typing listeners (UI-only)
  _controller.addListener(_handleTypingChange);
  _focusNode.addListener(_handleTypingChange);

  // ✅ REAL presence enter
  final name = _displayNameForId(widget.currentUserId);
  PresenceService.I.enterRoom(
    roomId: widget.roomId,
    userId: widget.currentUserId,
    displayName: name,
  );

  // ✅ REAL presence stream -> drives ActiveUsersBar
  _presenceSub?.cancel();
  _presenceSub = PresenceService.I
      .streamOnlineUserIds(roomId: widget.roomId)
      .listen((ids) {
    if (!mounted) return;

    // This is what ActiveUsersBar reads in build()
    _onlineNotifier.value = ids;

    // Group-only: ping daily fact scheduler on real presence changes
    if (widget.roomId == 'group_main') {
      DailyFactBotScheduler.I.pingPresence(roomId: 'group_main');
    }
  });

  // ✅ initial ping for group
  if (widget.roomId == 'group_main') {
    DailyFactBotScheduler.I.pingPresence(roomId: 'group_main');
  }

  // ✅ load bubble style for this user (saved locally)
  _loadBubbleStyle();

  // ✅ IMPORTANT: load scroll offset first, then attach listener + start stream
  _initScrollAndStream();
  
  _blockAutoMarkReadUntilMs = DateTime.now().millisecondsSinceEpoch + 1200;
_itemPositionsListener.itemPositions.addListener(_onPositionsChanged);



  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await _emitSystemLine(
      '${_displayNameForId(widget.currentUserId)} has entered the chatroom.',
      scroll: false,
    );
  });
}


@override
void dispose() {
  // ✅ Best-effort: don't await in dispose
  _emitLeft(showInUi: false);

  // ✅ presence leave
  PresenceService.I.leaveRoom(
    roomId: widget.roomId,
    userId: widget.currentUserId,
  );

  _roomSub?.cancel();
  _roomSub = null;

  _presenceSub?.cancel();
  _presenceSub = null;

  _typingSub?.cancel();
  _typingSub = null;

  _hourTimer?.cancel();

  // ✅ remove typing listeners (UI-only)
  _controller.removeListener(_handleTypingChange);
  _focusNode.removeListener(_handleTypingChange);

  // ✅ remove ScrollablePositionedList positions listener
  _itemPositionsListener.itemPositions.removeListener(_onPositionsChanged);

  // ✅ debounce cleanup
  _scrollSaveDebounce?.cancel();
  _scrollSaveDebounce = null;

  // ✅ last save (best-effort)
  _saveScrollOffsetNow();

  // ✅ stop typing presence (best effort)
  _typingDebounce?.cancel();
  _typingDebounce = null;

  PresenceService.I.setTyping(
    roomId: widget.roomId,
    userId: widget.currentUserId,
    displayName: _displayNameForId(widget.currentUserId),
    isTyping: false,
  );

  // ✅ this controller isn't attached to the list, but it's safe to dispose
  _scrollController.dispose();

  WidgetsBinding.instance.removeObserver(this);

  _bgFxCtrl.dispose();
  _markMeOffline();

  super.dispose();
}








void _startFirestoreSubscription() {
  _roomSub?.cancel();

_roomSub = FirestoreChatService.messagesStreamMaps(widget.roomId).listen(
  (rows) async {
    final List<ChatMessage> oldMessages = List<ChatMessage>.from(_messages);
    final int oldCount = oldMessages.length;
    final bool wasNearBottomBefore = _isNearBottom();
void _onTapScrollToBottomButton() {
  // ✅ clear "messages below" badge too (WhatsApp behavior)
  if (mounted) {
    setState(() {
      _newBelowCount = 0;
      _newBelowHasMention = false;
    });
  }

  _scrollToBottom(animated: true, keepFocus: true);

  // Optional: also mark read if we're now at bottom
  _markReadIfAtBottom();
}

    // snapshot "seen" BEFORE reload
    final oldSeen = Set<int>.from(_seenMessageTs);

    // snapshot heart reactors BEFORE reload
    final Map<int, Set<String>> oldReactorsByTs = <int, Set<String>>{};
    for (final m in oldMessages) {
      if (m.ts > 0) {
        oldReactorsByTs[m.ts] = Set<String>.from(m.heartReactorIds);
      }
    }

    // Convert maps -> ChatMessage
    final next = rows.map((m) => ChatMessage.fromMap(m)).toList();
    _messages = next;

    // ✅ IMPORTANT: if new messages arrived and user is NOT near bottom,
    // increment the "below" counter (only other users, text only)
final bool hasNewMessages = next.length > oldCount;
if (hasNewMessages && !wasNearBottomBefore) {
  final int added = _countAddedUnreadishMessages(oldMessages, next);
  final bool addedMention = _hasAddedMentionsOfMe(oldMessages, next);

  if ((added > 0 || addedMention) && mounted) {
    setState(() {
      if (added > 0) _newBelowCount += added;
      if (addedMention) _newBelowHasMention = true;
    });
  }
}


// ✅ Auto-scroll when:
// 1) I was already near bottom before the update, OR
// 2) the snapshot now contains the message I just sent (ts match)
final bool snapshotContainsMyPendingMessage =
    (_pendingScrollToBottomTs > 0) &&
    next.any((m) =>
        m.ts == _pendingScrollToBottomTs &&
        m.senderId == widget.currentUserId);

if (wasNearBottomBefore || snapshotContainsMyPendingMessage) {
  // ✅ IMPORTANT: wait TWO frames so the list rebuilds with the new itemCount
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _scrollToBottom(animated: true, keepFocus: true);

      // ✅ consume
      if (snapshotContainsMyPendingMessage) {
        _pendingScrollToBottomTs = 0;
      }
    });
  });
}



    // ✅ Ensure lastRead cache is loaded BEFORE UI builds unread divider
    await _loadLastReadTsOnce();

    if (!mounted) return;
    setState(() {});

    // seed seen on first load
    if (_seenMessageTs.isEmpty) {
      for (final m in _messages) {
        if (m.ts > 0) _seenMessageTs.add(m.ts);
      }
    } else {
      // detect truly new messages
      for (final m in _messages) {
        final int ts = m.ts;
        if (ts > 0 && !oldSeen.contains(ts)) {
          _seenMessageTs.add(ts);

          // NEW badge ONLY in GROUP CHAT
          if (widget.roomId == 'group_main') {
            final bool isMe = m.senderId == widget.currentUserId;
            if (!isMe && m.type == ChatMessageType.text) {
              _triggerNewBadgeForTs(ts);
            }
          }
        }
      }

      if (widget.roomId == 'group_main') {
        await DailyFactBotScheduler.I.pingPresence(roomId: 'group_main');
      }
    }

    // LIVE HEART ANIMATION for RECEIVER
    if (!_heartsSnapshotInitialized) {
      _lastReactorSnapshotByTs.clear();
      for (final m in _messages) {
        if (m.ts > 0) {
          _lastReactorSnapshotByTs[m.ts] = Set<String>.from(m.heartReactorIds);
        }
      }
      _heartsSnapshotInitialized = true;

      // ✅ IMPORTANT: first snapshot is "sync", never animate hearts for it
      _initialSnapshotDone = true;
    } else {
      final List<String> reactorsToAnimate = <String>[];

      for (final m in _messages) {
        if (m.type != ChatMessageType.text) continue;
        if (m.ts <= 0) continue;

        // receiver condition: I am the author of the message that got liked
        if (m.senderId != widget.currentUserId) continue;

        final Set<String> prev = oldReactorsByTs[m.ts] ??
            _lastReactorSnapshotByTs[m.ts] ??
            <String>{};

        final Set<String> now = Set<String>.from(m.heartReactorIds);

        final added = now.difference(prev);

        // never animate my own like
        added.remove(widget.currentUserId);

        if (added.isNotEmpty) {
          reactorsToAnimate.addAll(added.toList()..sort());
        }

        _lastReactorSnapshotByTs[m.ts] = now;
      }

      // ✅ ONLY animate if user is live in the chat
      if (reactorsToAnimate.isNotEmpty && _canPlayHeartFlyAnims()) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await _spawnHeartsForReactors(reactorsToAnimate);
        });
      }
    }

final bool firstLoad = (oldCount == 0 && !_didRestoreScroll);

if (firstLoad && next.isNotEmpty) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    // ✅ ScrollablePositionedList: start at bottom
    _scrollToBottom(animated: false);

    _didRestoreScroll = true;

    if (mounted) {
      setState(() => _hideUnreadDivider = true);
    }
  });
}

  },
);

}



  void _openKeyboard() {
    if (_isTyping) {
      _focusNode.requestFocus();
      return;
    }
    setState(() => _isTyping = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

void _scrollToBottom({bool keepFocus = false, bool animated = true}) {
  if (!mounted) return;
  if (!_itemScrollController.isAttached) return;

  // ✅ We scroll to the SPACER item (extra item at the end)
  final int spacerIndex = _messages.length; // <- NOT length-1

  final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;
  final bool keyboardOpen = keyboardInset > 0.0;

  // When keyboard open, keep content a bit higher.
  // When closed, go true bottom.
  final double alignment = keyboardOpen ? 0.85 : 1.0;

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!mounted) return;
    if (!_itemScrollController.isAttached) return;

    if (animated) {
      await _itemScrollController.scrollTo(
        index: spacerIndex,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: alignment,
      );
    } else {
      _itemScrollController.jumpTo(
        index: spacerIndex,
        alignment: alignment,
      );
    }

    _allowScrollOffsetSaves = true;

    if (keepFocus) {
      _focusNode.requestFocus();
    }
  });
}


Future<void> _jumpToFirstUnreadIfAny() async {
  final int lastReadTs = await _loadLastReadTs();

  int targetIndex = -1;

  // ✅ First unread from OTHER users only (same rule as your divider)
  for (int i = 0; i < _messages.length; i++) {
    final m = _messages[i];
    if (m.type != ChatMessageType.text) continue;
    if (m.ts <= 0) continue;
    if (m.senderId == widget.currentUserId) continue;

    if (m.ts > lastReadTs) {
      targetIndex = i;
      break;
    }
  }

  if (targetIndex < 0) {
    _scrollToBottom(animated: false);
    return;
  }

  if (!_itemScrollController.isAttached) return;

  await _itemScrollController.scrollTo(
    index: targetIndex,
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOut,
    alignment: 0.0, // ✅ keep it at top
  );

  _allowScrollOffsetSaves = true;
}




  
Future<void> _debugSimulateIncomingMessage() async {
  final ts = DateTime.now().millisecondsSinceEpoch;

  setState(() {
    _messages.add(
ChatMessage(
  id: ts.toString(), // ✅ NEW
  type: ChatMessageType.text,
  senderId: 'adi',
  text: 'Incoming test from Adi ✨',
  ts: ts,
),

    );
  });

  await _saveMessagesForRoom(
    updateMeta: true,
    lastSenderId: 'adi',
  );
}

Future<void> _sendMessage() async {
  final text = _controller.text.trim();
  final bool triggerCreepy = _shouldTriggerCreepyEgg(text);

  if (text.isEmpty) return;

  final bool triggerEgg = _shouldTrigger707Egg(text);

  final BubbleTemplate templateForThisMessage = _selectedTemplate;
  final BubbleDecor decorForThisMessage = _selectedDecor;

  final String? fontFamilyForThisMessage = _containsEnglishLetters(text)
      ? _englishFonts[_rng.nextInt(_englishFonts.length)]
      : null;

  final ts = DateTime.now().millisecondsSinceEpoch;
  // ✅ Force scroll when THIS exact message appears in the Firestore snapshot
_pendingScrollToBottomTs = ts;


  // ✅ capture reply info BEFORE we clear it
  final ChatMessage? reply = _replyTarget;
  final String? replyToId = reply?.id;
  final String? replyToSenderId = reply?.senderId;
  final String? replyToText = reply?.text;

  setState(() {
    _controller.clear();

    // ✅ user stays typing
    _isTyping = true;

    // ✅ reset bubble menu defaults
    _selectedTemplate = BubbleTemplate.normal;
    _selectedDecor = BubbleDecor.none;

    // ✅ IMPORTANT: auto-cancel mention/reply bar after send
    _replyTarget = null;
  });

  // ✅ remote typing OFF
  _sendTypingToFirestore(false);

  // ✅ keep keyboard open
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) _focusNode.requestFocus();
  });

  await FirestoreChatService.sendTextMessage(
    roomId: widget.roomId,
    senderId: widget.currentUserId,
    text: text,
    ts: ts,
    bubbleTemplate: templateForThisMessage.name,
    decor: decorForThisMessage.name,
    fontFamily: fontFamilyForThisMessage,

    // ✅ reply payload
    replyToMessageId: replyToId,
    replyToSenderId: replyToSenderId,
    replyToText: replyToText,
  );

  Sfx.I.playSend();

  if (triggerEgg) {
    Sfx.I.play707VoiceLine();
  }

  if (triggerCreepy) {
    _playCreepyEggFx();
  }



}


void _onTapScrollToBottomButton() {
  // ✅ clear "messages below" badge too (WhatsApp behavior)
  if (mounted) {
    setState(() {
      _newBelowCount = 0;
      _newBelowHasMention = false;
    });
  }

  _scrollToBottom(animated: true, keepFocus: true);

  // Optional: also mark read if we're now at bottom
  _markReadIfAtBottom();
}




@override
Widget build(BuildContext context) {
final int hour = _uiHour;
final bg = _bgOverride ?? backgroundForHour(hour);
final Color usernameColor = usernameColorForHour(hour);
final Color timeColor = timeColorForHour(hour);



   final double uiScale = mysticUiScale(context);

  // ✅ Keyboard height (0 when closed)
  final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;

WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;

  if (_lastKeyboardInset == keyboardInset) return;
  _lastKeyboardInset = keyboardInset;

  // ✅ Only auto-snap if user is already near bottom
  if (_isNearBottom()) {
    _scrollToBottom(animated: false);
  }
});



  debugPrint('HOUR=$hour  usernameColor=$usernameColor  bg=$bg  uiScale=$uiScale');
return GestureDetector(
  behavior: HitTestBehavior.translucent,
  onTap: () {
    // closes keyboard when tapping anywhere outside inputs
    FocusManager.instance.primaryFocus?.unfocus();

    // optional: also flip your typing UI state
    if (mounted) {
      setState(() => _isTyping = false);
    }
  },
  child: Scaffold(
    backgroundColor: Colors.black,
    floatingActionButton: kEnableDebugIncomingPreview
        ? FloatingActionButton(
            onPressed: _debugSimulateIncomingMessage,
            child: const Icon(Icons.bug_report),
          )
        : null,

    body: Column(
      children: [
        const TopBorderBar(height: _topBarHeight),

        SafeArea(
          bottom: false,
          child: ValueListenableBuilder<Set<String>>(
            valueListenable: _onlineNotifier,
            builder: (context, onlineIds, _) {
              return ActiveUsersBar(
                usersById: users,
                onlineUserIds: onlineIds,
                currentUserId: widget.currentUserId,
      onBack: () async {
  if (widget.enableBgm) {
    await Bgm.I.leaveGroupAndResumeHomeDm();
  }
  if (!mounted) return;
  Navigator.of(context).maybePop();
},

                onOpenBubbleMenu: _openBubbleTemplateMenu,
                titleText: widget.title ??
                    (users[widget.currentUserId]?.name ?? widget.currentUserId),
                uiScale: uiScale,
              );
            },
          ),
        ),

        Expanded(
          child: Stack(
            children: [
              // ✅ Background — SAME bounds as frame + messages
              Positioned(
                left: 0,
                right: 0,
                top: _redFrameTopGap,
                bottom: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 1200),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  layoutBuilder:
                      (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: AnimatedBuilder(
                    key: ValueKey(bg),
                    animation: _bgFxCtrl,
                    builder: (context, _) {
                      final t = _bgFxCtrl.value;

                      final bool glitchOn = _bgOverride != null;

                      final double pulse = (t * (1.0 - t)) * 4.0; // 0..~1
                      final double blur = glitchOn ? (pulse * 7.0) : 0.0;

                      final double dx = glitchOn ? (sin(t * 40) * 8.0) : 0.0;
                      final double dy = glitchOn ? (cos(t * 36) * 6.0) : 0.0;
                      final double rot = glitchOn ? (sin(t * 20) * 0.03) : 0.0;

                      Widget img = Image.asset(
                        bg,
                        fit: BoxFit.cover,
                      );

                      if (!glitchOn) return img;

                      return Transform.translate(
                        offset: Offset(dx, dy),
                        child: Transform.rotate(
                          angle: rot,
                          child: ImageFiltered(
                            imageFilter:
                                ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                            child: ColorFiltered(
                              colorFilter: ColorFilter.matrix(<double>[
                                1, 0, 0, 0, 18 * pulse,
                                0, 1, 0, 0, 6 * pulse,
                                0, 0, 1, 0, 24 * pulse,
                                0, 0, 0, 1, 0,
                              ]),
                              child: img,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ✅ Messages
              Positioned(
                left: 0,
                right: 0,
                top: _redFrameTopGap,
                bottom: 0,
                child: Column(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<Set<String>>(
                        valueListenable: _typingNotifier,
                        builder: (context, typingIds, _) {
                          final typingList = typingIds.toList();
                          typingList.sort((a, b) {
                            final an = users[a]?.name ?? a;
                            final bn = users[b]?.name ?? b;
                            return an.toLowerCase().compareTo(bn.toLowerCase());
                          });

final limitedTyping = typingList.take(3).toList();

final bool keyboardOpen = keyboardInset > 0.0;

// ✅ system bottom inset (gesture bar / home indicator)
final double safeBottom = MediaQuery.of(context).padding.bottom;

// ✅ Space only when keyboard is open (your "70" look)
final double extraBottomWhenKeyboardOpen = 70 * uiScale;

// ✅ When keyboard is closed: leave a small "floor" so the last bubble + shadow
// never gets clipped at the bottom edge.
final double bottomWhenClosed = (18 * uiScale) + safeBottom;

final double listBottomPadding = keyboardOpen
    ? (keyboardInset + extraBottomWhenKeyboardOpen)
    : bottomWhenClosed;


return ScrollablePositionedList.builder(
  itemScrollController: _itemScrollController,
  itemPositionsListener: _itemPositionsListener,
  padding: EdgeInsets.only(
    top: 8 * uiScale,
    // ✅ Bottom padding is handled by the spacer item below (more reliable)
    bottom: 0,
  ),

  // ✅ ADD 1: extra spacer item at the end
  itemCount: _messages.length + 1,

  itemBuilder: (context, index) {
    // ✅ LAST ITEM = spacer (gives real "floor" so last message never hides)
    if (index == _messages.length) {
      final bool keyboardOpen = keyboardInset > 0.0;
      final double safeBottom = MediaQuery.of(context).padding.bottom;

      final double extraBottomWhenKeyboardOpen = 70 * uiScale;
      final double bottomWhenClosed = (28 * uiScale) + safeBottom;

      final double spacerHeight = keyboardOpen
          ? (keyboardInset + extraBottomWhenKeyboardOpen)
          : bottomWhenClosed;

      return SizedBox(height: spacerHeight);
    }

    const double chatSidePadding = 16;

    final msg = _messages[index];
    final prev = index > 0 ? _messages[index - 1] : null;

    bool showDateDivider = false;
    String dateLabel = '';

    if (widget.roomId == 'group_main' && msg.ts > 0) {
      final msgDay = DateTime.fromMillisecondsSinceEpoch(msg.ts);

      if (prev == null || prev.ts <= 0) {
        showDateDivider = true;
        dateLabel = _dayLabel(msgDay);
      } else {
        final prevDay = DateTime.fromMillisecondsSinceEpoch(prev.ts);
        if (!_isSameDay(msgDay, prevDay)) {
          showDateDivider = true;
          dateLabel = _dayLabel(msgDay);
        }
      }
    }

    double topSpacing;
    if (msg.type == ChatMessageType.system) {
      topSpacing = 14;
    } else if (prev == null) {
      topSpacing = 10;
    } else if (prev.type == ChatMessageType.system) {
      topSpacing = 12;
    } else if (prev.senderId == msg.senderId) {
      topSpacing = 18;
    } else {
      topSpacing = 12;
    }

    final List<Widget> pieces = <Widget>[];

    if (showDateDivider) {
      pieces.add(_GcDateDivider(label: dateLabel, uiScale: uiScale));
    }

    final int firstUnreadTs = _firstUnreadTsOrNull();
    final bool showUnreadDivider = !_hideUnreadDivider &&
        firstUnreadTs > 0 &&
        msg.type == ChatMessageType.text &&
        msg.ts == firstUnreadTs;

    if (showUnreadDivider) {
      pieces.add(
        KeyedSubtree(
          key: _unreadDividerKey,
          child: _UnreadDivider(uiScale: uiScale, text: 'UNREAD'),
        ),
      );
    }

    if (msg.type == ChatMessageType.system) {
      const double systemSideInset = 2.0;
      pieces.add(
        Padding(
          padding: EdgeInsets.fromLTRB(
            systemSideInset * uiScale,
            topSpacing * uiScale,
            systemSideInset * uiScale,
            0,
          ),
          child: SystemMessageBar(text: msg.text, uiScale: uiScale),
        ),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: pieces,
      );
    }

    final user = users[msg.senderId];
    if (user == null) return const SizedBox.shrink();

    final isMe = user.id == widget.currentUserId;
    final bool isGroup = widget.roomId == 'group_main';
    final bool showNew =
        isGroup ? (_newBadgeVisibleByTs[msg.ts] ?? false) : false;

    pieces.add(
      KeyedSubtree(
        key: _keyForMsg(msg),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            chatSidePadding * uiScale,
            topSpacing * uiScale,
            chatSidePadding * uiScale,
            0,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: () {
  // ❌ No hearts on my own messages
  if (msg.senderId == widget.currentUserId) return;
  _toggleHeartForMessage(msg);
},

            onHorizontalDragStart: (_) {
              _dragDx = 0.0;
            },
            onHorizontalDragUpdate: (details) {
              _dragDx += details.delta.dx;

              final bool swipeOk = (_dragDx > 28);

              if (swipeOk) {
                _dragDx = 0.0;
                _setReplyTarget(msg);
                _flashHighlight(msg.id);
                _focusNode.requestFocus();
              }
            },
            onHorizontalDragEnd: (_) {
              _dragDx = 0.0;
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: AnimatedOpacity(
                      opacity:
                          (_highlightByMsgId[msg.id] ?? false) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22 * uiScale),
                          color: user.bubbleColor.withOpacity(0.18),
                          boxShadow: [
                            BoxShadow(
                              color: user.bubbleColor.withOpacity(0.45),
                              blurRadius: 22 * uiScale,
                              spreadRadius: 1.5 * uiScale,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                MessageRow(
                  user: user,
                  text: msg.text,
                  isMe: isMe,
                  bubbleTemplate: msg.bubbleTemplate,
                  decor: msg.decor,
                  fontFamily: msg.fontFamily,
                  showName: (widget.roomId == 'group_main'),
                  nameHearts: (widget.roomId == 'group_main')
                      ? _buildHeartIcons(msg.heartReactorIds, uiScale)
                      : const <Widget>[],
                  showTime: (widget.roomId == 'group_main'),
                  timeMs: msg.ts,
                  showNewBadge: showNew,
                  usernameColor: usernameColor,
                  timeColor: timeColor,
                  uiScale: uiScale,
                  replyToSenderName: (msg.replyToSenderId == null)
                      ? null
                      : (users[msg.replyToSenderId!]?.name ??
                          msg.replyToSenderId!),
                  replyToText: msg.replyToText,
                  onTapReplyPreview: () {
                    final id = msg.replyToMessageId;
                    if (id != null) _jumpToMessageId(id);
                  },
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: AnimatedOpacity(
                      opacity:
                          (_highlightByMsgId[msg.id] ?? false) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18 * uiScale),
                          border: Border.all(
                            color: user.bubbleColor.withOpacity(0.55),
                            width: 1.6 * uiScale,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: pieces,
    );
  },
);





                        },
                      ),
                    ),
                  ],
                ),
              ),




// ✅ Typing overlay (always visible, even when user is scrolled up)
Positioned(
  left: 0,
  right: 0,
  bottom: (8 * uiScale) + keyboardInset, // ✅ lift above keyboard
  child: IgnorePointer(

    ignoring: true,
    child: ValueListenableBuilder<Set<String>>(
      valueListenable: _typingNotifier,
      builder: (context, typingIds, _) {
        final ids = typingIds.toList()..remove(widget.currentUserId);
        if (ids.isEmpty) return const SizedBox.shrink();


        ids.sort((a, b) {
          final an = users[a]?.name ?? a;
          final bn = users[b]?.name ?? b;
          return an.toLowerCase().compareTo(bn.toLowerCase());
        });

        final limited = ids.take(3).toList();
        const double chatSidePadding = 16;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: chatSidePadding * uiScale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final uid in limited)
                Padding(
                  padding: EdgeInsets.only(bottom: 6 * uiScale),
                  child: TypingBubbleRow(
                    user: users[uid]!,
                    isMe: false,
                    uiScale: uiScale,
                  ),
                ),
            ],
          ),
        );
      },
    ),
  ),
),

// ✅ NEW messages-below badge (single instance)
if (_newBelowCount > 0 && !_nearBottomCached)
  Positioned(
    right: 16 * uiScale,
    bottom: 52 * uiScale,
    child: NewMessagesBadge(
      count: _newBelowCount,
      badgeColor: const Color(0xFFEF797E),
      hasMention: _newBelowHasMention,
      onTap: () {
        // אופציונלי: אפשר לקפוץ ל-UNREAD או ל-mention הראשון
      },
    ),
  ),


// ✅ Scroll-to-bottom button (WhatsApp-style)
if (!_nearBottomCached)
  Positioned(
    right: 16 * uiScale,
    bottom: 16 * uiScale,
    child: GestureDetector(
      onTap: _onTapScrollToBottomButton,
      child: Container(
        width: 44 * uiScale,
        height: 44 * uiScale,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.72),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withOpacity(0.22),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 16 * uiScale,
              spreadRadius: 1 * uiScale,
            ),
          ],
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.white,
          size: 30 * uiScale,
        ),
      ),
    ),
  ),






              // ✅ Mystic red frame
              Positioned(
                left: 0,
                right: 0,
                top: _redFrameTopGap,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: true,
                  child: CustomPaint(
                    painter: _MysticRedFramePainter(),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ✅ WhatsApp-like Reply Preview (only when replying)
        if (_replyTarget != null)
          ReplyPreviewBar(
            uiScale: uiScale,
            stripeColor:
                (users[_replyTarget!.senderId]?.bubbleColor ?? Colors.white),
            title: _displayNameForId(_replyTarget!.senderId),
            subtitle: _replyPreviewText(_replyTarget!.text),
            onTap: () {
              final id = _replyTarget!.id;
              _jumpToMessageId(id);
            },
            onClose: _clearReplyTarget,
          ),

        BottomBorderBar(
          height: _bottomBarHeight * uiScale,
          isTyping: _isTyping,
          onTapTypeMessage: _openKeyboard,
          controller: _controller,
          focusNode: _focusNode,
          onSend: _sendMessage,
          uiScale: uiScale,
        ),

      ],
    ),
  ),
);

  }
}


/// ✅ Painter שמצייר: קו אדום דק + “פייד” קטן פנימה (כמו Mystic, בלי glow blocks)
class _MysticRedFramePainter extends CustomPainter {
  static const Color _solidRed = Color(0xFFE53935);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1) קו אדום סולידי דק שנוגע בקצוות
    const double stroke = 2.0;
    final borderPaint = Paint()
      ..color = _solidRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawRect(rect.deflate(stroke / 2), borderPaint);

    // 2) פייד עדין פנימה בלבד (עובי קטן)
    const double fadeThickness = 10.0;

    // TOP
    final topRect = Rect.fromLTWH(0, 0, size.width, fadeThickness);
    final topPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x33E53935),
          Color(0x10E53935),
          Color(0x00E53935),
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(topRect);
    canvas.drawRect(topRect, topPaint);

    // BOTTOM
    final bottomRect =
        Rect.fromLTWH(0, size.height - fadeThickness, size.width, fadeThickness);
    final bottomPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color(0x33E53935),
          Color(0x10E53935),
          Color(0x00E53935),
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(bottomRect);
    canvas.drawRect(bottomRect, bottomPaint);

    // LEFT
    final leftRect = Rect.fromLTWH(0, 0, fadeThickness, size.height);
    final leftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0x33E53935),
          Color(0x10E53935),
          Color(0x00E53935),
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(leftRect);
    canvas.drawRect(leftRect, leftPaint);

    // RIGHT
    final rightRect =
        Rect.fromLTWH(size.width - fadeThickness, 0, fadeThickness, size.height);
    final rightPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          Color(0x33E53935),
          Color(0x10E53935),
          Color(0x00E53935),
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(rightRect);
    canvas.drawRect(rightRect, rightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class MysticNewBadge extends StatelessWidget {
  final double uiScale;

  const MysticNewBadge({
    super.key,
    this.uiScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * uiScale;

    return ClipRRect(
      borderRadius: BorderRadius.circular(s(2.4)),
      child: Container(
        color: const Color(0xFFFF6769),
        padding: EdgeInsets.symmetric(
          horizontal: s(3.2),
          vertical: s(1.4),
        ),
        child: Text(
          'NEW',
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: s(9.5),
            fontWeight: FontWeight.w900,
            height: 1.0,
            letterSpacing: s(0.35),
          ),
        ),
      ),
    );
  }
}


// =======================
// GROUP CHAT Date Divider
// =======================

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _dayLabel(DateTime d) {
  // ✅ DMs format: 2026.01.21 Wed
  const weekdays = <String>[
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  String two(int x) => x.toString().padLeft(2, '0');

  final y = d.year;
  final m = two(d.month);
  final day = two(d.day);

  // DateTime.weekday: 1=Mon ... 7=Sun
  final wd = weekdays[(d.weekday - 1).clamp(0, 6)];

  return '$y.$m.$day $wd';
}

class _GcDateDivider extends StatelessWidget {
  final String label;
  final double uiScale;

  const _GcDateDivider({
    required this.label,
    required this.uiScale,
  });

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * uiScale;

    return Padding(
      padding: EdgeInsets.fromLTRB(s(10), s(10), s(10), s(6)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // left line
          Expanded(
            child: Container(
              height: s(1),
              color: Colors.white.withOpacity(0.25),
            ),
          ),

          SizedBox(width: s(10)),

          // hourglass icon + text
          Image.asset(
            'assets/ui/GCHourglassDateAndTime.png',
            width: s(26),
            height: s(26),
            fit: BoxFit.contain,
          ),

          SizedBox(width: s(8)),

          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: s(12),
              fontWeight: FontWeight.w800,
              letterSpacing: s(0.6),
              height: 1.0,
            ),
          ),

          SizedBox(width: s(10)),

          // right line
          Expanded(
            child: Container(
              height: s(1),
              color: Colors.white.withOpacity(0.25),
            ),
          ),
        ],
      ),
    );
  }
}
class _UnreadDivider extends StatelessWidget {
  final double uiScale;
  final String text;

  const _UnreadDivider({
    required this.uiScale,
    this.text = 'UNREAD',
  });

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * uiScale;

    return Padding(
      padding: EdgeInsets.fromLTRB(s(10), s(12), s(10), s(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // left line
          Expanded(
            child: Container(
              height: s(1),
              color: Colors.white.withOpacity(0.25),
            ),
          ),

          SizedBox(width: s(10)),

          // ✅ your decor instead of hourglass
          Image.asset(
            'assets/ui/LastReadBarDecor.png', // <-- put your file here
            width: s(30),
            height: s(30),
            fit: BoxFit.contain,
          ),

          SizedBox(width: s(8)),

          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: s(12),
              fontWeight: FontWeight.w900,
              letterSpacing: s(0.8),
              height: 1.0,
            ),
          ),

          SizedBox(width: s(10)),

          // right line
          Expanded(
            child: Container(
              height: s(1),
              color: Colors.white.withOpacity(0.25),
            ),
          ),
        ],
      ),
    );
  }
}
