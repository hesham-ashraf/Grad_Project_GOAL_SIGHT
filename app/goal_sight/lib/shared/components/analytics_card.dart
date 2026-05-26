import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import 'glass_container.dart';
import 'stat_widgets.dart';

enum GoalSightAnalyticsCardSize { compact, regular, expanded }

class GoalSightAnalyticsCard extends StatelessWidget {
  const GoalSightAnalyticsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.unit = '',
    this.decimals = 0,
    this.icon = Icons.analytics_rounded,
    this.color = AppColors.accentCyan,
    this.trend = GoalSightTrend.flat,
    this.size = GoalSightAnalyticsCardSize.regular,
    this.chart,
    this.footer,
    this.expandable = false,
    this.onTap,
  });

  final String title;
  final double value;
  final String? subtitle;
  final String unit;
  final int decimals;
  final IconData icon;
  final Color color;
  final GoalSightTrend trend;
  final GoalSightAnalyticsCardSize size;
  final Widget? chart;
  final Widget? footer;
  final bool expandable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final compact = size == GoalSightAnalyticsCardSize.compact;
    final expanded = size == GoalSightAnalyticsCardSize.expanded;

    return GoalSightGradientBorder(
      gradient: LinearGradient(
        colors: [
          color.withValues(alpha: 0.75),
          AppColors.primaryPurple.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.04),
        ],
      ),
      radius: AppRadius.xl,
      child: GoalSightGlass(
        onTap: onTap,
        opacity: 0.82,
        blur: 16,
        shadow: expanded ? GoalSightGlassShadow.glow : GoalSightGlassShadow.soft,
        padding: EdgeInsets.all(context.rs(compact ? 13 : 17, min: 12, max: 22)),
        borderColor: color.withValues(alpha: 0.12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.11),
            AppColors.surfaceElevated.withValues(alpha: 0.88),
            AppColors.surface.withValues(alpha: 0.72),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: context.rs(compact ? 32 : 40, min: 30, max: 44),
                  height: context.rs(compact ? 32 : 40, min: 30, max: 44),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: color.withValues(alpha: 0.26)),
                  ),
                  child: Icon(icon, color: color, size: context.rs(18, min: 15, max: 21)),
                ),
                SizedBox(width: context.rs(10, min: 8, max: 12)),
                Expanded(
                  child: Text(
                    title,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(color: AppColors.textPrimary).copyWith(
                      fontSize: context.sp(compact ? 12 : 14, min: 11, max: 16),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (expandable)
                  Icon(
                    Icons.expand_more_rounded,
                    color: AppColors.textMuted,
                    size: context.rs(20, min: 18, max: 22),
                  ),
              ],
            ),
            SizedBox(height: context.rs(compact ? 12 : 16, min: 10, max: 20)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AnimatedStatValue(
                    value: value,
                    suffix: unit,
                    decimals: decimals,
                    style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
                      fontSize: context.sp(compact ? 24 : 32, min: 21, max: 38),
                      height: 0.92,
                    ),
                  ),
                ),
                _AnalyticsTrendChip(trend: trend, color: color),
              ],
            ),
            if (subtitle != null) ...[
              SizedBox(height: context.rs(7, min: 5, max: 9)),
              Text(
                subtitle!,
                maxLines: expanded ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(color: AppColors.textMuted),
              ),
            ],
            if (chart != null && !compact) ...[
              SizedBox(height: context.rs(14, min: 10, max: 18)),
              chart!,
            ],
            if (footer != null) ...[
              SizedBox(height: context.rs(14, min: 10, max: 18)),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class GoalSightMiniSparkline extends StatelessWidget {
  const GoalSightMiniSparkline({
    super.key,
    required this.values,
    this.color = AppColors.accentCyan,
    this.height = 36,
  });

  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.rs(height, min: 28, max: 54),
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(values: values, color: color),
      ),
    );
  }
}

class _AnalyticsTrendChip extends StatelessWidget {
  const _AnalyticsTrendChip({required this.trend, required this.color});

  final GoalSightTrend trend;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = switch (trend) {
      GoalSightTrend.up => Icons.arrow_upward_rounded,
      GoalSightTrend.down => Icons.arrow_downward_rounded,
      GoalSightTrend.flat => Icons.remove_rounded,
    };
    final label = switch (trend) {
      GoalSightTrend.up => 'UP',
      GoalSightTrend.down => 'DOWN',
      GoalSightTrend.flat => 'STABLE',
    };
    final tint = trend == GoalSightTrend.down ? AppColors.danger : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: AppRadius.chip,
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: tint, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption(color: tint).copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs() < 0.001 ? 1 : max - min;
    final path = Path();

    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - (((values[i] - min) / range) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: 0.12);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.45), color],
      ).createShader(Offset.zero & size);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
