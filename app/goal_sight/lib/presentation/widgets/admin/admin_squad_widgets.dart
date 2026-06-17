// ---------------------------------------------------------------------------
// GoalSight — Admin Squad Widgets
//
// Premium widgets for the Squad Intelligence screen:
//   • SquadRiskRankingCard    — ordered risk overview per player
//   • SquadTacticalContribution — tactical role breakdown
//   • SquadFatigueHeatGrid   — colour-coded fatigue grid
//   • SquadPositionSummary   — player distribution by position
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/player_analysis_model.dart';
import '../../../providers/app_providers.dart';

// ============================================================================
// SQUAD CONDITION SUMMARY HEADER
// ============================================================================

class SquadConditionHeader extends ConsumerWidget {
  const SquadConditionHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squad = ref.watch(adminSquadProvider).maybeWhen(
          data: (s) => s,
          orElse: () => const <PlayerAnalysisModel>[],
        );
    if (squad.isEmpty) return const SizedBox.shrink();
    final avgFatigue = squad.map((p) => p.fatigueLevel).reduce((a, b) => a + b) / squad.length;
    final avgRisk = squad.map((p) => p.injuryRisk).reduce((a, b) => a + b) / squad.length;
    final avgWorkRate = squad.map((p) => p.workRate).reduce((a, b) => a + b) / squad.length;
    final avgImpact = squad.map((p) => p.tacticalImpact).reduce((a, b) => a + b) / squad.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withValues(alpha: 0.2),
            AppColors.accentCyan.withValues(alpha: 0.08),
            AppColors.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.groups_outlined, color: AppColors.primaryPurple, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Squad Intelligence', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('${squad.length} Players', style: AppTextStyles.caption(color: AppColors.accentCyan).copyWith(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _CondStat(label: 'Avg Fatigue', value: '${avgFatigue.toInt()}%', color: _fatigueColor(avgFatigue), icon: Icons.local_fire_department_outlined)),
              const SizedBox(width: 8),
              Expanded(child: _CondStat(label: 'Avg Risk', value: '${avgRisk.toInt()}%', color: _riskColor(avgRisk), icon: Icons.warning_amber_outlined)),
              const SizedBox(width: 8),
              Expanded(child: _CondStat(label: 'Work Rate', value: '${avgWorkRate.toInt()}%', color: AppColors.accentGreen, icon: Icons.bolt_outlined)),
              const SizedBox(width: 8),
              Expanded(child: _CondStat(label: 'Tact Impact', value: '${avgImpact.toInt()}%', color: AppColors.accentCyan, icon: Icons.radio_button_checked_outlined)),
            ],
          ),
        ],
      ),
    );
  }

  Color _fatigueColor(double v) {
    if (v > 75) return AppColors.danger;
    if (v > 55) return AppColors.warning;
    return AppColors.accentGreen;
  }

  Color _riskColor(double v) {
    if (v > 50) return AppColors.danger;
    if (v > 30) return AppColors.warning;
    return AppColors.accentGreen;
  }
}

class _CondStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _CondStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.caption(color: Colors.white).copyWith(fontWeight: FontWeight.w800, fontSize: 13)),
          Text(label, style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ============================================================================
// RISK RANKING SECTION
// ============================================================================

class SquadRiskRankingSection extends ConsumerWidget {
  const SquadRiskRankingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squad = ref.watch(adminSquadProvider).maybeWhen(
          data: (s) => List<PlayerAnalysisModel>.from(s)
            ..sort((a, b) => b.injuryRisk.compareTo(a.injuryRisk)),
          orElse: () => const <PlayerAnalysisModel>[],
        );
    if (squad.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
            const SizedBox(width: 8),
            Text('Risk Rankings', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
        ...squad.asMap().entries.map((e) => _RiskRow(rank: e.key + 1, player: e.value)),
      ],
    );
  }
}

class _RiskRow extends StatelessWidget {
  final int rank;
  final PlayerAnalysisModel player;
  const _RiskRow({required this.rank, required this.player});

  Color get _riskColor {
    if (player.injuryRisk >= 60) return AppColors.danger;
    if (player.injuryRisk >= 35) return AppColors.warning;
    return AppColors.accentGreen;
  }

  Color get _fatigueColor {
    if (player.fatigueLevel >= 80) return AppColors.danger;
    if (player.fatigueLevel >= 60) return AppColors.warning;
    return AppColors.accentGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: player.injuryRisk >= 60
            ? AppColors.danger.withValues(alpha: 0.05)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: player.injuryRisk >= 60
              ? AppColors.danger.withValues(alpha: 0.25)
              : AppColors.outline,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _rankColor(rank).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: AppTextStyles.caption(color: _rankColor(rank)).copyWith(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(player.name,
                          style: AppTextStyles.body(color: Colors.white).copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(player.position,
                          style: AppTextStyles.caption(color: AppColors.accentCyan).copyWith(fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Risk', style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 10)),
                              Text('${player.injuryRisk.toInt()}%', style: AppTextStyles.caption(color: _riskColor).copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: player.injuryRisk / 100,
                              backgroundColor: AppColors.surfaceRaised,
                              valueColor: AlwaysStoppedAnimation<Color>(_riskColor),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Fatigue', style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 10)),
                              Text('${player.fatigueLevel.toInt()}%', style: AppTextStyles.caption(color: _fatigueColor).copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: player.fatigueLevel / 100,
                              backgroundColor: AppColors.surfaceRaised,
                              valueColor: AlwaysStoppedAnimation<Color>(_fatigueColor),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _rankColor(int r) {
    if (r == 1) return AppColors.danger;
    if (r == 2) return AppColors.warning;
    if (r <= 3) return AppColors.warning;
    return AppColors.textMuted;
  }
}

// ============================================================================
// TACTICAL CONTRIBUTION SECTION
// ============================================================================

class SquadTacticalContributionSection extends ConsumerWidget {
  const SquadTacticalContributionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squad = ref.watch(adminSquadProvider).maybeWhen(
          data: (s) => List<PlayerAnalysisModel>.from(s)
            ..sort((a, b) => b.tacticalImpact.compareTo(a.tacticalImpact)),
          orElse: () => const <PlayerAnalysisModel>[],
        );
    if (squad.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.radio_button_checked_outlined, color: AppColors.accentCyan, size: 18),
            const SizedBox(width: 8),
            Text('Tactical Contribution', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: squad.map((p) => _ContribRow(player: p)).toList(),
          ),
        ),
      ],
    );
  }
}

class _ContribRow extends StatelessWidget {
  final PlayerAnalysisModel player;
  const _ContribRow({required this.player});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            player.position,
            style: AppTextStyles.caption(color: AppColors.accentCyan).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              player.name,
              style: AppTextStyles.caption(color: Colors.white).copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: player.tacticalImpact / 100,
                backgroundColor: AppColors.surfaceRaised,
                valueColor: AlwaysStoppedAnimation<Color>(
                  player.tacticalImpact >= 90
                      ? AppColors.accentGreen
                      : player.tacticalImpact >= 80
                          ? AppColors.accentCyan
                          : AppColors.primaryPurple,
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${player.tacticalImpact.toInt()}',
            style: AppTextStyles.caption(color: AppColors.accentCyan).copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SQUAD STRENGTHS HEAT GRID
// ============================================================================

class SquadStrengthsGrid extends ConsumerWidget {
  const SquadStrengthsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squad = ref.watch(adminSquadProvider).maybeWhen(
          data: (s) => s,
          orElse: () => const <PlayerAnalysisModel>[],
        );
    if (squad.isEmpty) return const SizedBox.shrink();
    // Aggregate all strengths
    final Map<String, int> strengthCounts = {};
    for (final player in squad) {
      for (final s in player.keyStrengths) {
        strengthCounts[s] = (strengthCounts[s] ?? 0) + 1;
      }
    }
    final sorted = strengthCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.workspace_premium_outlined, color: AppColors.accentGreen, size: 18),
            const SizedBox(width: 8),
            Text('Squad Strengths', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sorted.map((e) {
            final intensity = (e.value / squad.length).clamp(0.1, 1.0);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withValues(alpha: intensity * 0.2),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.accentGreen.withValues(alpha: intensity * 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(e.key, style: AppTextStyles.caption(color: AppColors.accentGreen).copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text('${e.value}', style: AppTextStyles.caption(color: AppColors.accentGreen).copyWith(fontSize: 9)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ============================================================================
// PLAYER ANALYTICS CARD (enhanced version of existing widget)
// ============================================================================

class EnhancedPlayerAnalyticsCard extends StatelessWidget {
  final PlayerAnalysisModel player;
  const EnhancedPlayerAnalyticsCard({super.key, required this.player});

  Color get _ratingColor {
    if (player.overallRating >= 9.0) return AppColors.accentGreen;
    if (player.overallRating >= 8.0) return AppColors.accentCyan;
    if (player.overallRating >= 7.0) return AppColors.warning;
    return AppColors.danger;
  }

  Color get _fatigueColor {
    if (player.fatigueLevel >= 80) return AppColors.danger;
    if (player.fatigueLevel >= 60) return AppColors.warning;
    return AppColors.accentGreen;
  }

  Color get _riskColor {
    if (player.injuryRisk >= 60) return AppColors.danger;
    if (player.injuryRisk >= 35) return AppColors.warning;
    return AppColors.accentGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: player.injuryRisk >= 60
              ? AppColors.danger.withValues(alpha: 0.3)
              : AppColors.outline,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(player.imageUrl),
                backgroundColor: AppColors.surfaceRaised,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.name,
                        style: AppTextStyles.body(color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentCyan.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(player.position,
                              style: AppTextStyles.caption(color: AppColors.accentCyan).copyWith(fontSize: 10)),
                        ),
                        if (player.injuryRisk >= 60) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 10),
                                const SizedBox(width: 3),
                                Text('HIGH RISK', style: AppTextStyles.caption(color: AppColors.danger).copyWith(fontSize: 9, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _ratingColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: _ratingColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(player.overallRating.toStringAsFixed(1),
                        style: AppTextStyles.title(color: _ratingColor).copyWith(fontSize: 18)),
                    Text('Rating', style: AppTextStyles.caption(color: _ratingColor).copyWith(fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniBar(label: 'Fatigue', value: player.fatigueLevel / 100, color: _fatigueColor, text: '${player.fatigueLevel.toInt()}%')),
              const SizedBox(width: 10),
              Expanded(child: _MiniBar(label: 'Risk', value: player.injuryRisk / 100, color: _riskColor, text: '${player.injuryRisk.toInt()}%')),
              const SizedBox(width: 10),
              Expanded(child: _MiniBar(label: 'Impact', value: player.tacticalImpact / 100, color: AppColors.accentCyan, text: '${player.tacticalImpact.toInt()}%')),
            ],
          ),
          if (player.keyStrengths.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: player.keyStrengths.take(3).map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.2)),
                ),
                child: Text(s, style: AppTextStyles.caption(color: AppColors.accentGreen).copyWith(fontSize: 10)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String text;
  const _MiniBar({required this.label, required this.value, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 10)),
            Text(text, style: AppTextStyles.caption(color: color).copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceRaised,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
