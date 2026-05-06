import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../manager_dashboard_models.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.insight,
  });

  final ManagerInsight insight;

  @override
  Widget build(BuildContext context) {
    final style = _severityStyle(insight.severity);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: style.border,
        ),
      ),
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                style.icon,
                size: 18,
                color: style.foreground,
              ),
            ),
            SizedBox(width: context.rs(10, min: 8, max: 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          insight.title,
                          style: AppTextStyles.title().copyWith(
                            fontSize: context.sp(15, min: 14, max: 17),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        style.label,
                        style: AppTextStyles.caption(
                          color: style.foreground,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  SizedBox(height: context.rs(6, min: 4, max: 8)),
                  Text(
                    insight.message,
                    style: AppTextStyles.body(
                      color: AppColors.textSecondary,
                    ).copyWith(
                      fontSize: context.sp(12, min: 11, max: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _InsightSeverityStyle _severityStyle(ManagerInsightSeverity severity) {
    switch (severity) {
      case ManagerInsightSeverity.high:
        return const _InsightSeverityStyle(
          label: 'High',
          icon: Icons.warning_rounded,
          foreground: AppColors.danger,
          border: Color(0x66FF6B8A),
          background: Color(0x33FF6B8A),
        );
      case ManagerInsightSeverity.medium:
        return const _InsightSeverityStyle(
          label: 'Medium',
          icon: Icons.report_problem_rounded,
          foreground: AppColors.warning,
          border: Color(0x66FFC857),
          background: Color(0x33FFC857),
        );
      case ManagerInsightSeverity.low:
        return const _InsightSeverityStyle(
          label: 'Low',
          icon: Icons.lightbulb_rounded,
          foreground: AppColors.accentCyan,
          border: Color(0x662DE2E6),
          background: Color(0x332DE2E6),
        );
    }
  }
}

class _InsightSeverityStyle {
  const _InsightSeverityStyle({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.border,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color border;
  final Color background;
}
