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
  // Joy
  MysticAnimatedEmoji(
    id: 'joy_happy',
    ownerUserId: 'joy',
    label: 'Joy Happy',
    frame1Asset: 'assets/animated_emojis/joy/joy_happy_1.png',
    frame2Asset: 'assets/animated_emojis/joy/joy_happy_2.png',
  ),
  MysticAnimatedEmoji(
    id: 'joy_sad',
    ownerUserId: 'joy',
    label: 'Joy Sad',
    frame1Asset: 'assets/animated_emojis/joy/joy_sad_1.png',
    frame2Asset: 'assets/animated_emojis/joy/joy_sad_2.png',
  ),
  MysticAnimatedEmoji(
    id: 'joy_angry',
    ownerUserId: 'joy',
    label: 'Joy Angry',
    frame1Asset: 'assets/animated_emojis/joy/joy_angry_1.png',
    frame2Asset: 'assets/animated_emojis/joy/joy_angry_2.png',
  ),

  // Adi
  MysticAnimatedEmoji(
    id: 'adi_happy',
    ownerUserId: 'adi',
    label: 'Adi Happy',
    frame1Asset: 'assets/animated_emojis/adi/adi_happy_1.png',
    frame2Asset: 'assets/animated_emojis/adi/adi_happy_2.png',
  ),
  MysticAnimatedEmoji(
    id: 'adi_sad',
    ownerUserId: 'adi',
    label: 'Adi Sad',
    frame1Asset: 'assets/animated_emojis/adi/adi_sad_1.png',
    frame2Asset: 'assets/animated_emojis/adi/adi_sad_2.png',
  ),
  MysticAnimatedEmoji(
    id: 'adi_angry',
    ownerUserId: 'adi',
    label: 'Adi Angry',
    frame1Asset: 'assets/animated_emojis/adi/adi_angry_1.png',
    frame2Asset: 'assets/animated_emojis/adi/adi_angry_2.png',
  ),

  // Danielle
  MysticAnimatedEmoji(
    id: 'danielle_happy',
    ownerUserId: 'danielle',
    label: 'Danielle Happy',
    frame1Asset: 'assets/animated_emojis/danielle/danielle_happy_1.png',
    frame2Asset: 'assets/animated_emojis/danielle/danielle_happy_2.png',
  ),
  MysticAnimatedEmoji(
    id: 'danielle_sad',
    ownerUserId: 'danielle',
    label: 'Danielle Sad',
    frame1Asset: 'assets/animated_emojis/danielle/danielle_sad_1.png',
    frame2Asset: 'assets/animated_emojis/danielle/danielle_sad_2.png',
  ),
  MysticAnimatedEmoji(
    id: 'danielle_angry',
    ownerUserId: 'danielle',
    label: 'Danielle Angry',
    frame1Asset: 'assets/animated_emojis/danielle/danielle_angry_1.png',
    frame2Asset: 'assets/animated_emojis/danielle/danielle_angry_2.png',
  ),

  // Lera
  MysticAnimatedEmoji(
    id: 'lera_happy',
    ownerUserId: 'lera',
    label: 'Lera Happy',
    frame1Asset: 'assets/animated_emojis/lera/lera_happy_1.png',
    frame2Asset: 'assets/animated_emojis/lera/lera_happy_2.png',
  ),
  MysticAnimatedEmoji(
    id: 'lera_sad',
    ownerUserId: 'lera',
    label: 'Lera Sad',
    frame1Asset: 'assets/animated_emojis/lera/lera_sad_1.png',
    frame2Asset: 'assets/animated_emojis/lera/lera_sad_2.png',
  ),
  MysticAnimatedEmoji(
    id: 'lera_angry',
    ownerUserId: 'lera',
    label: 'Lera Angry',
    frame1Asset: 'assets/animated_emojis/lera/lera_angry_1.png',
    frame2Asset: 'assets/animated_emojis/lera/lera_angry_2.png',
  ),

  // Lihi
  MysticAnimatedEmoji(
    id: 'lihi_happy',
    ownerUserId: 'lihi',
    label: 'Lihi Happy',
    frame1Asset: 'assets/animated_emojis/lihi/lihi_happy_1.png',
    frame2Asset: 'assets/animated_emojis/lihi/lihi_happy_2.png',
  ),
  MysticAnimatedEmoji(
    id: 'lihi_sad',
    ownerUserId: 'lihi',
    label: 'Lihi Sad',
    frame1Asset: 'assets/animated_emojis/lihi/lihi_sad_1.png',
    frame2Asset: 'assets/animated_emojis/lihi/lihi_sad_2.png',
  ),
  MysticAnimatedEmoji(
    id: 'lihi_angry',
    ownerUserId: 'lihi',
    label: 'Lihi Angry',
    frame1Asset: 'assets/animated_emojis/lihi/lihi_angry_1.png',
    frame2Asset: 'assets/animated_emojis/lihi/lihi_angry_2.png',
  ),

  // Lian
  MysticAnimatedEmoji(
    id: 'lian_happy',
    ownerUserId: 'lian',
    label: 'Lian Happy',
    frame1Asset: 'assets/animated_emojis/lian/lian_happy_1.png',
    frame2Asset: 'assets/animated_emojis/lian/lian_happy_2.png',
  ),
  MysticAnimatedEmoji(
    id: 'lian_sad',
    ownerUserId: 'lian',
    label: 'Lian Sad',
    frame1Asset: 'assets/animated_emojis/lian/lian_sad_1.png',
    frame2Asset: 'assets/animated_emojis/lian/lian_sad_2.png',
  ),
  MysticAnimatedEmoji(
    id: 'lian_angry',
    ownerUserId: 'lian',
    label: 'Lian Angry',
    frame1Asset: 'assets/animated_emojis/lian/lian_angry_1.png',
    frame2Asset: 'assets/animated_emojis/lian/lian_angry_2.png',
  ),

  // Tal
  MysticAnimatedEmoji(
    id: 'tal_happy',
    ownerUserId: 'tal',
    label: 'Tal Happy',
    frame1Asset: 'assets/animated_emojis/tal/tal_happy_1.png',
    frame2Asset: 'assets/animated_emojis/tal/tal_happy_2.png',
  ),
  MysticAnimatedEmoji(
    id: 'tal_sad',
    ownerUserId: 'tal',
    label: 'Tal Sad',
    frame1Asset: 'assets/animated_emojis/tal/tal_sad_1.png',
    frame2Asset: 'assets/animated_emojis/tal/tal_sad_2.png',
  ),
  MysticAnimatedEmoji(
    id: 'tal_angry',
    ownerUserId: 'tal',
    label: 'Tal Angry',
    frame1Asset: 'assets/animated_emojis/tal/tal_angry_1.png',
    frame2Asset: 'assets/animated_emojis/tal/tal_angry_2.png',
  ),

  // Nella
  MysticAnimatedEmoji(
    id: 'nella_happy',
    ownerUserId: 'nella',
    label: 'Nella Happy',
    frame1Asset: 'assets/animated_emojis/nella/nella_happy_1.png',
    frame2Asset: 'assets/animated_emojis/nella/nella_happy_2.png',
  ),
  MysticAnimatedEmoji(
    id: 'nella_sad',
    ownerUserId: 'nella',
    label: 'Nella Sad',
    frame1Asset: 'assets/animated_emojis/nella/nella_sad_1.png',
    frame2Asset: 'assets/animated_emojis/nella/nella_sad_2.png',
  ),
  MysticAnimatedEmoji(
    id: 'nella_angry',
    ownerUserId: 'nella',
    label: 'Nella Angry',
    frame1Asset: 'assets/animated_emojis/nella/nella_angry_1.png',
    frame2Asset: 'assets/animated_emojis/nella/nella_angry_2.png',
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