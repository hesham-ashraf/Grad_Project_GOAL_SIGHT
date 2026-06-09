import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/upload_job_model.dart';
import '../../../providers/repository_providers.dart';
import '../widgets/upload_history_widgets.dart';

class UploadHistoryScreen extends ConsumerStatefulWidget {
  const UploadHistoryScreen({super.key});

  @override
  ConsumerState<UploadHistoryScreen> createState() =>
      _UploadHistoryScreenState();
}

class _UploadHistoryScreenState extends ConsumerState<UploadHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  UploadStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  Future<void> _handleRefresh() async {
    await HapticService.refresh();
    ref.invalidate(uploadHistoryProvider(null));
    await ref.read(uploadHistoryProvider(null).future);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Filtering ────────────────────────────────────────────────────────────────

  List<UploadJobModel> _filtered(List<UploadJobModel> source) {
    var jobs = List<UploadJobModel>.from(source);

    // Sort: processing first, then by uploadedAt descending
    jobs.sort((a, b) {
      if (a.status == UploadStatus.processing &&
          b.status != UploadStatus.processing) {
        return -1;
      }
      if (b.status == UploadStatus.processing &&
          a.status != UploadStatus.processing) {
        return 1;
      }
      return b.uploadedAt.compareTo(a.uploadedAt);
    });

    // Filter by status
    if (_filterStatus != null) {
      jobs = jobs.where((j) => j.status == _filterStatus).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      jobs = jobs.where((j) {
        return j.homeTeam.toLowerCase().contains(q) ||
            j.awayTeam.toLowerCase().contains(q) ||
            j.competition.toLowerCase().contains(q) ||
            j.fileName.toLowerCase().contains(q) ||
            j.venue.toLowerCase().contains(q);
      }).toList();
    }

    return jobs;
  }

  // ── Staggered reveal helper ───────────────────────────────────────────────

  Animation<double> _fade(double start, double end) => CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );

  Animation<Offset> _slide(Animation<double> fade) =>
      Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
          .animate(fade);

  Widget _reveal(double start, double end, Widget child) {
    final f = _fade(start, end);
    return FadeTransition(
      opacity: f,
      child: SlideTransition(position: _slide(f), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hp = context.rs(20, min: 14, max: 28);
    final jobs = ref.watch(uploadHistoryProvider(null)).maybeWhen(
          data: (d) => d,
          orElse: () => const <UploadJobModel>[],
        );
    final filtered = _filtered(jobs);
    final isSearching =
        _searchQuery.isNotEmpty || _filterStatus != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top bar ──
            _reveal(
              0.0,
              0.25,
              Padding(
                padding: EdgeInsets.fromLTRB(hp, 12, hp, 0),
                child: _HistoryTopBar(
                    onBack: () => context.pop(), count: jobs.length),
              ),
            ),

            // ── Scrollable content ──
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppColors.accentCyan,
                backgroundColor: AppColors.surface,
                strokeWidth: 2.5,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding:
                          EdgeInsets.fromLTRB(hp, 12, hp, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Header ──
                          _reveal(
                            0.05,
                            0.28,
                            _HistoryHeader(
                              totalCount: jobs.length,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Stats summary ──
                          _reveal(
                            0.12,
                            0.36,
                            HistoryStatsSummary(
                              jobs: jobs,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // ── Search bar ──
                          _reveal(
                            0.20,
                            0.44,
                            HistorySearchBar(
                              controller: _searchController,
                              onChanged: (q) =>
                                  setState(() => _searchQuery = q),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // ── Filter bar ──
                          _reveal(
                            0.28,
                            0.52,
                            HistoryFilterBar(
                              selectedFilter: _filterStatus,
                              onFilterChanged: (s) =>
                                  setState(() => _filterStatus = s),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Result count ──
                          _reveal(
                            0.36,
                            0.56,
                            _ResultsCount(
                              count: filtered.length,
                              total: jobs.length,
                              isFiltered: isSearching,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // ── List or empty state ──
                          if (filtered.isEmpty)
                            _reveal(
                              0.44,
                              0.75,
                              HistoryEmptyState(
                                isSearching: isSearching,
                                onUpload: () => context.pop(),
                              ),
                            )
                          else
                            ...List.generate(filtered.length, (i) {
                              final startA =
                                  (0.40 + i * 0.06).clamp(0.0, 0.88);
                              final endA =
                                  (startA + 0.24).clamp(0.0, 1.0);
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 12),
                                child: _reveal(
                                  startA,
                                  endA,
                                  UploadHistoryCard(
                                    job: filtered[i],
                                    onTap: () =>
                                        _onCardTap(filtered[i]),
                                    onRetry: filtered[i].status ==
                                            UploadStatus.failed
                                        ? () =>
                                            _onRetry(filtered[i])
                                        : null,
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCardTap(UploadJobModel job) {
    // Completed jobs could navigate to analysis
    // For now show a bottom sheet with details
    _showDetailSheet(job);
  }

  void _onRetry(UploadJobModel job) {
    // Navigate to upload screen to retry
    context.pop();
  }

  void _showDetailSheet(UploadJobModel job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _JobDetailSheet(job: job),
    );
  }
}

// ─── History Top Bar ──────────────────────────────────────────────────────────

class _HistoryTopBar extends StatelessWidget {
  const _HistoryTopBar({required this.onBack, required this.count});
  final VoidCallback onBack;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.outlineSubtle),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Upload History',
          style: AppTextStyles.title().copyWith(
            fontSize: context.sp(18, min: 16, max: 22),
          ),
        ),
        const Spacer(),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: AppRadius.chip,
            color: AppColors.primaryPurple.withValues(alpha: 0.12),
            border: Border.all(
              color: AppColors.primaryPurple.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_rounded,
                  size: 13, color: AppColors.primaryPurple),
              const SizedBox(width: 5),
              Text(
                '$count Records',
                style: AppTextStyles.caption(
                        color: AppColors.primaryPurple)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── History Header ───────────────────────────────────────────────────────────

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.totalCount});
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Match Uploads',
          style: AppTextStyles.headline().copyWith(
            fontSize: context.sp(26, min: 20, max: 32),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'All uploaded match footage and AI analysis results.',
          style: AppTextStyles.body(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ─── Results Count ────────────────────────────────────────────────────────────

class _ResultsCount extends StatelessWidget {
  const _ResultsCount({
    required this.count,
    required this.total,
    required this.isFiltered,
  });

  final int count;
  final int total;
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          isFiltered
              ? '$count of $total matches'
              : '$count matches',
          style: AppTextStyles.caption(color: AppColors.textMuted)
              .copyWith(fontWeight: FontWeight.w600),
        ),
        if (isFiltered) ...[
          const SizedBox(width: 8),
          Text(
            '(filtered)',
            style: AppTextStyles.caption(color: AppColors.accentCyan),
          ),
        ],
      ],
    );
  }
}

// ─── Job Detail Bottom Sheet ──────────────────────────────────────────────────

class _JobDetailSheet extends StatelessWidget {
  const _JobDetailSheet({required this.job});
  final UploadJobModel job;

  @override
  Widget build(BuildContext context) {
    final hp = context.rs(20, min: 14, max: 28);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(hp, 20, hp, 32),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: AppColors.outlineSubtle, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: AppColors.outlineSubtle,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Match name + status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${job.homeTeam} vs ${job.awayTeam}',
                      style: AppTextStyles.title(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.competition,
                      style: AppTextStyles.body(
                          color: AppColors.accentCyan),
                    ),
                  ],
                ),
              ),
              UploadStatusBadge(status: job.status),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.outlineSubtle),
          const SizedBox(height: 16),

          // Detail rows
          _SheetRow(
            icon: Icons.stadium_rounded,
            label: 'Venue',
            value: job.venue,
          ),
          _SheetRow(
            icon: Icons.calendar_today_rounded,
            label: 'Match Date',
            value:
                '${job.matchDate.day} ${months[job.matchDate.month - 1]} ${job.matchDate.year}',
          ),
          _SheetRow(
            icon: Icons.video_file_rounded,
            label: 'File',
            value: job.fileName,
          ),
          _SheetRow(
            icon: Icons.upload_rounded,
            label: 'Uploaded',
            value:
                '${job.uploadedAt.day} ${months[job.uploadedAt.month - 1]} ${job.uploadedAt.year} at ${_padTwo(job.uploadedAt.hour)}:${_padTwo(job.uploadedAt.minute)}',
          ),
          if (job.matchScore != null)
            _SheetRow(
              icon: Icons.scoreboard_rounded,
              label: 'Score',
              value: job.matchScore!,
            ),
          if (job.intensityScore != null)
            _SheetRow(
              icon: Icons.local_fire_department_rounded,
              label: 'Intensity',
              value: '${job.intensityScore} / 100',
            ),
          if (job.tacticalSummary != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: AppRadius.card,
                color: AppColors.surfaceRaised,
                border: Border.all(color: AppColors.outlineSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          size: 14,
                          color: AppColors.primaryPurple),
                      const SizedBox(width: 6),
                      Text(
                        'Tactical Summary',
                        style: AppTextStyles.caption(
                                color: AppColors.primaryPurple)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.tacticalSummary!,
                    style: AppTextStyles.body(
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
          if (job.failureReason != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: AppRadius.card,
                color: AppColors.danger.withValues(alpha: 0.06),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 14, color: AppColors.danger),
                      const SizedBox(width: 6),
                      Text(
                        'Failure Reason',
                        style: AppTextStyles.caption(
                                color: AppColors.danger)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.failureReason!,
                    style: AppTextStyles.body(
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Actions
          if (job.status == UploadStatus.completed) ...[
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.analytics_rounded),
              label: const Text('View Full Analysis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: AppColors.textPrimary,
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.button),
                elevation: 0,
              ),
            ),
          ] else if (job.status == UploadStatus.failed) ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger
                    .withValues(alpha: 0.8),
                foregroundColor: AppColors.textPrimary,
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.button),
                elevation: 0,
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: AppTextStyles.body(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  String _padTwo(int n) => n.toString().padLeft(2, '0');
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.caption(
                  color: AppColors.textMuted)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption(
                  color: AppColors.textPrimary)
                  .copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
