import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/admin/data/admin_mock_data.dart';
import '../../widgets/admin/tactical_insight_widget.dart';

class ClubAnalyticsPage extends StatelessWidget {
  const ClubAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final insights = AdminMockData.tacticalInsights;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Club Intelligence'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
        children: [
          _buildIdentityCard(),
          const SizedBox(height: 24),
          Text('Key Analytics', style: AppTextStyles.title(color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Possession', '62%', Icons.data_usage, AppColors.accentCyan)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('xG/Match', '2.1', Icons.show_chart, AppColors.success)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Avg Fatigue', '68%', Icons.battery_charging_full, AppColors.warning)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('High Press', '84%', Icons.speed, AppColors.primaryPurple)),
            ],
          ),
          const SizedBox(height: 24),
          Text('Tactical Insights', style: AppTextStyles.title(color: Colors.white)),
          const SizedBox(height: 12),
          ...insights.map((insight) => TacticalInsightWidget(insight: insight)),
        ],
      ),
    );
  }

  Widget _buildIdentityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.3)),
        boxShadow: AppShadows.cardGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fingerprint, color: AppColors.primaryPurple),
              const SizedBox(width: 10),
              Text('Tactical Identity', style: AppTextStyles.caption(color: AppColors.primaryPurple)),
            ],
          ),
          const SizedBox(height: 12),
          Text('High-Intensity Possession', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            'The club primarily relies on a high defensive line with aggressive counter-pressing. Most attacks are initiated from the wide areas.',
            style: AppTextStyles.body(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag('Gegenpressing'),
              _buildTag('Wing Play'),
              _buildTag('High Line'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Text(text, style: AppTextStyles.caption(color: Colors.white)),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
