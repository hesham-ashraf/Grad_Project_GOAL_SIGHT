import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/match_analysis_model.dart';
import 'tap_scale.dart';

class MatchListCard extends StatelessWidget {
  const MatchListCard({
    super.key,
    required this.match,
    this.onTap,
  });

  final MatchAnalysisModel match;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isTopMatch = match.intensity >= 80;
    final innerCard = Container(
      decoration: BoxDecoration(
        color: isTopMatch
            ? AppColors.surfaceElevated.withValues(alpha: 0.96)
            : AppColors.surfaceElevated.withValues(alpha: 0.6),
        borderRadius: AppRadius.cardLarge,
        border: Border.all(
          color: isTopMatch
              ? AppColors.accentCyan.withValues(alpha: 0.28)
              : AppColors.outlineSubtle,
        ),
        boxShadow: isTopMatch
            ? [
                BoxShadow(
                  color: AppColors.accentCyan.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardLarge,
        child: Stack(
          children: [
            if (isTopMatch)
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accentCyan.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(context.rs(16, min: 14, max: 20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Date & Intensity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: context.rs(14, min: 12, max: 16),
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: context.rs(6, min: 4, max: 8)),
                          Text(
                            match.date,
                            style: AppTextStyles.caption(
                              color: AppColors.textSecondary,
                            ).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.rs(8, min: 6, max: 10),
                          vertical: context.rs(4, min: 3, max: 6),
                        ),
                        decoration: BoxDecoration(
                          color: match.intensity >= 85
                              ? AppColors.warning.withValues(alpha: 0.12)
                              : AppColors.surfaceRaised,
                          borderRadius: AppRadius.chip,
                          border: Border.all(
                            color: match.intensity >= 85
                                ? AppColors.warning.withValues(alpha: 0.2)
                                : AppColors.outlineSubtle,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: context.rs(12, min: 10, max: 14),
                              color: match.intensity >= 85
                                  ? AppColors.warning
                                  : AppColors.textMuted,
                            ),
                            SizedBox(width: context.rs(4, min: 2, max: 6)),
                            Text(
                              '${match.intensity}',
                              style: AppTextStyles.caption(
                                color: match.intensity >= 85
                                    ? AppColors.warning
                                    : AppColors.textSecondary,
                              ).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: context.rs(10, min: 9, max: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.rs(16, min: 12, max: 20)),
                  
                  // Middle Row: Teams & Score
                  Row(
                    children: [
                      // Home Team
                      Expanded(
                        child: _TeamInfo(
                          teamName: match.homeTeam,
                          color: AppColors.accentCyan,
                          alignEnd: false,
                        ),
                      ),
                      // Score
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.rs(16, min: 12, max: 20),
                          vertical: context.rs(8, min: 6, max: 10),
                        ),
                        margin: EdgeInsets.symmetric(
                          horizontal: context.rs(12, min: 8, max: 16),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.button,
                          border: Border.all(
                            color: AppColors.outlineSubtle,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              match.score,
                              style: AppTextStyles.title(
                                color: AppColors.textPrimary,
                              ).copyWith(
                                fontSize: context.rs(22, min: 18, max: 26),
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: context.rs(2, min: 0, max: 4)),
                            Text(
                              match.status,
                              style: AppTextStyles.caption(
                                color: AppColors.textMuted,
                              ).copyWith(
                                fontSize: context.rs(10, min: 8, max: 11),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Away Team
                      Expanded(
                        child: _TeamInfo(
                          teamName: match.awayTeam,
                          color: AppColors.primaryPurple,
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                  
                  // Bottom Row: Highlight text (optional)
                  if (match.highlightText != null) ...[
                    SizedBox(height: context.rs(16, min: 12, max: 20)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rs(12, min: 10, max: 14),
                        vertical: context.rs(8, min: 6, max: 10),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withValues(alpha: 0.08),
                        borderRadius: AppRadius.button,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: context.rs(16, min: 14, max: 18),
                            color: AppColors.accentCyan,
                          ),
                          SizedBox(width: context.rs(8, min: 6, max: 10)),
                          Expanded(
                            child: Text(
                              match.highlightText!,
                              style: AppTextStyles.caption(
                                color: AppColors.textPrimary,
                              ).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return TapScale(
      onTap: onTap,
      scaleDown: 0.96,
      child: innerCard,
    );
  }
}

class _TeamInfo extends StatelessWidget {
  const _TeamInfo({
    required this.teamName,
    required this.color,
    required this.alignEnd,
  });

  final String teamName;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final abbreviation = teamName.split(' ').map((e) => e[0]).take(2).join('').toUpperCase();

    final content = [
      Container(
        width: context.rs(40, min: 36, max: 48),
        height: context.rs(40, min: 36, max: 48),
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
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Text(
            abbreviation,
            style: AppTextStyles.title(color: Colors.white).copyWith(
              fontSize: context.rs(14, min: 12, max: 16),
            ),
          ),
        ),
      ),
      SizedBox(height: context.rs(8, min: 6, max: 10)),
      Text(
        teamName,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: AppTextStyles.body(color: AppColors.textPrimary).copyWith(
          fontWeight: FontWeight.w600,
          fontSize: context.rs(13, min: 12, max: 15),
          height: 1.2,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ];

    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: content,
    );
  }
}
