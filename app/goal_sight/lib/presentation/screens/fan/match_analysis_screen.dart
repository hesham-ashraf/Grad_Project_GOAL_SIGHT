import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/match_analysis_model.dart';
import '../../widgets/fan/analysis_widgets.dart';
import '../../widgets/fan/match_tactical_widgets.dart';

class MatchAnalysisScreen extends StatefulWidget {
  const MatchAnalysisScreen({super.key, required this.match});
  final MatchAnalysisModel match;

  @override
  State<MatchAnalysisScreen> createState() => _MatchAnalysisScreenState();
}

class _MatchAnalysisScreenState extends State<MatchAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  static const int _sectionCount = 18;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..forward();

    _fades = List.generate(_sectionCount, (i) {
      final start = (i * 0.07).clamp(0.0, 0.85);
      final end = (start + 0.22).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic));
    });

    _slides = _fades
        .map((f) =>
            Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
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
    final match = widget.match;
    final h = context.rs(18, min: 14, max: 22);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, match),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(h, 0, h, context.rs(44, min: 32, max: 60)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight + 12),

            // ── 0. Score Overview ────────────────────────────────────────
            _section(0, AnalysisOverviewCard(match: match)),
            SizedBox(height: h),

            // ── 1. Tactical Summary ──────────────────────────────────────
            _section(1, TacticalSummaryCard(match: match)),
            SizedBox(height: h),

            // ── 2. Key Moments ───────────────────────────────────────────
            if (match.summary.keyMoments.isNotEmpty) ...[
              _section(2, KeyMomentsCard(moments: match.summary.keyMoments)),
              SizedBox(height: h),
            ],

            // ── 3. Team Comparison ───────────────────────────────────────
            _section(3, TeamComparisonCard(match: match)),
            SizedBox(height: h),

            // ── 4. Possession Charts ─────────────────────────────────────
            _section(4, PossessionChartCard(match: match)),
            SizedBox(height: h),

            // ── 5. Momentum Graph ────────────────────────────────────────
            _section(5, MomentumGraphCard(match: match)),
            SizedBox(height: h),

            // ── 6. Key Performers ────────────────────────────────────────
            if (match.motm != null || match.worstPlayer != null) ...[
              _section(6,
                  KeyPerformerRow(motm: match.motm, worst: match.worstPlayer)),
              SizedBox(height: h),
            ],

            // ── 7. Tactical Strengths ────────────────────────────────────
            _section(7, TacticalStrengthsCard(match: match)),
            SizedBox(height: h),

            // ── 8. Tactical Weaknesses ───────────────────────────────────
            _section(8, TacticalWeaknessesCard(match: match)),
            SizedBox(height: h),

            // ── 9. Attack Zones ──────────────────────────────────────────
            _section(9, AttackZonesCard(match: match)),
            SizedBox(height: h),

            // ── 10. Formation Visualization ──────────────────────────────
            _section(10, FormationCard(match: match)),
            SizedBox(height: h),

            // ── 11. Heatmaps ─────────────────────────────────────────────
            _section(11, HeatmapCard(match: match)),
            SizedBox(height: h),

            // ── 12. Bird-Eye View ────────────────────────────────────────
            _section(12, BirdEyeCard(match: match)),
            SizedBox(height: h),

            // ── 13. Player Impact ────────────────────────────────────────
            _section(13, PlayerImpactCard(players: match.players)),
            SizedBox(height: h),

            // ── 14. Fatigue Analysis ─────────────────────────────────────
            _section(14, FatigueAnalysisCard(players: match.players)),
            SizedBox(height: h),

            // ── 15. Risk Analysis ────────────────────────────────────────
            _section(15,
                RiskAnalysisCard(players: match.players, match: match)),
            SizedBox(height: h),

            // ── 16. Tactical Analysis (existing) ────────────────────────
            _section(16, TacticalAnalysisCard(match: match)),
            SizedBox(height: h),

            // ── 17. AI Insights ──────────────────────────────────────────
            _section(17, AIInsightsCard(match: match)),
            SizedBox(height: h),

            // ── Coach Recommendations ────────────────────────────────────
            if (match.recommendations.isNotEmpty)
              CoachRecommendationsCard(recommendations: match.recommendations),
            SizedBox(height: h),

            // ── Player Ratings ───────────────────────────────────────────
            _PlayerListSection(players: match.players),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, MatchAnalysisModel match) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineSubtle),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 18),
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${match.homeTeam} vs ${match.awayTeam}',
              style: AppTextStyles.body(color: AppColors.textPrimary)
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(match.date,
              style: AppTextStyles.caption(color: AppColors.textMuted)),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      match.intensity >= 80
                          ? Icons.local_fire_department_rounded
                          : Icons.sports_soccer_rounded,
                      color: match.intensity >= 80
                          ? AppColors.danger
                          : AppColors.accentCyan,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${match.intensity}',
                      style: AppTextStyles.caption(
                        color: match.intensity >= 80
                            ? AppColors.danger
                            : AppColors.accentCyan,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Player List Section ──────────────────────────────────────────────────────

class _PlayerListSection extends StatelessWidget {
  const _PlayerListSection({required this.players});
  final List<PlayerModel> players;

  @override
  Widget build(BuildContext context) {
    final sorted = [...players]..sort((a, b) => b.rating.compareTo(a.rating));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            const Icon(Icons.people_alt_rounded,
                color: AppColors.primaryBlue, size: 18),
            const SizedBox(width: 8),
            Text('Player Ratings',
                style: AppTextStyles.title(color: AppColors.textPrimary)
                    .copyWith(
                        fontSize: context.rs(16, min: 14, max: 18))),
            const Spacer(),
            Text('${players.length} players',
                style: AppTextStyles.caption(color: AppColors.textMuted)),
          ],
        ),
        SizedBox(height: context.rs(14, min: 10, max: 18)),
        ...sorted
            .asMap()
            .entries
            .map((e) =>
                AnalysisPlayerTile(player: e.value, index: e.key)),
      ],
    );
  }
}

