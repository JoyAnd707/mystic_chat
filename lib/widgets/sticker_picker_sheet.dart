import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

void showMysticStickerPickerSheet({
  required BuildContext context,
  required String currentUserId,
  required CreateStickerCallback onCreateSticker,
  required SendArchivedStickerCallback onSendArchivedSticker,
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
      );
    },
  );
}

class _MysticStickerPickerSheet extends StatefulWidget {
  final String currentUserId;
  final CreateStickerCallback onCreateSticker;
  final SendArchivedStickerCallback onSendArchivedSticker;

  const _MysticStickerPickerSheet({
    required this.currentUserId,
    required this.onCreateSticker,
    required this.onSendArchivedSticker,
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
                                        style: TextStyle(color: Colors.white70),
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

                                await FirestoreChatService.deleteArchivedSticker(
                                  userId: widget.currentUserId,
                                  stickerId: stickerId,
                                  storagePath: storagePath,
                                );

                                if (!mounted) return;
                                setState(() {});
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