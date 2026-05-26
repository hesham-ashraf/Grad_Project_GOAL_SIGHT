import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/manager_model.dart';
import 'package:go_router/go_router.dart';

class ManagerListCard extends StatelessWidget {
  final ManagerModel manager;

  const ManagerListCard({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/admin/managers/${manager.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(manager.imageUrl),
              backgroundColor: AppColors.surfaceRaised,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manager.name,
                    style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    manager.email,
                    style: AppTextStyles.caption(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: manager.isActive
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: manager.isActive
                          ? AppColors.success.withValues(alpha: 0.5)
                          : AppColors.danger.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    manager.isActive ? 'ACTIVE' : 'DISABLED',
                    style: AppTextStyles.caption(
                      color: manager.isActive ? AppColors.success : AppColors.danger,
                    ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${manager.uploadCount}',
                      style: AppTextStyles.caption(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
