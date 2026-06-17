import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_providers.dart';

class PlayerIntelligencePage extends ConsumerWidget {
  const PlayerIntelligencePage({super.key, required this.playerId});
  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squad = ref.watch(adminSquadProvider).maybeWhen(
      data: (s) => s,
      orElse: () => null,
    );
    if (squad == null || squad.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accentCyan)),
      );
    }
    final player = squad.firstWhere((p) => p.id == playerId, orElse: () => squad.first);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Player Intelligence'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryPurple, width: 2),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(player.imageUrl),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.name,
                        style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 24)),
                    Text(player.position,
                        style: AppTextStyles.caption(color: AppColors.accentCyan)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.accentCyan, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          player.overallRating.toStringAsFixed(1),
                          style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Risk & Condition Analysis',
              style: AppTextStyles.title(color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildRiskCard('Fatigue', player.fatigueLevel, AppColors.warning)),
              const SizedBox(width: 12),
              Expanded(child: _buildRiskCard('Injury Risk', player.injuryRisk, AppColors.danger)),
            ],
          ),
          const SizedBox(height: 32),
          Text('Tactical Profile',
              style: AppTextStyles.title(color: Colors.white)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressRow('Work Rate', player.workRate, AppColors.primaryBlue),
                const SizedBox(height: 16),
                _buildProgressRow('Tactical Impact', player.tacticalImpact, AppColors.accentGreen),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Key Attributes',
              style: AppTextStyles.title(color: Colors.white)),
          const SizedBox(height: 12),
          _buildAttributeSection('Strengths', player.keyStrengths, AppColors.success),
          const SizedBox(height: 16),
          _buildAttributeSection('Weaknesses', player.weaknesses, AppColors.danger),
        ],
      ),
    );
  }

  Widget _buildRiskCard(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.caption(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: value / 100,
                  strokeWidth: 6,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '${value.toInt()}%',
                style: AppTextStyles.body(color: Colors.white).copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.body(color: Colors.white)),
            Text('${value.toInt()}/100', style: AppTextStyles.caption(color: color)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildAttributeSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.caption(color: color)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(item, style: TextStyle(color: color, fontSize: 12)),
            );
          }).toList(),
        ),
      ],
    );
  }
}
