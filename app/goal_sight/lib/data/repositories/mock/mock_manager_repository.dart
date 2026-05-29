// ---------------------------------------------------------------------------
// GoalSight — Mock Manager Repository
//
// Realistic mock implementation of IManagerRepository.
// 6 managers spanning all 5 clubs with varied activity, ratings, and roles.
// Replace with SupabaseManagerRepository when backend is ready.
// ---------------------------------------------------------------------------

import '../../models/manager_model.dart';
import '../interfaces/i_manager_repository.dart';
import 'mock_club_repository.dart';

final class MockManagerRepository implements IManagerRepository {
  const MockManagerRepository();

  static const _delay = Duration(milliseconds: 500);

  // ── Mutable in-memory manager store ──────────────────────────────────────

  static final List<ManagerModel> _managers = [
    ManagerModel(
      id: 'm1',
      name: 'James Cooper',
      email: 'j.cooper@goalsightfc.com',
      imageUrl: 'https://i.pravatar.cc/150?u=m1',
      uploadCount: 28,
      lastActive: DateTime(2026, 5, 25, 22, 48),
      isActive: true,
      matchesAnalyzed: 24,
      tacticalRating: 9.1,
    ),
    ManagerModel(
      id: 'm2',
      name: 'Sofia Mendes',
      email: 's.mendes@citypanthers.com',
      imageUrl: 'https://i.pravatar.cc/150?u=m2',
      uploadCount: 32,
      lastActive: DateTime(2026, 5, 25, 20, 15),
      isActive: true,
      matchesAnalyzed: 30,
      tacticalRating: 9.4,
    ),
    ManagerModel(
      id: 'm3',
      name: 'Tariq Al-Rashid',
      email: 't.alrashid@thunderathletic.com',
      imageUrl: 'https://i.pravatar.cc/150?u=m3',
      uploadCount: 21,
      lastActive: DateTime(2026, 5, 24, 18, 30),
      isActive: true,
      matchesAnalyzed: 19,
      tacticalRating: 8.6,
    ),
    ManagerModel(
      id: 'm4',
      name: 'Emma Clarke',
      email: 'e.clarke@falconsunited.com',
      imageUrl: 'https://i.pravatar.cc/150?u=m4',
      uploadCount: 14,
      lastActive: DateTime(2026, 5, 22, 14, 20),
      isActive: true,
      matchesAnalyzed: 12,
      tacticalRating: 8.1,
    ),
    ManagerModel(
      id: 'm5',
      name: 'Nikos Papadopoulos',
      email: 'n.papa@redlionsfc.com',
      imageUrl: 'https://i.pravatar.cc/150?u=m5',
      uploadCount: 18,
      lastActive: DateTime(2026, 5, 20, 16, 10),
      isActive: true,
      matchesAnalyzed: 16,
      tacticalRating: 7.9,
    ),
    ManagerModel(
      id: 'm6',
      name: 'Rachel Osei',
      email: 'r.osei@goalsightfc.com',
      imageUrl: 'https://i.pravatar.cc/150?u=m6',
      uploadCount: 6,
      lastActive: DateTime(2026, 4, 15, 11, 0),
      isActive: false,
      matchesAnalyzed: 5,
      tacticalRating: 7.2,
    ),
  ];

  // ── IManagerRepository ────────────────────────────────────────────────────

  @override
  Future<List<ManagerModel>> fetchManagers({
    String? clubId,
    bool? activeOnly,
  }) async {
    await Future.delayed(_delay);
    var list = List<ManagerModel>.from(_managers);

    // Filter by active status
    if (activeOnly != null) {
      list = list.where((m) => m.isActive == activeOnly).toList();
    }

    // In a real implementation, clubId would filter by the manager's club
    // For mock data, we have no explicit club linkage, so return all
    return list;
  }

  @override
  Future<ManagerModel> fetchManagerById(String id) async {
    await Future.delayed(_delay);
    return _managers.firstWhere(
      (m) => m.id == id,
      orElse: () => throw RepositoryException('Manager not found: $id'),
    );
  }

  @override
  Future<ManagerModel> createManager(ManagerModel manager) async {
    await Future.delayed(_delay);
    // Check for duplicate email
    final exists = _managers.any((m) => m.email == manager.email);
    if (exists) {
      throw RepositoryException('Manager with email ${manager.email} already exists');
    }
    _managers.add(manager);
    return manager;
  }

  @override
  Future<ManagerModel> updateManagerStatus(
    String id, {
    required bool isActive,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _managers.indexWhere((m) => m.id == id);
    if (index == -1) throw RepositoryException('Manager not found: $id');

    final old = _managers[index];
    final updated = ManagerModel(
      id: old.id,
      name: old.name,
      email: old.email,
      imageUrl: old.imageUrl,
      uploadCount: old.uploadCount,
      lastActive: old.lastActive,
      isActive: isActive,
      matchesAnalyzed: old.matchesAnalyzed,
      tacticalRating: old.tacticalRating,
    );
    _managers[index] = updated;
    return updated;
  }

  @override
  Future<void> updatePermissions(
    String id, {
    required bool canUpload,
    required bool canEditPlayers,
    required bool canManageStaff,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Verify manager exists
    final exists = _managers.any((m) => m.id == id);
    if (!exists) throw RepositoryException('Manager not found: $id');
    // Permissions are stored externally in a real system.
    // Mock: no-op — success acknowledged.
  }
}
