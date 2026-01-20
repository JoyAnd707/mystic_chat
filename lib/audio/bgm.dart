import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class Bgm {
  Bgm._();
  static final Bgm I = Bgm._();

  final AudioPlayer _player = AudioPlayer();

  bool enabled = true;

  String? _currentAsset;

  String? _lastStoppedAsset;
  Duration? _lastStoppedPosition;

  bool _overrideActive = false;

  String? _preEggAsset;
  bool _preEggOverrideActive = false;
  Duration? _preEggPosition;
  StreamSubscription<void>? _eggCompleteSub;
  bool _eggPlaying = false;

  Future<void> init() async {
    // ✅ BGM: don't steal focus, allow mixing
    final bgmContext = AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
        options: <AVAudioSessionOptions>{
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
    );

    await _player.setAudioContext(bgmContext);
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.45);
  }

String assetForHour(int hour) {
  // 🌅 Morning
  if (hour >= 6 && hour <= 11) {
    return 'bgm/MorningBGM.mp3';
  }

  // ☀️ Noon
  if (hour >= 12 && hour <= 16) {
    return 'bgm/NoonBGM.mp3';
  }

  // 🌆 Evening
  if (hour >= 17 && hour <= 21) {
    return 'bgm/EveningBGM.mp3';
  }

  // 🌙 Night part 1
  if (hour >= 22 && hour <= 23) {
    return 'bgm/NightBGM.mp3';
  }

  // 🌑 Midnight
  if (hour == 0) {
    return 'bgm/MidnightBGM.mp3';
  }

  // 🌌 Night part 2 (01:00–05:59)
  return 'bgm/NightBGM.mp3';
}


  Future<void> playForHour(int hour) async {
    if (!enabled) return;
    if (_overrideActive || _eggPlaying) return;

    final next = assetForHour(hour);
    await _playLoopingAsset(next);
  }

Future<void> _playLoopingAsset(String asset) async {
  if (!enabled) return;
  if (_currentAsset == asset) return;

  final resumePos =
      (_lastStoppedAsset == asset) ? _lastStoppedPosition : null;

  _currentAsset = asset;

  try {
    debugPrint('🎵 BGM set source: $asset');

    await _player.setReleaseMode(ReleaseMode.loop);

    // ✅ Important: set the source first, then resume
    await _player.stop();
    await _player.setSource(AssetSource(asset));

    if (resumePos != null) {
      await _player.seek(resumePos!);

      _lastStoppedAsset = null;
      _lastStoppedPosition = null;
    }

    await _player.resume();
  } catch (e, s) {
    debugPrint('❌ BGM failed: $e');
    debugPrint('$s');
  }
}


  Future<void> playEasterEgg(String asset) async {
    if (!enabled) return;
    if (_eggPlaying) return;

    await _eggCompleteSub?.cancel();
    _eggCompleteSub = null;

    _eggPlaying = true;

    try {
      _preEggAsset = _currentAsset;
      _preEggOverrideActive = _overrideActive;

     _preEggPosition = await _player.getCurrentPosition();



      await _player.pause();

      _currentAsset = asset;

      // play once
await _player.setReleaseMode(ReleaseMode.stop);
await _player.stop();
await _player.setSource(AssetSource(asset));
await _player.resume();


      _eggCompleteSub = _player.onPlayerComplete.listen((_) async {
        await _restoreAfterEgg();
      });
    } catch (_) {
      await _restoreAfterEgg();
    }
  }

Future<void> _restoreAfterEgg() async {
  if (!_eggPlaying) return;
  _eggPlaying = false;

  await _eggCompleteSub?.cancel();
  _eggCompleteSub = null;

  _overrideActive = _preEggOverrideActive;

  final prev = _preEggAsset;
  if (prev == null) return;

  try {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.stop();
    await _player.setSource(AssetSource(prev));

    if (_preEggPosition != null) {
      await _player.seek(_preEggPosition!);
    }

    await _player.resume();
    _currentAsset = prev;
  } catch (_) {}
}


  Future<void> playAssetPermanentOverride(String asset) async {
    if (!enabled) return;
    _overrideActive = true;
    await _playLoopingAsset(asset);
  }

  Future<void> clearOverrideAndResume(int hour) async {
    _overrideActive = false;
    await playForHour(hour);
  }

Future<void> stop() async {
  try {
    await _eggCompleteSub?.cancel();
    _eggCompleteSub = null;

    _eggPlaying = false;
    _overrideActive = false;

    _lastStoppedAsset = _currentAsset;
    _lastStoppedPosition = await _player.getCurrentPosition();

    await _player.stop();
    _currentAsset = null;
  } catch (_) {}
}



Future<void> pause() async {
  try {
    // keep current asset + position so we can resume cleanly
    _lastStoppedAsset = _currentAsset;
    _lastStoppedPosition = await _player.getCurrentPosition();
    await _player.pause();
  } catch (_) {}
}

Future<void> resumeIfPossible() async {
  try {
    if (!enabled) return;
    if (_overrideActive || _eggPlaying) return;

    // If we already have a current asset loaded, just resume.
    if (_currentAsset != null) {
      await _player.resume();
      return;
    }

    // If we paused earlier and cleared nothing, restore same track+pos.
    if (_lastStoppedAsset != null) {
      final asset = _lastStoppedAsset!;
      final pos = _lastStoppedPosition;

      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.stop();
      await _player.setSource(AssetSource(asset));
      if (pos != null) await _player.seek(pos);
      await _player.resume();

      _currentAsset = asset;
    }
  } catch (_) {}
}

}
