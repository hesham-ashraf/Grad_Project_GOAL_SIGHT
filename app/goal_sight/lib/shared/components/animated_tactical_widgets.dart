import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/animations/motion_tokens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

class GoalSightAnimatedPossessionBar extends StatelessWidget {
  const GoalSightAnimatedPossessionBar({
    super.key,
    required this.homeLabel,
    required this.awayLabel,
    required this.homeValue,
    required this.awayValue,
    this.homeColor = AppColors.accentCyan,
    this.awayColor = AppColors.primaryPurple,
  });

  final String homeLabel;
  final String awayLabel;
  final int homeValue;
  final int awayValue;
  final Color homeColor;
  final Color awayColor;

  @override
  Widget build(BuildContext context) {
    final total = (homeValue + awayValue).clamp(1, 200).toDouble();
    final homeTarget = homeValue / total;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: homeTarget),
      duration: GoalSightMotion.slow,
      curve: GoalSightMotion.entrance,
      builder: (context, value, _) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$homeLabel $homeValue%',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(color: homeColor).copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(
                  child: Text(
                    '$awayValue% $awayLabel',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(color: awayColor).copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.rs(8, min: 6, max: 10)),
            ClipRRect(
              borderRadius: AppRadius.chip,
              child: SizedBox(
                height: context.rs(10, min: 8, max: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: (value * 1000).round().clamp(1, 999).toInt(),
                      child: DecoratedBox(decoration: BoxDecoration(color: homeColor)),
                    ),
                    Expanded(
                      flex: ((1 - value) * 1000).round().clamp(1, 999).toInt(),
                      child: DecoratedBox(decoration: BoxDecoration(color: awayColor)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class GoalSightMomentumChart extends StatelessWidget {
  const GoalSightMomentumChart({
    super.key,
    required this.values,
    this.positiveColor = AppColors.accentGreen,
    this.negativeColor = AppColors.danger,
  });

  final List<double> values;
  final Color positiveColor;
  final Color negativeColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: GoalSightMotion.slow,
      curve: GoalSightMotion.entrance,
      builder: (context, progress, _) {
        return CustomPaint(
          painter: _MomentumPainter(
            values: values,
            progress: progress,
            positiveColor: positiveColor,
            negativeColor: negativeColor,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class GoalSightPressureIndicator extends StatelessWidget {
  const GoalSightPressureIndicator({
    super.key,
    required this.value,
    this.label = 'Pressure',
    this.color = AppColors.warning,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100).toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: clamped / 100),
      duration: GoalSightMotion.slow,
      curve: GoalSightMotion.entrance,
      builder: (context, progress, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label, style: AppTextStyles.caption(color: AppColors.textMuted)),
                const Spacer(),
                Text('${(progress * 100).round()}%', style: AppTextStyles.button(color: color)),
              ],
            ),
            SizedBox(height: context.rs(8, min: 6, max: 10)),
            Stack(
              children: [
                Container(
                  height: context.rs(12, min: 9, max: 14),
                  decoration: BoxDecoration(
                    color: AppColors.outlineSubtle,
                    borderRadius: AppRadius.chip,
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: context.rs(12, min: 9, max: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.55), color],
                      ),
                      borderRadius: AppRadius.chip,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.22),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class GoalSightAttackZoneMap extends StatelessWidget {
  const GoalSightAttackZoneMap({
    super.key,
    required this.left,
    required this.center,
    required this.right,
    this.color = AppColors.accentCyan,
  });

  final int left;
  final int center;
  final int right;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final values = [left, center, right];
    final maxValue = values.reduce(math.max).clamp(1, 100).toDouble();
    final labels = ['Left', 'Central', 'Right'];

    return AspectRatio(
      aspectRatio: context.isPhone ? 1.9 : 2.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.64),
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.outlineSubtle),
        ),
        child: Padding(
          padding: EdgeInsets.all(context.rs(12, min: 10, max: 16)),
          child: Row(
            children: [
              for (var i = 0; i < values.length; i++) ...[
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: values[i] / maxValue),
                    duration: Duration(milliseconds: 520 + (i * 90)),
                    curve: GoalSightMotion.entrance,
                    builder: (context, progress, _) {
                      return Container(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.05 + (progress * 0.22)),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: color.withValues(alpha: 0.12 + (progress * 0.22)),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(values[i] * progress).round()}%',
                              style: AppTextStyles.title(color: color).copyWith(
                                fontSize: context.sp(18, min: 14, max: 24),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              labels[i],
                              style: AppTextStyles.caption(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (i != values.length - 1) SizedBox(width: context.rs(8, min: 6, max: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GoalSightTacticalRadar extends StatelessWidget {
  const GoalSightTacticalRadar({
    super.key,
    required this.values,
    required this.labels,
    this.color = AppColors.accentCyan,
  }) : assert(values.length == labels.length);

  final List<double> values;
  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: GoalSightMotion.slow,
      curve: GoalSightMotion.entrance,
      builder: (context, progress, _) {
        return CustomPaint(
          painter: _RadarPainter(
            values: values,
            labels: labels,
            color: color,
            progress: progress,
            textStyle: AppTextStyles.caption(color: AppColors.textMuted),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _MomentumPainter extends CustomPainter {
  const _MomentumPainter({
    required this.values,
    required this.progress,
    required this.positiveColor,
    required this.negativeColor,
  });

  final List<double> values;
  final double progress;
  final Color positiveColor;
  final Color negativeColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final centerY = size.height / 2;
    final visibleCount =
        (values.length * progress).ceil().clamp(1, values.length).toInt();
    final barWidth = size.width / values.length;
    final axisPaint = Paint()
      ..color = AppColors.outlineSubtle
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), axisPaint);

    for (var i = 0; i < visibleCount; i++) {
      final value = values[i].clamp(-1.0, 1.0).toDouble();
      final height = (size.height / 2 - 6) * value.abs();
      final rect = Rect.fromLTWH(
        i * barWidth + 2,
        value >= 0 ? centerY - height : centerY,
        barWidth - 4,
        height,
      );
      final paint = Paint()
        ..color = (value >= 0 ? positiveColor : negativeColor)
            .withValues(alpha: 0.72);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MomentumPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.progress != progress;
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({
    required this.values,
    required this.labels,
    required this.color,
    required this.progress,
    required this.textStyle,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final double progress;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 3) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.34;
    final sides = values.length;
    final gridPaint = Paint()
      ..color = AppColors.outlineSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var ring = 1; ring <= 4; ring++) {
      final path = Path();
      final ringRadius = radius * ring / 4;
      for (var i = 0; i < sides; i++) {
        final point = _radarPoint(center, ringRadius, i, sides);
        i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final valuePath = Path();
    for (var i = 0; i < sides; i++) {
      final valueRadius =
          radius * values[i].clamp(0.0, 1.0).toDouble() * progress;
      final point = _radarPoint(center, valueRadius, i, sides);
      i == 0 ? valuePath.moveTo(point.dx, point.dy) : valuePath.lineTo(point.dx, point.dy);
    }
    valuePath.close();
    canvas.drawPath(valuePath, fillPaint);
    canvas.drawPath(valuePath, linePaint);

    for (var i = 0; i < sides; i++) {
      final point = _radarPoint(center, radius + 18, i, sides);
      final painter = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle.copyWith(fontSize: 10)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: 76);
      painter.paint(
        canvas,
        Offset(point.dx - painter.width / 2, point.dy - painter.height / 2),
      );
    }
  }

  Offset _radarPoint(Offset center, double radius, int index, int total) {
    final angle = (math.pi * 2 * index / total) - math.pi / 2;
    return Offset(center.dx + math.cos(angle) * radius, center.dy + math.sin(angle) * radius);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.progress != progress;
  }
}
