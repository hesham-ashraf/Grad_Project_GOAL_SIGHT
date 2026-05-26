import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

enum GoalSightSeverity { positive, neutral, warning, critical }

class GoalSightRiskBadge extends StatefulWidget {
  const GoalSightRiskBadge({
    super.key,
    required this.label,
    this.severity = GoalSightSeverity.neutral,
    this.icon,
    this.pulse = false,
    this.compact = false,
  });

  final String label;
  final GoalSightSeverity severity;
  final IconData? icon;
  final bool pulse;
  final bool compact;

  @override
  State<GoalSightRiskBadge> createState() => _GoalSightRiskBadgeState();
}

class _GoalSightRiskBadgeState extends State<GoalSightRiskBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );
    if (widget.pulse) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant GoalSightRiskBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulse && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = goalSightSeverityColor(widget.severity);
    final icon = widget.icon ?? goalSightSeverityIcon(widget.severity);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glow = widget.pulse ? 0.16 + (_controller.value * 0.18) : 0.12;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: widget.compact ? 0.1 : 0.13),
            borderRadius: AppRadius.chip,
            border: Border.all(color: color.withValues(alpha: 0.32)),
            boxShadow: [
              if (widget.pulse)
                BoxShadow(
                  color: color.withValues(alpha: glow),
                  blurRadius: 18,
                  spreadRadius: 0.5,
                ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.rs(widget.compact ? 8 : 11, min: 7, max: 13),
              vertical: context.rs(widget.compact ? 5 : 7, min: 4, max: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: context.rs(13, min: 11, max: 15)),
                SizedBox(width: context.rs(5, min: 4, max: 7)),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(color: color).copyWith(
                      fontSize: context.sp(widget.compact ? 10 : 11, min: 9, max: 12),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Color goalSightSeverityColor(GoalSightSeverity severity) {
  switch (severity) {
    case GoalSightSeverity.positive:
      return AppColors.accentGreen;
    case GoalSightSeverity.warning:
      return AppColors.warning;
    case GoalSightSeverity.critical:
      return AppColors.danger;
    case GoalSightSeverity.neutral:
      return AppColors.accentCyan;
  }
}

IconData goalSightSeverityIcon(GoalSightSeverity severity) {
  switch (severity) {
    case GoalSightSeverity.positive:
      return Icons.trending_up_rounded;
    case GoalSightSeverity.warning:
      return Icons.report_problem_rounded;
    case GoalSightSeverity.critical:
      return Icons.warning_rounded;
    case GoalSightSeverity.neutral:
      return Icons.insights_rounded;
  }
}
