import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/app_providers.dart';
import '../widgets/manager_bottom_navigation_bar.dart';

class ManagerProfileScreen extends ConsumerStatefulWidget {
  const ManagerProfileScreen({super.key});

  @override
  ConsumerState<ManagerProfileScreen> createState() =>
      _ManagerProfileScreenState();
}

class _ManagerProfileScreenState extends ConsumerState<ManagerProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  static const int _sectionCount = 5;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _fades = List.generate(_sectionCount, (i) {
      final start = (i * 0.12).clamp(0.0, 0.85);
      final end = (start + 0.24).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _slides = _fades
        .map((f) => Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(f))
        .toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _section(int i, Widget child) => FadeTransition(
        opacity: _fades[i],
        child: SlideTransition(position: _slides[i], child: child),
      );

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    final name = user?.name ?? 'Manager';
    final email = user?.email ?? 'manager@goalsightfc.com';
    final initials = _initials(name);

    final hPad = context.rs(20, min: 16, max: 28);
    final bottomPad = ManagerBottomNavigationBar.totalHeight(context) +
        context.rs(12, min: 8, max: 16);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(hPad, context.rs(24, min: 18, max: 32), hPad, bottomPad),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 0. Profile Hero Card ───────────────────────────────────
                  _section(0, _ProfileHeroCard(
                    name: name,
                    email: email,
                    initials: initials,
                    club: 'GoalSight FC',
                    role: 'Team Manager',
                  )),

                  SizedBox(height: context.rs(18, min: 14, max: 24)),

                  // ── 1. Quick Stats ─────────────────────────────────────────
                  _section(1, const _ManagerQuickStats()),

                  SizedBox(height: context.rs(18, min: 14, max: 24)),

                  // ── 2. Account Details ─────────────────────────────────────
                  _section(2, _AccountDetailsCard(email: email, club: 'GoalSight FC')),

                  SizedBox(height: context.rs(18, min: 14, max: 24)),

                  // ── 3. Tools & Settings ────────────────────────────────────
                  _section(3, const _ToolsCard()),

                  SizedBox(height: context.rs(18, min: 14, max: 24)),

                  // ── 4. Danger Zone ─────────────────────────────────────────
                  _section(4, _DangerZoneCard(
                    onLogout: () =>
                        ref.read(authControllerProvider.notifier).logout(),
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Profile Hero Card ────────────────────────────────────────────────────────

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.name,
    required this.email,
    required this.initials,
    required this.club,
    required this.role,
  });

  final String name;
  final String email;
  final String initials;
  final String club;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.rs(20, min: 16, max: 24)),
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardLarge,
        color: AppColors.surfaceElevated.withValues(alpha: 0.72),
        border: Border.all(color: AppColors.outlineSubtle),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: context.rs(72, min: 60, max: 80),
                height: context.rs(72, min: 60, max: 80),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.brand,
                  boxShadow: AppShadows.buttonGlow,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: AppTextStyles.headline(color: Colors.white).copyWith(
                      fontSize: context.rs(26, min: 22, max: 30),
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.rs(16, min: 12, max: 20)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
                        fontSize: context.rs(22, min: 18, max: 26),
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.rs(4, min: 3, max: 6)),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.rs(10, min: 8, max: 12),
                            vertical: context.rs(4, min: 3, max: 6),
                          ),
                          decoration: const BoxDecoration(
                            gradient: AppGradients.brand,
                            borderRadius: AppRadius.chip,
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: AppTextStyles.caption(color: Colors.white).copyWith(
                              fontSize: context.rs(9, min: 8, max: 10),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        SizedBox(width: context.rs(8, min: 6, max: 10)),
                        Flexible(
                          child: Text(
                            club,
                            style: AppTextStyles.body(color: AppColors.accentCyan).copyWith(
                              fontSize: context.rs(13, min: 12, max: 14),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.rs(4, min: 3, max: 6)),
                    Text(
                      email,
                      style: AppTextStyles.caption(color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Quick Stats ──────────────────────────────────────────────────────────────

class _ManagerQuickStats extends StatelessWidget {
  const _ManagerQuickStats();

  @override
  Widget build(BuildContext context) {
    const stats = [
      _StatItem(label: 'Matches Analyzed', value: '124', icon: Icons.analytics_rounded, color: AppColors.accentCyan),
      _StatItem(label: 'Players Tracked', value: '28', icon: Icons.groups_rounded, color: AppColors.primaryPurple),
      _StatItem(label: 'Win Rate', value: '71%', icon: Icons.emoji_events_rounded, color: AppColors.accentGreen),
    ];

    return Row(
      children: stats.map((s) {
        final isLast = s == stats.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : context.rs(10, min: 8, max: 12)),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.rs(12, min: 10, max: 16),
                vertical: context.rs(14, min: 12, max: 18),
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.card,
                color: s.color.withValues(alpha: 0.07),
                border: Border.all(color: s.color.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s.icon, size: context.rs(22, min: 18, max: 26), color: s.color),
                  SizedBox(height: context.rs(8, min: 6, max: 10)),
                  Text(
                    s.value,
                    style: AppTextStyles.headline(color: AppColors.textPrimary).copyWith(
                      fontSize: context.rs(20, min: 16, max: 24),
                    ),
                  ),
                  SizedBox(height: context.rs(3, min: 2, max: 4)),
                  Text(
                    s.label,
                    style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
                      fontSize: context.rs(10, min: 9, max: 11),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

// ─── Account Details Card ─────────────────────────────────────────────────────

class _AccountDetailsCard extends StatelessWidget {
  const _AccountDetailsCard({required this.email, required this.club});

  final String email;
  final String club;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Account Details',
      icon: Icons.person_outline_rounded,
      color: AppColors.accentCyan,
      children: [
        _DetailRow(icon: Icons.email_outlined, label: 'Email', value: email),
        _DetailRow(icon: Icons.flag_outlined, label: 'Club', value: club),
        const _DetailRow(icon: Icons.badge_outlined, label: 'Role', value: 'Team Manager'),
        const _DetailRow(icon: Icons.verified_outlined, label: 'Status', value: 'Active', valueColor: AppColors.accentGreen),
      ],
    );
  }
}

// ─── Tools Card ──────────────────────────────────────────────────────────────

class _ToolsCard extends StatelessWidget {
  const _ToolsCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Tools & Settings',
      icon: Icons.settings_outlined,
      color: AppColors.primaryPurple,
      children: [
        _ActionRow(
          icon: Icons.edit_outlined,
          label: 'Edit Profile',
          onTap: () {},
        ),
        _ActionRow(
          icon: Icons.notifications_outlined,
          label: 'Notification Settings',
          onTap: () {},
        ),
        _ActionRow(
          icon: Icons.help_outline_rounded,
          label: 'Help & Support',
          onTap: () {},
        ),
      ],
    );
  }
}

// ─── Danger Zone Card ─────────────────────────────────────────────────────────

class _DangerZoneCard extends StatelessWidget {
  const _DangerZoneCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.rs(16, min: 14, max: 20)),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AppColors.danger.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: context.rs(18, min: 16, max: 20),
                  color: AppColors.danger),
              SizedBox(width: context.rs(8, min: 6, max: 10)),
              Text(
                'Account Actions',
                style: AppTextStyles.title(color: AppColors.danger).copyWith(
                  fontSize: context.rs(15, min: 13, max: 17),
                ),
              ),
            ],
          ),
          SizedBox(height: context.rs(14, min: 12, max: 18)),
          GestureDetector(
            onTap: onLogout,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.rs(16, min: 14, max: 20),
                vertical: context.rs(14, min: 12, max: 16),
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.button,
                color: AppColors.danger.withValues(alpha: 0.12),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded,
                      size: context.rs(18, min: 16, max: 20),
                      color: AppColors.danger),
                  SizedBox(width: context.rs(8, min: 6, max: 10)),
                  Text(
                    'Sign Out',
                    style: AppTextStyles.button(color: AppColors.danger).copyWith(
                      fontSize: context.rs(14, min: 13, max: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Section Card ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.rs(16, min: 14, max: 20)),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AppColors.surfaceElevated.withValues(alpha: 0.65),
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.rs(34, min: 28, max: 38),
                height: context.rs(34, min: 28, max: 38),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: AppRadius.chip,
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(icon,
                    size: context.rs(17, min: 14, max: 19), color: color),
              ),
              SizedBox(width: context.rs(10, min: 8, max: 12)),
              Text(
                title,
                style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
                  fontSize: context.rs(16, min: 14, max: 18),
                ),
              ),
            ],
          ),
          SizedBox(height: context.rs(14, min: 12, max: 18)),
          ...children,
        ],
      ),
    );
  }
}

// ─── Detail Row ───────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
    return Padding(
      padding: EdgeInsets.only(bottom: context.rs(10, min: 8, max: 12)),
      child: Row(
        children: [
          Icon(icon,
              size: context.rs(16, min: 14, max: 18),
              color: AppColors.textMuted),
          SizedBox(width: context.rs(10, min: 8, max: 12)),
          Text(
            label,
            style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(
              fontSize: context.rs(13, min: 12, max: 14),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.body(color: valueColor ?? AppColors.textPrimary).copyWith(
                fontSize: context.rs(13, min: 12, max: 14),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Row ───────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.rs(10, min: 8, max: 12)),
        child: Row(
          children: [
            Icon(icon,
                size: context.rs(18, min: 16, max: 20),
                color: AppColors.textSecondary),
            SizedBox(width: context.rs(12, min: 10, max: 14)),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body(color: AppColors.textPrimary).copyWith(
                  fontSize: context.rs(14, min: 13, max: 15),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: context.rs(18, min: 16, max: 20),
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'M';
  if (parts.length == 1) {
    final w = parts.first;
    return w.length >= 2 ? w.substring(0, 2).toUpperCase() : w.toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
