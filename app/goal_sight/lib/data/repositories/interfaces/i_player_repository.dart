import '../../models/player_profile_model.dart';
import '../../models/risk_analysis_model.dart';

abstract interface class IPlayerRepository {
  Future<List<PlayerProfileModel>> fetchSquad({String? clubId});

  Future<PlayerProfileModel> createPlayer({
    required String fullName,
    required String position,
    required String clubId,
    int? jerseyNumber,
  });

  Future<PlayerProfileModel> fetchPlayerById(String id);

  Future<RiskAnalysisModel> fetchRiskAnalysis(String playerId);

  Future<List<RiskAnalysisModel>> fetchSquadRiskAnalysis({String? clubId});

  Future<List<PlayerProfileModel>> fetchPlayersPaged({
    required int page,
    int pageSize = 20,
    String? query,
    String? position,
    String sortBy = 'rating',
    bool descending = true,
  });
}
