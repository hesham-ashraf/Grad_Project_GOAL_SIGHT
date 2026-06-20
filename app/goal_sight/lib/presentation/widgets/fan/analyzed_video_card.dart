// ---------------------------------------------------------------------------
// GoalSight — Analyzed Video Card
//
// Displays the AI-annotated match video artifact. Shows a processing
// placeholder while the video URL is absent, and a full inline player
// once a signed URL is available.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/gs_fullscreen_video.dart';

class AnalyzedVideoCard extends StatefulWidget {
  const AnalyzedVideoCard({super.key, required this.videoUrl});

  /// Signed URL for the analyzed video. Null = still processing.
  final String? videoUrl;

  @override
  State<AnalyzedVideoCard> createState() => _AnalyzedVideoCardState();
}

class _AnalyzedVideoCardState extends State<AnalyzedVideoCard> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _error = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null) {
      _initPlayer(widget.videoUrl!);
    }
  }

  @override
  void didUpdateWidget(AnalyzedVideoCard old) {
    super.didUpdateWidget(old);
    if (widget.videoUrl != old.videoUrl && widget.videoUrl != null) {
      _ctrl?.dispose();
      _ctrl = null;
      _initialized = false;
      _error = false;
      _initPlayer(widget.videoUrl!);
    }
  }

  Future<void> _initPlayer(String url) async {
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    _ctrl = ctrl;
    try {
      await ctrl.initialize();
      if (mounted) {
        setState(() => _initialized = true);
        // Auto-hide controls after 3 s
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showControls = false);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
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
    final pos = ctrl.value.duration * fraction;
    ctrl.seekTo(pos);
  }

  Future<void> _openFullscreen() async {
    final ctrl = _ctrl;
    if (ctrl == null || !_initialized) return;
    // Same controller → the playback position is shared, so returning from
    // fullscreen restores the exact position automatically.
    await openFullscreenVideo(context, ctrl);
    if (mounted) setState(() => _showControls = true);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          _body(context),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.rs(16, min: 14, max: 20),
        context.rs(16, min: 14, max: 20),
        context.rs(16, min: 14, max: 20),
        context.rs(10, min: 8, max: 14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.videocam_outlined,
                color: AppColors.accentCyan, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analyzed Match Video',
                style: AppTextStyles.title(color: Colors.white)
                    .copyWith(fontSize: context.sp(15, min: 13, max: 17)),
              ),
              Text(
                'AI-annotated tactical overlay',
                style: AppTextStyles.caption(color: AppColors.textMuted)
                    .copyWith(fontSize: context.sp(11, min: 10, max: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (widget.videoUrl == null) return _processingPlaceholder(context);
    if (_error) return _errorPlaceholder(context);
    if (!_initialized) return _loadingPlaceholder(context);
    return _player(context);
  }

  Widget _processingPlaceholder(BuildContext context) {
    return Container(
      height: context.rs(200, min: 160, max: 240),
      margin: EdgeInsets.fromLTRB(
        context.rs(16, min: 14, max: 20),
        0,
        context.rs(16, min: 14, max: 20),
        context.rs(16, min: 14, max: 20),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: AppColors.accentCyan.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.accentCyan.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Video processing…',
            style: AppTextStyles.body(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'The annotated video will appear here once ready',
            style: AppTextStyles.caption(color: AppColors.textMuted)
                .copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _loadingPlaceholder(BuildContext context) {
    return Container(
      height: context.rs(200, min: 160, max: 240),
      margin: EdgeInsets.fromLTRB(
        context.rs(16, min: 14, max: 20),
        0,
        context.rs(16, min: 14, max: 20),
        context.rs(16, min: 14, max: 20),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor:
              AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
          strokeWidth: 2.5,
        ),
      ),
    );
  }

  Widget _errorPlaceholder(BuildContext context) {
    return Container(
      height: context.rs(140, min: 120, max: 180),
      margin: EdgeInsets.fromLTRB(
        context.rs(16, min: 14, max: 20),
        0,
        context.rs(16, min: 14, max: 20),
        context.rs(16, min: 14, max: 20),
      ),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_outlined,
              color: AppColors.danger, size: 32),
          const SizedBox(height: 10),
          Text(
            'Could not load video',
            style: AppTextStyles.body(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {
              setState(() {
                _error = false;
                _initialized = false;
              });
              _initPlayer(widget.videoUrl!);
            },
            child: Text(
              'Retry',
              style: AppTextStyles.caption(color: AppColors.accentCyan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _player(BuildContext context) {
    final ctrl = _ctrl!;
    final aspectRatio = ctrl.value.aspectRatio;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.rs(16, min: 14, max: 20),
        0,
        context.rs(16, min: 14, max: 20),
        context.rs(16, min: 14, max: 20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: GestureDetector(
          onTap: _togglePlayPause,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
                child: VideoPlayer(ctrl),
              ),
              // Controls overlay
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Play / Pause button
                      Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            ctrl.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      // Seek bar
                      ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: ctrl,
                        builder: (_, v, __) {
                          final total = v.duration.inMilliseconds;
                          final pos = v.position.inMilliseconds;
                          final frac =
                              total > 0 ? (pos / total).clamp(0.0, 1.0) : 0.0;
                          return Padding(
                            padding:
                                const EdgeInsets.fromLTRB(12, 0, 12, 10),
                            child: Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 5),
                                    overlayShape: const RoundSliderOverlayShape(
                                        overlayRadius: 12),
                                    trackHeight: 2.5,
                                    activeTrackColor: AppColors.accentCyan,
                                    inactiveTrackColor: Colors.white
                                        .withValues(alpha: 0.3),
                                    thumbColor: AppColors.accentCyan,
                                  ),
                                  child: Slider(
                                    value: frac,
                                    onChanged: _seekTo,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _fmt(v.position),
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 11),
                                    ),
                                    Text(
                                      _fmt(v.duration),
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Fullscreen toggle (top-right), gated by the same controls fade.
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: _openFullscreen,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fullscreen_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
