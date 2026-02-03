import 'package:flutter/material.dart';
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
  late final Future<void> _initFuture;

  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    _initFuture = _controller.initialize().then((_) async {
      if (!mounted) return;
      await _controller.play(); // autoplay
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_controller.value.isInitialized) return;
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _initFuture,
          builder: (context, snap) {
            final ready =
                snap.connectionState == ConnectionState.done && _controller.value.isInitialized;

            if (!ready) {
              return const Center(child: CircularProgressIndicator());
            }

            // ✅ rebuilds whenever controller value changes (smooth UI)
            return ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller,
              builder: (context, v, _) {
                final Duration pos = v.position;
                final Duration dur = v.duration;

                final double maxMs =
                    dur.inMilliseconds.toDouble().clamp(1.0, double.infinity);
                final double curMs =
                    pos.inMilliseconds.toDouble().clamp(0.0, maxMs);

                return Stack(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _togglePlay,
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: v.aspectRatio == 0 ? 16 / 9 : v.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ),
                    ),

                    // Close button
                    Positioned(
                      top: 8,
                      left: 8,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      ),
                    ),

                    // Bottom controls overlay
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.70),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✅ Slider (scrub line)
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white.withOpacity(0.22),
                                thumbColor: Colors.white,
                                overlayColor: Colors.white.withOpacity(0.12),
                                trackHeight: 4.2, // ✅ “עבה”
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 7.0,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14.0,
                                ),
                              ),
                              child: Slider(
                                value: curMs,
                                min: 0.0,
                                max: maxMs,
                                onChangeStart: (_) => setState(() => _dragging = true),
                                onChanged: (ms) async {
                                  final seekTo = Duration(milliseconds: ms.round());
                                  await _controller.seekTo(seekTo);
                                },
                                onChangeEnd: (_) => setState(() => _dragging = false),
                              ),
                            ),

                            const SizedBox(height: 6),

                            Row(
                              children: [
                                IconButton(
                                  onPressed: _togglePlay,
                                  icon: Icon(
                                    v.isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),

                                Text(
                                  '${_fmt(pos)} / ${_fmt(dur)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.0,
                                  ),
                                ),

                                const Spacer(),

                                IconButton(
                                  onPressed: () async {
                                    final newPos = pos - const Duration(seconds: 10);
                                    await _controller.seekTo(
                                      newPos < Duration.zero ? Duration.zero : newPos,
                                    );
                                  },
                                  icon: const Icon(Icons.replay_10, color: Colors.white),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final newPos = pos + const Duration(seconds: 10);
                                    await _controller.seekTo(newPos > dur ? dur : newPos);
                                  },
                                  icon: const Icon(Icons.forward_10, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Play overlay icon when paused (and not dragging)
                    if (!v.isPlaying && !_dragging)
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 46,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
