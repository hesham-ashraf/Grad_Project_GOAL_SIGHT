import '../datasources/match_remote_datasource.dart';
import '../models/match_model.dart';

class MatchRepository {
  const MatchRepository(this._remoteDataSource);

  final MatchRemoteDataSource _remoteDataSource;

  Future<List<MatchModel>> fetchMatches() {
    return _remoteDataSource.fetchMatches();
  }

  Future<MatchModel> fetchMatchDetails(String matchId) {
    return _remoteDataSource.fetchMatchDetails(matchId);
  }

  Future<void> uploadMatch({
    required String homeTeam,
    required String awayTeam,
  }) {
    return _remoteDataSource.uploadMatch(
        homeTeam: homeTeam, awayTeam: awayTeam);
  }
}
