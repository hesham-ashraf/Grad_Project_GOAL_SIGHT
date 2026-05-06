import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/match_analysis_model.dart';
import '../manager_upload_mock_data.dart';

enum _UploadState { initial, selected, loading, success }

class UploadMatchScreen extends StatefulWidget {
  const UploadMatchScreen({super.key});

  @override
  State<UploadMatchScreen> createState() => _UploadMatchScreenState();
}

class _UploadMatchScreenState extends State<UploadMatchScreen>
    with SingleTickerProviderStateMixin {
  _UploadState _state = _UploadState.initial;
  String? _selectedFileName;
  double _uploadProgress = 0;
  MatchAnalysisModel? _generatedAnalysis;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOutCubic),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _selectVideo() {
    setState(() {
      _selectedFileName = 'match_video_${DateTime.now().millisecond}.mp4';
      _state = _UploadState.selected;
    });
    _fadeController.forward(from: 0);
  }

  void _startAnalysis() async {
    setState(() {
      _state = _UploadState.loading;
      _uploadProgress = 0;
    });
    _fadeController.forward(from: 0);

    // Simulate upload and processing over 3 seconds
    for (int i = 0; i <= 30; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _uploadProgress = (i / 30).clamp(0, 1);
        });
      }
    }

    // Generate mock analysis
    if (mounted) {
      final mockData = generateMockMatchAnalysis();
      setState(() {
        _generatedAnalysis = mockData;
        _state = _UploadState.success;
        _uploadProgress = 1;
      });
      _fadeController.forward(from: 0);
    }
  }

  void _viewAnalysis() {
    if (_generatedAnalysis != null) {
      context.push('/fan-match-analysis', extra: _generatedAnalysis);
    }
  }

  void _reset() {
    setState(() {
      _state = _UploadState.initial;
      _selectedFileName = null;
      _uploadProgress = 0;
      _generatedAnalysis = null;
    });
    _fadeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Upload & Analyze'),
        elevation: 0,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: AppSpacing.page,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildStateContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent() {
    switch (_state) {
      case _UploadState.initial:
        return _UploadAreaWidget(onSelectVideo: _selectVideo);
      case _UploadState.selected:
        return _FileSelectedWidget(
          fileName: _selectedFileName!,
          onAnalyze: _startAnalysis,
        );
      case _UploadState.loading:
        return _LoadingWidget(progress: _uploadProgress);
      case _UploadState.success:
        return _SuccessWidget(
          match: _generatedAnalysis!,
          onViewAnalysis: _viewAnalysis,
          onReset: _reset,
        );
    }
  }
}

// ─── Upload Area Widget ───────────────────────────────────────────────────────

class _UploadAreaWidget extends StatelessWidget {
  const _UploadAreaWidget({required this.onSelectVideo});

  final VoidCallback onSelectVideo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            boxShadow: AppShadows.card,
          ),
          child: Material(
            color: AppTheme.darkSurfaceAlt,
            borderRadius: AppRadius.card,
            child: InkWell(
              borderRadius: AppRadius.card,
              onTap: onSelectVideo,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.video_camera_back_outlined,
                      size: 72,
                      color: AppColors.accentCyan,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Upload Match Video',
                      style: AppTextStyles.title(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a video file to analyze',
                      style: AppTextStyles.body(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onSelectVideo,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Select Video'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppColors.primaryPurple,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _InfoCard(
          icon: Icons.info_outline,
          title: 'Supported Formats',
          subtitle: 'MP4, MOV, AVI (max 5GB)',
        ),
        const SizedBox(height: 16),
        _InfoCard(
          icon: Icons.schedule_outlined,
          title: 'Processing Time',
          subtitle: 'Analysis typically takes 2–3 minutes',
        ),
      ],
    );
  }
}

// ─── File Selected Widget ──────────────────────────────────────────────────────

class _FileSelectedWidget extends StatelessWidget {
  const _FileSelectedWidget({
    required this.fileName,
    required this.onAnalyze,
  });

  final String fileName;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            color: AppTheme.darkSurfaceAlt,
            boxShadow: AppShadows.card,
          ),
          padding: AppSpacing.card,
          child: Row(
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                size: 40,
                color: AppColors.accentCyan,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File Ready',
                      style: AppTextStyles.caption(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fileName,
                      style: AppTextStyles.body(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle_outlined,
                color: AppColors.success,
                size: 24,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onAnalyze,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Start Analysis'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _InfoCard(
          icon: Icons.analytics_outlined,
          title: 'What You\'ll Get',
          subtitle: 'Player ratings, team tactics, key moments, and AI insights',
        ),
      ],
    );
  }
}

// ─── Loading Widget ───────────────────────────────────────────────────────────

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toStringAsFixed(0);

    return Column(
      children: [
        const SizedBox(height: 60),
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accentCyan,
                  ),
                  backgroundColor: AppColors.outline.withOpacity(0.3),
                ),
              ),
              Text(
                '$percentage%',
                style: AppTextStyles.title(color: AppColors.accentCyan),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Analyzing Match...',
          style: AppTextStyles.title(),
        ),
        const SizedBox(height: 12),
        Text(
          'AI is processing team tactics, player performance, and key moments',
          style: AppTextStyles.body(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            color: AppTheme.darkSurfaceAlt,
            boxShadow: AppShadows.card,
          ),
          padding: AppSpacing.card,
          child: Row(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Processing...',
                  style: AppTextStyles.body(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Success Widget ───────────────────────────────────────────────────────────

class _SuccessWidget extends StatelessWidget {
  const _SuccessWidget({
    required this.match,
    required this.onViewAnalysis,
    required this.onReset,
  });

  final MatchAnalysisModel match;
  final VoidCallback onViewAnalysis;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Icon(
          Icons.check_circle_outline,
          size: 80,
          color: AppColors.success,
        ),
        const SizedBox(height: 24),
        Text(
          'Analysis Complete!',
          style: AppTextStyles.headline(color: AppColors.success),
        ),
        const SizedBox(height: 8),
        Text(
          'Your match data has been successfully analyzed.',
          style: AppTextStyles.body(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            color: AppTheme.darkSurfaceAlt,
            boxShadow: AppShadows.card,
          ),
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${match.homeTeam} vs ${match.awayTeam}',
                style: AppTextStyles.title(),
              ),
              const SizedBox(height: 8),
              Text(
                'Score: ${match.score}',
                style: AppTextStyles.body(color: AppColors.accentCyan),
              ),
              const SizedBox(height: 8),
              Text(
                'Date: ${match.date}',
                style: AppTextStyles.caption(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.whatshot_outlined,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text(
                    'Intensity: ${match.intensity}%',
                    style: AppTextStyles.caption(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onViewAnalysis,
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('View Full Analysis'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Upload Another'),
          ),
        ),
      ],
    );
  }
}

// ─── Info Card Widget ──────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: AppTheme.darkSurfaceAlt.withOpacity(0.5),
        border: Border.all(
          color: AppColors.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: AppSpacing.card,
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentCyan, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body()),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
