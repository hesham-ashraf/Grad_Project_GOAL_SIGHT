import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../manager_dashboard_models.dart';

class PlayerCard extends StatelessWidget {
  const PlayerCard({
    super.key,
    required this.player,
    required this.rank,
  });

  final ManagerPlayerPerformance player;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.rs(176, min: 150, max: 220),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.outlineSubtle),
          boxShadow: AppShadows.card,
        ),
        child: Padding(
          padding: AppSpacing.cardCompact,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.12),
                  borderRadius: AppRadius.chip,
                  border: Border.all(
                    color: AppColors.accentGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Top #$rank',
                  style: AppTextStyles.caption(
                    color: AppColors.accentGreen,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(height: context.rs(12, min: 9, max: 14)),
              Text(
                player.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.title().copyWith(
                  fontSize: context.sp(16, min: 14, max: 18),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    size: 17,
                    color: AppColors.accentCyan,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${player.rating.toStringAsFixed(1)} Rating',
                    style: AppTextStyles.body(
                      color: AppColors.textSecondary,
                    ).copyWith(
                      fontSize: context.sp(12, min: 11, max: 13),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
