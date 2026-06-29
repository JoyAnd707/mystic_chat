import 'package:flutter/material.dart';
import '../screens/settings_menu.dart';
class MysticTopStatusBar extends StatelessWidget {
  final DateTime now;
  final String currentUserId;

  const MysticTopStatusBar({
    super.key,
    required this.now,
    this.currentUserId = '',
  });

  String _timeText(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute$ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 45,
              child: Image.asset(
                'assets/ui/TopBar.png',
                fit: BoxFit.fitWidth,
              ),
            ),
            Positioned(
              left: 6,
              top:6,
              child: Text(
                _timeText(now),
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 17,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  height: 1,
                ),
              ),
            ),
            Positioned(
  right: 0,
  top: 0,
  child: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
builder: (_) => SettingsMenuScreen(
  currentUserId: currentUserId,
),
        ),
      );
    },
    child: const SizedBox(
      width: 72,
      height: 64,
    ),
  ),
),
          ],
        ),
      ),
    );
  }
}