// ---------------------------------------------------------------------------
// GoalSight — Mock Upload Repository
//
// Realistic mock implementation of IUploadRepository.
// 10 upload jobs spanning all statuses, managers, and match combinations.
// Replace with SupabaseUploadRepository when backend is ready.
// ---------------------------------------------------------------------------

import 'dart:async';

import '../../models/upload_job_model.dart';
import '../interfaces/i_upload_repository.dart';
import 'mock_club_repository.dart';

final class MockUploadRepository implements IUploadRepository {
  const MockUploadRepository();

  static const _delay = Duration(milliseconds: 440);

  // ── In-memory mutable store (supports updateJobStatus) ───────────────────

  static final List<UploadJobModel> _jobs = [
    UploadJobModel(
      id: 'job_001',
      homeTeam: 'GoalSight FC',
      awayTeam: 'City Panthers',
      competition: 'Premier League',
      venue: 'Analytics Arena',
      matchDate: DateTime(2026, 5, 18),
      fileName: 'gfc_vs_panthers_gw38.mp4',
      uploadedAt: DateTime(2026, 5, 18, 22, 14),
      status: UploadStatus.completed,
      progress: 1.0,
      intensityScore: 88,
      matchScore: '3 - 1',
      tacticalSummary:
          'GoalSight FC dominated with Haaland hat-trick. Panthers struggled to contain the high press.',
      notes: 'Title decider — full 90 minutes available',
    ),
    UploadJobModel(
      id: 'job_002',
      homeTeam: 'Falcons United',
      awayTeam: 'GoalSight FC',
      competition: 'Premier League',
      venue: 'Falcon Park',
      matchDate: DateTime(2026, 5, 11),
      fileName: 'falcons_vs_gfc_gw37.mp4',
      uploadedAt: DateTime(2026, 5, 11, 21, 58),
      status: UploadStatus.completed,
      progress: 1.0,
      intensityScore: 72,
      matchScore: '1 - 2',
      tacticalSummary:
          'GoalSight broke Falcons counter-attack with clinical pressing. De Bruyne controlled tempo.',
      notes: 'Camera angle 2 recommended for tactical review',
    ),
    UploadJobModel(
      id: 'job_003',
      homeTeam: 'GoalSight FC',
      awayTeam: 'Red Lions FC',
      competition: 'Premier League',
      venue: 'Analytics Arena',
      matchDate: DateTime(2026, 5, 4),
      fileName: 'gfc_vs_red_lions_gw36.mp4',
      uploadedAt: DateTime(2026, 5, 4, 22, 30),
      status: UploadStatus.completed,
      progress: 1.0,
      intensityScore: 65,
      matchScore: '2 - 0',
      tacticalSummary:
          'Comfortable win. Van Dijk and Rice dominated. Haaland brace from minimal touches.',
      notes: 'Second half was slow — first half worth studying',
    ),
    UploadJobModel(
      id: 'job_004',
      homeTeam: 'City Panthers',
      awayTeam: 'Thunder Athletic',
      competition: 'Premier League',
      venue: 'Panther Stadium',
      matchDate: DateTime(2026, 5, 10),
      fileName: 'panthers_vs_thunder_gw37.mp4',
      uploadedAt: DateTime(2026, 5, 10, 21, 45),
      status: UploadStatus.completed,
      progress: 1.0,
      intensityScore: 82,
      matchScore: '4 - 2',
      tacticalSummary:
          'Dominant Panthers performance. Wright and Rodri in perfect sync. Thunder showed resilience.',
      notes: 'Full match — excellent quality footage',
    ),
    UploadJobModel(
      id: 'job_005',
      homeTeam: 'Red Lions FC',
      awayTeam: 'Thunder Athletic',
      competition: 'Championship',
      venue: 'Lion Fortress',
      matchDate: DateTime(2026, 4, 26),
      fileName: 'red_lions_vs_thunder_cship.mp4',
      uploadedAt: DateTime(2026, 4, 26, 22, 08),
      status: UploadStatus.completed,
      progress: 1.0,
      intensityScore: 79,
      matchScore: '2 - 2',
      tacticalSummary:
          'Dramatic draw. Santos double offset by Ndiaye heroics in added time. High-intensity second half.',
      notes: 'Highlight reel recommended: 90+2 equaliser',
    ),
    UploadJobModel(
      id: 'job_006',
      homeTeam: 'Thunder Athletic',
      awayTeam: 'Falcons United',
      competition: 'Championship',
      venue: 'Thunder Dome',
      matchDate: DateTime(2026, 4, 19),
      fileName: 'thunder_vs_falcons_cship.mp4',
      uploadedAt: DateTime(2026, 4, 19, 22, 15),
      status: UploadStatus.completed,
      progress: 1.0,
      intensityScore: 76,
      matchScore: '3 - 1',
      tacticalSummary:
          'Romano-Ndiaye combination irresistible. Falcons\' Ferreira exposed on Ndiaye\'s pace.',
      notes: 'Excellent example of high-press forward press',
    ),
    UploadJobModel(
      id: 'job_007',
      homeTeam: 'Falcons United',
      awayTeam: 'Red Lions FC',
      competition: 'Championship',
      venue: 'Falcon Park',
      matchDate: DateTime(2026, 4, 12),
      fileName: 'falcons_vs_red_lions_cship.mp4',
      uploadedAt: DateTime(2026, 4, 12, 22, 40),
      status: UploadStatus.completed,
      progress: 1.0,
      intensityScore: 68,
      matchScore: '2 - 0',
      tacticalSummary:
          'Morrison brace on a clinical performance. Red Lions failed to create clear chances.',
      notes: 'Webb\'s performance worth highlighting',
    ),
    UploadJobModel(
      id: 'job_008',
      homeTeam: 'GoalSight FC',
      awayTeam: 'Falcons United',
      competition: 'Premier League',
      venue: 'Analytics Arena',
      matchDate: DateTime(2026, 5, 25),
      fileName: 'gfc_vs_falcons_gw39_promo.mp4',
      uploadedAt: DateTime(2026, 5, 25, 23, 12),
      status: UploadStatus.processing,
      progress: 0.62,
      processingStage: ProcessingStage.buildingTacticalModel,
      notes: 'Season finale fixture — high priority',
    ),
    UploadJobModel(
      id: 'job_009',
      homeTeam: 'City Panthers',
      awayTeam: 'Red Lions FC',
      competition: 'Premier League',
      venue: 'Panther Stadium',
      matchDate: DateTime(2026, 5, 25),
      fileName: 'panthers_vs_red_lions_gw39.mp4',
      uploadedAt: DateTime(2026, 5, 25, 23, 45),
      status: UploadStatus.uploading,
      progress: 0.38,
      notes: 'GW39 upload — stadium network used',
    ),
    UploadJobModel(
      id: 'job_010',
      homeTeam: 'Thunder Athletic',
      awayTeam: 'City Panthers',
      competition: 'Championship',
      venue: 'Thunder Dome',
      matchDate: DateTime(2026, 5, 20),
      fileName: 'thunder_vs_panthers_playoff.mp4',
      uploadedAt: DateTime(2026, 5, 20, 21, 30),
      status: UploadStatus.failed,
      progress: 0.14,
      failureReason: 'Upload interrupted — file corruption detected at 14%',
      notes: 'Playoff semi-final — retry required',
    ),
  ];

  // ── Manager → job mapping ─────────────────────────────────────────────────

  static const Map<String, List<String>> _managerJobs = {
    'm1': ['job_001', 'job_002', 'job_003', 'job_008'],
    'm2': ['job_004', 'job_009'],
    'm3': ['job_005', 'job_006', 'job_010'],
    'm4': ['job_007'],
  };

  // ── Stream controllers for real-time job watching ─────────────────────────

  static final Map<String, StreamController<UploadJobModel>> _controllers = {};

  // ── IUploadRepository ─────────────────────────────────────────────────────

  @override
  Future<List<UploadJobModel>> fetchUploadHistory({String? managerId}) async {
    await Future.delayed(_delay);
    if (managerId == null) return List.unmodifiable(_jobs);
    final ids = _managerJobs[managerId] ?? [];
    return _jobs.where((j) => ids.contains(j.id)).toList();
  }

  @override
  Future<UploadJobModel> fetchUploadById(String id) async {
    await Future.delayed(_delay);
    return _jobs.firstWhere(
      (j) => j.id == id,
      orElse: () => throw RepositoryException('Upload job not found: $id'),
    );
  }

  @override
  Future<UploadJobModel> createUploadJob(UploadJobModel job) async {
    await Future.delayed(_delay);
    _jobs.add(job);
    return job;
  }

  @override
  Future<UploadJobModel> updateJobStatus(
    String id, {
    required UploadStatus status,
    double? progress,
    ProcessingStage? stage,
    String? failureReason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final index = _jobs.indexWhere((j) => j.id == id);
    if (index == -1) throw RepositoryException('Upload job not found: $id');

    final old = _jobs[index];
    final updated = UploadJobModel(
      id: old.id,
      homeTeam: old.homeTeam,
      awayTeam: old.awayTeam,
      competition: old.competition,
      venue: old.venue,
      matchDate: old.matchDate,
      fileName: old.fileName,
      uploadedAt: old.uploadedAt,
      status: status,
      progress: progress ?? old.progress,
      failureReason: failureReason ?? old.failureReason,
      notes: old.notes,
      intensityScore: old.intensityScore,
      matchScore: old.matchScore,
      tacticalSummary: old.tacticalSummary,
      processingStage: stage ?? old.processingStage,
    );
    _jobs[index] = updated;

    // Notify any active watchers
    _controllers[id]?.add(updated);

    return updated;
  }

  @override
  Future<void> retryJob(String id) async {
    await updateJobStatus(
      id,
      status: UploadStatus.queued,
      progress: 0.0,
      failureReason: null,
    );
  }

  @override
  Stream<UploadJobModel> watchJob(String id) {
    _controllers[id]?.close();
    final ctrl = StreamController<UploadJobModel>.broadcast();
    _controllers[id] = ctrl;

    // Emit current state immediately
    final job = _jobs.firstWhere(
      (j) => j.id == id,
      orElse: () => throw RepositoryException('Upload job not found: $id'),
    );
    ctrl.add(job);

    return ctrl.stream;
  }
}
