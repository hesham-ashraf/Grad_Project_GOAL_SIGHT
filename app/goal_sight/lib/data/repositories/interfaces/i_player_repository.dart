import '../../models/player_heatmap_model.dart';
import '../../models/player_profile_model.dart';
import '../../models/risk_analysis_model.dart';

abstract interface class IPlayerRepository {
  Future<List<PlayerProfileModel>> fetchSquad({String? clubId});

  /// Per-match movement heatmaps for a player, newest match first. Empty when
  /// the AI pipeline hasn't produced any heatmaps for this player yet.
  Future<List<PlayerMatchHeatmap>> fetchPlayerHeatmaps(String playerId);

  /// Per-match history for a player (rating + stats per analysed match),
  /// newest first. Sourced from match_player_analysis joined to its match.
  Future<List<PlayerMatchHistory>> fetchPlayerMatchHistory(String playerId);

  Future<PlayerProfileModel> createPlayer({
    required String fullName,
    required String position,
    required String clubId,
    int? jerseyNumber,
    int? age,
    int? heightCm,
    int? weightKg,
    String? nationality,
    String? marketValue,
    bool isCaptain,
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
