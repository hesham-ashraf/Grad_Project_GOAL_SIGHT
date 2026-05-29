import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/upload_job_model.dart';

// ─── Status Badge ─────────────────────────────────────────────────────────────

class UploadStatusBadge extends StatelessWidget {
  const UploadStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final UploadStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.chip,
        color: status.color.withValues(alpha: 0.12),
        border: Border.all(
          color: status.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: compact ? 11 : 12,
            color: status.color,
          ),
          SizedBox(width: compact ? 4 : 5),
          Text(
            status.label,
            style: AppTextStyles.caption(color: status.color).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upload History Card ──────────────────────────────────────────────────────

class UploadHistoryCard extends StatelessWidget {
  const UploadHistoryCard({
    super.key,
    required this.job,
    required this.onTap,
    this.onRetry,
  });

  final UploadJobModel job;
  final VoidCallback onTap;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          color: AppColors.surfaceElevated,
          border: Border.all(
            color: job.status == UploadStatus.failed
                ? AppColors.danger.withValues(alpha: 0.25)
                : job.status == UploadStatus.processing
                    ? AppColors.primaryPurple.withValues(alpha: 0.25)
                    : AppColors.outlineSubtle,
            width: 1,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status icon
                  _StatusIcon(status: job.status),
                  const SizedBox(width: 12),
                  // Match info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${job.homeTeam} vs ${job.awayTeam}',
                          style: AppTextStyles.body(
                                  color: AppColors.textPrimary)
                              .copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.emoji_events_rounded,
                                size: 11,
                                color: AppColors.accentCyan),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                job.competition,
                                style: AppTextStyles.caption(
                                    color: AppColors.accentCyan),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.calendar_today_rounded,
                                size: 10, color: AppColors.textMuted),
                            const SizedBox(width: 3),
                            Text(
                              _formatDate(job.matchDate),
                              style: AppTextStyles.caption(
                                  color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  UploadStatusBadge(status: job.status, compact: true),
                ],
              ),
            ),

            // ── Status-specific content ──
            if (job.status == UploadStatus.completed)
              _CompletedContent(job: job)
            else if (job.status == UploadStatus.processing)
              _ProcessingContent(job: job)
            else if (job.status == UploadStatus.failed)
              _FailedContent(job: job, onRetry: onRetry),

            // ── Footer ──
            _CardFooter(job: job),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final UploadStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: status.color.withValues(alpha: 0.12),
      ),
      child: Icon(status.icon, size: 20, color: status.color),
    );
  }
}

class _CompletedContent extends StatelessWidget {
  const _CompletedContent({required this.job});
  final UploadJobModel job;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1, color: AppColors.outlineSubtle),
          const SizedBox(height: 10),
          // Score + intensity row
          Row(
            children: [
              if (job.matchScore != null) ...[
                _DataChip(
                  icon: Icons.scoreboard_rounded,
                  label: job.matchScore!,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 8),
              ],
              if (job.intensityScore != null) ...[
                _DataChip(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Intensity ${job.intensityScore}',
                  color: job.intensityScore! >= 80
                      ? AppColors.danger
                      : job.intensityScore! >= 60
                          ? AppColors.warning
                          : AppColors.accentGreen,
                ),
              ],
            ],
          ),
          if (job.tacticalSummary != null) ...[
            const SizedBox(height: 8),
            Text(
              job.tacticalSummary!,
              style: AppTextStyles.caption(color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.analytics_rounded, size: 15),
              label: const Text('View Full Analysis'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentCyan,
                side: BorderSide(
                    color: AppColors.accentCyan.withValues(alpha: 0.4),
                    width: 1),
                padding:
                    const EdgeInsets.symmetric(vertical: 9),
                textStyle: AppTextStyles.caption()
                    .copyWith(fontWeight: FontWeight.w700),
                shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.button),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingContent extends StatefulWidget {
  const _ProcessingContent({required this.job});
  final UploadJobModel job;

  @override
  State<_ProcessingContent> createState() => _ProcessingContentState();
}

class _ProcessingContentState extends State<_ProcessingContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.job.processingStage;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1, color: AppColors.outlineSubtle),
          const SizedBox(height: 10),
          if (stage != null) ...[
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stage.color.withValues(alpha: 0.12),
                  ),
                  child: Icon(stage.icon, size: 12, color: stage.color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stage.label,
                    style: AppTextStyles.caption(color: stage.color)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // Progress bar
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: widget.job.progress,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceRaised,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryPurple,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Processing…',
                style:
                    AppTextStyles.caption(color: AppColors.textMuted),
              ),
              Text(
                '${(widget.job.progress * 100).round()}%',
                style: AppTextStyles.caption(
                        color: AppColors.primaryPurple)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FailedContent extends StatelessWidget {
  const _FailedContent({required this.job, this.onRetry});
  final UploadJobModel job;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1, color: AppColors.outlineSubtle),
          const SizedBox(height: 10),
          if (job.failureReason != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: AppRadius.card,
                color: AppColors.danger.withValues(alpha: 0.06),
                border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 14, color: AppColors.danger),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job.failureReason!,
                      style: AppTextStyles.caption(
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (onRetry != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Retry Upload'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.4),
                      width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  textStyle: AppTextStyles.caption()
                      .copyWith(fontWeight: FontWeight.w700),
                  shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.button),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.job});
  final UploadJobModel job;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        border: const Border(
          top: BorderSide(color: AppColors.outlineSubtle, width: 1),
        ),
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.video_file_rounded,
              size: 11, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              job.fileName,
              style: AppTextStyles.caption(color: AppColors.textMuted)
                  .copyWith(fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatUploadTime(job.uploadedAt),
            style: AppTextStyles.caption(color: AppColors.textMuted)
                .copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _formatUploadTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 30) {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    }
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

class _DataChip extends StatelessWidget {
  const _DataChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: AppRadius.chip,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption(color: color)
                .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── History Filter Bar ───────────────────────────────────────────────────────

class HistoryFilterBar extends StatelessWidget {
  const HistoryFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final UploadStatus? selectedFilter;
  final ValueChanged<UploadStatus?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _FilterChip(
            label: 'All',
            isSelected: selectedFilter == null,
            color: AppColors.accentCyan,
            onTap: () => onFilterChanged(null),
          ),
          const SizedBox(width: 8),
          ...UploadStatus.values.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: s.label,
                  isSelected: selectedFilter == s,
                  color: s.color,
                  onTap: () =>
                      onFilterChanged(selectedFilter == s ? null : s),
                ),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: AppRadius.chip,
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : AppColors.surfaceElevated,
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : AppColors.outlineSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption(
            color: isSelected ? color : AppColors.textMuted,
          ).copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── History Search Bar ───────────────────────────────────────────────────────

class HistorySearchBar extends StatelessWidget {
  const HistorySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTextStyles.body(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search by team, competition or file…',
        hintStyle: AppTextStyles.body(color: AppColors.textMuted),
        prefixIcon: const Icon(Icons.search_rounded,
            size: 20, color: AppColors.textMuted),
        suffixIcon: controller.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textMuted),
              )
            : null,
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide:
              BorderSide(color: AppColors.outline, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide:
              BorderSide(color: AppColors.outline, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide:
              BorderSide(color: AppColors.accentCyan, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class HistoryEmptyState extends StatelessWidget {
  const HistoryEmptyState({
    super.key,
    required this.isSearching,
    required this.onUpload,
  });

  final bool isSearching;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceElevated,
                border: Border.all(color: AppColors.outlineSubtle),
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.cloud_upload_rounded,
                size: 34,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No Results Found' : 'No Uploads Yet',
              style: AppTextStyles.title(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try adjusting your search or filter criteria.'
                  : 'Upload your first match video to start generating AI tactical analysis.',
              style: AppTextStyles.body(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (!isSearching) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Upload Match'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: AppColors.textPrimary,
                  shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.button),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── History Stats Summary ────────────────────────────────────────────────────

class HistoryStatsSummary extends StatelessWidget {
  const HistoryStatsSummary({
    super.key,
    required this.jobs,
  });

  final List<UploadJobModel> jobs;

  @override
  Widget build(BuildContext context) {
    final completed =
        jobs.where((j) => j.status == UploadStatus.completed).length;
    final processing =
        jobs.where((j) => j.status == UploadStatus.processing).length;
    final failed =
        jobs.where((j) => j.status == UploadStatus.failed).length;

    return Row(
      children: [
        _StatPill(
          label: '$completed Completed',
          color: AppColors.accentGreen,
          icon: Icons.check_circle_rounded,
        ),
        const SizedBox(width: 8),
        if (processing > 0) ...[
          _StatPill(
            label: '$processing Processing',
            color: AppColors.primaryPurple,
            icon: Icons.auto_awesome_rounded,
          ),
          const SizedBox(width: 8),
        ],
        if (failed > 0)
          _StatPill(
            label: '$failed Failed',
            color: AppColors.danger,
            icon: Icons.error_rounded,
          ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: AppRadius.chip,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption(color: color)
                .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
