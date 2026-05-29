import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/club_model.dart';
import '../../../shared/widgets/gs_animated_bar.dart';
import '../../../shared/widgets/gs_mini_line_chart.dart';

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.gradient, this.borderColor});
  final Widget child;
  final Gradient? gradient;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
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
  const _SectionHeader({required this.title, required this.icon, required this.color, this.subtitle});
  final String title;
  final IconData icon;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 22,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Icon(icon, color: color, size: context.rs(18, min: 15, max: 20)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.title(color: AppColors.textPrimary)
                  .copyWith(fontSize: context.rs(16, min: 13, max: 18))),
              if (subtitle != null)
                Text(subtitle!, style: AppTextStyles.caption(color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 16. CLUB TACTICAL IDENTITY
// ─────────────────────────────────────────────────────────────────────────────

class ClubTacticalIdentityCard extends StatelessWidget {
  const ClubTacticalIdentityCard({super.key, required this.club});
  final ClubModel club;

  List<_TacticIdentity> _buildIdentities() {
    final style = club.playingStyle.toLowerCase();
    return [
      _TacticIdentity(
        style.contains('high') || style.contains('press') ? 'High Press 4-3-3' : 'Organized Build-Up',
        Icons.compress_rounded,
        'Primary tactical system deployed across the season',
        AppColors.primaryPurple,
        0.88,
      ),
      _TacticIdentity(
        club.stats.avgPossession > 55 ? 'Possession Dominant' : 'Counter-Attacking',
        Icons.swap_horiz_rounded,
        'Ball retention style and attacking trigger philosophy',
        AppColors.accentCyan,
        club.stats.avgPossession > 55 ? 0.82 : 0.74,
      ),
      _TacticIdentity(
        club.stats.goalsConceded < 12 ? 'Low Block Defense' : 'Aggressive Pressing',
        Icons.shield_rounded,
        'Defensive structural approach when not in possession',
        AppColors.accentGreen,
        club.stats.goalsConceded < 12 ? 0.78 : 0.65,
      ),
      _TacticIdentity(
        'Rapid Transitions',
        Icons.speed_rounded,
        'Speed of transition from defense to attack phases',
        AppColors.warning,
        0.71,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final identities = _buildIdentities();

    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [
          club.primaryColor.withValues(alpha: 0.1),
          AppColors.surfaceElevated,
          AppColors.primaryPurple.withValues(alpha: 0.06),
        ],
      ),
      borderColor: club.primaryColor.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Tactical Identity',
              icon: Icons.psychology_rounded,
              color: club.primaryColor,
              subtitle: 'AI-analyzed playing philosophy'),
          SizedBox(height: context.rs(16, min: 12, max: 20)),
          ...identities.asMap().entries.map((e) => _TacticIdentityTile(
              identity: e.value,
              delay: Duration(milliseconds: 100 + e.key * 100),
              color: club.primaryColor)),
        ],
      ),
    );
  }
}

class _TacticIdentity {
  const _TacticIdentity(this.name, this.icon, this.description, this.color, this.score);
  final String name, description;
  final IconData icon;
  final Color color;
  final double score;
}

class _TacticIdentityTile extends StatelessWidget {
  const _TacticIdentityTile({required this.identity, required this.delay, required this.color});
  final _TacticIdentity identity;
  final Duration delay;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(context.rs(14, min: 12, max: 16)),
      decoration: BoxDecoration(
        color: identity.color.withValues(alpha: 0.05),
        borderRadius: AppRadius.card,
        border: Border.all(color: identity.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: identity.color.withValues(alpha: 0.12),
            ),
            child: Icon(identity.icon, color: identity.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(identity.name,
                    style: AppTextStyles.body(color: AppColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(identity.description,
                    style: AppTextStyles.caption(color: AppColors.textMuted),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                GsAnimatedBar(
                    value: identity.score,
                    color: identity.color,
                    backgroundColor: AppColors.surface,
                    height: 5,
                    delay: delay),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('${(identity.score * 100).round()}',
              style: AppTextStyles.title(color: identity.color)
                  .copyWith(fontSize: context.rs(18, min: 14, max: 22))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 17. CLUB ANALYTICS DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

class ClubAnalyticsDashboard extends StatelessWidget {
  const ClubAnalyticsDashboard({super.key, required this.club});
  final ClubModel club;

  @override
  Widget build(BuildContext context) {
    final stats = club.stats;
    final attackRating = ((stats.goalsScored / stats.matchesPlayed.clamp(1, 99)) * 10).clamp(0.0, 100.0);
    final defenseRating = (100 - (stats.goalsConceded / stats.matchesPlayed.clamp(1, 99)) * 10).clamp(0.0, 100.0);
    final formRating = stats.winRate * 100;
    final squadRating = club.squadAvgRating * 10;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Analytics Dashboard',
              icon: Icons.analytics_rounded,
              color: AppColors.primaryBlue,
              subtitle: 'Season performance overview'),
          SizedBox(height: context.rs(16, min: 12, max: 20)),

          // Big 4 analytics
          context.adaptiveLayout(
            narrow: Column(children: [
              Row(children: [
                Expanded(child: _AnalyticCard('Attack', attackRating, AppColors.accentCyan, Icons.sports_soccer_rounded)),
                SizedBox(width: context.rs(10, min: 8, max: 12)),
                Expanded(child: _AnalyticCard('Defense', defenseRating, AppColors.accentGreen, Icons.shield_rounded)),
              ]),
              SizedBox(height: context.rs(10, min: 8, max: 12)),
              Row(children: [
                Expanded(child: _AnalyticCard('Form', formRating, AppColors.warning, Icons.trending_up_rounded)),
                SizedBox(width: context.rs(10, min: 8, max: 12)),
                Expanded(child: _AnalyticCard('Squad', squadRating, AppColors.primaryPurple, Icons.people_alt_rounded)),
              ]),
            ]),
            wide: Row(
              children: [
                Expanded(child: _AnalyticCard('Attack', attackRating, AppColors.accentCyan, Icons.sports_soccer_rounded)),
                SizedBox(width: context.rs(10, min: 8, max: 12)),
                Expanded(child: _AnalyticCard('Defense', defenseRating, AppColors.accentGreen, Icons.shield_rounded)),
                SizedBox(width: context.rs(10, min: 8, max: 12)),
                Expanded(child: _AnalyticCard('Form', formRating, AppColors.warning, Icons.trending_up_rounded)),
                SizedBox(width: context.rs(10, min: 8, max: 12)),
                Expanded(child: _AnalyticCard('Squad', squadRating, AppColors.primaryPurple, Icons.people_alt_rounded)),
              ],
            ),
          ),

          SizedBox(height: context.rs(16, min: 12, max: 20)),

          // Detailed bars
          _AnalyticBar('Goals per Match',
              stats.goalsScored / stats.matchesPlayed.clamp(1, 99),
              '${(stats.goalsScored / stats.matchesPlayed.clamp(1, 99)).toStringAsFixed(1)}/game',
              AppColors.accentCyan,
              const Duration(milliseconds: 100)),
          const SizedBox(height: 10),
          _AnalyticBar('Defensive Solidity',
              1 - (stats.goalsConceded / (stats.matchesPlayed.clamp(1, 99) * 3)),
              '${stats.goalsConceded} conceded',
              AppColors.accentGreen,
              const Duration(milliseconds: 200)),
          const SizedBox(height: 10),
          _AnalyticBar('Win Rate',
              stats.winRate,
              '${(stats.winRate * 100).round()}%',
              AppColors.warning,
              const Duration(milliseconds: 300)),
          const SizedBox(height: 10),
          _AnalyticBar('Squad Avg Rating',
              club.squadAvgRating / 10,
              club.squadAvgRating.toStringAsFixed(1),
              AppColors.primaryPurple,
              const Duration(milliseconds: 400)),
        ],
      ),
    );
  }
}

class _AnalyticCard extends StatelessWidget {
  const _AnalyticCard(this.label, this.value, this.color, this.icon);
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: context.rs(14, min: 10, max: 18),
          horizontal: context.rs(10, min: 8, max: 12)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          GsStatRing(value: value / 100, color: color, size: 46),
          const SizedBox(height: 6),
          Icon(icon, color: color, size: 14),
          const SizedBox(height: 3),
          Text(label, style: AppTextStyles.caption(color: AppColors.textMuted)
              .copyWith(fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _AnalyticBar extends StatelessWidget {
  const _AnalyticBar(this.label, this.value, this.valueLabel, this.color, this.delay);
  final String label, valueLabel;
  final double value;
  final Color color;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.caption(color: AppColors.textSecondary)),
            Text(valueLabel, style: AppTextStyles.caption(color: color)
                .copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 5),
        GsAnimatedBar(value: value.clamp(0.0, 1.0), color: color,
            backgroundColor: AppColors.surface, height: 6, delay: delay),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 18. PERFORMANCE TREND CHARTS
// ─────────────────────────────────────────────────────────────────────────────

class PerformanceTrendCard extends StatelessWidget {
  const PerformanceTrendCard({super.key, required this.club});
  final ClubModel club;

  @override
  Widget build(BuildContext context) {
    // Mock trend data
    final ratingTrend = [6.8, 7.2, 7.0, 7.5, 7.8, 7.4, 7.9, 8.1, 7.7, 8.2];
    final intensityTrend = [65.0, 70.0, 68.0, 75.0, 82.0, 78.0, 85.0, 80.0, 88.0, 91.0];
    final possessionTrend = [52.0, 55.0, 58.0, 54.0, 60.0, 62.0, 59.0, 63.0, 64.0, 66.0];

    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [club.primaryColor.withValues(alpha: 0.07), AppColors.surfaceElevated],
      ),
      borderColor: club.primaryColor.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Performance Trends',
              icon: Icons.show_chart_rounded,
              color: club.primaryColor,
              subtitle: 'Season progression analytics'),
          SizedBox(height: context.rs(16, min: 12, max: 20)),

          _TrendSection(
            label: 'Rating Progression',
            sublabel: 'AI match rating over last 10 games',
            data: ratingTrend,
            color: AppColors.accentCyan,
          ),
          SizedBox(height: context.rs(16, min: 12, max: 20)),

          _TrendSection(
            label: 'Match Intensity',
            sublabel: 'Physical intensity score per fixture',
            data: intensityTrend,
            color: AppColors.warning,
          ),
          SizedBox(height: context.rs(16, min: 12, max: 20)),

          _TrendSection(
            label: 'Possession Trend',
            sublabel: 'Average possession % per match',
            data: possessionTrend,
            color: AppColors.primaryPurple,
          ),
        ],
      ),
    );
  }
}

class _TrendSection extends StatelessWidget {
  const _TrendSection({
    required this.label,
    required this.sublabel,
    required this.data,
    required this.color,
  });
  final String label, sublabel;
  final List<double> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final current = data.last;
    final prev = data[data.length - 2];
    final isUp = current >= prev;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.body(color: AppColors.textPrimary)
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(sublabel, style: AppTextStyles.caption(color: AppColors.textMuted)),
              ],
            ),
            Row(
              children: [
                Icon(
                  isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: isUp ? AppColors.accentGreen : AppColors.danger,
                  size: 14,
                ),
                Text(
                  current.toStringAsFixed(1),
                  style: AppTextStyles.title(color: isUp ? AppColors.accentGreen : AppColors.danger)
                      .copyWith(fontSize: context.rs(16, min: 13, max: 18)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        GsMiniLineChart(
          data: data,
          color: color,
          height: context.rs(60, min: 50, max: 80),
          showDots: false,
          delay: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 19. RECENT ANALYSES SECTION
// ─────────────────────────────────────────────────────────────────────────────

class RecentAnalysesCard extends StatelessWidget {
  const RecentAnalysesCard({super.key, required this.clubName, required this.primaryColor});
  final String clubName;
  final Color primaryColor;

  List<_RecentMatch> _buildMatches() {
    return [
      _RecentMatch(clubName, 'Falcons United', '3–1', 'W', 91, AppColors.accentGreen),
      _RecentMatch('Sharks FC', clubName, '0–0', 'D', 62, AppColors.warning),
      _RecentMatch('Lions City', clubName, '1–2', 'W', 88, AppColors.accentGreen),
      _RecentMatch(clubName, 'Panthers', '2–0', 'W', 74, AppColors.accentGreen),
      _RecentMatch('Eagles Club', clubName, '1–1', 'D', 68, AppColors.warning),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final matches = _buildMatches();

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Recent Analyses',
              icon: Icons.history_rounded,
              color: primaryColor,
              subtitle: 'Latest match breakdowns'),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          ...matches.map((m) => _RecentMatchRow(match: m, color: primaryColor)),
        ],
      ),
    );
  }
}

class _RecentMatch {
  const _RecentMatch(this.home, this.away, this.score, this.result, this.intensity, this.resultColor);
  final String home, away, score, result;
  final int intensity;
  final Color resultColor;
}

class _RecentMatchRow extends StatelessWidget {
  const _RecentMatchRow({required this.match, required this.color});
  final _RecentMatch match;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(
          horizontal: context.rs(12, min: 10, max: 14),
          vertical: context.rs(10, min: 8, max: 12)),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                color: match.resultColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: match.resultColor.withValues(alpha: 0.3))),
            child: Center(
              child: Text(match.result,
                  style: AppTextStyles.caption(color: match.resultColor)
                      .copyWith(fontWeight: FontWeight.w800, fontSize: 10)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${match.home} vs ${match.away}',
                    style: AppTextStyles.caption(color: AppColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Intensity: ${match.intensity}',
                    style: AppTextStyles.caption(color: AppColors.textMuted)
                        .copyWith(fontSize: 10)),
              ],
            ),
          ),
          Text(match.score,
              style: AppTextStyles.body(color: AppColors.textPrimary)
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: AppRadius.chip),
            child: Text('Analysed',
                style: AppTextStyles.caption(color: color)
                    .copyWith(fontSize: 9, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 20. TOP PLAYERS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class TopPlayersCard extends StatelessWidget {
  const TopPlayersCard({super.key, required this.club});
  final ClubModel club;

  @override
  Widget build(BuildContext context) {
    final topPlayers = ([...club.players]
          ..sort((a, b) => b.rating.compareTo(a.rating)))
        .take(5)
        .toList();

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Top Performers',
              icon: Icons.star_rounded,
              color: AppColors.warning,
              subtitle: 'Season\'s best players'),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          ...topPlayers.asMap().entries.map((e) =>
              _TopPlayerRow(player: e.value, rank: e.key + 1,
                  delay: Duration(milliseconds: 80 * e.key),
                  primaryColor: club.primaryColor)),
        ],
      ),
    );
  }
}

class _TopPlayerRow extends StatelessWidget {
  const _TopPlayerRow({
    required this.player,
    required this.rank,
    required this.delay,
    required this.primaryColor,
  });
  final ClubPlayer player;
  final int rank;
  final Duration delay;
  final Color primaryColor;

  Color get _ratingColor {
    if (player.rating >= 8.0) return AppColors.accentCyan;
    if (player.rating >= 7.0) return AppColors.accentGreen;
    if (player.rating >= 6.0) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(
          horizontal: context.rs(12, min: 10, max: 14),
          vertical: context.rs(10, min: 8, max: 12)),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: AppRadius.card,
        border: Border.all(
            color: rank == 1 ? AppColors.warning.withValues(alpha: 0.35) : AppColors.outlineSubtle),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: rank == 1
                ? const Icon(Icons.star_rounded, color: AppColors.warning, size: 16)
                : Text('#$rank',
                    style: AppTextStyles.caption(color: AppColors.textMuted)
                        .copyWith(fontWeight: FontWeight.w700)),
          ),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_ratingColor.withValues(alpha: 0.3), _ratingColor.withValues(alpha: 0.05)],
              ),
              border: Border.all(color: _ratingColor.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(player.name[0],
                  style: AppTextStyles.button(color: _ratingColor).copyWith(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(player.name,
                      style: AppTextStyles.body(color: AppColors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: _ratingColor.withValues(alpha: 0.12),
                        borderRadius: AppRadius.chip),
                    child: Text(player.rating.toStringAsFixed(1),
                        style: AppTextStyles.caption(color: _ratingColor)
                            .copyWith(fontWeight: FontWeight.w800)),
                  ),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  _MiniStat('${player.goals}G', AppColors.accentCyan),
                  const SizedBox(width: 8),
                  _MiniStat('${player.assists}A', AppColors.accentGreen),
                  const SizedBox(width: 8),
                  _MiniStat(player.position, AppColors.textMuted),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: AppTextStyles.caption(color: color)
          .copyWith(fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 21. TACTICAL SUMMARIES
// ─────────────────────────────────────────────────────────────────────────────

class ClubTacticalSummaryCard extends StatelessWidget {
  const ClubTacticalSummaryCard({super.key, required this.club});
  final ClubModel club;

  @override
  Widget build(BuildContext context) {
    final stats = club.stats;
    final summaries = [
      _Summary(
        'Attacking Intelligence',
        Icons.sports_soccer_rounded,
        AppColors.accentCyan,
        '${club.name} scores an average of ${(stats.goalsScored / stats.matchesPlayed.clamp(1, 99)).toStringAsFixed(1)} goals per match. '
            'Primary attack zones show a strong preference for central channels, supported by '
            'wide overloads on the left flank.',
      ),
      _Summary(
        'Defensive Organization',
        Icons.shield_rounded,
        AppColors.accentGreen,
        'Conceding ${(stats.goalsConceded / stats.matchesPlayed.clamp(1, 99)).toStringAsFixed(1)} goals per game, ${club.name} maintains '
            'disciplined defensive blocks. High compactness in the middle third has been '
            'a defining characteristic this season.',
      ),
      _Summary(
        'Season Trajectory',
        Icons.trending_up_rounded,
        AppColors.warning,
        'With a ${(stats.winRate * 100).round()}% win rate and ${stats.points} points from ${stats.matchesPlayed} matches, '
            '${club.name} ranks #${stats.ranking} in the league. Form has been consistent '
            'in the last 5 fixtures.',
      ),
    ];

    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [club.primaryColor.withValues(alpha: 0.07), AppColors.surfaceElevated],
      ),
      borderColor: club.primaryColor.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _SectionHeader(
                title: 'AI Tactical Summary',
                icon: Icons.auto_awesome_rounded,
                color: club.primaryColor,
                subtitle: 'AI-generated season analysis'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: club.primaryColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.chip),
              child: Text('AI', style: AppTextStyles.caption(color: club.primaryColor)
                  .copyWith(fontWeight: FontWeight.w800)),
            ),
          ]),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          ...summaries.map((s) => _SummaryTile(summary: s)),
        ],
      ),
    );
  }
}

class _Summary {
  const _Summary(this.title, this.icon, this.color, this.text);
  final String title, text;
  final IconData icon;
  final Color color;
}

class _SummaryTile extends StatefulWidget {
  const _SummaryTile({required this.summary});
  final _Summary summary;

  @override
  State<_SummaryTile> createState() => _SummaryTileState();
}

class _SummaryTileState extends State<_SummaryTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.summary.color.withValues(alpha: 0.05),
        borderRadius: AppRadius.card,
        border: Border.all(color: widget.summary.color.withValues(alpha: 0.18)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: EdgeInsets.all(context.rs(14, min: 12, max: 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(widget.summary.icon, color: widget.summary.color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(widget.summary.title,
                      style: AppTextStyles.body(color: AppColors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 13))),
                  Icon(_open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted, size: 18),
                ]),
                if (_open) ...[
                  const SizedBox(height: 8),
                  Text(widget.summary.text,
                      style: AppTextStyles.caption(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
