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
  if (hour == 0) return 'assets/backgrounds/MidnightBG.png';
  if (hour >= 1 && hour <= 6) return 'assets/backgrounds/NightBG.png';
  if (hour >= 7 && hour <= 11) return 'assets/backgrounds/MorningBG.png';
  if (hour >= 12 && hour <= 16) return 'assets/backgrounds/NoonBG.png';
  return 'assets/backgrounds/EveningBG.png';
}
Color usernameColorForHour(int hour) {
  // Midnight + Night (00:00–06:00) => WHITE
  if (hour >= 0 && hour <= 6) return Colors.white;

  // All other hours => BLACK
  return Colors.black;
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
  final ChatMessageType type;

  /// For `text` messages this is the sender's userId.
  /// For `system` messages this can be an empty string.
  final String senderId;

  /// For `system` messages this is the system line (e.g. "Joy has entered...").
  final String text;

  /// ✅ unix ms timestamp (used for NEW badge + ordering)
  final int ts;

  /// ✅ Which bubble template this message uses (normal/glow...)
  final BubbleTemplate bubbleTemplate;

  /// ✅ Which decor is applied to this message
  final BubbleDecor decor;

  /// ✅ Optional per-message font family (English random fonts)
  final String? fontFamily;

  /// ✅ NEW: userIds that heart-reacted to THIS message
  /// Persisted in Hive as a List<String>
  final Set<String> heartReactorIds;

  ChatMessage({
    required this.type,
    required this.senderId,
    required this.text,
    required this.ts,
    this.bubbleTemplate = BubbleTemplate.normal,
    this.decor = BubbleDecor.none,
    this.fontFamily,
    Set<String>? heartReactorIds,
  }) : heartReactorIds = heartReactorIds ?? <String>{};

  ChatMessage copyWith({
    ChatMessageType? type,
    String? senderId,
    String? text,
    int? ts,
    BubbleTemplate? bubbleTemplate,
    BubbleDecor? decor,
    String? fontFamily,
    Set<String>? heartReactorIds,
  }) {
    return ChatMessage(
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      ts: ts ?? this.ts,
      bubbleTemplate: bubbleTemplate ?? this.bubbleTemplate,
      decor: decor ?? this.decor,
      fontFamily: fontFamily ?? this.fontFamily,
      heartReactorIds: heartReactorIds ?? this.heartReactorIds,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': type.name,
        'senderId': senderId,
        'text': text,
        'ts': ts,
        'bubbleTemplate': bubbleTemplate.name,
        'decor': decor.name,
        'fontFamily': fontFamily,
        'heartReactorIds': heartReactorIds.toList(),
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

    return ChatMessage(
      type: type,
      senderId: (m['senderId'] ?? '').toString(),
      text: (m['text'] ?? '').toString(),
      ts: ts,
      bubbleTemplate: bt,
      decor: decor,
      fontFamily: fontFamily,
      heartReactorIds: reactors,
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


class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {

  static const double _topBarHeight = 0;
  static const double _bottomBarHeight = 80;
  static const double _redFrameTopGap = 0;
  StreamSubscription? _roomSub;
VoidCallback? _onlineListener;

// =======================
// Creepy BG Easter Egg
// =======================
String? _bgOverride;

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

Color _bubbleColorForUserId(String userId) {
  return users[userId]?.bubbleColor ?? Colors.white;
}

List<Widget> _buildHeartIcons(Set<String> reactorIds, double uiScale) {
  if (reactorIds.isEmpty) return const <Widget>[];

  const double baseHeartSize = 40; // הגודל הוויזואלי של הלב
  const double baseHeartGap = 2.0;

  // גובה "שורת שם" בלבד (זה מה שמונע מהבועה לרדת)
  final double lineHeight = 16 * uiScale;

  final ids = reactorIds.toList()..sort();

  return ids.map((rid) {
    final tint = _bubbleColorForUserId(rid);

    return Padding(
      padding: EdgeInsets.only(left: baseHeartGap * uiScale),
      child: SizedBox(
        // ✅ הלייאאוט תופס רק גובה של שורת טקסט
        height: lineHeight,
        width: baseHeartSize * uiScale, // מספיק מקום ללב
        child: OverflowBox(
          // ✅ מאפשר לצייר את הלב "מחוץ" לגובה השורה בלי להגדיל את השורה
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: baseHeartSize * uiScale,
          minWidth: 0,
          maxWidth: baseHeartSize * uiScale,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
            child: Transform.translate(
              offset: Offset(0, -16 * uiScale), // להזיז למעלה בלי להשפיע על לייאאוט
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
  // ריאקשנים רק לטקסט (לא system)
  if (msg.type != ChatMessageType.text) return;

  final me = widget.currentUserId;
  final isAdding = !msg.heartReactorIds.contains(me);

  final next = msg.heartReactorIds.toSet();
  if (isAdding) {
    next.add(me);
  } else {
    next.remove(me);
  }

  final updated = msg.copyWith(heartReactorIds: next);

  setState(() {
    final i = _messages.indexWhere((m) => m.ts == msg.ts);
    if (i != -1) _messages[i] = updated;
  });

  // משתמשים אצלך כבר שומרים את החדר להייב באותה פונקציה ששומרת הכל
  // אל תשני אותה — רק תקראי לה.
  await _saveMessagesForRoom(updateMeta: false);


  // 🎬 אנימציה: לפי הספציפיקציה — רק מי שכתבה את ההודעה “מקבלת” את הלב.
  // ברגע שיהיה multi-device אמיתי, זה יעבוד מושלם.
  if (isAdding && msg.senderId == widget.currentUserId) {
    final reactorColor = _bubbleColorForUserId(me);
HeartReactionFlyLayer.of(context).spawnHeart(color: reactorColor);

  }
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
  Future.delayed(const Duration(milliseconds: 1150), () {

    if (!mounted) return;

    // ✅ turn OFF (MessageRow will fade it out)
    setState(() {
      _newBadgeVisibleByTs[ts] = false;
    });

    // ✅ keep it in the map a bit longer so fade-out can finish
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      _newBadgeVisibleByTs.remove(ts);
    });
  });
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
  // ✅ Persist system lines to Hive (but do NOT update DM meta / unread)
final msg = ChatMessage(
  type: ChatMessageType.system,
  senderId: '',
  text: line,
  ts: DateTime.now().millisecondsSinceEpoch,
);

  // Add to memory
  _messages.add(msg);

  // Update UI only if requested + we're still mounted
  if (showInUi && mounted) {
    setState(() {});
  }

  // ✅ Save to Hive so other users / future opens can see it
  await _saveMessagesForRoom(updateMeta: false);

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



  /// ===== Local presence (UI-only) =====
  static final Map<String, ValueNotifier<Set<String>>> _roomOnline = {};
  late final ValueNotifier<Set<String>> _onlineNotifier;

  /// ===== Local typing (UI-only) =====
  static final Map<String, ValueNotifier<Set<String>>> _roomTyping = {};
  late final ValueNotifier<Set<String>> _typingNotifier;

  void _markMeOnline() {
    _onlineNotifier.value = {..._onlineNotifier.value, widget.currentUserId};
  }

  void _markMeOffline() {
    _onlineNotifier.value = {..._onlineNotifier.value}
      ..remove(widget.currentUserId);
  }

  void _setMeTyping(bool typing) {
    final current = {..._typingNotifier.value};
    if (typing) {
      current.add(widget.currentUserId);
    } else {
      current.remove(widget.currentUserId);
    }
    _typingNotifier.value = current;
  }
  void _handleTypingChange() {
    final hasFocus = _focusNode.hasFocus;
    final hasText = _controller.text.trim().isNotEmpty;

    // typing == focus + has some text
    final shouldType = hasFocus && hasText;

    // Only react if my typing state actually changed (so we don't spam updates)
    final wasTyping = _typingNotifier.value.contains(widget.currentUserId);

    _setMeTyping(shouldType);

    // ✅ If typing just turned ON, auto-scroll so I can see my own typing preview
    if (!wasTyping && shouldType) {
      _scrollToBottom(keepFocus: true);
    }
  }


@override
void initState() {
  super.initState();
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

  _typingNotifier = _roomTyping.putIfAbsent(
    widget.roomId,
    () => ValueNotifier<Set<String>>(<String>{}),
  );

  // ✅ I am online in this room (UI-only)
  _markMeOnline();

  // ✅ typing listeners (UI-only)
  _controller.addListener(_handleTypingChange);
  _focusNode.addListener(_handleTypingChange);

  // ✅ Presence-based daily fact bot (GROUP ONLY)
  _onlineListener = () {
    if (widget.roomId == 'group_main') {
      DailyFactBotScheduler.I.pingPresence(roomId: 'group_main');
    }
  };

  // ✅ Actually attach the listener
  _onlineNotifier.addListener(_onlineListener!);

  // ✅ initial ping for group
  if (widget.roomId == 'group_main') {
    DailyFactBotScheduler.I.pingPresence(roomId: 'group_main');
  }

  // ✅ load bubble style for this user (saved locally)
  _loadBubbleStyle();

  _loadMessagesForRoom().then((_) async {
    await _markRoomReadNow(); // ✅ mark as read when opening
    await _emitEntered();
  });

  _box().then((box) {
_roomSub = box.watch(key: _roomKey(widget.roomId)).listen((event) async {
  // snapshot "seen" BEFORE reload
  final oldSeen = Set<int>.from(_seenMessageTs);

  await _loadMessagesForRoom();
  if (!mounted) return;

  // seed seen on first loads (so history won't flash NEW)
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

    // ✅ NEW badge ONLY in GROUP CHAT
    if (widget.roomId == 'group_main') {
      // show NEW only for messages from others (live vibe)
      final bool isMe = m.senderId == widget.currentUserId;
      if (!isMe && m.type == ChatMessageType.text) {
        _triggerNewBadgeForTs(ts);
      }
    }
  }
}
if (widget.roomId == 'group_main') {
  await DailyFactBotScheduler.I.pingPresence(roomId: 'group_main');
  await DailyFactBotScheduler.I.debugSendIn10Seconds();
}

  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    _scrollToBottom();
  });
});

  });
}



@override
void dispose() {
  // ✅ Write "left" line even in dispose:
  // showInUi=false => no setState, but it WILL be saved to Hive now.
  _emitLeft(showInUi: false);

  _roomSub?.cancel();
  _roomSub = null;

  _hourTimer?.cancel();

  _setMeTyping(false);
  _controller.removeListener(_handleTypingChange);
  _focusNode.removeListener(_handleTypingChange);

  _markMeOffline();

  _scrollController.dispose();
  _controller.dispose();
  _focusNode.dispose();

  if (_onlineListener != null) {
    _onlineNotifier.removeListener(_onlineListener!);
    _onlineListener = null;
  }
_bgFxCtrl.dispose();

  super.dispose();
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

  void _scrollToBottom({bool keepFocus = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      if (keepFocus) _focusNode.requestFocus();
    });
  }
Future<void> _debugSimulateIncomingMessage() async {
  final ts = DateTime.now().millisecondsSinceEpoch;

  setState(() {
    _messages.add(
      ChatMessage(
        type: ChatMessageType.text,
        senderId: 'adi', // כאילו עדי שלחה
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

void _sendMessage() {
  final text = _controller.text.trim();
  final bool triggerCreepy = _shouldTriggerCreepyEgg(text);

  if (text.isEmpty) return;

  final bool triggerEgg = _shouldTrigger707Egg(text);

  final BubbleTemplate templateForThisMessage = _selectedTemplate;
  final BubbleDecor decorForThisMessage = _selectedDecor;

  // ✅ Pick a random font only if there's English in the message
  final String? fontFamilyForThisMessage = _containsEnglishLetters(text)
      ? _englishFonts[_rng.nextInt(_englishFonts.length)]
      : null;

  setState(() {
    _messages.add(
      ChatMessage(
        type: ChatMessageType.text,
        senderId: widget.currentUserId,
        text: text,
        ts: DateTime.now().millisecondsSinceEpoch,
        bubbleTemplate: templateForThisMessage,
        decor: decorForThisMessage,
        fontFamily: fontFamilyForThisMessage,
      ),
    );

    _controller.clear();
    _isTyping = true;

    // ✅ Auto reset: next message goes back to normal + no decor
    _selectedTemplate = BubbleTemplate.normal;
    _selectedDecor = BubbleDecor.none;
  });

  _saveMessagesForRoom(
    updateMeta: true,
    lastSenderId: widget.currentUserId,
  );

  // ✅ SEND SFX (only when a real message was sent)
  Sfx.I.playSend();

  // ✅ 707 Easter Egg voice line (SFX only)
  if (triggerEgg) {
    Sfx.I.play707VoiceLine();
  }

  // ✅ Creepy background + glitch + music (Easter Egg)
  if (triggerCreepy) {
    _playCreepyEggFx();
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      _focusNode.requestFocus();
    }
  });
}





@override
Widget build(BuildContext context) {
final int hour = _uiHour;
final bg = _bgOverride ?? backgroundForHour(hour);
final Color usernameColor = usernameColorForHour(hour);


  final double uiScale = mysticUiScale(context);



  debugPrint('HOUR=$hour  usernameColor=$usernameColor  bg=$bg  uiScale=$uiScale');
return Scaffold(
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
  onBack: () {
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

  // ⭐️ זה החלק הקריטי
  layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
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
          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
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
      // ✅ typing users list (sorted for stability)
      final typingList = typingIds.toList();
      typingList.sort((a, b) {
        final an = users[a]?.name ?? a;
        final bn = users[b]?.name ?? b;
        return an.toLowerCase().compareTo(bn.toLowerCase());
      });

      // ✅ limit typing bubbles (so it won’t spam the UI)
      final limitedTyping = typingList.take(3).toList();

      final totalCount = _messages.length + limitedTyping.length;

      return ListView.builder(
        controller: _scrollController,
padding: EdgeInsets.only(
  top: 8 * uiScale,
  bottom: 88 * uiScale,
),

        itemCount: totalCount,
        itemBuilder: (context, index) {
          const double chatSidePadding = 16;

          // =========================
          // 1) REAL MESSAGES
          // =========================
if (index < _messages.length) {
  final msg = _messages[index];
  final prev = index > 0 ? _messages[index - 1] : null;

  // ✅ DATE DIVIDER LOGIC (Group Chat only)
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
    topSpacing = 18;
  } else if (prev == null) {
    topSpacing = 14;
  } else if (prev.type == ChatMessageType.system) {
    topSpacing = 16;
  } else if (prev.senderId == msg.senderId) {
    topSpacing = 40;
  } else {
    topSpacing = 20;
  }

  // ✅ We return a Column so we can inject the divider ABOVE the message
  final List<Widget> pieces = <Widget>[];

  if (showDateDivider) {
    pieces.add(_GcDateDivider(label: dateLabel, uiScale: uiScale));
  }

  if (msg.type == ChatMessageType.system) {
    const double systemSideInset = 2.0; // baseline
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
  if (user == null) {
    // sender no longer exists (e.g. removed user like "nella")
    return const SizedBox.shrink();
  }

final isMe = user.id == widget.currentUserId;

// ✅ Group-only UI features
final bool isGroup = widget.roomId == 'group_main';
final bool showNew = isGroup ? (_newBadgeVisibleByTs[msg.ts] ?? false) : false;

pieces.add(
  Padding(
    padding: EdgeInsets.fromLTRB(
      chatSidePadding * uiScale,
      topSpacing * uiScale,
      chatSidePadding * uiScale,
      0,
    ),
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () => _toggleHeartForMessage(msg),
      child: MessageRow(
        user: user,
        text: msg.text,
        isMe: isMe,
        bubbleTemplate: msg.bubbleTemplate,
        decor: msg.decor,
        fontFamily: msg.fontFamily,

        showName: true,
        nameHearts: _buildHeartIcons(msg.heartReactorIds, uiScale),

        // ✅ NEW: show time for group too (DMs already have their own logic elsewhere)
        showTime: (widget.roomId == 'group_main'),
        timeMs: msg.ts,

        showNewBadge: showNew,
        usernameColor: usernameColor,
        uiScale: uiScale,
      ),
    ),
  ),
);


  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: pieces,
  );
}


          // =========================
          // 2) TYPING BUBBLES (INLINE)
          // =========================
          final typingIndex = index - _messages.length;
          final typingUserId = limitedTyping[typingIndex];
          final typingUser = users[typingUserId]!;
          final isMeTyping = typingUserId == widget.currentUserId;

          // spacing above typing indicators
          final double topSpacing = 18;

return Padding(
  padding: EdgeInsets.fromLTRB(
    chatSidePadding * uiScale,
    topSpacing * uiScale,
    chatSidePadding * uiScale,
    0,
  ),
  child: TypingBubbleRow(
    user: typingUser,
    isMe: isMeTyping,
    uiScale: uiScale, // ✅ NEW
  ),
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
