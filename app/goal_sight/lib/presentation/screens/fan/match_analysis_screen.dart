import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/match_analysis_model.dart';
import '../../widgets/fan/analysis_widgets.dart';

class MatchAnalysisScreen extends StatefulWidget {
  const MatchAnalysisScreen({super.key, required this.match});
  final MatchAnalysisModel match;

  @override
  State<MatchAnalysisScreen> createState() => _MatchAnalysisScreenState();
}

class _MatchAnalysisScreenState extends State<MatchAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  Animation<double> _fade(double start, double end) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );

  Animation<Offset> _slide(Animation<double> fade) =>
      Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(fade);

  late final Animation<double> _f0, _f1, _f2, _f3, _f4;
  late final Animation<Offset> _s0, _s1, _s2, _s3, _s4;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
    _f0 = _fade(0.0, 0.3); _s0 = _slide(_f0);
    _f1 = _fade(0.15, 0.45); _s1 = _slide(_f1);
    _f2 = _fade(0.3, 0.6); _s2 = _slide(_f2);
    _f3 = _fade(0.5, 0.8); _s3 = _slide(_f3);
    _f4 = _fade(0.7, 1.0); _s4 = _slide(_f4);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _animated(Animation<double> f, Animation<Offset> s, Widget child) =>
      FadeTransition(opacity: f, child: SlideTransition(position: s, child: child));

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final h = context.rs(20, min: 16, max: 24);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, match),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(h, 0, h, context.rs(40, min: 32, max: 56)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 12),

            // ── Overview ──────────────────────────────────────────────────
            _animated(_f0, _s0, AnalysisOverviewCard(match: match)),
            SizedBox(height: h),

            // ── Key Moments ───────────────────────────────────────────────
            if (match.summary.keyMoments.isNotEmpty) ...[
              _animated(_f1, _s1, KeyMomentsCard(moments: match.summary.keyMoments)),
              SizedBox(height: h),
            ],

            // ── Key Performers ────────────────────────────────────────────
            if (match.motm != null || match.worstPlayer != null) ...[
              _animated(_f1, _s1, KeyPerformerRow(motm: match.motm, worst: match.worstPlayer)),
              SizedBox(height: h),
            ],

            // ── Tactical Analysis ─────────────────────────────────────────
            _animated(_f2, _s2, TacticalAnalysisCard(match: match)),
            SizedBox(height: h),

            // ── Player List ───────────────────────────────────────────────
            _animated(_f3, _s3, _PlayerListSection(players: match.players)),
            SizedBox(height: h),

            // ── Recommendations ───────────────────────────────────────────
            if (match.recommendations.isNotEmpty)
              _animated(_f4, _s4, RecommendationsCard(items: match.recommendations)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, MatchAnalysisModel match) {
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
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
                onPressed: () => Navigator.of(context).pop(),
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
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(match.date, style: AppTextStyles.caption(color: AppColors.textMuted)),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      match.intensity >= 80 ? Icons.local_fire_department_rounded : Icons.sports_soccer_rounded,
                      color: match.intensity >= 80 ? AppColors.danger : AppColors.accentCyan,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text('${match.intensity}',
                        style: AppTextStyles.caption(
                          color: match.intensity >= 80 ? AppColors.danger : AppColors.accentCyan,
                        ).copyWith(fontWeight: FontWeight.w700)),
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
            Container(width: 3, height: 20, decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            const Icon(Icons.people_alt_rounded, color: AppColors.primaryBlue, size: 18),
            const SizedBox(width: 8),
            Text('Player Ratings',
                style: AppTextStyles.title(color: AppColors.textPrimary)
                    .copyWith(fontSize: context.rs(16, min: 14, max: 18))),
            const Spacer(),
            Text('${players.length} players',
                style: AppTextStyles.caption(color: AppColors.textMuted)),
          ],
        ),
        SizedBox(height: context.rs(14, min: 10, max: 18)),
        ...sorted.asMap().entries.map((e) => AnalysisPlayerTile(player: e.value, index: e.key)),
      ],
    );
  }
}
