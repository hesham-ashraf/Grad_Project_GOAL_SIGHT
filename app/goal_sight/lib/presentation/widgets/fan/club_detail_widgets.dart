import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/club_model.dart';
import 'tap_scale.dart';

// ─── Player Item ────────────────────────────────────────────────────────────

class PlayerListTile extends StatelessWidget {
  const PlayerListTile({
    super.key,
    required this.player,
    required this.index,
  });

  final ClubPlayer player;
  final int index;

  Color _ratingColor(double rating) {
    if (rating >= 8.0) return AppColors.accentCyan;
    if (rating >= 7.0) return AppColors.accentGreen;
    if (rating >= 6.0) return AppColors.warning;
    return AppColors.danger;
  }

  String _positionFull(String pos) {
    const map = {
      'GK': 'Goalkeeper',
      'CB': 'Centre-Back',
      'LB': 'Left-Back',
      'RB': 'Right-Back',
      'DM': 'Defensive Mid',
      'CM': 'Central Mid',
      'AM': 'Attacking Mid',
      'CAM': 'Attacking Mid',
      'LW': 'Left Wing',
      'RW': 'Right Wing',
      'ST': 'Striker',
    };
    return map[pos] ?? pos;
  }

  @override
  Widget build(BuildContext context) {
    final ratingColor = _ratingColor(player.rating);

    return Container(
      margin: EdgeInsets.only(bottom: context.rs(10, min: 8, max: 12)),
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(16, min: 14, max: 20),
        vertical: context.rs(14, min: 12, max: 18),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.7),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Row(
        children: [
          // Index
          SizedBox(
            width: context.rs(24, min: 20, max: 28),
            child: Text(
              '${index + 1}',
              style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Avatar
          Container(
            width: context.rs(42, min: 36, max: 48),
            height: context.rs(42, min: 36, max: 48),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ratingColor.withValues(alpha: 0.25),
                  ratingColor.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(color: ratingColor.withValues(alpha: 0.35)),
            ),
            child: Center(
              child: Text(
                player.name[0],
                style: AppTextStyles.button(color: ratingColor).copyWith(
                  fontSize: context.rs(16, min: 14, max: 18),
                ),
              ),
            ),
          ),
          SizedBox(width: context.rs(12, min: 10, max: 16)),
          // Name + position
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        player.name,
                        style: AppTextStyles.body(color: AppColors.textPrimary).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (player.nationality.isNotEmpty) ...[
                      SizedBox(width: context.rs(6, min: 4, max: 8)),
                      Text(
                        player.nationality,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: context.rs(3, min: 2, max: 4)),
                Row(
                  children: [
                    _PositionBadge(position: player.position, color: ratingColor),
                    SizedBox(width: context.rs(8, min: 6, max: 10)),
                    Text(
                      _positionFull(player.position),
                      style: AppTextStyles.caption(color: AppColors.textMuted),
                    ),
                  ],
                ),
                if (player.performanceSummary.isNotEmpty) ...[
                  SizedBox(height: context.rs(6, min: 4, max: 8)),
                  Text(
                    player.performanceSummary,
                    style: AppTextStyles.caption(color: AppColors.textSecondary)
                        .copyWith(fontStyle: FontStyle.italic, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: context.rs(8, min: 6, max: 10)),
          // Quick stats
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MiniStat(value: '${player.goals}', label: 'G', color: AppColors.accentGreen),
              SizedBox(width: context.rs(8, min: 6, max: 10)),
              _MiniStat(value: '${player.assists}', label: 'A', color: AppColors.primaryBlue),
              SizedBox(width: context.rs(10, min: 8, max: 12)),
              // Rating pill
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.rs(10, min: 8, max: 12),
                  vertical: context.rs(5, min: 4, max: 7),
                ),
                decoration: BoxDecoration(
                  color: ratingColor.withValues(alpha: 0.15),
                  borderRadius: AppRadius.chip,
                ),
                child: Text(
                  player.rating.toStringAsFixed(1),
                  style: AppTextStyles.button(color: ratingColor).copyWith(
                    fontSize: context.rs(13, min: 11, max: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  const _PositionBadge({required this.position, required this.color});
  final String position;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        position,
        style: AppTextStyles.caption(color: color).copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.button(color: AppColors.textPrimary).copyWith(
            fontSize: context.rs(13, min: 11, max: 14),
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption(color: color).copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Club Stats Row ──────────────────────────────────────────────────────────

class ClubStatRow extends StatelessWidget {
  const ClubStatRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.rs(8, min: 6, max: 10)),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: context.rs(18, min: 16, max: 20), color: color),
            SizedBox(width: context.rs(10, min: 8, max: 12)),
          ],
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body(color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body(color: color).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.badge,
    this.color = AppColors.textPrimary,
  });

  final String title;
  final String? badge;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: context.rs(20, min: 18, max: 22),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: context.rs(10, min: 8, max: 12)),
        Text(
          title,
          style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
            fontSize: context.rs(18, min: 16, max: 20),
          ),
        ),
        if (badge != null) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.chip,
            ),
            child: Text(
              badge!,
              style: AppTextStyles.caption(color: color).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Form Bar (W / D / L) ────────────────────────────────────────────────────

class FormBar extends StatelessWidget {
  const FormBar({
    super.key,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.total,
  });

  final int wins;
  final int draws;
  final int losses;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              Flexible(
                flex: wins,
                child: Container(height: 8, color: AppColors.success),
              ),
              Flexible(
                flex: draws,
                child: Container(height: 8, color: AppColors.warning),
              ),
              Flexible(
                flex: losses,
                child: Container(height: 8, color: AppColors.danger),
              ),
            ],
          ),
        ),
        SizedBox(height: context.rs(8, min: 6, max: 10)),
        Row(
          children: [
            _FormLegend(color: AppColors.success, label: 'W $wins'),
            SizedBox(width: context.rs(12, min: 8, max: 16)),
            _FormLegend(color: AppColors.warning, label: 'D $draws'),
            SizedBox(width: context.rs(12, min: 8, max: 16)),
            _FormLegend(color: AppColors.danger, label: 'L $losses'),
          ],
        ),
      ],
    );
  }
}

class _FormLegend extends StatelessWidget {
  const _FormLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.caption(color: AppColors.textSecondary)),
      ],
    );
  }
}
