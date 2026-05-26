import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../components/glass_container.dart';
import '../components/section_header.dart';
import '../states/app_state_widgets.dart';

class GoalSightChartLegendItem {
  const GoalSightChartLegendItem({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;
}

class GoalSightChartWrapper extends StatelessWidget {
  const GoalSightChartWrapper({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon = Icons.show_chart_rounded,
    this.legend = const [],
    this.isLoading = false,
    this.isEmpty = false,
    this.emptyMessage = 'No analytics available yet.',
    this.onRetry,
    this.minHeight = 220,
    this.accent = AppColors.accentCyan,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final List<GoalSightChartLegendItem> legend;
  final bool isLoading;
  final bool isEmpty;
  final String emptyMessage;
  final VoidCallback? onRetry;
  final double minHeight;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GoalSightGlass(
      opacity: 0.82,
      borderColor: accent.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoalSightSectionHeader(
            title: title,
            subtitle: subtitle,
            icon: icon,
            accent: accent,
            animate: false,
            trailing: legend.isEmpty ? null : _Legend(items: legend),
          ),
          SizedBox(height: context.rs(16, min: 12, max: 20)),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: context.rs(minHeight, min: 160, max: 340)),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: isLoading
                  ? const GoalSightChartSkeleton(key: ValueKey('chart-loading'))
                  : isEmpty
                      ? GoalSightEmptyState(
                          key: const ValueKey('chart-empty'),
                          title: 'No chart data',
                          message: emptyMessage,
                          icon: Icons.query_stats_rounded,
                          compact: true,
                          actionLabel: onRetry == null ? null : 'Retry',
                          onAction: onRetry,
                        )
                      : child,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.items});

  final List<GoalSightChartLegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(
                  item.label,
                  style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 10),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}
