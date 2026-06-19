import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/fan_profile_model.dart';
import '../../../providers/fan_profile_provider.dart';
import '../../../shared/widgets/gs_animated_bar.dart';

// ─── Shared Helpers ───────────────────────────────────────────────────────────

void _showComingSoonSnack(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature — coming soon'),
      backgroundColor: AppColors.surfaceElevated,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
      duration: const Duration(seconds: 2),
    ),
  );
}

class _GlassCard extends StatelessWidget {
  const _GlassCard(
      {required this.child, this.gradient, this.borderColor});
  final Widget child;
  final Gradient? gradient;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ??
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.surfaceElevated, AppColors.surface],
            ),
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: borderColor ?? AppColors.outlineSubtle),
      ),
      padding: EdgeInsets.all(context.rs(18, min: 14, max: 22)),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title,
      required this.icon,
      required this.color,
      this.subtitle,
      this.trailing});
  final String title;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 3,
            height: 22,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Icon(icon, color: color, size: context.rs(18, min: 15, max: 20)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.title(color: AppColors.textPrimary)
                      .copyWith(
                          fontSize: context.rs(16, min: 13, max: 18))),
              if (subtitle != null)
                Text(subtitle!,
                    style: AppTextStyles.caption(color: AppColors.textMuted)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION SETTINGS
// ─────────────────────────────────────────────────────────────────────────────

class NotificationSettingsCard extends StatefulWidget {
  const NotificationSettingsCard({super.key});

  @override
  State<NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<NotificationSettingsCard> {
  final Map<String, bool> _toggles = {
    'Match Alerts': true,
    'Team News': true,
    'Player Updates': false,
    'Live Scores': true,
    'AI Insights': true,
    'Transfer Rumours': false,
  };

  final Map<String, IconData> _icons = {
    'Match Alerts': Icons.sports_soccer_rounded,
    'Team News': Icons.newspaper_rounded,
    'Player Updates': Icons.person_pin_rounded,
    'Live Scores': Icons.scoreboard_rounded,
    'AI Insights': Icons.auto_awesome_rounded,
    'Transfer Rumours': Icons.swap_horiz_rounded,
  };

  final Map<String, Color> _colors = {
    'Match Alerts': AppColors.accentCyan,
    'Team News': AppColors.primaryBlue,
    'Player Updates': AppColors.accentGreen,
    'Live Scores': AppColors.warning,
    'AI Insights': AppColors.primaryPurple,
    'Transfer Rumours': AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Notifications',
              icon: Icons.notifications_rounded,
              color: AppColors.accentCyan,
              subtitle: 'Manage your alert preferences'),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          ..._toggles.entries.map((e) => _NotifToggle(
                label: e.key,
                icon: _icons[e.key]!,
                color: _colors[e.key]!,
                value: e.value,
                onChanged: (v) =>
                    setState(() => _toggles[e.key] = v),
              )),
        ],
      ),
    );
  }
}

class _NotifToggle extends StatelessWidget {
  const _NotifToggle({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(
          horizontal: context.rs(12, min: 10, max: 14),
          vertical: context.rs(10, min: 8, max: 12)),
      decoration: BoxDecoration(
        color: (value ? color : AppColors.textMuted)
            .withValues(alpha: value ? 0.06 : 0.03),
        borderRadius: AppRadius.card,
        border: Border.all(
            color: (value ? color : AppColors.outlineSubtle)
                .withValues(alpha: value ? 0.25 : 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: value ? 0.14 : 0.05),
            ),
            child: Icon(icon,
                color: value ? color : AppColors.textMuted, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: AppTextStyles.body(
                        color: value
                            ? AppColors.textPrimary
                            : AppColors.textMuted)
                    .copyWith(
                        fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.25),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.surface,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAVORITE CLUBS & PLAYERS
// ─────────────────────────────────────────────────────────────────────────────

class FavoritesCard extends ConsumerWidget {
  const FavoritesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data =
        ref.watch(fanProfileProvider).asData?.value ?? FanProfileData.empty;
    final clubs = [
      for (var i = 0; i < data.favoriteClubs.length; i++)
        _FavClub(
          data.favoriteClubs[i].name,
          data.favoriteClubs[i].abbr,
          data.favoriteClubs[i].color,
          i == 0,
        ),
    ];

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Favourites',
              icon: Icons.favorite_rounded,
              color: AppColors.danger,
              subtitle: 'Clubs you follow'),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          if (clubs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('You are not following any clubs yet.',
                  style: AppTextStyles.caption(color: AppColors.textMuted)),
            )
          else ...[
            Text('Clubs',
                style: AppTextStyles.body(color: AppColors.textSecondary)
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 8),
            SizedBox(
              height: context.rs(80, min: 64, max: 92),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: clubs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _ClubChip(club: clubs[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FavClub {
  const _FavClub(this.name, this.abbr, this.color, this.isPrimary);
  final String name, abbr;
  final Color color;
  final bool isPrimary;
}

class _ClubChip extends StatelessWidget {
  const _ClubChip({required this.club});
  final _FavClub club;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.rs(80, min: 64, max: 92),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            club.color.withValues(alpha: 0.18),
            club.color.withValues(alpha: 0.05)
          ],
        ),
        borderRadius: AppRadius.card,
        border: Border.all(
            color: club.color.withValues(
                alpha: club.isPrimary ? 0.5 : 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(club.abbr,
              style: AppTextStyles.title(color: club.color).copyWith(
                  fontSize: context.rs(18, min: 14, max: 22),
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(club.name,
              style: AppTextStyles.caption(color: AppColors.textMuted)
                  .copyWith(fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (club.isPrimary) ...[
            const SizedBox(height: 2),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                  color: club.color, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SAVED MATCHES
// ─────────────────────────────────────────────────────────────────────────────

class SavedMatchesCard extends ConsumerWidget {
  const SavedMatchesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data =
        ref.watch(fanProfileProvider).asData?.value ?? FanProfileData.empty;
    final count = data.savedMatches;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Saved Analyses',
            icon: Icons.bookmark_rounded,
            color: AppColors.accentGreen,
            subtitle: '$count saved match reports',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.1),
                  borderRadius: AppRadius.chip,
                  border: Border.all(
                      color:
                          AppColors.accentGreen.withValues(alpha: 0.25))),
              child: Text('$count',
                  style: AppTextStyles.caption(color: AppColors.accentGreen)
                      .copyWith(fontWeight: FontWeight.w800)),
            ),
          ),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.bookmark_border_rounded,
                    color: AppColors.textMuted, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    count == 0
                        ? 'No saved analyses yet. Bookmark a match report to find it here.'
                        : 'Open the Matches tab to review your saved reports.',
                    style: AppTextStyles.caption(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREFERENCES & SETTINGS
// ─────────────────────────────────────────────────────────────────────────────

class PreferencesCard extends StatefulWidget {
  const PreferencesCard({super.key});

  @override
  State<PreferencesCard> createState() => _PreferencesCardState();
}

class _PreferencesCardState extends State<PreferencesCard> {
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Dark';
  bool _analyticsEnabled = true;
  bool _aiRecommendations = true;
  bool _hapticFeedback = false;

  final _languages = ['English', 'Arabic', 'Spanish', 'French'];
  final _themes = ['Dark', 'Auto'];

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Preferences',
              icon: Icons.tune_rounded,
              color: AppColors.primaryPurple,
              subtitle: 'Personalise your experience'),
          SizedBox(height: context.rs(14, min: 10, max: 18)),

          // Language picker
          _PrefRow(
            icon: Icons.language_rounded,
            color: AppColors.accentCyan,
            label: 'Language',
            child: DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: (v) =>
                  setState(() => _selectedLanguage = v!),
              dropdownColor: AppColors.surfaceElevated,
              underline: const SizedBox.shrink(),
              style: AppTextStyles.caption(color: AppColors.accentCyan)
                  .copyWith(fontWeight: FontWeight.w700),
              items: _languages
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
            ),
          ),

          // Theme picker
          _PrefRow(
            icon: Icons.dark_mode_rounded,
            color: AppColors.primaryPurple,
            label: 'App Theme',
            child: DropdownButton<String>(
              value: _selectedTheme,
              onChanged: (v) =>
                  setState(() => _selectedTheme = v!),
              dropdownColor: AppColors.surfaceElevated,
              underline: const SizedBox.shrink(),
              style: AppTextStyles.caption(color: AppColors.primaryPurple)
                  .copyWith(fontWeight: FontWeight.w700),
              items: _themes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
            ),
          ),

          const SizedBox(height: 4),

          // Toggle preferences
          _TogglePrefRow(
            icon: Icons.bar_chart_rounded,
            color: AppColors.accentGreen,
            label: 'Usage Analytics',
            subtitle: 'Help improve GoalSight',
            value: _analyticsEnabled,
            onChanged: (v) =>
                setState(() => _analyticsEnabled = v),
          ),
          _TogglePrefRow(
            icon: Icons.auto_awesome_rounded,
            color: AppColors.primaryPurple,
            label: 'AI Recommendations',
            subtitle: 'Personalised match suggestions',
            value: _aiRecommendations,
            onChanged: (v) =>
                setState(() => _aiRecommendations = v),
          ),
          _TogglePrefRow(
            icon: Icons.vibration_rounded,
            color: AppColors.warning,
            label: 'Haptic Feedback',
            subtitle: 'Vibration on interactions',
            value: _hapticFeedback,
            onChanged: (v) =>
                setState(() => _hapticFeedback = v),
          ),
        ],
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  const _PrefRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.child});
  final IconData icon;
  final Color color;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(
          horizontal: context.rs(12, min: 10, max: 14),
          vertical: context.rs(10, min: 8, max: 12)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: AppTextStyles.body(color: AppColors.textPrimary)
                    .copyWith(
                        fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          child,
        ],
      ),
    );
  }
}

class _TogglePrefRow extends StatelessWidget {
  const _TogglePrefRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final Color color;
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(
          horizontal: context.rs(12, min: 10, max: 14),
          vertical: context.rs(8, min: 6, max: 10)),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: value ? 0.14 : 0.05),
            ),
            child: Icon(icon,
                color: value ? color : AppColors.textMuted,
                size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        AppTextStyles.body(color: AppColors.textPrimary)
                            .copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                Text(subtitle,
                    style: AppTextStyles.caption(
                        color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.25),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.surface,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACHIEVEMENTS
// ─────────────────────────────────────────────────────────────────────────────

class AchievementsCard extends ConsumerWidget {
  const AchievementsCard({super.key});

  // Cycle of accent colours so each achievement tile is visually distinct.
  static const _palette = [
    AppColors.warning,
    AppColors.accentCyan,
    AppColors.primaryPurple,
    AppColors.accentGreen,
    AppColors.primaryBlue,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data =
        ref.watch(fanProfileProvider).asData?.value ?? FanProfileData.empty;
    final achievements = [
      for (var i = 0; i < data.achievements.length; i++)
        _Achievement(
          data.achievements[i].title,
          data.achievements[i].description,
          data.achievements[i].icon,
          _palette[i % _palette.length],
          data.achievements[i].unlocked,
        ),
    ];
    final total = achievements.isEmpty ? 1 : achievements.length;
    final unlocked = achievements.where((a) => a.unlocked).length;

    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.warning.withValues(alpha: 0.06),
          AppColors.surfaceElevated,
        ],
      ),
      borderColor: AppColors.warning.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Achievements',
            icon: Icons.emoji_events_rounded,
            color: AppColors.warning,
            subtitle: '$unlocked / $total unlocked',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: AppRadius.chip),
              child: Text('$unlocked/$total',
                  style: AppTextStyles.caption(color: AppColors.warning)
                      .copyWith(fontWeight: FontWeight.w800)),
            ),
          ),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          // Progress bar
          GsAnimatedBar(
            value: unlocked / total,
            color: AppColors.warning,
            backgroundColor: AppColors.surface,
            height: 6,
            delay: const Duration(milliseconds: 400),
          ),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          context.adaptiveLayout(
            narrow: Column(
              children: achievements
                  .map((a) => _AchievementTile(achievement: a))
                  .toList(),
            ),
            wide: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: achievements
                  .map((a) => _AchievementTile(achievement: a))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Achievement {
  const _Achievement(
      this.title, this.description, this.icon, this.color, this.unlocked);
  final String title, description;
  final IconData icon;
  final Color color;
  final bool unlocked;
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});
  final _Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(context.rs(10, min: 8, max: 12)),
      decoration: BoxDecoration(
        color: a.unlocked
            ? a.color.withValues(alpha: 0.07)
            : AppColors.surface.withValues(alpha: 0.4),
        borderRadius: AppRadius.card,
        border: Border.all(
            color: a.unlocked
                ? a.color.withValues(alpha: 0.25)
                : AppColors.outlineSubtle.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: a.unlocked
                      ? a.color.withValues(alpha: 0.15)
                      : AppColors.surface,
                  border: Border.all(
                      color: a.unlocked
                          ? a.color.withValues(alpha: 0.4)
                          : AppColors.outlineSubtle),
                ),
                child: Icon(a.icon,
                    color: a.unlocked ? a.color : AppColors.textMuted,
                    size: 16),
              ),
              if (!a.unlocked)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.outlineSubtle)),
                    child: const Icon(Icons.lock_rounded,
                        color: AppColors.textMuted, size: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title,
                    style: AppTextStyles.body(
                            color: a.unlocked
                                ? AppColors.textPrimary
                                : AppColors.textMuted)
                        .copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                Text(a.description,
                    style: AppTextStyles.caption(
                            color: AppColors.textMuted)
                        .copyWith(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (a.unlocked)
            const Icon(Icons.check_circle_rounded,
                color: AppColors.accentGreen, size: 14),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACCOUNT MANAGEMENT
// ─────────────────────────────────────────────────────────────────────────────

class AccountManagementCard extends StatelessWidget {
  const AccountManagementCard(
      {super.key, required this.email, required this.onLogout});
  final String email;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Account',
              icon: Icons.manage_accounts_rounded,
              color: AppColors.primaryBlue,
              subtitle: 'Manage your GoalSight account'),
          SizedBox(height: context.rs(14, min: 10, max: 18)),

          // Account info row
          Container(
            padding: EdgeInsets.all(context.rs(14, min: 12, max: 16)),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.06),
              borderRadius: AppRadius.card,
              border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.3),
                    AppColors.accentCyan.withValues(alpha: 0.1)
                  ]),
                  border: Border.all(
                      color:
                          AppColors.primaryBlue.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.person_rounded,
                    color: AppColors.accentCyan, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GoalSight Fan',
                        style: AppTextStyles.body(
                                color: AppColors.textPrimary)
                            .copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                    Text(email,
                        style: AppTextStyles.caption(
                            color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.primaryPurple,
                      AppColors.accentCyan
                    ]),
                    borderRadius: AppRadius.chip),
                child: Text('GOLD',
                    style: AppTextStyles.caption(color: Colors.white)
                        .copyWith(fontWeight: FontWeight.w800)),
              ),
            ]),
          ),

          SizedBox(height: context.rs(12, min: 8, max: 16)),

          // Action buttons
          _AccountActionTile(
            icon: Icons.edit_rounded,
            label: 'Edit Profile',
            color: AppColors.accentCyan,
            onTap: () {
              HapticService.selection();
              _showComingSoonSnack(context, 'Edit Profile');
            },
          ),
          _AccountActionTile(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            color: AppColors.primaryBlue,
            onTap: () {
              HapticService.selection();
              context.push('/forgot-password');
            },
          ),
          _AccountActionTile(
            icon: Icons.download_rounded,
            label: 'Export My Data',
            color: AppColors.accentGreen,
            onTap: () {
              HapticService.success();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Data export will be emailed to you shortly'),
                  backgroundColor: AppColors.surfaceElevated,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
          _AccountActionTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            color: AppColors.textSecondary,
            onTap: () {
              HapticService.selection();
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceElevated,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg)),
                  title: Text('Help & Support',
                      style: AppTextStyles.title(color: Colors.white)),
                  content: Text(
                    'For assistance, email support@goalsight.app\nor visit goalsight.app/help.',
                    style: AppTextStyles.body(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Close',
                          style: AppTextStyles.caption(
                              color: AppColors.accentCyan)),
                    ),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: context.rs(8, min: 6, max: 10)),

          // Sign out button
          GestureDetector(
            onTap: onLogout,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                  vertical: context.rs(14, min: 12, max: 16)),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: AppRadius.card,
                border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded,
                      color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Text('Sign Out',
                      style: AppTextStyles.body(color: AppColors.danger)
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  const _AccountActionTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(
            horizontal: context.rs(12, min: 10, max: 14),
            vertical: context.rs(12, min: 10, max: 14)),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.5),
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.outlineSubtle),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: context.rs(18, min: 14, max: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: AppTextStyles.body(color: AppColors.textPrimary)
                    .copyWith(
                        fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: context.rs(20, min: 16, max: 22)),
        ]),
      ),
    );
  }
}
