import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import 'glass_container.dart';
import 'risk_badge.dart';

enum GoalSightPlayerCardVariant { compact, detailed, ranking, horizontal }

class GoalSightPlayerCardData {
  const GoalSightPlayerCardData({
    required this.name,
    required this.position,
    required this.rating,
    this.club,
    this.image,
    this.fatigue = 0,
    this.workRate = 0,
    this.impactScore = 0,
    this.riskLabel,
    this.riskSeverity = GoalSightSeverity.neutral,
    this.rank,
  });

  final String name;
  final String position;
  final double rating;
  final String? club;
  final Widget? image;
  final int fatigue;
  final int workRate;
  final int impactScore;
  final String? riskLabel;
  final GoalSightSeverity riskSeverity;
  final int? rank;
}

class GoalSightPlayerCard extends StatelessWidget {
  const GoalSightPlayerCard({
    super.key,
    required this.player,
    this.variant = GoalSightPlayerCardVariant.detailed,
    this.onTap,
  });

  final GoalSightPlayerCardData player;
  final GoalSightPlayerCardVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor(player.rating);
    final horizontal = variant == GoalSightPlayerCardVariant.horizontal ||
        variant == GoalSightPlayerCardVariant.ranking;
    final compact = variant == GoalSightPlayerCardVariant.compact;

    return GoalSightGlass(
      onTap: onTap,
      opacity: 0.82,
      borderColor: color.withValues(alpha: 0.22),
      padding: EdgeInsets.all(context.rs(compact ? 12 : 15, min: 11, max: 18)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.1),
          AppColors.surfaceElevated.withValues(alpha: 0.88),
        ],
      ),
      child: horizontal ? _horizontal(context, color) : _vertical(context, color, compact),
    );
  }

  Widget _horizontal(BuildContext context, Color color) {
    return Row(
      children: [
        if (player.rank != null) ...[
          Text(
            '#${player.rank}',
            style: AppTextStyles.title(color: color).copyWith(fontSize: context.sp(17, min: 15, max: 20)),
          ),
          SizedBox(width: context.rs(12, min: 8, max: 14)),
        ],
        _Avatar(player: player, color: color),
        SizedBox(width: context.rs(12, min: 10, max: 14)),
        Expanded(child: _PlayerIdentity(player: player, color: color)),
        SizedBox(width: context.rs(10, min: 8, max: 12)),
        _RatingBlock(rating: player.rating, color: color),
      ],
    );
  }

  Widget _vertical(BuildContext context, Color color, bool compact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(player: player, color: color),
            const Spacer(),
            _RatingBlock(rating: player.rating, color: color),
          ],
        ),
        SizedBox(height: context.rs(compact ? 10 : 14, min: 8, max: 16)),
        _PlayerIdentity(player: player, color: color),
        if (!compact) ...[
          SizedBox(height: context.rs(14, min: 10, max: 16)),
          _AnimatedMetric(label: 'Fatigue', value: player.fatigue, color: _fatigueColor(player.fatigue)),
          SizedBox(height: context.rs(9, min: 7, max: 11)),
          _AnimatedMetric(label: 'Work rate', value: player.workRate, color: AppColors.accentCyan),
          SizedBox(height: context.rs(9, min: 7, max: 11)),
          _AnimatedMetric(label: 'Impact', value: player.impactScore, color: AppColors.accentGreen),
        ],
        if (player.riskLabel != null) ...[
          SizedBox(height: context.rs(12, min: 8, max: 14)),
          GoalSightRiskBadge(
            label: player.riskLabel!,
            severity: player.riskSeverity,
            pulse: player.riskSeverity == GoalSightSeverity.critical,
          ),
        ],
      ],
    );
  }
}

class _PlayerIdentity extends StatelessWidget {
  const _PlayerIdentity({required this.player, required this.color});

  final GoalSightPlayerCardData player;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          player.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
            fontSize: context.sp(16, min: 14, max: 19),
          ),
        ),
        SizedBox(height: context.rs(4, min: 2, max: 6)),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: AppRadius.chip,
                border: Border.all(color: color.withValues(alpha: 0.24)),
              ),
              child: Text(
                player.position.toUpperCase(),
                style: AppTextStyles.caption(color: color).copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ),
            if (player.club != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  player.club!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(color: AppColors.textMuted),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.player, required this.color});

  final GoalSightPlayerCardData player;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.rs(48, min: 40, max: 58),
      height: context.rs(48, min: 40, max: 58),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.26), color.withValues(alpha: 0.08)]),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: ClipOval(
        child: Center(
          child: player.image ??
              Text(
                player.name.isEmpty ? '?' : player.name[0].toUpperCase(),
                style: AppTextStyles.title(color: color),
              ),
        ),
      ),
    );
  }
}

class _RatingBlock extends StatelessWidget {
  const _RatingBlock({required this.rating, required this.color});

  final double rating;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: rating),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Text(
              value.toStringAsFixed(1),
              style: AppTextStyles.headline(color: color).copyWith(
                fontSize: context.sp(24, min: 20, max: 28),
                height: 0.95,
              ),
            );
          },
        ),
        Text('rating', style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 10)),
      ],
    );
  }
}

class _AnimatedMetric extends StatelessWidget {
  const _AnimatedMetric({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100).toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: clamped / 100),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label, style: AppTextStyles.caption(color: AppColors.textMuted)),
                const Spacer(),
                Text('${(progress * 100).round()}%', style: AppTextStyles.caption(color: color)),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: AppRadius.chip,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: color,
                backgroundColor: AppColors.outlineSubtle,
              ),
            ),
          ],
        );
      },
    );
  }
}

Color _ratingColor(double rating) {
  if (rating >= 8.4) return AppColors.accentCyan;
  if (rating >= 7.2) return AppColors.accentGreen;
  if (rating >= 6.2) return AppColors.warning;
  return AppColors.danger;
}

Color _fatigueColor(int fatigue) {
  if (fatigue >= 78) return AppColors.danger;
  if (fatigue >= 58) return AppColors.warning;
  return AppColors.accentGreen;
}
