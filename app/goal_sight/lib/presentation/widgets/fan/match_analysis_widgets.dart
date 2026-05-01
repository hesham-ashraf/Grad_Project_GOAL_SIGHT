import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

class MatchOverviewCard extends StatelessWidget {
  const MatchOverviewCard({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.score,
    required this.summary,
    required this.dominantTeam,
    required this.homeColor,
    required this.awayColor,
  });

  final String homeTeam;
  final String awayTeam;
  final String score;
  final String summary;
  final String dominantTeam;
  final Color homeColor;
  final Color awayColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            homeColor.withValues(alpha: 0.15),
            AppColors.surfaceElevated,
            awayColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      padding: EdgeInsets.all(context.rs(20, min: 16, max: 24)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TeamBadge(teamName: homeTeam, color: homeColor),
              Text(
                score,
                style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
                  fontSize: context.rs(36, min: 28, max: 42),
                  letterSpacing: 2.0,
                ),
              ),
              _TeamBadge(teamName: awayTeam, color: awayColor),
            ],
          ),
          SizedBox(height: context.rs(24, min: 16, max: 32)),
          Container(
            padding: EdgeInsets.all(context.rs(16, min: 12, max: 20)),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.6),
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.outlineSubtle.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: context.rs(18, min: 14, max: 20),
                      color: AppColors.accentCyan,
                    ),
                    SizedBox(width: context.rs(8, min: 4, max: 10)),
                    Text(
                      'AI Match Summary',
                      style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
                        fontSize: context.rs(14, min: 12, max: 16),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.rs(10, min: 8, max: 12)),
                Text(
                  summary,
                  style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(
                    height: 1.5,
                  ),
                ),
                SizedBox(height: context.rs(12, min: 8, max: 16)),
                Row(
                  children: [
                    Text(
                      'Dominant Team: ',
                      style: AppTextStyles.caption(color: AppColors.textMuted),
                    ),
                    Text(
                      dominantTeam,
                      style: AppTextStyles.caption(color: homeColor).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamBadge extends StatelessWidget {
  const _TeamBadge({required this.teamName, required this.color});

  final String teamName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: context.rs(56, min: 48, max: 64),
          height: context.rs(56, min: 48, max: 64),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Center(
            child: Text(
              teamName.substring(0, 2).toUpperCase(),
              style: AppTextStyles.title(color: Colors.white).copyWith(
                fontSize: context.rs(18, min: 16, max: 20),
              ),
            ),
          ),
        ),
        SizedBox(height: context.rs(8, min: 6, max: 10)),
        Text(
          teamName,
          style: AppTextStyles.body(color: AppColors.textPrimary).copyWith(
            fontWeight: FontWeight.w600,
            fontSize: context.rs(13, min: 11, max: 15),
          ),
        ),
      ],
    );
  }
}

class KeyPlayerCard extends StatelessWidget {
  const KeyPlayerCard({
    super.key,
    required this.title,
    required this.playerName,
    required this.rating,
    required this.insight,
    required this.isBest,
  });

  final String title;
  final String playerName;
  final double rating;
  final String insight;
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    final color = isBest ? AppColors.success : AppColors.danger;
    final icon = isBest ? Icons.military_tech_rounded : Icons.trending_down_rounded;

    return Container(
      padding: EdgeInsets.all(context.rs(16, min: 14, max: 20)),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: context.rs(18, min: 16, max: 20)),
              SizedBox(width: context.rs(8, min: 6, max: 10)),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.caption(color: color).copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: context.rs(12, min: 8, max: 16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  playerName,
                  style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
                    fontSize: context.rs(18, min: 16, max: 20),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.rs(8, min: 6, max: 10),
                  vertical: context.rs(4, min: 2, max: 6),
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppRadius.chip,
                ),
                child: Text(
                  rating.toStringAsFixed(1),
                  style: AppTextStyles.button(color: color),
                ),
              ),
            ],
          ),
          SizedBox(height: context.rs(8, min: 6, max: 12)),
          Text(
            insight,
            style: AppTextStyles.caption(color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class TacticalRow extends StatelessWidget {
  const TacticalRow({
    super.key,
    required this.possessionHome,
    required this.styleHome,
    required this.pressureHome,
    required this.styleAway,
    required this.pressureAway,
    required this.homeColor,
    required this.awayColor,
  });

  final int possessionHome;
  final String styleHome;
  final String pressureHome;
  final String styleAway;
  final String pressureAway;
  final Color homeColor;
  final Color awayColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.rs(20, min: 16, max: 24)),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Possession',
            textAlign: TextAlign.center,
            style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
              fontSize: context.rs(16, min: 14, max: 18),
            ),
          ),
          SizedBox(height: context.rs(16, min: 12, max: 20)),
          Row(
            children: [
              Text(
                '$possessionHome%',
                style: AppTextStyles.button(color: homeColor),
              ),
              SizedBox(width: context.rs(12, min: 8, max: 16)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: possessionHome,
                        child: Container(height: 8, color: homeColor),
                      ),
                      Expanded(
                        flex: 100 - possessionHome,
                        child: Container(height: 8, color: awayColor),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: context.rs(12, min: 8, max: 16)),
              Text(
                '${100 - possessionHome}%',
                style: AppTextStyles.button(color: awayColor),
              ),
            ],
          ),
          SizedBox(height: context.rs(24, min: 20, max: 32)),
          Row(
            children: [
              Expanded(
                child: _TacticalStat(
                  label: 'Style',
                  value: styleHome,
                  color: homeColor,
                  alignEnd: false,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.outlineSubtle,
              ),
              Expanded(
                child: _TacticalStat(
                  label: 'Style',
                  value: styleAway,
                  color: awayColor,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          SizedBox(height: context.rs(16, min: 12, max: 20)),
          Row(
            children: [
              Expanded(
                child: _TacticalStat(
                  label: 'Pressure',
                  value: pressureHome,
                  color: homeColor,
                  alignEnd: false,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.outlineSubtle,
              ),
              Expanded(
                child: _TacticalStat(
                  label: 'Pressure',
                  value: pressureAway,
                  color: awayColor,
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TacticalStat extends StatelessWidget {
  const _TacticalStat({
    required this.label,
    required this.value,
    required this.color,
    required this.alignEnd,
  });

  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.rs(12, min: 8, max: 16)),
      child: Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption(color: AppColors.textMuted),
          ),
          SizedBox(height: context.rs(4, min: 2, max: 6)),
          Text(
            value,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: AppTextStyles.body(color: color).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerListItem extends StatelessWidget {
  const PlayerListItem({
    super.key,
    required this.name,
    required this.rating,
    required this.insight,
    required this.isHighRated,
  });

  final String name;
  final double rating;
  final String insight;
  final bool isHighRated;

  @override
  Widget build(BuildContext context) {
    final color = isHighRated ? AppColors.accentCyan : AppColors.textMuted;

    return Container(
      margin: EdgeInsets.only(bottom: context.rs(8, min: 6, max: 10)),
      padding: EdgeInsets.all(context.rs(12, min: 10, max: 16)),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.rs(8, min: 6, max: 10)),
            decoration: BoxDecoration(
              color: isHighRated ? color.withValues(alpha: 0.1) : AppColors.surfaceRaised,
              shape: BoxShape.circle,
            ),
            child: Text(
              name.substring(0, 1),
              style: AppTextStyles.button(color: isHighRated ? color : AppColors.textPrimary),
            ),
          ),
          SizedBox(width: context.rs(12, min: 8, max: 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.body(color: AppColors.textPrimary).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: context.rs(2, min: 0, max: 4)),
                Text(
                  insight,
                  style: AppTextStyles.caption(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: context.rs(12, min: 8, max: 16)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.rs(8, min: 6, max: 10),
              vertical: context.rs(4, min: 2, max: 6),
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              rating.toStringAsFixed(1),
              style: AppTextStyles.button(color: color).copyWith(
                fontSize: context.rs(12, min: 10, max: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.recommendation,
  });

  final String recommendation;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.rs(8, min: 6, max: 12)),
      padding: EdgeInsets.all(context.rs(16, min: 14, max: 20)),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tips_and_updates_rounded,
            color: AppColors.warning,
            size: context.rs(20, min: 16, max: 24),
          ),
          SizedBox(width: context.rs(12, min: 10, max: 16)),
          Expanded(
            child: Text(
              recommendation,
              style: AppTextStyles.body(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
