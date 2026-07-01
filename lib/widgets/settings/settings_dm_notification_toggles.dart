import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../audio/sfx.dart';

class SettingsDmNotificationToggles extends StatefulWidget {
  final String currentUserId;

  const SettingsDmNotificationToggles({
    super.key,
    required this.currentUserId,
  });

  @override
  State<SettingsDmNotificationToggles> createState() =>
      _SettingsDmNotificationTogglesState();
}

class _SettingsDmNotificationTogglesState
    extends State<SettingsDmNotificationToggles> {
  final List<String> _userIds = const [
    'joy',
    'adi',
    'danielle',
    'lian',
    'tal',
    'lera',
    'lihi',
    'nella',
  ];

  final Map<String, bool> _enabledByUserId = {};
String _effectiveCurrentUserId = '';
  @override
  void initState() {
    super.initState();
    _loadDmNotificationSettings();
  }

String _prefKey(String userId) {
  return 'dm_notifications_${_effectiveCurrentUserId}_$userId';
}
Future<void> _loadDmNotificationSettings() async {
  final prefs = await SharedPreferences.getInstance();

  final String savedCurrentUserId =
      prefs.getString('currentUserId') ?? '';

  final String resolvedCurrentUserId =
      widget.currentUserId.trim().isNotEmpty
          ? widget.currentUserId.trim().toLowerCase()
          : savedCurrentUserId.trim().toLowerCase();

  final Map<String, bool> loaded = {};

  for (final userId in _userIds) {
    loaded[userId] =
        prefs.getBool('dm_notifications_${resolvedCurrentUserId}_$userId') ??
            true;
  }

  if (!mounted) return;

  setState(() {
    _effectiveCurrentUserId = resolvedCurrentUserId;
    _enabledByUserId
      ..clear()
      ..addAll(loaded);
  });
}
Future<void> _toggleUser(String userId) async {
  final bool currentValue = _enabledByUserId[userId] ?? true;
  final bool newValue = !currentValue;

  try {
    Sfx.I.playToggle();
  } catch (_) {}

  setState(() {
    _enabledByUserId[userId] = newValue;
  });

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_prefKey(userId), newValue);

  try {
    debugPrint('currentUserId is: ${widget.currentUserId}');
debugPrint('currentUserId lowercase is: ${widget.currentUserId.toLowerCase()}');
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('appUserId', isEqualTo: _effectiveCurrentUserId)
        .limit(1)
        .get();

    debugPrint('Found docs: ${snap.docs.length}');

    if (snap.docs.isEmpty) return;

    await snap.docs.first.reference.set({
      'dmNotificationSettings': {
        userId: newValue,
      },
      'dmNotificationSettingsUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint('DM notification setting saved.');
  } catch (e) {
    debugPrint('ERROR SAVING DM SETTINGS: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _DmNotificationToggleText(
          left: 114,
          top: 33,
          enabled: _enabledByUserId['joy'] ?? true,
          onTap: () => _toggleUser('joy'),
        ),
        _DmNotificationToggleText(
          left: 114,
          top: 63,
          enabled: _enabledByUserId['adi'] ?? true,
          onTap: () => _toggleUser('adi'),
        ),
        _DmNotificationToggleText(
          left: 114,
          top: 93,
          enabled: _enabledByUserId['danielle'] ?? true,
          onTap: () => _toggleUser('danielle'),
        ),
        _DmNotificationToggleText(
          left: 114,
          top: 123,
          enabled: _enabledByUserId['lian'] ?? true,
          onTap: () => _toggleUser('lian'),
        ),
        _DmNotificationToggleText(
          left: 114,
          top: 153,
          enabled: _enabledByUserId['tal'] ?? true,
          onTap: () => _toggleUser('tal'),
        ),
        _DmNotificationToggleText(
          left: 275,
          top: 33,
          enabled: _enabledByUserId['lera'] ?? true,
          onTap: () => _toggleUser('lera'),
        ),
        _DmNotificationToggleText(
          left: 275,
          top: 63,
          enabled: _enabledByUserId['lihi'] ?? true,
          onTap: () => _toggleUser('lihi'),
        ),
        _DmNotificationToggleText(
          left: 275,
          top: 93,
          enabled: _enabledByUserId['nella'] ?? true,
          onTap: () => _toggleUser('nella'),
        ),
      ],
    );
  }
}

class _DmNotificationToggleText extends StatelessWidget {
  final double left;
  final double top;
  final bool enabled;
  final VoidCallback onTap;

  const _DmNotificationToggleText({
    required this.left,
    required this.top,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String text = enabled ? 'On' : 'Off';

    final Color color = enabled
        ? const Color(0xFF9FFFF2)
        : const Color(0xFFD6D6D6);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 28,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              child: Text(
                text,
                key: ValueKey<String>(text),
                style: TextStyle(
                  color: color,
                  fontSize: 19,
                  fontWeight: FontWeight.w300,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.9),
                      offset: const Offset(1.3, 1.3),
                      blurRadius: 2,
                    ),
                    if (enabled)
                      Shadow(
                        color: const Color(0xFF9FFFF2).withOpacity(0.55),
                        blurRadius: 5,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}