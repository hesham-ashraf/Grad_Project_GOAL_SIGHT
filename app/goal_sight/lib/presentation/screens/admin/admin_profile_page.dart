import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Admin Profile'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.2),
                  child: const Icon(Icons.admin_panel_settings, size: 50, color: AppColors.primaryPurple),
                ),
                const SizedBox(height: 16),
                Text('System Administrator', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 24)),
                Text('admin@goalsight.com', style: AppTextStyles.caption(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Club Information'),
          _buildSettingsTile(icon: Icons.shield, title: 'Club Details', subtitle: 'GOALSIGHT F.C.'),
          _buildSettingsTile(icon: Icons.group, title: 'Staff Directory', subtitle: 'Manage all staff'),
          const SizedBox(height: 24),
          _buildSectionTitle('Preferences & Security'),
          _buildSettingsTile(icon: Icons.notifications, title: 'Notifications', subtitle: 'Manage alerts'),
          _buildSettingsTile(icon: Icons.security, title: 'Security Settings', subtitle: '2FA & Passwords'),
          _buildSettingsTile(icon: Icons.palette, title: 'Appearance', subtitle: 'Dark Mode Active'),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Sign Out', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 18)),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, required String subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.accentCyan),
        title: Text(title, style: AppTextStyles.body(color: Colors.white)),
        subtitle: Text(subtitle, style: AppTextStyles.caption(color: AppColors.textMuted)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () {},
      ),
    );
  }
}
