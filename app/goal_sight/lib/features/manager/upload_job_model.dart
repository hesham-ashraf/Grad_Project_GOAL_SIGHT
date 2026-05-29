import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum UploadStatus { queued, uploading, processing, completed, failed }

enum ProcessingStage {
  detectingPlayers,
  trackingBall,
  estimatingPossession,
  calculatingSpeed,
  buildingTacticalModel,
  generatingInsights,
  creatingPlayerReports,
  finalizingReport,
}

extension ProcessingStageExtension on ProcessingStage {
  String get label {
    switch (this) {
      case ProcessingStage.detectingPlayers: return 'Detecting Players';
      case ProcessingStage.trackingBall: return 'Tracking Ball';
      case ProcessingStage.estimatingPossession: return 'Estimating Possession';
      case ProcessingStage.calculatingSpeed: return 'Calculating Speed & Distance';
      case ProcessingStage.buildingTacticalModel: return 'Building Tactical Model';
      case ProcessingStage.generatingInsights: return 'Generating Tactical Insights';
      case ProcessingStage.creatingPlayerReports: return 'Creating Player Reports';
      case ProcessingStage.finalizingReport: return 'Finalizing Analysis';
    }
  }

  String get description {
    switch (this) {
      case ProcessingStage.detectingPlayers:
        return 'AI vision scanning all 22 players across every frame';
      case ProcessingStage.trackingBall:
        return 'Tracking ball trajectory and possession sequences';
      case ProcessingStage.estimatingPossession:
        return 'Calculating team control zones and possession percentages';
      case ProcessingStage.calculatingSpeed:
        return 'Measuring sprint speeds, distances, and intensity zones';
      case ProcessingStage.buildingTacticalModel:
        return 'Building formation maps and tactical shape analysis';
      case ProcessingStage.generatingInsights:
        return 'Synthesizing AI tactical recommendations';
      case ProcessingStage.creatingPlayerReports:
        return 'Compiling individual player intelligence reports';
      case ProcessingStage.finalizingReport:
        return 'Assembling the complete tactical analysis document';
    }
  }

  IconData get icon {
    switch (this) {
      case ProcessingStage.detectingPlayers: return Icons.person_search_rounded;
      case ProcessingStage.trackingBall: return Icons.sports_soccer_rounded;
      case ProcessingStage.estimatingPossession: return Icons.pie_chart_rounded;
      case ProcessingStage.calculatingSpeed: return Icons.speed_rounded;
      case ProcessingStage.buildingTacticalModel: return Icons.grid_on_rounded;
      case ProcessingStage.generatingInsights: return Icons.auto_awesome_rounded;
      case ProcessingStage.creatingPlayerReports: return Icons.people_alt_rounded;
      case ProcessingStage.finalizingReport: return Icons.summarize_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ProcessingStage.detectingPlayers: return AppColors.accentCyan;
      case ProcessingStage.trackingBall: return AppColors.primaryBlue;
      case ProcessingStage.estimatingPossession: return AppColors.primaryPurple;
      case ProcessingStage.calculatingSpeed: return AppColors.accentGreen;
      case ProcessingStage.buildingTacticalModel: return AppColors.accentCyan;
      case ProcessingStage.generatingInsights: return AppColors.primaryPurple;
      case ProcessingStage.creatingPlayerReports: return AppColors.primaryBlue;
      case ProcessingStage.finalizingReport: return AppColors.accentGreen;
    }
  }

  /// Progress milestone when this stage *completes* (0.0–1.0)
  double get completionProgress {
    const milestones = [0.12, 0.24, 0.36, 0.50, 0.62, 0.74, 0.87, 1.0];
    return milestones[ProcessingStage.values.indexOf(this)];
  }
}

class UploadJobModel {
  const UploadJobModel({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.competition,
    required this.venue,
    required this.matchDate,
    required this.fileName,
    required this.uploadedAt,
    required this.status,
    this.progress = 0.0,
    this.failureReason,
    this.notes,
    this.intensityScore,
    this.matchScore,
    this.tacticalSummary,
    this.processingStage,
  });

  final String id;
  final String homeTeam;
  final String awayTeam;
  final String competition;
  final String venue;
  final DateTime matchDate;
  final String fileName;
  final DateTime uploadedAt;
  final UploadStatus status;
  final double progress; // 0.0–1.0
  final String? failureReason;
  final String? notes;
  final int? intensityScore;
  final String? matchScore;
  final String? tacticalSummary;
  final ProcessingStage? processingStage;
}

extension UploadStatusExtension on UploadStatus {
  String get label {
    switch (this) {
      case UploadStatus.queued: return 'Queued';
      case UploadStatus.uploading: return 'Uploading';
      case UploadStatus.processing: return 'Processing';
      case UploadStatus.completed: return 'Analysis Ready';
      case UploadStatus.failed: return 'Failed';
    }
  }

  Color get color {
    switch (this) {
      case UploadStatus.queued: return AppColors.textMuted;
      case UploadStatus.uploading: return AppColors.primaryBlue;
      case UploadStatus.processing: return AppColors.primaryPurple;
      case UploadStatus.completed: return AppColors.accentGreen;
      case UploadStatus.failed: return AppColors.danger;
    }
  }

  IconData get icon {
    switch (this) {
      case UploadStatus.queued: return Icons.schedule_rounded;
      case UploadStatus.uploading: return Icons.cloud_upload_rounded;
      case UploadStatus.processing: return Icons.auto_awesome_rounded;
      case UploadStatus.completed: return Icons.check_circle_rounded;
      case UploadStatus.failed: return Icons.error_rounded;
    }
  }

  bool get isActive => this == UploadStatus.uploading || this == UploadStatus.processing;
}
