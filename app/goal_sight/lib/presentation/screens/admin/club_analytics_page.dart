import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/admin/data/admin_mock_data.dart';
import '../../widgets/admin/tactical_insight_widget.dart';
import '../../widgets/admin/admin_analytics_widgets.dart';

class ClubAnalyticsPage extends StatefulWidget {
  const ClubAnalyticsPage({super.key});

  @override
  State<ClubAnalyticsPage> createState() => _ClubAnalyticsPageState();
}

class _ClubAnalyticsPageState extends State<ClubAnalyticsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _fades;
  late List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
    _fades = List.generate(6, (i) {
      final start = (i * 0.12).clamp(0.0, 0.75);
      final end = (start + 0.30).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _ctrl, curve: Interval(start, end, curve: Curves.easeOutCubic));
    });
    _slides = _fades.map((f) =>
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(f)).toList();
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
    final insights = AdminMockData.tacticalInsights;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.bar_chart, color: AppColors.accentGreen, size: 20),
            const SizedBox(width: 8),
            Text('Club Intelligence', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 18)),
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
          // 0 — Tactical Identity
          _reveal(0, _TacticalIdentityCard()),
          const SizedBox(height: 20),

          // 1 — Season Stats
          _reveal(1, const ClubSeasonStatsSection()),
          const SizedBox(height: 20),

          // 2 — Tactical Evolution
          _reveal(2, const ClubTacticalEvolutionSection()),
          const SizedBox(height: 20),

          // 3 — Match Intensity
          _reveal(3, const ClubMatchIntensitySection()),
          const SizedBox(height: 20),

          // 4 — Fatigue Overview
          _reveal(4, const ClubFatigueOverviewSection()),
          const SizedBox(height: 20),

          // 5 — Tactical Insights
          _reveal(5, Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppColors.accentCyan, size: 18),
                  const SizedBox(width: 8),
                  Text('AI Tactical Insights', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              ...insights.map((insight) => TacticalInsightWidget(insight: insight)),
            ],
          )),
        ],
      ),
    );
  }
}

// ─── Tactical Identity Card ────────────────────────────────────────────────

class _TacticalIdentityCard extends StatelessWidget {
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
            AppColors.accentCyan.withValues(alpha: 0.1),
            AppColors.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.3)),
        boxShadow: AppShadows.cardGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fingerprint, color: AppColors.primaryPurple, size: 18),
              const SizedBox(width: 8),
              Text('Tactical Identity', style: AppTextStyles.caption(color: AppColors.primaryPurple).copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('Season 2024–25', style: AppTextStyles.caption(color: AppColors.accentGreen).copyWith(fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'High-Intensity Possession Football',
            style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            'The club primarily relies on a high defensive line with aggressive counter-pressing. Most attacks are initiated from wide areas with overlapping fullbacks creating numerical advantages.',
            style: AppTextStyles.body(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag('Gegenpressing', AppColors.primaryPurple),
              _Tag('Wing Play', AppColors.accentCyan),
              _Tag('High Line', AppColors.warning),
              _Tag('4-3-3', AppColors.accentGreen),
              _Tag('Positional Play', AppColors.accentCyan),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _IdentityStat(label: 'Avg Possession', value: '62%', color: AppColors.accentCyan)),
              Expanded(child: _IdentityStat(label: 'Press Success', value: '84%', color: AppColors.primaryPurple)),
              Expanded(child: _IdentityStat(label: 'High Line', value: '38m', color: AppColors.warning)),
              Expanded(child: _IdentityStat(label: 'Transitions', value: '18/G', color: AppColors.accentGreen)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: AppTextStyles.caption(color: color)),
    );
  }
}

class _IdentityStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _IdentityStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.title(color: color).copyWith(fontSize: 16)),
        Text(label, style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 9), textAlign: TextAlign.center),
      ],
    );
  }
}
