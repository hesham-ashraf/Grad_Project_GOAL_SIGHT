import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import 'glass_container.dart';
import 'risk_badge.dart';

enum AiRecommendationPriority { low, medium, high, urgent }

class GoalSightAiRecommendationCard extends StatefulWidget {
  const GoalSightAiRecommendationCard({
    super.key,
    required this.title,
    required this.summary,
    this.details,
    this.tags = const [],
    this.priority = AiRecommendationPriority.medium,
    this.initiallyExpanded = false,
    this.onTap,
  });

  final String title;
  final String summary;
  final String? details;
  final List<String> tags;
  final AiRecommendationPriority priority;
  final bool initiallyExpanded;
  final VoidCallback? onTap;

  @override
  State<GoalSightAiRecommendationCard> createState() =>
      _GoalSightAiRecommendationCardState();
}

class _GoalSightAiRecommendationCardState
    extends State<GoalSightAiRecommendationCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final style = _priorityStyle(widget.priority);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GoalSightGlass(
        opacity: 0.84,
        borderColor: style.color.withValues(alpha: 0.25),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withValues(alpha: 0.12),
            style.color.withValues(alpha: 0.07),
            AppColors.surfaceElevated.withValues(alpha: 0.86),
          ],
        ),
        onTap: () {
          widget.onTap?.call();
          if (widget.details != null) setState(() => _expanded = !_expanded);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: context.rs(40, min: 34, max: 46),
                  height: context.rs(40, min: 34, max: 46),
                  decoration: BoxDecoration(
                    gradient: AppGradients.brand,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppShadows.buttonGlow,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                ),
                SizedBox(width: context.rs(12, min: 10, max: 14)),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
                      fontSize: context.sp(16, min: 14, max: 19),
                    ),
                  ),
                ),
                GoalSightRiskBadge(
                  label: style.label,
                  severity: style.severity,
                  compact: true,
                  pulse: widget.priority == AiRecommendationPriority.urgent,
                ),
              ],
            ),
            SizedBox(height: context.rs(12, min: 9, max: 15)),
            Text(
              widget.summary,
              style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(
                fontSize: context.sp(13, min: 12, max: 15),
              ),
            ),
            if (widget.tags.isNotEmpty) ...[
              SizedBox(height: context.rs(12, min: 8, max: 14)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withValues(alpha: 0.09),
                          borderRadius: AppRadius.chip,
                          border: Border.all(
                            color: AppColors.accentCyan.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: AppTextStyles.caption(color: AppColors.accentCyan).copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: EdgeInsets.only(top: context.rs(12, min: 8, max: 14)),
                child: Text(
                  widget.details ?? '',
                  style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(height: 1.45),
                ),
              ),
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }
}

_PriorityStyle _priorityStyle(AiRecommendationPriority priority) {
  switch (priority) {
    case AiRecommendationPriority.low:
      return const _PriorityStyle('LOW', AppColors.accentCyan, GoalSightSeverity.neutral);
    case AiRecommendationPriority.medium:
      return const _PriorityStyle('MED', AppColors.warning, GoalSightSeverity.warning);
    case AiRecommendationPriority.high:
      return const _PriorityStyle('HIGH', AppColors.danger, GoalSightSeverity.critical);
    case AiRecommendationPriority.urgent:
      return const _PriorityStyle('URGENT', AppColors.danger, GoalSightSeverity.critical);
  }
}

class _PriorityStyle {
  const _PriorityStyle(this.label, this.color, this.severity);

  final String label;
  final Color color;
  final GoalSightSeverity severity;
}
