/// ---------------------------------------------------------------------------
/// GoalSight — Player List Card Widget
///
/// Displays a player summary card for use in players list.
/// Shows: name, position, current rating, performance indicator, and tap target.
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:goal_sight/core/theme/app_theme.dart';
import 'package:goal_sight/core/utils/responsive.dart';
import 'package:goal_sight/data/models/player_profile_model.dart';

class PlayerListCard extends StatelessWidget {
  const PlayerListCard({
    required this.player,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  final PlayerProfileModel player;
  final VoidCallback onTap;

  Color _getTrendColor() {
    switch (player.trend) {
      case PerformanceTrend.improving:
        return AppColors.accentGreen;
      case PerformanceTrend.declining:
        return AppColors.danger;
      case PerformanceTrend.stable:
        return AppColors.textSecondary;
    }
  }

  String _getTrendIcon() {
    switch (player.trend) {
      case PerformanceTrend.improving:
        return '↗';
      case PerformanceTrend.declining:
        return '↘';
      case PerformanceTrend.stable:
        return '→';
    }
  }

  Color _getRatingColor() {
    if (player.currentRating >= 8.0) {
      return AppColors.accentGreen;
    } else if (player.currentRating >= 7.0) {
      return AppColors.accentCyan;
    } else if (player.currentRating >= 6.0) {
      return AppColors.warning;
    } else {
      return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md.rs(context)),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border.all(
                color: AppColors.outline.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [AppShadows.card],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg.rs(context),
              vertical: AppSpacing.md.rs(context),
            ),
            child: Row(
              children: [
                // Player Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Position
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              player.name,
                              style: AppTextStyles.title(
                                color: AppColors.textPrimary,
                                fontSize: 16.sp(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm.rs(context)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs.rs(context),
                              vertical: AppSpacing.xxs.rs(context),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple.withOpacity(0.2),
                              border: Border.all(
                                color: AppColors.primaryPurple,
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              player.positionShort,
                              style: AppTextStyles.caption(
                                color: AppColors.primaryPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.xs.rs(context)),

                      // Rating and Trend Row
                      Row(
                        children: [
                          // Current Rating
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Rating',
                                style: AppTextStyles.caption(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              SizedBox(height: AppSpacing.xxs.rs(context)),
                              Row(
                                children: [
                                  Text(
                                    '${player.currentRating.toStringAsFixed(1)}',
                                    style: AppTextStyles.title(
                                      color: _getRatingColor(),
                                      fontSize: 18.sp(context),
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.xs.rs(context)),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs.rs(context),
                                      vertical: AppSpacing.xxs.rs(context),
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getTrendColor().withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Text(
                                      '${_getTrendIcon()} ${player.improvementRate > 0 ? '+' : ''}${player.improvementRate.toStringAsFixed(1)}%',
                                      style: AppTextStyles.caption(
                                        color: _getTrendColor(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(width: AppSpacing.lg.rs(context)),

                          // Status Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm.rs(context),
                              vertical: AppSpacing.xs.rs(context),
                            ),
                            decoration: BoxDecoration(
                              color: player.status == 'Explosive Form'
                                  ? AppColors.accentGreen.withOpacity(0.15)
                                  : player.status == 'Elite Form'
                                      ? AppColors.accentCyan.withOpacity(0.15)
                                      : player.status.contains('Improvement')
                                          ? AppColors.danger.withOpacity(0.15)
                                          : AppColors.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              player.status,
                              style: AppTextStyles.caption(
                                color: player.status == 'Explosive Form'
                                    ? AppColors.accentGreen
                                    : player.status == 'Elite Form'
                                        ? AppColors.accentCyan
                                        : player.status.contains('Improvement')
                                            ? AppColors.danger
                                            : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.xs.rs(context)),

                      // Quick Stats
                      Text(
                        '${player.totalMatches} matches • Avg ${player.averageRating.toStringAsFixed(1)} • Fatigue ${player.fatigue}%',
                        style: AppTextStyles.caption(
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.md.rs(context)),

                // Chevron
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 24.rs(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
