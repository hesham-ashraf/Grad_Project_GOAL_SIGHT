import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/match_analysis_model.dart';
import '../../../shared/widgets/gs_animated_bar.dart';
import '../../../shared/widgets/gs_mini_line_chart.dart';
import '../../../shared/widgets/gs_pitch_painter.dart';

// ─── Section Header (reused from club_detail_widgets via inline) ──────────────
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
                      .copyWith(fontSize: context.rs(16, min: 13, max: 18))),
              if (subtitle != null)
                Text(subtitle!,
                    style: AppTextStyles.caption(color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Glassmorphism card ───────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// 1. TACTICAL SUMMARY SECTION
// ─────────────────────────────────────────────────────────────────────────────

class TacticalSummaryCard extends StatelessWidget {
  const TacticalSummaryCard({super.key, required this.match});
  final MatchAnalysisModel match;

  @override
  Widget build(BuildContext context) {
    final home = match.homeAnalysis;
    final away = match.awayAnalysis;
    final intensity = match.intensity;
    final intensityColor = intensity >= 80
        ? AppColors.danger
        : intensity >= 60
            ? AppColors.warning
            : AppColors.accentGreen;

    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryPurple.withValues(alpha: 0.12),
          AppColors.surfaceElevated,
          AppColors.primaryBlue.withValues(alpha: 0.08),
        ],
      ),
      borderColor: AppColors.primaryPurple.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Tactical Summary',
              icon: Icons.psychology_rounded,
              color: AppColors.primaryPurple,
              subtitle: 'AI-generated match overview'),
          SizedBox(height: context.rs(16, min: 12, max: 20)),
          // Metrics row
          Row(
            children: [
              Expanded(child: _TacticMetric(label: 'Dominant', value: match.summary.dominantTeam.isEmpty ? 'Balanced' : match.summary.dominantTeam, color: AppColors.accentCyan)),
              _vDivider(),
              Expanded(child: _TacticMetric(label: 'Intensity', value: '$intensity', suffix: '/100', color: intensityColor)),
              _vDivider(),
              Expanded(child: _TacticMetric(label: 'Match Quality', value: intensity >= 80 ? 'High' : intensity >= 60 ? 'Medium' : 'Low', color: intensityColor)),
            ],
          ),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          const Divider(color: AppColors.outlineSubtle),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          // Team identities
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _TeamIdentityCol(analysis: home, color: AppColors.accentCyan)),
              SizedBox(width: context.rs(12, min: 8, max: 16)),
              Expanded(child: _TeamIdentityCol(analysis: away, color: AppColors.primaryPurple)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 48,
        color: AppColors.outlineSubtle,
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );
}

class _TacticMetric extends StatelessWidget {
  const _TacticMetric({required this.label, required this.value, required this.color, this.suffix = ''});
  final String label, value, suffix;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value$suffix',
            style: AppTextStyles.headline(color: color)
                .copyWith(fontSize: context.rs(20, min: 16, max: 24))),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(color: AppColors.textMuted)),
      ],
    );
  }
}

class _TeamIdentityCol extends StatelessWidget {
  const _TeamIdentityCol({required this.analysis, required this.color});
  final TeamAnalysisModel analysis;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(analysis.teamName,
            style: AppTextStyles.caption(color: color)
                .copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        _row(Icons.swap_horiz_rounded, analysis.style),
        const SizedBox(height: 4),
        _row(Icons.compress_rounded, analysis.pressureStyle),
        const SizedBox(height: 4),
        _row(Icons.grid_view_rounded, analysis.compactness),
      ],
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 11, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Expanded(
            child: Text(text,
                style: AppTextStyles.caption(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. TEAM COMPARISON ANALYTICS
// ─────────────────────────────────────────────────────────────────────────────

class TeamComparisonCard extends StatelessWidget {
  const TeamComparisonCard({super.key, required this.match});
  final MatchAnalysisModel match;

  @override
  Widget build(BuildContext context) {
    final home = match.homeAnalysis;
    final away = match.awayAnalysis;

    final metrics = [
      _CompMetric('Possession', home.possession.toDouble(), away.possession.toDouble(), '%'),
      _CompMetric('Avg Rating', home.avgRating * 10, away.avgRating * 10, ''),
      _CompMetric('Attack Zones', home.attackingZones.length.toDouble() * 30, away.attackingZones.length.toDouble() * 30, ''),
      _CompMetric('Press Style Score', home.pressureStyle == 'High Press' ? 90 : home.pressureStyle == 'Mid Block' ? 55 : 30, away.pressureStyle == 'High Press' ? 90 : away.pressureStyle == 'Mid Block' ? 55 : 30, ''),
    ];

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Team Comparison',
              icon: Icons.compare_arrows_rounded,
              color: AppColors.accentCyan,
              subtitle: 'Side-by-side analytics'),
          SizedBox(height: context.rs(8, min: 6, max: 10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(home.teamName,
                  style: AppTextStyles.caption(color: AppColors.accentCyan)
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text('vs',
                  style: AppTextStyles.caption(color: AppColors.textMuted)),
              Text(away.teamName,
                  style: AppTextStyles.caption(color: AppColors.primaryPurple)
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          ...metrics.asMap().entries.map((e) => _ComparisonRow(
                metric: e.value,
                delay: Duration(milliseconds: 100 + e.key * 120),
              )),
        ],
      ),
    );
  }
}

class _CompMetric {
  const _CompMetric(this.label, this.homeVal, this.awayVal, this.suffix);
  final String label, suffix;
  final double homeVal, awayVal;
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.metric, required this.delay});
  final _CompMetric metric;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final total = metric.homeVal + metric.awayVal;
    final homeFrac = total == 0 ? 0.5 : (metric.homeVal / total).clamp(0.0, 1.0);
    final awayFrac = 1.0 - homeFrac;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  metric.homeVal >= 10
                      ? metric.homeVal.round().toString()
                      : metric.homeVal.toStringAsFixed(1),
                  style: AppTextStyles.caption(color: AppColors.accentCyan)
                      .copyWith(fontWeight: FontWeight.w700)),
              Text(metric.label,
                  style: AppTextStyles.caption(color: AppColors.textMuted)),
              Text(
                  metric.awayVal >= 10
                      ? metric.awayVal.round().toString()
                      : metric.awayVal.toStringAsFixed(1),
                  style: AppTextStyles.caption(color: AppColors.primaryPurple)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 5),
          GsDualBar(
            leftPct: (homeFrac * 100).round(),
            rightPct: (awayFrac * 100).round(),
            leftColor: AppColors.accentCyan,
            rightColor: AppColors.primaryPurple,
            height: 7,
            delay: delay,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. POSSESSION CHARTS
// ─────────────────────────────────────────────────────────────────────────────

class PossessionChartCard extends StatelessWidget {
  const PossessionChartCard({super.key, required this.match});
  final MatchAnalysisModel match;

  // Mock timeline data (possession by 10-minute intervals)
  static const _homePossession = [55.0, 60.0, 65.0, 62.0, 58.0, 70.0, 64.0, 66.0, 62.0];
  static const _awayPossession = [45.0, 40.0, 35.0, 38.0, 42.0, 30.0, 36.0, 34.0, 38.0];

  @override
  Widget build(BuildContext context) {
    final home = match.homeAnalysis;
    final away = match.awayAnalysis;

    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.accentCyan.withValues(alpha: 0.06), AppColors.surfaceElevated],
      ),
      borderColor: AppColors.accentCyan.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Possession Analysis',
              icon: Icons.pie_chart_rounded,
              color: AppColors.accentCyan,
              subtitle: 'Match timeline'),
          SizedBox(height: context.rs(16, min: 12, max: 20)),

          // Big possession split
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PossessionSide(
                  teamName: home.teamName,
                  pct: home.possession,
                  color: AppColors.accentCyan),
              _PossessionPie(homePct: home.possession, awayPct: away.possession),
              _PossessionSide(
                  teamName: away.teamName,
                  pct: away.possession,
                  color: AppColors.primaryPurple,
                  rightAlign: true),
            ],
          ),
          SizedBox(height: context.rs(16, min: 12, max: 20)),

          // Animated possession bar
          GsDualBar(
            leftPct: home.possession,
            rightPct: away.possession,
            leftColor: AppColors.accentCyan,
            rightColor: AppColors.primaryPurple,
            height: 10,
            delay: const Duration(milliseconds: 200),
          ),
          SizedBox(height: context.rs(18, min: 14, max: 22)),

          // Timeline chart
          Text('Possession Flow (10-min intervals)',
              style: AppTextStyles.caption(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          GsDualLineChart(
            data1: _homePossession,
            data2: _awayPossession,
            color1: AppColors.accentCyan,
            color2: AppColors.primaryPurple,
            height: context.rs(80, min: 60, max: 100),
            label1: home.teamName,
            label2: away.teamName,
          ),
          SizedBox(height: context.rs(10, min: 8, max: 12)),
          // Minute labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const ['0\'', '10\'', '20\'', '30\'', '40\'', '45\'', '60\'', '75\'', '90\'']
                .map((t) => Text(t,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 9)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PossessionSide extends StatelessWidget {
  const _PossessionSide(
      {required this.teamName, required this.pct, required this.color, this.rightAlign = false});
  final String teamName;
  final int pct;
  final Color color;
  final bool rightAlign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          rightAlign ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GsAnimatedCounter(
          value: pct.toDouble(),
          style: AppTextStyles.headline(color: color)
              .copyWith(fontSize: context.rs(28, min: 22, max: 34)),
          suffix: '%',
          delay: const Duration(milliseconds: 300),
        ),
        Text(teamName,
            style: AppTextStyles.caption(color: AppColors.textMuted),
            textAlign: rightAlign ? TextAlign.right : TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _PossessionPie extends StatefulWidget {
  const _PossessionPie({required this.homePct, required this.awayPct});
  final int homePct, awayPct;

  @override
  State<_PossessionPie> createState() => _PossessionPieState();
}

class _PossessionPieState extends State<_PossessionPie>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        width: 70,
        height: 70,
        child: CustomPaint(
          painter: _PiePainter(
              home: widget.homePct,
              away: widget.awayPct,
              progress: _anim.value),
        ),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({required this.home, required this.away, required this.progress});
  final int home, away;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const pi = 3.14159265;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final total = home + away;
    if (total == 0) return;

    final homeAngle = (home / total) * 2 * pi * progress;
    const strokeW = 10.0;

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi,
        false,
        Paint()
          ..color = AppColors.primaryPurple.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW);

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        homeAngle,
        false,
        Paint()
          ..color = AppColors.accentCyan
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_PiePainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. MOMENTUM GRAPH
// ─────────────────────────────────────────────────────────────────────────────

class MomentumGraphCard extends StatelessWidget {
  const MomentumGraphCard({super.key, required this.match});
  final MatchAnalysisModel match;

  static const _homeMomentum = [45.0, 55.0, 70.0, 60.0, 50.0, 65.0, 80.0, 75.0, 85.0];
  static const _awayMomentum = [55.0, 45.0, 30.0, 40.0, 50.0, 35.0, 20.0, 25.0, 15.0];

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.warning.withValues(alpha: 0.07),
          AppColors.surfaceElevated,
        ],
      ),
      borderColor: AppColors.warning.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Match Momentum',
              icon: Icons.trending_up_rounded,
              color: AppColors.warning,
              subtitle: 'Attack pressure flow'),
          SizedBox(height: context.rs(16, min: 12, max: 20)),

          // Momentum key events
          const Row(
            children: [
              _MomentumEvent(minute: '12\'', event: '1st Goal', color: AppColors.accentCyan),
              SizedBox(width: 8),
              _MomentumEvent(minute: '38\'', event: 'Equalizer', color: AppColors.danger),
              SizedBox(width: 8),
              _MomentumEvent(minute: '67\'', event: '2nd Goal', color: AppColors.accentCyan),
              SizedBox(width: 8),
              _MomentumEvent(minute: '88\'', event: 'Penalty', color: AppColors.accentGreen),
            ],
          ),
          SizedBox(height: context.rs(14, min: 10, max: 18)),

          GsDualLineChart(
            data1: _homeMomentum,
            data2: _awayMomentum,
            color1: AppColors.accentCyan,
            color2: AppColors.primaryPurple,
            height: context.rs(90, min: 70, max: 110),
            label1: match.homeTeam,
            label2: match.awayTeam,
          ),
          SizedBox(height: context.rs(8, min: 6, max: 10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const ['0\'', '15\'', '30\'', '45\'', '60\'', '75\'', '90\'']
                .map((t) => Text(t,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 9)))
                .toList(),
          ),
          SizedBox(height: context.rs(10, min: 8, max: 12)),
          Container(
            padding: EdgeInsets.all(context.rs(10, min: 8, max: 12)),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights_rounded, color: AppColors.warning, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Momentum shifted decisively after 67th minute — ${match.homeTeam} dominated final 23 mins.',
                    style: AppTextStyles.caption(color: AppColors.textSecondary),
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

class _MomentumEvent extends StatelessWidget {
  const _MomentumEvent({required this.minute, required this.event, required this.color});
  final String minute, event;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadius.chip,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(minute,
                style: AppTextStyles.caption(color: color)
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 10)),
            Text(event,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. TACTICAL STRENGTHS
// ─────────────────────────────────────────────────────────────────────────────

class TacticalStrengthsCard extends StatelessWidget {
  const TacticalStrengthsCard({super.key, required this.match});
  final MatchAnalysisModel match;

  @override
  Widget build(BuildContext context) {
    final homeName = match.homeAnalysis.teamName;
    final awayName = match.awayAnalysis.teamName;
    final strengths = [
      _StrengthItem(homeName, Icons.shield_rounded, 'Defensive Compactness',
          'Maintained a tight 4-3-3 block, conceded only 2 shots on target in open play.'),
      _StrengthItem(homeName, Icons.route_rounded, 'Central Progression',
          'Controlled the central channel with 87% pass accuracy through the thirds.'),
      _StrengthItem(awayName, Icons.speed_rounded, 'Transition Speed',
          'Converted defensive phases into attacks within 4.2 seconds on average.'),
    ];

    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.accentGreen.withValues(alpha: 0.07), AppColors.surfaceElevated],
      ),
      borderColor: AppColors.accentGreen.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Tactical Strengths',
              icon: Icons.military_tech_rounded,
              color: AppColors.accentGreen),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          ...strengths.asMap().entries.map((e) => _StrengthTile(
              item: e.value,
              delay: Duration(milliseconds: 80 * e.key))),
        ],
      ),
    );
  }
}

class _StrengthItem {
  const _StrengthItem(this.team, this.icon, this.title, this.description);
  final String team, title, description;
  final IconData icon;
}

class _StrengthTile extends StatelessWidget {
  const _StrengthTile({required this.item, required this.delay});
  final _StrengthItem item;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(context.rs(14, min: 12, max: 16)),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withValues(alpha: 0.06),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGreen.withValues(alpha: 0.14)),
            child: Icon(item.icon, color: AppColors.accentGreen, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(item.title,
                            style: AppTextStyles.body(color: AppColors.textPrimary)
                                .copyWith(fontWeight: FontWeight.w600, fontSize: 13))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.accentCyan.withValues(alpha: 0.1),
                          borderRadius: AppRadius.chip),
                      child: Text(item.team,
                          style: AppTextStyles.caption(color: AppColors.accentCyan)
                              .copyWith(fontSize: 9, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.description,
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
// 6. TACTICAL WEAKNESSES
// ─────────────────────────────────────────────────────────────────────────────

class TacticalWeaknessesCard extends StatelessWidget {
  const TacticalWeaknessesCard({super.key, required this.match});
  final MatchAnalysisModel match;

  @override
  Widget build(BuildContext context) {
    final awayName = match.awayAnalysis.teamName;
    final weaknesses = [
      _WeaknessItem(awayName, Icons.warning_amber_rounded, 'Transition Recovery',
          'Left-back was bypassed 7 times. Transition recovery averaged 5.8 seconds.', _RiskLevel.high),
      _WeaknessItem(match.homeAnalysis.teamName, Icons.center_focus_weak_rounded,
          'Over-reliance on Center',
          '71% of attacks funneled through central zones — predictable and easily blocked.', _RiskLevel.medium),
    ];

    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.danger.withValues(alpha: 0.07), AppColors.surfaceElevated],
      ),
      borderColor: AppColors.danger.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Tactical Weaknesses',
              icon: Icons.crisis_alert_rounded,
              color: AppColors.danger),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          ...weaknesses.map((w) => _WeaknessTile(item: w)),
        ],
      ),
    );
  }
}

enum _RiskLevel { low, medium, high }

class _WeaknessItem {
  const _WeaknessItem(this.team, this.icon, this.title, this.description, this.level);
  final String team, title, description;
  final IconData icon;
  final _RiskLevel level;
}

class _WeaknessTile extends StatelessWidget {
  const _WeaknessTile({required this.item});
  final _WeaknessItem item;

  Color get _levelColor {
    switch (item.level) {
      case _RiskLevel.high:
        return AppColors.danger;
      case _RiskLevel.medium:
        return AppColors.warning;
      case _RiskLevel.low:
        return AppColors.accentGreen;
    }
  }

  String get _levelLabel {
    switch (item.level) {
      case _RiskLevel.high:
        return 'HIGH';
      case _RiskLevel.medium:
        return 'MED';
      case _RiskLevel.low:
        return 'LOW';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(context.rs(14, min: 12, max: 16)),
      decoration: BoxDecoration(
        color: _levelColor.withValues(alpha: 0.05),
        borderRadius: AppRadius.card,
        border: Border.all(color: _levelColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: _levelColor.withValues(alpha: 0.12)),
            child: Icon(item.icon, color: _levelColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(item.title,
                            style: AppTextStyles.body(color: AppColors.textPrimary)
                                .copyWith(fontWeight: FontWeight.w600, fontSize: 13))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: _levelColor.withValues(alpha: 0.12),
                          borderRadius: AppRadius.chip),
                      child: Text(_levelLabel,
                          style: AppTextStyles.caption(color: _levelColor)
                              .copyWith(fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.description,
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
// 7. ATTACK ZONES VISUALIZATION
// ─────────────────────────────────────────────────────────────────────────────

class AttackZonesCard extends StatelessWidget {
  const AttackZonesCard({super.key, required this.match});
  final MatchAnalysisModel match;

  @override
  Widget build(BuildContext context) {
    final home = match.homeAnalysis;
    final away = match.awayAnalysis;

    final homeHasLeft = home.attackingZones.any((z) => z.toLowerCase().contains('left'));
    final homeHasCenter = home.attackingZones.any((z) => z.toLowerCase().contains('central') || z.toLowerCase().contains('center'));
    final homeHasRight = home.attackingZones.any((z) => z.toLowerCase().contains('right'));

    final awayHasLeft = away.attackingZones.any((z) => z.toLowerCase().contains('left'));
    final awayHasCenter = away.attackingZones.any((z) => z.toLowerCase().contains('central') || z.toLowerCase().contains('center'));
    final awayHasRight = away.attackingZones.any((z) => z.toLowerCase().contains('right'));

    final homeHeatmap = [
      if (homeHasLeft) const HeatmapPoint(0.18, 0.4, 0.8),
      if (homeHasLeft) const HeatmapPoint(0.12, 0.6, 0.6),
      if (homeHasCenter) const HeatmapPoint(0.4, 0.5, 0.9),
      if (homeHasCenter) const HeatmapPoint(0.45, 0.35, 0.7),
      if (homeHasRight) const HeatmapPoint(0.7, 0.3, 0.75),
      const HeatmapPoint(0.3, 0.5, 0.4),
    ];

    final awayHeatmap = [
      if (awayHasLeft) const HeatmapPoint(0.2, 0.35, 0.7),
      if (awayHasCenter) const HeatmapPoint(0.5, 0.5, 0.6),
      if (awayHasRight) const HeatmapPoint(0.75, 0.4, 0.85),
      if (awayHasRight) const HeatmapPoint(0.8, 0.6, 0.55),
      const HeatmapPoint(0.6, 0.5, 0.35),
    ];

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Attack Zones',
              icon: Icons.location_on_rounded,
              color: AppColors.primaryBlue,
              subtitle: 'Attacking heat distribution'),
          SizedBox(height: context.rs(16, min: 12, max: 20)),
          context.adaptiveLayout(
            narrow: Column(
              children: [
                _ZonePitchPanel(
                    teamName: home.teamName,
                    color: AppColors.accentCyan,
                    heatmap: homeHeatmap,
                    zones: home.attackingZones),
                SizedBox(height: context.rs(12, min: 8, max: 16)),
                _ZonePitchPanel(
                    teamName: away.teamName,
                    color: AppColors.primaryPurple,
                    heatmap: awayHeatmap,
                    zones: away.attackingZones),
              ],
            ),
            wide: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _ZonePitchPanel(
                    teamName: home.teamName,
                    color: AppColors.accentCyan,
                    heatmap: homeHeatmap,
                    zones: home.attackingZones)),
                SizedBox(width: context.rs(12, min: 8, max: 16)),
                Expanded(child: _ZonePitchPanel(
                    teamName: away.teamName,
                    color: AppColors.primaryPurple,
                    heatmap: awayHeatmap,
                    zones: away.attackingZones)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZonePitchPanel extends StatelessWidget {
  const _ZonePitchPanel(
      {required this.teamName, required this.color, required this.heatmap, required this.zones});
  final String teamName;
  final Color color;
  final List<HeatmapPoint> heatmap;
  final List<String> zones;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Expanded(
                child: Text(teamName,
                    style: AppTextStyles.caption(color: color)
                        .copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
        const SizedBox(height: 8),
        GsPitchWidget(
          heatmapData: heatmap,
          showZones: true,
          height: 110,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: zones
              .map((z) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: AppRadius.chip,
                        border: Border.all(color: color.withValues(alpha: 0.25))),
                    child: Text(z,
                        style: AppTextStyles.caption(color: color)
                            .copyWith(fontSize: 10, fontWeight: FontWeight.w600)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. COACH RECOMMENDATIONS (enhanced)
// ─────────────────────────────────────────────────────────────────────────────

class CoachRecommendationsCard extends StatelessWidget {
  const CoachRecommendationsCard({super.key, required this.recommendations});
  final List<String> recommendations;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    final priorities = ['CRITICAL', 'HIGH', 'MEDIUM'];

    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.accentGreen.withValues(alpha: 0.08),
          AppColors.surfaceElevated,
        ],
      ),
      borderColor: AppColors.accentGreen.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionHeader(
                title: 'Coach Recommendations',
                icon: Icons.lightbulb_rounded,
                color: AppColors.accentGreen,
                subtitle: 'AI-generated tactical advice',
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withValues(alpha: 0.15),
                    borderRadius: AppRadius.chip),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: AppColors.accentGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('AI',
                        style: AppTextStyles.caption(color: AppColors.accentGreen)
                            .copyWith(fontWeight: FontWeight.w800, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          ...recommendations.asMap().entries.map((e) {
            final priority = e.key < priorities.length ? priorities[e.key] : 'LOW';
            final priorityColor = priority == 'CRITICAL'
                ? AppColors.danger
                : priority == 'HIGH'
                    ? AppColors.warning
                    : AppColors.accentGreen;
            return _RecommendationTile(
              index: e.key,
              text: e.value,
              priority: priority,
              priorityColor: priorityColor,
              delay: Duration(milliseconds: 80 * e.key),
            );
          }),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatefulWidget {
  const _RecommendationTile({
    required this.index,
    required this.text,
    required this.priority,
    required this.priorityColor,
    required this.delay,
  });
  final int index;
  final String text, priority;
  final Color priorityColor;
  final Duration delay;

  @override
  State<_RecommendationTile> createState() => _RecommendationTileState();
}

class _RecommendationTileState extends State<_RecommendationTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.priorityColor.withValues(alpha: 0.05),
        borderRadius: AppRadius.card,
        border: Border.all(color: widget.priorityColor.withValues(alpha: 0.18)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: EdgeInsets.all(context.rs(14, min: 12, max: 16)),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                          color: widget.priorityColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle),
                      child: Center(
                        child: Text('${widget.index + 1}',
                            style: AppTextStyles.caption(color: widget.priorityColor)
                                .copyWith(fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: widget.priorityColor.withValues(alpha: 0.12),
                          borderRadius: AppRadius.chip),
                      child: Text(widget.priority,
                          style: AppTextStyles.caption(color: widget.priorityColor)
                              .copyWith(fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.text,
                        style: AppTextStyles.body(color: AppColors.textSecondary)
                            .copyWith(fontSize: 12),
                        maxLines: _expanded ? null : 2,
                        overflow: _expanded ? null : TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 9. PLAYER IMPACT ANALYSIS
// ─────────────────────────────────────────────────────────────────────────────

class PlayerImpactCard extends StatelessWidget {
  const PlayerImpactCard({super.key, required this.players});
  final List<PlayerModel> players;

  @override
  Widget build(BuildContext context) {
    final top5 = ([...players]
          ..sort((a, b) => b.rating.compareTo(a.rating)))
        .take(5)
        .toList();

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Player Impact',
              icon: Icons.bolt_rounded,
              color: AppColors.accentCyan,
              subtitle: 'Top 5 by performance'),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          ...top5.asMap().entries.map((e) => _PlayerImpactRow(
              player: e.value,
              rank: e.key + 1,
              delay: Duration(milliseconds: 80 * e.key))),
        ],
      ),
    );
  }
}

class _PlayerImpactRow extends StatelessWidget {
  const _PlayerImpactRow({required this.player, required this.rank, required this.delay});
  final PlayerModel player;
  final int rank;
  final Duration delay;

  Color get _ratingColor {
    if (player.rating >= 8.5) return AppColors.accentCyan;
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
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 20,
            child: Text('#$rank',
                style: AppTextStyles.caption(color: AppColors.textMuted)
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [
                _ratingColor.withValues(alpha: 0.3),
                _ratingColor.withValues(alpha: 0.05)
              ]),
              border: Border.all(color: _ratingColor.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(player.name[0],
                  style: AppTextStyles.button(color: _ratingColor)
                      .copyWith(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(player.name,
                            style: AppTextStyles.body(color: AppColors.textPrimary)
                                .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                            color: _ratingColor.withValues(alpha: 0.12),
                            borderRadius: AppRadius.chip),
                        child: Text(player.rating.toStringAsFixed(1),
                            style: AppTextStyles.caption(color: _ratingColor)
                                .copyWith(fontWeight: FontWeight.w800))),
                  ],
                ),
                const SizedBox(height: 4),
                GsAnimatedBar(
                    value: player.rating / 10,
                    color: _ratingColor,
                    backgroundColor: AppColors.surface,
                    height: 4,
                    delay: delay),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: const BoxDecoration(
                color: AppColors.surface, borderRadius: AppRadius.chip),
            child: Text(player.impact,
                style: AppTextStyles.caption(color: AppColors.textSecondary)
                    .copyWith(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 10. FATIGUE ANALYSIS
// ─────────────────────────────────────────────────────────────────────────────

class FatigueAnalysisCard extends StatelessWidget {
  const FatigueAnalysisCard({super.key, required this.players});
  final List<PlayerModel> players;

  @override
  Widget build(BuildContext context) {
    final sortedByFatigue = ([...players]
          ..sort((a, b) => b.fatigue.compareTo(a.fatigue)))
        .take(6)
        .toList();

    final criticalCount = players.where((p) => p.fatigue >= 80).length;
    final highCount = players.where((p) => p.fatigue >= 60 && p.fatigue < 80).length;

    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.warning.withValues(alpha: 0.07), AppColors.surfaceElevated],
      ),
      borderColor: AppColors.warning.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Fatigue Analysis',
              icon: Icons.battery_alert_rounded,
              color: AppColors.warning,
              subtitle: 'Player workload monitoring'),
          SizedBox(height: context.rs(12, min: 8, max: 16)),
          Row(
            children: [
              _FatigueStat(count: criticalCount, label: 'Critical', color: AppColors.danger),
              const SizedBox(width: 12),
              _FatigueStat(count: highCount, label: 'High Risk', color: AppColors.warning),
              const SizedBox(width: 12),
              _FatigueStat(
                  count: players.length - criticalCount - highCount,
                  label: 'Normal',
                  color: AppColors.accentGreen),
            ],
          ),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          ...sortedByFatigue.asMap().entries.map((e) => _FatigueRow(
              player: e.value,
              delay: Duration(milliseconds: 80 * e.key))),
        ],
      ),
    );
  }
}

class _FatigueStat extends StatelessWidget {
  const _FatigueStat({required this.count, required this.label, required this.color});
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: AppRadius.card,
            border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(
          children: [
            Text('$count',
                style: AppTextStyles.title(color: color)
                    .copyWith(fontSize: context.rs(20, min: 16, max: 24))),
            Text(label,
                style: AppTextStyles.caption(color: AppColors.textMuted)
                    .copyWith(fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _FatigueRow extends StatelessWidget {
  const _FatigueRow({required this.player, required this.delay});
  final PlayerModel player;
  final Duration delay;

  Color get _fatigueColor {
    if (player.fatigue >= 80) return AppColors.danger;
    if (player.fatigue >= 60) return AppColors.warning;
    return AppColors.accentGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: context.rs(90, min: 72, max: 110),
            child: Text(player.name,
                style: AppTextStyles.caption(color: AppColors.textPrimary)
                    .copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GsAnimatedBar(
              value: player.fatigue / 100,
              color: _fatigueColor,
              backgroundColor: AppColors.surface,
              height: 7,
              delay: delay,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, color: _fatigueColor, size: 11),
                const SizedBox(width: 2),
                Text('${player.fatigue}',
                    style: AppTextStyles.caption(color: _fatigueColor)
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 11. RISK ANALYSIS
// ─────────────────────────────────────────────────────────────────────────────

class RiskAnalysisCard extends StatelessWidget {
  const RiskAnalysisCard({super.key, required this.players, required this.match});
  final List<PlayerModel> players;
  final MatchAnalysisModel match;

  @override
  Widget build(BuildContext context) {
    final risks = _buildRisks();

    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.danger.withValues(alpha: 0.06), AppColors.surfaceElevated],
      ),
      borderColor: AppColors.danger.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Risk Intelligence',
              icon: Icons.gpp_bad_rounded,
              color: AppColors.danger,
              subtitle: 'AI-detected match risks'),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: risks
                .map((r) => _RiskBadge(label: r.label, severity: r.severity, description: r.description))
                .toList(),
          ),
        ],
      ),
    );
  }

  List<_Risk> _buildRisks() {
    final risks = <_Risk>[];
    final criticalPlayers = players.where((p) => p.fatigue >= 85).toList();
    if (criticalPlayers.isNotEmpty) {
      risks.add(_Risk('Injury Risk', _Severity.critical,
          '${criticalPlayers.first.name} fatigue at ${criticalPlayers.first.fatigue}%'));
    }
    if (match.intensity >= 85) {
      risks.add(const _Risk('Fatigue Risk', _Severity.high,
          'High-intensity match — squad recovery period required.'));
    }
    final worstPlayers = players.where((p) => p.isWorst).toList();
    if (worstPlayers.isNotEmpty) {
      risks.add(_Risk('Inconsistency Risk', _Severity.medium,
          '${worstPlayers.first.name} underperformed — needs tactical review.'));
    }
    risks.add(const _Risk('Tactical Risk', _Severity.low,
        'Over-reliance on Hassan Ali detected across 3 consecutive matches.'));
    return risks;
  }
}

enum _Severity { critical, high, medium, low }

class _Risk {
  const _Risk(this.label, this.severity, this.description);
  final String label, description;
  final _Severity severity;
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.label, required this.severity, required this.description});
  final String label, description;
  final _Severity severity;

  Color get _color {
    switch (severity) {
      case _Severity.critical:
        return AppColors.danger;
      case _Severity.high:
        return AppColors.warning;
      case _Severity.medium:
        return AppColors.primaryBlue;
      case _Severity.low:
        return AppColors.textMuted;
    }
  }

  String get _level {
    switch (severity) {
      case _Severity.critical:
        return 'CRITICAL';
      case _Severity.high:
        return 'HIGH';
      case _Severity.medium:
        return 'MEDIUM';
      case _Severity.low:
        return 'LOW';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: context.screenWidth * 0.44),
      padding: EdgeInsets.all(context.rs(12, min: 10, max: 14)),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.07),
        borderRadius: AppRadius.card,
        border: Border.all(color: _color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(label,
                      style: AppTextStyles.caption(color: _color)
                          .copyWith(fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    borderRadius: AppRadius.chip),
                child: Text(_level,
                    style: AppTextStyles.caption(color: _color)
                        .copyWith(fontSize: 8, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(description,
              style: AppTextStyles.caption(color: AppColors.textSecondary)
                  .copyWith(fontSize: 10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 12. HEATMAPS
// ─────────────────────────────────────────────────────────────────────────────

class HeatmapCard extends StatelessWidget {
  const HeatmapCard({super.key, required this.match});
  final MatchAnalysisModel match;

  @override
  Widget build(BuildContext context) {
    // Derive heatmap from team attacking zones
    final homeData = _zoneToHeatmap(match.homeAnalysis.attackingZones, true);
    final awayData = _zoneToHeatmap(match.awayAnalysis.attackingZones, false);

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Movement Heatmaps',
              icon: Icons.thermostat_rounded,
              color: AppColors.primaryBlue,
              subtitle: 'Activity density map'),
          SizedBox(height: context.rs(16, min: 12, max: 20)),
          GsPitchWidget(
            heatmapData: [...homeData, ...awayData],
            showZones: false,
            height: context.rs(160, min: 130, max: 200),
          ),
          SizedBox(height: context.rs(10, min: 8, max: 12)),
          Row(
            children: [
              _HeatLegend(color: AppColors.accentCyan, label: match.homeTeam),
              const SizedBox(width: 16),
              _HeatLegend(color: AppColors.primaryPurple, label: match.awayTeam),
            ],
          ),
        ],
      ),
    );
  }

  static List<HeatmapPoint> _zoneToHeatmap(List<String> zones, bool isHome) {
    final pts = <HeatmapPoint>[];
    for (final z in zones) {
      final lz = z.toLowerCase();
      if (lz.contains('left')) {
        pts.add(HeatmapPoint(isHome ? 0.15 : 0.85, 0.25, 0.9));
        pts.add(HeatmapPoint(isHome ? 0.25 : 0.75, 0.45, 0.7));
      } else if (lz.contains('central') || lz.contains('center')) {
        pts.add(const HeatmapPoint(0.5, 0.35, 0.95));
        pts.add(const HeatmapPoint(0.45, 0.55, 0.75));
        pts.add(const HeatmapPoint(0.55, 0.5, 0.65));
      } else if (lz.contains('right')) {
        pts.add(HeatmapPoint(isHome ? 0.75 : 0.25, 0.3, 0.85));
        pts.add(HeatmapPoint(isHome ? 0.8 : 0.2, 0.5, 0.6));
      } else if (lz.contains('set')) {
        pts.add(HeatmapPoint(isHome ? 0.92 : 0.08, 0.3, 0.8));
        pts.add(HeatmapPoint(isHome ? 0.88 : 0.12, 0.5, 0.7));
        pts.add(HeatmapPoint(isHome ? 0.90 : 0.10, 0.65, 0.6));
      }
    }
    return pts;
  }
}

class _HeatLegend extends StatelessWidget {
  const _HeatLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                gradient: RadialGradient(
                    colors: [color, color.withValues(alpha: 0.3)]),
                shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.caption(color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 13. FORMATION VISUALIZATION
// ─────────────────────────────────────────────────────────────────────────────

class FormationCard extends StatelessWidget {
  const FormationCard({super.key, required this.match});
  final MatchAnalysisModel match;

  @override
  Widget build(BuildContext context) {
    final homePlayers = _buildFormation(match.players.take(5).toList(), true);
    final awayPlayers = _buildFormation(match.players.skip(3).take(5).toList(), false);

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Formation & Shape',
              icon: Icons.sports_soccer_rounded,
              color: AppColors.accentGreen,
              subtitle: 'Tactical positioning'),
          SizedBox(height: context.rs(16, min: 12, max: 20)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(match.homeTeam,
                  style: AppTextStyles.caption(color: AppColors.accentCyan)
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: const BoxDecoration(
                      color: AppColors.surface, borderRadius: AppRadius.chip),
                  child: Text('4-3-3',
                      style: AppTextStyles.caption(color: AppColors.textSecondary)
                          .copyWith(fontWeight: FontWeight.w700))),
              Text(match.awayTeam,
                  style: AppTextStyles.caption(color: AppColors.primaryPurple)
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
          SizedBox(height: context.rs(12, min: 8, max: 16)),
          GsPitchWidget(
            playerPositions: [...homePlayers, ...awayPlayers],
            height: context.rs(170, min: 140, max: 210),
          ),
          SizedBox(height: context.rs(10, min: 8, max: 12)),
          Row(
            children: [
              _FormLegend(color: AppColors.accentCyan, label: match.homeTeam),
              const SizedBox(width: 16),
              _FormLegend(color: AppColors.primaryPurple, label: match.awayTeam),
            ],
          ),
        ],
      ),
    );
  }

  static List<PitchPlayer> _buildFormation(List<PlayerModel> players, bool isHome) {
    final positions = isHome
        ? [
            const PitchPlayer(0.08, 0.5, 'GK'),
            const PitchPlayer(0.25, 0.18, 'RB'),
            const PitchPlayer(0.25, 0.4, 'CB'),
            const PitchPlayer(0.25, 0.62, 'CB'),
            const PitchPlayer(0.25, 0.82, 'LB'),
            const PitchPlayer(0.4, 0.3, 'DM'),
            const PitchPlayer(0.4, 0.5, 'CM'),
            const PitchPlayer(0.4, 0.7, 'CM'),
            const PitchPlayer(0.65, 0.2, 'RW'),
            const PitchPlayer(0.65, 0.5, 'CF'),
            const PitchPlayer(0.65, 0.8, 'LW'),
          ]
        : [
            const PitchPlayer(0.92, 0.5, 'GK'),
            const PitchPlayer(0.75, 0.18, 'LB'),
            const PitchPlayer(0.75, 0.4, 'CB'),
            const PitchPlayer(0.75, 0.62, 'CB'),
            const PitchPlayer(0.75, 0.82, 'RB'),
            const PitchPlayer(0.6, 0.3, 'DM'),
            const PitchPlayer(0.6, 0.5, 'CM'),
            const PitchPlayer(0.6, 0.7, 'CM'),
            const PitchPlayer(0.35, 0.2, 'LW'),
            const PitchPlayer(0.35, 0.5, 'CF'),
            const PitchPlayer(0.35, 0.8, 'RW'),
          ];

    final color = isHome ? AppColors.accentCyan : AppColors.primaryPurple;
    return positions.map((p) => PitchPlayer(p.x, p.y, p.label, color: color)).toList();
  }
}

class _FormLegend extends StatelessWidget {
  const _FormLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.caption(color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 14. BIRD-EYE TACTICAL VIEW
// ─────────────────────────────────────────────────────────────────────────────

class BirdEyeCard extends StatelessWidget {
  const BirdEyeCard({super.key, required this.match});
  final MatchAnalysisModel match;

  @override
  Widget build(BuildContext context) {
    final arrows = _buildArrows(match.homeAnalysis, match.awayAnalysis);

    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryBlue.withValues(alpha: 0.08), AppColors.surfaceElevated],
      ),
      borderColor: AppColors.primaryBlue.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              title: 'Bird-Eye Tactical View',
              icon: Icons.satellite_alt_rounded,
              color: AppColors.primaryBlue,
              subtitle: 'Movement & directional analysis'),
          SizedBox(height: context.rs(16, min: 12, max: 20)),
          GsPitchWidget(
            attackArrows: arrows,
            heatmapData: const [
              HeatmapPoint(0.4, 0.5, 0.7),
              HeatmapPoint(0.6, 0.5, 0.5),
              HeatmapPoint(0.5, 0.35, 0.6),
            ],
            height: context.rs(170, min: 140, max: 210),
          ),
          SizedBox(height: context.rs(12, min: 8, max: 16)),
          Row(
            children: [
              Expanded(child: _BirdEyeStat(label: 'Compactness', value: match.homeAnalysis.compactness, color: AppColors.accentCyan)),
              SizedBox(width: context.rs(10, min: 8, max: 12)),
              Expanded(child: _BirdEyeStat(label: 'Press Style', value: match.homeAnalysis.pressureStyle, color: AppColors.primaryPurple)),
              SizedBox(width: context.rs(10, min: 8, max: 12)),
              Expanded(child: _BirdEyeStat(label: 'Away Shape', value: match.awayAnalysis.compactness, color: AppColors.warning)),
            ],
          ),
        ],
      ),
    );
  }

  static List<PitchArrow> _buildArrows(TeamAnalysisModel home, TeamAnalysisModel away) {
    final arrows = <PitchArrow>[];
    for (final zone in home.attackingZones) {
      final lz = zone.toLowerCase();
      if (lz.contains('left')) {
        arrows.add(const PitchArrow(0.2, 0.7, 0.8, 0.75, color: AppColors.accentCyan));
      } else if (lz.contains('central') || lz.contains('center')) {
        arrows.add(const PitchArrow(0.15, 0.5, 0.85, 0.5, color: AppColors.accentCyan));
      } else if (lz.contains('right')) {
        arrows.add(const PitchArrow(0.2, 0.3, 0.8, 0.25, color: AppColors.accentCyan));
      }
    }
    for (final zone in away.attackingZones) {
      final lz = zone.toLowerCase();
      if (lz.contains('left')) {
        arrows.add(const PitchArrow(0.8, 0.7, 0.2, 0.75, color: AppColors.primaryPurple));
      } else if (lz.contains('central') || lz.contains('center')) {
        arrows.add(const PitchArrow(0.85, 0.45, 0.15, 0.45, color: AppColors.primaryPurple));
      } else if (lz.contains('right')) {
        arrows.add(const PitchArrow(0.8, 0.25, 0.2, 0.3, color: AppColors.primaryPurple));
      }
    }
    return arrows;
  }
}

class _BirdEyeStat extends StatelessWidget {
  const _BirdEyeStat({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: AppRadius.card,
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(value,
              style: AppTextStyles.caption(color: color)
                  .copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption(color: AppColors.textMuted)
                  .copyWith(fontSize: 9),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 15. AI INSIGHTS CARDS
// ─────────────────────────────────────────────────────────────────────────────

class AIInsightsCard extends StatelessWidget {
  const AIInsightsCard({super.key, required this.match});
  final MatchAnalysisModel match;

  // Mock AI insights from match data
  List<_AIInsight> _buildInsights() {
    return [
      _AIInsight(
        'Pressing Intensity Declined',
        'Pressing intensity decreased significantly after the 70th minute — ${match.homeTeam} completed 67% fewer defensive recoveries in the final 20 minutes.',
        Icons.trending_down_rounded,
        AppColors.warning,
        'Tactical Pattern',
      ),
      _AIInsight(
        'Wide Overload Detected',
        'The left flank was exploited 11 times throughout the match, with ${match.homeAnalysis.attackingZones.isNotEmpty ? match.homeAnalysis.attackingZones.first : "wide areas"} showing the highest attack density.',
        Icons.open_with_rounded,
        AppColors.accentCyan,
        'Positional',
      ),
      const _AIInsight(
        'Midfield Compactness Weakened',
        'Central compactness dropped in the last 20 minutes as fatigue set in — creating exploitable gaps between lines 2 and 3.',
        Icons.compress_rounded,
        AppColors.primaryPurple,
        'Structural',
      ),
      _AIInsight(
        'Set-Piece Vulnerability',
        '${match.awayTeam} won 8 corners and 6 free-kicks in dangerous areas — set-piece defensive organization needs review.',
        Icons.flag_rounded,
        AppColors.danger,
        'Defensive',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final insights = _buildInsights();

    return _GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryPurple.withValues(alpha: 0.1),
          AppColors.surfaceElevated,
          AppColors.accentCyan.withValues(alpha: 0.05),
        ],
      ),
      borderColor: AppColors.primaryPurple.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionHeader(
                title: 'AI Match Insights',
                icon: Icons.auto_awesome_rounded,
                color: AppColors.primaryPurple,
                subtitle: 'Neural pattern analysis',
              ),
              _AIPulse(),
            ],
          ),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          ...insights.asMap().entries.map((e) => _AIInsightTile(
              insight: e.value,
              delay: Duration(milliseconds: 80 * e.key))),
        ],
      ),
    );
  }
}

class _AIInsight {
  const _AIInsight(this.title, this.description, this.icon, this.color, this.category);
  final String title, description, category;
  final IconData icon;
  final Color color;
}

class _AIInsightTile extends StatefulWidget {
  const _AIInsightTile({required this.insight, required this.delay});
  final _AIInsight insight;
  final Duration delay;

  @override
  State<_AIInsightTile> createState() => _AIInsightTileState();
}

class _AIInsightTileState extends State<_AIInsightTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.insight.color.withValues(alpha: 0.05),
        borderRadius: AppRadius.card,
        border: Border.all(color: widget.insight.color.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: EdgeInsets.all(context.rs(14, min: 12, max: 16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.insight.color.withValues(alpha: 0.12),
                    boxShadow: [
                      BoxShadow(
                          color: widget.insight.color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 0),
                    ],
                  ),
                  child: Icon(widget.insight.icon,
                      color: widget.insight.color, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(widget.insight.title,
                                style: AppTextStyles.body(color: AppColors.textPrimary)
                                    .copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: widget.insight.color.withValues(alpha: 0.1),
                                borderRadius: AppRadius.chip),
                            child: Text(widget.insight.category,
                                style: AppTextStyles.caption(color: widget.insight.color)
                                    .copyWith(fontSize: 9, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.insight.description,
                        style: AppTextStyles.caption(color: AppColors.textSecondary),
                        maxLines: _expanded ? null : 2,
                        overflow: _expanded ? null : TextOverflow.ellipsis,
                      ),
                      if (!_expanded) ...[
                        const SizedBox(height: 4),
                        Text('Tap to expand',
                            style: AppTextStyles.caption(color: widget.insight.color)
                                .copyWith(fontSize: 10)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AIPulse extends StatefulWidget {
  @override
  State<_AIPulse> createState() => _AIPulseState();
}

class _AIPulseState extends State<_AIPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryPurple.withValues(alpha: 0.15 + _pulse.value * 0.1),
              AppColors.accentCyan.withValues(alpha: 0.15 + _pulse.value * 0.1),
            ],
          ),
          borderRadius: AppRadius.chip,
          border: Border.all(
              color: AppColors.primaryPurple
                  .withValues(alpha: 0.3 + _pulse.value * 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentCyan
                    .withValues(alpha: 0.7 + _pulse.value * 0.3),
              ),
            ),
            const SizedBox(width: 5),
            Text('LIVE AI',
                style: AppTextStyles.caption(color: AppColors.accentCyan)
                    .copyWith(fontSize: 9, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
