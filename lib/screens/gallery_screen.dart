
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../audio/sfx.dart';
import '../widgets/fullscreen_image_viewer.dart';
import '../widgets/mystic_top_status_bar.dart';
import '../widgets/mystic_star_twinkle.dart';
class GalleryScreen extends StatefulWidget {
  final String currentUserId;

  const GalleryScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _twinkleController;

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

  @override
  Widget build(BuildContext context) {
    const albums = [
      ['Joy', 'joy'],
      ['Adi★', 'adi'],
      ['Danielle', 'danielle'],
      ['Lera', 'lera'],
      ['Lihi', 'lihi'],
      ['Lian', 'lian'],
      ['Tal', 'tal'],
      ['Nella', 'nella'],
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
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
          SafeArea(
            child: Column(
              children: [
                MysticTopStatusBar(now: DateTime.now()),
                const GalleryTopBar(),
                const SizedBox(height: 12),
Expanded(
  child: SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          for (int i = 0; i < albums.length; i += 2) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GalleryAlbumTile(
                  title: albums[i][0],
                  userId: albums[i][1],
                ),
                GalleryAlbumTile(
                  title: albums[i + 1][0],
                  userId: albums[i + 1][1],
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    ),
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

class GalleryAlbumTile extends StatelessWidget {
  final String title;
  final String userId;

  const GalleryAlbumTile({
    super.key,
    required this.title,
    required this.userId,
  });

  Color _nameplateColor() {
    switch (userId) {
      case 'joy':
        return const Color.fromARGB(170, 167, 123, 255);

      case 'adi':
        return const Color.fromARGB(170, 255, 127, 223);

      case 'danielle':
        return const Color.fromARGB(170, 106, 146, 255);

      case 'lera':
        return const Color.fromARGB(170, 255, 169, 41);

      case 'lihi':
        return const Color.fromARGB(170, 255, 232, 79);

      case 'nella':
        return const Color.fromARGB(170, 38, 218, 212);

      case 'lian':
        return const Color.fromARGB(170, 241, 78, 75);

      case 'tal':
        return const Color(0xAA66BB6A);

      default:
        return const Color.fromARGB(84, 255, 255, 255);
    }
  }

  String _galleryImage() {
    switch (userId) {
      case 'joy':
        return 'assets/ui/gallery/JoyGalleryImage.png';

      case 'adi':
        return 'assets/ui/gallery/AdiGalleryImage.png';

      case 'danielle':
        return 'assets/ui/gallery/DanielleGalleryImage.png';

      case 'lera':
        return 'assets/ui/gallery/LeraGalleryImage.png';

      case 'lihi':
        return 'assets/ui/gallery/LihiGalleryImage.png';

      case 'lian':
        return 'assets/ui/gallery/LianGalleryImage.png';

      case 'tal':
        return 'assets/ui/gallery/TalGalleryImage.png';

      case 'nella':
        return 'assets/ui/gallery/NellaGalleryImage.png';

      default:
        return 'assets/ui/gallery/PhotoAlbumFrames.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final countQuery = FirebaseFirestore.instance
        .collection('rooms')
        .doc('group_main')
        .collection('messages')
        .where('senderId', isEqualTo: userId)
        .where('type', isEqualTo: 'image');

    return SizedBox(
      width: 135,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Sfx.I.playGoIntoGallery();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserGalleryScreen(
                userId: userId,
                title: title,
              ),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              _galleryImage(),
              width: 97,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(height: 6),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: countQuery.snapshots(),
              builder: (context, snapshot) {
                final int count = snapshot.data?.docs.length ?? 0;

                return SizedBox(
                  width: 132,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/ui/gallery/GalleryNameplateBase.png',
                        width: 138,
                        fit: BoxFit.contain,
                        color: _nameplateColor(),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                      Text(
                        '$title ($count)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1,
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
    );
  }
}

class UserGalleryScreen extends StatefulWidget {
  final String userId;
  final String title;

  const UserGalleryScreen({
    super.key,
    required this.userId,
    required this.title,
  });

  @override
  State<UserGalleryScreen> createState() => _UserGalleryScreenState();
}

class _UserGalleryScreenState extends State<UserGalleryScreen>
    with SingleTickerProviderStateMixin {
  static const int maxPhotos = 100;

  late final AnimationController _twinkleController;

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

  @override
  Widget build(BuildContext context) {
    final photosQuery = FirebaseFirestore.instance
        .collection('rooms')
        .doc('group_main')
        .collection('messages')
        .where('senderId', isEqualTo: widget.userId)
        .where('type', isEqualTo: 'image')
        .orderBy('ts', descending: true)
        .limit(maxPhotos);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
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
          SafeArea(
            child: Column(
              children: [
                MysticTopStatusBar(now: DateTime.now()),
                GalleryTopBar(title: widget.title),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: photosQuery.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: maxPhotos,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          if (index >= docs.length) {
                            return const EmptyGalleryPhotoTile();
                          }

                          final data = docs[index].data();
                          final imageUrl = data['imageUrl'] as String? ?? '';

                          if (imageUrl.isEmpty) {
                            return const EmptyGalleryPhotoTile();
                          }

                          return GalleryPhotoTile(imageUrl: imageUrl);
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

class GalleryPhotoTile extends StatelessWidget {
  final String imageUrl;

  const GalleryPhotoTile({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Sfx.I.playGoIntoPhoto();
        openFullscreenImageViewer(context, imageUrl);
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          Positioned.fill(
            child: Image.asset(
              'assets/ui/gallery/EmptyPhotoFrame.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyGalleryPhotoTile extends StatelessWidget {
  const EmptyGalleryPhotoTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/ui/gallery/EmptyPhoto.png',
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
    );
  }
}

class GalleryTopBar extends StatelessWidget {
  final String title;

  const GalleryTopBar({
    super.key,
    this.title = 'Photo Album',
  });

  static const double _resourceBarHeight = 34;
  static const double _barAspect = 2048 / 212;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                        'assets/ui/gallery/TextMessageBarMenu.png',
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.center,
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w300,
                          height: 1.0,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Sfx.I.playBack();
                          Navigator.pop(context);
                        },
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