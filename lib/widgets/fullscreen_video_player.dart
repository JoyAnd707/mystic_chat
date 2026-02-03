import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class FullscreenVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const FullscreenVideoPlayer({
    super.key,
    required this.videoUrl,
  });

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  late final VideoPlayerController _controller;
  Future<void>? _initFuture;

  // ✅ YOUR ASSETS (edit paths if needed)
  static const String _pauseIconAsset = 'assets/ui/VideoPausedIcon.png';
  static const String _playIconAsset = 'assets/ui/VideoResumedIcon.png';
  static const String _waveBarAsset = 'assets/ui/VideoProgressionBar.png';
  static const String _catThumbAsset = 'assets/ui/ProgressionDotVideo.png';

  bool _dragging = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initFuture = _controller.initialize().then((_) {
      if (!mounted) return;
      _controller.play();
      setState(() {});
    });

    _controller.addListener(_onTick);
  }

  void _onTick() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  bool get _ready => _controller.value.isInitialized;

  Duration get _pos => _ready ? _controller.value.position : Duration.zero;
  Duration get _dur => _ready ? _controller.value.duration : Duration.zero;

  double get _progress01 {
    final d = _dur.inMilliseconds;
    if (!_ready || d <= 0) return 0.0;
    final p = _pos.inMilliseconds / d;
    return p.clamp(0.0, 1.0);
  }

  Future<void> _seekTo01(double t01) async {
    if (!_ready) return;
    final totalMs = _dur.inMilliseconds;
    final targetMs = (t01.clamp(0.0, 1.0) * totalMs).round();
    await _controller.seekTo(Duration(milliseconds: targetMs));
  }

  void _togglePlay() {
    if (!_ready) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  String _fmt(Duration d) {
    final int totalSeconds = d.inSeconds;
    final int m = totalSeconds ~/ 60;
    final int s = totalSeconds % 60;
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final bool ready = _ready;
    final bool playing = ready ? _controller.value.isPlaying : false;

    final Duration pos = _pos;
    final Duration dur = _dur;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ==========================
            // VIDEO + TAP TO TOGGLE (BEHIND CONTROLS)
            // ==========================
            Positioned.fill(
              child: GestureDetector(
                onTap: ready ? _togglePlay : null,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: FutureBuilder<void>(
                    future: _initFuture,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done ||
                          !_ready) {
                        return const CircularProgressIndicator();
                      }

                      return AspectRatio(
                        aspectRatio: _controller.value.aspectRatio == 0
                            ? 16 / 9
                            : _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      );
                    },
                  ),
                ),
              ),
            ),

            // ==========================
            // CLOSE (top-left) - WORKS
            // ==========================
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () async {
                  if (_ready) {
                    try {
                      await _controller.pause();
                    } catch (_) {}
                  }
                  if (mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),

            // ==========================
            // CENTER PLAY OVERLAY (SMALLER)
            // ==========================
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: (!ready) ? 0.0 : (playing ? 0.0 : 1.0),
                    child: Image.asset(
                      _playIconAsset,
                      width: 74,
                      height: 74,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            // ==========================
            // BOTTOM BLACK BAR + CONTROLS
            // ==========================
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(0.88),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _WaveProgressBar(
                      waveAsset: _waveBarAsset,
                      thumbAsset: _catThumbAsset,
                      progress01: _progress01,
                      enabled: ready,
                      onSeek01: (t01) => _seekTo01(t01),
                      onDraggingChanged: (drag) {
                        if (!mounted) return;
                        setState(() => _dragging = drag);
                      },
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        GestureDetector(
                          onTap: ready ? _togglePlay : null,
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: 46,
                            height: 46,
                            child: Center(
                              child: Image.asset(
                                playing ? _pauseIconAsset : _playIconAsset,
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_fmt(pos)} / ${_fmt(dur)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () async {
                            if (!ready) return;
                            final newPos = pos - const Duration(seconds: 10);
                            await _controller.seekTo(
                              newPos < Duration.zero ? Duration.zero : newPos,
                            );
                          },
                          icon:
                              const Icon(Icons.replay_10, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (!ready) return;
                            final newPos = pos + const Duration(seconds: 10);
                            final end = dur;
                            await _controller.seekTo(
                              newPos > end ? end : newPos,
                            );
                          },
                          icon: const Icon(Icons.forward_10,
                              color: Colors.white),
                        ),
                      ],
                    ),

                    if (_dragging)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _fmt(pos),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12,
                            height: 1.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================
/// WAVE BAR + CAT THUMB (SCRUBBABLE)
/// ===============================
class _WaveProgressBar extends StatefulWidget {
  final String waveAsset;
  final String thumbAsset;

  final double progress01; // 0..1
  final bool enabled;

  final ValueChanged<double> onSeek01;
  final ValueChanged<bool> onDraggingChanged;

  const _WaveProgressBar({
    required this.waveAsset,
    required this.thumbAsset,
    required this.progress01,
    required this.enabled,
    required this.onSeek01,
    required this.onDraggingChanged,
  });

  @override
  State<_WaveProgressBar> createState() => _WaveProgressBarState();
}

class _WaveProgressBarState extends State<_WaveProgressBar> {
  List<double>? _y01;

  @override
  void initState() {
    super.initState();
    _loadWaveProfile();
  }

  Future<void> _loadWaveProfile() async {
    try {
      final ByteData bd = await rootBundle.load(widget.waveAsset);
      final Uint8List bytes = bd.buffer.asUint8List();

      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image img = frame.image;

      final ByteData? rgba =
          await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (rgba == null) return;

      final int imgW = img.width;
      final int imgH = img.height;

      final Uint8List data = rgba.buffer.asUint8List();

      const int step = 8; // 2048/8=256 samples
      final int samples = (imgW / step).floor().clamp(2, 2000);

      final List<double> yOut = List<double>.filled(samples, 0.5);

      for (int i = 0; i < samples; i++) {
        final int x = (i * step).clamp(0, imgW - 1);

        int count = 0;
        int sumY = 0;

        for (int y = 0; y < imgH; y++) {
          final int idx = (y * imgW + x) * 4;
          final int a = data[idx + 3];
          if (a > 20) {
            count++;
            sumY += y;
          }
        }

        if (count > 0) {
          final double meanY = sumY / count;
          yOut[i] = (meanY / (imgH - 1)).clamp(0.0, 1.0);
        } else {
          yOut[i] = 0.5;
        }
      }

      if (!mounted) return;
      setState(() => _y01 = yOut);
    } catch (_) {
      if (!mounted) return;
      setState(() => _y01 = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double hitH = 44;

    const double thumbW = 22;
    const double thumbH = 22;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;

        // keep ratio of 2048x144 image
        final double barH = (w * 0.0703125).clamp(18.0, 34.0);

        final double leftPad = thumbW * 0.55;
        final double rightPad = thumbW * 0.55;
        final double usableW =
            (w - leftPad - rightPad).clamp(1.0, double.infinity);

        double xToT01(double localX) {
          final double clampedX = localX.clamp(leftPad, w - rightPad);
          final double t = (clampedX - leftPad) / usableW;
          return t.clamp(0.0, 1.0);
        }

        final double t = widget.progress01.clamp(0.0, 1.0);

        final double xCenter = leftPad + usableW * t;
        final double thumbLeft = (xCenter - thumbW / 2).clamp(0.0, w - thumbW);

        double yOnWave01(double t01) {
          final profile = _y01;
          if (profile == null || profile.length < 2) return 0.5;

          final double f = t01.clamp(0.0, 1.0) * (profile.length - 1);
          final int a = f.floor().clamp(0, profile.length - 1);
          final int b = (a + 1).clamp(0, profile.length - 1);
          final double mix = (f - a).clamp(0.0, 1.0);
          return (profile[a] * (1 - mix) + profile[b] * mix).clamp(0.0, 1.0);
        }

        final double y01 = yOnWave01(t);
        final double waveTop = (hitH / 2) - (barH / 2);

        final double yPx = waveTop + (barH * y01);
        final double thumbTop = (yPx - thumbH / 2).clamp(0.0, hitH - thumbH);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.enabled
              ? (d) => widget.onSeek01(xToT01(d.localPosition.dx))
              : null,
          onHorizontalDragStart:
              widget.enabled ? (_) => widget.onDraggingChanged(true) : null,
          onHorizontalDragUpdate: widget.enabled
              ? (d) => widget.onSeek01(xToT01(d.localPosition.dx))
              : null,
          onHorizontalDragEnd:
              widget.enabled ? (_) => widget.onDraggingChanged(false) : null,
          onHorizontalDragCancel:
              widget.enabled ? () => widget.onDraggingChanged(false) : null,
          child: SizedBox(
            height: hitH,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: waveTop,
                  height: barH,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Opacity(
                        opacity: 0.35,
                        child: Image.asset(
                          widget.waveAsset,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: t,
                          child: Image.asset(
                            widget.waveAsset,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: thumbLeft,
                  top: thumbTop,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Image.asset(
                      widget.thumbAsset,
                      width: thumbW,
                      height: thumbH,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
