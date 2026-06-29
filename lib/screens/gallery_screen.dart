import 'package:flutter/material.dart';

import '../widgets/mystic_top_status_bar.dart';

class GalleryScreen extends StatelessWidget {
  final String currentUserId;

  const GalleryScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    const albums = [
      ['Joy', 'Adi'],
      ['Danielle', 'Lera'],
      ['Lihi', 'Lian'],
      ['Tal', 'Nella'],
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            MysticTopStatusBar(
              now: DateTime.now(),
            ),
const GalleryTopBar(),


            const SizedBox(height: 18),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    for (final row in albums) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GalleryAlbumTile(title: row[0]),
                          GalleryAlbumTile(title: row[1]),
                        ],
                      ),
                      const SizedBox(height: 22),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GalleryAlbumTile extends StatelessWidget {
  final String title;

  const GalleryAlbumTile({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 135,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/ui/gallery/PhotoAlbumFrames.png',
            width: 105,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 6),
          Text(
            '$title (0)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class GalleryTopBar extends StatelessWidget {
  const GalleryTopBar({super.key});

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

                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Photo Album',
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