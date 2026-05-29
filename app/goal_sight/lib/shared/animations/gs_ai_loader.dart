// ---------------------------------------------------------------------------
// GoalSight — GsAiLoader
//
// Futuristic AI loading system with three components:
//
//   1. GsAiLoader      — full-screen AI processing overlay
//   2. GsAiStageCard   — compact stage progress card (for upload flow)
//   3. GsInsightReveal — staggered AI insight reveal animation
//
// Design: pulsing rings, neural scan lines, stage timeline,
//         and holographic text to evoke AI intelligence in motion.
// ---------------------------------------------------------------------------

import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/animations/motion_tokens.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/upload_job_model.dart';

// ═════════════════════════════════════════════════════════════════════════════
// 1. GsAiLoader — full-screen AI processing overlay
// ═════════════════════════════════════════════════════════════════════════════

class GsAiLoader extends StatefulWidget {
  const GsAiLoader({
    super.key,
    this.title = 'AI Processing',
    this.subtitle = 'GoalSight Intelligence is analysing the footage',
    this.progress,
    this.stage,
    this.showStages = false,
  });

  final String title;
  final String subtitle;

  /// Optional progress (0–1). If null, indeterminate animation.
  final double? progress;

  /// Current processing stage
  final ProcessingStage? stage;

  /// Whether to show all stage chips
  final bool showStages;

  @override
  State<GsAiLoader> createState() => _GsAiLoaderState();
}

class _GsAiLoaderState extends State<GsAiLoader>
    with TickerProviderStateMixin {
  late final AnimationController _ringCtrl;
  late final AnimationController _scanCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _textCtrl;

  late final Animation<double> _ring1;
  late final Animation<double> _ring2;
  late final Animation<double> _scan;
  late final Animation<double> _pulse;
  late final Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: GoalSightMotion.pulse)
      ..repeat(reverse: true);
    _textCtrl = AnimationController(vsync: this, duration: GoalSightMotion.normal)
      ..forward();

    _ring1 = CurvedAnimation(parent: _ringCtrl, curve: Curves.linear);
    _ring2 = CurvedAnimation(
      parent: _ringCtrl,
      curve: const Interval(0.25, 1.25, curve: Curves.linear),
    );
    _scan = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut),
    );
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.95),
      child: FadeTransition(
        opacity: _textFade,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Animated ring orb ────────────────────────────────────────
            ScaleTransition(
              scale: _pulse,
              child: SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer rotating ring
                    AnimatedBuilder(
                      animation: _ring1,
                      builder: (_, __) => Transform.rotate(
                        angle: _ring1.value * 2 * pi,
                        child: const CustomPaint(
                          size: Size(160, 160),
                          painter: _RingPainter(
                            color: AppColors.accentCyan,
                            strokeWidth: 2,
                            dashCount: 12,
                          ),
                        ),
                      ),
                    ),
                    // Inner counter-rotating ring
                    AnimatedBuilder(
                      animation: _ring2,
                      builder: (_, __) => Transform.rotate(
                        angle: -_ring2.value * 2 * pi,
                        child: const CustomPaint(
                          size: Size(110, 110),
                          painter: _RingPainter(
                            color: AppColors.primaryPurple,
                            strokeWidth: 1.5,
                            dashCount: 8,
                          ),
                        ),
                      ),
                    ),
                    // Scan line
                    AnimatedBuilder(
                      animation: _scan,
                      builder: (_, __) => ClipOval(
                        child: SizedBox(
                          width: 90,
                          height: 90,
                          child: CustomPaint(
                            painter: _ScanLinePainter(
                              progress: _scan.value,
                              color: AppColors.accentCyan,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Core glow
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primaryPurple.withValues(alpha: 0.6),
                            AppColors.accentCyan.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.accentCyan,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 36),

            // ── Title ────────────────────────────────────────────────────
            Text(
              widget.title,
              style: AppTextStyles.headline(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: AppTextStyles.caption(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),

            // ── Progress bar ─────────────────────────────────────────────
            if (widget.progress != null) ...[
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: _GsProgressBar(progress: widget.progress!),
              ),
              const SizedBox(height: 12),
              Text(
                '${(widget.progress! * 100).toInt()}%',
                style: AppTextStyles.caption(color: AppColors.accentCyan),
              ),
            ] else ...[
              const SizedBox(height: 28),
              _GsDotLoader(),
            ],

            // ── Current stage ─────────────────────────────────────────────
            if (widget.stage != null) ...[
              const SizedBox(height: 20),
              _GsCurrentStageChip(stage: widget.stage!),
            ],

            // ── Stage list ────────────────────────────────────────────────
            if (widget.showStages && widget.stage != null) ...[
              const SizedBox(height: 24),
              _GsStageTimeline(currentStage: widget.stage!),
            ],
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 2. GsAiStageCard — compact inline stage card (for upload flow)
// ═════════════════════════════════════════════════════════════════════════════

class GsAiStageCard extends StatefulWidget {
  const GsAiStageCard({
    super.key,
    required this.stage,
    required this.progress,
  });

  final ProcessingStage stage;
  final double progress; // 0–1

  @override
  State<GsAiStageCard> createState() => _GsAiStageCardState();
}

class _GsAiStageCardState extends State<GsAiStageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: GoalSightMotion.pulse)
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: stage.color.withValues(alpha: 0.2 + 0.1 * _pulse.value),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stage.color.withValues(alpha: 0.12 + 0.06 * _pulse.value),
                  ),
                  child: Icon(stage.icon, color: stage.color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.label,
                        style: AppTextStyles.body(color: AppColors.textPrimary),
                      ),
                      Text(
                        stage.description,
                        style: AppTextStyles.caption(color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(widget.progress * 100).toInt()}%',
                  style: AppTextStyles.caption(color: stage.color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: AppRadius.button,
              child: LinearProgressIndicator(
                value: widget.progress,
                backgroundColor: stage.color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(stage.color),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 3. GsInsightReveal — staggered AI insight list reveal
// ═════════════════════════════════════════════════════════════════════════════

class GsInsightReveal extends StatefulWidget {
  const GsInsightReveal({
    super.key,
    required this.insights,
    this.accentColor = AppColors.accentCyan,
    this.delay = Duration.zero,
    this.icon = Icons.psychology_alt_rounded,
  });

  final List<String> insights;
  final Color accentColor;
  final Duration delay;
  final IconData icon;

  @override
  State<GsInsightReveal> createState() => _GsInsightRevealState();
}

class _GsInsightRevealState extends State<GsInsightReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();
    final n = widget.insights.length;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + n * 140),
    );

    _fades = List.generate(n, (i) {
      final start = (0.08 + i * 0.14).clamp(0.0, 0.9);
      final end = (start + 0.25).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _slides = _fades
        .map((f) => Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(f))
        .toList();

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.insights.length, (i) {
        return FadeTransition(
          opacity: _fades[i],
          child: SlideTransition(
            position: _slides[i],
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(top: 2, right: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.accentColor.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.accentColor,
                      size: 14,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.insights[i],
                      style: AppTextStyles.body(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal supporting widgets
// ─────────────────────────────────────────────────────────────────────────────

class _GsProgressBar extends StatelessWidget {
  const _GsProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.button,
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: AppColors.accentCyan.withValues(alpha: 0.12),
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
        minHeight: 6,
      ),
    );
  }
}

class _GsDotLoader extends StatefulWidget {
  @override
  State<_GsDotLoader> createState() => _GsDotLoaderState();
}

class _GsDotLoaderState extends State<_GsDotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final opacity = (sin(phase * pi)).clamp(0.0, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentCyan.withValues(alpha: 0.2 + 0.8 * opacity),
              ),
            );
          }),
        );
      },
    );
  }
}

class _GsCurrentStageChip extends StatelessWidget {
  const _GsCurrentStageChip({required this.stage});
  final ProcessingStage stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: stage.color.withValues(alpha: 0.12),
        borderRadius: AppRadius.chip,
        border: Border.all(color: stage.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stage.icon, color: stage.color, size: 16),
          const SizedBox(width: 8),
          Text(stage.label, style: AppTextStyles.caption(color: stage.color)),
        ],
      ),
    );
  }
}

class _GsStageTimeline extends StatelessWidget {
  const _GsStageTimeline({required this.currentStage});
  final ProcessingStage currentStage;

  @override
  Widget build(BuildContext context) {
    const stages = ProcessingStage.values;
    final currentIdx = stages.indexOf(currentStage);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: stages.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final isDone = i < currentIdx;
          final isCurrent = i == currentIdx;
          final color = isDone
              ? AppColors.accentGreen
              : isCurrent
                  ? s.color
                  : AppColors.textMuted.withValues(alpha: 0.3);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.15),
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: isDone
                      ? Icon(Icons.check_rounded, color: color, size: 11)
                      : isCurrent
                          ? Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            )
                          : null,
                ),
                const SizedBox(width: 12),
                Text(
                  s.label,
                  style: AppTextStyles.caption(
                    color: isCurrent ? color : AppColors.textMuted,
                  ),
                ),
                if (isCurrent) ...[
                  const Spacer(),
                  const _PulsingDot(),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: GoalSightMotion.pulse)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accentCyan.withValues(alpha: 0.4 + 0.6 * _ctrl.value),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom painters
// ─────────────────────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashCount,
  });

  final Color color;
  final double strokeWidth;
  final int dashCount;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;
    final dashAngle = (pi * 2) / (dashCount * 2);

    for (int i = 0; i < dashCount; i++) {
      final start = i * dashAngle * 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        dashAngle * 0.7,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}

class _ScanLinePainter extends CustomPainter {
  const _ScanLinePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0 || progress > 1) return;

    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          color.withValues(alpha: 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y - 1, size.width, 2));

    canvas.drawRect(Rect.fromLTWH(0, y - 1, size.width, 2), paint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.progress != progress;
}
