import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
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
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.surfaceElevated, AppColors.surface],
            ),
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: borderColor ?? AppColors.outlineSubtle),
        boxShadow: AppShadows.card,
      ),
      padding: EdgeInsets.all(context.rs(16, min: 12, max: 20)),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon, this.trailing});
  final String title;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.accentCyan,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: context.rs(17, min: 14, max: 20), color: AppColors.accentCyan),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.title().copyWith(
              fontSize: context.sp(17, min: 14, max: 20),
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TACTICAL RECOMMENDATIONS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _TacticalRecommendation {
  const _TacticalRecommendation({
    required this.title,
    required this.detail,
    required this.category,
    required this.priority,
    required this.icon,
  });
  final String title, detail, category;
  final _Priority priority;
  final IconData icon;
}

enum _Priority { critical, high, medium, low }

extension _PriorityExt on _Priority {
  String get label {
    switch (this) {
      case _Priority.critical: return 'CRITICAL';
      case _Priority.high: return 'HIGH';
      case _Priority.medium: return 'MEDIUM';
      case _Priority.low: return 'LOW';
    }
  }

  Color get color {
    switch (this) {
      case _Priority.critical: return AppColors.danger;
      case _Priority.high: return AppColors.warning;
      case _Priority.medium: return AppColors.accentCyan;
      case _Priority.low: return AppColors.accentGreen;
    }
  }
}

const _kRecommendations = [
  _TacticalRecommendation(
    title: 'Increase Attacking Width',
    detail: 'Wingers hugging touchlines only 32% of build-up phases. Widen to stretch defensive blocks.',
    category: 'Attack',
    priority: _Priority.high,
    icon: Icons.open_in_full_rounded,
  ),
  _TacticalRecommendation(
    title: 'Improve Transition Speed',
    detail: 'Average counter-attack launch takes 4.2 seconds. Target sub-3 second transitions.',
    category: 'Transition',
    priority: _Priority.high,
    icon: Icons.double_arrow_rounded,
  ),
  _TacticalRecommendation(
    title: 'Reduce Midfield Compactness Gaps',
    detail: '18m gap detected between defensive and attacking midfielders at 67+ minutes.',
    category: 'Shape',
    priority: _Priority.critical,
    icon: Icons.compress_rounded,
  ),
  _TacticalRecommendation(
    title: 'Improve Pressing Efficiency',
    detail: 'Press recovery rate dropped from 68% to 51% in final 15 minutes. Condition mid-press.',
    category: 'Press',
    priority: _Priority.medium,
    icon: Icons.speed_rounded,
  ),
  _TacticalRecommendation(
    title: 'Monitor Player Fatigue',
    detail: '3 players above 85% fatigue threshold. Rotation required next fixture.',
    category: 'Fitness',
    priority: _Priority.medium,
    icon: Icons.battery_alert_rounded,
  ),
];

class TacticalRecommendationsSection extends StatefulWidget {
  const TacticalRecommendationsSection({super.key});

  @override
  State<TacticalRecommendationsSection> createState() =>
      _TacticalRecommendationsSectionState();
}

class _TacticalRecommendationsSectionState
    extends State<TacticalRecommendationsSection> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'Tactical Recommendations',
          icon: Icons.tips_and_updates_rounded,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.12),
              borderRadius: AppRadius.chip,
              border:
                  Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.primaryPurple, size: 11),
                const SizedBox(width: 4),
                Text('AI',
                    style: AppTextStyles.caption(color: AppColors.primaryPurple)
                        .copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
        SizedBox(height: context.rs(10, min: 8, max: 14)),
        ..._kRecommendations.asMap().entries.map(
              (e) => Padding(
                padding: EdgeInsets.only(
                    bottom: context.rs(8, min: 6, max: 10)),
                child: _RecommendationCard(
                  rec: e.value,
                  isExpanded: _expandedIndex == e.key,
                  onTap: () => setState(() =>
                      _expandedIndex =
                          _expandedIndex == e.key ? null : e.key),
                ),
              ),
            ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.rec,
    required this.isExpanded,
    required this.onTap,
  });
  final _TacticalRecommendation rec;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = rec.priority.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: isExpanded ? 0.08 : 0.04),
              AppColors.surfaceElevated.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: AppRadius.card,
          border: Border.all(
              color: color.withValues(alpha: isExpanded ? 0.35 : 0.18)),
        ),
        padding: EdgeInsets.all(context.rs(12, min: 10, max: 14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(rec.icon, color: color, size: 15),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.title,
                        style: AppTextStyles.body(color: AppColors.textPrimary)
                            .copyWith(
                                fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(rec.category,
                          style: AppTextStyles.caption(
                              color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: AppRadius.chip,
                  ),
                  child: Text(rec.priority.label,
                      style: AppTextStyles.caption(color: color)
                          .copyWith(
                              fontSize: 9, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 6),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
            if (isExpanded) ...[
              SizedBox(height: context.rs(10, min: 8, max: 12)),
              Container(
                padding: EdgeInsets.all(context.rs(10, min: 8, max: 12)),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  borderRadius: AppRadius.card,
                  border:
                      Border.all(color: color.withValues(alpha: 0.15)),
                ),
                child: Text(rec.detail,
                    style: AppTextStyles.body(
                        color: AppColors.textSecondary)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UNDERPERFORMING PLAYERS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _AtRiskPlayer {
  const _AtRiskPlayer({
    required this.name,
    required this.position,
    required this.rating,
    required this.fatigue,
    required this.concern,
    required this.riskLevel,
  });
  final String name, position, concern;
  final double rating, fatigue;
  final _Priority riskLevel;
}

const _kAtRiskPlayers = [
  _AtRiskPlayer(
    name: 'Youssef Tarek',
    position: 'FW',
    rating: 5.8,
    fatigue: 88,
    concern: 'Low work rate, poor positioning',
    riskLevel: _Priority.critical,
  ),
  _AtRiskPlayer(
    name: 'Ahmed Nasser',
    position: 'GK',
    rating: 6.2,
    fatigue: 76,
    concern: 'Distribution errors, hesitant command',
    riskLevel: _Priority.high,
  ),
  _AtRiskPlayer(
    name: 'Omar Fathy',
    position: 'CB',
    rating: 6.6,
    fatigue: 81,
    concern: 'Aerial weakness, late pressing triggers',
    riskLevel: _Priority.medium,
  ),
];

class UnderperformingPlayersSection extends StatelessWidget {
  const UnderperformingPlayersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'Players Needing Attention',
          icon: Icons.warning_amber_rounded,
          trailing: Text(
            '${_kAtRiskPlayers.length} players',
            style: AppTextStyles.caption(color: AppColors.warning),
          ),
        ),
        SizedBox(height: context.rs(10, min: 8, max: 14)),
        ..._kAtRiskPlayers.map((p) => Padding(
              padding:
                  EdgeInsets.only(bottom: context.rs(8, min: 6, max: 10)),
              child: _AtRiskPlayerCard(player: p),
            )),
      ],
    );
  }
}

class _AtRiskPlayerCard extends StatelessWidget {
  const _AtRiskPlayerCard({required this.player});
  final _AtRiskPlayer player;

  @override
  Widget build(BuildContext context) {
    final color = player.riskLevel.color;
    final ratingColor = player.rating >= 7.5
        ? AppColors.accentGreen
        : player.rating >= 6.5
            ? AppColors.warning
            : AppColors.danger;

    return _GlassCard(
      borderColor: color.withValues(alpha: 0.22),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.05), AppColors.surfaceElevated],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: context.rs(48, min: 40, max: 56),
            height: context.rs(48, min: 40, max: 56),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  ratingColor.withValues(alpha: 0.25),
                  ratingColor.withValues(alpha: 0.06),
                ],
              ),
              border:
                  Border.all(color: ratingColor.withValues(alpha: 0.4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(player.rating.toStringAsFixed(1),
                    style: AppTextStyles.caption(color: ratingColor)
                        .copyWith(fontWeight: FontWeight.w800, fontSize: 12)),
                Text(player.position,
                    style: AppTextStyles.caption(color: AppColors.textMuted)
                        .copyWith(fontSize: 9)),
              ],
            ),
          ),
          SizedBox(width: context.rs(12, min: 8, max: 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      player.name,
                      style:
                          AppTextStyles.body(color: AppColors.textPrimary)
                              .copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: AppRadius.chip,
                    ),
                    child: Text(player.riskLevel.label,
                        style: AppTextStyles.caption(color: color)
                            .copyWith(
                                fontSize: 8,
                                fontWeight: FontWeight.w800)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(player.concern,
                    style: AppTextStyles.caption(
                        color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fatigue',
                            style: AppTextStyles.caption(
                                color: AppColors.textMuted)
                                .copyWith(fontSize: 9)),
                        const SizedBox(height: 3),
                        GsAnimatedBar(
                          value: player.fatigue / 100,
                          color: player.fatigue >= 80
                              ? AppColors.danger
                              : AppColors.warning,
                          backgroundColor: AppColors.surface,
                          height: 4,
                          delay: const Duration(milliseconds: 400),
                        ),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TACTICAL IDENTITY OVERVIEW
// ─────────────────────────────────────────────────────────────────────────────

class TacticalIdentityOverview extends StatelessWidget {
  const TacticalIdentityOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'Tactical Identity',
          icon: Icons.layers_rounded,
        ),
        SizedBox(height: context.rs(10, min: 8, max: 14)),
        _GlassCard(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryPurple.withValues(alpha: 0.08),
              AppColors.surfaceElevated,
              AppColors.accentCyan.withValues(alpha: 0.04),
            ],
          ),
          borderColor: AppColors.primaryPurple.withValues(alpha: 0.22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Style label
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      AppColors.primaryPurple,
                      AppColors.accentCyan
                    ]),
                    borderRadius: AppRadius.chip,
                  ),
                  child: Text('Possession Dominant',
                      style: AppTextStyles.caption(color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Text('Season 2025/26',
                    style:
                        AppTextStyles.caption(color: AppColors.textMuted)),
              ]),
              SizedBox(height: context.rs(14, min: 10, max: 18)),
              context.adaptiveLayout(
                narrow: Column(
                  children: [
                    _IdentityRow('Playing Style', 'High Possession Build-Up',
                        Icons.sports_soccer_rounded, AppColors.accentCyan),
                    SizedBox(height: context.rs(8, min: 6, max: 10)),
                    _IdentityRow('Pressure Style', 'High Press + Gegenpressing',
                        Icons.compress_rounded, AppColors.primaryPurple),
                    SizedBox(height: context.rs(8, min: 6, max: 10)),
                    _IdentityRow('Transition', 'Fast Vertical Counter',
                        Icons.double_arrow_rounded, AppColors.accentGreen),
                    SizedBox(height: context.rs(8, min: 6, max: 10)),
                    _IdentityRow('Attack Zone', 'Central + Left Wing',
                        Icons.grid_on_rounded, AppColors.warning),
                  ],
                ),
                wide: Wrap(
                  spacing: context.rs(10, min: 8, max: 12),
                  runSpacing: context.rs(8, min: 6, max: 10),
                  children: [
                    SizedBox(
                      width: (context.screenWidth - context.rs(100)) / 2,
                      child: _IdentityRow('Playing Style',
                          'High Possession Build-Up',
                          Icons.sports_soccer_rounded, AppColors.accentCyan),
                    ),
                    SizedBox(
                      width: (context.screenWidth - context.rs(100)) / 2,
                      child: _IdentityRow('Pressure Style',
                          'High Press + Gegenpressing',
                          Icons.compress_rounded, AppColors.primaryPurple),
                    ),
                    SizedBox(
                      width: (context.screenWidth - context.rs(100)) / 2,
                      child: _IdentityRow('Transition',
                          'Fast Vertical Counter',
                          Icons.double_arrow_rounded, AppColors.accentGreen),
                    ),
                    SizedBox(
                      width: (context.screenWidth - context.rs(100)) / 2,
                      child: _IdentityRow('Attack Zone', 'Central + Left Wing',
                          Icons.grid_on_rounded, AppColors.warning),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.rs(14, min: 10, max: 18)),
              // Tactical efficiency bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tactical Efficiency',
                      style: AppTextStyles.caption(
                          color: AppColors.textSecondary)),
                  Text('78 / 100',
                      style: AppTextStyles.caption(
                              color: AppColors.accentCyan)
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              GsAnimatedBar(
                value: 0.78,
                color: AppColors.accentCyan,
                backgroundColor: AppColors.surface,
                height: 6,
                delay: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow(this.label, this.value, this.icon, this.color);
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.rs(10, min: 8, max: 12),
          vertical: context.rs(8, min: 6, max: 10)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: context.rs(15, min: 12, max: 17)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.caption(color: AppColors.textMuted)
                      .copyWith(fontSize: 9)),
              Text(value,
                  style:
                      AppTextStyles.body(color: AppColors.textPrimary)
                          .copyWith(
                              fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLUB ANALYTICS DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

class ClubAnalyticsDashboard extends StatelessWidget {
  const ClubAnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'Club Analytics',
          icon: Icons.analytics_rounded,
        ),
        SizedBox(height: context.rs(10, min: 8, max: 14)),
        context.adaptiveLayout(
          narrow: Column(children: [
            Row(children: [
              Expanded(
                  child: _AnalyticMetric('Avg Possession', '58%',
                      Icons.donut_large_rounded, AppColors.accentCyan, 0.58)),
              SizedBox(width: context.rs(8, min: 6, max: 10)),
              Expanded(
                  child: _AnalyticMetric('Sprint Intensity', '74%',
                      Icons.speed_rounded, AppColors.accentGreen, 0.74)),
            ]),
            SizedBox(height: context.rs(8, min: 6, max: 10)),
            Row(children: [
              Expanded(
                  child: _AnalyticMetric('Team Rating', '7.82',
                      Icons.stars_rounded, AppColors.primaryPurple, 0.782)),
              SizedBox(width: context.rs(8, min: 6, max: 10)),
              Expanded(
                  child: _AnalyticMetric('Press Score', '68%',
                      Icons.compress_rounded, AppColors.warning, 0.68)),
            ]),
          ]),
          wide: Row(children: [
            Expanded(
                child: _AnalyticMetric('Avg Possession', '58%',
                    Icons.donut_large_rounded, AppColors.accentCyan, 0.58)),
            SizedBox(width: context.rs(8, min: 6, max: 10)),
            Expanded(
                child: _AnalyticMetric('Sprint Intensity', '74%',
                    Icons.speed_rounded, AppColors.accentGreen, 0.74)),
            SizedBox(width: context.rs(8, min: 6, max: 10)),
            Expanded(
                child: _AnalyticMetric('Team Rating', '7.82',
                    Icons.stars_rounded, AppColors.primaryPurple, 0.782)),
            SizedBox(width: context.rs(8, min: 6, max: 10)),
            Expanded(
                child: _AnalyticMetric('Press Score', '68%',
                    Icons.compress_rounded, AppColors.warning, 0.68)),
          ]),
        ),
      ],
    );
  }
}

class _AnalyticMetric extends StatelessWidget {
  const _AnalyticMetric(
      this.label, this.value, this.icon, this.color, this.barValue);
  final String label, value;
  final IconData icon;
  final Color color;
  final double barValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.rs(12, min: 10, max: 14)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            AppColors.surfaceElevated,
          ],
        ),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: context.rs(16, min: 13, max: 18)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.caption(color: AppColors.textMuted)
                      .copyWith(fontSize: 10),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          SizedBox(height: context.rs(6, min: 4, max: 8)),
          Text(value,
              style: AppTextStyles.title(color: color).copyWith(
                  fontSize: context.sp(20, min: 16, max: 24))),
          const SizedBox(height: 6),
          GsAnimatedBar(
            value: barValue,
            color: color,
            backgroundColor: AppColors.surface,
            height: 4,
            delay: const Duration(milliseconds: 400),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PERFORMANCE TREND CHART
// ─────────────────────────────────────────────────────────────────────────────

class PerformanceTrendSection extends StatelessWidget {
  const PerformanceTrendSection({super.key});

  static const _ratingData = [
    7.1, 7.4, 7.2, 7.8, 7.6, 7.9, 8.1, 7.7, 8.0, 8.3,
  ];
  static const _possessionData = [
    52, 55, 49, 58, 57, 61, 63, 59, 62, 65,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'Performance Trends',
          icon: Icons.show_chart_rounded,
          trailing: Text('Last 10 matches',
              style: AppTextStyles.caption(color: AppColors.textMuted)),
        ),
        SizedBox(height: context.rs(10, min: 8, max: 14)),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rating trend
              _TrendChartRow(
                label: 'Team Rating',
                data: _ratingData,
                color: AppColors.primaryPurple,
                current: '8.3',
                delta: '+1.2',
                positive: true,
              ),
              SizedBox(height: context.rs(16, min: 12, max: 20)),
              // Possession trend
              _TrendChartRow(
                label: 'Avg Possession %',
                data: _possessionData.map((v) => v.toDouble()).toList(),
                color: AppColors.accentCyan,
                current: '65%',
                delta: '+13%',
                positive: true,
              ),
              SizedBox(height: context.rs(12, min: 8, max: 16)),
              // Match labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  10,
                  (i) => Text('M${i + 1}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 8)),
                ),
              ),
              SizedBox(height: context.rs(12, min: 8, max: 16)),
              // Form summary
              Container(
                padding: EdgeInsets.all(context.rs(10, min: 8, max: 12)),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.06),
                  borderRadius: AppRadius.card,
                  border: Border.all(
                      color: AppColors.accentGreen.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.trending_up_rounded,
                      color: AppColors.accentGreen, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upward trajectory over last 5 matches. Maintain current pressing intensity.',
                      style: AppTextStyles.caption(
                          color: AppColors.textSecondary),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendChartRow extends StatelessWidget {
  const _TrendChartRow({
    required this.label,
    required this.data,
    required this.color,
    required this.current,
    required this.delta,
    required this.positive,
  });
  final String label, current, delta;
  final List<double> data;
  final Color color;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    AppTextStyles.caption(color: AppColors.textSecondary)
                        .copyWith(fontWeight: FontWeight.w600)),
            Row(children: [
              Text(current,
                  style: AppTextStyles.body(color: color)
                      .copyWith(
                          fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (positive
                          ? AppColors.accentGreen
                          : AppColors.danger)
                      .withValues(alpha: 0.1),
                  borderRadius: AppRadius.chip,
                ),
                child: Text(delta,
                    style: AppTextStyles.caption(
                            color: positive
                                ? AppColors.accentGreen
                                : AppColors.danger)
                        .copyWith(
                            fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 6),
        GsMiniLineChart(
          data: data,
          color: color,
          height: context.rs(52, min: 40, max: 64),
          showDots: false,
          delay: const Duration(milliseconds: 300),
        ),
      ],
    );
  }
}
