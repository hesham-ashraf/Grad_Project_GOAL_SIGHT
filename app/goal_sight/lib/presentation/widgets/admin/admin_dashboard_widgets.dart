// ---------------------------------------------------------------------------
// GoalSight — Admin Dashboard Widgets
//
// Premium analytics sections for the Admin Home Dashboard:
//   • AdminTacticalAnalyticsSection — KPI metrics + efficiency bars
//   • AdminActivityFeedSection      — Rich activity feed with action icons
//   • AdminSquadConditionSection    — Fatigue/risk/health overview
//   • AdminQuickActionsSection      — 4 large CTA tiles
//   • AdminAlertsSection            — Severity-coded alert cards
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/activity_model.dart';
import '../../../features/admin/data/admin_mock_data.dart';

// ============================================================================
// TACTICAL ANALYTICS SECTION
// ============================================================================

class AdminTacticalAnalyticsSection extends StatelessWidget {
  const AdminTacticalAnalyticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_outlined, color: AppColors.primaryPurple, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Tactical Analytics', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
              const Spacer(),
              _LiveBadge(),
            ],
          ),
          const SizedBox(height: 18),
          // KPI Row
          const Row(
            children: [
              _KpiChip(label: 'Possession', value: '62%', color: AppColors.accentCyan),
              SizedBox(width: 8),
              _KpiChip(label: 'xG/Match', value: '2.8', color: AppColors.accentGreen),
              SizedBox(width: 8),
              _KpiChip(label: 'Press %', value: '84%', color: AppColors.primaryPurple),
            ],
          ),
          const SizedBox(height: 18),
          // Efficiency Bars
          const _EfficiencyBar(label: 'Tactical Efficiency', value: 0.84, color: AppColors.accentCyan),
          const SizedBox(height: 10),
          const _EfficiencyBar(label: 'Pressing Intensity', value: 0.78, color: AppColors.primaryPurple),
          const SizedBox(height: 10),
          const _EfficiencyBar(label: 'Chance Creation', value: 0.72, color: AppColors.accentGreen),
          const SizedBox(height: 16),
          // Ratings Row
          const Row(
            children: [
              Expanded(child: _RatingCell(label: 'Attack', value: '8.7', color: AppColors.accentGreen)),
              SizedBox(width: 8),
              Expanded(child: _RatingCell(label: 'Midfield', value: '8.2', color: AppColors.accentCyan)),
              SizedBox(width: 8),
              Expanded(child: _RatingCell(label: 'Defence', value: '7.9', color: AppColors.warning)),
              SizedBox(width: 8),
              Expanded(child: _RatingCell(label: 'Pressing', value: '8.4', color: AppColors.primaryPurple)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.accentGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text('LIVE', style: AppTextStyles.caption(color: AppColors.accentGreen).copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _KpiChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.title(color: color).copyWith(fontSize: 18)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _EfficiencyBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _EfficiencyBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.caption(color: AppColors.textSecondary)),
            Text('${(value * 100).toInt()}%', style: AppTextStyles.caption(color: color)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.surfaceRaised,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _RatingCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RatingCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.body(color: color).copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ============================================================================
// ACTIVITY FEED SECTION
// ============================================================================

class AdminActivityFeedSection extends StatelessWidget {
  const AdminActivityFeedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = AdminMockData.recentActivity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Activity Feed', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
              child: Text('View All', style: AppTextStyles.caption(color: AppColors.primaryPurple)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.outline),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length > 5 ? 5 : activities.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 1,
              color: AppColors.outline.withValues(alpha: 0.5),
              indent: 56,
            ),
            itemBuilder: (context, i) => _ActivityTile(activity: activities[i]),
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityModel activity;
  const _ActivityTile({required this.activity});

  Color get _actionColor {
    final action = activity.action.toLowerCase();
    if (action.contains('analyzed') || action.contains('uploaded')) return AppColors.accentCyan;
    if (action.contains('updated') || action.contains('permissions')) return AppColors.primaryPurple;
    if (action.contains('downloaded') || action.contains('generated')) return AppColors.accentGreen;
    if (action.contains('suspended') || action.contains('added')) return AppColors.warning;
    return AppColors.textMuted;
  }

  IconData get _actionIcon {
    final action = activity.action.toLowerCase();
    if (action.contains('analyzed')) return Icons.analytics_outlined;
    if (action.contains('uploaded')) return Icons.cloud_upload_outlined;
    if (action.contains('downloaded')) return Icons.download_outlined;
    if (action.contains('permissions') || action.contains('updated')) return Icons.security_outlined;
    if (action.contains('added')) return Icons.person_add_outlined;
    if (action.contains('suspended')) return Icons.block_outlined;
    if (action.contains('generated') || action.contains('report')) return Icons.summarize_outlined;
    if (action.contains('reviewed')) return Icons.preview_outlined;
    return Icons.history;
  }

  String get _timeAgo {
    final diff = DateTime.now().difference(activity.timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _actionColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_actionIcon, color: _actionColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: AppTextStyles.caption(color: Colors.white).copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${activity.userName} · ${activity.action}',
                  style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(_timeAgo, style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

// ============================================================================
// SQUAD CONDITION SECTION
// ============================================================================

class AdminSquadConditionSection extends StatelessWidget {
  const AdminSquadConditionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final squad = AdminMockData.squad;
    final avgFatigue = squad.map((p) => p.fatigueLevel).reduce((a, b) => a + b) / squad.length;
    final avgRisk = squad.map((p) => p.injuryRisk).reduce((a, b) => a + b) / squad.length;
    final highRiskCount = squad.where((p) => p.injuryRisk > 50).length;
    final highFatigueCount = squad.where((p) => p.fatigueLevel > 75).length;
    final squadHealth = 100 - (avgFatigue * 0.4) - (avgRisk * 0.6);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.health_and_safety_outlined, color: AppColors.warning, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Squad Condition', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
              const Spacer(),
              _HealthScore(value: squadHealth),
            ],
          ),
          const SizedBox(height: 18),
          // Health bars
          _HealthBar(label: 'Avg Fatigue', value: avgFatigue / 100, valueText: '${avgFatigue.toInt()}%', color: _fatigueColor(avgFatigue)),
          const SizedBox(height: 10),
          _HealthBar(label: 'Avg Injury Risk', value: avgRisk / 100, valueText: '${avgRisk.toInt()}%', color: _riskColor(avgRisk)),
          const SizedBox(height: 10),
          _HealthBar(label: 'Squad Health', value: squadHealth / 100, valueText: '${squadHealth.toInt()}%', color: AppColors.accentGreen),
          const SizedBox(height: 16),
          // Alert chips
          Row(
            children: [
              _ConditionChip(
                icon: Icons.warning_amber_rounded,
                label: '$highRiskCount High Risk',
                color: AppColors.danger,
              ),
              const SizedBox(width: 8),
              _ConditionChip(
                icon: Icons.local_fire_department_outlined,
                label: '$highFatigueCount High Fatigue',
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              _ConditionChip(
                icon: Icons.check_circle_outline,
                label: '${squad.length - highRiskCount} Fit',
                color: AppColors.accentGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _fatigueColor(double v) {
    if (v > 75) return AppColors.danger;
    if (v > 55) return AppColors.warning;
    return AppColors.accentGreen;
  }

  Color _riskColor(double v) {
    if (v > 50) return AppColors.danger;
    if (v > 30) return AppColors.warning;
    return AppColors.accentGreen;
  }
}

class _HealthScore extends StatelessWidget {
  final double value;
  const _HealthScore({required this.value});

  Color get _color {
    if (value >= 70) return AppColors.accentGreen;
    if (value >= 50) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_outline, color: _color, size: 12),
          const SizedBox(width: 4),
          Text('${value.toInt()}%', style: AppTextStyles.caption(color: _color).copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  final String label;
  final double value;
  final String valueText;
  final Color color;
  const _HealthBar({required this.label, required this.value, required this.valueText, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.caption(color: AppColors.textSecondary)),
            Text(valueText, style: AppTextStyles.caption(color: color).copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceRaised,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _ConditionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ConditionChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption(color: color).copyWith(fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// QUICK ACTIONS SECTION
// ============================================================================

class AdminQuickActionsSection extends StatelessWidget {
  final VoidCallback? onAddManager;
  const AdminQuickActionsSection({super.key, this.onAddManager});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _ActionTile(
              icon: Icons.person_add_rounded,
              label: 'Add Manager',
              sublabel: 'Onboard staff',
              color: AppColors.primaryPurple,
              onTap: onAddManager ?? () {},
            )),
            const SizedBox(width: 10),
            Expanded(child: _ActionTile(
              icon: Icons.summarize_outlined,
              label: 'Generate Report',
              sublabel: 'Club analytics',
              color: AppColors.accentCyan,
              onTap: () {},
            )),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _ActionTile(
              icon: Icons.security_outlined,
              label: 'Manage Permissions',
              sublabel: 'Access control',
              color: AppColors.accentGreen,
              onTap: () => context.push('/admin/managers'),
            )),
            const SizedBox(width: 10),
            Expanded(child: _ActionTile(
              icon: Icons.groups_outlined,
              label: 'Squad Review',
              sublabel: 'Player health',
              color: AppColors.warning,
              onTap: () => context.push('/admin/squad'),
            )),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.sublabel, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.caption(color: Colors.white).copyWith(fontWeight: FontWeight.w700, fontSize: 12)),
                  Text(sublabel, style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ALERTS SECTION
// ============================================================================

class AdminAlertsSection extends StatelessWidget {
  const AdminAlertsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = AdminMockData.alerts;
    final unreadCount = alerts.where((a) => !a.isRead).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Alerts', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('$unreadCount', style: AppTextStyles.caption(color: AppColors.danger).copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        ...alerts.take(4).map((alert) => _AlertCard(alert: alert)),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AdminAlertModel alert;
  const _AlertCard({required this.alert});

  Color get _levelColor {
    switch (alert.level) {
      case AlertLevel.critical:
        return AppColors.danger;
      case AlertLevel.warning:
        return AppColors.warning;
      case AlertLevel.info:
        return AppColors.accentCyan;
    }
  }

  IconData get _levelIcon {
    switch (alert.level) {
      case AlertLevel.critical:
        return Icons.error_outline;
      case AlertLevel.warning:
        return Icons.warning_amber_outlined;
      case AlertLevel.info:
        return Icons.info_outline;
    }
  }

  String get _timeAgo {
    final diff = DateTime.now().difference(alert.timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alert.isRead
            ? AppColors.surfaceElevated
            : _levelColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: alert.isRead
              ? AppColors.outline
              : _levelColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _levelColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_levelIcon, color: _levelColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: AppTextStyles.caption(color: Colors.white)
                            .copyWith(fontWeight: alert.isRead ? FontWeight.w500 : FontWeight.w700),
                      ),
                    ),
                    if (!alert.isRead)
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _levelColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  alert.description,
                  style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(_timeAgo, style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

// ============================================================================
// ADMIN HERO HEADER
// ============================================================================

class AdminDashboardHero extends StatelessWidget {
  const AdminDashboardHero({super.key});

  @override
  Widget build(BuildContext context) {
    final managers = AdminMockData.managers;
    final activeManagers = managers.where((m) => m.isActive).length;
    final squad = AdminMockData.squad;
    final unreadAlerts = AdminMockData.alerts.where((a) => !a.isRead).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withValues(alpha: 0.25),
            AppColors.accentCyan.withValues(alpha: 0.12),
            AppColors.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.primaryPurple, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GoalSight FC', style: AppTextStyles.title(color: Colors.white)),
                    Text('System Operational', style: AppTextStyles.caption(color: AppColors.accentGreen)),
                  ],
                ),
              ),
              if (unreadAlerts > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_active, color: AppColors.danger, size: 14),
                      const SizedBox(width: 4),
                      Text('$unreadAlerts', style: AppTextStyles.caption(color: AppColors.danger).copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _HeroStat(value: '$activeManagers/${managers.length}', label: 'Active Managers', icon: Icons.manage_accounts_outlined, color: AppColors.accentCyan),
              _VertDivider(),
              _HeroStat(value: '${squad.length}', label: 'Players Tracked', icon: Icons.groups_outlined, color: AppColors.primaryPurple),
              _VertDivider(),
              const _HeroStat(value: '391', label: 'Total Analyses', icon: Icons.analytics_outlined, color: AppColors.accentGreen),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _HeroStat({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 18)),
          Text(label, style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.outline);
  }
}

