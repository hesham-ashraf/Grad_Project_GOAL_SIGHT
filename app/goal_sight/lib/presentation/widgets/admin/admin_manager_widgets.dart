// ---------------------------------------------------------------------------
// GoalSight — Admin Manager Widgets
//
// Premium widgets for the Managers Management screen:
//   • ManagerStatsHeader   — summary stats bar
//   • EnhancedManagerCard  — rich card with status/upload/rating
//   • ManagerSearchBar     — styled search with filter chips
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/manager_model.dart';
import '../../../features/admin/data/admin_mock_data.dart';
import '../../../providers/repository_providers.dart';

// ============================================================================
// MANAGER STATS HEADER
// ============================================================================

class ManagerStatsHeader extends ConsumerWidget {
  const ManagerStatsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managers = ref.watch(adminManagersProvider);
    final active = managers.where((m) => m.isActive).length;
    final totalUploads = managers.fold<int>(0, (sum, m) => sum + m.uploadCount);
    final avgRating = managers.isEmpty
        ? 0.0
        : managers.map((m) => m.tacticalRating).reduce((a, b) => a + b) /
            managers.length;

    return Row(
      children: [
        Expanded(child: _StatPill(value: '$active/${managers.length}', label: 'Active', color: AppColors.accentGreen, icon: Icons.person_outline)),
        const SizedBox(width: 8),
        Expanded(child: _StatPill(value: '$totalUploads', label: 'Uploads', color: AppColors.accentCyan, icon: Icons.cloud_upload_outlined)),
        const SizedBox(width: 8),
        Expanded(child: _StatPill(value: avgRating.toStringAsFixed(1), label: 'Avg Rating', color: AppColors.warning, icon: Icons.star_outline)),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const _StatPill({required this.value, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
          Text(label, style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ============================================================================
// ENHANCED MANAGER CARD
// ============================================================================

class EnhancedManagerCard extends StatelessWidget {
  final ManagerModel manager;
  final VoidCallback? onTap;
  const EnhancedManagerCard({super.key, required this.manager, this.onTap});

  String get _lastActiveSince {
    final diff = DateTime.now().difference(manager.lastActive);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final perf = AdminMockData.managerPerformance[manager.id];

    return GestureDetector(
      onTap: onTap ?? () => context.push('/admin/managers/${manager.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: manager.isActive
                ? AppColors.outline
                : AppColors.danger.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            // Top row: avatar + info + status badge
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundImage: NetworkImage(manager.imageUrl),
                      backgroundColor: AppColors.surfaceRaised,
                    ),
                    if (manager.isActive)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surfaceElevated, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(manager.name,
                          style: AppTextStyles.body(color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(manager.email,
                          style: AppTextStyles.caption(color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text('Last active: $_lastActiveSince',
                          style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 10)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: manager.isActive
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: manager.isActive
                              ? AppColors.success.withValues(alpha: 0.5)
                              : AppColors.danger.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        manager.isActive ? 'ACTIVE' : 'DISABLED',
                        style: AppTextStyles.caption(
                          color: manager.isActive ? AppColors.success : AppColors.danger,
                        ).copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.warning, size: 12),
                        const SizedBox(width: 3),
                        Text(manager.tacticalRating.toStringAsFixed(1),
                            style: AppTextStyles.caption(color: AppColors.warning)
                                .copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Stats row
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _MiniStat(icon: Icons.cloud_upload_outlined, value: '${manager.uploadCount}', label: 'Uploads', color: AppColors.accentCyan),
                  _MiniDivider(),
                  _MiniStat(icon: Icons.sports_soccer, value: '${manager.matchesAnalyzed}', label: 'Matches', color: AppColors.primaryPurple),
                  _MiniDivider(),
                  _MiniStat(
                    icon: Icons.trending_up,
                    value: perf != null ? '${perf.uploadsThisMonth}' : '—',
                    label: 'This Month',
                    color: AppColors.accentGreen,
                  ),
                ],
              ),
            ),
            // Performance trend if available
            if (perf != null) ...[
              const SizedBox(height: 10),
              _MiniTrend(ratings: perf.weeklyRatings),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _MiniStat({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Column(
            children: [
              Text(value, style: AppTextStyles.caption(color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
              Text(label, style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: AppColors.outline);
  }
}

class _MiniTrend extends StatelessWidget {
  final List<double> ratings;
  const _MiniTrend({required this.ratings});

  @override
  Widget build(BuildContext context) {
    if (ratings.isEmpty) return const SizedBox.shrink();
    final max = ratings.reduce((a, b) => a > b ? a : b);
    final min = ratings.reduce((a, b) => a < b ? a : b);
    final isUp = ratings.last >= ratings.first;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 24,
            child: CustomPaint(
              painter: _TrendPainter(ratings: ratings, max: max, min: min, color: isUp ? AppColors.accentGreen : AppColors.danger),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(isUp ? Icons.trending_up : Icons.trending_down,
            color: isUp ? AppColors.accentGreen : AppColors.danger, size: 14),
        const SizedBox(width: 4),
        Text(
          isUp ? '+${(ratings.last - ratings.first).toStringAsFixed(1)}' : (ratings.last - ratings.first).toStringAsFixed(1),
          style: AppTextStyles.caption(color: isUp ? AppColors.accentGreen : AppColors.danger).copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> ratings;
  final double max;
  final double min;
  final Color color;
  const _TrendPainter({required this.ratings, required this.max, required this.min, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (ratings.length < 2) return;
    final range = (max - min).clamp(0.01, double.infinity);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < ratings.length; i++) {
      final x = (i / (ratings.length - 1)) * size.width;
      final y = size.height - ((ratings[i] - min) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.ratings != ratings;
}
