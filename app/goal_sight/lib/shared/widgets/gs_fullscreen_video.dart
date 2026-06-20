// ---------------------------------------------------------------------------
// GoalSight — Fullscreen Video Player
//
// Immersive, landscape-locked fullscreen player driven by an EXISTING
// [VideoPlayerController]. Because the caller passes its own controller, the
// playback position is shared — entering and exiting fullscreen never loses
// the current position. On dispose the screen restores portrait + the normal
// system UI overlays.
//
// Controls: tap-to-toggle, play/pause, scrubber with time indicators, and a
// cycling playback-speed button (0.5× / 1× / 1.5× / 2×).
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_theme.dart';

/// Pushes the fullscreen player for [controller]. Returns when the user exits.
Future<void> openFullscreenVideo(
  BuildContext context,
  VideoPlayerController controller,
) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => GsFullscreenVideo(controller: controller),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

class GsFullscreenVideo extends StatefulWidget {
  const GsFullscreenVideo({super.key, required this.controller});

  final VideoPlayerController controller;

  @override
  State<GsFullscreenVideo> createState() => _GsFullscreenVideoState();
}

class _GsFullscreenVideoState extends State<GsFullscreenVideo> {
  static const _speeds = [0.5, 1.0, 1.5, 2.0];

  bool _showControls = true;

  VideoPlayerController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    // Go immersive + landscape for a true fullscreen feel.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _autoHide();
  }

  @override
  void dispose() {
    // Restore the app's normal portrait chrome on the way out.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _autoHide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _ctrl.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _autoHide();
  }

  void _togglePlay() {
    setState(() {
      _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play();
      _showControls = true;
    });
    _autoHide();
  }

  void _cycleSpeed() {
    final current = _ctrl.value.playbackSpeed;
    final idx = _speeds.indexWhere((s) => (s - current).abs() < 0.01);
    final next = _speeds[(idx + 1) % _speeds.length];
    _ctrl.setPlaybackSpeed(next);
    setState(() => _showControls = true);
    _autoHide();
  }

  void _seekTo(double fraction) {
    _ctrl.seekTo(_ctrl.value.duration * fraction);
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final aspect = _ctrl.value.aspectRatio;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: aspect > 0 ? aspect : 16 / 9,
                child: VideoPlayer(_ctrl),
              ),
            ),
            AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: _controlsOverlay(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlsOverlay(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.55),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.65),
          ],
          stops: const [0, 0.4, 1],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top: exit + speed.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  _circleButton(
                    icon: Icons.fullscreen_exit_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cycleSpeed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: AppRadius.chip,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.speed_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          ValueListenableBuilder<VideoPlayerValue>(
                            valueListenable: _ctrl,
                            builder: (_, v, __) => Text(
                              '${v.playbackSpeed}×',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Center: play / pause.
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _ctrl.value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
            const Spacer(),
            // Bottom: scrubber + times.
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _ctrl,
              builder: (_, v, __) {
                final total = v.duration.inMilliseconds;
                final pos = v.position.inMilliseconds;
                final frac = total > 0 ? (pos / total).clamp(0.0, 1.0) : 0.0;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Text(_fmt(v.position),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14),
                            trackHeight: 3,
                            activeTrackColor: AppColors.accentCyan,
                            inactiveTrackColor:
                                Colors.white.withValues(alpha: 0.3),
                            thumbColor: AppColors.accentCyan,
                          ),
                          child: Slider(value: frac, onChanged: _seekTo),
                        ),
                      ),
                      Text(_fmt(v.duration),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
