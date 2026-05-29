import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/club_model.dart';
import '../../../shared/widgets/gs_animated_bar.dart';
import '../../../shared/widgets/gs_mini_line_chart.dart';
import '../../../shared/widgets/gs_pitch_painter.dart';

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
        gradient: gradient ?? const LinearGradient(
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

Color _ratingColor(double r) {
  if (r >= 8.0) return AppColors.accentCyan;
  if (r >= 7.0) return AppColors.accentGreen;
  if (r >= 6.0) return AppColors.warning;
  return AppColors.danger;
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAYER HERO HEADER
// ─────────────────────────────────────────────────────────────────────────────

class PlayerHeroHeader extends StatelessWidget {
  const PlayerHeroHeader({super.key, required this.player});
  final ClubPlayer player;

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor(player.rating);

    return Container(
      height: context.rs(240, min: 200, max: 280),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.2), AppColors.background],
        ),
      ),
      child: Stack(
        children: [
          // Background orb
          Positioned(
            top: -60,
            left: MediaQuery.of(context).size.width / 2 - 100,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  color.withValues(alpha: 0.2), Colors.transparent,
                ]),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: context.rs(20, min: 16, max: 28)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  Container(
                    width: context.rs(80, min: 64, max: 96),
                    height: context.rs(80, min: 64, max: 96),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.08)],
                      ),
                      border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 24, spreadRadius: 2)],
                    ),
                    child: Center(
                      child: Text(player.name[0],
                          style: AppTextStyles.headline(color: color)
                              .copyWith(fontSize: context.rs(28, min: 22, max: 34))),
                    ),
                  ),
                  SizedBox(height: context.rs(12, min: 8, max: 16)),
                  Text(player.name,
                      style: AppTextStyles.headline(color: AppColors.textPrimary)
                          .copyWith(fontSize: context.rs(24, min: 18, max: 28)),
                      textAlign: TextAlign.center),
                  SizedBox(height: context.rs(6, min: 4, max: 8)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: AppRadius.chip,
                            border: Border.all(color: color.withValues(alpha: 0.3))),
                        child: Text(player.position,
                            style: AppTextStyles.caption(color: color)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: AppRadius.chip,
                            border: Border.all(color: AppColors.outlineSubtle)),
                        child: Text('${player.nationality} Age ${player.age}',
                            style: AppTextStyles.caption(color: AppColors.textSecondary)),
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// 22. RATING PROGRESSION
// ─────────────────────────────────────────────────────────────────────────────

class RatingProgressionCard extends StatelessWidget {
  const RatingProgressionCard({super.key, required this.player});
  final ClubPlayer player;

  @override
  Widget build(BuildContext context) {
    // Mock progression
    final base = player.rating - 0.8;
    final ratingData = [
      base, base + 0.1, base + 0.3, base + 0.2, base + 0.5,
      base + 0.4, base + 0.6, base + 0.7, base + 0.65, player.rating,
    ];
    final color = _ratingColor(player.rating);

    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.07), AppColors.surfaceElevated],
      ),
      borderColor: color.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionHeader(
                  title: 'Rating Progression',
                  icon: Icons.show_chart_rounded,
                  color: color,
                  subtitle: 'Last 10 matches'),
              GsAnimatedCounter(
                value: player.rating,
                style: AppTextStyles.headline(color: color)
                    .copyWith(fontSize: context.rs(28, min: 22, max: 34)),
                decimals: 1,
                delay: const Duration(milliseconds: 300),
              ),
            ],
          ),
          SizedBox(height: context.rs(16, min: 12, max: 20)),
          GsMiniLineChart(
            data: ratingData,
            color: color,
            height: context.rs(80, min: 60, max: 100),
            showDots: true,
            delay: const Duration(milliseconds: 200),
          ),
          SizedBox(height: context.rs(8, min: 6, max: 10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(10, (i) => Text('M${i + 1}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 9))),
          ),
          SizedBox(height: context.rs(10, min: 8, max: 12)),
          _RatingStats(player: player),
        ],
      ),
    );
  }
}

class _RatingStats extends StatelessWidget {
  const _RatingStats({required this.player});
  final ClubPlayer player;

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor(player.rating);
    return Row(
      children: [
        Expanded(child: _RatingStat('Season Avg', player.rating.toStringAsFixed(1), color)),
        Container(width: 1, height: 36, color: AppColors.outlineSubtle),
        Expanded(child: _RatingStat('Appearances', '${player.appearances}', AppColors.textSecondary)),
        Container(width: 1, height: 36, color: AppColors.outlineSubtle),
        Expanded(child: _RatingStat('Goals', '${player.goals}', AppColors.accentCyan)),
        Container(width: 1, height: 36, color: AppColors.outlineSubtle),
        Expanded(child: _RatingStat('Assists', '${player.assists}', AppColors.accentGreen)),
      ],
    );
  }
}

class _RatingStat extends StatelessWidget {
  const _RatingStat(this.label, this.value, this.color);
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.title(color: color)
            .copyWith(fontSize: context.rs(18, min: 14, max: 22))),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption(color: AppColors.textMuted)
            .copyWith(fontSize: 10), textAlign: TextAlign.center),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 23 + 24. SPEED & DISTANCE ANALYTICS
// ─────────────────────────────────────────────────────────────────────────────

class SpeedDistanceCard extends StatelessWidget {
  const SpeedDistanceCard({super.key, required this.player});
  final ClubPlayer player;

  @override
  Widget build(BuildContext context) {
    // Mock data based on position
    final isAttacker = ['ST', 'LW', 'RW', 'CF', 'CAM', 'AM'].contains(player.position);
    final isDefender = ['CB', 'LB', 'RB', 'DM'].contains(player.position);
    final topSpeed = isAttacker ? 8.7 + player.rating * 0.03 : isDefender ? 7.8 + player.rating * 0.03 : 8.2 + player.rating * 0.03;
    final avgDistance = isAttacker ? 10.2 + player.rating * 0.1 : isDefender ? 11.4 + player.rating * 0.1 : 10.8 + player.rating * 0.1;
    final sprintCount = (player.rating * 3).round();

    final speedData = [topSpeed - 1.2, topSpeed - 0.8, topSpeed - 0.6, topSpeed - 0.9,
      topSpeed - 0.4, topSpeed - 0.5, topSpeed - 0.2, topSpeed - 0.3, topSpeed - 0.1, topSpeed];
    final distanceData = [avgDistance - 1.5, avgDistance - 0.8, avgDistance - 1.2, avgDistance - 0.5,
      avgDistance - 0.9, avgDistance - 0.3, avgDistance - 0.7, avgDistance - 0.1, avgDistance - 0.4, avgDistance];

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Speed & Distance',
              icon: Icons.speed_rounded,
              color: AppColors.accentGreen,
              subtitle: 'Physical performance tracking'),
          SizedBox(height: context.rs(14, min: 10, max: 18)),

          // Key metrics row
          Row(children: [
            Expanded(child: _SpeedMetric('Top Speed', '${topSpeed.toStringAsFixed(1)} m/s', AppColors.accentCyan, Icons.bolt_rounded)),
            SizedBox(width: context.rs(10, min: 8, max: 12)),
            Expanded(child: _SpeedMetric('Avg Distance', '${avgDistance.toStringAsFixed(1)} km', AppColors.accentGreen, Icons.straighten_rounded)),
            SizedBox(width: context.rs(10, min: 8, max: 12)),
            Expanded(child: _SpeedMetric('Sprints', '$sprintCount', AppColors.warning, Icons.directions_run_rounded)),
          ]),

          SizedBox(height: context.rs(16, min: 12, max: 20)),

          Text('Speed Profile (last 10 games)',
              style: AppTextStyles.caption(color: AppColors.textMuted)),
          const SizedBox(height: 6),
          GsMiniLineChart(
            data: speedData,
            color: AppColors.accentCyan,
            height: context.rs(60, min: 48, max: 76),
            showDots: false,
            delay: const Duration(milliseconds: 200),
          ),

          SizedBox(height: context.rs(12, min: 8, max: 16)),

          Text('Distance Covered (km)',
              style: AppTextStyles.caption(color: AppColors.textMuted)),
          const SizedBox(height: 6),
          GsMiniLineChart(
            data: distanceData,
            color: AppColors.accentGreen,
            height: context.rs(60, min: 48, max: 76),
            showDots: false,
            delay: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

class _SpeedMetric extends StatelessWidget {
  const _SpeedMetric(this.label, this.value, this.color, this.icon);
  final String label, value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: context.rs(12, min: 8, max: 16),
          horizontal: context.rs(8, min: 6, max: 10)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: context.rs(18, min: 14, max: 22)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.body(color: color)
              .copyWith(fontWeight: FontWeight.w700, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption(color: AppColors.textMuted)
              .copyWith(fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 25 + 26. FATIGUE & WORKLOAD
// ─────────────────────────────────────────────────────────────────────────────

class FatigueWorkloadCard extends StatelessWidget {
  const FatigueWorkloadCard({super.key, required this.player});
  final ClubPlayer player;

  @override
  Widget build(BuildContext context) {
    final fatigueIndex = (100 - player.rating * 6).clamp(0.0, 100.0);
    final workload = (player.appearances / 10.0).clamp(0.0, 1.0);
    final fatigueColor = fatigueIndex >= 80 ? AppColors.danger :
      fatigueIndex >= 60 ? AppColors.warning : AppColors.accentGreen;

    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [fatigueColor.withValues(alpha: 0.06), AppColors.surfaceElevated],
      ),
      borderColor: fatigueColor.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Fatigue & Workload',
              icon: Icons.battery_charging_full_rounded,
              color: fatigueColor,
              subtitle: 'Physical load monitoring'),
          SizedBox(height: context.rs(16, min: 12, max: 20)),

          Row(
            children: [
              // Fatigue ring
              Column(
                children: [
                  GsStatRing(
                    value: fatigueIndex / 100,
                    color: fatigueColor,
                    size: 80,
                    strokeWidth: 7,
                    delay: const Duration(milliseconds: 300),
                  ),
                  const SizedBox(height: 6),
                  Text('Fatigue', style: AppTextStyles.caption(color: AppColors.textMuted)
                      .copyWith(fontSize: 10)),
                ],
              ),
              const SizedBox(width: 20),
              // Workload ring
              Column(
                children: [
                  GsStatRing(
                    value: workload,
                    color: AppColors.primaryBlue,
                    size: 80,
                    strokeWidth: 7,
                    delay: const Duration(milliseconds: 450),
                  ),
                  const SizedBox(height: 6),
                  Text('Workload', style: AppTextStyles.caption(color: AppColors.textMuted)
                      .copyWith(fontSize: 10)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WorkloadStat('Appearances', '${player.appearances}', AppColors.textSecondary),
                    const SizedBox(height: 8),
                    const _WorkloadStat('Avg Minutes', '82', AppColors.textSecondary),
                    const SizedBox(height: 8),
                    _WorkloadStat('Risk Level',
                        fatigueIndex >= 80 ? 'HIGH' :
                        fatigueIndex >= 60 ? 'MEDIUM' : 'LOW',
                        fatigueColor),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          Container(
            padding: EdgeInsets.all(context.rs(12, min: 10, max: 14)),
            decoration: BoxDecoration(
              color: fatigueColor.withValues(alpha: 0.07),
              borderRadius: AppRadius.card,
              border: Border.all(color: fatigueColor.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, color: fatigueColor, size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text(
                fatigueIndex >= 80
                    ? 'HIGH RISK: Immediate rest recommended. Risk of muscle injury elevated.'
                    : fatigueIndex >= 60
                    ? 'MODERATE: Monitor closely. Consider substitution after 70 minutes.'
                    : 'FIT: Player is in good physical condition for the next fixture.',
                style: AppTextStyles.caption(color: AppColors.textSecondary),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}

class _WorkloadStat extends StatelessWidget {
  const _WorkloadStat(this.label, this.value, this.color);
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.caption(color: AppColors.textMuted)),
        Text(value, style: AppTextStyles.caption(color: color)
            .copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 27 + 28. CONSISTENCY & TACTICAL CONTRIBUTION
// ─────────────────────────────────────────────────────────────────────────────

class ConsistencyTacticalCard extends StatelessWidget {
  const ConsistencyTacticalCard({super.key, required this.player});
  final ClubPlayer player;

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor(player.rating);
    final variance = 1.0 - (player.rating - 6.0) * 0.1; // Mock variance

    final tacticalLabels = ['Pressing', 'Positioning', 'Transition', 'Build-Up', 'Duels'];
    final tacticalValues = [
      0.6 + player.rating * 0.03,
      0.55 + player.rating * 0.04,
      0.5 + player.rating * 0.035,
      0.65 + player.rating * 0.02,
      0.58 + player.rating * 0.03,
    ].map((v) => v.clamp(0.0, 1.0)).toList();

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              title: 'Consistency & Tactics',
              icon: Icons.radar_rounded,
              color: color,
              subtitle: 'Performance stability & contribution'),
          SizedBox(height: context.rs(16, min: 12, max: 20)),

          context.adaptiveLayout(
            narrow: Column(
              children: [
                _ConsistencyMeter(variance: variance, rating: player.rating, color: color),
                SizedBox(height: context.rs(16, min: 12, max: 20)),
                Center(
                  child: GsRadarChart(
                    labels: tacticalLabels,
                    values: tacticalValues,
                    color: color,
                    size: 150,
                    delay: const Duration(milliseconds: 300),
                  ),
                ),
              ],
            ),
            wide: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _ConsistencyMeter(variance: variance, rating: player.rating, color: color)),
                const SizedBox(width: 16),
                GsRadarChart(
                  labels: tacticalLabels,
                  values: tacticalValues,
                  color: color,
                  size: 140,
                  delay: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),

          SizedBox(height: context.rs(14, min: 10, max: 18)),

          // Tactical attributes bars
          ...tacticalLabels.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GsAnimatedBar(
              label: e.value,
              valueLabel: '${(tacticalValues[e.key] * 100).round()}',
              value: tacticalValues[e.key],
              color: color,
              backgroundColor: AppColors.surface,
              height: 6,
              showLabel: true,
              delay: Duration(milliseconds: 100 + e.key * 80),
            ),
          )),
        ],
      ),
    );
  }
}

class _ConsistencyMeter extends StatelessWidget {
  const _ConsistencyMeter({required this.variance, required this.rating, required this.color});
  final double variance, rating;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final consistencyScore = (1.0 - (variance * 0.5)).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Consistency Score',
            style: AppTextStyles.body(color: AppColors.textPrimary)
                .copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        Row(children: [
          GsStatRing(
              value: consistencyScore,
              color: color,
              size: 64,
              strokeWidth: 6,
              delay: const Duration(milliseconds: 200)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${(consistencyScore * 100).round()}/100',
                    style: AppTextStyles.title(color: color)
                        .copyWith(fontSize: context.rs(20, min: 16, max: 24))),
                Text(consistencyScore > 0.75 ? 'Highly Consistent' :
                consistencyScore > 0.55 ? 'Moderately Consistent' : 'Inconsistent',
                    style: AppTextStyles.caption(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ]),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 29. STRENGTHS & WEAKNESSES
// ─────────────────────────────────────────────────────────────────────────────

class PlayerStrengthsWeaknessesCard extends StatelessWidget {
  const PlayerStrengthsWeaknessesCard({super.key, required this.player});
  final ClubPlayer player;

  List<String> _getStrengths() {
    final pos = player.position;
    if (['ST', 'CF'].contains(pos)) return ['Clinical finishing', 'Aerial ability', 'Hold-up play'];
    if (['LW', 'RW'].contains(pos)) return ['Pace and dribbling', 'Wide channel runs', 'Direct threat'];
    if (['CAM', 'AM'].contains(pos)) return ['Key pass creation', 'Between-the-lines movement', 'Final third vision'];
    if (['CM', 'DM'].contains(pos)) return ['Ball retention', 'Defensive cover', 'Box-to-box stamina'];
    if (['CB'].contains(pos)) return ['Aerial dominance', 'Positional awareness', 'Ball-playing ability'];
    if (['LB', 'RB'].contains(pos)) return ['Overlapping runs', 'Crossing accuracy', 'Defensive 1v1'];
    if (pos == 'GK') return ['Shot stopping', 'Command of area', 'Distribution quality'];
    return ['Technical quality', 'Work rate', 'Tactical awareness'];
  }

  List<String> _getWeaknesses() {
    if (player.rating >= 8.0) return ['End-of-match fatigue', 'Over-reliance from teammates'];
    if (player.rating >= 7.0) return ['Inconsistency under pressure', 'Set-piece vulnerability'];
    return ['Decision-making in final third', 'Physical recovery speed', 'Aerial duels'];
  }

  @override
  Widget build(BuildContext context) {
    final strengths = _getStrengths();
    final weaknesses = _getWeaknesses();

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Strengths & Weaknesses',
              icon: Icons.balance_rounded,
              color: AppColors.primaryPurple,
              subtitle: 'AI-generated player profile'),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          context.adaptiveLayout(
            narrow: Column(children: [
              _StrengthSection(items: strengths),
              SizedBox(height: context.rs(12, min: 8, max: 16)),
              _WeaknessSection(items: weaknesses),
            ]),
            wide: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _StrengthSection(items: strengths)),
                SizedBox(width: context.rs(12, min: 8, max: 16)),
                Expanded(child: _WeaknessSection(items: weaknesses)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StrengthSection extends StatelessWidget {
  const _StrengthSection({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.trending_up_rounded, color: AppColors.accentGreen, size: 14),
          const SizedBox(width: 6),
          Text('Strengths', style: AppTextStyles.body(color: AppColors.accentGreen)
              .copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        ...items.map((s) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.07),
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.2))),
          child: Row(children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.accentGreen, size: 13),
            const SizedBox(width: 7),
            Expanded(child: Text(s, style: AppTextStyles.caption(color: AppColors.textSecondary))),
          ]),
        )),
      ],
    );
  }
}

class _WeaknessSection extends StatelessWidget {
  const _WeaknessSection({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.trending_down_rounded, color: AppColors.danger, size: 14),
          const SizedBox(width: 6),
          Text('Weaknesses', style: AppTextStyles.body(color: AppColors.danger)
              .copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        ...items.map((w) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.06),
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.18))),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 13),
            const SizedBox(width: 7),
            Expanded(child: Text(w, style: AppTextStyles.caption(color: AppColors.textSecondary))),
          ]),
        )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 30. AI INSIGHTS
// ─────────────────────────────────────────────────────────────────────────────

class PlayerAIInsightsCard extends StatelessWidget {
  const PlayerAIInsightsCard({super.key, required this.player});
  final ClubPlayer player;

  List<_Insight> _buildInsights() {
    final name = player.name.split(' ').first;
    return [
      _Insight('Pattern Detected',
          '$name consistently peaks in matches following 48+ hour rest periods. Schedule management critical.',
          Icons.pattern_rounded, AppColors.accentCyan),
      const _Insight('Injury Radar',
          'Sprint speed variance detected in last 3 matches — soft tissue risk elevated. Physical staff alert.',
          Icons.health_and_safety_rounded, AppColors.warning),
      _Insight('Tactical Fit',
          '$name performs 23% better in high-press systems vs. possession-based setups. Optimal in 4-3-3.',
          Icons.psychology_rounded, AppColors.primaryPurple),
      _Insight('Clutch Factor',
          '${player.goals} goals from ${player.appearances} appearances. ${player.rating >= 7.5 ? 'High clutch rating in decisive moments.' : 'Needs improvement in decisive moments.'}',
          Icons.stars_rounded, AppColors.accentGreen),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final insights = _buildInsights();

    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [AppColors.primaryPurple.withValues(alpha: 0.09), AppColors.surfaceElevated],
      ),
      borderColor: AppColors.primaryPurple.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const _SectionHeader(
                title: 'AI Player Insights',
                icon: Icons.auto_awesome_rounded,
                color: AppColors.primaryPurple,
                subtitle: 'Neural intelligence analysis'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.12),
                  borderRadius: AppRadius.chip),
              child: Text('AI', style: AppTextStyles.caption(color: AppColors.primaryPurple)
                  .copyWith(fontWeight: FontWeight.w800)),
            ),
          ]),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          ...insights.map((i) => _InsightTile(insight: i)),
        ],
      ),
    );
  }
}

class _Insight {
  const _Insight(this.title, this.text, this.icon, this.color);
  final String title, text;
  final IconData icon;
  final Color color;
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});
  final _Insight insight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(context.rs(12, min: 10, max: 14)),
      decoration: BoxDecoration(
        color: insight.color.withValues(alpha: 0.05),
        borderRadius: AppRadius.card,
        border: Border.all(color: insight.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: insight.color.withValues(alpha: 0.12),
              boxShadow: [BoxShadow(color: insight.color.withValues(alpha: 0.25), blurRadius: 8)],
            ),
            child: Icon(insight.icon, color: insight.color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: AppTextStyles.body(color: AppColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 3),
                Text(insight.text,
                    style: AppTextStyles.caption(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 31. MATCH-BY-MATCH HISTORY
// ─────────────────────────────────────────────────────────────────────────────

class MatchHistoryCard extends StatelessWidget {
  const MatchHistoryCard({super.key, required this.player});
  final ClubPlayer player;

  @override
  Widget build(BuildContext context) {
    final base = player.rating - 1.0;
    final matches = [
      _MatchEntry('vs Falcons United', 'May 2', (base + 1.2).clamp(0, 10), '1G 2A'),
      _MatchEntry('vs Sharks FC', 'May 1', (base + 0.4).clamp(0, 10), '0G 0A'),
      _MatchEntry('vs Lions City', 'Apr 28', (base + 0.8).clamp(0, 10), '0G 1A'),
      _MatchEntry('vs Panthers', 'Apr 22', (base + 0.6).clamp(0, 10), '1G 0A'),
      _MatchEntry('vs Eagles Club', 'Apr 18', (base + 0.3).clamp(0, 10), '0G 0A'),
    ];

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Match History',
              icon: Icons.history_rounded,
              color: AppColors.primaryBlue,
              subtitle: 'Last 5 fixtures'),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          ...matches.asMap().entries.map((e) =>
              _MatchHistoryRow(match: e.value, delay: Duration(milliseconds: 80 * e.key))),
        ],
      ),
    );
  }
}

class _MatchEntry {
  const _MatchEntry(this.opponent, this.date, this.rating, this.stats);
  final String opponent, date, stats;
  final double rating;
}

class _MatchHistoryRow extends StatelessWidget {
  const _MatchHistoryRow({required this.match, required this.delay});
  final _MatchEntry match;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor(match.rating);
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
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.05)]),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Center(
            child: Text(match.rating.toStringAsFixed(1),
                style: AppTextStyles.caption(color: color)
                    .copyWith(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(match.opponent,
                  style: AppTextStyles.body(color: AppColors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(match.date,
                  style: AppTextStyles.caption(color: AppColors.textMuted)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.chip),
          child: Text(match.stats,
              style: AppTextStyles.caption(color: color)
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 10)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 32. RISK ANALYSIS
// ─────────────────────────────────────────────────────────────────────────────

class PlayerRiskCard extends StatelessWidget {
  const PlayerRiskCard({super.key, required this.player});
  final ClubPlayer player;

  @override
  Widget build(BuildContext context) {
    final fatigueIndex = (100 - player.rating * 6).clamp(0.0, 100.0);
    final injuryRisk = fatigueIndex / 100;
    final tacticalRisk = (1.0 - player.rating / 10).clamp(0.0, 1.0);
    final formRisk = (1.0 - (player.rating - 5.0) / 5.0).clamp(0.0, 1.0);

    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [AppColors.danger.withValues(alpha: 0.06), AppColors.surfaceElevated],
      ),
      borderColor: AppColors.danger.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Risk Dashboard',
              icon: Icons.gpp_bad_rounded,
              color: AppColors.danger,
              subtitle: 'AI-detected player risks'),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          _RiskRow('Injury Risk', injuryRisk, const Duration(milliseconds: 100)),
          const SizedBox(height: 8),
          _RiskRow('Fatigue Risk', fatigueIndex / 100, const Duration(milliseconds: 200)),
          const SizedBox(height: 8),
          _RiskRow('Inconsistency Risk', formRisk, const Duration(milliseconds: 300)),
          const SizedBox(height: 8),
          _RiskRow('Tactical Risk', tacticalRisk * 0.7, const Duration(milliseconds: 400)),
        ],
      ),
    );
  }
}

class _RiskRow extends StatelessWidget {
  const _RiskRow(this.label, this.value, this.delay);
  final String label;
  final double value;
  final Duration delay;

  Color get _color {
    if (value >= 0.7) return AppColors.danger;
    if (value >= 0.4) return AppColors.warning;
    return AppColors.accentGreen;
  }

  String get _level {
    if (value >= 0.7) return 'HIGH';
    if (value >= 0.4) return 'MED';
    return 'LOW';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.caption(color: AppColors.textSecondary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12), borderRadius: AppRadius.chip),
              child: Text(_level,
                  style: AppTextStyles.caption(color: _color)
                      .copyWith(fontSize: 9, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 5),
        GsAnimatedBar(
            value: value.clamp(0.0, 1.0),
            color: _color,
            backgroundColor: AppColors.surface,
            height: 6,
            delay: delay),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 33. SEASON INTELLIGENCE SUMMARY
// ─────────────────────────────────────────────────────────────────────────────

class SeasonIntelligenceCard extends StatelessWidget {
  const SeasonIntelligenceCard({super.key, required this.player});
  final ClubPlayer player;

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor(player.rating);
    final name = player.name.split(' ').first;
    final tierLabel = player.rating >= 8.0 ? 'Elite' :
        player.rating >= 7.0 ? 'Good' : 'Average';
    final tierColor = player.rating >= 8.0 ? AppColors.accentCyan :
        player.rating >= 7.0 ? AppColors.accentGreen : AppColors.warning;

    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.1),
          AppColors.surfaceElevated,
          AppColors.primaryPurple.withValues(alpha: 0.06),
        ],
      ),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _SectionHeader(
                title: 'Season Summary',
                icon: Icons.auto_awesome_rounded,
                color: color,
                subtitle: 'AI season intelligence report'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppColors.primaryPurple.withValues(alpha: 0.2),
                        AppColors.accentCyan.withValues(alpha: 0.2)]),
                  borderRadius: AppRadius.chip,
                  border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.3))),
              child: Text('AI', style: AppTextStyles.caption(color: AppColors.accentCyan)
                  .copyWith(fontWeight: FontWeight.w800)),
            ),
          ]),
          SizedBox(height: context.rs(16, min: 12, max: 20)),

          // Season verdict banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.rs(14, min: 12, max: 16)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
              ),
              borderRadius: AppRadius.card,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.15),
                        borderRadius: AppRadius.chip,
                        border: Border.all(color: tierColor.withValues(alpha: 0.3))),
                    child: Text(tierLabel.toUpperCase(),
                        style: AppTextStyles.caption(color: tierColor)
                            .copyWith(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Text(player.rating.toStringAsFixed(1),
                      style: AppTextStyles.headline(color: color)
                          .copyWith(fontSize: context.rs(24, min: 18, max: 28))),
                  Text(' / 10',
                      style: AppTextStyles.caption(color: AppColors.textMuted)),
                ]),
                const SizedBox(height: 8),
                Text(
                  '$name has delivered a ${tierLabel.toLowerCase()} season performance. '
                      'With ${player.goals} goals and ${player.assists} assists from ${player.appearances} appearances, '
                      '${player.rating >= 7.5 ? 'this player has been a key contributor to the team\'s success.' : 'there is room for improvement in the final third.'}',
                  style: AppTextStyles.body(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(height: context.rs(14, min: 10, max: 18)),

          // Season stats grid
          context.adaptiveLayout(
            narrow: Column(children: [
              Row(children: [
                Expanded(child: _SeasonStat('Goals', '${player.goals}', AppColors.accentCyan)),
                SizedBox(width: context.rs(10, min: 8, max: 12)),
                Expanded(child: _SeasonStat('Assists', '${player.assists}', AppColors.accentGreen)),
              ]),
              SizedBox(height: context.rs(10, min: 8, max: 12)),
              Row(children: [
                Expanded(child: _SeasonStat('Appearances', '${player.appearances}', AppColors.primaryBlue)),
                SizedBox(width: context.rs(10, min: 8, max: 12)),
                Expanded(child: _SeasonStat('Rating', player.rating.toStringAsFixed(1), color)),
              ]),
            ]),
            wide: Row(children: [
              Expanded(child: _SeasonStat('Goals', '${player.goals}', AppColors.accentCyan)),
              SizedBox(width: context.rs(10, min: 8, max: 12)),
              Expanded(child: _SeasonStat('Assists', '${player.assists}', AppColors.accentGreen)),
              SizedBox(width: context.rs(10, min: 8, max: 12)),
              Expanded(child: _SeasonStat('Appearances', '${player.appearances}', AppColors.primaryBlue)),
              SizedBox(width: context.rs(10, min: 8, max: 12)),
              Expanded(child: _SeasonStat('Rating', player.rating.toStringAsFixed(1), color)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SeasonStat extends StatelessWidget {
  const _SeasonStat(this.label, this.value, this.color);
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.rs(12, min: 8, max: 16)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          GsAnimatedCounter(
            value: double.tryParse(value) ?? 0,
            style: AppTextStyles.headline(color: color)
                .copyWith(fontSize: context.rs(22, min: 18, max: 26)),
            decimals: value.contains('.') ? 1 : 0,
            delay: const Duration(milliseconds: 300),
          ),
          const SizedBox(height: 3),
          Text(label,
              style: AppTextStyles.caption(color: AppColors.textMuted)
                  .copyWith(fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
