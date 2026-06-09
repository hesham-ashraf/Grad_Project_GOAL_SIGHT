import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/admin/data/admin_mock_data.dart';
import '../../../data/models/manager_model.dart';
import '../../../providers/repository_providers.dart';

class ManagerDetailsPage extends ConsumerStatefulWidget {
  const ManagerDetailsPage({super.key, required this.managerId});
  final String managerId;

  @override
  ConsumerState<ManagerDetailsPage> createState() => _ManagerDetailsPageState();
}

class _ManagerDetailsPageState extends ConsumerState<ManagerDetailsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _fades;
  late List<Animation<Offset>> _slides;

  bool _canUpload = true;
  bool _canEditPlayers = true;
  bool _canManageStaff = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
    _fades = List.generate(5, (i) {
      final start = (i * 0.15).clamp(0.0, 0.7);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _ctrl, curve: Interval(start, end, curve: Curves.easeOutCubic));
    });
    _slides = _fades.map((f) =>
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(f)).toList();
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
    final managers = ref.watch(adminManagersProvider);
    if (managers.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentCyan),
        ),
      );
    }
    final manager = managers.firstWhere(
      (m) => m.id == widget.managerId,
      orElse: () => managers.first,
    );
    final perf = AdminMockData.managerPerformance[manager.id];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(manager.name, style: AppTextStyles.title(color: Colors.white)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsSheet(context, manager),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        physics: const BouncingScrollPhysics(),
        children: [
          // 0 — Profile header
          _reveal(0, _ProfileHeader(manager: manager)),
          const SizedBox(height: 20),

          // 1 — Stats grid
          _reveal(1, Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Performance Overview', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'Uploads', value: '${manager.uploadCount}', icon: Icons.cloud_upload_outlined, color: AppColors.accentCyan)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Analyses', value: '${manager.matchesAnalyzed}', icon: Icons.analytics_outlined, color: AppColors.primaryPurple)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Rating', value: manager.tacticalRating.toStringAsFixed(1), icon: Icons.star_outline, color: AppColors.warning)),
                ],
              ),
              if (perf != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'This Week', value: '${perf.uploadsThisWeek}', icon: Icons.calendar_today_outlined, color: AppColors.accentGreen)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(label: 'This Month', value: '${perf.uploadsThisMonth}', icon: Icons.date_range_outlined, color: AppColors.accentCyan)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(label: 'Reports', value: '${perf.reportsGenerated}', icon: Icons.summarize_outlined, color: AppColors.primaryPurple)),
                  ],
                ),
              ],
            ],
          )),
          const SizedBox(height: 20),

          // 2 — Performance trend
          if (perf != null)
            _reveal(2, _PerformanceTrendCard(record: perf)),
          const SizedBox(height: 20),

          // 3 — Recent activity
          if (perf != null)
            _reveal(3, _ActivityHistoryCard(record: perf)),
          const SizedBox(height: 20),

          // 4 — Permissions
          _reveal(4, _PermissionsCard(
            canUpload: _canUpload,
            canEditPlayers: _canEditPlayers,
            canManageStaff: _canManageStaff,
            onUploadChanged: (v) => setState(() => _canUpload = v),
            onEditPlayersChanged: (v) => setState(() => _canEditPlayers = v),
            onManageStaffChanged: (v) => setState(() => _canManageStaff = v),
            isActive: manager.isActive,
            onToggleStatus: () => _showStatusSheet(context, manager),
          )),
        ],
      ),
    );
  }

  void _showOptionsSheet(BuildContext context, ManagerModel manager) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _OptionsSheet(manager: manager),
    );
  }

  void _showStatusSheet(BuildContext context, ManagerModel manager) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _StatusConfirmSheet(manager: manager),
    );
  }
}

// ─── Profile Header ──────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final ManagerModel manager;
  const _ProfileHeader({required this.manager});

  String get _lastActiveSince {
    final diff = DateTime.now().difference(manager.lastActive);
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withValues(alpha: 0.18),
            AppColors.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: NetworkImage(manager.imageUrl),
                backgroundColor: AppColors.surfaceRaised,
              ),
              if (manager.isActive)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
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
                Text(manager.name, style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 20)),
                const SizedBox(height: 3),
                Text(manager.email, style: AppTextStyles.caption(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: manager.isActive
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: manager.isActive
                              ? AppColors.success.withValues(alpha: 0.4)
                              : AppColors.danger.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        manager.isActive ? 'Active Account' : 'Suspended Account',
                        style: AppTextStyles.caption(
                          color: manager.isActive ? AppColors.success : AppColors.danger,
                        ).copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, color: AppColors.warning, size: 11),
                          const SizedBox(width: 4),
                          Text(_lastActiveSince, style: AppTextStyles.caption(color: AppColors.warning).copyWith(fontSize: 11)),
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
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 18)),
          Text(label, style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Performance Trend Card ───────────────────────────────────────────────────

class _PerformanceTrendCard extends StatelessWidget {
  final ManagerPerformanceRecord record;
  const _PerformanceTrendCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final ratings = record.weeklyRatings;
    final max = ratings.isNotEmpty ? ratings.reduce((a, b) => a > b ? a : b) : 10.0;
    final min = ratings.isNotEmpty ? ratings.reduce((a, b) => a < b ? a : b) : 0.0;
    final avg = ratings.isNotEmpty ? ratings.reduce((a, b) => a + b) / ratings.length : 0.0;
    final isImproving = ratings.length >= 2 && ratings.last >= ratings.first;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Performance Trend', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
              Row(
                children: [
                  Icon(
                    isImproving ? Icons.trending_up : Icons.trending_down,
                    color: isImproving ? AppColors.accentGreen : AppColors.danger,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isImproving ? 'Improving' : 'Declining',
                    style: AppTextStyles.caption(
                      color: isImproving ? AppColors.accentGreen : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 64,
            child: CustomPaint(
              painter: _RatingTrendPainter(
                ratings: ratings,
                max: max,
                min: min,
                color: isImproving ? AppColors.accentCyan : AppColors.danger,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 10),
          // X labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(ratings.length, (i) {
              return Text('W${i + 1}', style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(fontSize: 9));
            }),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _TrendStat(label: 'Peak', value: max.toStringAsFixed(1), color: AppColors.accentGreen)),
              Expanded(child: _TrendStat(label: 'Average', value: avg.toStringAsFixed(1), color: AppColors.accentCyan)),
              Expanded(child: _TrendStat(label: 'Lowest', value: min.toStringAsFixed(1), color: AppColors.danger)),
              Expanded(child: _TrendStat(label: 'Current', value: ratings.last.toStringAsFixed(1), color: AppColors.warning)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _TrendStat({required this.label, required this.value, required this.color});

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

class _RatingTrendPainter extends CustomPainter {
  final List<double> ratings;
  final double max;
  final double min;
  final Color color;

  const _RatingTrendPainter({required this.ratings, required this.max, required this.min, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (ratings.length < 2) return;
    final range = (max - min).clamp(0.01, double.infinity);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final points = <Offset>[];
    for (int i = 0; i < ratings.length; i++) {
      final x = (i / (ratings.length - 1)) * size.width;
      final y = size.height - ((ratings[i] - min) / range) * (size.height - 8) - 4;
      points.add(Offset(x, y));
    }

    // Fill area
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
    for (final p in points) {
      canvas.drawCircle(p, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_RatingTrendPainter old) => old.ratings != ratings;
}

// ─── Activity History Card ────────────────────────────────────────────────────

class _ActivityHistoryCard extends StatelessWidget {
  final ManagerPerformanceRecord record;
  const _ActivityHistoryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            children: record.recentActions.map((action) {
              return _ActivityRow(action: action);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String action;
  const _ActivityRow({required this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.history_outlined, color: AppColors.primaryPurple, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(action, style: AppTextStyles.caption(color: AppColors.textSecondary).copyWith(fontWeight: FontWeight.w600)),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
        ],
      ),
    );
  }
}

// ─── Permissions Card ─────────────────────────────────────────────────────────

class _PermissionsCard extends StatelessWidget {
  final bool canUpload;
  final bool canEditPlayers;
  final bool canManageStaff;
  final bool isActive;
  final ValueChanged<bool> onUploadChanged;
  final ValueChanged<bool> onEditPlayersChanged;
  final ValueChanged<bool> onManageStaffChanged;
  final VoidCallback onToggleStatus;

  const _PermissionsCard({
    required this.canUpload,
    required this.canEditPlayers,
    required this.canManageStaff,
    required this.isActive,
    required this.onUploadChanged,
    required this.onEditPlayersChanged,
    required this.onManageStaffChanged,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Permissions & Access', style: AppTextStyles.title(color: Colors.white).copyWith(fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            children: [
              _PermissionRow(
                icon: Icons.cloud_upload_outlined,
                title: 'Upload Matches',
                subtitle: 'Video & footage uploads',
                value: canUpload,
                onChanged: onUploadChanged,
                color: AppColors.accentCyan,
              ),
              const Divider(height: 1, color: AppColors.outline),
              _PermissionRow(
                icon: Icons.edit_outlined,
                title: 'Edit Player Data',
                subtitle: 'Squad & player records',
                value: canEditPlayers,
                onChanged: onEditPlayersChanged,
                color: AppColors.accentGreen,
              ),
              const Divider(height: 1, color: AppColors.outline),
              _PermissionRow(
                icon: Icons.group_outlined,
                title: 'Manage Sub-Staff',
                subtitle: 'Onboard assistant managers',
                value: canManageStaff,
                onChanged: onManageStaffChanged,
                color: AppColors.primaryPurple,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onToggleStatus,
            icon: Icon(
              isActive ? Icons.block_outlined : Icons.check_circle_outline,
              size: 18,
              color: isActive ? AppColors.danger : AppColors.success,
            ),
            label: Text(
              isActive ? 'Suspend Manager' : 'Reactivate Manager',
              style: TextStyle(color: isActive ? AppColors.danger : AppColors.success),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: (isActive ? AppColors.danger : AppColors.success).withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
            ),
          ),
        ),
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;
  const _PermissionRow({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body(color: Colors.white)),
                Text(subtitle, style: AppTextStyles.caption(color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accentCyan,
          ),
        ],
      ),
    );
  }
}

// ─── Options Sheet ────────────────────────────────────────────────────────────

class _OptionsSheet extends StatelessWidget {
  final ManagerModel manager;
  const _OptionsSheet({required this.manager});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.outline, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          _OptionTile(icon: Icons.share_outlined, label: 'Share Profile', color: AppColors.accentCyan, onTap: () => Navigator.pop(context)),
          _OptionTile(icon: Icons.download_outlined, label: 'Export Activity Report', color: AppColors.accentGreen, onTap: () => Navigator.pop(context)),
          _OptionTile(icon: Icons.email_outlined, label: 'Send Message', color: AppColors.primaryPurple, onTap: () => Navigator.pop(context)),
          _OptionTile(
            icon: manager.isActive ? Icons.block_outlined : Icons.check_circle_outline,
            label: manager.isActive ? 'Suspend Account' : 'Reactivate Account',
            color: manager.isActive ? AppColors.danger : AppColors.success,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OptionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label, style: AppTextStyles.body(color: Colors.white)),
      onTap: onTap,
    );
  }
}

// ─── Status Confirm Sheet ─────────────────────────────────────────────────────

class _StatusConfirmSheet extends StatelessWidget {
  final ManagerModel manager;
  const _StatusConfirmSheet({required this.manager});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.outline, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (manager.isActive ? AppColors.danger : AppColors.success).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              manager.isActive ? Icons.block_outlined : Icons.check_circle_outline,
              color: manager.isActive ? AppColors.danger : AppColors.success,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            manager.isActive ? 'Suspend ${manager.name}?' : 'Reactivate ${manager.name}?',
            style: AppTextStyles.title(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            manager.isActive
                ? 'The manager will lose access to all GoalSight features until reactivated.'
                : 'The manager will regain full access to their permitted features.',
            style: AppTextStyles.body(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.outline),
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: manager.isActive ? AppColors.danger : AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                  child: Text(
                    manager.isActive ? 'Suspend' : 'Reactivate',
                    style: AppTextStyles.button(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
