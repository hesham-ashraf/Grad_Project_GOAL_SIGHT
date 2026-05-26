import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/player_analysis_model.dart';
import 'package:go_router/go_router.dart';

class PlayerAnalyticsCard extends StatelessWidget {
  final PlayerAnalysisModel player;

  const PlayerAnalyticsCard({super.key, required this.player});

  Color _getRiskColor(double risk) {
    if (risk < 30) return AppColors.success;
    if (risk < 70) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/admin/player/${player.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineSubtle),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(player.imageUrl),
                        backgroundColor: AppColors.surfaceRaised,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            player.position,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.accentCyan, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              player.overallRating.toStringAsFixed(1),
                              style: AppTextStyles.body(color: Colors.white).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildCircularIndicator(
                    value: player.fatigueLevel,
                    label: 'Fatigue',
                    color: _getRiskColor(player.fatigueLevel),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Impact', player.tacticalImpact, AppColors.accentGreen),
                  _buildStatColumn('Work Rate', player.workRate, AppColors.primaryBlue),
                  _buildStatColumn('Risk', player.injuryRisk, _getRiskColor(player.injuryRisk)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularIndicator({required double value, required String label, required Color color}) {
    return Column(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 4,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Text(
                  '${value.toInt()}%',
                  style: AppTextStyles.caption(color: Colors.white).copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _buildStatColumn(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          value.toInt().toString(),
          style: AppTextStyles.title(color: color).copyWith(fontSize: 16),
        ),
        Text(label, style: AppTextStyles.caption()),
      ],
    );
  }
}
