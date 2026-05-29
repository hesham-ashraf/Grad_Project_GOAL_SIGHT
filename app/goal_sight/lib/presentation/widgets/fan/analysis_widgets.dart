import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/match_analysis_model.dart';

// ─── Shared helpers ───────────────────────────────────────────────────────────

Color ratingColor(double r) {
  if (r >= 8.5) return AppColors.accentCyan;
  if (r >= 7.0) return AppColors.accentGreen;
  if (r >= 6.0) return AppColors.warning;
  return AppColors.danger;
}

// ─── Match Overview Card ──────────────────────────────────────────────────────

class AnalysisOverviewCard extends StatelessWidget {
  const AnalysisOverviewCard({super.key, required this.match});
  final MatchAnalysisModel match;

  @override
  Widget build(BuildContext context) {
    final home = match.homeAnalysis;
    final away = match.awayAnalysis;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.15),
            AppColors.surfaceElevated,
            AppColors.primaryPurple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      padding: EdgeInsets.all(context.rs(20, min: 16, max: 24)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TeamCol(name: match.homeTeam, rating: home.avgRating),
              Column(
                children: [
                  Text(match.score,
                      style: AppTextStyles.headline(color: AppColors.textPrimary)
                          .copyWith(fontSize: context.rs(36, min: 28, max: 42), letterSpacing: 2)),
                  const SizedBox(height: 4),
                  _StatusBadge(status: match.status),
                ],
              ),
              _TeamCol(name: match.awayTeam, rating: away.avgRating, rightAlign: true),
            ],
          ),
          SizedBox(height: context.rs(18, min: 12, max: 24)),
          if (match.summary.dominantTeam.isNotEmpty && match.summary.dominantTeam != 'None')
            _DominantBanner(team: match.summary.dominantTeam),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          // Possession bar
          _PossessionBar(
            homeTeam: match.homeTeam,
            awayTeam: match.awayTeam,
            homePct: home.possession,
            awayPct: away.possession,
          ),
          SizedBox(height: context.rs(16, min: 12, max: 20)),
          Container(
            padding: EdgeInsets.all(context.rs(14, min: 12, max: 16)),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.card,
            ),
            child: Text(
              match.summary.overallNarrative,
              style: AppTextStyles.body(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamCol extends StatelessWidget {
  const _TeamCol({required this.name, required this.rating, this.rightAlign = false});
  final String name;
  final double rating;
  final bool rightAlign;

  @override
  Widget build(BuildContext context) {
    final color = ratingColor(rating);
    return Expanded(
      child: Column(
        crossAxisAlignment: rightAlign ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(name,
              textAlign: rightAlign ? TextAlign.right : TextAlign.left,
              style: AppTextStyles.title(color: AppColors.textPrimary)
                  .copyWith(fontSize: context.rs(13, min: 11, max: 15)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: AppRadius.chip,
            ),
            child: Text(rating.toStringAsFixed(1),
                style: AppTextStyles.caption(color: color).copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: AppRadius.chip,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Text(status,
          style: AppTextStyles.caption(color: AppColors.success).copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

class _DominantBanner extends StatelessWidget {
  const _DominantBanner({required this.team});
  final String team;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.military_tech_rounded, color: AppColors.warning, size: 16),
        const SizedBox(width: 6),
        Text('Dominant: $team',
            style: AppTextStyles.caption(color: AppColors.warning).copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _PossessionBar extends StatelessWidget {
  const _PossessionBar({
    required this.homeTeam, required this.awayTeam,
    required this.homePct, required this.awayPct,
  });
  final String homeTeam;
  final String awayTeam;
  final int homePct;
  final int awayPct;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$homePct%', style: AppTextStyles.caption(color: AppColors.accentCyan).copyWith(fontWeight: FontWeight.w700)),
            Text('Possession', style: AppTextStyles.caption(color: AppColors.textMuted)),
            Text('$awayPct%', style: AppTextStyles.caption(color: AppColors.primaryPurple).copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Flexible(flex: homePct, child: Container(height: 8, color: AppColors.accentCyan)),
              Flexible(flex: awayPct, child: Container(height: 8, color: AppColors.primaryPurple)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Key Moments ─────────────────────────────────────────────────────────────

class KeyMomentsCard extends StatelessWidget {
  const KeyMomentsCard({super.key, required this.moments});
  final List<String> moments;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      padding: EdgeInsets.all(context.rs(18, min: 14, max: 22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AnalysisSectionHeader(title: 'Key Moments', icon: Icons.timeline_rounded, color: AppColors.warning),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          ...moments.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                ),
                Expanded(child: Text(e.value, style: AppTextStyles.body(color: AppColors.textSecondary))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─── MOTM / Worst Player Cards ────────────────────────────────────────────────

class KeyPerformerRow extends StatelessWidget {
  const KeyPerformerRow({super.key, required this.motm, required this.worst});
  final PlayerModel? motm;
  final PlayerModel? worst;

  @override
  Widget build(BuildContext context) {
    if (motm == null && worst == null) return const SizedBox.shrink();
    return Row(
      children: [
        if (motm != null) Expanded(child: _PerformerCard(player: motm!, isBest: true)),
        if (motm != null && worst != null) SizedBox(width: context.rs(12, min: 8, max: 16)),
        if (worst != null) Expanded(child: _PerformerCard(player: worst!, isBest: false)),
      ],
    );
  }
}

class _PerformerCard extends StatelessWidget {
  const _PerformerCard({required this.player, required this.isBest});
  final PlayerModel player;
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    final color = isBest ? AppColors.accentCyan : AppColors.danger;
    final icon = isBest ? Icons.star_rounded : Icons.trending_down_rounded;
    final title = isBest ? 'Man of the Match' : 'Worst Player';
    return Container(
      padding: EdgeInsets.all(context.rs(14, min: 12, max: 18)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.12), AppColors.surfaceElevated],
        ),
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: context.rs(14, min: 12, max: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    style: AppTextStyles.caption(color: color).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          SizedBox(height: context.rs(10, min: 8, max: 12)),
          Row(
            children: [
              Expanded(
                child: Text(player.name,
                    style: AppTextStyles.title(color: AppColors.textPrimary)
                        .copyWith(fontSize: context.rs(15, min: 13, max: 17)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppRadius.chip),
                child: Text(player.rating.toStringAsFixed(1),
                    style: AppTextStyles.button(color: color).copyWith(fontSize: 13)),
              ),
            ],
          ),
          SizedBox(height: context.rs(6, min: 4, max: 8)),
          Text(player.position,
              style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: context.rs(8, min: 6, max: 10)),
          Text(player.insight,
              style: AppTextStyles.caption(color: AppColors.textSecondary),
              maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Tactical Analysis Card ───────────────────────────────────────────────────

class TacticalAnalysisCard extends StatelessWidget {
  const TacticalAnalysisCard({super.key, required this.match});
  final MatchAnalysisModel match;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      padding: EdgeInsets.all(context.rs(18, min: 14, max: 22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AnalysisSectionHeader(title: 'Tactical Analysis', icon: Icons.analytics_rounded, color: AppColors.primaryPurple),
          SizedBox(height: context.rs(16, min: 12, max: 20)),
          _TeamTactics(team: match.homeAnalysis, color: AppColors.accentCyan),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          const Divider(color: AppColors.outlineSubtle),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          _TeamTactics(team: match.awayAnalysis, color: AppColors.primaryPurple),
        ],
      ),
    );
  }
}

class _TeamTactics extends StatelessWidget {
  const _TeamTactics({required this.team, required this.color});
  final TeamAnalysisModel team;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(team.teamName,
            style: AppTextStyles.body(color: color).copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: context.rs(10, min: 8, max: 12)),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            _TacticChip(label: team.style, icon: Icons.swap_horiz_rounded),
            _TacticChip(label: team.pressureStyle, icon: Icons.compress_rounded),
            _TacticChip(label: team.compactness, icon: Icons.grid_view_rounded),
            ...team.attackingZones.map((z) => _TacticChip(label: z, icon: Icons.location_on_rounded, highlight: true)),
          ],
        ),
      ],
    );
  }
}

class _TacticChip extends StatelessWidget {
  const _TacticChip({required this.label, required this.icon, this.highlight = false});
  final String label;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.accentGreen : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.chip,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.caption(color: color).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Player List Item ─────────────────────────────────────────────────────────

class AnalysisPlayerTile extends StatelessWidget {
  const AnalysisPlayerTile({super.key, required this.player, required this.index});
  final PlayerModel player;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = ratingColor(player.rating);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(14, min: 12, max: 18),
        vertical: context.rs(12, min: 10, max: 16),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.7),
        borderRadius: AppRadius.card,
        border: Border.all(
          color: (player.isMOTM || player.isWorst)
              ? (player.isMOTM ? AppColors.accentCyan : AppColors.danger).withValues(alpha: 0.3)
              : AppColors.outlineSubtle,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: context.rs(40, min: 34, max: 46),
            height: context.rs(40, min: 34, max: 46),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.05)]),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(player.name[0],
                  style: AppTextStyles.button(color: color).copyWith(fontSize: context.rs(15, min: 13, max: 17))),
            ),
          ),
          SizedBox(width: context.rs(12, min: 10, max: 14)),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(player.name,
                          style: AppTextStyles.body(color: AppColors.textPrimary)
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (player.isMOTM)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _PosTag(position: player.position, color: color),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(player.insight,
                          style: AppTextStyles.caption(color: AppColors.textMuted),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: context.rs(8, min: 6, max: 10)),
          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppRadius.chip),
                child: Text(player.rating.toStringAsFixed(1),
                    style: AppTextStyles.button(color: color).copyWith(fontSize: 13)),
              ),
              const SizedBox(height: 4),
              _FatigueBar(fatigue: player.fatigue),
            ],
          ),
        ],
      ),
    );
  }
}

class _PosTag extends StatelessWidget {
  const _PosTag({required this.position, required this.color});
  final String position;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(position,
          style: AppTextStyles.caption(color: color).copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _FatigueBar extends StatelessWidget {
  const _FatigueBar({required this.fatigue});
  final int fatigue;

  @override
  Widget build(BuildContext context) {
    final color = fatigue >= 80 ? AppColors.danger : fatigue >= 60 ? AppColors.warning : AppColors.accentGreen;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bolt_rounded, color: color, size: 11),
        const SizedBox(width: 3),
        Text('$fatigue%', style: AppTextStyles.caption(color: color).copyWith(fontSize: 10)),
      ],
    );
  }
}

// ─── Recommendations Card ─────────────────────────────────────────────────────

class RecommendationsCard extends StatelessWidget {
  const RecommendationsCard({super.key, required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.accentGreen.withValues(alpha: 0.08), AppColors.surfaceElevated],
        ),
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.2)),
      ),
      padding: EdgeInsets.all(context.rs(18, min: 14, max: 22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AnalysisSectionHeader(title: 'AI Recommendations', icon: Icons.lightbulb_rounded, color: AppColors.accentGreen),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          ...items.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22, height: 22,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text('${e.key + 1}',
                        style: AppTextStyles.caption(color: AppColors.accentGreen)
                            .copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
                Expanded(child: Text(e.value, style: AppTextStyles.body(color: AppColors.textSecondary))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class AnalysisSectionHeader extends StatelessWidget {
  const AnalysisSectionHeader({super.key, required this.title, required this.icon, required this.color});
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Icon(icon, color: color, size: context.rs(18, min: 16, max: 20)),
        const SizedBox(width: 8),
        Text(title,
            style: AppTextStyles.title(color: AppColors.textPrimary)
                .copyWith(fontSize: context.rs(16, min: 14, max: 18))),
      ],
    );
  }
}
