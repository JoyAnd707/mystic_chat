import 'package:flutter/material.dart';
import '../../audio/bgm.dart';
import '../../audio/sfx.dart';
import 'package:shared_preferences/shared_preferences.dart';
class SettingsSoundSliders extends StatefulWidget {
  const SettingsSoundSliders({super.key});

  @override
  State<SettingsSoundSliders> createState() =>
      _SettingsSoundSlidersState();
}

class _SettingsSoundSlidersState extends State<SettingsSoundSliders> {
  double _bgmValue = 0.7;
  double _sfxValue = 0.7;
  double _voiceValue = 0.7;
  double _voiceSfxValue = 0.7;
@override
void initState() {
  super.initState();
  _loadSettings();
}

Future<void> _loadSettings() async {
  final prefs = await SharedPreferences.getInstance();

  final bgm = prefs.getDouble('bgm_volume') ?? 0.7;
  final sfx = prefs.getDouble('sfx_volume') ?? 0.7;
  final voice = prefs.getDouble('voice_volume') ?? 0.7;
  final voiceSfx = prefs.getDouble('voice_sfx_volume') ?? 0.7;

  if (!mounted) return;

  setState(() {
    _bgmValue = bgm;
    _sfxValue = sfx;
    _voiceValue = voice;
    _voiceSfxValue = voiceSfx;
  });

  await Bgm.I.setVolume(bgm);
  await Sfx.I.setVolume(sfx);
}
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 122,
          right: 34,
          top: 34,
          child: MysticPlanetSlider(
value: _bgmValue,
onChanged: (value) {
  setState(() {
    _bgmValue = value;
  });

Bgm.I.setVolume(value);
SharedPreferences.getInstance().then((prefs) {
  prefs.setDouble('bgm_volume', value);
});},
          ),
        ),

        Positioned(
          left: 122,
          right: 34,
          top: 68,
          child: MysticPlanetSlider(
 value: _sfxValue,
onChanged: (value) {
  setState(() {
    _sfxValue = value;
  });

Sfx.I.setVolume(value);
SharedPreferences.getInstance().then((prefs) {
  prefs.setDouble('sfx_volume', value);
});},
          ),
        ),
                Positioned(
          left: 122,
          right: 34,
          top: 102,
          child: MysticPlanetSlider(
            value: _voiceValue,
            onChanged: (value) {
              setState(() {
                _voiceValue = value;
              });
            },
          ),
        ),

        Positioned(
          left: 122,
          right: 34,
          top: 136,
          child: MysticPlanetSlider(
            value: _voiceSfxValue,
            onChanged: (value) {
              setState(() {
                _voiceSfxValue = value;
              });
            },
          ),
        ),
      ],
    );
  }


  
}

class MysticPlanetSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const MysticPlanetSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<MysticPlanetSlider> createState() => _MysticPlanetSliderState();
}

class _MysticPlanetSliderState extends State<MysticPlanetSlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

@override
Widget build(BuildContext context) {
 return GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTapDown: (details) {
    _updateValueFromDx(details.localPosition.dx);
  },
  onHorizontalDragUpdate: (details) {
    _updateValueFromDx(details.localPosition.dx);
  },
  child: SizedBox(
    width: 210,
    height: 34,
    child: Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(
            painter: _MysticSliderTrackPainter(),
          ),
        ),

        Positioned(
         left: (8 + ((160 - 26) * _value)).clamp(0.0, 134.0),
          top: 4,
          child: const SizedBox(
            width: 26,
            height: 26,
            child: CustomPaint(
              painter: _PlanetThumbPainter(),
            ),
          ),
        ),
      ],
    ),
  )
  );
 
}
void _updateValueFromDx(double dx) {
  const double sliderWidth = 210;
  const double trackInset = 8;

  final double usableWidth = sliderWidth - (trackInset * 2);
  final double clampedDx = dx.clamp(trackInset, sliderWidth - trackInset);

  final double newValue = ((clampedDx - trackInset) / usableWidth).clamp(0.0, 1.0);

  setState(() {
    _value = newValue;
  });

  widget.onChanged(newValue);
}
}

class _MysticSliderTrackPainter extends CustomPainter {
  const _MysticSliderTrackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const Color mint = Color(0xFF8FFFEF);

    final Paint linePaint = Paint()
      ..color = mint.withOpacity(0.85)
     ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    final double y = size.height / 2;

    canvas.drawLine(
      Offset(8, y),
      Offset(size.width - 8, y),
      linePaint,
    );

    final Paint starPaint = Paint()
      ..color = mint
      ..style = PaintingStyle.fill;

void drawStar(double x) {
  final Path p = Path()
    ..moveTo(x, y - 3.5)
    ..lineTo(x + 2.2, y)
    ..lineTo(x, y + 3.5)
    ..lineTo(x - 2.2, y)
    ..close();

  canvas.drawPath(p, starPaint);
}
    drawStar(8);
    drawStar(size.width - 8);
  }

  @override
  bool shouldRepaint(covariant _MysticSliderTrackPainter oldDelegate) {
    return false;
  }
}
class _PlanetThumbPainter extends CustomPainter {
  const _PlanetThumbPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint ringPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final Paint planetPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawLine(
      Offset(center.dx - 14, center.dy - 4),
      Offset(center.dx + 14, center.dy + 4),
      ringPaint,
    );

    canvas.drawCircle(center, 8.5, planetPaint);
  }

  @override
  bool shouldRepaint(covariant _PlanetThumbPainter oldDelegate) {
    return false;
  }
}

