import 'package:flutter/material.dart';

import '../widgets/mystic_star_twinkle.dart';
import '../widgets/mystic_top_status_bar.dart';
import 'gallery_screen.dart';

class GuestArchiveScreen extends StatefulWidget {
  const GuestArchiveScreen({super.key});

  @override
  State<GuestArchiveScreen> createState() => _GuestArchiveScreenState();
}

class _GuestArchiveScreenState extends State<GuestArchiveScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _twinkleController;

static const List<String> guestImages = [
  'assets/ui/guest_archive/Atsushi.png',
  'assets/ui/guest_archive/Ruki.png',
  'assets/ui/guest_archive/707.png',
   'assets/ui/guest_archive/Ace.png',
  'assets/ui/guest_archive/Ada.png',
  'assets/ui/guest_archive/Adachi.png',
   'assets/ui/guest_archive/Aoi.png',
  'assets/ui/guest_archive/Chris.png',
  'assets/ui/guest_archive/Edge.png',
   'assets/ui/guest_archive/Hannibal.png',
  'assets/ui/guest_archive/Issei.png',
  'assets/ui/guest_archive/Jake.png',
   'assets/ui/guest_archive/Jiro.png',
  'assets/ui/guest_archive/Joseph.png',
  'assets/ui/guest_archive/Josuke.png',
   'assets/ui/guest_archive/Kai.png',
  'assets/ui/guest_archive/Kazuma.png',
  'assets/ui/guest_archive/Kenji.png',
   'assets/ui/guest_archive/Kurosawa.png',
  'assets/ui/guest_archive/Leon.png',
   'assets/ui/guest_archive/Luffy.png',
  'assets/ui/guest_archive/Mista.png',
  'assets/ui/guest_archive/Narancia.png',
   'assets/ui/guest_archive/Nir.png',
  'assets/ui/guest_archive/Phoenix.png',
  'assets/ui/guest_archive/Reita.png',
   'assets/ui/guest_archive/Sanji.png',
  'assets/ui/guest_archive/Sho.png',
  'assets/ui/guest_archive/Uruha.png',
   'assets/ui/guest_archive/Vasco.png',
  'assets/ui/guest_archive/Yutaka.png',
  'assets/ui/guest_archive/Zack.png',
   'assets/ui/guest_archive/ZackFair.png',
  'assets/ui/guest_archive/Zoro.png',
  
];

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
    const int maxGuests = 40;

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
                const GalleryTopBar(title: 'Guest'),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: maxGuests,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      if (index >= guestImages.length) {
                        return const EmptyGalleryPhotoTile();
                      }

                      final imageAsset = guestImages[index];

                      return Stack(
                        children: [
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Image.asset(
                                imageAsset,
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