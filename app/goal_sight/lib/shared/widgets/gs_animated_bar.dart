import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

// ─── Animated Stat Bar ────────────────────────────────────────────────────────
/// A horizontal progress bar that animates its fill on first render.
class GsAnimatedBar extends StatefulWidget {
  const GsAnimatedBar({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.height,
    this.label,
    this.valueLabel,
    this.showLabel = false,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 900),
  });

  final double value; // 0.0 – 1.0
  final Color? color;
  final Color? backgroundColor;
  final double? height;
  final String? label;
  final String? valueLabel;
  final bool showLabel;
  final Duration delay;
  final Duration duration;

  @override
  State<GsAnimatedBar> createState() => _GsAnimatedBarState();
}

class _GsAnimatedBarState extends State<GsAnimatedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
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
    final barHeight = widget.height ?? context.rs(6, min: 5, max: 8);
    final color = widget.color ?? AppColors.primaryBlue;
    final bg = widget.backgroundColor ?? AppColors.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel && (widget.label != null || widget.valueLabel != null)) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.label != null)
                Text(widget.label!,
                    style: AppTextStyles.caption(color: AppColors.textSecondary)),
              if (widget.valueLabel != null)
                Text(widget.valueLabel!,
                    style: AppTextStyles.caption(color: color)
                        .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 5),
        ],
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(barHeight),
              child: Stack(
                children: [
                  Container(height: barHeight, color: bg),
                  FractionallySizedBox(
                    widthFactor: (_anim.value * widget.value).clamp(0.0, 1.0),
                    child: Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withValues(alpha: 0.7), color],
                        ),
                        borderRadius: BorderRadius.circular(barHeight),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Dual-team comparison bar ─────────────────────────────────────────────────
class GsDualBar extends StatefulWidget {
  const GsDualBar({
    super.key,
    required this.leftPct,
    required this.rightPct,
    required this.leftColor,
    required this.rightColor,
    this.height,
    this.delay = Duration.zero,
  });

  final int leftPct;
  final int rightPct;
  final Color leftColor;
  final Color rightColor;
  final double? height;
  final Duration delay;

  @override
  State<GsDualBar> createState() => _GsDualBarState();
}

class _GsDualBarState extends State<GsDualBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
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
    final h = widget.height ?? context.rs(8, min: 6, max: 10);
    final total = widget.leftPct + widget.rightPct;
    final lFrac = total == 0 ? 0.5 : widget.leftPct / total;
    final rFrac = 1.0 - lFrac;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(h),
          child: Row(
            children: [
              Flexible(
                flex: (lFrac * _anim.value * 100).round().clamp(1, 100),
                child: Container(
                  height: h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.leftColor, widget.leftColor.withValues(alpha: 0.8)],
                    ),
                  ),
                ),
              ),
              Flexible(
                flex: (rFrac * _anim.value * 100).round().clamp(1, 100),
                child: Container(
                  height: h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.rightColor.withValues(alpha: 0.8), widget.rightColor],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Animated Counter ─────────────────────────────────────────────────────────
class GsAnimatedCounter extends StatefulWidget {
  const GsAnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 1200),
  });

  final double value;
  final TextStyle style;
  final String prefix;
  final String suffix;
  final int decimals;
  final Duration delay;
  final Duration duration;

  @override
  State<GsAnimatedCounter> createState() => _GsAnimatedCounterState();
}

class _GsAnimatedCounterState extends State<GsAnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
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
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final val = _anim.value.toStringAsFixed(widget.decimals);
        return Text('${widget.prefix}$val${widget.suffix}', style: widget.style);
      },
    );
  }
}

// ─── Circular Stat Ring ───────────────────────────────────────────────────────
class GsStatRing extends StatefulWidget {
  const GsStatRing({
    super.key,
    required this.value,
    required this.color,
    required this.size,
    this.strokeWidth = 5,
    this.label,
    this.delay = Duration.zero,
  });

  final double value; // 0.0–1.0
  final Color color;
  final double size;
  final double strokeWidth;
  final String? label;
  final Duration delay;

  @override
  State<GsStatRing> createState() => _GsStatRingState();
}

class _GsStatRingState extends State<GsStatRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
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
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          return CustomPaint(
            painter: _RingPainter(
              value: _anim.value * widget.value,
              color: widget.color,
              strokeWidth: widget.strokeWidth,
            ),
            child: Center(
              child: Text(
                '${(_anim.value * widget.value * 100).round()}%',
                style: AppTextStyles.caption(color: widget.color)
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 10),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.color, required this.strokeWidth});
  final double value;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -1.5708, 6.2832, false, bgPaint);

    if (value > 0) {
      final paint = Paint()
        ..shader = SweepGradient(
          startAngle: -1.5708,
          endAngle: -1.5708 + 6.2832 * value,
          colors: [color.withValues(alpha: 0.7), color],
        ).createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, -1.5708, 6.2832 * value, false, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}
