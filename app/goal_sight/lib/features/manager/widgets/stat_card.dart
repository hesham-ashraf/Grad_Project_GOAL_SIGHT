import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../manager_dashboard_models.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.stat,
  });

  final ManagerKeyStat stat;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.outlineSubtle,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: AppSpacing.card,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 170;
            final iconSize = compact ? 16.0 : 18.0;
            final valueSize = context.sp(compact ? 21 : 24, min: 18, max: 26);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: compact ? 34 : 38,
                  height: compact ? 34 : 38,
                  decoration: BoxDecoration(
                    color: stat.tint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: stat.tint.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(
                    stat.icon,
                    color: stat.tint,
                    size: iconSize,
                  ),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    stat.value,
                    style: AppTextStyles.title().copyWith(
                      fontSize: valueSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(height: context.rs(4, min: 3, max: 6)),
                Text(
                  stat.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(
                    color: AppColors.textSecondary,
                  ).copyWith(
                    fontSize: context.sp(11, min: 10, max: 12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
