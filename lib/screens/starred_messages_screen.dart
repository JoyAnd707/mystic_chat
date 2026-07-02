import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/sfx.dart';
import '../widgets/mystic_top_status_bar.dart';

class StarredMessagesScreen extends StatefulWidget {
  final String currentUserId;

  const StarredMessagesScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<StarredMessagesScreen> createState() => _StarredMessagesScreenState();
}

class _StarredMessagesScreenState extends State<StarredMessagesScreen> {
  bool _showGroup = true;

  String _senderName(String senderId) {
    switch (senderId) {
      case 'joy':
        return 'Joy';
      case 'adi':
        return 'Adi';
      case 'danielle':
        return 'Danielle';
      case 'lera':
        return 'Lera';
      case 'lihi':
        return 'Lihi';
      case 'lian':
        return 'Lian';
      case 'tal':
        return 'Tal';
      case 'nella':
        return 'Nella';
      case 'gackto_facto':
        return 'Gackt';
      default:
        return senderId;
    }
  }

  String _previewForMessage(Map<String, dynamic> data) {
    final type = (data['type'] ?? 'text').toString();
    final text = (data['text'] ?? '').toString().trim();

    if (type == 'image') return '📷 Photo';
    if (type == 'video') return '🎥 Video';
    if (type == 'voice') return '🎙️ Voice message';
    if (type == 'sticker') return '🙂 Sticker';
    if (type == 'animatedEmoji') return '✨ Animated emoji';

    if (text.isEmpty) return '(empty message)';
    return text;
  }

  String _dateLabel(int ts) {
    if (ts <= 0) return '';

    final dt = DateTime.fromMillisecondsSinceEpoch(ts);

    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(dt.day)}/${two(dt.month)}/${dt.year}  ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _otherUserFromDmRoomId(String roomId) {
    if (!roomId.startsWith('dm_')) return '';

    final raw = roomId.substring(3);
    final parts = raw.split('_');

    if (parts.length < 2) return '';

    final a = parts[0];
    final b = parts[1];

    if (a == widget.currentUserId) return b;
    if (b == widget.currentUserId) return a;

    return '';
  }

  bool _isMyDmRoom(String roomId) {
    if (!roomId.startsWith('dm_')) return false;

    final raw = roomId.substring(3);
    final parts = raw.split('_');

    return parts.contains(widget.currentUserId);
  }

  Widget _tabButton({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF46F5D6).withOpacity(0.18)
                : Colors.white.withOpacity(0.05),
            border: Border.all(
              color: selected
                  ? const Color(0xFF46F5D6).withOpacity(0.85)
                  : Colors.white.withOpacity(0.16),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: selected ? const Color(0xFF46F5D6) : Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStarredMessageMenu({
    required BuildContext context,
    required DocumentReference<Map<String, dynamic>> ref,
    required String preview,
  }) async {
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
                  'Starred Message',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(
                    Icons.star_border_rounded,
                    color: Color(0xFFFFD95A),
                  ),
                  title: const Text(
                    'Remove Star',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, 'remove_star');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.copy_rounded,
                    color: Color(0xFF46F5D6),
                  ),
                  title: const Text(
                    'Copy Message',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, 'copy');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                  ),
                  title: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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

    if (action == 'copy') {
      final textToCopy = preview.trim();

      if (textToCopy.isNotEmpty) {
        await Clipboard.setData(
          ClipboardData(text: textToCopy),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message copied'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      return;
    }

    if (action != 'remove_star') return;

    await ref.update({
      'starredBy': FieldValue.arrayRemove([widget.currentUserId]),
    });
  }

  Widget _starredTile({
    required BuildContext context,
    required DocumentReference<Map<String, dynamic>> ref,
    required Map<String, dynamic> data,
    required String title,
    required String subtitle,
    required int ts,
  }) {
    final preview = _previewForMessage(data);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () async {
        await _openStarredMessageMenu(
          context: context,
          ref: ref,
          preview: preview,
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF061522).withOpacity(0.88),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF46F5D6).withOpacity(0.28),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFD95A),
                  size: 19,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF46F5D6),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  _dateLabel(ts),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.52),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (subtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.52),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              preview,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.25,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupStarredList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc('group_main')
          .collection('messages')
          .where('starredBy', arrayContains: widget.currentUserId)
          .orderBy('ts', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Could not load group starred messages:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF46F5D6),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No starred group messages yet.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final senderId = (data['senderId'] ?? '').toString();
            final ts = (data['ts'] is int) ? data['ts'] as int : 0;

            return _starredTile(
              context: context,
              ref: doc.reference,
              data: data,
              title: _senderName(senderId),
              subtitle: 'Group Chat',
              ts: ts,
            );
          },
        );
      },
    );
  }

  Widget _dmStarredList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('messages')
          .where('starredBy', arrayContains: widget.currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Could not load DM starred messages:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF46F5D6),
            ),
          );
        }

        final docs = snapshot.data!.docs.where((doc) {
          final parentCollection = doc.reference.parent.parent?.parent.id ?? '';
          final roomId = doc.reference.parent.parent?.id ?? '';

          return parentCollection == 'dm_rooms' && _isMyDmRoom(roomId);
        }).toList();

        docs.sort((a, b) {
          final ad = a.data();
          final bd = b.data();

          final ats = (ad['tsMs'] is int) ? ad['tsMs'] as int : 0;
          final bts = (bd['tsMs'] is int) ? bd['tsMs'] as int : 0;

          return bts.compareTo(ats);
        });

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No starred DM messages yet.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final senderId = (data['senderId'] ?? '').toString();
            final ts = (data['tsMs'] is int) ? data['tsMs'] as int : 0;
            final roomId = doc.reference.parent.parent?.id ?? '';
            final otherUserId = _otherUserFromDmRoomId(roomId);

            return _starredTile(
              context: context,
              ref: doc.reference,
              data: data,
              title: _senderName(senderId),
              subtitle: otherUserId.isEmpty
                  ? 'Direct Message'
                  : 'DM with ${_senderName(otherUserId)}',
              ts: ts,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/backgrounds/StarsBG.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  MysticTopStatusBar(now: now),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 56,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              try {
                                Sfx.I.playBack();
                              } catch (_) {}

                              Navigator.of(context).pop();
                            },
                            child: const SizedBox(
                              width: 52,
                              height: 52,
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        const Center(
                          child: Text(
                            'Starred Messages',
                            style: TextStyle(
                              color: Color(0xFF46F5D6),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _tabButton(
                        text: 'Group',
                        selected: _showGroup,
                        onTap: () {
                          setState(() {
                            _showGroup = true;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _tabButton(
                        text: 'DMs',
                        selected: !_showGroup,
                        onTap: () {
                          setState(() {
                            _showGroup = false;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _showGroup ? _groupStarredList() : _dmStarredList(),
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