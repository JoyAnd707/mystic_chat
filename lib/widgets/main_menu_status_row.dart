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
    _StatusUserData(userId: 'joy', assetPath: 'assets/ui/status/JoyNoStatus.png'),
    _StatusUserData(userId: 'adi', assetPath: 'assets/ui/status/AdiNoStatus.png'),
    _StatusUserData(userId: 'danielle', assetPath: 'assets/ui/status/DanielleNoStatus.png'),
    _StatusUserData(userId: 'lera', assetPath: 'assets/ui/status/LeraNoStatus.png'),
    _StatusUserData(userId: 'lihi', assetPath: 'assets/ui/status/LihiNoStatus.png'),
    _StatusUserData(userId: 'lian', assetPath: 'assets/ui/status/LianNoStatus.png'),
    _StatusUserData(userId: 'tal', assetPath: 'assets/ui/status/TalNoStatus.png'),
    _StatusUserData(userId: 'nella', assetPath: 'assets/ui/status/NellaNoStatus.png'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _users.map((user) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              onStatusTap(user.userId);
            },
            child: Image.asset(
              user.assetPath,
              width: 43,
              height: 43,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatusUserData {
  final String userId;
  final String assetPath;

  const _StatusUserData({
    required this.userId,
    required this.assetPath,
  });
}