import 'package:flutter/material.dart';
import 'package:goal_sight/core/theme/app_theme.dart';
import 'package:goal_sight/core/utils/responsive.dart';

class InfoTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const InfoTile({super.key, required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(context.rs(AppSpacing.md)),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.rs(AppSpacing.sm)),
              decoration: BoxDecoration(
                color: AppColors.backgroundAlt,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: context.rs(20), color: AppColors.primaryBlue),
            ),
            SizedBox(width: context.rs(AppSpacing.md)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.caption(color: AppColors.textMuted)),
                  SizedBox(height: context.rs(AppSpacing.xs)),
                  Text(value, style: AppTextStyles.body(color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
