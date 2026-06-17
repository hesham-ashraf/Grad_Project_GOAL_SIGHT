import '../../models/manager_model.dart';

abstract interface class IManagerRepository {
  Future<List<ManagerModel>> fetchManagers({String? clubId, bool? activeOnly});

  Future<ManagerModel> fetchManagerById(String id);

  Future<ManagerModel> createManager(ManagerModel manager);

  Future<ManagerModel> updateManagerStatus(String id, {required bool isActive});

  Future<void> updatePermissions(
    String id, {
    required bool canUpload,
    required bool canEditPlayers,
    required bool canManageStaff,
  });

  /// Finds an existing fan by email and promotes them to manager role in the
  /// given club. Calls the `promote_to_manager` Postgres RPC.
  Future<ManagerModel> promoteUserToManager({
    required String email,
    required String clubId,
    bool canUpload = true,
    bool canEditPlayers = true,
    bool canManageStaff = false,
  });
}
