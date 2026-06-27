class MysticAnimatedEmoji {
  final String id;
  final String ownerUserId;
  final String label;
  final String frame1Asset;
  final String frame2Asset;
  final bool canBeSaved;

  const MysticAnimatedEmoji({
    required this.id,
    required this.ownerUserId,
    required this.label,
    required this.frame1Asset,
    required this.frame2Asset,
    this.canBeSaved = false,
  });
}

const List<MysticAnimatedEmoji> mysticAnimatedEmojis = [
  MysticAnimatedEmoji(
    id: 'joy_test_happy',
    ownerUserId: 'joy',
    label: 'Joy Happy',
    frame1Asset: 'assets/animated_emojis/joy/test_happy_1.png',
    frame2Asset: 'assets/animated_emojis/joy/test_happy_2.png',
  ),
  MysticAnimatedEmoji(
    id: 'joy_test_angry',
    ownerUserId: 'joy',
    label: 'Joy Angry',
    frame1Asset: 'assets/animated_emojis/joy/test_angry_1.png',
    frame2Asset: 'assets/animated_emojis/joy/test_angry_2.png',
  ),
  MysticAnimatedEmoji(
    id: 'adi_test_laugh',
    ownerUserId: 'adi',
    label: 'Adi Laugh',
    frame1Asset: 'assets/animated_emojis/adi/test_laugh_1.png',
    frame2Asset: 'assets/animated_emojis/adi/test_laugh_2.png',
  ),
];

List<MysticAnimatedEmoji> animatedEmojisForUser(String currentUserId) {
  return mysticAnimatedEmojis
      .where((emoji) => emoji.ownerUserId == currentUserId)
      .toList();
}

MysticAnimatedEmoji? animatedEmojiById(String id) {
  for (final emoji in mysticAnimatedEmojis) {
    if (emoji.id == id) return emoji;
  }

  return null;
}