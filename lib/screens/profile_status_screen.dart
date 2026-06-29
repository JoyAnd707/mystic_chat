import 'dart:async';
import 'dart:io';

import 'banner_adjust_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/mystic_top_status_bar.dart';
import '../widgets/mystic_star_twinkle.dart';
import '../widgets/mystic_screen_top_bar.dart';

class ProfileStatusScreen extends StatefulWidget {
  final String currentUserId;
  final String profileUserId;

  const ProfileStatusScreen({
    super.key,
    required this.currentUserId,
    required this.profileUserId,
  });

  @override
  State<ProfileStatusScreen> createState() => _ProfileStatusScreenState();
  
}

class _ProfileStatusScreenState extends State<ProfileStatusScreen>
    with TickerProviderStateMixin {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  late final AnimationController _twinkleController;

  final ImagePicker _imagePicker = ImagePicker();

  bool get _canEditProfile {
    return widget.currentUserId == widget.profileUserId;
  }

DocumentReference<Map<String, dynamic>> get _profileDoc {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(widget.profileUserId);
}
Future<void> _markStatusAsSeen() async {
  if (widget.currentUserId == widget.profileUserId) return;

  await _profileDoc.set({
    'statusSeenBy': {
      widget.currentUserId: true,
    },
  }, SetOptions(merge: true));
}
Future<void> _editStatusText(String currentStatusText) async {
  if (!_canEditProfile) return;

  final TextEditingController controller = TextEditingController(
    text: currentStatusText == 'Tap to set your status.' ? '' : currentStatusText,
  );

  final String? newStatusText = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF101020),
        title: const Text(
          'Edit Status',
          style: TextStyle(
            fontFamily: 'Roboto',
            color: Colors.white,
            fontWeight: FontWeight.w300,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLength: 80,
          maxLines: 3,
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: Colors.white,
            fontSize: 18,
          ),
          decoration: const InputDecoration(
            hintText: 'Write your status...',
            hintStyle: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white54,
            ),
            counterStyle: TextStyle(
              color: Colors.white54,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(null);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white70,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(controller.text.trim());
            },
            child: const Text(
              'Save',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    },
  );

WidgetsBinding.instance.addPostFrameCallback((_) {
  controller.dispose();
});

if (newStatusText == null) return;

await _profileDoc.set({
  'statusText': newStatusText.isEmpty
      ? 'Tap to set your status.'
      : newStatusText,
  'statusUpdatedAt': FieldValue.serverTimestamp(),
  'statusSeenBy': <String, bool>{},
}, SetOptions(merge: true));
}

Future<void> _pickAndUploadBanner() async {
    if (!_canEditProfile) return;

    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );

    if (picked == null) return;
    if (!mounted) return;

    final BannerAdjustResult? adjustResult =
        await Navigator.of(context).push<BannerAdjustResult>(
      MaterialPageRoute(
        builder: (_) => BannerAdjustScreen(
          imagePath: picked.path,
        ),
      ),
    );

    if (adjustResult == null) return;

    try {
      final File file = File(picked.path);

      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('profile_banners')
          .child(widget.profileUserId)
          .child('banner.jpg');

      await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final String downloadUrl = await ref.getDownloadURL();

      await _profileDoc.set({
        'bannerImageUrl': downloadUrl,
        'bannerScale': adjustResult.scale,
        'bannerOffsetX': adjustResult.offsetX,
        'bannerOffsetY': adjustResult.offsetY,
        'bannerUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update banner: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
  _markStatusAsSeen();
});

    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        setState(() {
          _now = DateTime.now();
        });
      },
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _twinkleController.dispose();
    super.dispose();
  }

  String get _displayName {
    switch (widget.profileUserId) {
      case 'joy':
        return 'Joy';
      case 'adi':
        return 'Adi★';
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
      default:
        return widget.profileUserId;
    }
  }

  Color get _userColor {
    switch (widget.profileUserId) {
      case 'joy':
        return const Color(0xFF8E63FF);
      case 'adi':
        return const Color(0xFFFF7EBB);
      case 'danielle':
        return const Color(0xFF62C7FF);
      case 'lera':
        return const Color(0xFFFFA24A);
      case 'lihi':
        return const Color(0xFFFFE066);
      case 'lian':
        return const Color(0xFFFF5C5C);
      case 'tal':
        return const Color(0xFF74D66B);
      case 'nella':
        return const Color(0xFF36D8C8);
      default:
        return const Color(0xFF9A9A9A);
    }
  }

  String get _profileAssetPath {
    switch (widget.profileUserId) {
      case 'joy':
        return 'assets/ui/status/JoyNoStatus.png';
      case 'adi':
        return 'assets/ui/status/AdiNoStatus.png';
      case 'danielle':
        return 'assets/ui/status/DanielleNoStatus.png';
      case 'lera':
        return 'assets/ui/status/LeraNoStatus.png';
      case 'lihi':
        return 'assets/ui/status/LihiNoStatus.png';
      case 'lian':
        return 'assets/ui/status/LianNoStatus.png';
      case 'tal':
        return 'assets/ui/status/TalNoStatus.png';
      case 'nella':
        return 'assets/ui/status/NellaNoStatus.png';
      default:
        return 'assets/ui/status/JoyNoStatus.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color userColor = _userColor;

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
            Positioned.fill(
              child: MysticStarTwinkleOverlay(
                animation: _twinkleController,
                starCount: 58,
                sizeMultiplier: 1.25,
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: MysticTopStatusBar(now: _now),
                ),
                const SizedBox(height: 6),
                MysticScreenTopBar(
                  title: 'Profile',
                  onBack: () {
                    Navigator.of(context).pop();
                  },
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: 385,
                        child: StreamBuilder<
                            DocumentSnapshot<Map<String, dynamic>>>(
                          stream: _profileDoc.snapshots(),
                          builder: (context, snapshot) {
                            final Map<String, dynamic>? data =
                                snapshot.data?.data();

                            final String bannerImageUrl =
                                (data?['bannerImageUrl'] ?? '').toString();
                                
                            final double bannerScale =
                                (data?['bannerScale'] as num?)?.toDouble() ??
                                    1.0;

                            final double bannerOffsetX =
                                (data?['bannerOffsetX'] as num?)?.toDouble() ??
                                    0.0;

                            final double bannerOffsetY =
                                (data?['bannerOffsetY'] as num?)?.toDouble() ??
                                    0.0;

                            return GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap:
                                  _canEditProfile ? _pickAndUploadBanner : null,
                              child: Container(
                                color: Colors.white,
                                child: bannerImageUrl.isEmpty
                                    ? Center(
                                        child: Text(
                                          _canEditProfile
                                              ? 'Tap to add banner'
                                              : 'No banner yet',
                                          style: const TextStyle(
                                            fontFamily: 'Roboto',
                                            color: Colors.black54,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      )
                                    : ClipRect(
                                        child: Transform.translate(
                                          offset: Offset(
                                            bannerOffsetX,
                                            bannerOffsetY,
                                          ),
                                          child: Transform.scale(
                                            scale: bannerScale,
                               child: CachedNetworkImage(
  imageUrl: bannerImageUrl,
  fit: BoxFit.cover,
  width: double.infinity,
  height: double.infinity,
  filterQuality: FilterQuality.high,
  fadeInDuration: const Duration(milliseconds: 180),
  fadeOutDuration: const Duration(milliseconds: 80),
  placeholder: (context, url) {
    return Container(
      color: userColor.withOpacity(0.22),
      child: const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
      ),
    );
  },
  errorWidget: (context, url, error) {
    return const Center(
      child: Text(
        'Banner',
        style: TextStyle(
          fontFamily: 'Roboto',
          color: Colors.black54,
          fontSize: 30,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  },
),
                                          ),
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 382,
                        bottom: 0,
                        child: Container(
                          color: userColor.withOpacity(0.38),
                        ),
                      ),
                      Positioned(
                        left: 26,
                        top: 300,
                        child: Container(
                          width: 145,
                          height: 145,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: userColor,
                              width: 3,
                            ),
                          ),
                          child: Image.asset(
                            _profileAssetPath,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 195,
                        right: 20,
                        top: 385,
                        child: Text(
                          _displayName,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.white,
                            fontSize: 31,
                            fontWeight: FontWeight.w300,
                            height: 1.0,
                          ),
                        ),
                      ),
   Positioned(
  left: 38,
  right: 38,
  top: 530,
  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: _profileDoc.snapshots(),
    builder: (context, snapshot) {
      final data = snapshot.data?.data();

      final String statusText =
          (data?['statusText'] ?? 'Tap to set your status.').toString();

      return GestureDetector(
   onTap: _canEditProfile
    ? () => _editStatusText(statusText)
    : null,
        child: Text(
          statusText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: Colors.white,
            fontSize: 24,
            height: 1.25,
            fontWeight: FontWeight.w300,
          ),
        ),
      );
    },
  ),
),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}