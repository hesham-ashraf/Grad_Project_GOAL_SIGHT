import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/admin/admin_dashboard_widgets.dart';
import '../../widgets/admin/tactical_insight_widget.dart';
import '../../../features/admin/data/admin_mock_data.dart';

class AdminHomeDashboard extends StatefulWidget {
  const AdminHomeDashboard({super.key});

  @override
  State<AdminHomeDashboard> createState() => _AdminHomeDashboardState();
}

class _AdminHomeDashboardState extends State<AdminHomeDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _fades;
  late List<Animation<Offset>> _slides;

  static const int _sectionCount = 7;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    _fades = List.generate(_sectionCount, (i) {
      final start = (i * 0.10).clamp(0.0, 0.80);
      final end = (start + 0.28).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _slides = _fades.map((f) {
      return Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
          .animate(f);
    }).toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _reveal(int index, Widget child) {
    return FadeTransition(
      opacity: _fades[index],
      child: SlideTransition(position: _slides[index], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insights = AdminMockData.tacticalInsights;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.primaryPurple, size: 20),
            const SizedBox(width: 8),
            Text(
              'Admin Dashboard',
              style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 18),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        physics: const BouncingScrollPhysics(),
        children: [
          // 0 — Hero Header
          _reveal(0, const AdminDashboardHero()),
          const SizedBox(height: 20),

          // 1 — Tactical Analytics
          _reveal(1, const AdminTacticalAnalyticsSection()),
          const SizedBox(height: 20),

          // 2 — Squad Condition
          _reveal(2, const AdminSquadConditionSection()),
          const SizedBox(height: 20),

          // 3 — Quick Actions
          _reveal(3, AdminQuickActionsSection(
            onAddManager: _showAddManagerSheet,
          )),
          const SizedBox(height: 20),

          // 4 — Activity Feed
          _reveal(4, const AdminActivityFeedSection()),
          const SizedBox(height: 20),

          // 5 — AI Tactical Insights
          _reveal(5, Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('AI Tactical Insights',
                      style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text('AI Generated',
                        style: AppTextStyles.caption(color: AppColors.accentCyan).copyWith(fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...insights.take(3).map((insight) => TacticalInsightWidget(insight: insight)),
            ],
          )),
          const SizedBox(height: 20),

          // 6 — Alerts
          _reveal(6, const AdminAlertsSection()),
        ],
      ),
    );
  }

  void _showAddManagerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddManagerSheet(),
    );
  }
}

// ─── Add Manager Bottom Sheet ────────────────────────────────────────────────

class _AddManagerSheet extends StatefulWidget {
  const _AddManagerSheet();

  @override
  State<_AddManagerSheet> createState() => _AddManagerSheetState();
}

class _AddManagerSheetState extends State<_AddManagerSheet> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _canUpload = true;
  bool _canEditPlayers = true;
  bool _canManageStaff = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_add_outlined, color: AppColors.primaryPurple, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Add New Manager', style: AppTextStyles.title(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 20),
          _SheetField(controller: _nameCtrl, label: 'Full Name', hint: 'e.g. Jose Mourinho', icon: Icons.person_outline),
          const SizedBox(height: 12),
          _SheetField(controller: _emailCtrl, label: 'Email Address', hint: 'jose@club.com', icon: Icons.email_outlined),
          const SizedBox(height: 20),
          Text('Permissions', style: AppTextStyles.body(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _PermissionToggle(
            title: 'Upload Matches',
            subtitle: 'Allow video uploads',
            value: _canUpload,
            onChanged: (v) => setState(() => _canUpload = v),
          ),
          _PermissionToggle(
            title: 'Edit Player Data',
            subtitle: 'Modify squad information',
            value: _canEditPlayers,
            onChanged: (v) => setState(() => _canEditPlayers = v),
          ),
          _PermissionToggle(
            title: 'Manage Sub-Staff',
            subtitle: 'Add assistant managers',
            value: _canManageStaff,
            onChanged: (v) => setState(() => _canManageStaff = v),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: Text('Add Manager', style: AppTextStyles.button(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  const _SheetField({required this.controller, required this.label, required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: AppTextStyles.body(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body(color: AppColors.textMuted),
            prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
            filled: true,
            fillColor: AppColors.surfaceRaised,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primaryPurple),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _PermissionToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PermissionToggle({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.body(color: Colors.white)),
              Text(subtitle, style: AppTextStyles.caption(color: AppColors.textMuted)),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accentCyan,
          ),
        ],
      ),
    );
  }
}
