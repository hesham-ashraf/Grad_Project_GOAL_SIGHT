// ---------------------------------------------------------------------------
// GoalSight — Analysis Export & Stored Report Models
//
// Reference rows for files persisted in Supabase Storage
// (`analysis-exports` and `reports` buckets).
// ---------------------------------------------------------------------------

enum AnalysisExportType { pdf, tacticalReport, playerReport, matchSummary }

extension AnalysisExportTypeX on AnalysisExportType {
  String get wire => switch (this) {
        AnalysisExportType.pdf => 'pdf',
        AnalysisExportType.tacticalReport => 'tactical_report',
        AnalysisExportType.playerReport => 'player_report',
        AnalysisExportType.matchSummary => 'match_summary',
      };

  static AnalysisExportType from(String? value) => switch (value) {
        'tactical_report' => AnalysisExportType.tacticalReport,
        'player_report' => AnalysisExportType.playerReport,
        'match_summary' => AnalysisExportType.matchSummary,
        _ => AnalysisExportType.pdf,
      };
}

class AnalysisExportModel {
  const AnalysisExportModel({
    required this.id,
    required this.fileName,
    required this.storagePath,
    required this.type,
    required this.title,
    required this.fileSize,
    required this.mimeType,
    required this.createdAt,
    this.analysisId,
    this.signedUrl,
  });

  final String id;
  final String? analysisId;
  final String fileName;
  final String storagePath;
  final AnalysisExportType type;
  final String title;
  final int fileSize;
  final String mimeType;
  final DateTime createdAt;

  /// Populated on demand via a signed URL request (not stored in DB).
  final String? signedUrl;

  factory AnalysisExportModel.fromJson(Map<String, dynamic> json) {
    return AnalysisExportModel(
      id: json['id'].toString(),
      analysisId: json['analysis_id']?.toString(),
      fileName: (json['file_name'] ?? '').toString(),
      storagePath: (json['storage_path'] ?? '').toString(),
      type: AnalysisExportTypeX.from(json['export_type']?.toString()),
      title: (json['title'] ?? 'Analysis Export').toString(),
      fileSize: (json['file_size'] as num? ?? 0).toInt(),
      mimeType: (json['mime_type'] ?? 'application/pdf').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  AnalysisExportModel copyWith({String? signedUrl}) => AnalysisExportModel(
        id: id,
        analysisId: analysisId,
        fileName: fileName,
        storagePath: storagePath,
        type: type,
        title: title,
        fileSize: fileSize,
        mimeType: mimeType,
        createdAt: createdAt,
        signedUrl: signedUrl ?? this.signedUrl,
      );
}

enum StoredReportType { tactical, ai, playerIntelligence, summary }

extension StoredReportTypeX on StoredReportType {
  String get wire => switch (this) {
        StoredReportType.tactical => 'tactical',
        StoredReportType.ai => 'ai',
        StoredReportType.playerIntelligence => 'player_intelligence',
        StoredReportType.summary => 'summary',
      };

  static StoredReportType from(String? value) => switch (value) {
        'ai' => StoredReportType.ai,
        'player_intelligence' => StoredReportType.playerIntelligence,
        'summary' => StoredReportType.summary,
        _ => StoredReportType.tactical,
      };
}

class StoredReportModel {
  const StoredReportModel({
    required this.id,
    required this.type,
    required this.title,
    required this.fileName,
    required this.storagePath,
    required this.fileSize,
    required this.mimeType,
    required this.metadata,
    required this.createdAt,
    this.relatedId,
    this.signedUrl,
  });

  final String id;
  final StoredReportType type;
  final String title;
  final String? relatedId;
  final String fileName;
  final String storagePath;
  final int fileSize;
  final String mimeType;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final String? signedUrl;

  factory StoredReportModel.fromJson(Map<String, dynamic> json) {
    return StoredReportModel(
      id: json['id'].toString(),
      type: StoredReportTypeX.from(json['report_type']?.toString()),
      title: (json['title'] ?? 'Report').toString(),
      relatedId: json['related_id']?.toString(),
      fileName: (json['file_name'] ?? '').toString(),
      storagePath: (json['storage_path'] ?? '').toString(),
      fileSize: (json['file_size'] as num? ?? 0).toInt(),
      mimeType: (json['mime_type'] ?? 'application/pdf').toString(),
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  StoredReportModel copyWith({String? signedUrl}) => StoredReportModel(
        id: id,
        type: type,
        title: title,
        relatedId: relatedId,
        fileName: fileName,
        storagePath: storagePath,
        fileSize: fileSize,
        mimeType: mimeType,
        metadata: metadata,
        createdAt: createdAt,
        signedUrl: signedUrl ?? this.signedUrl,
      );
}
