import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ─── Football Pitch Painter ────────────────────────────────────────────────────
class GsPitchWidget extends StatelessWidget {
  const GsPitchWidget({
    super.key,
    this.width,
    this.height,
    this.heatmapData,
    this.playerPositions,
    this.attackArrows,
    this.showZones = false,
    this.highlightZone,
    this.pitchColor,
    this.lineColor,
  });

  final double? width;
  final double? height;

  /// Heatmap: list of (x, y, intensity) where x/y are 0.0–1.0 normalized.
  final List<HeatmapPoint>? heatmapData;

  /// Player dots: list of (x, y, label, color).
  final List<PitchPlayer>? playerPositions;

  /// Attack arrows: list of (startX, startY, endX, endY).
  final List<PitchArrow>? attackArrows;

  final bool showZones;
  final int? highlightZone; // 0=left, 1=center, 2=right

  final Color? pitchColor;
  final Color? lineColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = width ?? constraints.maxWidth;
        final h = height ?? w * 0.65;

        return SizedBox(
          width: w,
          height: h,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(
              painter: _PitchPainter(
                heatmapData: heatmapData,
                playerPositions: playerPositions,
                attackArrows: attackArrows,
                showZones: showZones,
                highlightZone: highlightZone,
                pitchColor: pitchColor ?? const Color(0xFF0D2D0D),
                lineColor: lineColor ?? const Color(0xFF2A5A2A),
              ),
            ),
          ),
        );
      },
    );
  }
}

class HeatmapPoint {
  const HeatmapPoint(this.x, this.y, this.intensity);
  final double x; // 0.0–1.0
  final double y; // 0.0–1.0
  final double intensity; // 0.0–1.0

  @override
  String toString() => 'HeatmapPoint($x, $y, $intensity)';
}

class PitchPlayer {
  const PitchPlayer(this.x, this.y, this.label, {this.color = AppColors.accentCyan});
  final double x; // 0.0–1.0
  final double y; // 0.0–1.0
  final String label;
  final Color color;
}

class PitchArrow {
  const PitchArrow(this.x1, this.y1, this.x2, this.y2, {this.color = AppColors.accentGreen});
  final double x1, y1, x2, y2;
  final Color color;
}

class _PitchPainter extends CustomPainter {
  _PitchPainter({
    required this.pitchColor,
    required this.lineColor,
    this.heatmapData,
    this.playerPositions,
    this.attackArrows,
    this.showZones = false,
    this.highlightZone,
  });

  final Color pitchColor;
  final Color lineColor;
  final List<HeatmapPoint>? heatmapData;
  final List<PitchPlayer>? playerPositions;
  final List<PitchArrow>? attackArrows;
  final bool showZones;
  final int? highlightZone;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = pitchColor,
    );

    // Stripe pattern (subtle)
    final stripePaint = Paint()..color = lineColor.withValues(alpha: 0.08);
    final stripeWidth = w / 10;
    for (var i = 0; i < 10; i += 2) {
      canvas.drawRect(Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, h), stripePaint);
    }

    // Draw heatmap
    if (heatmapData != null && heatmapData!.isNotEmpty) {
      for (final pt in heatmapData!) {
        final cx = pt.x * w;
        final cy = pt.y * h;
        final radius = w * 0.12 * pt.intensity;
        final paint = Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.accentCyan.withValues(alpha: pt.intensity * 0.55),
              AppColors.primaryPurple.withValues(alpha: pt.intensity * 0.35),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(
              Rect.fromCircle(center: Offset(cx, cy), radius: radius));
        canvas.drawCircle(Offset(cx, cy), radius, paint);
      }
    }

    // Zone highlights
    if (showZones) {
      final zoneW = w / 3;
      final zones = [
        Rect.fromLTWH(0, 0, zoneW, h),
        Rect.fromLTWH(zoneW, 0, zoneW, h),
        Rect.fromLTWH(zoneW * 2, 0, zoneW, h),
      ];
      for (var i = 0; i < 3; i++) {
        final isHighlit = highlightZone == i;
        canvas.drawRect(
          zones[i],
          Paint()
            ..color = isHighlit
                ? AppColors.accentCyan.withValues(alpha: 0.15)
                : Colors.transparent,
        );
      }
      final dividerPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.3)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(zoneW, 0), Offset(zoneW, h), dividerPaint);
      canvas.drawLine(Offset(zoneW * 2, 0), Offset(zoneW * 2, h), dividerPaint);
    }

    // Pitch lines
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Outline
    canvas.drawRect(Rect.fromLTWH(2, 2, w - 4, h - 4), linePaint);

    // Halfway line
    canvas.drawLine(Offset(w / 2, 2), Offset(w / 2, h - 2), linePaint);

    // Centre circle
    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.22, linePaint);
    canvas.drawCircle(Offset(w / 2, h / 2), 2.5, Paint()..color = lineColor);

    // Left penalty area
    final lBoxW = w * 0.15, lBoxH = h * 0.55;
    canvas.drawRect(
      Rect.fromLTWH(2, (h - lBoxH) / 2, lBoxW, lBoxH),
      linePaint,
    );
    // Left goal area
    final lGBoxW = w * 0.065, lGBoxH = h * 0.28;
    canvas.drawRect(
      Rect.fromLTWH(2, (h - lGBoxH) / 2, lGBoxW, lGBoxH),
      linePaint,
    );

    // Right penalty area
    canvas.drawRect(
      Rect.fromLTWH(w - lBoxW - 2, (h - lBoxH) / 2, lBoxW, lBoxH),
      linePaint,
    );
    // Right goal area
    canvas.drawRect(
      Rect.fromLTWH(w - lGBoxW - 2, (h - lGBoxH) / 2, lGBoxW, lGBoxH),
      linePaint,
    );

    // Penalty spots
    canvas.drawCircle(Offset(w * 0.12, h / 2), 2.5, Paint()..color = lineColor);
    canvas.drawCircle(Offset(w * 0.88, h / 2), 2.5, Paint()..color = lineColor);

    // Draw attack arrows
    if (attackArrows != null) {
      for (final arrow in attackArrows!) {
        _drawArrow(
          canvas,
          Offset(arrow.x1 * w, arrow.y1 * h),
          Offset(arrow.x2 * w, arrow.y2 * h),
          arrow.color,
        );
      }
    }

    // Draw player positions
    if (playerPositions != null) {
      for (final player in playerPositions!) {
        final pos = Offset(player.x * w, player.y * h);
        final r = w * 0.032;
        canvas.drawCircle(
          pos,
          r,
          Paint()
            ..color = player.color
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          pos,
          r,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        // Label
        final tp = TextPainter(
          text: TextSpan(
            text: player.label,
            style: const TextStyle(
                color: Colors.white, fontSize: 7, fontWeight: FontWeight.w700),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, pos.translate(-tp.width / 2, -tp.height / 2));
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, paint);

    // Arrowhead
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final lenSq = dx * dx + dy * dy;
    final len = lenSq == 0.0 ? 1.0 : lenSq;
    final ux = dx / len * 8;
    final uy = dy / len * 8;
    canvas.drawLine(end, Offset(end.dx - ux - uy * 0.5, end.dy - uy + ux * 0.5),
        paint..strokeWidth = 1.5);
    canvas.drawLine(end, Offset(end.dx - ux + uy * 0.5, end.dy - uy - ux * 0.5),
        paint..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_PitchPainter old) => false;
}

// ─── Radar / Spider Chart ────────────────────────────────────────────────────
class GsRadarChart extends StatefulWidget {
  const GsRadarChart({
    super.key,
    required this.labels,
    required this.values,
    required this.color,
    this.size = 160,
    this.delay = Duration.zero,
  });

  final List<String> labels;
  final List<double> values; // 0.0–1.0
  final Color color;
  final double size;
  final Duration delay;

  @override
  State<GsRadarChart> createState() => _GsRadarChartState();
}

class _GsRadarChartState extends State<GsRadarChart>
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
        builder: (_, __) => CustomPaint(
          painter: _RadarPainter(
            labels: widget.labels,
            values: widget.values,
            color: widget.color,
            progress: _anim.value,
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.labels,
    required this.values,
    required this.color,
    required this.progress,
  });

  final List<String> labels;
  final List<double> values;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (labels.isEmpty) return;
    final n = labels.length;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.72;
    const twoPi = 2 * 3.14159265;
    final angleStep = twoPi / n;

    // Grid rings
    for (var ring = 1; ring <= 4; ring++) {
      final ringR = radius * ring / 4;
      final pts = List.generate(n, (i) {
        final a = -3.14159265 / 2 + i * angleStep;
        return Offset(center.dx + ringR * _cos(a), center.dy + ringR * _sin(a));
      });
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path,
          Paint()
            ..color = color.withValues(alpha: 0.08)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8);
    }

    // Axis lines
    for (var i = 0; i < n; i++) {
      final a = -3.14159265 / 2 + i * angleStep;
      canvas.drawLine(
          center,
          Offset(center.dx + radius * _cos(a), center.dy + radius * _sin(a)),
          Paint()
            ..color = color.withValues(alpha: 0.12)
            ..strokeWidth = 0.8);
    }

    // Data polygon
    final dataPts = List.generate(n, (i) {
      final a = -3.14159265 / 2 + i * angleStep;
      final r = radius * values[i].clamp(0.0, 1.0) * progress;
      return Offset(center.dx + r * _cos(a), center.dy + r * _sin(a));
    });

    final dataPath = Path()..moveTo(dataPts.first.dx, dataPts.first.dy);
    for (final p in dataPts.skip(1)) {
      dataPath.lineTo(p.dx, p.dy);
    }
    dataPath.close();

    canvas.drawPath(
        dataPath,
        Paint()
          ..color = color.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        dataPath,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Labels
    for (var i = 0; i < n; i++) {
      final a = -3.14159265 / 2 + i * angleStep;
      final r = radius + 14;
      final lx = center.dx + r * _cos(a);
      final ly = center.dy + r * _sin(a);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
              color: color.withValues(alpha: 0.75), fontSize: 8, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }
  }

  double _cos(double a) => a == 0
      ? 1.0
      : (a == 3.14159265 ? -1.0 : (a == 3.14159265 / 2 ? 0.0 : _fastCos(a)));
  double _sin(double a) => _fastSin(a);

  double _fastCos(double a) {
    const pi = 3.14159265;
    double x = a % (2 * pi);
    if (x < 0) x += 2 * pi;
    // Taylor approximation
    double sum = 1, term = 1;
    for (var i = 1; i <= 8; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      sum += term;
    }
    return sum;
  }

  double _fastSin(double a) {
    const pi = 3.14159265;
    double x = a % (2 * pi);
    if (x < 0) x += 2 * pi;
    double sum = x, term = x;
    for (var i = 1; i <= 8; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      sum += term;
    }
    return sum;
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.progress != progress;
}
