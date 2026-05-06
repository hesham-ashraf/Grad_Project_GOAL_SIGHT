import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../manager_dashboard_models.dart';

class MatchSummaryCard extends StatelessWidget {
  const MatchSummaryCard({
    super.key,
    required this.summary,
  });

  final ManagerLastMatch summary;

  @override
  Widget build(BuildContext context) {
    final scoreStyle = AppTextStyles.headline().copyWith(
      fontSize: context.sp(30, min: 24, max: 34),
      fontWeight: FontWeight.w800,
      letterSpacing: -0.7,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: AppColors.outlineSubtle),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated,
            AppColors.surface,
            AppColors.surfaceElevated.withValues(alpha: 0.96),
          ],
        ),
        boxShadow: AppShadows.cardGlow,
      ),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withValues(alpha: 0.14),
                    borderRadius: AppRadius.chip,
                    border: Border.all(
                      color: AppColors.accentCyan.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    'Last Match Summary',
                    style: AppTextStyles.caption(
                      color: AppColors.accentCyan,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                _DominantBadge(team: summary.dominantTeam),
              ],
            ),
            SizedBox(height: context.rs(14, min: 10, max: 18)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    summary.homeTeam,
                    style: AppTextStyles.title().copyWith(
                      fontSize: context.sp(18, min: 15, max: 22),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '${summary.homeScore} - ${summary.awayScore}',
                    style: scoreStyle,
                  ),
                ),
                Expanded(
                  child: Text(
                    summary.awayTeam,
                    textAlign: TextAlign.end,
                    style: AppTextStyles.title().copyWith(
                      fontSize: context.sp(18, min: 15, max: 22),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.rs(14, min: 10, max: 18)),
            Text(
              summary.aiSummary,
              style: AppTextStyles.body(
                color: AppColors.textSecondary,
              ).copyWith(
                fontSize: context.sp(13, min: 12, max: 15),
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DominantBadge extends StatelessWidget {
  const _DominantBadge({required this.team});

  final String team;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.16),
        borderRadius: AppRadius.chip,
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.36),
        ),
      ),
      child: Text(
        'Dominant: $team',
        style: AppTextStyles.caption(color: AppColors.textPrimary).copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
