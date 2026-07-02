import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import '../services/app_settings.dart';
import 'bgm.dart';
class Sfx {
  Sfx._();
  static final Sfx I = Sfx._();

  bool enabled = true;
  double _volume = 0.9;

  // Small pool so SFX can overlap without stealing the BGM engine
  final int _poolSize = 4;
  final List<AudioPlayer> _pool = [];
  int _next = 0;

Future<void> init() async {
  _volume = AppSettings.sfxVolume;

  for (int i = 0; i < _poolSize; i++) {
    final p = AudioPlayer();
    await p.setVolume(_volume);
    _pool.add(p);
  }
}

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);

    for (final p in _pool) {
      await p.setVolume(_volume);
    }
  }

  double get volume => _volume;
Future<void> playCloseImage() =>
    _playOne('assets/fx/CloseImage.mp3', volume: 0.9);

  AudioPlayer _take() {
    final p = _pool[_next];
    _next = (_next + 1) % _pool.length;
    return p;
  }
Future<void> playUruha() =>
    _playOne('assets/fx/Uruha.mp3', volume: 0.9, pauseBgm: true);

Future<void> playRuki() =>
    _playOne('assets/fx/Ruki.mp3', volume: 0.9, pauseBgm: true);

Future<void> playAoi() =>
    _playOne('assets/fx/Aoi.mp3', volume: 0.9, pauseBgm: true);

Future<void> playReita() =>
    _playOne('assets/fx/Reita.mp3', volume: 0.9, pauseBgm: true);

Future<void> playKai() =>
    _playOne('assets/fx/Kai.mp3', volume: 0.9, pauseBgm: true);

Future<void> playGazette() =>
    _playOne('assets/fx/Gazette.mp3', volume: 0.9, pauseBgm: true);
Future<void> _playOne(
  String assetPath, {
  double volume = 0.9,
  bool pauseBgm = false,
}) async {
  if (!enabled) return;

  final p = _take();

  try {
    if (pauseBgm) {
      await Bgm.I.pause();
    }

    await p.setVolume(volume * _volume);
    await p.stop();
    await p.setAudioSource(AudioSource.asset(assetPath));
    await p.play();

    if (pauseBgm) {
      await p.playerStateStream
          .firstWhere((s) => s.processingState == ProcessingState.completed);

      await Bgm.I.resumeIfPossible();
    }
  } catch (e) {
    debugPrint('SFX failed ($assetPath): $e');

    if (pauseBgm) {
      await Bgm.I.resumeIfPossible();
    }
  }
}
  Future<void> playSend() => _playOne('assets/fx/send.mp3', volume: 0.8);
  Future<void> playSelectDm() => _playOne('assets/fx/SelectDMsfx.mp3', volume: 0.9);
  Future<void> playSettingsTabChange() =>
    _playOne('assets/fx/ChangeTabSFX.mp3', volume: 0.9);

Future<void> playToggle() =>
    _playOne('assets/fx/ToggleSfx.mp3', volume: 0.9);
  Future<void> playEnterDmsMenu() =>
    _playOne('assets/fx/EnterDMSMenuSFX.mp3', volume: 0.9);
Future<void> playGoIntoPhoto() =>
    _playOne('assets/fx/GoIntophotoSFX.mp3', volume: 0.9);
Future<void> playEnterGroupChat() =>
    _playOne('assets/fx/EnterGroupChatSFX.mp3', volume: 0.9);
  Future<void> playBack() => _playOne('assets/fx/back.mp3', volume: 0.8);
Future<void> playStopListeningToVoiceMessage() =>
    _playOne('assets/fx/StopListeningToVoiceMessage.mp3', volume: 0.9);
Future<void> playGoIntoGallery() =>
    _playOne('assets/fx/GoIntoSomeonesGallerySFX.mp3', volume: 0.9);
Future<void> playMainMenuButtonRow() =>
    _playOne('assets/fx/MainMenuButtonRowSFX.mp3', volume: 0.9);

  Future<void> play707VoiceLine() =>
      _playOne('assets/fx/707VoiceLine.mp3', volume: 0.95);
Future<void> playLolol() =>
    _playOne('assets/fx/LOLOLsfx.mp3', volume: 0.9);
Future<void> playViewStatus() =>
    _playOne('assets/fx/ViewStatusSFX.mp3', volume: 0.9);
    

  Future<void> dispose() async {
    for (final p in _pool) {
      await p.dispose();
    }
    _pool.clear();
  }

Future<void> playGlitch() => _playOne('assets/fx/GlitchSFX.mp3', volume: 0.95);

  Future<void> stopAll() async {
  try {
    for (final p in _pool) {
      await p.stop();
    }
  } catch (_) {}
}

}
