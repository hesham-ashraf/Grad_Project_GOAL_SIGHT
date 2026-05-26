import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/tactical_insight_model.dart';

class TacticalInsightWidget extends StatelessWidget {
  final TacticalInsightModel insight;

  const TacticalInsightWidget({super.key, required this.insight});

  Color _getCategoryColor() {
    switch (insight.category) {
      case 'Strength':
        return AppColors.success;
      case 'Weakness':
        return AppColors.danger;
      case 'Opportunity':
        return AppColors.accentCyan;
      default:
        return AppColors.primaryBlue;
    }
  }

  IconData _getCategoryIcon() {
    switch (insight.category) {
      case 'Strength':
        return Icons.trending_up;
      case 'Weakness':
        return Icons.trending_down;
      case 'Opportunity':
        return Icons.lightbulb_outline;
      default:
        return Icons.analytics_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getCategoryIcon(), color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      insight.category.toUpperCase(),
                      style: AppTextStyles.caption(color: color).copyWith(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.flash_on, size: 14, color: AppColors.warning),
                        Text(
                          insight.impactScore.toStringAsFixed(1),
                          style: AppTextStyles.caption(color: AppColors.warning).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  insight.title,
                  style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  insight.description,
                  style: AppTextStyles.body(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
