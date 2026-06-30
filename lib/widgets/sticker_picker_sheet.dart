import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/animated_emojis.dart';
import '../firebase/firestore_chat_service.dart';

typedef CreateStickerCallback = Future<void> Function(
  String localFilePath,
  int ts,
);

typedef SendArchivedStickerCallback = Future<void> Function(
  String stickerUrl,
  String storagePath,
  int ts,
);

typedef SendAnimatedEmojiCallback = Future<void> Function(
  MysticAnimatedEmoji emoji,
  int ts,
);

void showMysticStickerPickerSheet({
  required BuildContext context,
  required String currentUserId,
  required CreateStickerCallback onCreateSticker,
  required SendArchivedStickerCallback onSendArchivedSticker,
  SendAnimatedEmojiCallback? onSendAnimatedEmoji,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black.withOpacity(0.92),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (sheetContext) {
return _MysticStickerPickerSheet(
  currentUserId: currentUserId,
  onCreateSticker: onCreateSticker,
  onSendArchivedSticker: onSendArchivedSticker,
  onSendAnimatedEmoji: onSendAnimatedEmoji,
);
    },
  );
}

class _MysticStickerPickerSheet extends StatefulWidget {
  final String currentUserId;
  final CreateStickerCallback onCreateSticker;
  final SendArchivedStickerCallback onSendArchivedSticker;
final SendAnimatedEmojiCallback? onSendAnimatedEmoji;
const _MysticStickerPickerSheet({
  required this.currentUserId,
  required this.onCreateSticker,
  required this.onSendArchivedSticker,
  this.onSendAnimatedEmoji,
});

  @override
  State<_MysticStickerPickerSheet> createState() =>
      _MysticStickerPickerSheetState();
}

class _MysticStickerPickerSheetState extends State<_MysticStickerPickerSheet> {
  final ImagePicker _picker = ImagePicker();

  Future<List<Map<String, dynamic>>> _load() {
    return FirestoreChatService.loadStickerArchive(
      userId: widget.currentUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<MysticAnimatedEmoji> myAnimatedEmojis =
        animatedEmojisForUser(widget.currentUserId);

    return SafeArea(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _load(),
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

                if (myAnimatedEmojis.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'My Animated Emojis',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 105,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: myAnimatedEmojis.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final MysticAnimatedEmoji emoji =
                            myAnimatedEmojis[index];

         return _AnimatedEmojiTestTile(
  emoji: emoji,
  onTap: widget.onSendAnimatedEmoji == null
      ? null
      : () async {
          final int ts = DateTime.now().millisecondsSinceEpoch;

          Navigator.pop(context);

          await widget.onSendAnimatedEmoji!(
            emoji,
            ts,
          );
        },
);
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Saved Stickers',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

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
                              return _CreateStickerTile(
                                onTap: () async {
                                  final XFile? picked =
                                      await _picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 70,
                                  );

                                  if (picked == null) return;

                                  final int ts =
                                      DateTime.now().millisecondsSinceEpoch;

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }

                                  await widget.onCreateSticker(
                                    picked.path,
                                    ts,
                                  );
                                },
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
                                final int ts =
                                    DateTime.now().millisecondsSinceEpoch;

                                Navigator.pop(context);

                                await widget.onSendArchivedSticker(
                                  stickerUrl,
                                  storagePath,
                                  ts,
                                );
                              },
    onLongPress: () async {
  if (stickerId.isEmpty) return;

  final bool isFavorite = sticker['isFavorite'] == true;

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
                'Sticker Options',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _StickerOptionTile(
                icon: isFavorite
                    ? Icons.star_outline_rounded
                    : Icons.star_rounded,
                title: isFavorite
                    ? 'Remove from Favorites'
                    : 'Add to Favorites',
                color: const Color(0xFF46F5D6),
                onTap: () {
                  Navigator.pop(
                    sheetContext,
                    isFavorite ? 'unfavorite' : 'favorite',
                  );
                },
              ),
              const SizedBox(height: 8),
              _StickerOptionTile(
                icon: Icons.delete_outline_rounded,
                title: 'Delete from Archive',
                color: const Color(0xFFFF6B7A),
                onTap: () {
                  Navigator.pop(sheetContext, 'delete');
                },
              ),
              const SizedBox(height: 8),
              _StickerOptionTile(
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

  if (action == null || action == 'cancel') return;

  if (action == 'favorite' || action == 'unfavorite') {
    await FirestoreChatService.setArchivedStickerFavorite(
      userId: widget.currentUserId,
      stickerId: stickerId,
      isFavorite: action == 'favorite',
    );

    if (!mounted) return;
    setState(() {});
    return;
  }

  if (action == 'delete') {
    final bool? shouldDelete = await showDialog<bool>(
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
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await FirestoreChatService.deleteArchivedSticker(
      userId: widget.currentUserId,
      stickerId: stickerId,
      storagePath: storagePath,
    );

    if (!mounted) return;
    setState(() {});
  }
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
  }
}

class _AnimatedEmojiTestTile extends StatefulWidget {
  final MysticAnimatedEmoji emoji;
  final VoidCallback? onTap;

  const _AnimatedEmojiTestTile({
    required this.emoji,
    this.onTap,
  });

  @override
  State<_AnimatedEmojiTestTile> createState() => _AnimatedEmojiTestTileState();
}

class _AnimatedEmojiTestTileState extends State<_AnimatedEmojiTestTile> {
  bool _showFirstFrame = true;

  @override
  void initState() {
    super.initState();

    Future.doWhile(() async {
      await Future.delayed(
  _showFirstFrame
      ? const Duration(milliseconds: 400)
      : const Duration(milliseconds: 1000),
);

      if (!mounted) return false;

      setState(() {
        _showFirstFrame = !_showFirstFrame;
      });

      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String assetPath = _showFirstFrame
        ? widget.emoji.frame1Asset
        : widget.emoji.frame2Asset;

    return GestureDetector(
  onTap: widget.onTap,
  child: Container(
      width: 92,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF46F5D6).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF46F5D6).withOpacity(0.45),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return Center(
                  child: Text(
                    widget.emoji.ownerUserId.characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF46F5D6),
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.emoji.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      
    )
    );
    
  }
}

class _CreateStickerTile extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateStickerTile({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                color: Colors.white.withOpacity(0.75),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _StickerOptionTile extends StatelessWidget {
  const _StickerOptionTile({
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