// ---------------------------------------------------------------------------
// GoalSight — Analysis Job Models (stateful AI pipeline)
//
// Wire types for the WSL FastAPI analysis service:
//   POST /jobs → GET /jobs/{id} (poll) → GET /jobs/{id}/naming
//   → POST /jobs/{id}/players → GET /jobs/{id}/result
// Field names mirror the service's Pydantic schemas exactly.
// ---------------------------------------------------------------------------

/// Lifecycle of one upload→analysis job (matches the service `JobStatus`).
enum AnalysisJobStatus {
  queued,
  detecting,
  awaitingNaming,
  analyzing,
  completed,
  failed,
  unknown;

  static AnalysisJobStatus parse(String? raw) {
    switch (raw) {
      case 'queued':
        return AnalysisJobStatus.queued;
      case 'detecting':
        return AnalysisJobStatus.detecting;
      case 'awaiting_naming':
        return AnalysisJobStatus.awaitingNaming;
      case 'analyzing':
        return AnalysisJobStatus.analyzing;
      case 'completed':
        return AnalysisJobStatus.completed;
      case 'failed':
        return AnalysisJobStatus.failed;
      default:
        return AnalysisJobStatus.unknown;
    }
  }

  bool get isTerminal =>
      this == AnalysisJobStatus.completed || this == AnalysisJobStatus.failed;
}

/// Status poll response (`GET /jobs/{id}`).
class AnalysisJobStatusResult {
  const AnalysisJobStatusResult({
    required this.jobId,
    required this.status,
    this.stageLabel = '',
    this.progress = 0.0,
    this.error,
  });

  final String jobId;
  final AnalysisJobStatus status;
  final String stageLabel;
  final double progress;
  final String? error;

  factory AnalysisJobStatusResult.fromJson(Map<String, dynamic> j) =>
      AnalysisJobStatusResult(
        jobId: (j['job_id'] ?? '').toString(),
        status: AnalysisJobStatus.parse(j['status']?.toString()),
        stageLabel: (j['stage_label'] ?? '').toString(),
        progress: (j['progress'] is num) ? (j['progress'] as num).toDouble() : 0.0,
        error: j['error']?.toString(),
      );
}

/// One detected track served to the naming screen (`GET /jobs/{id}/naming`).
class DetectedPlayer {
  const DetectedPlayer({
    required this.trackId,
    required this.autoRole,
    this.teamId,
    this.jerseyNumber,
    this.trackLength = 0,
    this.roleConfidence = 0.0,
    this.cropUrl,
    this.cropUrls = const [],
    this.suggestedName,
  });

  final int trackId;
  final String autoRole; // player | goalkeeper | referee | unknown
  final int? teamId; // detected cluster 0/1 (null for non-players)
  final String? jerseyNumber; // detected shirt number (null if unread)
  final int trackLength;
  final double roleConfidence;
  final String? cropUrl;
  final List<String> cropUrls; // all extracted frames for this track (gallery)
  final String? suggestedName;

  /// Frames to show in the verification gallery: prefer the full list, fall
  /// back to the single representative crop so older servers still render.
  List<String> get galleryUrls {
    final urls = cropUrls.where((u) => u.startsWith('http')).toList();
    if (urls.isNotEmpty) return urls;
    final single = cropUrl;
    return (single != null && single.startsWith('http')) ? [single] : const [];
  }

  factory DetectedPlayer.fromJson(Map<String, dynamic> j) => DetectedPlayer(
        trackId: (j['track_id'] as num).toInt(),
        autoRole: (j['auto_role'] ?? 'unknown').toString(),
        teamId: (j['team_id'] as num?)?.toInt(),
        jerseyNumber: (j['jersey_number']?.toString().trim().isEmpty ?? true)
            ? null
            : j['jersey_number'].toString().trim(),
        trackLength: (j['track_length'] as num?)?.toInt() ?? 0,
        roleConfidence:
            (j['role_confidence'] as num?)?.toDouble() ?? 0.0,
        cropUrl: j['crop_url']?.toString(),
        cropUrls: (j['crop_urls'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        suggestedName: j['suggested_name']?.toString(),
      );
}

/// Visual legend so the manager can tell team 0 from team 1.
class TeamLegendEntry {
  const TeamLegendEntry({
    required this.teamId,
    required this.label,
    this.colorRgb = const [],
    this.cropUrls = const [],
  });

  final int teamId;
  final String label;
  final List<int> colorRgb;
  final List<String> cropUrls;

  factory TeamLegendEntry.fromJson(Map<String, dynamic> j) => TeamLegendEntry(
        teamId: (j['team_id'] as num).toInt(),
        label: (j['label'] ?? '').toString(),
        colorRgb:
            (j['color_rgb'] as List?)?.map((e) => (e as num).toInt()).toList() ??
                const [],
        cropUrls: (j['crop_urls'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}

/// Everything the naming screen needs (`GET /jobs/{id}/naming`).
class NamingData {
  const NamingData({
    required this.jobId,
    required this.players,
    required this.teamLegend,
  });

  final String jobId;
  final List<DetectedPlayer> players;
  final List<TeamLegendEntry> teamLegend;

  factory NamingData.fromJson(Map<String, dynamic> j) => NamingData(
        jobId: (j['job_id'] ?? '').toString(),
        players: (j['players'] as List? ?? const [])
            .map((e) => DetectedPlayer.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        teamLegend: (j['team_legend'] as List? ?? const [])
            .map((e) =>
                TeamLegendEntry.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

/// One reviewer decision sent to `POST /jobs/{id}/players`.
class PlayerNameMapping {
  const PlayerNameMapping({
    required this.trackId,
    required this.playerName,
    this.playerId,
  });

  final int trackId;
  final String playerName;
  final String? playerId; // existing club player id, if linked

  Map<String, dynamic> toJson() => {
        'track_id': trackId,
        'player_name': playerName,
        if (playerId != null) 'player_id': playerId,
      };
}

/// Final result reference (`GET /jobs/{id}/result`). The display screens read
/// the full analysis from Supabase via [analysisId]; these URLs are fallbacks.
class AnalysisJobResult {
  const AnalysisJobResult({
    required this.jobId,
    this.analysisId,
    this.myTeamId = 0,
    this.analyzedVideoUrl,
    this.heatmapUrls = const {},
    this.raw = const {},
  });

  final String jobId;
  final String? analysisId; // Supabase match_analyses id
  final int myTeamId;
  final String? analyzedVideoUrl;
  final Map<String, String> heatmapUrls;

  /// Verbatim model JSONs (final_report, player_analytics, possession,
  /// team_tactical, speed_distance). Lets the app render the analysis even when
  /// Supabase persistence is unavailable.
  final Map<String, dynamic> raw;

  factory AnalysisJobResult.fromJson(Map<String, dynamic> j) => AnalysisJobResult(
        jobId: (j['job_id'] ?? '').toString(),
        analysisId: j['analysis_id']?.toString(),
        myTeamId: (j['my_team_id'] as num?)?.toInt() ?? 0,
        analyzedVideoUrl: j['analyzed_video_url']?.toString(),
        heatmapUrls: (j['heatmap_urls'] as Map?)
                ?.map((k, v) => MapEntry(k.toString(), v.toString())) ??
            const {},
        raw: (j['raw'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}
