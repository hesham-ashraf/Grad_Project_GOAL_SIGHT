// ---------------------------------------------------------------------------
// GoalSight — Supabase Manager Repository
//
// Reads/writes the admin-managed manager directory (managers table) and maps
// rows to the ManagerModel view-model. Admin-only writes are enforced by RLS.
// ---------------------------------------------------------------------------

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/manager_model.dart';
import '../interfaces/i_manager_repository.dart';

final class SupabaseManagerRepository implements IManagerRepository {
  const SupabaseManagerRepository();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<ManagerModel>> fetchManagers({
    String? clubId,
    bool? activeOnly,
  }) async {
    var query = _client.from('managers').select();
    if (clubId != null) {
      query = query.eq('club_id', clubId);
    }
    if (activeOnly != null) {
      query = query.eq('is_active', activeOnly);
    }
    final rows = await query.order('tactical_rating', ascending: false);
    return (rows as List)
        .map((r) => _mapManager(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ManagerModel> fetchManagerById(String id) async {
    final row =
        await _client.from('managers').select().eq('id', id).maybeSingle();
    if (row == null) throw Exception('Manager not found: $id');
    return _mapManager(row);
  }

  @override
  Future<ManagerModel> createManager(ManagerModel manager) async {
    final inserted = await _client
        .from('managers')
        .insert({
          'name': manager.name,
          'email': manager.email,
          'image_url': manager.imageUrl,
          'upload_count': manager.uploadCount,
          'matches_analyzed': manager.matchesAnalyzed,
          'tactical_rating': manager.tacticalRating,
          'last_active': manager.lastActive.toIso8601String(),
          'is_active': manager.isActive,
          if (manager.clubId != null) 'club_id': manager.clubId,
        })
        .select()
        .single();
    return _mapManager(inserted);
  }

  @override
  Future<ManagerModel> updateManagerStatus(
    String id, {
    required bool isActive,
  }) async {
    final updated = await _client
        .from('managers')
        .update({'is_active': isActive})
        .eq('id', id)
        .select()
        .single();
    return _mapManager(updated);
  }

  @override
  Future<void> updatePermissions(
    String id, {
    required bool canUpload,
    required bool canEditPlayers,
    required bool canManageStaff,
  }) async {
    // Manager permissions are not yet modelled in the DB — acknowledged no-op.
  }

  ManagerModel _mapManager(Map<String, dynamic> r) => ManagerModel(
        id: r['id'].toString(),
        name: (r['name'] ?? '').toString(),
        email: (r['email'] ?? '').toString(),
        imageUrl: (r['image_url'] ?? '').toString(),
        uploadCount: (r['upload_count'] as num? ?? 0).toInt(),
        lastActive: DateTime.tryParse(r['last_active']?.toString() ?? '') ??
            DateTime.now(),
        isActive: r['is_active'] == true,
        matchesAnalyzed: (r['matches_analyzed'] as num? ?? 0).toInt(),
        tacticalRating: _toDouble(r['tactical_rating']),
        clubId: r['club_id']?.toString(),
      );

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
