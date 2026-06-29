import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MainMenuStatusRow extends StatelessWidget {
  final String currentUserId;
  final void Function(String userId) onStatusTap;

  const MainMenuStatusRow({
    super.key,
    required this.currentUserId,
    required this.onStatusTap,
  });

  static const List<_StatusUserData> _users = [
    _StatusUserData(
      userId: 'joy',
      noStatusAssetPath: 'assets/ui/status/JoyNoStatus.png',
      newStatusAssetPath: 'assets/ui/status/JoyNewStatus.png',
    ),
    _StatusUserData(
      userId: 'adi',
      noStatusAssetPath: 'assets/ui/status/AdiNoStatus.png',
      newStatusAssetPath: 'assets/ui/status/AdiNewStatus.png',
    ),
    _StatusUserData(
      userId: 'danielle',
      noStatusAssetPath: 'assets/ui/status/DanielleNoStatus.png',
      newStatusAssetPath: 'assets/ui/status/DanielleNewStatus.png',
    ),
    _StatusUserData(
      userId: 'lera',
      noStatusAssetPath: 'assets/ui/status/LeraNoStatus.png',
      newStatusAssetPath: 'assets/ui/status/LeraNewStatus.png',
    ),
    _StatusUserData(
      userId: 'lihi',
      noStatusAssetPath: 'assets/ui/status/LihiNoStatus.png',
      newStatusAssetPath: 'assets/ui/status/LihiNewStatus.png',
    ),
    _StatusUserData(
      userId: 'lian',
      noStatusAssetPath: 'assets/ui/status/LianNoStatus.png',
      newStatusAssetPath: 'assets/ui/status/LianNewStatus.png',
    ),
    _StatusUserData(
      userId: 'tal',
      noStatusAssetPath: 'assets/ui/status/TalNoStatus.png',
      newStatusAssetPath: 'assets/ui/status/TalNewStatus.png',
    ),
    _StatusUserData(
      userId: 'nella',
      noStatusAssetPath: 'assets/ui/status/NellaNoStatus.png',
      newStatusAssetPath: 'assets/ui/status/NellaNewStatus.png',
    ),
  ];
int _timestampToMs(dynamic value) {
  if (value is Timestamp) {
    return value.millisecondsSinceEpoch;
  }

  if (value is int) {
    return value;
  }

  return 0;
}

int _latestProfileUpdateMs(Map<String, dynamic>? data) {
  if (data == null) return 0;

  final int statusUpdatedAtMs = _timestampToMs(data['statusUpdatedAt']);
  final int profileImageUpdatedAtMs =
      _timestampToMs(data['profileImageUpdatedAt']);
  final int bannerUpdatedAtMs = _timestampToMs(data['bannerUpdatedAt']);

  return [
    statusUpdatedAtMs,
    profileImageUpdatedAtMs,
    bannerUpdatedAtMs,
  ].reduce((a, b) => a > b ? a : b);
}

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          final Map<String, Map<String, dynamic>> usersData = {};

          if (snapshot.hasData) {
            for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
                in snapshot.data!.docs) {
              usersData[doc.id] = doc.data();
            }
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _users.map((user) {
              final Map<String, dynamic>? data = usersData[user.userId];
final Map<String, dynamic> statusSeenBy =
    (data?['statusSeenBy'] is Map<String, dynamic>)
        ? data!['statusSeenBy'] as Map<String, dynamic>
        : <String, dynamic>{};

final bool isOwnStatus = user.userId == currentUserId;

final bool currentUserAlreadySawStatus =
    statusSeenBy[currentUserId] == true;

final int latestProfileUpdateMs = _latestProfileUpdateMs(data);

final bool hasProfileUpdate = latestProfileUpdateMs > 0;

final bool shouldShowNewStatus =
    hasProfileUpdate && !isOwnStatus && !currentUserAlreadySawStatus;

final String assetPath = shouldShowNewStatus
    ? user.newStatusAssetPath
    : user.noStatusAssetPath;

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  onStatusTap(user.userId);
                },
                child: Image.asset(
                  assetPath,
                  width: 43,
                  height: 43,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _StatusUserData {
  final String userId;
  final String noStatusAssetPath;
  final String newStatusAssetPath;

  const _StatusUserData({
    required this.userId,
    required this.noStatusAssetPath,
    required this.newStatusAssetPath,
  });
}