import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/admin/data/admin_mock_data.dart';

class ManagerDetailsPage extends StatelessWidget {
  const ManagerDetailsPage({super.key, required this.managerId});
  final String managerId;

  @override
  Widget build(BuildContext context) {
    final manager = AdminMockData.managers.firstWhere((m) => m.id == managerId,
        orElse: () => AdminMockData.managers.first);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(manager.name),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(manager.imageUrl),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(manager.name,
                        style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 24)),
                    Text(manager.email,
                        style: AppTextStyles.caption(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: manager.isActive
                            ? AppColors.success.withValues(alpha: 0.2)
                            : AppColors.danger.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        manager.isActive ? 'Active Account' : 'Suspended Account',
                        style: TextStyle(
                            color: manager.isActive ? AppColors.success : AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Performance Overview',
              style: AppTextStyles.title(color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Uploads', '${manager.uploadCount}', Icons.cloud_upload)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Matches', '${manager.matchesAnalyzed}', Icons.sports_soccer)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Rating', manager.tacticalRating.toStringAsFixed(1), Icons.star)),
            ],
          ),
          const SizedBox(height: 32),
          Text('Permissions & Access',
              style: AppTextStyles.title(color: Colors.white)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              children: [
                _buildPermissionRow('Upload Matches', true),
                const Divider(),
                _buildPermissionRow('Edit Player Data', true),
                const Divider(),
                _buildPermissionRow('Manage Sub-Staff', false),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                foregroundColor: AppColors.danger,
              ),
              child: Text(manager.isActive ? 'Suspend Manager' : 'Reactivate Manager'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryPurple, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.title(color: Colors.white)),
          Text(label, style: AppTextStyles.caption(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String title, bool isGranted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.body(color: Colors.white)),
          Switch(
            value: isGranted,
            onChanged: (val) {},
            activeColor: AppColors.accentCyan,
          ),
        ],
      ),
    );
  }
}
