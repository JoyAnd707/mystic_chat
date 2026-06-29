import 'package:flutter/material.dart';

class GalleryScreen extends StatelessWidget {
  final String currentUserId;

  const GalleryScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final albums = [
      'Joy',
      'Adi',
      'Danielle',
      'Lera',
      'Lihi',
      'Lian',
      'Tal',
      'Nella',
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
          itemCount: albums.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 28,
            crossAxisSpacing: 28,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            return Column(
              children: [
                Image.asset(
                  'assets/ui/gallery/PhotoAlbumFrames.png',
                  width: 140,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                Text(
                  '${albums[index]} (0)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}