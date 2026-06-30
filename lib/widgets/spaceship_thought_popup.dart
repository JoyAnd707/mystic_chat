import 'dart:math';

import 'package:flutter/material.dart';
import '../audio/sfx.dart';

class ThoughtData {
  final String userId;
  final String text;
  final String silhouetteAsset;
  final Color color;

  const ThoughtData({
    required this.userId,
    required this.text,
    required this.silhouetteAsset,
    required this.color,
  });
}

const String _thoughtBackgroundAsset =
    'assets/ui/thoughts/ThoughtWindowBG.png';

const String _topText =
    "The spaceship's sensors have caught the AFA members'\nmeaningless thoughts.";

const String _bottomText =
    "The spaceship does not always move forward... It orbits around :D";

const List<ThoughtData> _thoughts = [
  ThoughtData(
    userId: 'joy',
    text: 'I miss Jake...', 
    silhouetteAsset: 'assets/ui/thoughts/JoyThought.png',
    color: Color(0xFFB789FF),
  ),
    ThoughtData(
    userId: 'joy',
    text: 'I\'m gonna piss myself if i don\'t go soon.', 
    silhouetteAsset: 'assets/ui/thoughts/JoyThought.png',
    color: Color(0xFFB789FF),
  ),
      ThoughtData(
    userId: 'joy',
    text: 'Why do my eyes look like that..?', 
    silhouetteAsset: 'assets/ui/thoughts/JoyThought.png',
    color: Color(0xFFB789FF),
  ),
        ThoughtData(
    userId: 'joy',
    text: 'One whisker... And another one. Whiskers everywhere!', 
    silhouetteAsset: 'assets/ui/thoughts/JoyThought.png',
    color: Color(0xFFB789FF),
  ),
          ThoughtData(
    userId: 'joy',
    text: 'Do Dubi and Mila even miss me?', 
    silhouetteAsset: 'assets/ui/thoughts/JoyThought.png',
    color: Color(0xFFB789FF),
  ),
            ThoughtData(
    userId: 'joy',
    text: 'Badul Badai Badei Badong!', 
    silhouetteAsset: 'assets/ui/thoughts/JoyThought.png',
    color: Color(0xFFB789FF),
  ),
          ThoughtData(
    userId: 'joy',
    text: 'Aw hell nah Jigsaw...', 
    silhouetteAsset: 'assets/ui/thoughts/JoyThought.png',
    color: Color(0xFFB789FF),
  ),
  ThoughtData(
    userId: 'adi',
    text: 'I forgot what I was going to say.',
    silhouetteAsset: 'assets/ui/thoughts/AdiThought.png',
    color: Color(0xFFFF7E9E),
  ),
    ThoughtData(
    userId: 'adi',
    text: 'I forgot what I was going to say.',
    silhouetteAsset: 'assets/ui/thoughts/AdiThought.png',
    color: Color(0xFFFF7E9E),
  ),
    ThoughtData(
    userId: 'adi',
    text: 'Shmitzy and Tuti and Shmitzy and tuti!!.',
    silhouetteAsset: 'assets/ui/thoughts/AdiThought.png',
    color: Color(0xFFFF7E9E),
  ),
    ThoughtData(
    userId: 'adi',
    text: 'New spongebob is so bad... I miss the old Bob.',
    silhouetteAsset: 'assets/ui/thoughts/AdiThought.png',
    color: Color(0xFFFF7E9E),
  ),
    ThoughtData(
    userId: 'adi',
    text: 'Where did my lash go?!',
    silhouetteAsset: 'assets/ui/thoughts/AdiThought.png',
    color: Color(0xFFFF7E9E),
  ),
    ThoughtData(
    userId: 'adi',
    text: 'I miss Lian. Ough...',
    silhouetteAsset: 'assets/ui/thoughts/AdiThought.png',
    color: Color(0xFFFF7E9E),
  ),
    ThoughtData(
    userId: 'adi',
    text: 'The potatoes. Mash them.',
    silhouetteAsset: 'assets/ui/thoughts/AdiThought.png',
    color: Color(0xFFFF7E9E),
  ),
  ThoughtData(
    userId: 'danielle',
    text:
        'So... tired...',
    silhouetteAsset: 'assets/ui/thoughts/DanielleThought.png',
    color: Color(0xFF4DBDFF),
  ),
    ThoughtData(
    userId: 'danielle',
    text:
        'So... tired...',
    silhouetteAsset: 'assets/ui/thoughts/DanielleThought.png',
    color: Color(0xFF4DBDFF),
  ),
    ThoughtData(
    userId: 'danielle',
    text:
        'Why is everyone so noisy today...',
    silhouetteAsset: 'assets/ui/thoughts/DanielleThought.png',
    color: Color(0xFF4DBDFF),
  ),
    ThoughtData(
    userId: 'danielle',
    text:
        'The laptop is burning my legs. Ugh.',
    silhouetteAsset: 'assets/ui/thoughts/DanielleThought.png',
    color: Color(0xFF4DBDFF),
  ),
    ThoughtData(
    userId: 'danielle',
    text:
        'Itsu kara sonna kao shite, Itsu kara kowareteitta, Sugiyuki kisetsu ga naiteiru..',

    silhouetteAsset: 'assets/ui/thoughts/DanielleThought.png',
    color: Color(0xFF4DBDFF),
  ),
    ThoughtData(
    userId: 'danielle',
    text:
        'Blegh, shit smells of strawberries.',
    silhouetteAsset: 'assets/ui/thoughts/DanielleThought.png',
    color: Color(0xFF4DBDFF),
  ),
    ThoughtData(
    userId: 'danielle',
    text:
        'Ruki The Gazette Ruki The Gazette',
    silhouetteAsset: 'assets/ui/thoughts/DanielleThought.png',
    color: Color(0xFF4DBDFF),
  ),
  ThoughtData(
    userId: 'lera',
    text: 'I can walk there.',
    silhouetteAsset: 'assets/ui/thoughts/LeraThought.png',
    color: Color(0xFFFFA24D),
  ),
    ThoughtData(
    userId: 'lera',
    text: 'Need to pick up Taya ASAP.',
    silhouetteAsset: 'assets/ui/thoughts/LeraThought.png',
    color: Color(0xFFFFA24D),
  ),
    ThoughtData(
    userId: 'lera',
    text: 'Is Danielle home?.',
    silhouetteAsset: 'assets/ui/thoughts/LeraThought.png',
    color: Color(0xFFFFA24D),
  ),
  ThoughtData(
    userId: 'lihi',
    text: 'Should i go choco-vanilla again?',
    silhouetteAsset: 'assets/ui/thoughts/LihiThought.png',
    color: Color(0xFFFFE66D),
  ),
    ThoughtData(
    userId: 'lihi',
    text: 'Everyone in this building\'s so damn kawaii',
    silhouetteAsset: 'assets/ui/thoughts/LihiThought.png',
    color: Color(0xFFFFE66D),
  ),
  ThoughtData(
    userId: 'lian',
    text: 'What type of makeup style should i go with today..?',
    silhouetteAsset: 'assets/ui/thoughts/LianThought.png',
    color: Color(0xFFFF5A5A),
  ),
    ThoughtData(
    userId: 'lian',
    text: 'Annoying ahh costumers.',
    silhouetteAsset: 'assets/ui/thoughts/LianThought.png',
    color: Color(0xFFFF5A5A),
  ),
    ThoughtData(
    userId: 'lian',
    text: 'I miss you too, Adi..',
    silhouetteAsset: 'assets/ui/thoughts/LianThought.png',
    color: Color(0xFFFF5A5A),
  ),
    ThoughtData(
    userId: 'lian',
    text: 'Hannibal looks extra hot this episode. Uwa... >.<',
    silhouetteAsset: 'assets/ui/thoughts/LianThought.png',
    color: Color(0xFFFF5A5A),
  ),
  ThoughtData(
    userId: 'tal',
    text: 'I don\'t wanna play this alone!!.',
    silhouetteAsset: 'assets/ui/thoughts/TalThought.png',
    color: Color(0xFF7ED957),
  ),
    ThoughtData(
    userId: 'tal',
    text: 'I don\'t wanna play this alone!!.',
    silhouetteAsset: 'assets/ui/thoughts/TalThought.png',
    color: Color(0xFF7ED957),
  ),
    ThoughtData(
    userId: 'tal',
    text: 'New animation project...yea!',
    silhouetteAsset: 'assets/ui/thoughts/TalThought.png',
    color: Color(0xFF7ED957),
  ),
      ThoughtData(
    userId: 'tal',
    text: 'Where the hell is Berry?!',
    silhouetteAsset: 'assets/ui/thoughts/TalThought.png',
    color: Color(0xFF7ED957),
  ),
  ThoughtData(
    userId: 'nella',
    text: 'Goodnight Issei, good night Lion!',
    silhouetteAsset: 'assets/ui/thoughts/NellaThought.png',
    color: Color(0xFF40E0D0),
  ),
    ThoughtData(
    userId: 'nella',
    text: 'I need to cut my bangs again.',
    silhouetteAsset: 'assets/ui/thoughts/NellaThought.png',
    color: Color(0xFF40E0D0),
  ),
    ThoughtData(
    userId: 'nella',
    text: 'CLEARLY i own an air fryer!!!',
    silhouetteAsset: 'assets/ui/thoughts/NellaThought.png',
    color: Color(0xFF40E0D0),
  ),
];

void showRandomSpaceshipThought(BuildContext context) {
  try {
    Sfx.I.playBack();
  } catch (_) {}

  final ThoughtData thought = _thoughts[Random().nextInt(_thoughts.length)];

  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Spaceship thought',
    barrierColor: Colors.black.withOpacity(0.08),
    transitionDuration: const Duration(milliseconds: 560),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _SpaceshipThoughtPopup(thought: thought);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final CurvedAnimation curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      );

      return FadeTransition(
        opacity: curved,
        child: child,
      );
    },
  );
}

class _SpaceshipThoughtPopup extends StatelessWidget {
  final ThoughtData thought;

  const _SpaceshipThoughtPopup({
    required this.thought,
  });

  void _close(BuildContext context) {
    try {
      Sfx.I.playBack();
    } catch (_) {}

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _close(context);
        },
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.48,
                    child: Image.asset(
                      _thoughtBackgroundAsset,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: Colors.black.withOpacity(0.45),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 22,
                  left: 22,
                  right: 22,
                  child: Text(
                    _topText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'CormorantGaramond',
                      color: const Color(0xFFFFF16A),
                      fontSize: 13,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.9),
                          blurRadius: 5,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 66,
                  child: Opacity(
                    opacity: 0.38,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        thought.color.withOpacity(0.9),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        thought.silhouetteAsset,
                        width: 185,
                        height: 150,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) {
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 28,
                  right: 28,
                  top: 102,
                  child: Text(
                    thought.text,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'CormorantGaramond',
                      color: Colors.white,
                      fontSize: 19,
                      height: 1.05,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.95),
                          blurRadius: 6,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Text(
                    _bottomText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'CormorantGaramond',
                      color: const Color(0xFFFFC37A),
                      fontSize: 10,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.95),
                          blurRadius: 5,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}