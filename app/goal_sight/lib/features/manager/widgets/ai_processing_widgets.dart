import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../upload_job_model.dart';

// ─── AI Processing View ───────────────────────────────────────────────────────

/// Full-screen processing view shown during the 8-stage AI pipeline.
/// [currentStage] is the currently active stage (null = starting up).
/// [overallProgress] is 0.0–1.0.
class AiProcessingView extends StatefulWidget {
  const AiProcessingView({
    super.key,
    required this.currentStage,
    required this.overallProgress,
    required this.homeTeam,
    required this.awayTeam,
    required this.competition,
  });

  final ProcessingStage? currentStage;
  final double overallProgress;
  final String homeTeam;
  final String awayTeam;
  final String competition;

  @override
  State<AiProcessingView> createState() => _AiProcessingViewState();
}

class _AiProcessingViewState extends State<AiProcessingView>
    with TickerProviderStateMixin {
  late final AnimationController _mainCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _rotateCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _fadeIn = CurvedAnimation(parent: _mainCtrl, curve: Curves.easeOutCubic);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.currentStage;
    final stages = ProcessingStage.values;
    final currentIndex =
        stage != null ? stages.indexOf(stage) : -1;
    final percentage = (widget.overallProgress * 100).round();

    return FadeTransition(
      opacity: _fadeIn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Match header
          _MatchHeader(
            homeTeam: widget.homeTeam,
            awayTeam: widget.awayTeam,
            competition: widget.competition,
          ),
          SizedBox(height: context.rs(20, min: 16, max: 28)),

          // Central stage visual
          _StageVisualCard(
            stage: stage,
            pulseAnim: _pulse,
            rotateCtrl: _rotateCtrl,
          ),
          SizedBox(height: context.rs(20, min: 16, max: 28)),

          // Overall progress bar
          _OverallProgressBar(
            progress: widget.overallProgress,
            percentage: percentage,
          ),
          SizedBox(height: context.rs(20, min: 16, max: 28)),

          // Stage pipeline list
          _StagePipelineList(
            currentIndex: currentIndex,
            stages: stages,
            overallProgress: widget.overallProgress,
          ),
          SizedBox(height: context.rs(16, min: 12, max: 20)),

          // Info banner
          _ProcessingInfoBanner(),
        ],
      ),
    );
  }
}

// ─── Match Header ─────────────────────────────────────────────────────────────

class _MatchHeader extends StatelessWidget {
  const _MatchHeader({
    required this.homeTeam,
    required this.awayTeam,
    required this.competition,
  });

  final String homeTeam;
  final String awayTeam;
  final String competition;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withValues(alpha: 0.15),
            AppColors.accentCyan.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            competition,
            style: AppTextStyles.caption(color: AppColors.accentCyan)
                .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  homeTeam,
                  style: AppTextStyles.title(color: AppColors.textPrimary)
                      .copyWith(fontSize: context.sp(16, min: 13, max: 18)),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'vs',
                  style: AppTextStyles.body(color: AppColors.textMuted),
                ),
              ),
              Expanded(
                child: Text(
                  awayTeam,
                  style: AppTextStyles.title(color: AppColors.textPrimary)
                      .copyWith(fontSize: context.sp(16, min: 13, max: 18)),
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stage Visual Card ────────────────────────────────────────────────────────

class _StageVisualCard extends StatelessWidget {
  const _StageVisualCard({
    required this.stage,
    required this.pulseAnim,
    required this.rotateCtrl,
  });

  final ProcessingStage? stage;
  final Animation<double> pulseAnim;
  final AnimationController rotateCtrl;

  @override
  Widget build(BuildContext context) {
    final currentStage = stage;
    final stageColor = currentStage?.color ?? AppColors.primaryPurple;
    final stageIcon = currentStage?.icon ?? Icons.hourglass_empty_rounded;
    final stageLabel = currentStage?.label ?? 'Initializing...';
    final stageDesc = currentStage?.description ??
        'Preparing AI analysis pipeline...';

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: context.rs(28, min: 22, max: 36),
        horizontal: context.rs(20, min: 16, max: 28),
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardLarge,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surfaceElevated,
            stageColor.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: stageColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: stageColor.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated icon cluster
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (context, _) {
              return SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stageColor.withValues(
                            alpha: pulseAnim.value * 0.08),
                      ),
                    ),
                    // Middle ring
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stageColor.withValues(alpha: 0.1),
                        border: Border.all(
                          color: stageColor.withValues(
                              alpha: pulseAnim.value * 0.4),
                          width: 1,
                        ),
                      ),
                    ),
                    // Rotating arc
                    RotationTransition(
                      turns: rotateCtrl,
                      child: CustomPaint(
                        size: const Size(76, 76),
                        painter: _ArcPainter(color: stageColor),
                      ),
                    ),
                    // Core icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stageColor.withValues(alpha: 0.15),
                      ),
                      child: Icon(stageIcon, size: 26, color: stageColor),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Stage name
          Text(
            stageLabel,
            style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
              fontSize: context.sp(17, min: 14, max: 20),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Stage description
          Text(
            stageDesc,
            style: AppTextStyles.body(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Animated dots
          _PulsingDots(color: stageColor),
        ],
      ),
    );
  }
}

// ─── Overall Progress Bar ─────────────────────────────────────────────────────

class _OverallProgressBar extends StatelessWidget {
  const _OverallProgressBar({
    required this.progress,
    required this.percentage,
  });

  final double progress;
  final int percentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: AppTextStyles.body(color: AppColors.textSecondary)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '$percentage%',
                style: AppTextStyles.title(color: AppColors.accentCyan)
                    .copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: AppColors.surfaceRaised,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryPurple,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Analysis in Progress',
                style: AppTextStyles.caption(color: AppColors.textMuted),
              ),
              Text(
                'Est. 2–5 min',
                style: AppTextStyles.caption(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stage Pipeline List ──────────────────────────────────────────────────────

class _StagePipelineList extends StatelessWidget {
  const _StagePipelineList({
    required this.currentIndex,
    required this.stages,
    required this.overallProgress,
  });

  final int currentIndex;
  final List<ProcessingStage> stages;
  final double overallProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardLarge,
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.outlineSubtle),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryPurple.withValues(alpha: 0.15),
                  ),
                  child: Icon(Icons.account_tree_rounded,
                      size: 14, color: AppColors.primaryPurple),
                ),
                const SizedBox(width: 10),
                Text(
                  'Analysis Pipeline',
                  style: AppTextStyles.body(color: AppColors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  '${currentIndex + 1} / ${stages.length}',
                  style: AppTextStyles.caption(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.outlineSubtle),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stages.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: AppColors.outlineSubtle),
            itemBuilder: (context, i) {
              final s = stages[i];
              final isCompleted = i < currentIndex;
              final isCurrent = i == currentIndex;
              final isPending = i > currentIndex;

              return _StageListItem(
                stage: s,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                isPending: isPending,
                index: i,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StageListItem extends StatelessWidget {
  const _StageListItem({
    required this.stage,
    required this.isCompleted,
    required this.isCurrent,
    required this.isPending,
    required this.index,
  });

  final ProcessingStage stage;
  final bool isCompleted;
  final bool isCurrent;
  final bool isPending;
  final int index;

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    Color bgColor;
    IconData statusIcon;
    Color textColor;

    if (isCompleted) {
      iconColor = AppColors.accentGreen;
      bgColor = AppColors.accentGreen.withValues(alpha: 0.12);
      statusIcon = Icons.check_rounded;
      textColor = AppColors.textSecondary;
    } else if (isCurrent) {
      iconColor = stage.color;
      bgColor = stage.color.withValues(alpha: 0.12);
      statusIcon = stage.icon;
      textColor = AppColors.textPrimary;
    } else {
      iconColor = AppColors.textMuted;
      bgColor = AppColors.surfaceRaised;
      statusIcon = stage.icon;
      textColor = AppColors.textMuted;
    }

    return Container(
      color: isCurrent
          ? stage.color.withValues(alpha: 0.04)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          // Index number
          SizedBox(
            width: 20,
            child: Text(
              '${index + 1}',
              style: AppTextStyles.caption(
                color: isCompleted || isCurrent
                    ? AppColors.textMuted
                    : AppColors.outline,
              ).copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),

          // Stage icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
            ),
            child: isCompleted
                ? Icon(statusIcon, size: 16, color: iconColor)
                : isCurrent
                    ? _SpinningIcon(icon: statusIcon, color: iconColor)
                    : Icon(statusIcon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 12),

          // Stage label
          Expanded(
            child: Text(
              stage.label,
              style: AppTextStyles.body(color: textColor).copyWith(
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),

          // Status badge
          if (isCompleted)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: AppRadius.chip,
                color: AppColors.accentGreen.withValues(alpha: 0.12),
              ),
              child: Text(
                'Done',
                style: AppTextStyles.caption(color: AppColors.accentGreen)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            )
          else if (isCurrent)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: AppRadius.chip,
                color: stage.color.withValues(alpha: 0.15),
              ),
              child: Text(
                'Active',
                style: AppTextStyles.caption(color: stage.color)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            )
          else
            Text(
              '—',
              style: AppTextStyles.caption(color: AppColors.outline),
            ),
        ],
      ),
    );
  }
}

// ─── Processing Info Banner ───────────────────────────────────────────────────

class _ProcessingInfoBanner extends StatelessWidget {
  const _ProcessingInfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AppColors.primaryBlue.withValues(alpha: 0.06),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Do not close the app. Analysis runs in the background and results will be saved to Upload History.',
              style: AppTextStyles.caption(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Processing Success Card ──────────────────────────────────────────────────

class ProcessingSuccessCard extends StatefulWidget {
  const ProcessingSuccessCard({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.competition,
    required this.matchScore,
    required this.intensityScore,
    required this.tacticalSummary,
    required this.onViewAnalysis,
    required this.onUploadAnother,
    required this.onViewHistory,
  });

  final String homeTeam;
  final String awayTeam;
  final String competition;
  final String matchScore;
  final int intensityScore;
  final String tacticalSummary;
  final VoidCallback onViewAnalysis;
  final VoidCallback onUploadAnother;
  final VoidCallback onViewHistory;

  @override
  State<ProcessingSuccessCard> createState() =>
      _ProcessingSuccessCardState();
}

class _ProcessingSuccessCardState extends State<ProcessingSuccessCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward();

    _fades = List.generate(5, (i) {
      final start = (i * 0.14).clamp(0.0, 0.80);
      final end = (start + 0.28).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic));
    });
    _slides = _fades
        .map((f) => Tween<Offset>(
                begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(f))
        .toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _reveal(int i, Widget child) => FadeTransition(
        opacity: _fades[i],
        child: SlideTransition(position: _slides[i], child: child),
      );

  @override
  Widget build(BuildContext context) {
    final intensityColor = widget.intensityScore >= 80
        ? AppColors.danger
        : widget.intensityScore >= 60
            ? AppColors.warning
            : AppColors.accentGreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Success hero ──
        _reveal(
          0,
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardLarge,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accentGreen.withValues(alpha: 0.08),
                  AppColors.primaryPurple.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(
                color: AppColors.accentGreen.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                _SuccessRing(),
                const SizedBox(height: 16),
                Text(
                  'Analysis Complete!',
                  style: AppTextStyles.headline(color: AppColors.accentGreen)
                      .copyWith(
                          fontSize: context.sp(26, min: 20, max: 32)),
                ),
                const SizedBox(height: 6),
                Text(
                  'AI has finished processing all 8 stages successfully.',
                  style: AppTextStyles.body(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: context.rs(16, min: 12, max: 20)),

        // ── Match result card ──
        _reveal(
          1,
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: AppRadius.card,
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.outlineSubtle),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.homeTeam,
                        style: AppTextStyles.title(
                                color: AppColors.textPrimary)
                            .copyWith(
                                fontSize:
                                    context.sp(14, min: 12, max: 17)),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.card,
                        color:
                            AppColors.primaryBlue.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppColors.primaryBlue
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        widget.matchScore,
                        style: AppTextStyles.headline(
                                color: AppColors.textPrimary)
                            .copyWith(fontSize: 22),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.awayTeam,
                        style: AppTextStyles.title(
                                color: AppColors.textPrimary)
                            .copyWith(
                                fontSize:
                                    context.sp(14, min: 12, max: 17)),
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MetricChip(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Intensity',
                      value: '${widget.intensityScore}',
                      color: intensityColor,
                    ),
                    const SizedBox(width: 10),
                    _MetricChip(
                      icon: Icons.emoji_events_rounded,
                      label: 'Competition',
                      value: widget.competition,
                      color: AppColors.accentCyan,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: context.rs(12, min: 8, max: 16)),

        // ── Tactical summary ──
        _reveal(
          2,
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: AppRadius.card,
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.outlineSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 16, color: AppColors.primaryPurple),
                    const SizedBox(width: 8),
                    Text(
                      'AI Tactical Summary',
                      style: AppTextStyles.body(
                              color: AppColors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.tacticalSummary,
                  style: AppTextStyles.body(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: context.rs(20, min: 16, max: 28)),

        // ── View full analysis CTA ──
        _reveal(
          3,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onViewAnalysis,
              icon: const Icon(Icons.analytics_rounded),
              label: const Text('View Full Analysis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: AppColors.textPrimary,
                padding: EdgeInsets.symmetric(
                    vertical: context.rs(15, min: 12, max: 18)),
                shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.button),
                elevation: 0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── Secondary actions ──
        _reveal(
          4,
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onViewHistory,
                  icon: const Icon(Icons.history_rounded, size: 17),
                  label: const Text('History'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.outline, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.button),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onUploadAnother,
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text('New Upload'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentCyan,
                    side: BorderSide(
                        color: AppColors.accentCyan.withValues(alpha: 0.4),
                        width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.button),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Success Ring Widget ──────────────────────────────────────────────────────

class _SuccessRing extends StatefulWidget {
  const _SuccessRing();

  @override
  State<_SuccessRing> createState() => _SuccessRingState();
}

class _SuccessRingState extends State<_SuccessRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentGreen.withValues(alpha: 0.12),
            border: Border.all(
              color: AppColors.accentGreen.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.check_rounded,
            size: 38,
            color: AppColors.accentGreen,
          ),
        ),
      ),
    );
  }
}

// ─── Private Helpers ──────────────────────────────────────────────────────────

class _PulsingDots extends StatefulWidget {
  const _PulsingDots({required this.color});
  final Color color;

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.33;
            final t = ((_ctrl.value - delay) % 1.0 + 1.0) % 1.0;
            final opacity =
                (math.sin(t * math.pi)).clamp(0.2, 1.0).toDouble();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: opacity),
              ),
            );
          }),
        );
      },
    );
  }
}

class _SpinningIcon extends StatefulWidget {
  const _SpinningIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: Icon(widget.icon, size: 15, color: widget.color),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: AppRadius.chip,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            '$label: $value',
            style: AppTextStyles.caption(color: color)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ─── Arc Painter ──────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, 0, math.pi * 1.2, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
