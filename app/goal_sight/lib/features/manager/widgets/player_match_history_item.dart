/// ---------------------------------------------------------------------------
/// GoalSight — Player Match History Item Widget
///
/// Displays a single match from player's history.
/// Shows: match name, date, rating, and key statistics.
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:goal_sight/core/theme/app_theme.dart';
import 'package:goal_sight/core/utils/responsive.dart';
import 'package:goal_sight/data/models/player_profile_model.dart';

class PlayerMatchHistoryItem extends StatelessWidget {
  const PlayerMatchHistoryItem({
    required this.match,
    Key? key,
  }) : super(key: key);

  final PlayerMatchHistory match;

  Color _getPerformanceColor() {
    switch (match.performanceStatus.toLowerCase()) {
      case 'excellent':
        return AppColors.accentGreen;
      case 'good':
        return AppColors.accentCyan;
      case 'average':
        return AppColors.warning;
      case 'poor':
      case 'terrible':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day} ${_monthName(date.month)}';
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.rs(AppSpacing.md)),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border.all(
          color: AppColors.outline.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: EdgeInsets.all(context.rs(AppSpacing.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match Name and Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${match.homeTeam} vs ${match.awayTeam}',
                      style: AppTextStyles.title(
                        color: AppColors.textPrimary,
                      ).copyWith(
                        fontSize: context.sp(15),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.rs(AppSpacing.xs)),
                    Text(
                      _formatDate(match.matchDate),
                      style: AppTextStyles.caption(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.rs(AppSpacing.md)),

              // Rating Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.rs(AppSpacing.md),
                  vertical: context.rs(AppSpacing.sm),
                ),
                decoration: BoxDecoration(
                  color: _getPerformanceColor().withOpacity(0.15),
                  border: Border.all(
                    color: _getPerformanceColor().withOpacity(0.5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Text(
                      '${match.playerRating.toStringAsFixed(1)}',
                      style: AppTextStyles.title(
                        color: _getPerformanceColor(),
                      ).copyWith(
                        fontSize: context.sp(16),
                      ),
                    ),
                    Text(
                      match.performanceStatus,
                      style: AppTextStyles.caption(
                        color: _getPerformanceColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.rs(AppSpacing.md)),

          // Stats Grid
          Container(
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            padding: EdgeInsets.all(context.rs(AppSpacing.md)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Goals
                _StatBadge(
                  label: 'Goals',
                  value: '${match.goals}',
                  icon: Icons.sports_soccer,
                  context: context,
                ),
                // Assists
                _StatBadge(
                  label: 'Assists',
                  value: '${match.assists}',
                  icon: Icons.sports_basketball,
                  context: context,
                ),
                // Tackles
                _StatBadge(
                  label: 'Tackles',
                  value: '${match.tackles}',
                  icon: Icons.shield,
                  context: context,
                ),
                // Key Passes
                _StatBadge(
                  label: 'Key Passes',
                  value: '${match.keyPasses}',
                  icon: Icons.trending_up,
                  context: context,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.context,
    Key? key,
  }) : super(key: key);

  final String label;
  final String value;
  final IconData icon;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.accentCyan,
          size: context.rs(18),
        ),
        SizedBox(height: context.rs(AppSpacing.xs)),
        Text(
          value,
          style: AppTextStyles.title(
            color: AppColors.textPrimary,
          ).copyWith(
            fontSize: context.sp(14),
          ),
        ),
        SizedBox(height: context.rs(AppSpacing.xxs)),
        Text(
          label,
          style: AppTextStyles.caption(
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
