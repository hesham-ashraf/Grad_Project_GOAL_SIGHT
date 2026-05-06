import 'package:flutter/material.dart';
import 'package:goal_sight/core/theme/app_theme.dart';
import 'package:goal_sight/core/utils/responsive.dart';

class ProfileHeader extends StatelessWidget {
  final String avatarInitials;
  final String name;
  final String role;
  final String club;
  final String? subtitle;

  const ProfileHeader({
    Key? key,
    required this.avatarInitials,
    required this.name,
    required this.role,
    required this.club,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      elevation: 6,
      child: Padding(
        padding: EdgeInsets.all(context.rs(AppSpacing.md)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: context.rs(36),
              backgroundColor: AppColors.primaryBlue,
              child: Text(avatarInitials, style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(fontSize: context.sp(20))),
            ),
            SizedBox(width: context.rs(AppSpacing.md)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.title(color: AppColors.textPrimary)),
                  SizedBox(height: context.rs(AppSpacing.xs)),
                  Row(
                    children: [
                      Flexible(child: Text(role, style: AppTextStyles.body(color: AppColors.textSecondary))),
                      SizedBox(width: context.rs(AppSpacing.sm)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: context.rs(AppSpacing.sm), vertical: context.rs(6)),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundAlt,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(club, style: AppTextStyles.caption(color: AppColors.textPrimary)),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: context.rs(AppSpacing.xs)),
                    Text(subtitle!, style: AppTextStyles.caption(color: AppColors.textMuted)),
                  ]
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
