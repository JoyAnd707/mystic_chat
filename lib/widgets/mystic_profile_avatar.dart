import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MysticProfileAvatar extends StatelessWidget {
  final String userId;
  final double size;
  final BoxFit fit;

  const MysticProfileAvatar({
    super.key,
    required this.userId,
    this.size = 42,
    this.fit = BoxFit.cover,
  });

  String get _fallbackAssetPath {
    switch (userId) {
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
      case 'gackto_facto':
        return 'assets/avatars/gackto_facto.png';
      default:
        return 'assets/ui/status/JoyNoStatus.png';
    }
  }

@override
Widget build(BuildContext context) {
  return SizedBox(
    width: size,
    height: size,
    child: ClipRect(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              width: size,
              height: size,
              color: Colors.black,
            );
          }

          final data = snapshot.data?.data();

          final String profileImageUrl =
              (data?['profileImageUrl'] ?? '').toString();

          if (profileImageUrl.isEmpty) {
            return Image.asset(
              _fallbackAssetPath,
              fit: fit,
              filterQuality: FilterQuality.high,
            );
          }

          return CachedNetworkImage(
            imageUrl: profileImageUrl,
            fit: fit,
            width: size,
            height: size,
            filterQuality: FilterQuality.high,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (context, url) {
              return Container(
                width: size,
                height: size,
                color: Colors.black,
              );
            },
            errorWidget: (context, url, error) {
              return Image.asset(
                _fallbackAssetPath,
                fit: fit,
                filterQuality: FilterQuality.high,
              );
            },
          );
        },
      ),
    ),
  );
}
}