import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/admin/data/admin_mock_data.dart';
import '../../widgets/admin/admin_hero_card.dart';
import '../../widgets/admin/tactical_insight_widget.dart';
import 'package:go_router/go_router.dart';

class AdminHomeDashboard extends StatelessWidget {
  const AdminHomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final recentActivities = AdminMockData.recentActivity;
    final insights = AdminMockData.tacticalInsights;

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by shell
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AdminHeroCard(
            title: 'Club Overview',
            subtitle: 'Performance & Systems Nominal',
            icon: Icons.shield_outlined,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${AdminMockData.managers.length} Managers',
                  style: AppTextStyles.caption(color: Colors.white),
                ),
                Text(
                  '${AdminMockData.squad.length} Players Tracked',
                  style: AppTextStyles.caption(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('AI Tactical Insights', context, '/admin/club-analytics'),
          const SizedBox(height: 12),
          ...insights.take(2).map((insight) => TacticalInsightWidget(insight: insight)),
          const SizedBox(height: 24),
          _buildSectionHeader('Quick Actions', context, null),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildQuickAction(context, Icons.person_add, 'Add Manager', () {})),
              const SizedBox(width: 12),
              Expanded(child: _buildQuickAction(context, Icons.analytics, 'Run Report', () {})),
              const SizedBox(width: 12),
              Expanded(child: _buildQuickAction(context, Icons.security, 'Permissions', () {})),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Recent Activity', context, null),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              children: recentActivities.map((activity) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.2),
                        child: const Icon(Icons.history, size: 16, color: AppColors.primaryPurple),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.description,
                              style: AppTextStyles.body(color: Colors.white).copyWith(fontSize: 14),
                            ),
                            Text(
                              '${activity.userName} • ${activity.action}',
                              style: AppTextStyles.caption(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 100), // padding for bottom nav
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context, String? route) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 18),
        ),
        if (route != null)
          TextButton(
            onPressed: () => context.push(route),
            child: const Text('View All', style: TextStyle(color: AppColors.primaryPurple)),
          ),
      ],
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accentCyan),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.caption(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
