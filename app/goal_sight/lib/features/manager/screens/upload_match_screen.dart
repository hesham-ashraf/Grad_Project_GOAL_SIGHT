import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/cache_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/analysis_job_model.dart';
import '../../../data/models/match_analysis_model.dart';
import '../../../data/models/upload_job_model.dart';
import '../../../data/services/analysis_api_client.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/manager_players_provider.dart';
import '../../../providers/repository_providers.dart';
import '../widgets/ai_processing_widgets.dart';
import '../widgets/upload_widgets.dart';
import 'player_naming_screen.dart';

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

class UploadMatchScreen extends ConsumerStatefulWidget {
  const UploadMatchScreen({super.key});

  @override
  ConsumerState<UploadMatchScreen> createState() => _UploadMatchScreenState();
}

class _UploadMatchScreenState extends ConsumerState<UploadMatchScreen>
    with TickerProviderStateMixin {
  _UploadStep _step = _UploadStep.fileSelection;
  UploadFormData _formData = UploadFormData();
  MatchAnalysisModel? _generatedAnalysis;

  // Processing state
  ProcessingStage? _currentStage;
  double _overallProgress = 0.0;
  Timer? _processingTimer;
  String? _serviceJobId; // WSL analysis-service job id
  String? _analysisId; // real match_analyses ID once the engine persists it
  XFile? _pickedVideo; // the real video file the manager selected

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

  Future<void> _onFileSelected() async {
    // Real flow: open the native picker and let the manager choose a video.
    try {
      final picker = ImagePicker();
      final file = await picker.pickVideo(source: ImageSource.gallery);
      if (file == null) return; // user cancelled
      final length = await file.length();
      if (!mounted) return;
      setState(() {
        _pickedVideo = file;
        _formData = _formData.copyWith(
          fileName: file.name,
          fileSize: _formatBytes(length),
        );
      });
      _goTo(_UploadStep.matchDetails);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not pick a video: $e'),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var i = 0;
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(size >= 100 || i == 0 ? 0 : 1)} ${units[i]}';
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

  // ── Processing ─────────────────────────────────────────────────────────────

  void _startProcessing() {
    _goTo(_UploadStep.processing);
    setState(() {
      _currentStage = ProcessingStage.detectingPlayers;
      _overallProgress = 0.0;
    });
    unawaited(_runPipeline());
  }

  /// Real pipeline: upload → detect → name players → full analysis → results.
  /// The WSL FastAPI service runs the model and persists everything to
  /// Supabase; the app polls status and fetches the persisted analysis.
  Future<void> _runPipeline() async {
    final api = ref.read(analysisApiClientProvider);
    final clubId = ref.read(managerClubIdProvider);
    final userId = ref.read(authControllerProvider).user?.id;

    if (_pickedVideo == null) {
      _fail('No video selected.');
      return;
    }
    if (clubId == null || clubId.isEmpty) {
      _fail('No club assigned to your account yet. Ask your admin to add you '
          'to a club, then try again.');
      return;
    }
    if (!api.isConfigured) {
      _fail('No analysis server configured. Set ANALYSIS_API_URL in .env to '
          'your ngrok URL and restart the app.');
      return;
    }

    try {
      // 1) Send the video to the WSL service; detection starts immediately.
      _serviceJobId = await api.createJob(
        videoPath: _pickedVideo!.path,
        fileName: _pickedVideo!.name,
        homeTeam: _formData.homeTeam,
        awayTeam: _formData.awayTeam,
        competition: _formData.competition,
        venue: _formData.venue,
        matchDate: _formData.matchDate.toIso8601String(),
        clubId: clubId,
        uploadedBy: userId,
      );

      // 2) Poll until the model has detected players (awaiting_naming).
      final detect = await _pollUntil(
          api,
          _serviceJobId!,
          (s) =>
              s.status == AnalysisJobStatus.awaitingNaming ||
              s.status.isTerminal);
      if (detect.status == AnalysisJobStatus.failed) {
        _fail(detect.error ?? 'Detection failed.');
        return;
      }
      if (detect.status == AnalysisJobStatus.completed) {
        await _finish(api, _serviceJobId!); // no naming needed (rare)
        return;
      }

      // 3) Show the naming screen and collect the manager's mapping.
      final naming = await api.getNaming(_serviceJobId!);
      if (!mounted) return;
      final result = await Navigator.of(context).push<NamingResult>(
        MaterialPageRoute(builder: (_) => PlayerNamingScreen(data: naming)),
      );
      if (result == null) {
        _fail('Player naming was cancelled.');
        return;
      }

      // 4) Submit names → the model resumes the full analysis.
      if (mounted) {
        setState(() {
          _currentStage = ProcessingStage.trackingBall;
          _overallProgress = 0.5;
        });
      }
      await api.confirmPlayers(
        jobId: _serviceJobId!,
        mappings: result.mappings,
        myTeamId: result.myTeamId,
      );

      // 5) Poll until the full analysis is complete.
      final done =
          await _pollUntil(api, _serviceJobId!, (s) => s.status.isTerminal);
      if (done.status == AnalysisJobStatus.failed) {
        _fail(done.error ?? 'Analysis failed.');
        return;
      }
      await _finish(api, _serviceJobId!);
    } catch (e) {
      _fail(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Polls job status (every 3s), updating the progress UI, until [done].
  Future<AnalysisJobStatusResult> _pollUntil(
    AnalysisApiClient api,
    String jobId,
    bool Function(AnalysisJobStatusResult) done,
  ) async {
    while (mounted) {
      AnalysisJobStatusResult s;
      try {
        s = await api.getStatus(jobId);
      } catch (_) {
        await Future.delayed(const Duration(seconds: 3));
        continue; // transient network hiccup → keep polling
      }
      if (mounted) {
        setState(() {
          _overallProgress = s.progress.clamp(0.0, 1.0);
          _currentStage = _stageFor(s);
        });
      }
      if (done(s)) return s;
      await Future.delayed(const Duration(seconds: 3));
    }
    return api.getStatus(jobId);
  }

  ProcessingStage _stageFor(AnalysisJobStatusResult s) {
    switch (s.status) {
      case AnalysisJobStatus.analyzing:
        final p = s.progress;
        if (p >= 0.9) return ProcessingStage.finalizingReport;
        if (p >= 0.8) return ProcessingStage.creatingPlayerReports;
        if (p >= 0.7) return ProcessingStage.generatingInsights;
        if (p >= 0.6) return ProcessingStage.buildingTacticalModel;
        if (p >= 0.5) return ProcessingStage.calculatingSpeed;
        return ProcessingStage.estimatingPossession;
      case AnalysisJobStatus.completed:
        return ProcessingStage.finalizingReport;
      default:
        return ProcessingStage.detectingPlayers;
    }
  }

  /// Fetches the result + the Supabase-persisted analysis, refreshes caches.
  Future<void> _finish(AnalysisApiClient api, String jobId) async {
    final res = await api.getResult(jobId);
    _analysisId = res.analysisId;

    MatchAnalysisModel? persisted;
    if (_analysisId != null) {
      try {
        persisted = await ref
            .read(analysisRepositoryProvider)
            .fetchAnalysisById(_analysisId!);
      } catch (_) {
        persisted = null;
      }
    }

    // The analysis, analyzed video and per-player verdicts are in Supabase now,
    // so refresh every screen that can surface them.
    CacheService.invalidatePrefix('squad:');
    CacheService.invalidatePrefix('player:');
    ref.invalidate(matchAnalysisListProvider);
    ref.invalidate(squadProvider);
    ref.invalidate(squadRiskProvider);
    ref.invalidate(uploadHistoryProvider);
    ref.invalidate(managerPlayersProvider);
    ref.invalidate(managerDashboardProvider);

    if (!mounted) return;
    setState(() {
      _generatedAnalysis = persisted;
      _overallProgress = 1.0;
    });
    _goTo(_UploadStep.success);
  }

  void _fail(String reason) {
    if (!mounted) return;
    setState(() => _failureReason = reason);
    _goTo(_UploadStep.failed);
  }

  void _retryProcessing() {
    _processingTimer?.cancel();
    _startProcessing();
  }

  void _retryFromDetails() {
    _goTo(_UploadStep.matchDetails);
  }

  // ── Analysis navigation ─────────────────────────────────────────────────────

  Future<void> _viewAnalysis() async {
    // Prefer the REAL persisted analysis (with the analyzed video) over the
    // on-screen preview. Fall back to the latest club analysis, then the mock.
    final repo = ref.read(analysisRepositoryProvider);
    MatchAnalysisModel? real;
    try {
      real = _analysisId != null
          ? await repo.fetchAnalysisById(_analysisId!)
          : await repo.fetchLatestAnalysis(clubId: null);
    } catch (_) {
      real = null;
    }
    final toShow = real ?? _generatedAnalysis;
    if (toShow != null && mounted) {
      context.push('/fan-match-analysis', extra: toShow);
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
      _analysisId = null;
      _serviceJobId = null;
      _pickedVideo = null;
      _currentStage = null;
      _overallProgress = 0.0;
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
    final showBack =
        _step == _UploadStep.matchDetails || _step == _UploadStep.confirmation;

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
              shape:
                  const RoundedRectangleBorder(borderRadius: AppRadius.button),
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
