// ---------------------------------------------------------------------------
// GoalSight — Upload Video Preview Card
//
// Lets the manager preview the selected match video BEFORE analysis:
// play / pause, scrub, see the duration, and open a fullscreen preview. Built
// on the same [VideoPlayerController] + fullscreen player as the analyzed
// match experience, so controls feel identical across the app.
// ---------------------------------------------------------------------------

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gs_fullscreen_video.dart';

class VideoPreviewCard extends StatefulWidget {
  const VideoPreviewCard({super.key, required this.path});

  /// Local file path of the picked video (from image_picker).
  final String path;

  @override
  State<VideoPreviewCard> createState() => _VideoPreviewCardState();
}

class _VideoPreviewCardState extends State<VideoPreviewCard> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _error = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(VideoPreviewCard old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) {
      _ctrl?.dispose();
      _ctrl = null;
      _initialized = false;
      _error = false;
      _init();
    }
  }

  Future<void> _init() async {
    final ctrl = VideoPlayerController.file(File(widget.path));
    _ctrl = ctrl;
    try {
      await ctrl.initialize();
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final ctrl = _ctrl;
    if (ctrl == null) return;
    setState(() {
      ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
      _showControls = true;
    });
    if (ctrl.value.isPlaying) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && (_ctrl?.value.isPlaying ?? false)) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _seekTo(double fraction) {
    final ctrl = _ctrl;
    if (ctrl == null) return;
    ctrl.seekTo(ctrl.value.duration * fraction);
  }

  Future<void> _openFullscreen() async {
    final ctrl = _ctrl;
    if (ctrl == null || !_initialized) return;
    await openFullscreenVideo(context, ctrl);
    if (mounted) setState(() => _showControls = true);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: (_ctrl?.value.aspectRatio ?? 0) > 0
            ? _ctrl!.value.aspectRatio
            : 16 / 9,
        child: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_error) {
      return Container(
        color: AppColors.surface,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_outlined,
                  color: AppColors.danger, size: 30),
              const SizedBox(height: 8),
              Text('Preview unavailable',
                  style: AppTextStyles.caption(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }
    if (!_initialized) {
      return Container(
        color: AppColors.surface,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    final ctrl = _ctrl!;
    return GestureDetector(
      onTap: () {
        setState(() => _showControls = !_showControls);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(ctrl),
          AnimatedOpacity(
            opacity: _showControls ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
                child: Column(
                  children: [
                    // Top-right fullscreen.
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: GestureDetector(
                          onTap: _openFullscreen,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.fullscreen_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          ctrl.value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const Spacer(),
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: ctrl,
                      builder: (_, v, __) {
                        final total = v.duration.inMilliseconds;
                        final pos = v.position.inMilliseconds;
                        final frac =
                            total > 0 ? (pos / total).clamp(0.0, 1.0) : 0.0;
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                          child: Row(
                            children: [
                              Text(_fmt(v.position),
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11)),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 5),
                                    overlayShape:
                                        const RoundSliderOverlayShape(
                                            overlayRadius: 12),
                                    trackHeight: 2.5,
                                    activeTrackColor: AppColors.accentCyan,
                                    inactiveTrackColor:
                                        Colors.white.withValues(alpha: 0.3),
                                    thumbColor: AppColors.accentCyan,
                                  ),
                                  child:
                                      Slider(value: frac, onChanged: _seekTo),
                                ),
                              ),
                              Text(_fmt(v.duration),
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
