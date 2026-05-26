import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import 'glass_container.dart';

enum GoalSightTrend { up, down, flat }

class AnimatedStatValue extends StatelessWidget {
  const AnimatedStatValue({
    super.key,
    required this.value,
    this.suffix = '',
    this.prefix = '',
    this.decimals = 0,
    this.style,
    this.duration = const Duration(milliseconds: 850),
  });

  final double value;
  final String suffix;
  final String prefix;
  final int decimals;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return Text(
          '$prefix${animated.toStringAsFixed(decimals)}$suffix',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style ??
              AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
                fontSize: context.sp(28, min: 22, max: 34),
                height: 1,
              ),
        );
      },
    );
  }
}

class GoalSightStatTile extends StatelessWidget {
  const GoalSightStatTile({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.color = AppColors.accentCyan,
    this.suffix = '',
    this.decimals = 0,
    this.trend = GoalSightTrend.flat,
    this.compact = false,
  });

  final String label;
  final double value;
  final String? subtitle;
  final IconData? icon;
  final Color color;
  final String suffix;
  final int decimals;
  final GoalSightTrend trend;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GoalSightGlass(
      opacity: 0.72,
      padding: EdgeInsets.all(context.rs(compact ? 13 : 16, min: 11, max: 20)),
      borderColor: color.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  width: context.rs(compact ? 32 : 38, min: 30, max: 42),
                  height: context.rs(compact ? 32 : 38, min: 30, max: 42),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: color.withValues(alpha: 0.28)),
                  ),
                  child: Icon(icon, color: color, size: context.rs(17, min: 15, max: 20)),
                ),
              const Spacer(),
              _TrendPill(trend: trend, color: color),
            ],
          ),
          SizedBox(height: context.rs(compact ? 10 : 14, min: 8, max: 16)),
          AnimatedStatValue(
            value: value,
            suffix: suffix,
            decimals: decimals,
            style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
              fontSize: context.sp(compact ? 22 : 28, min: 19, max: 34),
              height: 0.95,
            ),
          ),
          SizedBox(height: context.rs(6, min: 4, max: 8)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body(color: AppColors.textPrimary).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: context.sp(compact ? 12 : 14, min: 11, max: 16),
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: context.rs(3, min: 2, max: 5)),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class GoalSightCircularStat extends StatelessWidget {
  const GoalSightCircularStat({
    super.key,
    required this.label,
    required this.value,
    this.color = AppColors.accentCyan,
    this.size = 78,
    this.centerSuffix = '%',
  });

  final String label;
  final double value;
  final Color color;
  final double size;
  final String centerSuffix;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: clamped / 100),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, progress, _) {
            return SizedBox(
              width: context.rs(size, min: 58, max: 96),
              height: context.rs(size, min: 58, max: 96),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 7,
                    color: color,
                    backgroundColor: AppColors.outlineSubtle,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      '${(progress * 100).round()}$centerSuffix',
                      style: AppTextStyles.button(color: AppColors.textPrimary).copyWith(
                        fontSize: context.sp(13, min: 11, max: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        SizedBox(height: context.rs(8, min: 6, max: 10)),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class GoalSightComparisonStat extends StatelessWidget {
  const GoalSightComparisonStat({
    super.key,
    required this.label,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftValue,
    required this.rightValue,
    this.leftColor = AppColors.accentCyan,
    this.rightColor = AppColors.primaryPurple,
  });

  final String label;
  final String leftLabel;
  final String rightLabel;
  final int leftValue;
  final int rightValue;
  final Color leftColor;
  final Color rightColor;

  @override
  Widget build(BuildContext context) {
    final total = (leftValue + rightValue).clamp(1, 1000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('$leftValue%', style: AppTextStyles.button(color: leftColor)),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(color: AppColors.textMuted),
              ),
            ),
            Text('$rightValue%', style: AppTextStyles.button(color: rightColor)),
          ],
        ),
        SizedBox(height: context.rs(7, min: 5, max: 9)),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Row(
            children: [
              Flexible(
                flex: leftValue <= 0 ? 1 : leftValue,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: 8,
                  color: leftColor,
                ),
              ),
              Flexible(
                flex: rightValue <= 0 ? 1 : rightValue,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: 8,
                  color: rightColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.rs(7, min: 5, max: 9)),
        Row(
          children: [
            Expanded(
              child: Text(
                leftLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(color: AppColors.textMuted),
              ),
            ),
            Text(
              '${((leftValue / total) * 100).round()} / ${((rightValue / total) * 100).round()} split',
              style: AppTextStyles.caption(color: AppColors.textMuted),
            ),
            Expanded(
              child: Text(
                rightLabel,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.trend, required this.color});

  final GoalSightTrend trend;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = switch (trend) {
      GoalSightTrend.up => Icons.trending_up_rounded,
      GoalSightTrend.down => Icons.trending_down_rounded,
      GoalSightTrend.flat => Icons.trending_flat_rounded,
    };
    final trendColor = trend == GoalSightTrend.down ? AppColors.danger : color;

    return Container(
      width: context.rs(28, min: 24, max: 30),
      height: context.rs(28, min: 24, max: 30),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.11),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: trendColor, size: context.rs(15, min: 13, max: 17)),
    );
  }
}
