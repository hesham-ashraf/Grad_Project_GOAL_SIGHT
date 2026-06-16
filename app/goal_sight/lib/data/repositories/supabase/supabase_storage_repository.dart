// ---------------------------------------------------------------------------
// GoalSight — Supabase Storage Repository
//
// Persists and retrieves analysis exports and generated reports in the
// `analysis-exports` and `reports` Storage buckets, with reference rows in
// `analysis_exports` / `stored_reports`. Provides upload, list, signed-URL
// retrieval, and deletion (file + DB row) APIs.
// ---------------------------------------------------------------------------

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/analysis_export_model.dart';

class SupabaseStorageRepository {
  const SupabaseStorageRepository();

  static const exportsBucket = 'analysis-exports';
  static const reportsBucket = 'reports';
  static const _signedUrlTtl = 60 * 60; // 1 hour

  SupabaseClient get _client => Supabase.instance.client;
  String? get _uid => _client.auth.currentUser?.id;

  // ── Analysis Exports ──────────────────────────────────────────────────────

  /// Uploads [bytes] to the exports bucket and records a reference row.
  Future<AnalysisExportModel> uploadAnalysisExport({
    required Uint8List bytes,
    required String fileName,
    String? analysisId,
    AnalysisExportType type = AnalysisExportType.pdf,
    String title = 'Analysis Export',
    String mimeType = 'application/pdf',
  }) async {
    final uid = _uid ?? 'anonymous';
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage.from(exportsBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );

    final row = await _client
        .from('analysis_exports')
        .insert({
          if (analysisId != null) 'analysis_id': analysisId,
          'export_type': type.wire,
          'title': title,
          'file_name': fileName,
          'storage_path': path,
          'file_size': bytes.length,
          'mime_type': mimeType,
        })
        .select()
        .single();

    return AnalysisExportModel.fromJson(row);
  }

  /// Lists export references, optionally filtered by analysis.
  Future<List<AnalysisExportModel>> fetchAnalysisExports({
    String? analysisId,
  }) async {
    var query = _client.from('analysis_exports').select();
    if (analysisId != null && analysisId.isNotEmpty) {
      query = query.eq('analysis_id', analysisId);
    }
    final rows = await query.order('created_at', ascending: false);
    return (rows as List)
        .map((r) => AnalysisExportModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Returns the model with a time-limited signed download URL attached.
  Future<AnalysisExportModel> withSignedUrl(AnalysisExportModel export) async {
    final url = await _client.storage
        .from(exportsBucket)
        .createSignedUrl(export.storagePath, _signedUrlTtl);
    return export.copyWith(signedUrl: url);
  }

  /// Deletes both the stored file and its reference row.
  Future<void> deleteAnalysisExport(AnalysisExportModel export) async {
    await _client.storage.from(exportsBucket).remove([export.storagePath]);
    await _client.from('analysis_exports').delete().eq('id', export.id);
  }

  // ── Stored Reports ────────────────────────────────────────────────────────

  Future<StoredReportModel> uploadReport({
    required Uint8List bytes,
    required String fileName,
    required String title,
    StoredReportType type = StoredReportType.tactical,
    String? relatedId,
    Map<String, dynamic> metadata = const {},
    String mimeType = 'application/pdf',
  }) async {
    final uid = _uid ?? 'anonymous';
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage.from(reportsBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );

    final row = await _client
        .from('stored_reports')
        .insert({
          'report_type': type.wire,
          'title': title,
          if (relatedId != null) 'related_id': relatedId,
          'file_name': fileName,
          'storage_path': path,
          'file_size': bytes.length,
          'mime_type': mimeType,
          'metadata': metadata,
        })
        .select()
        .single();

    return StoredReportModel.fromJson(row);
  }

  Future<List<StoredReportModel>> fetchReports({
    StoredReportType? type,
    String? relatedId,
  }) async {
    var query = _client.from('stored_reports').select();
    if (type != null) query = query.eq('report_type', type.wire);
    if (relatedId != null && relatedId.isNotEmpty) {
      query = query.eq('related_id', relatedId);
    }
    final rows = await query.order('created_at', ascending: false);
    return (rows as List)
        .map((r) => StoredReportModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<StoredReportModel> reportWithSignedUrl(StoredReportModel report) async {
    final url = await _client.storage
        .from(reportsBucket)
        .createSignedUrl(report.storagePath, _signedUrlTtl);
    return report.copyWith(signedUrl: url);
  }

  Future<void> deleteReport(StoredReportModel report) async {
    await _client.storage.from(reportsBucket).remove([report.storagePath]);
    await _client.from('stored_reports').delete().eq('id', report.id);
  }
}
