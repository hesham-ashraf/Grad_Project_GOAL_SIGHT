import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/match_analysis_model.dart';
import '../manager_upload_mock_data.dart';
import '../../../data/models/upload_job_model.dart';
import '../widgets/ai_processing_widgets.dart';
import '../widgets/upload_widgets.dart';

// ─── Step Enum ────────────────────────────────────────────────────────────────

enum _UploadStep {
  fileSelection,
  matchDetails,
  confirmation,
  processing,
  success,
  failed,
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class UploadMatchScreen extends StatefulWidget {
  const UploadMatchScreen({super.key});

  @override
  State<UploadMatchScreen> createState() => _UploadMatchScreenState();
}

class _UploadMatchScreenState extends State<UploadMatchScreen>
    with TickerProviderStateMixin {
  _UploadStep _step = _UploadStep.fileSelection;
  UploadFormData _formData = UploadFormData();
  MatchAnalysisModel? _generatedAnalysis;

  // Processing state
  ProcessingStage? _currentStage;
  double _overallProgress = 0.0;
  Timer? _processingTimer;
  int _stageIndex = -1;

  // Failure state
  String _failureReason = '';

  // Page scroll controller
  final _scrollController = ScrollController();

  // Step transition animation
  late final AnimationController _stepCtrl;
  late final Animation<double> _stepFade;

  @override
  void initState() {
    super.initState();
    _stepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _stepFade = CurvedAnimation(
      parent: _stepCtrl,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _processingTimer?.cancel();
    _stepCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Navigation helpers ──────────────────────────────────────────────────────

  void _goTo(_UploadStep step) {
    setState(() => _step = step);
    _stepCtrl.forward(from: 0);
    // Scroll to top when step changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // ── File selection ──────────────────────────────────────────────────────────

  void _onFileSelected() {
    // Simulate picking a file — generate a mock name/size
    final r = math.Random();
    final sizes = ['842 MB', '1.2 GB', '2.1 GB', '650 MB', '1.8 GB'];
    final mockName =
        'match_footage_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final mockSize = sizes[r.nextInt(sizes.length)];

    setState(() {
      _formData = _formData.copyWith(
        fileName: mockName,
        fileSize: mockSize,
      );
    });
    _goTo(_UploadStep.matchDetails);
  }

  void _onFileRemoved() {
    setState(() {
      _formData = UploadFormData();
    });
    _goTo(_UploadStep.fileSelection);
  }

  // ── Form ──────────────────────────────────────────────────────────────────

  void _onFormDataChanged(UploadFormData data) {
    setState(() => _formData = data);
  }

  bool get _isMatchDetailsValid =>
      _formData.isTeamFormValid && _formData.isMetadataFormValid;

  void _proceedToConfirmation() {
    if (!_isMatchDetailsValid) {
      _showValidationSnackBar();
      return;
    }
    _goTo(_UploadStep.confirmation);
  }

  void _showValidationSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 18),
            SizedBox(width: 10),
            Text('Please fill in all required fields.'),
          ],
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
    );
  }

  // ── Processing simulation ───────────────────────────────────────────────────

  void _startProcessing() {
    _goTo(_UploadStep.processing);
    setState(() {
      _currentStage = null;
      _overallProgress = 0.0;
      _stageIndex = -1;
    });

    // Simulate initial upload delay then begin stages
    Future.delayed(const Duration(milliseconds: 800), _advanceStage);
  }

  void _advanceStage() {
    if (!mounted) return;

    const stages = ProcessingStage.values;
    _stageIndex++;

    if (_stageIndex >= stages.length) {
      // All stages done — generate analysis
      final analysis = generateMockMatchAnalysis();
      setState(() {
        _overallProgress = 1.0;
        _currentStage = stages.last;
        _generatedAnalysis = analysis;
      });
      // Short pause then go to success
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _goTo(_UploadStep.success);
      });
      return;
    }

    final stage = stages[_stageIndex];
    final targetProgress = stage.completionProgress;

    setState(() {
      _currentStage = stage;
    });

    // Animate progress toward target over the stage duration
    const stageDurationMs = 2400; // ~2.4s per stage
    const tickMs = 80;
    const ticks = stageDurationMs ~/ tickMs;
    final startProgress = _overallProgress;
    int tick = 0;

    _processingTimer?.cancel();
    _processingTimer =
        Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      tick++;
      final t = (tick / ticks).clamp(0.0, 1.0);
      final eased = Curves.easeInOut
          .transform(t.clamp(0.0, 1.0));
      setState(() {
        _overallProgress =
            (startProgress + (targetProgress - startProgress) * eased)
                .clamp(0.0, 1.0);
      });

      if (tick >= ticks) {
        timer.cancel();
        // Brief pause between stages
        Future.delayed(const Duration(milliseconds: 300), _advanceStage);
      }
    });
  }

  void _retryProcessing() {
    _processingTimer?.cancel();
    _startProcessing();
  }

  void _retryFromDetails() {
    _goTo(_UploadStep.matchDetails);
  }

  // ── Analysis navigation ─────────────────────────────────────────────────────

  void _viewAnalysis() {
    if (_generatedAnalysis != null) {
      context.push('/fan-match-analysis', extra: _generatedAnalysis);
    }
  }

  void _viewHistory() {
    context.push('/manager/upload-history');
  }

  void _reset() {
    _processingTimer?.cancel();
    setState(() {
      _step = _UploadStep.fileSelection;
      _formData = UploadFormData();
      _generatedAnalysis = null;
      _currentStage = null;
      _overallProgress = 0.0;
      _stageIndex = -1;
      _failureReason = '';
    });
    _stepCtrl.forward(from: 0);
  }

  // ── Step indicator ──────────────────────────────────────────────────────────

  int get _currentStepIndex {
    switch (_step) {
      case _UploadStep.fileSelection:
        return 0;
      case _UploadStep.matchDetails:
        return 1;
      case _UploadStep.confirmation:
        return 2;
      case _UploadStep.processing:
        return 3;
      case _UploadStep.success:
      case _UploadStep.failed:
        return 3;
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hp = context.rs(20, min: 14, max: 28);
    final showBack = _step == _UploadStep.matchDetails ||
        _step == _UploadStep.confirmation;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            _TopBar(
              step: _step,
              onBack: showBack ? _handleBack : null,
              onHistoryTap: _viewHistory,
            ),

            // ── Step indicator (hide on processing/success/failed) ──
            if (_step != _UploadStep.processing &&
                _step != _UploadStep.success &&
                _step != _UploadStep.failed) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hp),
                child: _StepIndicator(
                  currentIndex: _currentStepIndex,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ── Content ──
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hp, 16, hp, 40),
                      child: FadeTransition(
                        opacity: _stepFade,
                        child: _buildStepContent(),
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

  void _handleBack() {
    switch (_step) {
      case _UploadStep.matchDetails:
        _goTo(_UploadStep.fileSelection);
        break;
      case _UploadStep.confirmation:
        _goTo(_UploadStep.matchDetails);
        break;
      default:
        break;
    }
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _UploadStep.fileSelection:
        return _FileSelectionStep(
          formData: _formData,
          onFileSelected: _onFileSelected,
        );

      case _UploadStep.matchDetails:
        return _MatchDetailsStep(
          formData: _formData,
          onChanged: _onFormDataChanged,
          onFileRemoved: _onFileRemoved,
          onContinue: _proceedToConfirmation,
          isValid: _isMatchDetailsValid,
        );

      case _UploadStep.confirmation:
        return UploadConfirmationCard(
          formData: _formData,
          onConfirm: _startProcessing,
          onEdit: () => _goTo(_UploadStep.matchDetails),
        );

      case _UploadStep.processing:
        return AiProcessingView(
          currentStage: _currentStage,
          overallProgress: _overallProgress,
          homeTeam: _formData.homeTeam,
          awayTeam: _formData.awayTeam,
          competition: _formData.competition,
        );

      case _UploadStep.success:
        final analysis = _generatedAnalysis;
        if (analysis == null) return const SizedBox.shrink();
        return ProcessingSuccessCard(
          homeTeam: _formData.homeTeam,
          awayTeam: _formData.awayTeam,
          competition: _formData.competition,
          matchScore: analysis.score,
          intensityScore: analysis.intensity,
          tacticalSummary: _buildTacticalSummary(analysis),
          onViewAnalysis: _viewAnalysis,
          onUploadAnother: _reset,
          onViewHistory: _viewHistory,
        );

      case _UploadStep.failed:
        return UploadFailedCard(
          reason: _failureReason,
          onRetry: _retryProcessing,
          onEditDetails: _retryFromDetails,
          formData: _formData,
        );
    }
  }

  String _buildTacticalSummary(MatchAnalysisModel analysis) {
    final dominant = analysis.summary.dominantTeam;
    final homeAR = analysis.homeAnalysis.avgRating.toStringAsFixed(1);
    final awayAR = analysis.awayAnalysis.avgRating.toStringAsFixed(1);
    final style = analysis.homeAnalysis.style;
    return '$dominant dominated with a $style approach. '
        '${analysis.homeTeam} avg rating: $homeAR · '
        '${analysis.awayTeam} avg rating: $awayAR. '
        '${analysis.recommendations.isNotEmpty ? '${analysis.recommendations.first}.' : ''}';
  }
}

// ─── File Selection Step ──────────────────────────────────────────────────────

class _FileSelectionStep extends StatelessWidget {
  const _FileSelectionStep({
    required this.formData,
    required this.onFileSelected,
  });

  final UploadFormData formData;
  final VoidCallback onFileSelected;

  @override
  Widget build(BuildContext context) {
    return UploadDropZone(onSelectFile: onFileSelected);
  }
}

// ─── Match Details Step ───────────────────────────────────────────────────────

class _MatchDetailsStep extends StatelessWidget {
  const _MatchDetailsStep({
    required this.formData,
    required this.onChanged,
    required this.onFileRemoved,
    required this.onContinue,
    required this.isValid,
  });

  final UploadFormData formData;
  final ValueChanged<UploadFormData> onChanged;
  final VoidCallback onFileRemoved;
  final VoidCallback onContinue;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Match Details',
          style: AppTextStyles.headline().copyWith(
            fontSize: context.sp(24, min: 20, max: 30),
          ),
        ),
        SizedBox(height: context.rs(4, min: 3, max: 6)),
        Text(
          'Enter the teams and match information for accurate analysis.',
          style: AppTextStyles.body(color: AppColors.textSecondary),
        ),
        SizedBox(height: context.rs(16, min: 12, max: 20)),

        // Selected file card
        if (formData.fileName != null) ...[
          SelectedFileCard(
            fileName: formData.fileName!,
            fileSize: formData.fileSize ?? '—',
            onRemove: onFileRemoved,
          ),
          SizedBox(height: context.rs(16, min: 12, max: 20)),
        ],

        // Team form
        TeamSelectionForm(
          formData: formData,
          onChanged: onChanged,
        ),
        SizedBox(height: context.rs(14, min: 10, max: 18)),

        // Metadata form
        MatchMetadataForm(
          formData: formData,
          onChanged: onChanged,
        ),
        SizedBox(height: context.rs(24, min: 18, max: 32)),

        // Continue button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isValid ? onContinue : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Review & Confirm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: AppColors.textPrimary,
              disabledBackgroundColor:
                  AppColors.primaryPurple.withValues(alpha: 0.35),
              disabledForegroundColor:
                  AppColors.textPrimary.withValues(alpha: 0.5),
              padding: EdgeInsets.symmetric(
                  vertical: context.rs(15, min: 12, max: 18)),
              shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.button),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.step,
    required this.onBack,
    required this.onHistoryTap,
  });

  final _UploadStep step;
  final VoidCallback? onBack;
  final VoidCallback onHistoryTap;

  String get _title {
    switch (step) {
      case _UploadStep.fileSelection:
        return 'Upload & Analyze';
      case _UploadStep.matchDetails:
        return 'Match Details';
      case _UploadStep.confirmation:
        return 'Review';
      case _UploadStep.processing:
        return 'AI Processing';
      case _UploadStep.success:
        return 'Analysis Ready';
      case _UploadStep.failed:
        return 'Upload Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hp = context.rs(20, min: 14, max: 28);

    return Padding(
      padding: EdgeInsets.fromLTRB(hp, 12, hp, 8),
      child: Row(
        children: [
          if (onBack != null)
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
            )
          else
            const SizedBox(width: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _title,
              style: AppTextStyles.title().copyWith(
                fontSize: context.sp(18, min: 16, max: 22),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          // History button
          GestureDetector(
            onTap: onHistoryTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceElevated,
                border: Border.all(color: AppColors.outlineSubtle),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentIndex});

  final int currentIndex;

  static const _labels = ['Select', 'Details', 'Review', 'Processing'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(_labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = i ~/ 2;
            final isCompleted = stepIndex < currentIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted
                    ? AppColors.primaryPurple
                    : AppColors.outlineSubtle,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isCompleted = stepIndex < currentIndex;
          final isCurrent = stepIndex == currentIndex;

          return _StepDot(
            label: _labels[stepIndex],
            index: stepIndex + 1,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
          );
        }),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.label,
    required this.index,
    required this.isCompleted,
    required this.isCurrent,
  });

  final String label;
  final int index;
  final bool isCompleted;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    Color textColor;
    Widget dotChild;

    if (isCompleted) {
      dotColor = AppColors.primaryPurple;
      textColor = AppColors.textSecondary;
      dotChild = const Icon(Icons.check_rounded, size: 12, color: Colors.white);
    } else if (isCurrent) {
      dotColor = AppColors.primaryPurple;
      textColor = AppColors.textPrimary;
      dotChild = Text(
        '$index',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      );
    } else {
      dotColor = AppColors.surfaceElevated;
      textColor = AppColors.textMuted;
      dotChild = Text(
        '$index',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
            border: Border.all(
              color: isCurrent || isCompleted
                  ? AppColors.primaryPurple
                  : AppColors.outlineSubtle,
              width: 1.5,
            ),
          ),
          child: Center(child: dotChild),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption(color: textColor).copyWith(
            fontSize: 9,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
