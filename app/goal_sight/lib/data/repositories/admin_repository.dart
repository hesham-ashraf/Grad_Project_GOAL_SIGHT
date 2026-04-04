import '../datasources/admin_remote_datasource.dart';
import '../models/match_model.dart';
import '../models/system_overview_model.dart';
import '../models/user_model.dart';

class AdminRepository {
  const AdminRepository(this._remoteDataSource);

  final AdminRemoteDataSource _remoteDataSource;

  Future<SystemOverviewModel> fetchOverview() {
    return _remoteDataSource.fetchOverview();
  }

  Future<List<UserModel>> fetchUsers() {
    return _remoteDataSource.fetchUsers();
  }

  Future<List<MatchModel>> fetchMatches() {
    return _remoteDataSource.fetchMatches();
  }

  Future<void> uploadMatch({
    required String homeTeam,
    required String awayTeam,
  }) {
    return _remoteDataSource.uploadMatch(homeTeam: homeTeam, awayTeam: awayTeam);
  }
}
