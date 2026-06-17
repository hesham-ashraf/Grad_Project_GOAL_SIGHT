import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/gs_animated_bar.dart';
import '../../widgets/fan/fan_profile_advanced_widgets.dart';
import '../../widgets/fan/profile_widgets.dart';
import '../../widgets/fan/tap_scale.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  // header + stats + CTA row + content group + settings group + account
  static const int _sectionCount = 6;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();

    _fades = List.generate(_sectionCount, (i) {
      final start = (i * 0.12).clamp(0.0, 0.85);
      final end = (start + 0.25).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic));
    });

    _slides = _fades
        .map((f) =>
            Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
                .animate(f))
        .toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _section(int idx, Widget child) => FadeTransition(
        opacity: _fades[idx],
        child: SlideTransition(position: _slides[idx], child: child),
      );

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    final name = user?.name ?? 'Guest Fan';
    final email = user?.email.isNotEmpty == true ? user!.email : 'user@example.com';
    final roleLabel = user?.role.label ?? UserRole.fan.label;
    final firstName = name.split(' ').first;

    final h = context.rs(20, min: 16, max: 24);
    final hPad = context.rs(20, min: 16, max: 28);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            hPad,
            context.rs(28, min: 20, max: 40),
            hPad,
            context.rs(100, min: 80, max: 120),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 0. Identity Header ────────────────────────────────────────
              _section(0, ProfileHeader(name: name, role: roleLabel, subtitle: 'Football Enthusiast')),
              SizedBox(height: h),

              // ── 1. Key Stats (4 numbers) ──────────────────────────────────
              _section(1, _CompactStatsRow(name: firstName)),
              SizedBox(height: h),

              // ── 2. Primary CTAs ───────────────────────────────────────────
              _section(2, _PrimaryCtaRow()),
              SizedBox(height: h * 1.25),

              // ── Section label ─────────────────────────────────────────────
              _section(2, _GroupLabel('My Content')),
              SizedBox(height: context.rs(10, min: 8, max: 14)),

              // ── 3. Content group (expandable tiles) ───────────────────────
              _section(3, _ContentGroup()),
              SizedBox(height: h * 1.25),

              // ── Section label ─────────────────────────────────────────────
              _section(3, _GroupLabel('Settings')),
              SizedBox(height: context.rs(10, min: 8, max: 14)),

              // ── 4. Settings group ─────────────────────────────────────────
              _section(4, _SettingsGroup()),
              SizedBox(height: h * 1.25),

              // ── Section label ─────────────────────────────────────────────
              _section(4, _GroupLabel('Account')),
              SizedBox(height: context.rs(10, min: 8, max: 14)),

              // ── 5. Account ────────────────────────────────────────────────
              _section(
                5,
                AccountManagementCard(
                  email: email,
                  onLogout: () => ref.read(authControllerProvider.notifier).logout(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Group label ──────────────────────────────────────────────────────────────

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
        fontSize: context.sp(10, min: 9, max: 12),
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─── Compact Stats Row ────────────────────────────────────────────────────────

class _CompactStatsRow extends StatelessWidget {
  const _CompactStatsRow({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withValues(alpha: 0.15),
            AppColors.primaryBlue.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.25)),
      ),
      padding: EdgeInsets.all(context.rs(16, min: 14, max: 20)),
      child: Column(
        children: [
          // XP bar + badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppColors.primaryPurple, AppColors.accentCyan]),
                  borderRadius: AppRadius.chip,
                ),
                child: Text('GOLD FAN',
                    style: AppTextStyles.caption(color: Colors.white)
                        .copyWith(fontWeight: FontWeight.w800, fontSize: 10)),
              ),
              const Spacer(),
              Text('3,240 / 5,000 XP',
                  style: AppTextStyles.caption(color: AppColors.primaryPurple)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          const GsAnimatedBar(
            value: 0.648,
            color: AppColors.primaryPurple,
            backgroundColor: AppColors.surface,
            height: 6,
            delay: Duration(milliseconds: 400),
          ),
          const SizedBox(height: 14),
          // 4 stats
          Row(
            children: [
              const Expanded(child: _Stat('47', 'Matches\nViewed', AppColors.accentCyan)),
              _VDivider(),
              const Expanded(child: _Stat('23', 'Analyses\nRead', AppColors.accentGreen)),
              _VDivider(),
              const Expanded(child: _Stat('3', 'Clubs\nFollowed', AppColors.warning)),
              _VDivider(),
              const Expanded(child: _Stat('12', 'Saved', AppColors.primaryPurple)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.color);
  final String value, label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.title(color: color)
                .copyWith(fontSize: context.sp(18, min: 15, max: 22))),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.caption(color: AppColors.textMuted)
                .copyWith(fontSize: 9),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 36, color: AppColors.outlineSubtle.withValues(alpha: 0.6));
  }
}

// ─── Primary CTA Row ──────────────────────────────────────────────────────────

class _PrimaryCtaRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TapScale(
            onTap: () {},
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.rs(12, min: 10, max: 16),
                vertical: context.rs(12, min: 10, max: 14),
              ),
              decoration: const BoxDecoration(
                gradient: AppGradients.brand,
                borderRadius: AppRadius.button,
                boxShadow: AppShadows.buttonGlow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text('Edit Profile',
                      style: AppTextStyles.button(color: Colors.white)
                          .copyWith(fontSize: context.sp(13, min: 12, max: 15))),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TapScale(
            onTap: () {},
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.rs(12, min: 10, max: 16),
                vertical: context.rs(12, min: 10, max: 14),
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadius.button,
                border: Border.all(color: AppColors.outline.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.share_outlined, color: AppColors.accentCyan, size: 16),
                  const SizedBox(width: 8),
                  Text('Share Profile',
                      style: AppTextStyles.button(color: AppColors.accentCyan)
                          .copyWith(fontSize: context.sp(13, min: 12, max: 15))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Content Group (Favourites · Saved · Achievements as expandable tiles) ────

class _ContentGroup extends StatefulWidget {
  @override
  State<_ContentGroup> createState() => _ContentGroupState();
}

class _ContentGroupState extends State<_ContentGroup> {
  bool _favExpanded = true;
  bool _savedExpanded = false;
  bool _achievementsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _ExpandableTile(
            icon: Icons.favorite_rounded,
            color: AppColors.danger,
            title: 'Favourites',
            subtitle: 'Clubs & players you follow',
            expanded: _favExpanded,
            onToggle: () => setState(() => _favExpanded = !_favExpanded),
            content: const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FavoritesCard(),
            ),
          ),
          _Hairline(),
          _ExpandableTile(
            icon: Icons.bookmark_rounded,
            color: AppColors.accentGreen,
            title: 'Saved Analyses',
            subtitle: '12 saved match reports',
            expanded: _savedExpanded,
            onToggle: () => setState(() => _savedExpanded = !_savedExpanded),
            content: const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SavedMatchesCard(),
            ),
          ),
          _Hairline(),
          _ExpandableTile(
            icon: Icons.emoji_events_rounded,
            color: AppColors.warning,
            title: 'Achievements',
            subtitle: '3 / 5 unlocked',
            expanded: _achievementsExpanded,
            onToggle: () => setState(() => _achievementsExpanded = !_achievementsExpanded),
            content: const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: AchievementsCard(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Group ───────────────────────────────────────────────────────────

class _SettingsGroup extends StatefulWidget {
  @override
  State<_SettingsGroup> createState() => _SettingsGroupState();
}

class _SettingsGroupState extends State<_SettingsGroup> {
  bool _notifsExpanded = false;
  bool _prefsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _ExpandableTile(
            icon: Icons.notifications_rounded,
            color: AppColors.accentCyan,
            title: 'Notifications',
            subtitle: 'Manage your alert preferences',
            expanded: _notifsExpanded,
            onToggle: () => setState(() => _notifsExpanded = !_notifsExpanded),
            content: const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: NotificationSettingsCard(),
            ),
          ),
          _Hairline(),
          _ExpandableTile(
            icon: Icons.tune_rounded,
            color: AppColors.primaryPurple,
            title: 'Preferences',
            subtitle: 'Language, theme & more',
            expanded: _prefsExpanded,
            onToggle: () => setState(() => _prefsExpanded = !_prefsExpanded),
            content: const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: PreferencesCard(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _Hairline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.outlineSubtle.withValues(alpha: 0.5),
    );
  }
}

class _ExpandableTile extends StatelessWidget {
  const _ExpandableTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onToggle,
    required this.content,
  });

  final IconData icon;
  final Color color;
  final String title, subtitle;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.rs(16, min: 14, max: 20),
              vertical: context.rs(14, min: 12, max: 18),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTextStyles.body(color: AppColors.textPrimary)
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text(subtitle,
                          style: AppTextStyles.caption(color: AppColors.textMuted)
                              .copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: expanded ? content : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
