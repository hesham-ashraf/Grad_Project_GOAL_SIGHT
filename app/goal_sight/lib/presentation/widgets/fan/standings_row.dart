import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import 'tap_scale.dart';

class StandingTeamData {
  const StandingTeamData({
    required this.rank,
    required this.teamName,
    required this.matchesPlayed,
    required this.goalDifference,
    required this.points,
    required this.teamColor,
    this.isHighlighted = false,
  });

  final int rank;
  final String teamName;
  final int matchesPlayed;
  final int goalDifference;
  final int points;
  final Color teamColor;
  final bool isHighlighted;
}

class StandingsRow extends StatelessWidget {
  const StandingsRow({
    super.key,
    required this.team,
    this.onTap,
  });

  final StandingTeamData team;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isTop3 = team.rank <= 3;
    final Color rankColor = team.rank == 1
        ? const Color(0xFFFFD700) // Gold
        : team.rank == 2
            ? const Color(0xFFC0C0C0) // Silver
            : team.rank == 3
                ? const Color(0xFFCD7F32) // Bronze
                : AppColors.textSecondary;

    final innerCard = Container(
      margin: EdgeInsets.only(bottom: context.rs(8, min: 6, max: 10)),
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(16, min: 14, max: 20),
        vertical: context.rs(12, min: 10, max: 16),
      ),
      decoration: BoxDecoration(
        color: team.isHighlighted
            ? team.teamColor.withValues(alpha: 0.1)
            : AppColors.surfaceElevated.withValues(alpha: 0.6),
        borderRadius: AppRadius.card,
        border: Border.all(
          color: team.isHighlighted
              ? team.teamColor.withValues(alpha: 0.3)
              : AppColors.outlineSubtle,
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          SizedBox(
            width: context.rs(28, min: 24, max: 32),
            child: isTop3
                ? Container(
                    width: context.rs(24, min: 20, max: 28),
                    height: context.rs(24, min: 20, max: 28),
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: rankColor.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Text(
                        '${team.rank}',
                        style: AppTextStyles.button(color: rankColor).copyWith(
                          fontSize: context.rs(11, min: 10, max: 13),
                        ),
                      ),
                    ),
                  )
                : Text(
                    '${team.rank}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(color: rankColor).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          SizedBox(width: context.rs(12, min: 10, max: 16)),
          
          // Team Name & Logo
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: context.rs(28, min: 24, max: 32),
                  height: context.rs(28, min: 24, max: 32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: team.teamColor.withValues(alpha: 0.2),
                    border: Border.all(color: team.teamColor.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Text(
                      team.teamName.substring(0, 1).toUpperCase(),
                      style: AppTextStyles.button(color: Colors.white).copyWith(
                        fontSize: context.rs(12, min: 10, max: 14),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: context.rs(10, min: 8, max: 12)),
                Expanded(
                  child: Text(
                    team.teamName,
                    style: AppTextStyles.body(color: AppColors.textPrimary).copyWith(
                      fontWeight: team.isHighlighted ? FontWeight.w700 : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Stats Columns
          Expanded(
            flex: 1,
            child: Text(
              '${team.matchesPlayed}',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              team.goalDifference > 0 ? '+${team.goalDifference}' : '${team.goalDifference}',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(
                color: team.goalDifference > 0
                    ? AppColors.success
                    : team.goalDifference < 0
                        ? AppColors.danger
                        : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${team.points}',
              textAlign: TextAlign.right,
              style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
                fontSize: context.rs(16, min: 14, max: 18),
              ),
            ),
          ),
        ],
      ),
    );

    return TapScale(
      onTap: onTap,
      scaleDown: 0.97,
      child: innerCard,
    );
  }
}

class StandingsHeaderRow extends StatelessWidget {
  const StandingsHeaderRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(16, min: 14, max: 20),
        vertical: context.rs(12, min: 10, max: 14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: context.rs(28, min: 24, max: 32),
            child: Text(
              '#',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption(color: AppColors.textMuted),
            ),
          ),
          SizedBox(width: context.rs(12, min: 10, max: 16)),
          Expanded(
            flex: 4,
            child: Text(
              'CLUB',
              style: AppTextStyles.caption(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'MP',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'GD',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'PTS',
              textAlign: TextAlign.right,
              style: AppTextStyles.caption(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
