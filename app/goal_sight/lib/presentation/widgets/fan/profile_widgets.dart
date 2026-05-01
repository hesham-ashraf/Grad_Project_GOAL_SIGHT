import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import 'tap_scale.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.role,
    required this.subtitle,
  });

  final String name;
  final String role;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar with glow
        Container(
          width: context.rs(100, min: 80, max: 120),
          height: context.rs(100, min: 80, max: 120),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.brand,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: AppColors.primaryPurple.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              _buildInitials(name),
              style: AppTextStyles.headline(color: Colors.white).copyWith(
                fontSize: context.rs(36, min: 28, max: 42),
              ),
            ),
          ),
        ),
        SizedBox(height: context.rs(24, min: 16, max: 32)),
        
        // Name
        Text(
          name,
          style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
            fontSize: context.rs(28, min: 24, max: 32),
          ),
        ),
        SizedBox(height: context.rs(8, min: 6, max: 12)),
        
        // Role & Subtitle
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.rs(10, min: 8, max: 12),
                vertical: context.rs(4, min: 2, max: 6),
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.15),
                borderRadius: AppRadius.chip,
                border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.3)),
              ),
              child: Text(
                role.toUpperCase(),
                style: AppTextStyles.caption(color: AppColors.primaryPurple).copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(width: context.rs(12, min: 8, max: 16)),
            Text(
              subtitle,
              style: AppTextStyles.body(color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  String _buildInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (words.isEmpty) return 'F';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

class ProfileItem extends StatelessWidget {
  const ProfileItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.rs(12, min: 8, max: 16)),
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(20, min: 16, max: 24),
        vertical: context.rs(16, min: 14, max: 20),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.rs(8, min: 6, max: 10)),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.textSecondary,
              size: context.rs(20, min: 16, max: 24),
            ),
          ),
          SizedBox(width: context.rs(16, min: 12, max: 20)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption(color: AppColors.textMuted),
                ),
                SizedBox(height: context.rs(4, min: 2, max: 6)),
                Text(
                  value,
                  style: AppTextStyles.body(color: valueColor ?? AppColors.textPrimary).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.danger : AppColors.textPrimary;

    return TapScale(
      onTap: onTap,
      scaleDown: 0.96,
      child: Container(
        margin: EdgeInsets.only(bottom: context.rs(12, min: 8, max: 16)),
        padding: EdgeInsets.symmetric(
          horizontal: context.rs(20, min: 16, max: 24),
          vertical: context.rs(16, min: 14, max: 20),
        ),
        decoration: BoxDecoration(
          color: isDestructive 
              ? AppColors.danger.withValues(alpha: 0.1) 
              : AppColors.surfaceElevated,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: isDestructive 
                ? AppColors.danger.withValues(alpha: 0.2) 
                : AppColors.outlineSubtle,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: context.rs(22, min: 18, max: 26),
            ),
            SizedBox(width: context.rs(16, min: 12, max: 20)),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.title(color: color).copyWith(
                  fontSize: context.rs(16, min: 14, max: 18),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDestructive ? AppColors.danger : AppColors.textMuted,
              size: context.rs(24, min: 20, max: 28),
            ),
          ],
        ),
      ),
    );
  }
}
