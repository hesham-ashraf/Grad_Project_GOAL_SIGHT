import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ─── Mini Line Chart (CustomPainter, no external dependencies) ────────────────
class GsMiniLineChart extends StatefulWidget {
  const GsMiniLineChart({
    super.key,
    required this.data,
    this.color,
    this.height = 80,
    this.showDots = true,
    this.filled = true,
    this.delay = Duration.zero,
    this.lineWidth = 2.0,
  });

  final List<double> data;
  final Color? color;
  final double height;
  final bool showDots;
  final bool filled;
  final Duration delay;
  final double lineWidth;

  @override
  State<GsMiniLineChart> createState() => _GsMiniLineChartState();
}

class _GsMiniLineChartState extends State<GsMiniLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
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
    if (widget.data.isEmpty) return SizedBox(height: widget.height);
    final color = widget.color ?? AppColors.primaryBlue;

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => CustomPaint(
          painter: _LineChartPainter(
            data: widget.data,
            progress: _anim.value,
            color: color,
            showDots: widget.showDots,
            filled: widget.filled,
            lineWidth: widget.lineWidth,
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.data,
    required this.progress,
    required this.color,
    required this.showDots,
    required this.filled,
    required this.lineWidth,
  });

  final List<double> data;
  final double progress;
  final Color color;
  final bool showDots;
  final bool filled;
  final double lineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).abs();
    final safeRange = range == 0 ? 1.0 : range;

    final points = <Offset>[];
    final steps = data.length - 1;
    final drawCount = (steps * progress).round().clamp(0, steps);

    for (var i = 0; i <= drawCount + 1 && i < data.length; i++) {
      final x = steps == 0 ? 0.0 : (i / steps) * size.width;
      final y = size.height - ((data[i] - minVal) / safeRange) * (size.height * 0.85) - size.height * 0.05;
      points.add(Offset(x, y.clamp(0, size.height).toDouble()));
    }

    if (points.length < 2) return;

    // Interpolate last partial segment
    if (drawCount < steps) {
      final frac = (steps * progress) - drawCount;
      final prev = points[points.length - 2];
      final next = Offset(
        steps == 0 ? 0.0 : ((drawCount + 1) / steps) * size.width,
        size.height - ((data[drawCount + 1] - minVal) / safeRange) * (size.height * 0.85) - size.height * 0.05,
      );
      points[points.length - 1] = Offset(
        prev.dx + (next.dx - prev.dx) * frac,
        prev.dy + (next.dy - prev.dy) * frac,
      );
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final cp1 = Offset(
        points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 3,
        points[i - 1].dy,
      );
      final cp2 = Offset(
        points[i].dx - (points[i].dx - points[i - 1].dx) / 3,
        points[i].dy,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i].dx, points[i].dy);
    }

    if (filled) {
      final fillPath = Path.from(path)
        ..lineTo(points.last.dx, size.height)
        ..lineTo(points.first.dx, size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill,
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = lineWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (showDots) {
      for (final p in points) {
        canvas.drawCircle(p, lineWidth + 1,
            Paint()..color = color..style = PaintingStyle.fill);
        canvas.drawCircle(
          p,
          lineWidth + 1,
          Paint()
            ..color = AppColors.surface
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.progress != progress || old.data != data;
}

// ─── Dual-line comparison chart ───────────────────────────────────────────────
class GsDualLineChart extends StatefulWidget {
  const GsDualLineChart({
    super.key,
    required this.data1,
    required this.data2,
    required this.color1,
    required this.color2,
    this.height = 100,
    this.label1,
    this.label2,
  });

  final List<double> data1;
  final List<double> data2;
  final Color color1;
  final Color color2;
  final double height;
  final String? label1;
  final String? label2;

  @override
  State<GsDualLineChart> createState() => _GsDualLineChartState();
}

class _GsDualLineChartState extends State<GsDualLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label1 != null || widget.label2 != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (widget.label1 != null) ...[
                  Container(
                      width: 10, height: 3,
                      decoration: BoxDecoration(
                          color: widget.color1, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 5),
                  Text(widget.label1!,
                      style: AppTextStyles.caption(color: AppColors.textMuted)),
                  const SizedBox(width: 14),
                ],
                if (widget.label2 != null) ...[
                  Container(
                      width: 10, height: 3,
                      decoration: BoxDecoration(
                          color: widget.color2, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 5),
                  Text(widget.label2!,
                      style: AppTextStyles.caption(color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
        SizedBox(
          height: widget.height,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => CustomPaint(
              painter: _DualLinePainter(
                data1: widget.data1,
                data2: widget.data2,
                color1: widget.color1,
                color2: widget.color2,
                progress: _anim.value,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DualLinePainter extends CustomPainter {
  _DualLinePainter({
    required this.data1,
    required this.data2,
    required this.color1,
    required this.color2,
    required this.progress,
  });
  final List<double> data1;
  final List<double> data2;
  final Color color1;
  final Color color2;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    _drawLine(canvas, size, data1, color1);
    _drawLine(canvas, size, data2, color2);
  }

  void _drawLine(Canvas canvas, Size size, List<double> data, Color color) {
    if (data.length < 2) return;
    final allData = [...data1, ...data2];
    final minVal = allData.reduce((a, b) => a < b ? a : b);
    final maxVal = allData.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).abs();
    final safeRange = range == 0 ? 1.0 : range;
    final steps = data.length - 1;
    final drawCount = (steps * progress).round().clamp(0, steps);

    final points = <Offset>[];
    for (var i = 0; i <= drawCount && i < data.length; i++) {
      final x = steps == 0 ? 0.0 : (i / steps) * size.width;
      final y = size.height - ((data[i] - minVal) / safeRange) * (size.height * 0.85) - size.height * 0.05;
      points.add(Offset(x, y.clamp(0.0, size.height).toDouble()));
    }
    if (points.length < 2) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DualLinePainter old) => old.progress != progress;
}
