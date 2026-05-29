import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../state_management/app_providers.dart';

class AdminProfilePage extends ConsumerStatefulWidget {
  const AdminProfilePage({super.key});

  @override
  ConsumerState<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends ConsumerState<AdminProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _fades;
  late List<Animation<Offset>> _slides;

  // Notification preferences
  bool _alertsEnabled = true;
  bool _uploadNotifs = true;
  bool _weeklyDigest = true;
  bool _systemAlerts = true;
  bool _twoFaEnabled = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
    _fades = List.generate(5, (i) {
      final start = (i * 0.15).clamp(0.0, 0.7);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _ctrl, curve: Interval(start, end, curve: Curves.easeOutCubic));
    });
    _slides = _fades.map((f) =>
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(f)).toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _reveal(int i, Widget child) {
    return FadeTransition(opacity: _fades[i], child: SlideTransition(position: _slides[i], child: child));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primaryPurple, size: 20),
            const SizedBox(width: 8),
            Text('Admin Profile', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 18)),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        physics: const BouncingScrollPhysics(),
        children: [
          // 0 — Profile header
          _reveal(0, _ProfileHeader()),
          const SizedBox(height: 24),

          // 1 — Club settings
          _reveal(1, _SectionCard(
            title: 'Club Information',
            icon: Icons.shield_outlined,
            color: AppColors.primaryPurple,
            children: [
              _SettingTile(icon: Icons.shield_outlined, label: 'Club Details', subtitle: 'GoalSight FC — Premier League', color: AppColors.primaryPurple, onTap: () {}),
              _Divider(),
              _SettingTile(icon: Icons.sports_soccer_outlined, label: 'Season Settings', subtitle: '2024–25 Season', color: AppColors.accentCyan, onTap: () {}),
              _Divider(),
              _SettingTile(icon: Icons.group_outlined, label: 'Staff Directory', subtitle: '6 managers · 2 analysts', color: AppColors.accentGreen, onTap: () {}),
              _Divider(),
              _SettingTile(icon: Icons.workspace_premium_outlined, label: 'Plan & Billing', subtitle: 'Enterprise · Renews Jan 2026', color: AppColors.warning, onTap: () {}),
            ],
          )),
          const SizedBox(height: 16),

          // 2 — Notification settings
          _reveal(2, _SectionCard(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            color: AppColors.accentCyan,
            children: [
              _ToggleTile(icon: Icons.warning_amber_outlined, label: 'System Alerts', subtitle: 'Fatigue, risk & failure alerts', value: _alertsEnabled, onChanged: (v) => setState(() => _alertsEnabled = v), color: AppColors.danger),
              _Divider(),
              _ToggleTile(icon: Icons.cloud_upload_outlined, label: 'Upload Notifications', subtitle: 'Completed & failed uploads', value: _uploadNotifs, onChanged: (v) => setState(() => _uploadNotifs = v), color: AppColors.accentCyan),
              _Divider(),
              _ToggleTile(icon: Icons.email_outlined, label: 'Weekly Digest', subtitle: 'Summary email every Monday', value: _weeklyDigest, onChanged: (v) => setState(() => _weeklyDigest = v), color: AppColors.accentGreen),
              _Divider(),
              _ToggleTile(icon: Icons.admin_panel_settings_outlined, label: 'System Alerts', subtitle: 'Platform health & updates', value: _systemAlerts, onChanged: (v) => setState(() => _systemAlerts = v), color: AppColors.primaryPurple),
            ],
          )),
          const SizedBox(height: 16),

          // 3 — Security settings
          _reveal(3, _SectionCard(
            title: 'Security',
            icon: Icons.security_outlined,
            color: AppColors.accentGreen,
            children: [
              _ToggleTile(icon: Icons.lock_outlined, label: 'Two-Factor Authentication', subtitle: '2FA via Authenticator app', value: _twoFaEnabled, onChanged: (v) => setState(() => _twoFaEnabled = v), color: AppColors.accentGreen),
              _Divider(),
              _SettingTile(icon: Icons.password_outlined, label: 'Change Password', subtitle: 'Last changed 3 months ago', color: AppColors.accentCyan, onTap: () {}),
              _Divider(),
              _SettingTile(icon: Icons.devices_outlined, label: 'Active Sessions', subtitle: '2 devices signed in', color: AppColors.warning, onTap: () {}),
              _Divider(),
              _SettingTile(icon: Icons.history_outlined, label: 'Login History', subtitle: 'View recent sign-ins', color: AppColors.textMuted, onTap: () {}),
            ],
          )),
          const SizedBox(height: 16),

          // 4 — Preferences & logout
          _reveal(4, Column(
            children: [
              _SectionCard(
                title: 'Appearance',
                icon: Icons.palette_outlined,
                color: AppColors.warning,
                children: [
                  _SettingTile(icon: Icons.dark_mode_outlined, label: 'Theme', subtitle: 'Dark Mode Active', color: AppColors.warning, onTap: () {}),
                  _Divider(),
                  _SettingTile(icon: Icons.language_outlined, label: 'Language', subtitle: 'English (UK)', color: AppColors.textMuted, onTap: () {}),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                  icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                  label: Text('Sign Out', style: AppTextStyles.button(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }
}

// ─── Profile Header ──────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withValues(alpha: 0.22),
            AppColors.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.4), width: 2),
            ),
            child: const Icon(Icons.admin_panel_settings, color: AppColors.primaryPurple, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('System Administrator',
                    style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 18)),
                const SizedBox(height: 4),
                Text('admin@goalsight.com',
                    style: AppTextStyles.caption(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _Badge(label: 'ADMIN', color: AppColors.primaryPurple),
                    _Badge(label: 'ENTERPRISE', color: AppColors.accentGreen),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: AppTextStyles.caption(color: color).copyWith(fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 15)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ─── Setting Tile ─────────────────────────────────────────────────────────────

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _SettingTile({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.body(color: Colors.white)),
                  Text(subtitle, style: AppTextStyles.caption(color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Toggle Tile ─────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;
  const _ToggleTile({required this.icon, required this.label, required this.subtitle, required this.value, required this.onChanged, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.body(color: Colors.white)),
                Text(subtitle, style: AppTextStyles.caption(color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accentCyan,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

// ─── Divider ─────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.outline.withValues(alpha: 0.5),
      indent: 50,
    );
  }
}
