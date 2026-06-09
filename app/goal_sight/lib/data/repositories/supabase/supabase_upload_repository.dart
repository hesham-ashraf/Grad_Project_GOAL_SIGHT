// ---------------------------------------------------------------------------
// GoalSight — Supabase Upload Repository
//
// Reads/writes manager upload jobs from the upload_jobs table and maps them to
// the UploadJobModel view-model. RLS restricts managers to their own jobs.
// ---------------------------------------------------------------------------

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/upload_job_model.dart';
import '../interfaces/i_upload_repository.dart';

final class SupabaseUploadRepository implements IUploadRepository {
  const SupabaseUploadRepository();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<UploadJobModel>> fetchUploadHistory({String? managerId}) async {
    final rows = await _client
        .from('upload_jobs')
        .select()
        .not('file_name', 'is', null)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => _mapJob(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<UploadJobModel> fetchUploadById(String id) async {
    final row =
        await _client.from('upload_jobs').select().eq('id', id).maybeSingle();
    if (row == null) throw Exception('Upload job not found: $id');
    return _mapJob(row);
  }

  @override
  Future<UploadJobModel> createUploadJob(UploadJobModel job) async {
    final inserted = await _client
        .from('upload_jobs')
        .insert({
          'uploaded_by': _client.auth.currentUser?.id,
          'status': _lifecycleStatus(job.status),
          'ui_status': job.status.name,
          'progress': (job.progress * 100).round(),
          'home_team': job.homeTeam,
          'away_team': job.awayTeam,
          'competition': job.competition,
          'venue': job.venue,
          'match_date': job.matchDate.toIso8601String(),
          'file_name': job.fileName,
          'intensity_score': job.intensityScore,
          'match_score': job.matchScore,
          'tactical_summary': job.tacticalSummary,
          'notes': job.notes,
          'error_message': job.failureReason,
          'processing_stage': job.processingStage?.name,
        })
        .select()
        .single();
    return _mapJob(inserted);
  }

  @override
  Future<UploadJobModel> updateJobStatus(
    String id, {
    required UploadStatus status,
    double? progress,
    ProcessingStage? stage,
    String? failureReason,
  }) async {
    final updated = await _client
        .from('upload_jobs')
        .update({
          'status': _lifecycleStatus(status),
          'ui_status': status.name,
          if (progress != null) 'progress': (progress * 100).round(),
          if (stage != null) 'processing_stage': stage.name,
          if (failureReason != null) 'error_message': failureReason,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return _mapJob(updated);
  }

  @override
  Future<void> retryJob(String id) async {
    await _client.from('upload_jobs').update({
      'status': 'uploaded',
      'ui_status': UploadStatus.queued.name,
      'progress': 0,
      'error_message': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Stream<UploadJobModel> watchJob(String id) {
    // No live processing backend yet — emit the current state once.
    return Stream.fromFuture(fetchUploadById(id));
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  /// Maps the UI status onto the table's lifecycle CHECK domain.
  String _lifecycleStatus(UploadStatus s) {
    switch (s) {
      case UploadStatus.queued:
      case UploadStatus.uploading:
        return 'uploaded';
      case UploadStatus.processing:
        return 'processing';
      case UploadStatus.completed:
        return 'completed';
      case UploadStatus.failed:
        return 'failed';
    }
  }

  UploadJobModel _mapJob(Map<String, dynamic> r) {
    ProcessingStage? stage;
    final ps = r['processing_stage'];
    if (ps != null) {
      for (final s in ProcessingStage.values) {
        if (s.name == ps) {
          stage = s;
          break;
        }
      }
    }

    return UploadJobModel(
      id: r['id'].toString(),
      homeTeam: (r['home_team'] ?? '').toString(),
      awayTeam: (r['away_team'] ?? '').toString(),
      competition: (r['competition'] ?? '').toString(),
      venue: (r['venue'] ?? '').toString(),
      matchDate: DateTime.tryParse(r['match_date']?.toString() ?? '') ??
          DateTime.now(),
      fileName: (r['file_name'] ?? '').toString(),
      uploadedAt: DateTime.tryParse(r['created_at']?.toString() ?? '') ??
          DateTime.now(),
      status: UploadStatus.values.firstWhere(
        (e) => e.name == r['ui_status'],
        orElse: () => UploadStatus.queued,
      ),
      progress: ((r['progress'] as num? ?? 0).toDouble()) / 100.0,
      failureReason: r['error_message']?.toString(),
      notes: r['notes']?.toString(),
      intensityScore: (r['intensity_score'] as num?)?.toInt(),
      matchScore: r['match_score']?.toString(),
      tacticalSummary: r['tactical_summary']?.toString(),
      processingStage: stage,
    );
  }
}
