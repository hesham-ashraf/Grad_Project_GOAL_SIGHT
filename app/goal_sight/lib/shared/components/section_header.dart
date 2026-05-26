import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

class GoalSightSectionHeader extends StatelessWidget {
  const GoalSightSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.filters = const [],
    this.accent = AppColors.accentCyan,
    this.animate = true,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;
  final List<Widget> filters;
  final Color accent;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 3,
              height: context.rs(22, min: 18, max: 26),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            SizedBox(width: context.rs(9, min: 7, max: 11)),
            if (icon != null) ...[
              Icon(icon, color: accent, size: context.rs(18, min: 16, max: 22)),
              SizedBox(width: context.rs(8, min: 6, max: 10)),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
                      fontSize: context.sp(18, min: 15, max: 22),
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: context.rs(3, min: 2, max: 5)),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (actionLabel != null && onAction != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.rs(10, min: 8, max: 12),
                    vertical: context.rs(7, min: 5, max: 8),
                  ),
                ),
                child: Text(actionLabel!),
              ),
          ],
        ),
        if (filters.isNotEmpty) ...[
          SizedBox(height: context.rs(12, min: 8, max: 16)),
          Wrap(spacing: 8, runSpacing: 8, children: filters),
        ],
      ],
    );

    if (!animate) return header;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: header,
    );
  }
}
