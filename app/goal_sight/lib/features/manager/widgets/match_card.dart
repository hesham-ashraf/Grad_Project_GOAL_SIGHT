import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/match_analysis_model.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    this.isRecent = false,
    this.onTap,
  });

  final MatchAnalysisModel match;
  final bool isRecent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surface = AppTheme.darkSurface;
    final accent = AppTheme.accentCyan;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Material(
        color: surface,
        elevation: 2,
        borderRadius: AppRadius.card,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.card,
              boxShadow: AppShadows.card,
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // left: teams and score
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${match.homeTeam} vs ${match.awayTeam}',
                              style: AppTextStyles.title(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isRecent)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('Recent',
                                  style: AppTextStyles.caption(
                                      color: AppColors.accentCyan)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        match.score,
                        style: AppTextStyles.headline(
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(match.date, style: AppTextStyles.caption()),
                          const SizedBox(width: 12),
                          Icon(Icons.whatshot_outlined,
                              size: 14, color: AppColors.warning),
                          const SizedBox(width: 6),
                          Text('${match.intensity}%',
                              style: AppTextStyles.caption()),
                        ],
                      ),
                      if ((match.summary.overallNarrative ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            match.summary.overallNarrative,
                            style:
                                AppTextStyles.body(color: AppColors.textSecondary)
                                .copyWith(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                // right: chevron
                const SizedBox(width: 12),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
