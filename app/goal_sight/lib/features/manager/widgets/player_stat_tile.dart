// ---------------------------------------------------------------------------
// GoalSight — Player Stat Tile Widget
//
// Displays a single performance stat in the player profile.
// Used for: Average Rating, Fatigue Level, Activity Level, etc.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:goal_sight/core/theme/app_theme.dart';
import 'package:goal_sight/core/utils/responsive.dart';

class PlayerStatTile extends StatelessWidget {
  const PlayerStatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.color = AppColors.accentCyan,
    this.maxValue = 100,
    super.key,
  });

  final String label;
  final double value;
  final String unit;
  final IconData icon;
  final Color color;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: EdgeInsets.all(context.rs(AppSpacing.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Label
          Row(
            children: [
              Container(
                width: context.rs(40),
                height: context.rs(40),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: context.rs(20),
                ),
              ),
              SizedBox(width: context.rs(AppSpacing.md)),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.rs(AppSpacing.md)),

          // Value Display
          Text(
            '${value.toStringAsFixed(value == value.toInt() ? 0 : 1)}$unit',
            style: AppTextStyles.title(
              color: color,
            ).copyWith(
              fontSize: context.sp(24),
            ),
          ),
          SizedBox(height: context.rs(AppSpacing.sm)),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: context.rs(6),
              backgroundColor: AppColors.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
