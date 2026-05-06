import 'package:flutter/material.dart';
import 'package:goal_sight/core/theme/app_theme.dart';
import 'package:goal_sight/core/utils/responsive.dart';

class ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  const ActionTile({Key? key, required this.label, required this.icon, required this.onTap, this.destructive = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.rs(AppSpacing.sm)),
        child: Row(
          children: [
            Icon(icon, color: destructive ? AppColors.danger : AppColors.textPrimary, size: context.rs(20)),
            SizedBox(width: context.rs(AppSpacing.md)),
            Expanded(child: Text(label, style: AppTextStyles.body(color: destructive ? AppColors.danger : AppColors.textPrimary))),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
