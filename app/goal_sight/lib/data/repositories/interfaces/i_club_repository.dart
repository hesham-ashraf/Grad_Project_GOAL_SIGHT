import '../../models/club_model.dart';

/// Abstract contract for the Club data source.
/// Swap the mock implementation for a Supabase implementation
/// with zero changes to callers.
abstract interface class IClubRepository {
  /// Returns all clubs, optionally filtered by [query].
  Future<List<ClubModel>> fetchClubs({String? query});

  /// Returns a single club by [id]. Throws if not found.
  Future<ClubModel> fetchClubById(String id);

  /// Returns a paginated list. [page] is 0-indexed.
  Future<List<ClubModel>> fetchClubsPaged({
    required int page,
    int pageSize = 20,
    String? query,
    String sortBy = 'name',
  });
}
