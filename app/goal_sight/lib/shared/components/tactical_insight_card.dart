import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import 'glass_container.dart';
import 'risk_badge.dart';

enum TacticalInsightCategory { attacking, defensive, transition, pressing, fatigue, risk }

class GoalSightTacticalInsightCard extends StatelessWidget {
  const GoalSightTacticalInsightCard({
    super.key,
    required this.title,
    required this.message,
    this.recommendation,
    this.category = TacticalInsightCategory.attacking,
    this.severity = GoalSightSeverity.neutral,
    this.metricLabel,
    this.metricValue,
    this.onTap,
  });

  final String title;
  final String message;
  final String? recommendation;
  final TacticalInsightCategory category;
  final GoalSightSeverity severity;
  final String? metricLabel;
  final String? metricValue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final severityColor = goalSightSeverityColor(severity);
    final categoryStyle = _categoryStyle(category);

    return GoalSightGlass(
      onTap: onTap,
      opacity: 0.82,
      borderColor: severityColor.withValues(alpha: 0.22),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          severityColor.withValues(alpha: 0.09),
          AppColors.surfaceElevated.withValues(alpha: 0.86),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AnimatedInsightSignal(color: severityColor, icon: categoryStyle.icon),
              SizedBox(width: context.rs(12, min: 10, max: 14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
                              fontSize: context.sp(15, min: 13, max: 18),
                            ),
                          ),
                        ),
                        GoalSightRiskBadge(
                          label: categoryStyle.label,
                          severity: severity,
                          icon: categoryStyle.icon,
                          compact: true,
                          pulse: severity == GoalSightSeverity.critical,
                        ),
                      ],
                    ),
                    SizedBox(height: context.rs(8, min: 6, max: 10)),
                    Text(
                      message,
                      style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(
                        fontSize: context.sp(12, min: 11, max: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (metricLabel != null || metricValue != null) ...[
            SizedBox(height: context.rs(14, min: 10, max: 18)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.rs(12, min: 10, max: 14),
                vertical: context.rs(9, min: 7, max: 11),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: AppRadius.card,
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Text(
                    metricLabel ?? 'Signal',
                    style: AppTextStyles.caption(color: AppColors.textMuted),
                  ),
                  const Spacer(),
                  Text(
                    metricValue ?? 'Detected',
                    style: AppTextStyles.button(color: severityColor).copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          if (recommendation != null) ...[
            SizedBox(height: context.rs(12, min: 8, max: 14)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.accentCyan, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation!,
                    style: AppTextStyles.caption(color: AppColors.textSecondary).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimatedInsightSignal extends StatefulWidget {
  const _AnimatedInsightSignal({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  State<_AnimatedInsightSignal> createState() => _AnimatedInsightSignalState();
}

class _AnimatedInsightSignalState extends State<_AnimatedInsightSignal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: context.rs(38, min: 34, max: 44),
          height: context.rs(38, min: 34, max: 44),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: widget.color.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.08 + _controller.value * 0.1),
                blurRadius: 18,
              ),
            ],
          ),
          child: Icon(widget.icon, color: widget.color, size: 18),
        );
      },
    );
  }
}

_CategoryStyle _categoryStyle(TacticalInsightCategory category) {
  switch (category) {
    case TacticalInsightCategory.attacking:
      return const _CategoryStyle('Attack', Icons.sports_soccer_rounded);
    case TacticalInsightCategory.defensive:
      return const _CategoryStyle('Defense', Icons.shield_rounded);
    case TacticalInsightCategory.transition:
      return const _CategoryStyle('Transition', Icons.swap_horiz_rounded);
    case TacticalInsightCategory.pressing:
      return const _CategoryStyle('Pressing', Icons.compress_rounded);
    case TacticalInsightCategory.fatigue:
      return const _CategoryStyle('Fatigue', Icons.battery_3_bar_rounded);
    case TacticalInsightCategory.risk:
      return const _CategoryStyle('Risk', Icons.warning_rounded);
  }
}

class _CategoryStyle {
  const _CategoryStyle(this.label, this.icon);

  final String label;
  final IconData icon;
}
