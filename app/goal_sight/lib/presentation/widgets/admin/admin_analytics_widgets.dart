// ---------------------------------------------------------------------------
// GoalSight — Admin Analytics Widgets
//
// Premium widgets for the Club Analytics screen:
//   • ClubTacticalEvolutionSection  — trend charts showing tactical progression
//   • ClubSeasonStatsSection        — season KPI cards
//   • ClubMatchIntensitySection     — match-by-match intensity chart
//   • ClubFatigueOverviewSection    — squad fatigue trend over season
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/admin/data/admin_mock_data.dart';

// ============================================================================
// CLUB TACTICAL EVOLUTION
// ============================================================================

class ClubTacticalEvolutionSection extends StatelessWidget {
  const ClubTacticalEvolutionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final trends = AdminMockData.performanceTrends;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.show_chart, color: AppColors.accentCyan, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Tactical Evolution', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Last 8 weeks — possession, pressure & rating',
              style: AppTextStyles.caption(color: AppColors.textMuted)),
          const SizedBox(height: 20),
          // Chart
          SizedBox(
            height: 100,
            child: CustomPaint(
              painter: _MultiLinePainter(trends: trends),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 10),
          // X labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: trends.map((t) => Text(t.label,
                style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 9))).toList(),
          ),
          const SizedBox(height: 16),
          // Legend
          const Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _LegendItem(color: AppColors.accentCyan, label: 'Possession %'),
              _LegendItem(color: AppColors.primaryPurple, label: 'Pressure Index'),
              _LegendItem(color: AppColors.accentGreen, label: 'Team Rating × 10'),
            ],
          ),
          const SizedBox(height: 16),
          // Current values
          Row(
            children: [
              Expanded(child: _TrendValue(
                label: 'Possession',
                current: '${trends.last.possession.toInt()}%',
                change: '+${(trends.last.possession - trends.first.possession).toInt()}%',
                up: trends.last.possession > trends.first.possession,
                color: AppColors.accentCyan,
              )),
              Expanded(child: _TrendValue(
                label: 'Pressure',
                current: '${trends.last.pressureIndex.toInt()}%',
                change: '+${(trends.last.pressureIndex - trends.first.pressureIndex).toInt()}%',
                up: trends.last.pressureIndex > trends.first.pressureIndex,
                color: AppColors.primaryPurple,
              )),
              Expanded(child: _TrendValue(
                label: 'Team Rating',
                current: trends.last.teamRating.toStringAsFixed(1),
                change: '+${(trends.last.teamRating - trends.first.teamRating).toStringAsFixed(1)}',
                up: trends.last.teamRating > trends.first.teamRating,
                color: AppColors.accentGreen,
              )),
              Expanded(child: _TrendValue(
                label: 'xG/Match',
                current: trends.last.xg.toStringAsFixed(1),
                change: '+${(trends.last.xg - trends.first.xg).toStringAsFixed(1)}',
                up: trends.last.xg > trends.first.xg,
                color: AppColors.warning,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption(color: AppColors.textSecondary).copyWith(fontSize: 11)),
      ],
    );
  }
}

class _TrendValue extends StatelessWidget {
  final String label;
  final String current;
  final String change;
  final bool up;
  final Color color;
  const _TrendValue({required this.label, required this.current, required this.change, required this.up, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(current, style: AppTextStyles.title(color: color).copyWith(fontSize: 16)),
        Text(label, style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 10)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: up ? AppColors.accentGreen : AppColors.danger, size: 14),
            Text(change, style: AppTextStyles.caption(
              color: up ? AppColors.accentGreen : AppColors.danger,
            ).copyWith(fontSize: 9)),
          ],
        ),
      ],
    );
  }
}

// ─── Multi-Line Chart Painter ──────────────────────────────────────────────

class _MultiLinePainter extends CustomPainter {
  final List<ClubPerformanceTrend> trends;
  const _MultiLinePainter({required this.trends});

  @override
  void paint(Canvas canvas, Size size) {
    if (trends.length < 2) return;
    final n = trends.length;

    _drawLine(canvas, size, n,
        values: trends.map((t) => t.possession).toList(),
        min: 50, max: 70, color: AppColors.accentCyan);

    _drawLine(canvas, size, n,
        values: trends.map((t) => t.pressureIndex).toList(),
        min: 65, max: 95, color: AppColors.primaryPurple);

    _drawLine(canvas, size, n,
        values: trends.map((t) => t.teamRating * 10).toList(),
        min: 70, max: 95, color: AppColors.accentGreen);
  }

  void _drawLine(Canvas canvas, Size size, int n,
      {required List<double> values, required double min, required double max, required Color color}) {
    final range = (max - min).clamp(0.01, double.infinity);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - min) / range) * (size.height - 8);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    // Dots at each point
    final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - min) / range) * (size.height - 8);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_MultiLinePainter old) => old.trends != trends;
}

// ============================================================================
// SEASON STATS SECTION
// ============================================================================

class ClubSeasonStatsSection extends StatelessWidget {
  const ClubSeasonStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Season Analytics', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(child: _SeasonCard(value: '38', label: 'Matches Played', sublabel: '+6 this month', color: AppColors.accentCyan, icon: Icons.sports_soccer)),
            SizedBox(width: 10),
            Expanded(child: _SeasonCard(value: '24', label: 'Wins', sublabel: '63% win rate', color: AppColors.accentGreen, icon: Icons.emoji_events_outlined)),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(child: _SeasonCard(value: '72', label: 'Goals Scored', sublabel: '1.9/match avg', color: AppColors.primaryPurple, icon: Icons.flag_outlined)),
            SizedBox(width: 10),
            Expanded(child: _SeasonCard(value: '31', label: 'Goals Conceded', sublabel: '0.8/match avg', color: AppColors.warning, icon: Icons.shield_outlined)),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(child: _SeasonCard(value: '391', label: 'Total Analyses', sublabel: 'by AI engine', color: AppColors.accentCyan, icon: Icons.analytics_outlined)),
            SizedBox(width: 10),
            Expanded(child: _SeasonCard(value: '8.9', label: 'Avg Team Rating', sublabel: '+0.4 vs last season', color: AppColors.accentGreen, icon: Icons.star_outline)),
          ],
        ),
      ],
    );
  }
}

class _SeasonCard extends StatelessWidget {
  final String value;
  final String label;
  final String sublabel;
  final Color color;
  final IconData icon;
  const _SeasonCard({required this.value, required this.label, required this.sublabel, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 20)),
                Text(label, style: AppTextStyles.caption(color: AppColors.textSecondary).copyWith(fontSize: 11)),
                Text(sublabel, style: AppTextStyles.caption(color: color).copyWith(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MATCH INTENSITY SECTION
// ============================================================================

class ClubMatchIntensitySection extends StatelessWidget {
  const ClubMatchIntensitySection({super.key});

  static const _matches = [
    (label: 'M1', intensity: 0.88, result: 'W'),
    (label: 'M2', intensity: 0.72, result: 'W'),
    (label: 'M3', intensity: 0.95, result: 'L'),
    (label: 'M4', intensity: 0.80, result: 'W'),
    (label: 'M5', intensity: 0.68, result: 'D'),
    (label: 'M6', intensity: 0.91, result: 'W'),
    (label: 'M7', intensity: 0.85, result: 'W'),
    (label: 'M8', intensity: 0.77, result: 'D'),
    (label: 'M9', intensity: 0.93, result: 'W'),
    (label: 'M10', intensity: 0.89, result: 'W'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.speed, color: AppColors.primaryPurple, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Match Intensity', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
              const Spacer(),
              Text('Last 10 Matches', style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _matches.map((m) {
              final color = m.result == 'W'
                  ? AppColors.accentGreen
                  : m.result == 'D'
                      ? AppColors.warning
                      : AppColors.danger;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Container(
                        height: 72 * m.intensity,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.25),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          border: Border.all(color: color.withValues(alpha: 0.5)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Row(
            children: _matches.map((m) {
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      decoration: BoxDecoration(
                        color: (m.result == 'W'
                                ? AppColors.accentGreen
                                : m.result == 'D'
                                    ? AppColors.warning
                                    : AppColors.danger)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        m.result,
                        style: AppTextStyles.caption(
                          color: m.result == 'W'
                              ? AppColors.accentGreen
                              : m.result == 'D'
                                  ? AppColors.warning
                                  : AppColors.danger,
                        ).copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Text(m.label,
                        style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 8),
                        textAlign: TextAlign.center),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const _ResultLegend(color: AppColors.accentGreen, label: 'Win'),
              const SizedBox(width: 16),
              const _ResultLegend(color: AppColors.warning, label: 'Draw'),
              const SizedBox(width: 16),
              const _ResultLegend(color: AppColors.danger, label: 'Loss'),
              const Spacer(),
              Text('Height = Press Intensity', style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _ResultLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption(color: AppColors.textSecondary).copyWith(fontSize: 11)),
      ],
    );
  }
}

// ============================================================================
// FATIGUE OVERVIEW SECTION
// ============================================================================

class ClubFatigueOverviewSection extends StatelessWidget {
  const ClubFatigueOverviewSection({super.key});

  static const _fatigueTrend = [68.0, 71.0, 66.0, 74.0, 72.0, 78.0, 75.0, 68.0];
  static const _weekLabels = ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7', 'W8'];

  @override
  Widget build(BuildContext context) {
    final current = _fatigueTrend.last;
    final previous = _fatigueTrend[_fatigueTrend.length - 2];
    final delta = current - previous;
    final isWorse = delta > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.battery_charging_full_outlined, color: AppColors.warning, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Fatigue Trend', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isWorse ? AppColors.danger : AppColors.accentGreen).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isWorse ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isWorse ? AppColors.danger : AppColors.accentGreen, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      '${delta.abs().toStringAsFixed(1)}%',
                      style: AppTextStyles.caption(
                        color: isWorse ? AppColors.danger : AppColors.accentGreen,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(
            height: 80,
            child: CustomPaint(
              painter: _FatiguePainter(values: _fatigueTrend),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _weekLabels.map((w) =>
                Text(w, style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 9))).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _FatigueStat(label: 'Current', value: '${current.toInt()}%', color: _color(current))),
              Expanded(child: _FatigueStat(label: 'Peak', value: '${_fatigueTrend.reduce((a, b) => a > b ? a : b).toInt()}%', color: AppColors.danger)),
              Expanded(child: _FatigueStat(label: 'Min', value: '${_fatigueTrend.reduce((a, b) => a < b ? a : b).toInt()}%', color: AppColors.accentGreen)),
              Expanded(child: _FatigueStat(label: 'Avg', value: '${(_fatigueTrend.reduce((a, b) => a + b) / _fatigueTrend.length).toInt()}%', color: AppColors.accentCyan)),
            ],
          ),
        ],
      ),
    );
  }

  Color _color(double v) {
    if (v > 75) return AppColors.danger;
    if (v > 60) return AppColors.warning;
    return AppColors.accentGreen;
  }
}

class _FatigueStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _FatigueStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.body(color: color).copyWith(fontWeight: FontWeight.w800)),
        Text(label, style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 10)),
      ],
    );
  }
}

class _FatiguePainter extends CustomPainter {
  final List<double> values;
  const _FatiguePainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    const min = 55.0;
    const max = 85.0;
    const range = max - min;

    final fill = Paint()
      ..color = AppColors.warning.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = AppColors.warning
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - min) / range) * (size.height - 8);
      points.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fill);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, line);

    final dot = Paint()..color = AppColors.warning..style = PaintingStyle.fill;
    for (final p in points) {
      canvas.drawCircle(p, 3, dot);
    }
  }

  @override
  bool shouldRepaint(_FatiguePainter old) => old.values != values;
}
