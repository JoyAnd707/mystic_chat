import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../audio/sfx.dart';
import 'dart:math' as math;

enum BubbleTemplate {
  normal,
  glow,
}

enum BubbleDecor {
  none,
  hearts,
  pinkHearts,

  /// ✅ NEW: same format as Hearts, but tinted + glow
  cornerStarsGlow,

  /// ✅ Single sticker: bottom-left corner
  flowersRibbon,

  /// ✅ Single sticker: bottom-left corner (same behavior as flowersRibbon)
  stars,

  /// ✅ Music note: top corner
  musicNotes,

  /// ✅ Surprise: top corner (same behavior as musicNotes)
  surprise,

  /// ✅ Kitty: top corner (same behavior as musicNotes + surprise)
  kitty,

  /// ✅ Drip tinted to bubble + sad face on top
  dripSad,
}


class TopBorderBar extends StatelessWidget {
  final double height;
  const TopBorderBar({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: height,
        width: double.infinity,
        color: Colors.black,
      ),
    );
  }
}

class BottomBorderBar extends StatelessWidget {
  final double height;
  final bool isTyping;
  final VoidCallback onTapTypeMessage;
  final VoidCallback onSend;
  final TextEditingController controller;
  final FocusNode focusNode;

  /// ✅ NEW
  final double uiScale;

  const BottomBorderBar({
    super.key,
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
 static const double _sendScale = 1.0;


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

  // =====================
  // BEFORE TYPING
  // =====================
  Widget _typeMessageBar(double Function(double) s) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Type Message button
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

  // =====================
  // TYPING MODE
  // =====================
  Widget _typingBar(double Function(double) s) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Type bar + text field
        SizedBox(
          width: s(_typeButtonWidth),
          child: Stack(
            children: [
              Image.asset(
                'assets/ui/TypeBar.png',
                fit: BoxFit.fitWidth,
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: s(18),
                    vertical: s(8),
                  ),
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


class ActiveUsersBar extends StatelessWidget {
  final Map<String, ChatUser> usersById;
  final Set<String> onlineUserIds;
  final String currentUserId;
  final VoidCallback onBack;

  /// ✅ opens the bubble-style menu
  final VoidCallback onOpenBubbleMenu;

  /// ✅ title text to display in the center
  final String titleText;

  /// ✅ UI scale
  final double uiScale;

  const ActiveUsersBar({
    super.key,
    required this.usersById,
    required this.onlineUserIds,
    required this.currentUserId,
    required this.onBack,
    required this.onOpenBubbleMenu,
    required this.titleText,
    required this.uiScale,
  });

  static const double barHeight = 64;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * uiScale;

    final double tapSize = s(40);
    final double iconSize = s(26);

    return SizedBox(
      height: s(barHeight),
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/ui/ChatParticipantList.png',
              fit: BoxFit.cover,
            ),
          ),

          // ✅ Back triangle (left)
          Positioned(
            left: s(4),
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Sfx.I.playBack();
                  onBack();
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: tapSize,
                  height: tapSize,
                  child: Center(
                    child: Image.asset(
                      'assets/ui/ChatBackButton.png',
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ✅ Max Speed (LEFT) — נשאר
          Positioned(
            left: s(44),
            top: 0,
            bottom: 0,
            child: Center(
              child: Image.asset(
                'assets/ui/MaxSpeedDecoy.png',
                width: s(57),
                height: s(42),
                fit: BoxFit.contain,
              ),
            ),
          ),

          // ✅ Active users text (center) — זה מה שאת רוצה להשאיר
          Positioned.fill(
            child: Center(
              child: Builder(
                builder: (context) {
                  final ids = onlineUserIds.toList();

                  // Mystic-like: sorted + show current user too
                  ids.sort((a, b) {
                    final an = usersById[a]?.name ?? a;
                    final bn = usersById[b]?.name ?? b;
                    return an.toLowerCase().compareTo(bn.toLowerCase());
                  });

                  final names = ids
                      .map((id) => usersById[id]?.name ?? id)
                      .where((n) => n.trim().isNotEmpty)
                      .toList();

                  final centerText = names.isEmpty ? titleText : names.join(', ');

                  return Text(
                    centerText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: s(18),
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
          ),

          // ❌ הוסר: Active users row (bottom center)
          // זה בדיוק מה שצייר את ה-A הקטנה

          // ✅ Bubble menu button (RIGHT)
          Positioned(
            right: s(6),
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: onOpenBubbleMenu,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: tapSize,
                  height: tapSize,
                  child: Center(
                    child: Icon(
                      Icons.auto_awesome,
                      size: s(20),
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}




/// =======================
/// MODEL (UI)
/// =======================
class ChatUser {
  final String id;
  final String name;
  final Color bubbleColor;
  final String? avatarPath;

  const ChatUser({
    required this.id,
    required this.name,
    required this.bubbleColor,
    this.avatarPath,
  });
}

/// =======================
/// SYSTEM MESSAGE BAR (entered/left)
/// =======================
class SystemMessageBar extends StatelessWidget {
  final String text;

  /// ✅ NEW
  final double uiScale;

  const SystemMessageBar({
    super.key,
    required this.text,
    this.uiScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * uiScale;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: s(8)),
      padding: EdgeInsets.symmetric(vertical: s(6)),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(s(2)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: s(11),
          fontWeight: FontWeight.w400,
          height: 1.2,
        ),
      ),
    );
  }
}


/// =======================
/// MESSAGE ROW (bubble + tail + avatar)
/// =======================
class MessageRow extends StatelessWidget {
  final ChatUser user;
  final String text;
  final bool isMe;
  final List<Widget> nameHearts;

  /// ✅ איזה טמפלייט לצייר
  final BubbleTemplate bubbleTemplate;

  /// ✅ איזה קישוט להדביק על הבועה
  final BubbleDecor decor;

  /// ✅ Optional per-message font family (English random fonts)
  final String? fontFamily;

  final bool showName;
  final Color usernameColor;
  final double uiScale; // ✅ NEW
  final bool showNewBadge;

  /// ✅ NEW: time under message (like DMs)
  final bool showTime;
  final int timeMs;

  const MessageRow({
    super.key,
    required this.user,
    required this.text,
    required this.isMe,
    required this.bubbleTemplate,
    this.decor = BubbleDecor.none,
    this.fontFamily,
    this.showName = true,
    required this.usernameColor,
    required this.showNewBadge,
    this.nameHearts = const <Widget>[],
    required this.uiScale,

    // ✅ NEW
    this.showTime = false,
    this.timeMs = 0,
  });

  Color _decorBaseFromUser(Color c) {
    // Very light tint (reference: #fff8f8 on red)
    return _lighten(c, 0.88);
  }

  Color _decorGlowFromUser(Color c) {
    // Deeper glow (reference: #b47080 on red)
    final hsl = HSLColor.fromColor(c);
    final darker = hsl
        .withLightness((hsl.lightness * 0.62).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.95 + 0.05).clamp(0.0, 1.0))
        .toColor();
    // Slightly pull toward warm pink-ish glow like Mystic
    const warm = Color(0xFFB47080);
    return Color.lerp(darker, warm, 0.22) ?? darker;
  }

  Widget _decorWithGlow({
    required String asset,
    required double w,
    required double h,
    required Color baseTint,
    required Color glowTint,
  }) {
    return IgnorePointer(
      ignoring: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ✅ Glow layer (blurred + tinted)
          Opacity(
            opacity: 0.95,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(glowTint, BlendMode.srcIn),
                child: Image.asset(
                  asset,
                  width: w,
                  height: h,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // ✅ Base layer (light tinted)
          ColorFiltered(
            colorFilter: ColorFilter.mode(baseTint, BlendMode.srcIn),
            child: Image.asset(
              asset,
              width: w,
              height: h,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Color _lerp(Color a, Color b, double t) {
    return Color.lerp(a, b, t) ?? a;
  }

  Color _lighten(Color c, double amount) {
    return _lerp(c, Colors.white, amount.clamp(0.0, 1.0));
  }

  // “Mystic-ish” inner dark glow:
  Color _innerDarkGlowFromBase(Color base) {
    final hsl = HSLColor.fromColor(base);

    final muted = hsl
        .withLightness((hsl.lightness * 0.45).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.45).clamp(0.0, 1.0))
        .toColor();

    const warmHint = Color(0xFFAD927E);
    return Color.lerp(muted, warmHint, 0.12) ?? muted;
  }

  Color _outerBrightGlowFromBase(Color base) {
    final lifted = _lighten(base, 0.70);
    return _lerp(lifted, Colors.white, 0.10);
  }

  Color _darkenColor(Color color, [double amount = 0.25]) {
    final hsl = HSLColor.fromColor(color);
    final darker = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return darker.toColor();
  }

  /// ✅ Fixes "punctuation jumps to the wrong side" in mixed RTL/LTR chat.
  /// We isolate each message so surrounding Directionality doesn't reorder punctuation.
  String _bidiIsolate(String s) => '\u2068$s\u2069'; // FSI ... PDI

  bool _isProbablyRtl(String s) {
    // Hebrew + Arabic ranges (covers common RTL languages).
    return RegExp(r'[\u0590-\u08FF]').hasMatch(s);
  }

  Color _musicNoteTintFromBubble(Color bubble) {
    final hsl = HSLColor.fromColor(bubble);

    // ✅ computed from your reference:
    // base  #FFF5EB = HSL(30, 100%, 96%)
    // note  #F3B7A2 = HSL(16,  77%, 79%)
    const double hueShift = -14.44444444; // degrees (16 - 30)
    const double satFactor = 0.7714285714; // 77 / 100
    const double lightFactor = 0.8229166667; // 79 / 96

    // ✅ make it a bit darker (closer to your reference look on saturated bubbles)
    const double extraDarken = 0.92; // 1.0 = original ratio, <1.0 = darker

    final double hue = (hsl.hue + hueShift) % 360;
    final double sat = (hsl.saturation * satFactor).clamp(0.0, 1.0);
    final double light =
        (hsl.lightness * lightFactor * extraDarken).clamp(0.0, 1.0);

    return HSLColor.fromAHSL(1.0, hue, sat, light).toColor();
  }

  // ✅ NEW: simple HH:mm formatter (no intl)
  String _timeLabel(int ms) {
    if (ms <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final double avatarSize = 56 * uiScale; // ✅ scale with device
    final double gap = 10 * uiScale;
    double s(double v) => v * uiScale;

    final avatar = SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: SquareAvatar(
        size: avatarSize,
        letter: user.name[0],
        imagePath: user.avatarPath,
      ),
    );

    final BubbleTemplate effectiveTemplate = bubbleTemplate;

    // צבע בסיס: כמו הבועה הרגילה, ובמצבי אפקט אפשר קצת להרים אותו
    final Color bubbleBase = user.bubbleColor;
    final Color bubbleFill = (effectiveTemplate == BubbleTemplate.glow)
        ? _lighten(bubbleBase, 0.18)
        : bubbleBase;

    // ✅ NORMAL / GLOW
    final Color innerDarkGlow = _innerDarkGlowFromBase(bubbleFill);
    final Color outerBrightGlow = _outerBrightGlowFromBase(bubbleFill);

    // ✅ Corner Stars (Glow)
    final Color cornerStarsBaseTint = _decorBaseFromUser(user.bubbleColor);
    final Color cornerStarsGlowTint = _decorGlowFromUser(user.bubbleColor);

    const String cornerStarsLeftAsset =
        'assets/decors/TextBubble4CornerStarsLeft.png';
    const String cornerStarsRightAsset =
        'assets/decors/TextBubble4CornerStarsRightpng.png';

    final bubbleInner = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * uiScale,
        vertical: 6 * uiScale,
      ),
      child: Directionality(
        textDirection: _isProbablyRtl(text) ? TextDirection.rtl : TextDirection.ltr,
        child: Text(
          _bidiIsolate(text),
          textAlign: _isProbablyRtl(text) ? TextAlign.right : TextAlign.left,
          strutStyle: StrutStyle(
            fontSize: 16 * uiScale,
            height: 1.2,
            forceStrutHeight: true,
          ),
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 16 * uiScale,
            height: 1.2,
            color: Colors.black,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.15 * uiScale,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ),
    );

    final double screenW = MediaQuery.of(context).size.width;
    final double sidePadding = 16 * uiScale;
    final double availableForBubble =
        screenW - (sidePadding * 2) - (avatarSize + gap);

    final double groupMax = availableForBubble * 0.75;
    final double legacyMax = 260 * uiScale;
    final double maxBubbleWidth = math.min(legacyMax, groupMax);

    final bubbleWidget = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      child: BubbleWithTail(
        color: bubbleFill,
        isMe: isMe,
        radius: 6 * uiScale,
        tailWidth: 10 * uiScale,
        tailHeight: 6 * uiScale,
        tailTop: 12 * uiScale,
        glowEnabled: (effectiveTemplate == BubbleTemplate.glow),
        glowInnerColor: innerDarkGlow,
        glowOuterColor: outerBrightGlow,
        child: bubbleInner,
      ),
    );

    final bubbleStack = Stack(
      clipBehavior: Clip.none,
      children: [
        bubbleWidget,

        // ✅ NEW badge
        Positioned(
          top: s(-10),
          left: isMe ? s(-14) : null,
          right: isMe ? null : s(-14),
          child: IgnorePointer(
            ignoring: true,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              opacity: showNewBadge ? 1.0 : 0.0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                scale: showNewBadge ? 1.08 : 0.92,
                child: MysticNewBadge(
                  uiScale: uiScale,
                ),
              ),
            ),
          ),
        ),

// ✅ DECOR: Hearts
if (decor == BubbleDecor.hearts) ...[
  if (isMe) ...[
    // TOP-LEFT
    Positioned(
      top: s(-22),
      left: s(-28),
      child: IgnorePointer(
        ignoring: true,
        child: Image.asset(
          'assets/decors/TextBubbleLeftHearts.png',
          width: s(46),
          height: s(46),
          fit: BoxFit.contain,
        ),
      ),
    ),
    // BOTTOM-RIGHT
    Positioned(
      bottom: s(-8),
      right: s(-20),
      child: IgnorePointer(
        ignoring: true,
        child: Image.asset(
          'assets/decors/TextBubbleRightHearts.png',
          width: s(48),
          height: s(48),
          fit: BoxFit.contain,
        ),
      ),
    ),
  ] else ...[
    // TOP-RIGHT (mirror of TOP-LEFT)
    Positioned(
      top: s(-22),
      right: s(-28),
      child: IgnorePointer(
        ignoring: true,
        child: Transform.flip(
          flipX: true,
          child: Image.asset(
            'assets/decors/TextBubbleLeftHearts.png',
            width: s(46),
            height: s(46),
            fit: BoxFit.contain,
          ),
        ),
      ),
    ),
    // ✅ BOTTOM-LEFT (mirror of BOTTOM-RIGHT) — זה החיבור שחסר לך
    Positioned(
      bottom: s(-8),
      left: s(-20),
      child: IgnorePointer(
        ignoring: true,
        child: Transform.flip(
          flipX: true,
          child: Image.asset(
            'assets/decors/TextBubbleRightHearts.png',
            width: s(48),
            height: s(48),
            fit: BoxFit.contain,
          ),
        ),
      ),
    ),
  ],
],


// ✅ DECOR: Pink Hearts
if (decor == BubbleDecor.pinkHearts) ...[
  if (isMe) ...[
    // TOP-LEFT
    Positioned(
      top: s(-22),
      left: s(-28),
      child: IgnorePointer(
        ignoring: true,
        child: Image.asset(
          'assets/decors/TextBubblePinkHeartsLeft.png',
          width: s(46),
          height: s(46),
          fit: BoxFit.contain,
        ),
      ),
    ),
    // BOTTOM-RIGHT
    Positioned(
      bottom: s(-8),
      right: s(-20),
      child: IgnorePointer(
        ignoring: true,
        child: Image.asset(
          'assets/decors/TextBubblePinkHeartsRight.png',
          width: s(48),
          height: s(48),
          fit: BoxFit.contain,
        ),
      ),
    ),
  ] else ...[
    // TOP-RIGHT (mirror)
    Positioned(
      top: s(-22),
      right: s(-28),
      child: IgnorePointer(
        ignoring: true,
        child: Transform.flip(
          flipX: true,
          child: Image.asset(
            'assets/decors/TextBubblePinkHeartsLeft.png',
            width: s(46),
            height: s(46),
            fit: BoxFit.contain,
          ),
        ),
      ),
    ),
    // ✅ BOTTOM-LEFT (mirror) — גם פה היה חסר
    Positioned(
      bottom: s(-8),
      left: s(-20),
      child: IgnorePointer(
        ignoring: true,
        child: Transform.flip(
          flipX: true,
          child: Image.asset(
            'assets/decors/TextBubblePinkHeartsRight.png',
            width: s(48),
            height: s(48),
            fit: BoxFit.contain,
          ),
        ),
      ),
    ),
  ],
],


        // ✅ DECOR: Stars
        if (decor == BubbleDecor.stars) ...[
          if (isMe)
            Positioned(
              bottom: s(-20),
              left: s(-25),
              child: IgnorePointer(
                ignoring: true,
                child: Image.asset(
                  'assets/decors/TextBubbleStars.png',
                  width: s(44),
                  height: s(44),
                  fit: BoxFit.contain,
                ),
              ),
            )
          else
            Positioned(
              bottom: s(-20),
              right: s(-25),
              child: IgnorePointer(
                ignoring: true,
                child: Transform.flip(
                  flipX: true,
                  child: Image.asset(
                    'assets/decors/TextBubbleStars.png',
                    width: s(44),
                    height: s(44),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
        ],

        // ✅ DECOR: DripSad
        if (decor == BubbleDecor.dripSad) ...[
          Positioned(
            bottom: s(-31),
            right: isMe ? s(6) : null,
            left: isMe ? null : s(6),
            child: IgnorePointer(
              ignoring: true,
              child: Transform.flip(
                flipX: isMe,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    bubbleFill,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/decors/TextBubbleDrip.png',
                    width: s(40),
                    height: s(40),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: s(-7),
            right: isMe ? s(12) : null,
            left: isMe ? null : s(18),
            child: IgnorePointer(
              ignoring: true,
              child: Transform.flip(
                flipX: isMe,
                child: Image.asset(
                  'assets/decors/TextBubbleSadFace.png',
                  width: s(22),
                  height: s(22),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],

        // ✅ DECOR: Music Notes
        if (decor == BubbleDecor.musicNotes) ...[
          Positioned(
            top: s(-18),
            left: isMe ? s(-18) : null,
            right: isMe ? null : s(-18),
            child: IgnorePointer(
              ignoring: true,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  _musicNoteTintFromBubble(bubbleFill),
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/decors/TextBubbleMusicNotes.png',
                  width: s(34),
                  height: s(34),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],

        // ✅ DECOR: Surprise
        if (decor == BubbleDecor.surprise) ...[
          Positioned(
            top: s(-18),
            left: isMe ? s(-18) : null,
            right: isMe ? null : s(-18),
            child: IgnorePointer(
              ignoring: true,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  _musicNoteTintFromBubble(bubbleFill),
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/decors/TextBubbleSurprise.png',
                  width: s(34),
                  height: s(34),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],

// ✅ DECOR: Corner Stars Glow
if (decor == BubbleDecor.cornerStarsGlow) ...[
  if (isMe) ...[
    // TOP-LEFT
    Positioned(
      top: s(-18),
      left: s(-22),
      child: _decorWithGlow(
        asset: cornerStarsLeftAsset,
        w: s(46),
        h: s(46),
        baseTint: cornerStarsBaseTint,
        glowTint: cornerStarsGlowTint,
      ),
    ),
    // BOTTOM-RIGHT
    Positioned(
      bottom: s(-8),
      right: s(-20),
      child: _decorWithGlow(
        asset: cornerStarsRightAsset,
        w: s(48),
        h: s(48),
        baseTint: cornerStarsBaseTint,
        glowTint: cornerStarsGlowTint,
      ),
    ),
  ] else ...[
    // TOP-RIGHT (mirror)
    Positioned(
      top: s(-18),
      right: s(-22),
      child: Transform.flip(
        flipX: true,
        child: _decorWithGlow(
          asset: cornerStarsLeftAsset,
          w: s(46),
          h: s(46),
          baseTint: cornerStarsBaseTint,
          glowTint: cornerStarsGlowTint,
        ),
      ),
    ),
    // ✅ BOTTOM-LEFT (mirror) — זה החיבור שחסר לך בכוכבים
    Positioned(
      bottom: s(-8),
      left: s(-20),
      child: Transform.flip(
        flipX: true,
        child: _decorWithGlow(
          asset: cornerStarsRightAsset,
          w: s(48),
          h: s(48),
          baseTint: cornerStarsBaseTint,
          glowTint: cornerStarsGlowTint,
        ),
      ),
    ),
  ],
],


        // ✅ DECOR: Kitty
        if (decor == BubbleDecor.kitty) ...[
          Positioned(
            top: s(-18),
            left: isMe ? s(-18) : null,
            right: isMe ? null : s(-18),
            child: IgnorePointer(
              ignoring: true,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      _musicNoteTintFromBubble(bubbleFill),
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/decors/TextBubbleKitty.png',
                      width: s(34),
                      height: s(34),
                      fit: BoxFit.contain,
                    ),
                  ),
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      _darkenColor(_musicNoteTintFromBubble(bubbleFill), 0.25),
                      BlendMode.srcIn,
                    ),
                    child: Transform.scale(
                      scale: 0.78,
                      child: Image.asset(
                        'assets/decors/TextBubbleKittyFace.png',
                        width: s(34),
                        height: s(34),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );

    final String tLabel = showTime ? _timeLabel(timeMs) : '';

final bubbleWithName = Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch, // ✅ חשוב! נותן לנו רוחב
  children: [
    if (showName)
      Padding(
        padding: EdgeInsets.only(bottom: 2 * uiScale),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMe) ...nameHearts,
              if (isMe && nameHearts.isNotEmpty) SizedBox(width: 4 * uiScale),
              Text(
                user.name,
                style: TextStyle(
                  color: usernameColor,
                  fontSize: 13.5 * uiScale,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                  letterSpacing: 0.2 * uiScale,
                ),
              ),
              if (!isMe && nameHearts.isNotEmpty) SizedBox(width: 4 * uiScale),
              if (!isMe) ...nameHearts,
            ],
          ),
        ),
      ),

    // ✅ "Bubble area" with fixed width so alignment works
    Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: SizedBox(
        width: maxBubbleWidth,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: bubbleStack,
        ),
      ),
    ),

    // ✅ Time under bubble — OPPOSITE SIDE
    if (showTime && tLabel.isNotEmpty)
      Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: SizedBox(
          width: maxBubbleWidth,
          child: Padding(
            padding: EdgeInsets.only(top: 6 * uiScale),
            child: Align(
              alignment: isMe ? Alignment.centerLeft : Alignment.centerRight, // ✅ flipped
              child: Text(
                tLabel,
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12 * uiScale,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  letterSpacing: 0.2 * uiScale,
                ),
              ),
            ),
          ),
        ),
      ),
  ],
);


    // ✅ אחרים (isMe=false): האווטאר חייב להיות שכבה מעל המדבקה התחתונה
    if (!isMe) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.only(left: avatarSize + gap),
            child: bubbleWithName,
          ),


          Positioned(
            left: 0,
            top: 0,
            child: avatar,
          ),
        ],
      );
    }

    // ✅ אני (isMe=true)
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(right: avatarSize + gap),
          child: Align(
            alignment: Alignment.centerRight,
            child: bubbleWithName,
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: avatar,
        ),
      ],
    );
  }
}




class TypingBubbleRow extends StatelessWidget {
  final ChatUser user;
  final bool isMe;
  final double uiScale;

  const TypingBubbleRow({
    super.key,
    required this.user,
    required this.isMe,
    required this.uiScale,
  });

  Color _darken(Color c, [double amount = 0.25]) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final double avatarSlot = 56 * uiScale;

    final bubbleFill = user.bubbleColor;
    final dotsColor = _darken(bubbleFill, 0.55).withOpacity(0.85);

    final typingBubble = Container(
      width: avatarSlot,
      height: 34 * uiScale,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bubbleFill,
        borderRadius: BorderRadius.circular(8 * uiScale),
      ),
      child: TypingDots(
        color: dotsColor,
        dotSize: 6.0 * uiScale,
        gap: 4.0 * uiScale,
      ),
    );

    return SizedBox(
      height: avatarSlot,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: isMe ? null : 0,
            right: isMe ? 0 : null,
            child: typingBubble,
          ),
        ],
      ),
    );
  }
}


class SquareAvatar extends StatelessWidget {
  final double size;
  final String letter;
  final String? imagePath;

  const SquareAvatar({
    super.key,
    required this.size,
    required this.letter,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.zero, // ✅ פינות חדות לגמרי
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: (imagePath != null && imagePath!.trim().isNotEmpty)
          ? ClipRect(
              child: Image.asset(
                imagePath!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(
                  letter.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ),
            )
          : Text(
              letter.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
    );
  }
}



/// =======================
/// BUBBLE + TAIL (single painted shape = no seam)
/// =======================
class _BubbleWithTailPainter extends CustomPainter {
  final Color color;
  final bool isMe;
  final double radius;
  final double tailWidth;
  final double tailHeight;

  /// ✅ locked from TOP (Mystic behavior)
  final double tailTop;

  final bool glowEnabled;
  final Color? glowInnerColor;
  final Color? glowOuterColor;

  _BubbleWithTailPainter({
    required this.color,
    required this.isMe,
    required this.radius,
    required this.tailWidth,
    required this.tailHeight,
    required this.tailTop,
    required this.glowEnabled,
    required this.glowInnerColor,
    required this.glowOuterColor,
  });

  double _sigma(double blurRadius) {
    return blurRadius * 0.57735 + 0.5;
  }

  Path _buildBubblePath(Size size) {
    final Rect bubbleRect = isMe
        ? Rect.fromLTWH(0, 0, size.width - tailWidth, size.height)
        : Rect.fromLTWH(tailWidth, 0, size.width - tailWidth, size.height);

    final RRect bubbleRRect = RRect.fromRectAndRadius(
      bubbleRect,
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(bubbleRRect);

    // ✅ tail center is anchored from TOP, so it never moves with message height
    final double cy = bubbleRect.top + tailTop + (tailHeight / 2);

    final double minCy = bubbleRect.top + radius + tailHeight / 2 + 1;
    final double maxCy = bubbleRect.bottom - radius - tailHeight / 2 - 1;
    final double tailCy = cy.clamp(minCy, maxCy);

    // ✅ SHARP TRIANGLE TAIL
    if (isMe) {
      final double xBase = bubbleRect.right;
      final double xTip = bubbleRect.right + tailWidth;

      path.moveTo(xBase, tailCy - tailHeight / 2);
      path.lineTo(xTip, tailCy);
      path.lineTo(xBase, tailCy + tailHeight / 2);
      path.close();
    } else {
      final double xBase = bubbleRect.left;
      final double xTip = bubbleRect.left - tailWidth;

      path.moveTo(xBase, tailCy - tailHeight / 2);
      path.lineTo(xTip, tailCy);
      path.lineTo(xBase, tailCy + tailHeight / 2);
      path.close();
    }

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = _buildBubblePath(size);

    // ✅ Glow must wrap the SAME path (bubble + tail)
    // ✅ Stroke-based glow: thickness stays constant no matter message length
    if (glowEnabled) {
      final Color inner = glowInnerColor ?? Colors.black;
      final Color outer = glowOuterColor ?? Colors.white;

      final Paint outerHaze = Paint()
        ..color = outer.withOpacity(0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 32.0
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, _sigma(22));

      final Paint innerSpread = Paint()
        ..color = inner.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, _sigma(8));

      final Paint tightRing = Paint()
        ..color = inner.withOpacity(0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, _sigma(2.2));

      canvas.drawPath(path, outerHaze);
      canvas.drawPath(path, innerSpread);
      canvas.drawPath(path, tightRing);
    }

    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant _BubbleWithTailPainter old) {
    return old.color != color ||
        old.isMe != isMe ||
        old.radius != radius ||
        old.tailWidth != tailWidth ||
        old.tailHeight != tailHeight ||
        old.tailTop != tailTop ||
        old.glowEnabled != glowEnabled ||
        old.glowInnerColor != glowInnerColor ||
        old.glowOuterColor != glowOuterColor;
  }
}


class BubbleWithTail extends StatelessWidget {
  final Widget child;
  final Color color;
  final bool isMe;

  /// bubble shape tuning
  final double radius;
  final double tailWidth;
  final double tailHeight;

  /// ✅ from TOP of bubble-rect (not counting tail gutter)
  final double tailTop;

  /// ✅ glow (must wrap bubble + tail)
  final bool glowEnabled;
  final Color? glowInnerColor;
  final Color? glowOuterColor;

  const BubbleWithTail({
    super.key,
    required this.child,
    required this.color,
    required this.isMe,
    this.radius = 6,
    this.tailWidth = 10,
    this.tailHeight = 6,
    this.tailTop = 12,
    this.glowEnabled = false,
    this.glowInnerColor,
    this.glowOuterColor,
  });

  @override
  Widget build(BuildContext context) {
    final EdgeInsets gutter = EdgeInsets.only(
      left: isMe ? 0 : tailWidth,
      right: isMe ? tailWidth : 0,
    );

    return CustomPaint(
      painter: _BubbleWithTailPainter(
        color: color,
        isMe: isMe,
        radius: radius,
        tailWidth: tailWidth,
        tailHeight: tailHeight,
        tailTop: tailTop,
        glowEnabled: glowEnabled,
        glowInnerColor: glowInnerColor,
        glowOuterColor: glowOuterColor,
      ),
      child: Padding(
        padding: gutter,
        child: child,
      ),
    );
  }
}



class BubbleTail extends StatelessWidget {
  final Color color;
  final bool isMe;

  const BubbleTail({
    super.key,
    required this.color,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(7, 8),
      painter: _TailPainter(color: color, isMe: isMe),
    );
  }
}

class _TailPainter extends CustomPainter {
  final Color color;
  final bool isMe;

  _TailPainter({required this.color, required this.isMe});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    if (isMe) {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// =======================
/// RTL/LTR detector (per message)
/// =======================
bool _isRtl(String text) {
  for (final rune in text.runes) {
    if (rune == 0x20) continue; // space

    final ch = String.fromCharCode(rune);

    final isWeak = ch.trim().isEmpty ||
        '0123456789.,!?;:-()[]{}\'"'.contains(ch) ||
        ch == '\u200E' || // LRM
        ch == '\u200F'; // RLM

    if (isWeak) continue;

    if ((rune >= 0x0590 && rune <= 0x08FF) ||
        (rune >= 0xFB1D && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF)) {
      return true;
    }

    return false;
  }

  return false;
}
// =====================
// Typing line (Option 2)
// =====================

class TypingDots extends StatefulWidget {
  final Color color;
  final double dotSize;
  final double gap;

  const TypingDots({
    super.key,
    required this.color,
    this.dotSize = 4.5,
    this.gap = 3.0,
  });

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _yForDot(int i, double t) {
    final phase = (t + i * 0.16) % 1.0;

    final v = (phase < 0.5)
        ? Curves.easeOut.transform(phase / 0.5)
        : Curves.easeIn.transform((1.0 - phase) / 0.5);

    return -6.0 * v;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : widget.gap),
              child: Transform.translate(
                offset: Offset(0, _yForDot(i, t)),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class TypingNamesLine extends StatelessWidget {
  final Map<String, ChatUser> usersById;
  final List<String> typingUserIds;
  final String currentUserId;

  /// אם יש יותר מ-2 מקלידות, נציג 2 ראשונות ואז "+N".
  final int maxNames;

  /// ✅ NEW
  final double uiScale;

  const TypingNamesLine({
    super.key,
    required this.usersById,
    required this.typingUserIds,
    required this.currentUserId,
    this.maxNames = 2,
    this.uiScale = 1.0,
  });

  String _nameFor(String id) {
    final u = usersById[id];
    final name = (u == null) ? id : u.name;
    return id == currentUserId ? 'You' : name;
  }

  Color _colorFor(String id) {
    final u = usersById[id];
    return (u == null) ? Colors.white : u.bubbleColor;
  }

  @override
  Widget build(BuildContext context) {
    if (typingUserIds.isEmpty) return const SizedBox.shrink();

    double s(double v) => v * uiScale;

    final shown = typingUserIds.take(maxNames).toList();
    final remaining = typingUserIds.length - shown.length;

    return Padding(
      padding: EdgeInsets.only(left: s(14), right: s(14), bottom: s(6)),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: s(8),
        runSpacing: s(4),
        children: [
          for (final id in shown) ...[
            Text(
              _nameFor(id),
              style: TextStyle(
                color: Colors.white.withOpacity(0.92),
                fontSize: s(12),
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            TypingDots(color: _colorFor(id), dotSize: s(4.5), gap: s(3.0)),
          ],
          if (remaining > 0) ...[
            Text(
              '+$remaining',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: s(12),
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            TypingDots(color: Colors.white.withOpacity(0.65), dotSize: s(4.5), gap: s(3.0)),
          ],
        ],
      ),
    );
  }
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
      borderRadius: BorderRadius.circular(s(1.8)), // היה 1.1
      child: Container(
        color: const Color(0xFFFF6769),
        padding: EdgeInsets.symmetric(
          horizontal: s(2.4), // היה 0.7
          vertical: s(0.9),   // היה 0.15
        ),
        child: Text(
          'NEW',
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: s(9.2),          // היה 6.0
            fontWeight: FontWeight.w900,
            height: 1.0,
            letterSpacing: s(0.35),     // היה 0.12
          ),
        ),
      ),
    );
  }
}

